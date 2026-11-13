--!strict
--[[
	SquadService — les escouades (CONCEPT.md, valide le 12 novembre 2026).

	Chaque participant porte le numero de son equipe (attribut `Equipe`). Les
	coequipiers se voient a travers les murs (l'ecran, TeamView), se relevent
	et se donnent des objets (les invites d'ItemService), ne sont jamais
	ensemble dans un duel du Ventre, et les objets ne les touchent pas. Les
	coups entre coequipiers marchent (valide). Une equipe gagne quand elle est
	la seule a avoir quelqu'un en vie.

	Sauve du Ventre, on revient pres d'un coequipier en vie, dans un cocon
	qu'il ouvre en 3 coups. Le cocon signale sa place a l'Oeil apres 8 s : si
	un faisceau le touche avant qu'il soit ouvert, c'est la capture
	definitive.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local Squads = require(Royale:WaitForChild("Squads"))

local CombatService = require(script.Parent.CombatService)
local EyeService = require(script.Parent.EyeService)
local ChallengeService = require(script.Parent.ChallengeService)
local Roster = require(script.Parent.Roster)
local ShopService = require(script.Parent.ShopService)
local World = require(script.Parent.World)

local SquadService = {}

local SQ = Config.squads
local CC = SQ.cocoon

type Cocoon = { actor: Roster.Actor, part: BasePart, hits: number, born: number, id: string }

local teams: { [Roster.Actor]: number } = {}
-- Pour les recompenses : quand chaque equipe a eu quelqu'un en jeu pour la
-- derniere fois, et le dernier Regard ou chacun etait en jeu.
local teamLastIn: { [number]: number } = {}
local lastRegard: { [Roster.Actor]: number } = {}
local cocoons: { Cocoon } = {}
local startTeams = 0
local serial = 0
local random = Random.new()

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Le mode de la partie en cours (choisi au salon).
local mode = SQ.mode

function SquadService.setMode(newMode: string)
	if SQ.sizes[newMode] then
		mode = newMode
		workspace:SetAttribute(SQ.modeAttribute, newMode)
	end
end

function SquadService.size(): number
	return SQ.sizes[mode]
end

-- Repartit les participants en equipes et le publie : les groupes du salon
-- restent ensemble, un joueur sans groupe est un groupe a lui seul, les bots
-- completent.
function SquadService.assign(actors: { Roster.Actor }, groups: { { Player } })
	table.clear(teams)
	local byId: { [string]: Roster.Actor } = {}
	local grouped: { [Roster.Actor]: boolean } = {}
	local lists: { { string } } = {}
	for _, group in groups do
		local list: { string } = {}
		for _, player in group do
			if table.find(actors, player) then
				grouped[player] = true
				table.insert(list, Roster.idOf(player))
			end
		end
		if #list > 0 then
			table.insert(lists, list)
		end
	end
	local bots: { string } = {}
	for _, actor in actors do
		local id = Roster.idOf(actor)
		byId[id] = actor
		if actor:IsA("Player") then
			if not grouped[actor] then
				table.insert(lists, { id })
			end
		else
			table.insert(bots, id)
		end
	end
	local map = Squads.assignGroups(SquadService.size(), lists, bots)
	local seen: { [number]: boolean } = {}
	startTeams = 0
	for id, team in map do
		local actor = byId[id]
		teams[actor] = team
		actor:SetAttribute(SQ.attribute, team)
		if not seen[team] then
			seen[team] = true
			startTeams += 1
		end
	end
end

function SquadService.teamOf(actor: Roster.Actor): number?
	return teams[actor]
end

-- Deux participants differents de la meme equipe (jamais en solo).
function SquadService.allies(a: Roster.Actor?, b: Roster.Actor?): boolean
	if a == nil or b == nil or a == b or SquadService.size() <= 1 then
		return false
	end
	return teams[a] ~= nil and teams[a] == teams[b]
end

-- La partie est-elle finie ? (une seule equipe encore en vie)
function SquadService.over(): boolean
	local alive: { number } = {}
	for _, actor in Roster.alive() do
		table.insert(alive, teams[actor] or 0)
	end
	return Squads.over(alive, startTeams)
end

-- Ceux qui ont gagne : l'equipe du dernier en vie, tous ses membres.
function SquadService.winners(): { Roster.Actor }
	local last = Roster.alive()[1]
	if last == nil then
		return {}
	end
	local team = teams[last]
	local out: { Roster.Actor } = {}
	for actor, t in teams do
		-- Toute l'equipe, meme les aspires (un bot aspire n'a plus de modele
		-- dans le monde, mais garde son nom ; vu en partie : seul le survivant
		-- etait annonce).
		if t == team then
			table.insert(out, actor)
		end
	end
	if #out == 0 then
		out = { last }
	end
	return out
end

local function open(cocoon: Cocoon, taken: boolean)
	local i = table.find(cocoons, cocoon)
	if i then
		table.remove(cocoons, i)
	end
	cocoon.part:Destroy()
	cocoon.actor:SetAttribute(SQ.cocoonAttribute, nil)
	local root = Roster.rootOf(cocoon.actor)
	if root and not taken then
		root.Anchored = false
	end
end

local function onCocoonHit(id: string, by: Roster.Actor, _push: Vector3)
	for _, cocoon in cocoons do
		if cocoon.id == id and SquadService.allies(by, cocoon.actor) then
			cocoon.hits += 1
			if cocoon.hits >= CC.hits then
				print(
					string.format(
						"[Royale] %s ouvre le cocon de %s",
						Roster.nameOf(by),
						Roster.nameOf(cocoon.actor)
					)
				)
				open(cocoon, false)
				ChallengeService.record(by, "cocoon")
			end
			return
		end
	end
end

-- Sauve du Ventre : un cocon pres d'un coequipier en vie. Rend faux s'il
-- n'y en a pas (il revient alors seul, au hasard).
function SquadService.cocoon(actor: Roster.Actor): boolean
	if SquadService.size() <= 1 then
		return false
	end
	local mate = nil
	for _, other in Roster.alive() do
		if SquadService.allies(actor, other) and Roster.rootOf(other) then
			mate = other
			break
		end
	end
	if mate == nil then
		return false
	end
	local near = (Roster.rootOf(mate) :: BasePart).Position
	local a = random:NextNumber(0, math.pi * 2)
	local x, z = near.X + math.cos(a) * CC.offset, near.Z + math.sin(a) * CC.offset
	local ground = World.ground(x, z) or near
	serial += 1
	local size = Vector3.new(CC.size[1], CC.size[2], CC.size[3])
	local p = Instance.new("Part")
	p.Name = "Cocon"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(size.X, size.X, size.X)
	p.Material = Enum.Material.Slate
	-- La couleur de cocon portee (un cosmetique), sinon la couleur de base.
	local skin = if actor:IsA("Player") then ShopService.equipped(actor, "cocoon") else nil
	p.Color = rgb(if skin then skin.color else CC.color)
	p.Anchored = true
	p.CanCollide = true
	-- Une boule etiree, debout : une sphere prend le plus petit cote, on
	-- l'allonge donc par un maillage.
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, size.Y / size.X, 1)
	mesh.Parent = p
	p.CFrame = CFrame.new(ground + Vector3.new(0, size.Y / 2, 0))
	local light = Instance.new("PointLight")
	light.Color = rgb(CC.glow)
	light.Range = CC.lightRange
	light.Brightness = CC.lightBrightness
	light.Parent = p
	p.Parent = workspace
	local cocoon: Cocoon =
		{ actor = actor, part = p, hits = 0, born = os.clock(), id = "cocon:" .. serial }
	table.insert(cocoons, cocoon)
	actor:SetAttribute(SQ.cocoonAttribute, true)
	Roster.revive(actor)
	local character = Roster.characterOf(actor)
	local root = Roster.rootOf(actor)
	if character and root then
		character:PivotTo(p.CFrame)
		root.Anchored = true
	end
	-- Apres 8 s, l'Oeil sait ou il est.
	task.delay(CC.eyeDelay, function()
		if table.find(cocoons, cocoon) then
			EyeService.lure(function()
				return if table.find(cocoons, cocoon) then p.Position else nil
			end, CC.lureSeconds, false)
		end
	end)
	print(
		string.format(
			"[Royale] %s revient dans un cocon pres de %s",
			Roster.nameOf(actor),
			Roster.nameOf(mate)
		)
	)
	return true
end

-- Un faisceau allume touche-t-il ce point ? (les faisceaux publies par
-- l'Oeil : x, rayon, z)
local function lit(at: Vector3): boolean
	local folder = workspace:FindFirstChild(Config.eye.beamsFolder)
	if folder == nil then
		return false
	end
	for _, value in folder:GetAttributes() do
		if typeof(value) == "Vector3" then
			local dx, dz = at.X - value.X, at.Z - value.Z
			if dx * dx + dz * dz <= value.Y * value.Y then
				return true
			end
		end
	end
	return false
end

local function step()
	for _, cocoon in table.clone(cocoons) do
		if not Roster.isAlive(cocoon.actor) or cocoon.part.Parent == nil then
			open(cocoon, true)
		elseif lit(cocoon.part.Position) then
			print(
				string.format(
					"[Royale] Le faisceau atteint le cocon de %s",
					Roster.nameOf(cocoon.actor)
				)
			)
			open(cocoon, true)
			Roster.take(cocoon.actor)
		end
	end
end

-- A chaque pas de la partie : qui est encore en jeu (en vie, ou au Ventre
-- qui le garde), a ce Regard.
function SquadService.track(regard: number, inGame: (Roster.Actor) -> boolean)
	local t = os.clock()
	for actor, team in teams do
		if inGame(actor) then
			teamLastIn[team] = t
			lastRegard[actor] = regard
		end
	end
end

-- La place de son equipe : 1 pour la derniere en jeu, puis par ordre de
-- sortie.
function SquadService.placeOf(actor: Roster.Actor): number?
	local team = teams[actor]
	local mine = team and teamLastIn[team]
	if mine == nil then
		return nil
	end
	local place = 1
	for other, last in teamLastIn do
		if other ~= team and last > mine then
			place += 1
		end
	end
	return place
end

function SquadService.regardOf(actor: Roster.Actor): number
	return lastRegard[actor] or 0
end

-- Le cocon d'un coequipier a portee (pour les bots qui viennent l'ouvrir).
function SquadService.cocoonNear(actor: Roster.Actor, at: Vector3, range: number): BasePart?
	local best, bestD = nil, range
	for _, cocoon in cocoons do
		if SquadService.allies(actor, cocoon.actor) then
			local d = (cocoon.part.Position - at).Magnitude
			if d <= bestD then
				best, bestD = cocoon.part, d
			end
		end
	end
	return best
end

function SquadService.clear()
	table.clear(teamLastIn)
	table.clear(lastRegard)
	for _, cocoon in table.clone(cocoons) do
		open(cocoon, true)
	end
	for actor in teams do
		if actor.Parent then
			actor:SetAttribute(SQ.attribute, nil)
		end
	end
	table.clear(teams)
	startTeams = 0
end

function SquadService.start()
	CombatService.addCreatures(function()
		local out: { CombatService.Creature } = {}
		for _, cocoon in cocoons do
			table.insert(out, { id = cocoon.id, root = cocoon.part, onHit = onCocoonHit })
		end
		return out
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local ok, err = pcall(step)
			if not ok then
				warn("[Royale] Cocons : " .. tostring(err))
			end
		end
	end)
end

return SquadService
