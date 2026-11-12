--!strict
--[[
	ItemService — la fouille, le sac et les objets (CONCEPT.md, Les objets).

	- Fouiller : maintenir X sur un meuble de Carte.Fouilles. A chaque partie,
	  une partie des meubles seulement a quelque chose (on ne sait pas
	  lesquels) ; un meuble fouille l'est pour toute la partie. Ca fait du
	  bruit.
	- Le sac : 4 places, L1 / R1 pour choisir, L2 pour utiliser. Sac plein,
	  le nouvel objet prend la place choisie et l'ancien tombe par terre.
	- Voler : X maintenu sur un K.O. (une invite sur son corps).
	- Aspire, on lache tout son sac sur place (on revient le sac vide).
	- Les Reliques : au debut de certains Regards, l'Oeil lache un legendaire
	  au milieu du cercle, annonce a tous.

	Le serveur decide de tout : le client n'envoie que « choisir », « tourner »
	et « utiliser » (avec la direction de son regard pour un lancer). Les
	effets sur l'Oeil passent par EyeService (leurres, voile, clignement),
	ceux sur les cachettes par HidingService, les chutes par CombatService.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Bag = require(Royale:WaitForChild("Bag"))
local Config = require(Royale:WaitForChild("Config"))
local Loot = require(Royale:WaitForChild("Loot"))
local Throw = require(Royale:WaitForChild("Throw"))

local CombatService = require(script.Parent.CombatService)
local EyeService = require(script.Parent.EyeService)
local HidingService = require(script.Parent.HidingService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Roster = require(script.Parent.Roster)
local SquadService = require(script.Parent.SquadService)
local World = require(script.Parent.World)
local ZoneService = require(script.Parent.ZoneService)

local ItemService = {}

local L = Config.loot
local BG = Config.bag
local T = Config.throw
local I = Config.items
local FX = Config.effects
local SQ = Config.squads
local Mv = Config.movement

local random = Random.new()

local bags: { [Roster.Actor]: Bag.Bag } = {}
local selected: { [Roster.Actor]: number } = {}
local lastUse: { [Roster.Actor]: number } = {}
-- Les meubles qui ont quelque chose cette partie.
local filled: { [BasePart]: boolean } = {}
local prompts: { [BasePart]: ProximityPrompt } = {}
-- Ce que la partie a pose (fumee, flaques, objets par terre, relique).
local folder: Folder? = nil
local puddles: { { at: Vector3, radius: number, untilT: number, fall: number } } = {}
-- Bache de plomb : jusqu'a quand.
local sheets: { [Roster.Actor]: number } = {}
local stealPrompts: { [Roster.Actor]: ProximityPrompt } = {}
-- Donner a un coequipier : l'ecran ne la montre qu'a ses coequipiers.
local givePrompts: { [Roster.Actor]: ProximityPrompt } = {}
-- Les legendaires deja donnes cette partie (une relique n'en donne jamais
-- deux fois le meme).
local givenLegendary: { [string]: boolean } = {}
local projectileRemote: RemoteEvent? = nil
-- Prendre la relique en cours (l'invite, les bots).
local relicTake: ((Roster.Actor) -> ())? = nil

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

-- Un message court sur l'ecran du joueur (« Rien ici », « Tu trouves… »).
local function notify(actor: Roster.Actor, text: string)
	actor:SetAttribute(BG.messageAttribute, text .. "|" .. tostring(serverNow()))
end

-- Une annonce pour tout le monde (Relique, Larme).
local function announce(text: string)
	workspace:SetAttribute(BG.announceAttribute, text .. "|" .. tostring(serverNow()))
end

local function bagOf(actor: Roster.Actor): Bag.Bag
	local b = bags[actor]
	if b == nil then
		b = Bag.new(BG.slots)
		bags[actor] = b
	end
	return b
end

local function publish(actor: Roster.Actor)
	if actor.Parent == nil then
		return
	end
	actor:SetAttribute(BG.attribute, Bag.encode(bagOf(actor)))
	actor:SetAttribute(BG.selectedAttribute, selected[actor] or 1)
	-- Le Cocon se garde dans le sac et agit tout seul.
	actor:SetAttribute(FX.cocoonAttribute, if Bag.has(bagOf(actor), "cocoon") then true else nil)
end

local function partsFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = L.folder
	f.Parent = World.root or workspace
	folder = f
	return f
end

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function effectPart(name: string, at: Vector3, size: Vector3, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Size = size
	p.Color = color
	p.CFrame = CFrame.new(at)
	p.Parent = partsFolder()
	return p
end

local function glow(part: BasePart, color: Color3, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = 3
	light.Parent = part
end

local function free(actor: Roster.Actor): boolean
	return Roster.isAlive(actor)
		and not CombatService.isDown(actor)
		and not CombatService.isCarried(actor)
end

local give: (Roster.Actor, string) -> ()

-- Un objet par terre, a ramasser (sac plein, aspire).
local function dropOnGround(id: string, at: Vector3)
	local def = I[id]
	if def == nil then
		return
	end
	local ground = World.ground(at.X, at.Z) or at
	local part = effectPart(
		"ObjetPorTerre",
		ground
			+ Vector3.new(
				random:NextNumber(-L.groundScatter, L.groundScatter),
				0.6,
				random:NextNumber(-L.groundScatter, L.groundScatter)
			),
		Vector3.new(1.2, 1.2, 1.2),
		rgb(Config.rarities[def.rarity].color)
	)
	part.Material = Enum.Material.Neon
	part.CanQuery = true
	glow(part, part.Color, 8)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ramasser"
	prompt.ObjectText = def.name
	prompt.HoldDuration = L.pickupSeconds
	prompt.MaxActivationDistance = L.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode[Config.controls.contexts.onFoot.interact.keyboard]
	prompt.GamepadKeyCode = Enum.KeyCode[Config.controls.contexts.onFoot.interact.gamepad]
	prompt.Parent = part
	local taken = false
	prompt.Triggered:Connect(function(player: Player)
		if taken or not free(player) or HidingService.isHidden(player) then
			return
		end
		taken = true
		part:Destroy()
		give(player, id)
	end)
	Debris:AddItem(part, L.groundSeconds)
end

give = function(actor: Roster.Actor, id: string)
	local b, _, dropped = Bag.add(bagOf(actor), id, selected[actor] or 1)
	bags[actor] = b
	publish(actor)
	notify(actor, "Tu prends : " .. I[id].name)
	if dropped ~= "" then
		local root = Roster.rootOf(actor)
		if root then
			dropOnGround(dropped, root.Position)
		end
	end
end

local function consume(actor: Roster.Actor, slot: number)
	bags[actor] = (Bag.take(bagOf(actor), slot))
	publish(actor)
end

-- La fouille d'un meuble : le chemin de l'invite, et celui des bots et des
-- sondes. Rend l'objet trouve, ou nil (vide, deja fouille, trop loin).
function ItemService.trySearch(actor: Roster.Actor, part: BasePart): string?
	local root = Roster.rootOf(actor)
	if
		root == nil
		or not free(actor)
		or HidingService.isHidden(actor)
		or part:GetAttribute(L.searchedAttribute) == true
		or (root.Position - part.Position).Magnitude
			> L.promptDistance + part.Size.Magnitude / 2
	then
		return nil
	end
	part:SetAttribute(L.searchedAttribute, true)
	local prompt = prompts[part]
	if prompt then
		prompt.Enabled = false
	end
	EyeService.noise(part.Position, L.searchNoiseSeconds, false)
	if not filled[part] then
		notify(actor, "Rien ici.")
		return nil
	end
	local tableName = part:GetAttribute("Table")
	local weights = Loot.weights(L.weights, L.dangerTables[tableName] == true, L.dangerEpicFactor)
	local rarity = Loot.rollRarity(weights, random:NextNumber())
	local id = Loot.pick(I, rarity, random:NextNumber())
	if id == nil then
		return nil
	end
	give(actor, id)
	return id
end

-- Le meuble encore a fouiller le plus proche (les bots).
-- Un objet commun par terre (un Repris tue, CONCEPT.md).
function ItemService.dropCommon(at: Vector3)
	local id = Loot.pick(I, "common", random:NextNumber())
	if id then
		dropOnGround(id, at)
	end
end

function ItemService.searchableNear(at: Vector3, radius: number): BasePart?
	local best: BasePart? = nil
	local bestD = radius
	for part in prompts do
		if part:GetAttribute(L.searchedAttribute) ~= true then
			local d = (part.Position - at).Magnitude
			if d < bestD then
				best, bestD = part, d
			end
		end
	end
	return best
end

-- Les participants a moins de `radius` de `at` (pas caches).
-- Ceux qu'un objet touche autour de `at` : jamais son lanceur, ni ses
-- coequipiers (CONCEPT.md : les objets ne touchent jamais un coequipier).
local function around(at: Vector3, radius: number, except: Roster.Actor?): { Roster.Actor }
	local out: { Roster.Actor } = {}
	for _, actor in Roster.alive() do
		local root = Roster.rootOf(actor)
		if
			actor ~= except
			and not SquadService.allies(except, actor)
			and root
			and not HidingService.isHidden(actor)
		then
			if (root.Position - at).Magnitude <= radius then
				table.insert(out, actor)
			end
		end
	end
	return out
end

local function particles(part: BasePart, color: Color3, rate: number, size: number, life: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Rate = rate
	emitter.Size = NumberSequence.new(size * 0.6, size)
	emitter.Lifetime = NumberRange.new(life * 0.7, life)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Transparency = NumberSequence.new(0.2, 1)
	emitter.LightEmission = 0.1
	emitter.Parent = part
end

-- Ce qu'un lancer fait la ou il tombe.
local function land(id: string, at: Vector3, thrower: Roster.Actor)
	local def = I[id]
	if id == "smoke" then
		-- Une boule invisible qui coupe le regard (attribut Couvert a 1), et la
		-- fumee qu'on voit.
		local ball =
			effectPart("Fumee", at, Vector3.one * def.radius * 2, Color3.fromRGB(120, 120, 120))
		ball.Shape = Enum.PartType.Ball
		ball.Transparency = 1
		ball.CanQuery = true
		ball:SetAttribute(Config.world.coverAttribute, 1)
		particles(ball, Color3.fromRGB(150, 150, 150), 40, def.radius, 4)
		Debris:AddItem(ball, def.seconds)
	elseif id == "firecracker" then
		EyeService.noise(at, def.seconds, true)
		local p = effectPart("Petard", at, Vector3.one, Color3.fromRGB(255, 200, 80))
		p.Material = Enum.Material.Neon
		particles(p, Color3.fromRGB(255, 220, 120), 60, 1, 0.6)
		glow(p, p.Color, 20)
		Debris:AddItem(p, def.seconds)
	elseif id == "flare" or id == "redFlare" then
		local color = if id == "redFlare"
			then Color3.fromRGB(255, 40, 30)
			else Color3.fromRGB(255, 120, 60)
		local p = effectPart("Fusee", at, Vector3.new(0.6, 1.2, 0.6), color)
		p.Material = Enum.Material.Neon
		glow(p, color, 30)
		particles(p, color, 30, 1, 1)
		Debris:AddItem(p, def.seconds)
		local stuck: Roster.Actor? = nil
		if id == "flare" then
			stuck = around(at, def.stickRadius, thrower)[1]
		end
		EyeService.lure(function(): Vector3?
			if stuck then
				local root = Roster.rootOf(stuck)
				if root and Roster.isAlive(stuck) then
					p.CFrame = root.CFrame + Vector3.new(0, 3, 0)
					return root.Position
				end
			end
			return if p.Parent then at else nil
		end, def.seconds, id == "redFlare")
	elseif id == "bottle" or id == "net" then
		-- Jamais le lanceur lui-meme (un objet ne touche pas son camp).
		for _, victim in around(at, def.radius, thrower) do
			CombatService.trip(victim, def.fall, nil)
		end
	elseif id == "oil" then
		local ground = World.ground(at.X, at.Z) or at
		local p = effectPart(
			"Huile",
			ground + Vector3.new(0, 0.05, 0),
			Vector3.new(0.1, def.radius * 2, def.radius * 2),
			Color3.fromRGB(25, 22, 18)
		)
		p.Shape = Enum.PartType.Cylinder
		p.CFrame = CFrame.new(ground + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		p.Material = Enum.Material.Glass
		p.Reflectance = 0.3
		Debris:AddItem(p, def.seconds)
		table.insert(
			puddles,
			{ at = ground, radius = def.radius, untilT = os.clock() + def.seconds, fall = def.fall }
		)
	elseif id == "stinkBomb" then
		local p = effectPart("Puanteur", at, Vector3.one, Color3.fromRGB(110, 160, 40))
		p.Transparency = 1
		particles(p, Color3.fromRGB(120, 170, 50), 30, 3, 2)
		Debris:AddItem(p, def.seconds)
		local spot = HidingService.spotNear(at, def.radius)
		if spot then
			local out = HidingService.evict(spot)
			if out then
				notify(out, "Ça pue ! Tu sors en toussant.")
			end
		end
	end
end

-- Le point de chute d'un lancer, en suivant l'arc par petits pas.
local function throwFrom(actor: Roster.Actor, id: string, look: Vector3): boolean
	local character = Roster.characterOf(actor)
	local head = character and character:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) or look.Magnitude < 0.5 then
		return false
	end
	look = look.Unit
	local origin = head.Position + look * T.handForward
	local o = { x = origin.X, y = origin.Y, z = origin.Z }
	local v = Throw.velocity({ x = look.X, y = look.Y, z = look.Z }, T.speed, T.lift)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter: { Instance } = { character :: Instance, partsFolder() }
	if World.sky then
		table.insert(filter, World.sky)
	end
	params.FilterDescendantsInstances = filter
	params.RespectCanCollide = true
	local landing = origin
	local flight = T.maxSeconds
	local previous = origin
	local t = 0
	while t < T.maxSeconds do
		t += T.stepSeconds
		local p = Throw.at(o, v, T.gravity, t)
		local here = Vector3.new(p.x, p.y, p.z)
		local hit = workspace:Raycast(previous, here - previous, params)
		if hit then
			landing, flight = hit.Position, t
			break
		end
		previous, landing = here, here
	end
	if projectileRemote then
		projectileRemote:FireAllClients(id, origin, Vector3.new(v.x, v.y, v.z), flight)
	end
	task.delay(flight, function()
		land(id, landing, actor)
	end)
	return true
end

-- Celui qu'on a devant soi, dans un cone etroit (la lampe torche).
local function inFront(actor: Roster.Actor, root: BasePart, range: number): Roster.Actor?
	local best: Roster.Actor? = nil
	local bestD = range
	local look = root.CFrame.LookVector
	for _, other in around(root.Position, range, actor) do
		local r = Roster.rootOf(other)
		if r then
			local to = r.Position - root.Position
			local d = to.Magnitude
			if d > 0 and to.Unit:Dot(look) >= Config.combat.hitCone and d < bestD then
				best, bestD = other, d
			end
		end
	end
	return best
end

-- Le Grappin : un toit ou le haut d'un mur devant le regard.
local function grappleTarget(
	head: BasePart,
	look: Vector3,
	range: number,
	ignore: { Instance }
): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true
	local hit = workspace:Raycast(head.Position, look * range, params)
	if hit == nil then
		return nil
	end
	if hit.Normal.Y >= 0.7 then
		return hit.Position
	end
	-- Un mur : son dessus, juste derriere le point touche.
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.1 then
		return nil
	end
	local probe = hit.Position + flat.Unit * 1.5 + Vector3.new(0, Mv.mantleHeight * 2, 0)
	local top = workspace:Raycast(probe, Vector3.new(0, -Mv.mantleHeight * 2, 0), params)
	if top and top.Normal.Y >= 0.7 and top.Position.Y > hit.Position.Y then
		return top.Position
	end
	return nil
end

-- Utiliser l'objet de la place choisie. Rend vrai s'il a servi (et s'en va).
local function useItem(actor: Roster.Actor, look: Vector3?): boolean
	local slot = selected[actor] or 1
	local id = bagOf(actor)[slot]
	local def = I[id]
	local root = Roster.rootOf(actor)
	if def == nil or root == nil or not free(actor) then
		return false
	end
	local now = os.clock()
	if now < (lastUse[actor] or -math.huge) + BG.useCooldown then
		return false
	end
	local hidden = HidingService.isHidden(actor)
	local ownSpot = HidingService.spotOf(actor)
	-- Cache, seuls les objets qui ferment sa cachette servent.
	if hidden and id ~= "planks" and id ~= "padlock" then
		notify(actor, "Pas depuis une cachette.")
		return false
	end
	local direction = look or root.CFrame.LookVector
	local done = false
	local untilT = serverNow() + (def.seconds or 0)
	if def.kind == "throw" then
		done = throwFrom(actor, id, direction)
	elseif id == "torch" then
		local target = inFront(actor, root, def.range)
		if target then
			target:SetAttribute(FX.dazzledAttribute, serverNow() + def.seconds)
			done = true
		else
			notify(actor, "Personne devant toi.")
		end
	elseif id == "bat" then
		actor:SetAttribute(FX.batAttribute, def.charges)
		done = true
	elseif id == "binoculars" or id == "glassEye" then
		actor:SetAttribute(FX.revealAttribute, untilT)
		actor:SetAttribute(FX.revealRangeAttribute, def.range)
		actor:SetAttribute(FX.revealHiddenAttribute, id == "glassEye")
		done = true
	elseif id == "fakeBox" then
		local flat = Vector3.new(direction.X, 0, direction.Z)
		flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, -1)
		local spotAt = root.Position + flat * def.distance
		local ground = World.ground(spotAt.X, spotAt.Z, { Roster.characterOf(actor) :: Instance })
		if ground then
			done = HidingService.placeFake(def.prefab, CFrame.lookAt(ground, ground - flat)) ~= nil
		end
	elseif id == "cloak" then
		actor:SetAttribute(FX.cloakAttribute, untilT)
		done = true
	elseif id == "mirror" then
		done = EyeService.deflect(actor, def.seconds)
		if not done then
			notify(actor, "Aucun faisceau ne te suit.")
		end
	elseif id == "grapple" then
		local character = Roster.characterOf(actor)
		local head = character and character:FindFirstChild("Head")
		if head and head:IsA("BasePart") and character then
			local target = grappleTarget(head, direction.Unit, def.range, { character })
			if target then
				actor:SetAttribute(FX.grappleAttribute, target)
				actor:SetAttribute(FX.grappleTimeAttribute, serverNow())
				done = true
			else
				notify(actor, "Rien où s'accrocher.")
			end
		end
	elseif id == "adrenaline" then
		actor:SetAttribute(FX.adrenalineAttribute, untilT)
		done = true
	elseif id == "leadSheet" then
		sheets[actor] = os.clock() + def.seconds
		done = true
	elseif id == "dummy" then
		local flat = Vector3.new(direction.X, 0, direction.Z)
		flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, -1)
		local at = root.Position + flat * def.distance
		local figure =
			effectPart("Mannequin", at, Vector3.new(2, 5, 1), Color3.fromRGB(150, 130, 110))
		figure.Material = Enum.Material.Fabric
		figure.CanQuery = false
		local head = effectPart(
			"Tete",
			at + Vector3.new(0, 3.2, 0),
			Vector3.new(1.3, 1.3, 1.3),
			figure.Color
		)
		head.Shape = Enum.PartType.Ball
		head.Parent = figure
		Debris:AddItem(figure, def.seconds)
		EyeService.lure(function(): Vector3?
			return if figure.Parent then at else nil
		end, def.seconds, false)
		done = true
	elseif id == "stolenGaze" then
		EyeService.steer(actor, def.seconds)
		actor:SetAttribute(FX.steerAttribute, untilT)
		done = true
	elseif id == "tear" then
		EyeService.blink(def.seconds)
		announce("L'Œil cligne : plus aucun faisceau pendant " .. def.seconds .. " s !")
		done = true
	elseif id == "fragment" then
		actor:SetAttribute(FX.veiledAttribute, untilT)
		done = true
	elseif def.kind == "spot" then
		if id == "planks" or id == "padlock" then
			if ownSpot == nil then
				notify(actor, "Il faut être caché dedans.")
			elseif def.solidOnly and not ownSpot.solid then
				notify(actor, "Seulement dans une cachette solide.")
			else
				HidingService.barricade(ownSpot, def.seconds)
				notify(actor, "Barricadé pour " .. def.seconds .. " s.")
				done = true
			end
		else
			local spot = HidingService.spotNear(root.Position, Config.hiding.promptDistance)
			if spot == nil then
				notify(actor, "Aucune cachette à côté.")
			elseif id == "chalk" then
				HidingService.mark(spot)
				done = true
			elseif id == "bell" then
				spot.bell = true
				done = true
			elseif id == "trap" then
				spot.trap = true
				done = true
			end
		end
	end
	if done then
		lastUse[actor] = now
		consume(actor, slot)
	end
	return done
end

-- Le chemin du remote, des bots et des sondes.
function ItemService.use(actor: Roster.Actor, look: Vector3?): boolean
	return useItem(actor, look)
end

function ItemService.select(actor: Roster.Actor, slot: number)
	selected[actor] = math.clamp(math.floor(slot), 1, BG.slots)
	publish(actor)
end

function ItemService.bagOf(actor: Roster.Actor): Bag.Bag
	return table.clone(bagOf(actor))
end

function ItemService.give(actor: Roster.Actor, id: string)
	if I[id] then
		give(actor, id)
	end
end

-- Voler (X maintenu sur un K.O.) : un objet au hasard de son sac. Sur un
-- coequipier, la meme invite le releve (CONCEPT.md).
local function steal(thief: Roster.Actor, victim: Roster.Actor)
	local victimRoot, thiefRoot = Roster.rootOf(victim), Roster.rootOf(thief)
	if
		thief == victim
		or not free(thief)
		or victim:GetAttribute(Config.combat.koAttribute) ~= true
		or victimRoot == nil
		or thiefRoot == nil
		or (victimRoot.Position - thiefRoot.Position).Magnitude > BG.stealDistance + 2
	then
		return
	end
	if SquadService.allies(thief, victim) then
		CombatService.reset(victim)
		notify(victim, Roster.nameOf(thief) .. " te relève")
		notify(thief, "Tu relèves " .. Roster.nameOf(victim))
		return
	end
	local items = Bag.items(bagOf(victim))
	if #items == 0 then
		notify(thief, "Son sac est vide.")
		return
	end
	local id = items[random:NextInteger(1, #items)]
	local slot = Bag.has(bagOf(victim), id) :: number
	consume(victim, slot)
	notify(victim, "On t'a volé : " .. I[id].name)
	give(thief, id)
end

local function addStealPrompt(actor: Roster.Actor)
	local root = Roster.rootOf(actor)
	if root == nil then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RoyaleVoler"
	prompt.ActionText = "Voler"
	prompt.ObjectText = Roster.nameOf(actor)
	prompt.HoldDuration = BG.stealSeconds
	prompt.MaxActivationDistance = BG.stealDistance
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.KeyboardKeyCode = Enum.KeyCode[Config.controls.contexts.onFoot.interact.keyboard]
	prompt.GamepadKeyCode = Enum.KeyCode[Config.controls.contexts.onFoot.interact.gamepad]
	prompt.Parent = root
	prompt.Triggered:Connect(function(player: Player)
		steal(player, actor)
	end)
	stealPrompts[actor] = prompt
end

-- Donner l'objet qu'on tient a un coequipier debout (X maintenu sur lui).
local function hand(giver: Roster.Actor, receiver: Roster.Actor)
	local a, b = Roster.rootOf(giver), Roster.rootOf(receiver)
	if
		not SquadService.allies(giver, receiver)
		or not free(giver)
		or not free(receiver)
		or a == nil
		or b == nil
		or (a.Position - b.Position).Magnitude > SQ.giveDistance + 2
	then
		return
	end
	local slot = selected[giver] or 1
	local id = bagOf(giver)[slot]
	if id == nil or id == "" then
		notify(giver, "Tu ne tiens rien.")
		return
	end
	consume(giver, slot)
	give(receiver, id)
	notify(receiver, Roster.nameOf(giver) .. " te donne : " .. I[id].name)
end

local function addGivePrompt(actor: Roster.Actor)
	local root = Roster.rootOf(actor)
	if root == nil or SquadService.size() <= 1 then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RoyaleDonner"
	prompt.ActionText = SQ.giveText
	prompt.ObjectText = Roster.nameOf(actor)
	prompt.HoldDuration = SQ.giveSeconds
	prompt.MaxActivationDistance = SQ.giveDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode[Config.controls.contexts.onFoot.interact.keyboard]
	prompt.GamepadKeyCode = Enum.KeyCode[Config.controls.contexts.onFoot.interact.gamepad]
	prompt.Parent = root
	prompt.Triggered:Connect(function(player: Player)
		hand(player, actor)
	end)
	givePrompts[actor] = prompt
end

-- X maintenu sur un participant, par le meme chemin que les invites (les
-- sondes du pont ne peuvent pas les declencher) : voler ou relever un K.O.,
-- sinon donner a un coequipier.
function ItemService.tryInteract(actor: Roster.Actor, target: Roster.Actor)
	if target:GetAttribute(Config.combat.koAttribute) == true then
		steal(actor, target)
	else
		hand(actor, target)
	end
end

-- Le Cocon de secours : aspire, recrache sur place, une fois.
local function save(actor: Roster.Actor): boolean
	local slot = Bag.has(bagOf(actor), "cocoon")
	local regard = workspace:GetAttribute(Config.match.regardAttribute)
	if slot == nil or (typeof(regard) == "number" and regard >= I.cocoon.closedFromRegard) then
		return false
	end
	consume(actor, slot)
	actor:SetAttribute(Config.eye.graceAttribute, serverNow() + Config.eye.graceSeconds)
	actor:SetAttribute(Config.eye.exposureAttribute, 0)
	notify(actor, "Le Cocon de secours te recrache !")
	announce(Roster.nameOf(actor) .. " est recraché par un Cocon de secours")
	return true
end

-- Aspire : tout le sac tombe la ou il etait.
local function dropAll(actor: Roster.Actor)
	local root = Roster.rootOf(actor)
	for _, id in Bag.items(bagOf(actor)) do
		if root then
			dropOnGround(id, root.Position)
		end
	end
	bags[actor] = Bag.new(BG.slots)
	publish(actor)
end

-- Une Relique : un legendaire pas encore donne, au milieu du cercle.
local function spawnRelic()
	local pool: { string } = {}
	for _, id in Loot.ofRarity(I, "legendary") do
		if not givenLegendary[id] then
			table.insert(pool, id)
		end
	end
	if #pool == 0 then
		return
	end
	local id = pool[random:NextInteger(1, #pool)]
	givenLegendary[id] = true
	local circle = ZoneService.current()
	local center = Vector3.new(circle.x, 0, circle.z)
	local best: Vector3? = nil
	local anchors = World.anchors
	if anchors then
		local options: { Vector3 } = {}
		for _, a in anchors:GetChildren() do
			if a:IsA("BasePart") then
				local flat = Vector3.new(a.Position.X, 0, a.Position.Z)
				if (flat - center).Magnitude <= circle.radius * Config.relics.insideFraction then
					table.insert(options, a.Position)
				end
			end
		end
		if #options > 0 then
			best = options[random:NextInteger(1, #options)]
		end
	end
	local at = best or World.ground(center.X, center.Z) or center
	local gold = rgb(Config.rarities.legendary.color)
	local relic = effectPart("Relique", at + Vector3.new(0, 2, 0), Vector3.one * 2, gold)
	relic.Shape = Enum.PartType.Ball
	relic.Material = Enum.Material.Neon
	relic.CanQuery = true
	glow(relic, gold, Config.relics.lightRange)
	particles(relic, gold, 20, 1, 1.5)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Prendre la Relique"
	prompt.ObjectText = I[id].name
	prompt.HoldDuration = L.pickupSeconds
	prompt.MaxActivationDistance = L.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode[Config.controls.contexts.onFoot.interact.keyboard]
	prompt.GamepadKeyCode = Enum.KeyCode[Config.controls.contexts.onFoot.interact.gamepad]
	prompt.Parent = relic
	local taken = false
	local function take(actor: Roster.Actor)
		if taken or not free(actor) or HidingService.isHidden(actor) then
			return
		end
		taken = true
		relic:Destroy()
		workspace:SetAttribute(Config.relics.attribute, nil)
		give(actor, id)
		announce(Roster.nameOf(actor) .. " a pris la Relique : " .. I[id].name)
	end
	prompt.Triggered:Connect(take)
	relicTake = take
	workspace:SetAttribute(Config.relics.attribute, relic.Position)
	announce("L'Œil lâche une Relique au milieu du cercle !")
	print("[Royale] Relique posée : " .. I[id].name)
end

-- La relique en cours, si elle est a moins de `radius` (les bots y courent).
function ItemService.relicNear(at: Vector3, radius: number): BasePart?
	local f = folder
	local relic = f and f:FindFirstChild("Relique")
	if relic and relic:IsA("BasePart") and (relic.Position - at).Magnitude <= radius then
		return relic
	end
	return nil
end

-- La prendre, a portee d'invite (les bots et les sondes).
function ItemService.tryTakeRelic(actor: Roster.Actor): boolean
	local root = Roster.rootOf(actor)
	if root and relicTake and ItemService.relicNear(root.Position, L.promptDistance) then
		relicTake(actor)
		return true
	end
	return false
end

-- Un bot traque utilise ce qui le protege le mieux (`shield` le plus haut).
function ItemService.defend(actor: Roster.Actor): boolean
	local bag = bagOf(actor)
	local best, bestShield = nil, 0
	for i, id in bag do
		local def = I[id]
		local shield = if def and (def.kind == "use" or def.kind == "throw")
			then Loot.shield(I, { id })
			else 0
		if shield > bestShield then
			best, bestShield = i, shield
		end
	end
	local root = Roster.rootOf(actor)
	if best == nil or root == nil then
		return false
	end
	selected[actor] = best
	local id = bag[best]
	-- Le fumigene a ses pieds ; une fusee rouge au loin, devant lui.
	local look = if id == "smoke"
		then Vector3.new(0, -1, 0)
		else (root.CFrame.LookVector + Vector3.new(0, 1, 0)).Unit
	return useItem(actor, look)
end

-- Un nouveau Regard commence (MatchService).
function ItemService.onRegard(index: number)
	for _, r in Config.relics.regards do
		if r == index then
			spawnRelic()
		end
	end
end

-- Le debut d'une partie : les meubles a remplir, les invites de vol.
function ItemService.setup(actors: { Roster.Actor })
	local all: { BasePart } = {}
	for part in prompts do
		part:SetAttribute(L.searchedAttribute, nil)
		prompts[part].Enabled = true
		table.insert(all, part)
	end
	for i = #all, 2, -1 do
		local j = random:NextInteger(1, i)
		all[i], all[j] = all[j], all[i]
	end
	table.clear(filled)
	local wanted = math.min(#all, math.max(L.minFilled, L.perParticipant * #actors))
	for i = 1, wanted do
		filled[all[i]] = true
	end
	for _, actor in actors do
		bags[actor] = Bag.new(BG.slots)
		selected[actor] = 1
		publish(actor)
		addStealPrompt(actor)
		addGivePrompt(actor)
	end
	print(string.format("[Royale] %d meubles sur %d ont quelque chose", wanted, #all))
end

function ItemService.clear()
	for actor in bags do
		if actor.Parent then
			for _, a in
				{
					BG.attribute,
					BG.selectedAttribute,
					BG.messageAttribute,
					FX.cocoonAttribute,
					FX.batAttribute,
					FX.veiledAttribute,
					FX.cloakAttribute,
					FX.adrenalineAttribute,
					FX.dazzledAttribute,
					FX.revealAttribute,
					FX.steerAttribute,
					FX.grappleAttribute,
				}
			do
				actor:SetAttribute(a, nil)
			end
		end
	end
	for _, prompt in stealPrompts do
		prompt:Destroy()
	end
	table.clear(stealPrompts)
	for _, prompt in givePrompts do
		prompt:Destroy()
	end
	table.clear(givePrompts)
	table.clear(bags)
	table.clear(selected)
	table.clear(lastUse)
	table.clear(puddles)
	table.clear(sheets)
	table.clear(givenLegendary)
	relicTake = nil
	if folder then
		folder:Destroy()
		folder = nil
	end
	workspace:SetAttribute(Config.relics.attribute, nil)
	workspace:SetAttribute(BG.announceAttribute, nil)
	workspace:SetAttribute(FX.bellAttribute, nil)
end

-- Le pas des effets qui durent : flaques, bache, ceux qui brillent.
local function step()
	local now = os.clock()
	for i = #puddles, 1, -1 do
		local puddle = puddles[i]
		if now >= puddle.untilT then
			table.remove(puddles, i)
			continue
		end
		for _, actor in around(puddle.at, puddle.radius) do
			local root = Roster.rootOf(actor)
			if root and not CombatService.isDown(actor) then
				local v = root.AssemblyLinearVelocity
				if Vector3.new(v.X, 0, v.Z).Magnitude > Mv.runningAbove then
					CombatService.trip(actor, puddle.fall, Vector3.new(v.X, 0, v.Z))
				end
			end
		end
	end
	-- La Bache : invisible tant qu'on ne bouge pas.
	for actor, untilT in sheets do
		local root = Roster.rootOf(actor)
		if now >= untilT or root == nil or not Roster.isAlive(actor) then
			sheets[actor] = nil
			if actor.Parent then
				actor:SetAttribute(FX.sheetAttribute, nil)
			end
			continue
		end
		local v = root.AssemblyLinearVelocity
		local still = Vector3.new(v.X, 0, v.Z).Magnitude <= I.leadSheet.stillSpeed
		actor:SetAttribute(FX.sheetAttribute, still)
		if still then
			actor:SetAttribute(FX.veiledAttribute, serverNow() + Config.effects.stepSeconds * 2)
		end
	end
	-- Qui porte un legendaire brille un peu ; le Fragment brille fort.
	for _, actor in Roster.alive() do
		local character = Roster.characterOf(actor)
		if character == nil then
			continue
		end
		local veil = actor:GetAttribute(FX.veiledAttribute)
		local fragment = typeof(veil) == "number" and serverNow() < veil and sheets[actor] == nil
		local legendary = false
		for _, id in Bag.items(bagOf(actor)) do
			if I[id].rarity == "legendary" then
				legendary = true
			end
		end
		local highlight = character:FindFirstChild("RoyaleLueur") :: Highlight?
		if (fragment or legendary) and highlight == nil then
			local h = Instance.new("Highlight")
			h.Name = "RoyaleLueur"
			h.FillColor = rgb(FX.glowColor)
			h.OutlineColor = rgb(FX.glowColor)
			h.DepthMode = Enum.HighlightDepthMode.Occluded
			h.Parent = character
			highlight = h
		elseif not (fragment or legendary) and highlight then
			highlight:Destroy()
			highlight = nil
		end
		if highlight then
			highlight.FillTransparency = if fragment then FX.fragmentFill else FX.legendaryFill
			highlight.OutlineTransparency = if fragment then 0 else FX.legendaryOutline
		end
	end
	-- Les invites de vol : seulement sur un K.O.
	for actor, prompt in stealPrompts do
		prompt.Enabled = actor.Parent ~= nil
			and actor:GetAttribute(Config.combat.koAttribute) == true
			and Roster.isAlive(actor)
	end
	-- Donner : sur un participant debout, a decouvert.
	for actor, prompt in givePrompts do
		prompt.Enabled = actor.Parent ~= nil and free(actor) and not HidingService.isHidden(actor)
	end
end

function ItemService.start(
	itemRemote: RemoteEvent,
	projectile: RemoteEvent,
	steerRemote: RemoteEvent
)
	projectileRemote = projectile
	-- Les invites des meubles, une fois pour toutes.
	local root = World.root
	local containers = root and root:FindFirstChild(Config.world.containers)
	if containers then
		for _, part in containers:GetChildren() do
			if part:IsA("BasePart") then
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "RoyaleFouille"
				prompt.ActionText = "Fouiller"
				prompt.ObjectText = ""
				prompt.HoldDuration = L.searchSeconds
				prompt.MaxActivationDistance = L.promptDistance
				prompt.RequiresLineOfSight = false
				prompt.KeyboardKeyCode =
					Enum.KeyCode[Config.controls.contexts.onFoot.interact.keyboard]
				prompt.GamepadKeyCode =
					Enum.KeyCode[Config.controls.contexts.onFoot.interact.gamepad]
				prompt.Parent = part
				prompt.Triggered:Connect(function(player: Player)
					ItemService.trySearch(player, part)
				end)
				prompts[part] = prompt
			end
		end
	end
	itemRemote.OnServerEvent:Connect(
		RemoteGuard.wrap(Config.remotes.item, function(player: Player, action: any, arg: any)
			if action == "select" and typeof(arg) == "number" then
				ItemService.select(player, arg)
			elseif action == "cycle" and (arg == 1 or arg == -1) then
				ItemService.select(player, Bag.cycle(selected[player] or 1, arg, BG.slots))
			elseif action == "use" then
				useItem(player, if typeof(arg) == "Vector3" then arg else nil)
			end
		end)
	)
	steerRemote.OnServerEvent:Connect(
		RemoteGuard.wrap(Config.remotes.steer, function(player: Player, x: any, z: any)
			if typeof(x) == "number" and typeof(z) == "number" then
				local cx, cz = ZoneService.clamp(x, z)
				EyeService.steerTo(player, cx, cz)
			end
		end)
	)
	-- Les objets poses sur les cachettes.
	HidingService.onEnter(function(actor: Roster.Actor, spot: HidingService.Spot)
		if spot.fake then
			-- Le Carton piege : ejecte, flaire, et le carton s'envole.
			task.defer(function()
				HidingService.evict(spot)
				EyeService.flag(actor)
				notify(actor, "C'était un piège ! L'Œil t'a flairé.")
				HidingService.rip(spot, false)
			end)
		elseif spot.bell then
			workspace:SetAttribute(FX.bellAttribute, spot.inside.Position)
			workspace:SetAttribute(FX.bellTimeAttribute, serverNow())
		end
	end)
	HidingService.onRelease(function(actor: Roster.Actor, spot: HidingService.Spot)
		if spot.trap then
			spot.trap = false
			task.defer(function()
				CombatService.trip(actor, I.trap.fall, nil)
				notify(actor, "Un piège à loup !")
			end)
		end
	end)
	Roster.setSaver(save)
	Roster.onBeforeTake(dropAll)
	Players.PlayerRemoving:Connect(function(player: Player)
		bags[player] = nil
		selected[player] = nil
		lastUse[player] = nil
		sheets[player] = nil
		stealPrompts[player] = nil
		givePrompts[player] = nil
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc >= FX.stepSeconds then
			acc = 0
			step()
		end
	end)
end

return ItemService
