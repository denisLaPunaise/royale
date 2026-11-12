--!strict
--[[
	BotService — les bots qui completent la partie (CONCEPT.md, valide le 12
	novembre 2026 : invisibles, noms inventes, jouent a peu pres comme un
	joueur moyen, jamais plus faciles).

	Un bot est un personnage R15 dans Workspace.Participants, sous les memes
	regles que tout le monde : l'Oeil le voit par la meme ligne de vue, il entre
	dans les cachettes par le meme chemin que l'invite, il est aspire pareil.
	Il ne sait que ce qu'un joueur peut voir : ou sont les faisceaux, le
	cercle, l'Oeil ouvert ou non, les cachettes libres autour de lui, et sa
	propre jauge de mefiance (que l'ecran d'un joueur affiche aussi).

	Ce qu'il fait, a chaque reflexion :
	1. hors du cercle : rentrer ;
	2. l'Oeil ouvert (ou sur le point de) et un faisceau proche : courir a la
	   cachette libre la plus proche, ou s'eloigner du faisceau ;
	3. cache : rester un moment, partir avant d'etre flaire ;
	4. sinon : aller vers une cachette du prochain cercle, en marchant.
	Il reagit avec un temps humain, et se trompe parfois.
]]

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local HidingService = require(script.Parent.HidingService)
local Roster = require(script.Parent.Roster)
local World = require(script.Parent.World)
local ZoneService = require(script.Parent.ZoneService)

local BotService = {}

local B = Config.bots
local Mv = Config.movement
local random = Random.new()

type Bot = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	-- Le but en cours, et le chemin pour y aller.
	goal: Vector3?,
	waypoints: { PathWaypoint },
	index: number,
	computing: boolean,
	-- Ce qu'il veut y faire : se cacher dans `spot`, ou juste y aller.
	spot: Model?,
	running: boolean,
	-- Le temps de reaction : il ne reagit au danger qu'a partir de `reactAt`.
	reactAt: number,
	sawDanger: boolean,
	-- Cette ouverture-ci, il joue mal (reste dehors, se trompe).
	careless: boolean,
	lastBurstOpen: boolean,
	hiddenUntil: number,
	-- Pour savoir s'il est bloque.
	checkAt: number,
	checkFrom: Vector3,
	-- Combien de fois il s'est retrouve bloque sur ce but.
	stuck: number,
	-- Les cachettes qu'il evite un moment (inaccessibles pour lui).
	avoid: { [Model]: number },
}

local bots: { Bot } = {}
-- La cachette que chaque bot vise : deux bots ne courent pas a la meme.
local claimed: { [Model]: Bot } = {}
local folder: Folder? = nil
local thinking = false

local function participantsFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = B.folder
	f.Parent = workspace
	World.ignore(f)
	folder = f
	return f
end

-- Un avatar simple mais varie : peau, haut et bas de couleurs differentes.

