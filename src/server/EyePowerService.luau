--!strict
--[[
	EyePowerService — les pouvoirs de l'Oeil (CONCEPT.md, valide le 12
	novembre 2026) : un tire au sort au debut de chaque Regard, annonce a tous,
	garde jusqu'a la fin.

	Les pouvoirs qui changent des chiffres passent par le Regard que
	`regardFor` rend (EyePowers.apply), lu par MatchService et EyeService. Ceux
	qui font quelque chose a l'ouverture (l'eclair, le souffle) ou en continu
	(les empreintes) vivent ici.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local EyePowers = require(Royale:WaitForChild("EyePowers"))

local CombatService = require(script.Parent.CombatService)
local EyeService = require(script.Parent.EyeService)
local HidingService = require(script.Parent.HidingService)
local Roster = require(script.Parent.Roster)
local World = require(script.Parent.World)
local ZoneService = require(script.Parent.ZoneService)

local EyePowerService = {}

local P = Config.eyePowers
local L = P.list

local owned: { string } = {}
-- Le Regard joue avec ses pouvoirs, par numero : tire une fois par Regard,
-- pour que les faux departs et la rafale allongee ne changent pas en route.
local applied: { [number]: any } = {}
local random = Random.new()

type Print = { at: Vector3, born: number, part: BasePart }
local prints: { [Roster.Actor]: { Print } } = {}
local lastPrint: { [Roster.Actor]: number } = {}
local folder: Folder? = nil
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.RespectCanCollide = true

-- Config est en { r, g, b } et { x, y, z } : il se charge aussi dans les tests.
local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end
local PRINT_SIZE = Vector3.new(L.prints.size[1], L.prints.size[2], L.prints.size[3])

local function has(id: string): boolean
	return table.find(owned, id) ~= nil
end

local function u(): number
	return random:NextNumber()
end

function EyePowerService.owned(): { string }
	return table.clone(owned)
end

-- Le Regard `index` tel que l'Oeil le joue.
function EyePowerService.regardFor(index: number): any
	local cached = applied[index]
	if cached == nil then
		cached = EyePowers.apply(Config.regards[index], owned, L, u)
		applied[index] = cached
	end
	return cached
end

local function publish()
	local names: { string } = {}
	for _, id in owned do
		table.insert(names, L[id].name)
	end
	workspace:SetAttribute(P.listAttribute, if #names > 0 then table.concat(names, " · ") else nil)
end

-- Un nouveau Regard : un pouvoir de plus, annonce.
function EyePowerService.onRegard(index: number)
	local id = EyePowers.draw(L, owned, Config.regards[index], u())
	if id then
		table.insert(owned, id)
		local def = L[id]
		workspace:SetAttribute(
			P.announceAttribute,
			def.name .. "|" .. def.text .. "|" .. tostring(workspace:GetServerTimeNow())
		)
		print(string.format("[Royale] L'Oeil gagne : %s", def.name))
	end
	applied[index] = nil
	publish()
end

-- A decouvert : en vie, dans le cercle, pas cache, et une ligne de vue reelle.
local function exposed(regard: any): { Roster.Actor }
	local out: { Roster.Actor } = {}
	for _, actor in Roster.alive() do
		local root = Roster.rootOf(actor)
		local character = Roster.characterOf(actor)
		if
			root
			and character
			and not HidingService.isHidden(actor)
			and not ZoneService.outside(root.Position)
			and World.seenFactor(character, regard.slantElevation) > 0
		then
			table.insert(out, actor)
		end
	end
	return out
end

local function onBurst(regard: any)
	if regard.flashSeconds then
		for _, actor in exposed(regard) do
			local character = Roster.characterOf(actor)
			if character then
				local h = Instance.new("Highlight")
				h.Name = "RoyaleEclair"
				h.FillColor = rgb(L.flash.color)
				h.OutlineColor = rgb(L.flash.color)
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = character
				task.delay(regard.flashSeconds, function()
					h:Destroy()
				end)
			end
		end
	end
	if regard.windSpeed then
		-- Un seul vent par rafale, du meme cote pour tous : on le voit venir
		-- dans le meme sens que les autres.
		local a = random:NextNumber(0, math.pi * 2)
		local push = Vector3.new(
			math.cos(a) * regard.windSpeed,
			regard.windLift,
			math.sin(a) * regard.windSpeed
		)
		for _, actor in exposed(regard) do
			CombatService.push(actor, push)
		end
	end
end

local function printFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = P.folder
	f.Parent = workspace
	World.ignore(f)
	folder = f
	return f
end

-- La trace a remonter : la piste dont une trace est assez proche du
-- faisceau, et sa trace la plus recente.
local function trail(x: number, z: number): Vector3?
	local best, bestD = nil, L.prints.followRange * L.prints.followRange
	for _, list in prints do
		local near = false
		for _, p in list do
			local d = (p.at.X - x) ^ 2 + (p.at.Z - z) ^ 2
			if d <= bestD then
				near = true
				break
			end
		end
		if near and #list > 0 then
			best = list[#list].at
		end
	end
	return best
end

local function stepPrints()
	local now = os.clock()
	for actor, list in prints do
		while #list > 0 and now - list[1].born >= L.prints.seconds do
			list[1].part:Destroy()
			table.remove(list, 1)
		end
		if #list == 0 then
			prints[actor] = nil
		end
	end
	if not has("prints") then
		return
	end
	for _, actor in Roster.alive() do
		local root = Roster.rootOf(actor)
		if root == nil or HidingService.isHidden(actor) then
			continue
		end
		local v = root.AssemblyLinearVelocity
		if Vector3.new(v.X, 0, v.Z).Magnitude < Config.eye.runningSpeed then
			continue
		end
		if now - (lastPrint[actor] or 0) < L.prints.every then
			continue
		end
		-- Le sol juste sous ses pieds : pas de trace en l'air ni sur un toit
		-- au-dessus de lui.
		local character = Roster.characterOf(actor)
		groundParams.FilterDescendantsInstances = { character :: Instance, printFolder() }
		local hit =
			workspace:Raycast(root.Position, Vector3.new(0, -L.prints.probe, 0), groundParams)
		if hit == nil then
			continue
		end
		local ground = hit.Position
		lastPrint[actor] = now
		local part = Instance.new("Part")
		part.Name = "Empreinte"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Material = Enum.Material.Neon
		part.Color = rgb(L.prints.color)
		part.Size = PRINT_SIZE
		local look = Vector3.new(v.X, 0, v.Z).Unit
		part.CFrame = CFrame.lookAt(ground, ground + look) + Vector3.new(0, PRINT_SIZE.Y / 2, 0)
		part.Parent = printFolder()
		local list = prints[actor] or {}
		table.insert(list, { at = ground, born = now, part = part })
		prints[actor] = list
	end
end

function EyePowerService.reset()
	table.clear(owned)
	table.clear(applied)
	for _, list in prints do
		for _, p in list do
			p.part:Destroy()
		end
	end
	table.clear(prints)
	table.clear(lastPrint)
	workspace:SetAttribute(P.announceAttribute, nil)
	workspace:SetAttribute(P.listAttribute, nil)
end

function EyePowerService.start()
	EyeService.onBurst(onBurst)
	EyeService.setTrail(trail)
	RunService.Heartbeat:Connect(stepPrints)
end

return EyePowerService
