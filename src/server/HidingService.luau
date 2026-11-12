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
local World = require(script.Parent.World)

local HidingService = {}

local W = Config.world
local H = Config.hiding

export type Spot = {
	model: Model,
	inside: BasePart,
	exits: { BasePart },
	solid: boolean,
	occupant: Roster.Actor?,
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
}

local spots: { Spot } = {}
local byPlayer: { [Roster.Actor]: Spot } = {}
local placed: Folder? = nil
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

local function release(player: Roster.Actor, spot: Spot, grace: boolean)
	byPlayer[player] = nil
	spot.occupant = nil
	spot.prompt.Enabled = not spot.ripping
	player:SetAttribute(H.hiddenAttribute, nil)
	local root = Roster.rootOf(player)
	if root then
		local exit = if #spot.exits > 0 then nearestExit(spot, root.Position) else spot.inside
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
end

local function enter(player: Roster.Actor, spot: Spot)
	if
		not Roster.isAlive(player)
		or spot.occupant
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
	spot.occupant = player
	spot.mark = burstSerial
	spot.prompt.Enabled = false
	byPlayer[player] = spot
	player:SetAttribute(H.hiddenAttribute, spot.model.Name)
	root.Anchored = true
	root.CFrame = spot.inside.CFrame
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
	prompt.ActionText = "Se cacher"
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
		occupant = nil,
		bell = false,
		trap = false,
		barricadedUntil = 0,
		fake = false,
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
	if placed then
		placed:Destroy()
		placed = nil
	end
	burstSerial = 0
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
		if not anchor:IsA("BasePart") then
			continue
		end
		local prefab = anchor:GetAttribute("Prefab")
		if typeof(prefab) ~= "string" then
			continue
		end
		local variants = variantsOf(prefab)
		if #variants == 0 then
			continue
		end
		local template = variants[random:NextInteger(1, #variants)]
		local model = template:Clone()
		local socle = model.PrimaryPart
		if socle == nil then
			model:Destroy()
			continue
		end
		local offset = socle.CFrame:ToObjectSpace(model:GetPivot())
		model:PivotTo(anchor.CFrame * offset)
		model.Name = prefab
		model.Parent = folder
		if makeSpot(model, false) then
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
	print(string.format("[Royale] %d cachettes posées, plus les cachettes solides", count))
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

function HidingService.leave(player: Roster.Actor)
	local spot = byPlayer[player]
	if spot then
		release(player, spot, false)
	end
end

-- Une nouvelle ouverture de l'Oeil commence.
function HidingService.setBurst(serial: number)
	burstSerial = serial
end

-- Les cachettes que l'Oeil peut arracher maintenant : marquees AVANT cette
-- ouverture, il y a au plus `markBursts` ouvertures. Les occupees d'abord,
-- celles dont l'occupant est flaire (`flagged`) avant tout.
function HidingService.ripCandidates(
	flagged: { [Roster.Actor]: boolean },
	solidFalls: boolean
): { Spot }
	local out: { Spot } = {}
	for _, spot in spots do
		local mark = spot.mark
		if
			(solidFalls or not spot.solid)
			and not spot.ripping
			and mark ~= nil
			and mark < burstSerial
			and burstSerial - mark <= H.markBursts
		then
			table.insert(out, spot)
		end
	end
	local function rank(spot: Spot): number
		local occupant = spot.occupant
		if occupant and flagged[occupant] then
			return 0
		elseif occupant then
			return 1
		end
		return 2
	end
	table.sort(out, function(a, b)
		local ra, rb = rank(a), rank(b)
		if ra ~= rb then
			return ra < rb
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
		if spot.occupant == nil and not spot.ripping and spot.model.Parent then
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

-- Deloge l'occupant (la poussee sur un abri) : il sort, sans le repit de
-- l'arrachage (c'est un joueur qui l'a trouve, pas l'Oeil). Rend qui est sorti.
function HidingService.evict(spot: Spot): Roster.Actor?
	local occupant = spot.occupant
	if occupant and os.clock() < spot.barricadedUntil then
		return nil
	end
	if occupant then
		release(occupant, spot, false)
	end
	return occupant
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
	if spot.solid then
		-- Une cachette solide fait partie de la carte : elle ne s'envole pas,
		-- elle s'effondre (on en est chasse, et on n'y rentre plus).
		spot.ripping = true
		spot.prompt.Enabled = false
		local occupant = spot.occupant
		if occupant then
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
		local occupant = spot.occupant
		if occupant then
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
		spot.occupant = nil
		spot.prompt.Enabled = not spot.ripping
		byPlayer[player] = nil
	end
end)

return HidingService