local function makeModel(name: string): Model
	local description = Instance.new("HumanoidDescription")
	local tone = B.skins[random:NextInteger(1, #B.skins)]
	local skin = Color3.fromRGB(tone[1], tone[2], tone[3])
	description.HeadColor = skin
	description.LeftArmColor = skin
	description.RightArmColor = skin
	local top = Color3.fromHSV(
		random:NextNumber(),
		random:NextNumber(0.3, 0.8),
		random:NextNumber(0.3, 0.9)
	)
	local bottom = Color3.fromHSV(
		random:NextNumber(),
		random:NextNumber(0.1, 0.5),
		random:NextNumber(0.15, 0.6)
	)
	description.TorsoColor = top
	description.LeftLegColor = bottom
	description.RightLegColor = bottom
	local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	model.Name = name
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayName = name
	humanoid.WalkSpeed = Mv.walkSpeed
	return model
end

function BotService.clear()
	for _, bot in bots do
		bot.model:Destroy()
	end
	table.clear(bots)
	table.clear(claimed)
end

-- Cree `count` bots, poses a cote de `at()`. Rend leurs modeles.
function BotService.spawn(count: number, at: () -> Vector3): { Model }
	BotService.clear()
	local names = table.clone(B.names)
	for i = #names, 2, -1 do
		local j = random:NextInteger(1, i)
		names[i], names[j] = names[j], names[i]
	end
	local taken: { [string]: boolean } = {}
	for _, player in Players:GetPlayers() do
		taken[player.Name] = true
		taken[player.DisplayName] = true
	end
	local out: { Model } = {}
	for _, name in names do
		if #out >= count then
			break
		end
		if taken[name] then
			continue
		end
		local model = makeModel(name)
		model:PivotTo(CFrame.new(at()))
		model.Parent = participantsFolder()
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
		-- Le serveur les fait bouger : pas de proprietaire client.
		root:SetNetworkOwner(nil)
		table.insert(bots, {
			model = model,
			humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid,
			root = root,
			goal = nil,
			waypoints = {},
			index = 0,
			computing = false,
			spot = nil,
			running = false,
			reactAt = 0,
			sawDanger = false,
			careless = false,
			lastBurstOpen = false,
			hiddenUntil = 0,
			checkAt = 0,
			checkFrom = root.Position,
			stuck = 0,
			avoid = {},
		})
		table.insert(out, model)
	end
	return out
end

local function setGoal(bot: Bot, goal: Vector3, run: boolean, spot: Model?)
	bot.running = run
	bot.humanoid.WalkSpeed = if run then Mv.runSpeed else Mv.walkSpeed
	if bot.goal and (bot.goal - goal).Magnitude < B.arriveDistance and bot.spot == spot then
		return
	end
	if bot.spot and claimed[bot.spot] == bot then
		claimed[bot.spot] = nil
	end
	bot.goal = goal
	bot.spot = spot
	bot.stuck = 0
	if spot then
		claimed[spot] = bot
	end
	bot.waypoints = {}
	bot.index = 0
	if bot.computing then
		return
	end
	bot.computing = true
	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = B.agentRadius,
			AgentHeight = B.agentHeight,
			AgentCanJump = true,
		})
		local ok, err = pcall(function()
			path:ComputeAsync(bot.root.Position, goal)
		end)
		bot.computing = false
		if bot.goal ~= goal then
			return
		end
		if ok and path.Status == Enum.PathStatus.Success then
			bot.waypoints = path:GetWaypoints()
			bot.index = 1
		else
			-- Sans chemin (en plein champ, ou dans l'eau), tout droit.
			if not ok then
				warn("[Royale] Chemin de bot impossible : " .. tostring(err))
			end
			bot.waypoints = {}
			bot.index = 0
			bot.humanoid:MoveTo(goal)
		end
	end)
end

local function stop(bot: Bot)
	if bot.spot and claimed[bot.spot] == bot then
		claimed[bot.spot] = nil
	end
	bot.goal = nil
	bot.spot = nil
	bot.waypoints = {}
	bot.index = 0
	bot.humanoid:MoveTo(bot.root.Position)
end

local function follow(bot: Bot)
	local waypoint = bot.waypoints[bot.index]
	if waypoint == nil then
		return
	end
	local flat = Vector3.new(
		waypoint.Position.X - bot.root.Position.X,
		0,
		waypoint.Position.Z - bot.root.Position.Z
	)
	if flat.Magnitude < B.waypointReach then
		bot.index += 1
		waypoint = bot.waypoints[bot.index]
		if waypoint == nil then
			return
		end
	end
	if waypoint.Action == Enum.PathWaypointAction.Jump then
		bot.humanoid.Jump = true
	end
	bot.humanoid:MoveTo(waypoint.Position)
end

local function beams(): { Vector3 }
	local out: { Vector3 } = {}
	local f = workspace:FindFirstChild(Config.eye.beamsFolder)
	if f then
		for _, v in f:GetAttributes() do
			if typeof(v) == "Vector3" then
				table.insert(out, Vector3.new(v.X, 0, v.Z))
			end
		end
	end
	return out
end

local function nearestFreeSpot(
	bot: Bot,
	from: Vector3,
	radius: number,
	inside: Vector3?
): { model: Model, at: Vector3 }?
	local best = nil
	local bestD = radius
	local now = os.clock()
	for _, spot in HidingService.freeSpots() do
		local owner = claimed[spot.model]
		if (owner and owner ~= bot) or (bot.avoid[spot.model] or 0) > now then
			continue
		end
		local d = (spot.at - from).Magnitude
		if inside then
			-- `inside` : (x, rayon, z) d'un cercle ou il faut rester.
			local dx, dz = spot.at.X - inside.X, spot.at.Z - inside.Z
			if dx * dx + dz * dz > inside.Y * inside.Y then
				continue
			end
		end
		if d < bestD then
			best, bestD = spot, d
		end
	end
	return best
