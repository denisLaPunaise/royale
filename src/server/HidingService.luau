--!strict
--[[
	HidingService — les cachettes (CONCEPT.md, Cachettes).

	A chaque partie, des modeles de ServerStorage.RoyaleCachettes se posent sur
	une partie des emplacements de la recette (jamais les memes d'une partie a
	l'autre). Les cachettes solides de la carte (tunnels, chambre froide) sont
	toujours la et ne s'arrachent jamais.

	Entrer (maintenir X) : on se tient dans le modele, invisible a l'Oeil, et
	la cachette se MARQUE. L'Oeil ne vient pas la chercher pendant l'ouverture
	ou l'on y entre, seulement aux suivantes (`markBursts` au plus) : il
	l'arrache alors a la vue de tous, apres un tremblement qui laisse le temps
	de sortir. Ejecte, on a `graceSeconds` de repit pour courir.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Roster = require(script.Parent.Roster)
local Sfx = require(script.Parent.Sfx)
local World = require(script.Parent.World)

local HidingService = {}

local W = Config.world
local H = Config.hiding

export type Spot = {
	model: Model,
	inside: BasePart,
	exits: { BasePart },
	solid: boolean,
	-- Ceux qui y sont : un abri ferme n'en prend qu'un, un volume (buisson,
	-- roseaux, abri, dessous de pont...) plusieurs (CONCEPT.md).
	occupants: { Roster.Actor },
	capacity: number,
	-- Sa sorte (le nom du modele sans son numero) : ses mecaniques en
	-- dependent (CONCEPT.md, les cachettes a mecanique).
	kind: string,
	-- Le numero de l'ouverture pendant laquelle (ou apres laquelle) on y est
	-- entre pour la derniere fois ; nil : pas marquee.
	mark: number?,
	ripping: boolean,
	prompt: ProximityPrompt,
	-- Les objets poses dessus (ItemService) : clochette, piege, barricade
	-- (heure de fin, os.clock), fausse cachette (le Carton piege).
	bell: boolean,
	trap: boolean,
	barricadedUntil: number,
	fake: boolean,
	-- Depuis quand l'occupant y est (os.clock), pour le flair de l'Oeil.
	since: number,
}

local spots: { Spot } = {}
local byPlayer: { [Roster.Actor]: Spot } = {}
local placed: Folder? = nil
-- Les emplacements deja occupes cette partie (on n'y pose pas deux fois).
local usedAnchors: { [BasePart]: boolean } = {}
local random = Random.new()
-- Le numero de la derniere ouverture de l'Oeil (tenu par EyeService).
local burstSerial = 0
local enterCallbacks: { (Roster.Actor, Spot) -> () } = {}
local releaseCallbacks: { (Roster.Actor, Spot) -> () } = {}

local function markersOf(model: Instance): (BasePart?, { BasePart })
	local inside: BasePart? = nil
	local exits: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == W.inside then
				inside = d
			elseif d.Name == W.exit then
				table.insert(exits, d)
			end
		end
	end
	return inside, exits
end

local function nearestExit(spot: Spot, from: Vector3): BasePart
	local best = spot.exits[1]
	local bestD = math.huge
	for _, e in spot.exits do
		local d = (e.Position - from).Magnitude
		if d < bestD then
			best, bestD = e, d
		end
	end
	return best
end

-- La place d'un occupant dans la cachette : le premier au centre, les
-- suivants a cote (on se tient serres dans un buisson).
local function seat(spot: Spot, index: number): CFrame
	if index <= 1 then
		return spot.inside.CFrame
	end
	local side = if index % 2 == 0 then 1 else -1
	local step = math.floor(index / 2) * H.seatSpacing
	return spot.inside.CFrame * CFrame.new(side * step, 0, 0)
end

local function farthestExit(spot: Spot, from: Vector3): BasePart
	local best = spot.exits[1]
	local bestD = -math.huge
	for _, e in spot.exits do
		local d = (e.Position - from).Magnitude
		if d > bestD then
			best, bestD = e, d
		end
	end
	return best
end

local function release(player: Roster.Actor, spot: Spot, grace: boolean, awayFrom: Vector3?)
	byPlayer[player] = nil
	local i = table.find(spot.occupants, player)
	if i then
		table.remove(spot.occupants, i)
	end
	spot.prompt.Enabled = not spot.ripping and #spot.occupants < spot.capacity
	player:SetAttribute(H.hiddenAttribute, nil)
	local root = Roster.rootOf(player)
	if root then
		-- Delogee, on sort par le cote oppose a celui qui pousse (la voiture
		-- a deux portieres, CONCEPT.md) ; sinon par la sortie la plus proche.
		local exit = if #spot.exits == 0
			then spot.inside
			elseif awayFrom then farthestExit(spot, awayFrom)
			else nearestExit(spot, root.Position)
		root.Anchored = false
		root.CFrame = CFrame.new(exit.Position + Vector3.new(0, 1, 0))
			* (exit.CFrame - exit.CFrame.Position)
	end
	if grace then
		player:SetAttribute(
			Config.eye.graceAttribute,
			workspace:GetServerTimeNow() + Config.eye.graceSeconds
		)
	end
	for _, callback in releaseCallbacks do
		callback(player, spot)
	end
end

-- Au sol, en portant quelqu'un ou porte : on n'entre nulle part.
local function busy(player: Roster.Actor): boolean
	local C = Config.combat
	local down = player:GetAttribute(C.downAttribute)
	return (typeof(down) == "number" and workspace:GetServerTimeNow() < down)
		or player:GetAttribute(C.carryingAttribute) ~= nil
		or player:GetAttribute(C.carriedAttribute) ~= nil
		-- Dans un cocon, on attend qu'on nous ouvre (vu au banc d'equilibrage :
		-- un bot en cocon entrait dans un egout voisin, puis tombait sous la
		-- carte a l'ouverture du cocon).
		or player:GetAttribute(Config.squads.cocoonAttribute) == true
end

local function enter(player: Roster.Actor, spot: Spot)
	if
		not Roster.isAlive(player)
		or #spot.occupants >= spot.capacity
		or spot.ripping
		or byPlayer[player]
		or busy(player)
	then
		return
	end
	local root = Roster.rootOf(player)
	if root == nil then
		return
	end
	table.insert(spot.occupants, player)
	if #spot.occupants == 1 then
		spot.since = os.clock()
	end
	spot.mark = burstSerial
	spot.prompt.Enabled = #spot.occupants < spot.capacity
	byPlayer[player] = spot
	player:SetAttribute(H.hiddenAttribute, spot.model.Name)
	root.Anchored = true
	root.CFrame = seat(spot, #spot.occupants)
	for _, callback in enterCallbacks do
		callback(player, spot)
	end
end

local function makeSpot(model: Model, solid: boolean): Spot?
	local inside, exits = markersOf(model)
	if inside == nil then
		warn("[Royale] Cachette sans « " .. W.inside .. " » : " .. model:GetFullName())
		return nil
	end
	local holder = if #exits > 0 then exits[1] else inside
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = H.actionText[(string.gsub(model.Name, "%d+$", ""))] or H.defaultAction
	prompt.ObjectText = model.Name
	prompt.HoldDuration = H.enterHoldSeconds
	prompt.MaxActivationDistance = H.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode[Config.controls.contexts.onFoot.interact.keyboard]
	prompt.GamepadKeyCode = Enum.KeyCode[Config.controls.contexts.onFoot.interact.gamepad]
	prompt.Parent = holder
	local spot: Spot = {
		model = model,
		inside = inside,
		exits = exits,
		solid = solid,
		occupants = {},
		capacity = H.capacity[(string.gsub(model.Name, "%d+$", ""))] or H.defaultCapacity,
		kind = (string.gsub(model.Name, "%d+$", "")),
		bell = false,
		trap = false,
		barricadedUntil = 0,
		fake = false,
		since = 0,
		mark = nil,
		ripping = false,
		prompt = prompt,
	}
	prompt.Triggered:Connect(function(player: Player)
		HidingService.tryEnter(player, model)
	end)
	table.insert(spots, spot)
	return spot
end

-- Les modeles qui peuvent aller sur un emplacement `Prefab` : le nom exact,
-- ou ses variantes numerotees (Voiture, Voiture2...).
local function variantsOf(prefab: string): { Model }
	local out: { Model } = {}
	local library = World.prefabs
	if library == nil then
		return out
	end
	for _, m in library:GetChildren() do
		if m:IsA("Model") and string.match(m.Name, "^" .. prefab .. "%d*$") then
			table.insert(out, m)
		end
	end
	return out
end

-- Tout enlever : sortir chacun, detruire les cachettes posees, retirer les
-- invites des cachettes solides.
function HidingService.clear()
	for player, spot in byPlayer do
		release(player, spot, false)
	end
	for _, spot in spots do
		spot.prompt:Destroy()
	end
	table.clear(spots)
	table.clear(byPlayer)
	table.clear(usedAnchors)
	if placed then
		placed:Destroy()
		placed = nil
	end
	burstSerial = 0
end

-- Pose une cachette sur cet emplacement de la carte (son prefab, une
-- variante au hasard). Vrai si elle est posee.
local function placeAt(anchor: Instance, folder: Folder): boolean
	if not anchor:IsA("BasePart") or usedAnchors[anchor] then
		return false
	end
	local prefab = anchor:GetAttribute("Prefab")
	if typeof(prefab) ~= "string" then
		return false
	end
	local variants = variantsOf(prefab)
	if #variants == 0 then
		return false
	end
	local template = variants[random:NextInteger(1, #variants)]
	local model = template:Clone()
	local socle = model.PrimaryPart
	if socle == nil then
		model:Destroy()
		return false
	end
	local offset = socle.CFrame:ToObjectSpace(model:GetPivot())
	model:PivotTo(anchor.CFrame * offset)
	model.Name = prefab
	model.Parent = folder
	if makeSpot(model, false) then
		usedAnchors[anchor] = true
		return true
	end
	return false
end

-- Une nouvelle partie : pose les cachettes pour `players` joueurs.
function HidingService.setup(players: number)
	HidingService.clear()
	local root = World.root
	local anchors = World.anchors
	if root == nil or anchors == nil then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = W.placedFolder
	folder.Parent = root
	placed = folder

	local pool = anchors:GetChildren()
	-- Melange (Fisher-Yates) : jamais les memes places d'une partie a l'autre.
	for i = #pool, 2, -1 do
		local j = random:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local wanted = math.min(#pool, math.max(H.minSpots, H.spotsPerPlayer * players))
	local count = 0
	for _, anchor in pool do
		if count >= wanted then
			break
		end
		if placeAt(anchor, folder) then
			count += 1
		end
	end
	local solid = World.solidSpots
	if solid then
		for _, model in solid:GetChildren() do
			if model:IsA("Model") then
				makeSpot(model, true)
			end
		end
	end
	-- Les plaques d'egout de la carte (CONCEPT.md : « ressort plus loin :
	-- traverser une rue sans etre vu ») : sous chacune, une cachette etroite.
	local sewers = 0
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and part.Name == H.sewer.coverName then
			local model = Instance.new("Model")
			model.Name = H.sewer.name
			local top = part.Position
			local inside = Instance.new("Part")
			inside.Name = W.inside
			inside.Size = Vector3.one * 2
			inside.Anchored = true
			inside.CanCollide = false
			inside.CanQuery = false
			inside.Transparency = 1
			inside.CFrame = CFrame.new(top - Vector3.new(0, H.sewer.depth, 0))
			inside.Parent = model
			local exit = Instance.new("Part")
			exit.Name = W.exit
			exit.Size = Vector3.one * 2
			exit.Anchored = true
			exit.CanCollide = false
			exit.CanQuery = false
			exit.Transparency = 1
			exit.CFrame = CFrame.new(top + Vector3.new(0, 1, 0))
			exit.Parent = model
			model.Parent = folder
			-- Solide : elle fait partie de la carte, on ne l'arrache pas.
			if makeSpot(model, true) then
				sewers += 1
			end
		end
	end
	print(
		string.format(
			"[Royale] %d cachettes posées, %d égouts, plus les cachettes solides",
			count,
			sewers
		)
	)
end

-- Un cercle s'annonce (x, z, rayon) : on complete les cachettes a
-- l'interieur jusqu'a `wanted` (toutes sortes comptees, solides et egouts
-- compris). Mesure au banc d'equilibrage du 13 novembre 2026 : posees au
-- hasard sur toute la carte, il en restait 4 dans le cercle du Regard 3
-- pour 12 joueurs, et la partie finissait en chaises musicales. Jamais a
-- moins de `fillAwayFrom` studs d'un joueur : personne ne la voit apparaitre.
function HidingService.fillCircle(x: number, z: number, radius: number, wanted: number): number
	local folder = placed
	local anchors = World.anchors
	if folder == nil or anchors == nil then
		return 0
	end
	local function inside(p: Vector3): boolean
		local dx, dz = p.X - x, p.Z - z
		return dx * dx + dz * dz <= radius * radius
	end
	local have = 0
	for _, spot in spots do
		if not spot.ripping and inside(spot.inside.Position) then
			have += 1
		end
	end
	local watchers: { Vector3 } = {}
	for _, actor in Roster.alive() do
		local root = Roster.rootOf(actor)
		if root then
			table.insert(watchers, root.Position)
		end
	end
	local pool = anchors:GetChildren()
	for i = #pool, 2, -1 do
		local j = random:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local added = 0
	for _, anchor in pool do
		if have + added >= wanted then
			break
		end
		if not anchor:IsA("BasePart") or usedAnchors[anchor] or not inside(anchor.Position) then
			continue
		end
		local seen = false
		for _, at in watchers do
			if (at - anchor.Position).Magnitude < H.fillAwayFrom then
				seen = true
				break
			end
		end
		if not seen and placeAt(anchor, folder) then
			added += 1
		end
	end
	if added > 0 then
		print(
			string.format(
				"[Royale] %d cachettes ajoutées dans le prochain cercle (%d en tout)",
				added,
				have + added
			)
		)
	end
	return added
end

-- Entrer dans la cachette `model` : le chemin de l'invite, et celui des
-- sondes (les touches simulees n'atteignent pas les invites depuis le pont).
function HidingService.tryEnter(player: Roster.Actor, model: Instance): boolean
	for _, spot in spots do
		if spot.model == model then
			enter(player, spot)
			return byPlayer[player] == spot
		end
	end
	return false
end

function HidingService.isHidden(player: Roster.Actor): boolean
	return byPlayer[player] ~= nil
end

-- La plaque ou ressortir d'un egout : la plus proche dans la direction
-- regardee (`look`), a portee ; sans direction, une voisine au hasard.
local function sewerExit(from: Spot, look: Vector3?): Spot?
	local here = from.inside.Position
	local best, bestScore = nil, -math.huge
	for _, spot in spots do
		if spot == from or spot.kind ~= H.sewer.name or spot.ripping then
			continue
		end
		local delta =
			Vector3.new(spot.inside.Position.X - here.X, 0, spot.inside.Position.Z - here.Z)
		local d = delta.Magnitude
		if d <= 0 or d > H.sewer.range then
			continue
		end
		local score
		if look then
			local flat = Vector3.new(look.X, 0, look.Z)
			local dot = if flat.Magnitude > 0 then flat.Unit:Dot(delta.Unit) else 0
			if dot < H.sewer.minDot then
				continue
			end
			-- Dans l'axe d'abord, puis la plus proche.
			score = dot * H.sewer.range - d
		else
			score = random:NextNumber()
		end
		if score > bestScore then
			best, bestScore = spot, score
		end
	end
	return best
end

-- Sortir de sa cachette. D'un egout, on ressort par la plaque vers
-- laquelle on regarde (`look`, la camera du joueur), ou par la meme.
function HidingService.leave(player: Roster.Actor, look: Vector3?)
	local spot = byPlayer[player]
	if spot == nil then
		return
	end
	-- Seulement en regardant quelque part (un joueur) : sans direction (un
	-- bot, sortir en force), on ressort par la meme plaque. Vu en partie :
	-- les bots entraient et sortaient sans cesse, teleportes d'une plaque a
	-- l'autre (82 fois en 4 minutes).
	local target = if spot.kind == H.sewer.name and look then sewerExit(spot, look) else nil
	release(player, spot, false)
	local root = Roster.rootOf(player)
	if target and root then
		root.CFrame = CFrame.new(target.exits[1].Position + Vector3.new(0, 2, 0))
		print(string.format("[Royale] %s ressort d'un égout plus loin", Roster.nameOf(player)))
	end
end

-- Une nouvelle ouverture de l'Oeil commence.
function HidingService.setBurst(serial: number)
	burstSerial = serial
end

-- Les cachettes que l'Oeil peut arracher maintenant : marquees AVANT cette
-- ouverture, il y a au plus `markBursts` ouvertures. Les occupees d'abord,
-- celles dont l'occupant est flaire (`flagged`) avant tout.
-- `forgetAfter` : le nombre d'ouvertures qu'il garde une marque (la rancune :
-- toujours). `byAge` : le flair, les occupees depuis le plus longtemps d'abord.
function HidingService.ripCandidates(
	flagged: { [Roster.Actor]: boolean },
	solidFalls: boolean,
	forgetAfter: number,
	byAge: boolean
): { Spot }
	local out: { Spot } = {}
	for _, spot in spots do
		local mark = spot.mark
		if
			(solidFalls or not spot.solid)
			and not spot.ripping
			and mark ~= nil
			and mark < burstSerial
			and burstSerial - mark <= forgetAfter
		then
			table.insert(out, spot)
		end
	end
	local function rank(spot: Spot): number
		for _, occupant in spot.occupants do
			if flagged[occupant] then
				return 0
			end
		end
		return if #spot.occupants > 0 then 1 else 2
	end
	table.sort(out, function(a, b)
		local ra, rb = rank(a), rank(b)
		if ra ~= rb then
			return ra < rb
		end
		if byAge and ra < 2 and a.since ~= b.since then
			return a.since < b.since
		end
		return (a.mark :: number) > (b.mark :: number)
	end)
	return out
end

-- Les cachettes libres, pour les bots : le modele et l'endroit d'ou l'on y
-- entre (sa sortie).
function HidingService.freeSpots(): { { model: Model, at: Vector3 } }
	local out = {}
	for _, spot in spots do
		if #spot.occupants < spot.capacity and not spot.ripping and spot.model.Parent then
			local at = if #spot.exits > 0 then spot.exits[1].Position else spot.inside.Position
			table.insert(out, { model = spot.model, at = at })
		end
	end
	return out
end

-- La cachette la plus proche de `at` a moins de `range` (toquer, deloger).
-- Rend aussi le point ou elle se touche.
function HidingService.spotNear(at: Vector3, range: number): (Spot?, Vector3?)
	local best: Spot? = nil
	local bestAt: Vector3? = nil
	local bestD = range
	for _, spot in spots do
		if spot.ripping or spot.model.Parent == nil then
			continue
		end
		for _, part in { spot.inside, table.unpack(spot.exits) } do
			local d = (part.Position - at).Magnitude
			if d <= bestD then
				best, bestAt, bestD = spot, part.Position, d
			end
		end
	end
	return best, bestAt
end

-- Deloge un occupant (la poussee sur un abri, le Rampant) : le premier
-- entre sort, sans le repit de l'arrachage (c'est un joueur qui l'a trouve,
-- pas l'Oeil). Rend qui est sorti.
-- `from` : la ou se tient celui qui pousse (nil : un objet, un Repris). Un
-- conteneur se ferme de l'interieur : on ne le force pas en poussant.
function HidingService.evict(spot: Spot, from: Vector3?): Roster.Actor?
	local occupant = spot.occupants[1]
	if occupant and os.clock() < spot.barricadedUntil then
		return nil
	end
	if occupant and from and H.sealed[spot.kind] then
		return nil
	end
	if occupant then
		release(occupant, spot, false, from)
	end
	return occupant
end

-- Ce que l'Oeil voit de quelqu'un dans cette cachette : rien d'un abri
-- ferme, une partie dans un buisson (« un faisceau qui reste dessus finit
-- par voir », CONCEPT.md).
function HidingService.coverOf(player: Roster.Actor): number
	local spot = byPlayer[player]
	return if spot then H.seenInside[spot.kind] or 0 else 0
end

-- Le bruit d'une cachette quand on y entre ou en sort (le conteneur fait un
-- vacarme), en secondes d'ecoute pour l'Oeil ; 0 sinon.
function HidingService.noiseOf(spot: Spot): number
	return H.noisy[spot.kind] or 0
end

-- Appele quand un participant entre dans une cachette, ou en sort (de
-- quelque facon que ce soit) : les objets poses dessus reagissent.
function HidingService.onEnter(callback: (Roster.Actor, Spot) -> ())
	table.insert(enterCallbacks, callback)
end

function HidingService.onRelease(callback: (Roster.Actor, Spot) -> ())
	table.insert(releaseCallbacks, callback)
end

-- La Craie : l'Oeil vient l'arracher a sa prochaine ouverture.
function HidingService.mark(spot: Spot)
	spot.mark = burstSerial
end

-- Planches, Cadenas : personne ne deloge l'occupant pendant `seconds`.
function HidingService.barricade(spot: Spot, seconds: number)
	spot.barricadedUntil = os.clock() + seconds
end

-- Le Carton piege : une fausse cachette dont le socle se pose a `at`.
-- Elle se comporte comme une vraie (invite, entree) ; ItemService ejecte.
function HidingService.placeFake(prefab: string, at: CFrame): Spot?
	local variants = variantsOf(prefab)
	if #variants == 0 or placed == nil then
		return nil
	end
	local model = variants[random:NextInteger(1, #variants)]:Clone()
	local socle = model.PrimaryPart
	if socle == nil then
		model:Destroy()
		return nil
	end
	-- Comme une vraie : le socle pose sur le sol, a `at`.
	model:PivotTo(at * socle.CFrame:ToObjectSpace(model:GetPivot()))
	model.Name = prefab
	model.Parent = placed
	local spot = makeSpot(model, false)
	if spot then
		spot.fake = true
	else
		model:Destroy()
	end
	return spot
end

-- La cachette ou ce joueur se tient (pour l'arracher quand il est flaire).
function HidingService.spotOf(player: Roster.Actor): Spot?
	return byPlayer[player]
end

-- L'Oeil arrache cette cachette : elle tremble, puis s'envole.
function HidingService.rip(spot: Spot, solidFalls: boolean)
	if spot.ripping or (spot.solid and not solidFalls) then
		return
	end
	Sfx.at("aspiration", spot.inside.Position)
	if spot.solid then
		-- Une cachette solide fait partie de la carte : elle ne s'envole pas,
		-- elle s'effondre (on en est chasse, et on n'y rentre plus).
		spot.ripping = true
		spot.prompt.Enabled = false
		for _, occupant in table.clone(spot.occupants) do
			release(occupant, spot, true)
		end
		print("[Royale] Une cachette solide s'effondre : " .. spot.model.Name)
		return
	end
	spot.ripping = true
	spot.prompt.Enabled = false
	local model = spot.model
	local base = model:GetPivot()
	local shakeUntil = os.clock() + H.ripWarningSeconds
	task.spawn(function()
		while os.clock() < shakeUntil and model.Parent do
			model:PivotTo(
				base
					* CFrame.new(
						random:NextNumber(-H.shakeOffset, H.shakeOffset),
						0,
						random:NextNumber(-H.shakeOffset, H.shakeOffset)
					)
					* CFrame.Angles(0, random:NextNumber(-H.shakeTurn, H.shakeTurn), 0)
			)
			task.wait()
		end
		if model.Parent == nil then
			return
		end
		model:PivotTo(base)
		for _, occupant in table.clone(spot.occupants) do
			release(occupant, spot, true)
		end
		local toward = World.eyeOrigin
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
				part.CanQuery = false
				local up = (toward - part.Position).Unit
				part.AssemblyLinearVelocity = up * random:NextNumber(H.liftMin, H.liftMax)
					+ Vector3.new(
						random:NextNumber(-H.scatter, H.scatter),
						0,
						random:NextNumber(-H.scatter, H.scatter)
					)
				part.AssemblyAngularVelocity = Vector3.new(
					random:NextNumber(-H.spin, H.spin),
					random:NextNumber(-H.spin, H.spin),
					random:NextNumber(-H.spin, H.spin)
				)
				TweenService:Create(part, TweenInfo.new(H.ripSeconds), { Transparency = 1 }):Play()
			end
		end
		Debris:AddItem(model, H.ripSeconds)
		print("[Royale] L'Œil arrache une cachette : " .. model.Name)
	end)
end

Roster.onBeforeTake(function(player: Roster.Actor)
	local spot = byPlayer[player]
	if spot then
		release(player, spot, false)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	local spot = byPlayer[player]
	if spot then
		local i = table.find(spot.occupants, player)
		if i then
			table.remove(spot.occupants, i)
		end
		spot.prompt.Enabled = not spot.ripping and #spot.occupants < spot.capacity
		byPlayer[player] = nil
	end
end)

return HidingService