end

-- `circle` : (x, rayon, z).
local function insideCircle(circle: Vector3, at: Vector3): boolean
	local dx, dz = at.X - circle.X, at.Z - circle.Z
	return dx * dx + dz * dz <= circle.Y * circle.Y
end

-- A l'abri du regard, ici ? La meme ligne de vue que l'Oeil (tete debout).
local function covered(at: Vector3): boolean
	return World.visibility(at + Vector3.new(0, B.headHeight, 0), { participantsFolder() }) <= 0
end

-- Un coin hors de la vue de l'Oeil autour de `from` (derriere un mur, sous un
-- toit), dans le cercle : ce qu'un joueur trouve en regardant ou est l'Oeil.
local function coverNear(from: Vector3, circle: Vector3?): Vector3?
	for ring = 1, B.coverRings do
		local radius = B.coverRadius * ring / B.coverRings
		local start = random:NextNumber(0, math.pi * 2)
		for k = 0, B.coverSamples - 1 do
			local a = start + k / B.coverSamples * math.pi * 2
			local x, z = from.X + math.cos(a) * radius, from.Z + math.sin(a) * radius
			local ground = World.ground(x, z, { participantsFolder() })
			if ground and math.abs(ground.Y - from.Y) < B.coverClimb then
				if (circle == nil or insideCircle(circle, ground)) and covered(ground) then
					return ground
				end
			end
		end
	end
	return nil
end

local function circleOf(attribute: string): Vector3?
	local v = workspace:GetAttribute(attribute)
	return if typeof(v) == "Vector3" then v else nil
end

local function think(bot: Bot, now: number)
	if not Roster.isAlive(bot.model) or bot.model.Parent == nil then
		return
	end
	local position = bot.root.Position
	local open = workspace:GetAttribute(Config.match.eyeOpenAttribute) == true
	local warning = workspace:GetAttribute(Config.eye.warningAttribute) == true
	local current = circleOf(Config.zone.attribute)
	local nextCircle = circleOf(Config.zone.nextAttribute)

	-- Une nouvelle ouverture : cette fois-ci, joue-t-il mal ?
	if open and not bot.lastBurstOpen then
		bot.careless = random:NextNumber() < B.mistakeChance
	end
	bot.lastBurstOpen = open

	-- CACHE : rester, puis partir avant d'etre flaire.
	if HidingService.isHidden(bot.model) then
		local suspicion = bot.model:GetAttribute(Config.suspicion.attribute)
		local flaired = typeof(suspicion) == "number" and suspicion >= B.leaveSuspicion
		local outside = ZoneService.outside(position)
		-- Le prochain cercle annonce et la cachette dehors : partir pendant
		-- que l'Oeil est ferme (un joueur voit le trait blanc, lui aussi).
		local leaving = nextCircle ~= nil
			and not insideCircle(nextCircle, position)
			and not open
			and not warning
		if
			flaired
			or outside
			or leaving
			or (not open and not warning and now >= bot.hiddenUntil)
		then
			HidingService.leave(bot.model)
			bot.goal = nil
		end
		return
	end

	-- Le danger : un faisceau proche, l'Oeil ouvert ou sur le point de l'etre.
	local nearestBeam: Vector3? = nil
	local beamD = math.huge
	for _, b in beams() do
		local d = (Vector3.new(position.X, 0, position.Z) - b).Magnitude
		if d < beamD then
			nearestBeam, beamD = b, d
		end
	end
	local danger = (open and beamD < B.dangerDistance) or warning
	if danger and not bot.sawDanger then
		bot.sawDanger = true
		bot.reactAt = now + random:NextNumber(B.reactionMin, B.reactionMax)
	elseif not danger then
		bot.sawDanger = false
	end

	-- 1. Hors du cercle : rentrer, en courant.
	if current and ZoneService.outside(position) then
		local center = Vector3.new(current.X, position.Y, current.Z)
		local outward = position - center
		local target = center + outward.Unit * current.Y * B.insideFraction
		setGoal(bot, target, true, nil)
	-- 2. Le danger : se cacher, ou fuir.
	elseif danger and now >= bot.reactAt and not bot.careless then
		-- Une cachette au plus pres ; sinon un coin a l'abri tout pres ; sinon
		-- une cachette plus loin dans le cercle, en courant ; sinon fuir.
		local spot = nearestFreeSpot(bot, position, B.hideSearchRadius, current)
		local shelter = if spot == nil and bot.goal == nil
			then coverNear(position, current)
			else nil
		spot = spot
			or (if shelter == nil then nearestFreeSpot(bot, position, math.huge, current) else nil)
		if spot then
			setGoal(bot, spot.at, true, spot.model)
		elseif covered(position) then
			stop(bot)
		elseif shelter then
			setGoal(bot, shelter, true, nil)
		elseif nearestBeam then
			local away = Vector3.new(position.X - nearestBeam.X, 0, position.Z - nearestBeam.Z)
			if away.Magnitude < 1 then
				away = Vector3.new(random:NextNumber(-1, 1), 0, random:NextNumber(-1, 1))
			end
			local target = position + away.Unit * B.dangerDistance
			if current then
				local dx, dz = target.X - current.X, target.Z - current.Z
				local d = math.sqrt(dx * dx + dz * dz)
				if d > current.Y then
					local r = current.Y * B.insideFraction
					target = Vector3.new(current.X + dx / d * r, target.Y, current.Z + dz / d * r)
				end
			end
			setGoal(bot, target, true, nil)
		end
	-- 3. Au calme : vers une cachette du prochain cercle (ou de l'actuel). Un
	-- but hors du prochain cercle ne vaut plus rien.
	elseif
		bot.goal == nil
		or (nextCircle ~= nil and not insideCircle(nextCircle, bot.goal :: Vector3))
	then
		local area = nextCircle or current
		local spot = nearestFreeSpot(bot, position, math.huge, area)
		if spot then
			setGoal(bot, spot.at, false, spot.model)
		elseif not covered(position) then
			-- Plus de cachette libre : au moins un coin a l'abri.
			local shelter = coverNear(position, area)
			if shelter then
				setGoal(bot, shelter, false, nil)
			end
		end
	end

	-- Arrive a sa cachette : y entrer (par le chemin de l'invite).
	if bot.spot and bot.goal and (bot.goal - position).Magnitude < Config.hiding.promptDistance then
		local spot = bot.spot
		if HidingService.tryEnter(bot.model, spot) then
			bot.hiddenUntil = now + random:NextNumber(B.hideMinSeconds, B.hideMaxSeconds)
		end
		stop(bot)
		return
	end
	if bot.goal and (bot.goal - position).Magnitude < B.arriveDistance then
		stop(bot)
		return
	end

	-- Bloque : recalculer.
	if now >= bot.checkAt then
		if
			bot.goal
			and (position - bot.checkFrom).Magnitude < B.stuckDistance
			and not bot.computing
		then
			local goal, run, spot = bot.goal :: Vector3, bot.running, bot.spot
			local tries = bot.stuck + 1
			bot.humanoid.Jump = true
			if tries >= B.stuckTries then
				-- Toujours bloque : on renonce a ce but (et a cette cachette).
				if spot then
					bot.avoid[spot] = now + B.avoidSeconds
				end
				stop(bot)
			else
				bot.goal = nil
				setGoal(bot, goal, run, spot)
				bot.stuck = tries
			end
		end
		bot.checkAt = now + B.stuckSeconds
		bot.checkFrom = position
	end
	follow(bot)
end

function BotService.start()
	if thinking then
		return
	end
	thinking = true
	task.spawn(function()
		while true do
			task.wait(B.thinkSeconds)
			local now = os.clock()
			local playing = workspace:GetAttribute(Config.match.phaseAttribute) == "Partie"
			if playing then
				for _, bot in bots do
					local ok, err = pcall(think, bot, now)
					if not ok then
						warn("[Royale] Un bot s'est trompé : " .. tostring(err))
					end
				end
			end
		end
	end)
end

return BotService
