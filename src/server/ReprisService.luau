--!strict
--[[
	ReprisService — ceux que l'Oeil a pris, et qu'il recrache (CONCEPT.md,
	Contre le camping).

	A chaque fermeture de l'Oeil (au Regard 5, a chaque rafale), il en
	recrache quelques-uns, de preference pres des joueurs caches. Au debut de
	chaque Regard, il en re-aspire la moitie. Quatre sortes :

	- l'Errant erre ; s'il te voit, il crie et un faisceau vient ou tu etais ;
	- le Rampant sent ceux qui sont caches tout pres et les arrache de leur
	  cachette ;
	- le Hurleur hurle : l'Oeil entend, les Repris proches accourent ;
	- le Coureur, rapide et fragile, grogne puis plaque (K.O. 2 s).

	Ils ne tuent jamais : c'est toujours l'Oeil qui aspire, par une vraie
	ligne de vue. Ils voient comme lui (World.visibility, depuis leur tete) :
	la fumee et les murs les aveuglent, une cachette fermee les trompe (sauf
	le Rampant). Repris de Survivor : le corps, le crane, les animations.
]]

local AssetService = game:GetService("AssetService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local Horde = require(Royale:WaitForChild("Horde"))

local CombatService = require(script.Parent.CombatService)
local EyeService = require(script.Parent.EyeService)
local HidingService = require(script.Parent.HidingService)
local ItemService = require(script.Parent.ItemService)
local ChallengeService = require(script.Parent.ChallengeService)
local Roster = require(script.Parent.Roster)
local Sfx = require(script.Parent.Sfx)
local World = require(script.Parent.World)
local ZoneService = require(script.Parent.ZoneService)

local ReprisService = {}

local R = Config.repris

type Agent = {
	id: string,
	kindId: string,
	kind: any,
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	head: BasePart,
	moveTrack: AnimationTrack?,
	idleTrack: AnimationTrack?,
	steps: Sound?,
	hits: number,
	ready: boolean,
	dying: boolean,
	target: Roster.Actor?,
	lastSeen: number,
	lastSeenAt: Vector3?,
	lead: Vector3?,
	roamTo: Vector3?,
	lastCry: number,
	windupUntil: number,
	lastTackle: number,
	evictSince: number,
	restUntil: number,
	waypoints: { PathWaypoint },
	waypointIndex: number,
	pathGoal: Vector3?,
	lastPath: number,
	pathing: boolean,
	stuckFrom: Vector3,
	stuckSince: number,
	sidestepTo: Vector3?,
	sidestepUntil: number,
}

local agents: { Agent } = {}
local templates: { [string]: Model } = {}
local folder: Folder? = nil
local skull: MeshPart? = nil
local random = Random.new()
local serial = 0
local pathWarned = false

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function getFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = R.folder
	f.Parent = workspace
	-- L'Oeil voit a travers eux : ce sont ses yeux, pas des murs.
	World.ignore(f)
	folder = f
	return f
end

-- Le crane genere, charge une fois. Echec : on le dit, le corps reste sans.
local function loadSkull()
	local ok, result = pcall(function()
		return AssetService:CreateMeshPartAsync(Content.fromUri(R.headMesh))
	end)
	if ok then
		skull = result
	else
		warn("[Royale] Crane des Repris introuvable : " .. tostring(result))
	end
end

local function weld(to: BasePart, part: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
end

local function glowingEye(model: Model, to: BasePart, at: CFrame, size: number, color: { number })
	local eye = Instance.new("Part")
	eye.Name = "Oeil"
	eye.Shape = Enum.PartType.Ball
	eye.Size = Vector3.one * size
	eye.Material = Enum.Material.Neon
	eye.Color = rgb(color)
	eye.CanCollide = false
	eye.CanQuery = false
	eye.CanTouch = false
	eye.Massless = true
	eye.CFrame = to.CFrame * at
	weld(to, eye)
	eye.Parent = model
end

-- Un corps de Repris : un humain de cendre, decharne, une tete de crane aux
-- orbites qui luisent (repris de Survivor).
local function buildTemplate(look: any): Model
	local description = Instance.new("HumanoidDescription")
	description.HeightScale = look.height
	description.WidthScale = look.width
	description.DepthScale = look.depth
	description.HeadScale = 0.85
	description.BodyTypeScale = 0
	description.ProportionScale = 0
	local ash = rgb(R.ash)
	description.HeadColor = ash
	description.TorsoColor = ash:Lerp(Color3.new(0, 0, 0), 0.15)
	description.LeftArmColor = ash
	description.RightArmColor = ash
	description.LeftLegColor = ash:Lerp(Color3.new(0, 0, 0), 0.2)
	description.RightLegColor = ash:Lerp(Color3.new(0, 0, 0), 0.2)
	local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	model.Name = "Repris"
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Material = Enum.Material.Basalt
		end
	end
	local head = model:FindFirstChild("Head") :: BasePart
	for _, child in head:GetDescendants() do
		if child:IsA("Decal") or child:IsA("FaceControls") then
			child:Destroy()
		end
	end
	if head:IsA("MeshPart") then
		head.TextureID = ""
	end
	local face: BasePart = head
	if skull then
		local piece = skull:Clone()
		piece.Name = "Crane"
		piece.Size = piece.Size * (head.Size.X * 1.05 / piece.Size.X)
		piece.TextureID = ""
		piece.Material = Enum.Material.Basalt
		piece.Color = ash
		piece.Anchored = false
		piece.CanCollide = false
		piece.CanQuery = false
		piece.CanTouch = false
		piece.Massless = true
		piece.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.1, 0)
		weld(head, piece)
		piece.Parent = model
		head.Transparency = 1
		face = piece
	end
	if look.bigEye then
		glowingEye(
			model,
			face,
			CFrame.new(0, face.Size.Y * 0.08, -face.Size.Z * 0.4),
			face.Size.X * 0.38,
			look.bigEye
		)
	elseif look.eyes then
		for _, side in { -1, 1 } do
			glowingEye(
				model,
				face,
				CFrame.new(side * face.Size.X * 0.2, face.Size.Y * 0.08, -face.Size.Z * 0.36),
				face.Size.X * 0.13,
				look.eyes
			)
		end
	end
	local torso = model:FindFirstChild("UpperTorso") :: BasePart?
	if torso then
		local smoke = Instance.new("Smoke")
		smoke.Color = Color3.fromRGB(30, 28, 28)
		smoke.Opacity = 0.12
		smoke.Size = 1.2
		smoke.RiseVelocity = 1.5
		smoke.Parent = torso
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	-- Ils ne meurent pas comme un humanoide : les coups se comptent a part.
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.BreakJointsOnDeath = false
	if look.scale ~= 1 then
		model:ScaleTo(look.scale)
	end
	return model
end

local function templateFor(kindId: string): Model
	local cached = templates[kindId]
	if cached == nil then
		cached = buildTemplate(R.kinds[kindId].look)
		templates[kindId] = cached
	end
	return cached
end

local function remove(agent: Agent)
	local index = table.find(agents, agent)
	if index then
		table.remove(agents, index)
	end
	agent.model:Destroy()
end

-- Mort ou re-aspire : il s'efface, ou il remonte vers l'Oeil.
local function vanish(agent: Agent, rise: boolean)
	if agent.dying then
		return
	end
	agent.dying = true
	for _, part in agent.model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			if not rise then
				TweenService:Create(part, TweenInfo.new(1.2), { Transparency = 1 }):Play()
			end
		end
	end
	if rise then
		agent.root.Anchored = true
		TweenService:Create(
			agent.root,
			TweenInfo.new(R.riseSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = agent.root.CFrame + Vector3.new(0, R.dropHeight, 0) }
		):Play()
	end
	task.delay(if rise then R.riseSeconds else 1.3, function()
		remove(agent)
	end)
end

local function onHit(id: string, by: Roster.Actor, push: Vector3)
	for _, agent in agents do
		if agent.id == id and not agent.dying then
			agent.hits += 1
			local flash = Instance.new("Highlight")
			flash.FillColor = Color3.fromRGB(240, 230, 220)
			flash.FillTransparency = 0.4
			flash.OutlineTransparency = 1
			flash.Parent = agent.model
			task.delay(0.12, function()
				flash:Destroy()
			end)
			if agent.ready and not agent.root.Anchored then
				agent.root.AssemblyLinearVelocity = push * R.hitPush
			end
			if agent.hits >= agent.kind.hits then
				-- Un Repris tue lache un objet commun (CONCEPT.md).
				ItemService.dropCommon(agent.root.Position)
				ChallengeService.record(by, "repris")
				print(string.format("[Royale] Un %s est detruit", agent.kind.name))
				vanish(agent, false)
			end
			return
		end
	end
end

-- Ou poser un Repris pres de `near` : sur le sol, dans le cercle.
local function dropPoint(near: Vector3): Vector3?
	for _ = 1, 8 do
		local a = random:NextNumber(0, math.pi * 2)
		local d = random:NextNumber(R.spawnMin, R.spawnMax)
		local x, z = near.X + math.cos(a) * d, near.Z + math.sin(a) * d
		local at = Vector3.new(x, near.Y, z)
		if not ZoneService.outside(at) then
			local ground = World.ground(x, z, { getFolder() })
			if ground and math.abs(ground.Y - near.Y) < 30 then
				return ground
			end
		end
	end
	return nil
end

local function spawnAgent(kindId: string, at: Vector3)
	local kind = R.kinds[kindId]
	local model = templateFor(kindId):Clone()
	serial += 1
	model.Name = kind.name
	model:SetAttribute(R.kindAttribute, kindId)
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local head = model:FindFirstChild("Head") :: BasePart
	local standing = CFrame.new(at + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0))
		* CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
	model:PivotTo(standing + Vector3.new(0, R.dropHeight, 0))
	root.Anchored = true
	humanoid.WalkSpeed = kind.speed
	-- La trainee de la chute, visible de tous (CONCEPT.md).
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 1.2
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 80, 40), Color3.fromRGB(40, 20, 20))
	trail.LightEmission = 0.8
	trail.WidthScale = NumberSequence.new(3, 0)
	trail.Parent = root
	model.Parent = getFolder()

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator == nil then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local function load(id: number): AnimationTrack?
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. id
		local ok, track = pcall(function()
			return (animator :: Animator):LoadAnimation(animation)
		end)
		if not ok then
			warn("[Royale] Animation de Repris : " .. tostring(track))
			return nil
		end
		return track
	end
	local moveTrack =
		load(if kind.speed > Config.movement.walkSpeed then R.animations.run else R.animations.walk)
	local idleTrack = load(R.animations.idle)
	if idleTrack then
		idleTrack:Play()
	end
	local agent: Agent = {
		id = "repris:" .. serial,
		kindId = kindId,
		kind = kind,
		model = model,
		humanoid = humanoid,
		root = root,
		head = head,
		moveTrack = moveTrack,
		idleTrack = idleTrack,
		steps = nil,
		hits = 0,
		ready = false,
		dying = false,
		target = nil,
		lastSeen = -math.huge,
		lastSeenAt = nil,
		lead = nil,
		roamTo = nil,
		lastCry = -math.huge,
		windupUntil = 0,
		lastTackle = -math.huge,
		evictSince = 0,
		restUntil = 0,
		waypoints = {},
		waypointIndex = 0,
		pathGoal = nil,
		lastPath = 0,
		pathing = false,
		stuckFrom = at,
		stuckSince = os.clock(),
		sidestepTo = nil,
		sidestepUntil = 0,
	}
	table.insert(agents, agent)
	local fall = TweenService:Create(
		root,
		TweenInfo.new(R.dropSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ CFrame = standing }
	)
	fall.Completed:Connect(function()
		if agent.dying then
			return
		end
		root.Anchored = false
		root:SetNetworkOwner(nil)
		trail.Enabled = false
		agent.ready = true
		Sfx.at("chute", root)
		agent.steps = Sfx.loop("pas", root, Config.sounds.stepsMin, Config.sounds.stepsMax)
	end)
	fall:Play()
end

local function living(): number
	local n = 0
	for _, agent in agents do
		if not agent.dying then
			n += 1
		end
	end
	return n
end

-- Recrache `count` Repris, pres de joueurs tires au sort (les caches pesent
-- plus), ou pres de `near` s'il est donne.
local function recrache(count: number, regard: number, near: Vector3?)
	local alive = Roster.alive()
	for _ = 1, count do
		local around = near
		if around == nil then
			local weights: { number } = {}
			for i, actor in alive do
				weights[i] = if HidingService.isHidden(actor) then R.hiddenWeight else 1
			end
			local index = Horde.pickWeighted(weights, random:NextNumber())
			local root = index and Roster.rootOf(alive[index])
			around = root and root.Position
		end
		local kindId = Horde.pickKind(R.kinds, regard, random:NextNumber())
		local at = around and dropPoint(around)
		if kindId and at then
			spawnAgent(kindId, at)
		end
	end
end

-- Une fermeture de l'Oeil (ou une rafale au Regard 5) : il en recrache.
function ReprisService.onClose(regard: number)
	local per = R.perPlayers[regard]
	if per == nil then
		return
	end
	local count = Horde.spawnCount(Roster.count(), living(), per, R.capRatio)
	if count > 0 then
		recrache(count, regard, nil)
		print(string.format("[Royale] L'Oeil recrache %d Repris", count))
	end
end

-- Un nouveau Regard : il en re-aspire la moitie (on les voit remonter).
function ReprisService.onRegard(_regard: number)
	local n = Horde.reaspire(living(), R.reaspireFraction)
	local list = table.clone(agents)
	for i = #list, 2, -1 do
		local j = random:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	for _, agent in list do
		if n <= 0 then
			break
		end
		if not agent.dying then
			vanish(agent, true)
			n -= 1
		end
	end
end

-- Flaire sans rien a arracher : des Repris tombent pres de lui.
local function onFlagged(actor: Roster.Actor)
	local root = Roster.rootOf(actor)
	local regard = workspace:GetAttribute(Config.match.regardAttribute)
	if root == nil or typeof(regard) ~= "number" then
		return
	end
	-- Hors plafond : avec 3 joueurs en vie le plafond n'en laissait qu'un, et
	-- en finale plus rien ne delogeait un campeur dans un recoin (finale de
	-- plus de 5 minutes au banc d'equilibrage du 13 novembre 2026). On compte
	-- seulement ceux qui sont deja autour de lui.
	local nearby = 0
	for _, agent in agents do
		if
			agent.model.Parent
			and not agent.dying
			and (agent.root.Position - root.Position).Magnitude <= R.spawnMax
		then
			nearby += 1
		end
	end
	local count = math.max(R.flaggedSend - nearby, 0)
	if count > 0 then
		recrache(count, regard, root.Position)
	end
end

local function moveTowards(agent: Agent, goal: Vector3)
	local now = os.clock()
	local sidestep = agent.sidestepTo
	if sidestep and now < agent.sidestepUntil then
		agent.humanoid:MoveTo(sidestep)
		return
	end
	if (agent.root.Position - agent.stuckFrom).Magnitude > 1 then
		agent.stuckFrom = agent.root.Position
		agent.stuckSince = now
	elseif now - agent.stuckSince > R.stuckSeconds then
		local angle = random:NextNumber(0, math.pi * 2)
		agent.sidestepTo = agent.root.Position
			+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * 10
		agent.sidestepUntil = now + R.sidestepSeconds
		agent.stuckSince = now
		agent.humanoid.Jump = true
		agent.pathGoal = nil
		return
	end
	if (goal - agent.root.Position).Magnitude < R.directRange then
		agent.waypoints = {}
		agent.humanoid:MoveTo(goal)
		return
	end
	if
		not agent.pathing
		and (
			now - agent.lastPath >= R.repathSeconds
			or agent.pathGoal == nil
			or ((agent.pathGoal :: Vector3) - goal).Magnitude > 8
		)
	then
		agent.lastPath = now
		agent.pathGoal = goal
		agent.pathing = true
		local from = agent.root.Position
		task.spawn(function()
			local path = PathfindingService:CreatePath({
				AgentRadius = R.path.radius,
				AgentHeight = R.path.height,
				AgentCanJump = R.path.canJump,
			})
			local ok, problem = pcall(function()
				path:ComputeAsync(from, goal)
			end)
			agent.pathing = false
			if ok and path.Status == Enum.PathStatus.Success then
				agent.waypoints = path:GetWaypoints()
				agent.waypointIndex = math.min(2, #agent.waypoints)
			else
				if not ok and not pathWarned then
					pathWarned = true
					warn("[Royale] Calcul de chemin des Repris : " .. tostring(problem))
				end
				agent.waypoints = {}
			end
		end)
	end
	local waypoint = agent.waypoints[agent.waypointIndex]
	if waypoint then
		if
			(waypoint.Position - agent.root.Position).Magnitude < 3
			and agent.waypointIndex < #agent.waypoints
		then
			agent.waypointIndex += 1
			waypoint = agent.waypoints[agent.waypointIndex]
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				agent.humanoid.Jump = true
			end
		end
		agent.humanoid:MoveTo(waypoint.Position)
	else
		agent.humanoid:MoveTo(goal)
	end
end

local function animate(agent: Agent)
	local v = agent.root.AssemblyLinearVelocity
	local moving = Vector3.new(v.X, 0, v.Z).Magnitude > 1.5
	local steps = agent.steps
	if steps then
		if moving and not steps.IsPlaying then
			steps:Play()
		elseif not moving and steps.IsPlaying then
			steps:Stop()
		end
	end
	local move, idle = agent.moveTrack, agent.idleTrack
	if move and idle then
		if moving and not move.IsPlaying then
			idle:Stop(0.25)
			move:Play(0.25)
		elseif not moving and move.IsPlaying then
			move:Stop(0.3)
			idle:Play(0.3)
		end
	end
end

-- Ce qu'il voit d'un participant : comme l'Oeil, une ligne reelle depuis sa
-- tete (la fumee et les murs l'aveuglent).
local function sees(agent: Agent, actor: Roster.Actor, root: BasePart): boolean
	if HidingService.isHidden(actor) then
		return false
	end
	local ignore: { Instance } = { getFolder() }
	local character = Roster.characterOf(actor)
	for _, other in Roster.alive() do
		local c = Roster.characterOf(other)
		if c then
			table.insert(ignore, c)
		end
	end
	if character == nil then
		return false
	end
	return World.visibility(root.Position, ignore, agent.head.Position) > R.seenAbove
end

-- Combien de Repris suivent deja chacun (sans compter `self`).
local function takenCounts(self: Agent): { [string]: number }
	local out: { [string]: number } = {}
	for _, agent in agents do
		if agent ~= self and agent.target and not agent.dying then
			local id = Roster.idOf(agent.target)
			out[id] = (out[id] or 0) + 1
		end
	end
	return out
end

local function chooseTarget(agent: Agent)
	local kind = agent.kind
	if kind.sight == nil then
		return
	end
	local seen: { Horde.Seen } = {}
	local byId: { [string]: Roster.Actor } = {}
	local here = agent.root.Position
	for _, actor in Roster.alive() do
		local root = Roster.rootOf(actor)
		if root == nil then
			continue
		end
		local v = root.AssemblyLinearVelocity
		local range = Horde.sightRange(
			kind.sight,
			Vector3.new(v.X, 0, v.Z).Magnitude,
			R.slowSpeed,
			R.slowSightFactor
		)
		local distance = (root.Position - here).Magnitude
		if distance > range then
			continue
		end
		local id = Roster.idOf(actor)
		byId[id] = actor
		table.insert(seen, { id = id, distance = distance, visible = sees(agent, actor, root) })
	end
	local current = agent.target and Roster.idOf(agent.target)
	local id = Horde.pickTarget(seen, math.huge, takenCounts(agent), R.maxPerTarget, current)
	local now = os.clock()
	if id then
		local actor = byId[id]
		local first = agent.target ~= actor or now - agent.lastSeen > R.memorySeconds
		agent.target = actor
		agent.lastSeen = now
		local root = Roster.rootOf(actor)
		agent.lastSeenAt = root and root.Position
		if first and root then
			-- Il te voit : l'Errant crie, le Hurleur hurle.
			if kind.cry and now - agent.lastCry >= kind.cry.cooldown then
				agent.lastCry = now
				local at = root.Position
				print(string.format("[Royale] Un Errant crie : il a vu %s", Roster.nameOf(actor)))
				Sfx.at("grognement", agent.head)
				EyeService.lure(function()
					return at
				end, kind.cry.lureSeconds, false)
			elseif kind.howl and now - agent.lastCry >= kind.howl.cooldown then
				agent.lastCry = now
				print(string.format("[Royale] Un Hurleur hurle : il a vu %s", Roster.nameOf(actor)))
				Sfx.at("hurlement", agent.head)
				EyeService.noise(here, kind.howl.noiseSeconds, true)
				for _, other in agents do
					if
						other ~= agent
						and not other.dying
						and (other.root.Position - here).Magnitude <= kind.howl.callRadius
					then
						other.lead = root.Position
					end
				end
			end
		end
	elseif agent.target and now - agent.lastSeen > R.memorySeconds then
		-- Perdu : il va voir ou il l'a vu, puis rode.
		agent.lead = agent.lastSeenAt
		agent.target = nil
	end
end

-- Le Rampant : un cache dans une cachette, tout pres.
local function sniff(agent: Agent): HidingService.Spot?
	local best, bestD = nil, agent.kind.smell
	for _, actor in Roster.alive() do
		local spot = HidingService.spotOf(actor)
		if spot then
			local d = (spot.inside.Position - agent.root.Position).Magnitude
			if d <= bestD then
				best, bestD = spot, d
			end
		end
	end
	return best
end

local function roam(agent: Agent)
	local here = agent.root.Position
	if agent.roamTo and (agent.roamTo - here).Magnitude > 4 then
		moveTowards(agent, agent.roamTo)
		return
	end
	-- Vers le joueur le plus proche, a petits pas, sinon au hasard.
	local best, bestD = nil, R.roamRange
	for _, actor in Roster.alive() do
		local root = Roster.rootOf(actor)
		if root then
			local d = (root.Position - here).Magnitude
			if d < bestD then
				best, bestD = root.Position, d
			end
		end
	end
	local toward = if best
		then (best - here)
		else Vector3.new(random:NextNumber(-1, 1), 0, random:NextNumber(-1, 1))
	toward = Vector3.new(toward.X, 0, toward.Z)
	if toward.Magnitude < 1e-3 then
		toward = Vector3.new(1, 0, 0)
	end
	local step = math.min(R.roamStep, if best then bestD else R.roamStep)
	agent.roamTo = here
		+ toward.Unit * step
		+ Vector3.new(random:NextNumber(-6, 6), 0, random:NextNumber(-6, 6))
	moveTowards(agent, agent.roamTo :: Vector3)
end

local function think(agent: Agent, now: number)
	local kind = agent.kind
	local here = agent.root.Position
	if kind.smell then
		-- Apres un arrachage, il rode un moment (vu en partie : il arrachait
		-- le meme bot quatre fois de suite, qui rentrait aussitot).
		local spot = if now < agent.restUntil then nil else sniff(agent)
		if spot then
			-- Il vise l'entree la plus proche (ou l'interieur), a plat : sur le
			-- toit d'un wagon, il etait a 8 studs de l'interieur sans jamais
			-- l'atteindre (vu en sonde).
			local goal, d = spot.inside.Position, math.huge
			for _, p in { spot.inside, table.unpack(spot.exits) } do
				local flat = Vector3.new(p.Position.X - here.X, 0, p.Position.Z - here.Z).Magnitude
				if flat < d then
					goal, d = p.Position, flat
				end
			end
			if d <= kind.evictReach then
				agent.humanoid:MoveTo(here)
				if agent.evictSince == 0 then
					agent.evictSince = now
				elseif now - agent.evictSince >= kind.evictSeconds then
					agent.evictSince = 0
					agent.restUntil = now + kind.evictRest
					local out = HidingService.evict(spot)
					if out then
						print(
							string.format(
								"[Royale] Un Rampant arrache %s de sa cachette",
								Roster.nameOf(out)
							)
						)
					end
				end
			else
				agent.evictSince = 0
				moveTowards(agent, goal)
			end
			return
		end
		agent.evictSince = 0
		roam(agent)
		return
	end
	chooseTarget(agent)
	local target = agent.target
	local root = target and Roster.rootOf(target)
	if target and root and Roster.isAlive(target) then
		local tackle = kind.tackle
		if tackle then
			local d = (root.Position - here).Magnitude
			if agent.windupUntil > 0 then
				-- Le grognement est fini : il plaque s'il l'atteint encore.
				if now >= agent.windupUntil then
					agent.windupUntil = 0
					agent.lastTackle = now
					if d <= tackle.range + 1 and not CombatService.isDown(target) then
						local away = root.Position - here
						away = Vector3.new(away.X, 0, away.Z)
						local push = if away.Magnitude > 0 then away.Unit * tackle.push else nil
						CombatService.trip(target, tackle.fall, push)
						print(string.format("[Royale] Un Coureur plaque %s", Roster.nameOf(target)))
					end
				end
			elseif d <= tackle.range and now - agent.lastTackle >= tackle.cooldown then
				agent.windupUntil = now + tackle.windup
				-- Il grogne avant de plaquer (CONCEPT.md : ils previennent).
				Sfx.at("grognement", agent.head)
				agent.humanoid:MoveTo(here)
				return
			end
		end
		moveTowards(agent, root.Position)
		return
	end
	agent.target = nil
	local lead = agent.lead
	if lead then
		if (lead - here).Magnitude < 4 then
			agent.lead = nil
		else
			moveTowards(agent, lead)
			return
		end
	end
	roam(agent)
end

-- Pose un Repris de cette sorte sur le sol, pres de `at` (les sondes, et les
-- envois de l'Oeil).
function ReprisService.drop(kindId: string, at: Vector3)
	if R.kinds[kindId] then
		spawnAgent(kindId, at)
	end
end

-- Un corps de Repris tout pret, hors de la horde (le bot du Ventre).
function ReprisService.body(kindId: string): Model
	return templateFor(kindId):Clone()
end

-- Pour les bots : le Repris le plus proche a portee.
function ReprisService.nearest(at: Vector3, range: number): BasePart?
	local best, bestD = nil, range
	for _, agent in agents do
		if agent.ready and not agent.dying then
			local d = (agent.root.Position - at).Magnitude
			if d <= bestD then
				best, bestD = agent.root, d
			end
		end
	end
	return best
end

function ReprisService.count(): number
	return living()
end

function ReprisService.clear()
	for i = #agents, 1, -1 do
		agents[i].model:Destroy()
	end
	table.clear(agents)
end

function ReprisService.start()
	getFolder()
	loadSkull()
	CombatService.addCreatures(function()
		local out: { CombatService.Creature } = {}
		for _, agent in agents do
			if agent.ready and not agent.dying then
				table.insert(out, { id = agent.id, root = agent.root, onHit = onHit })
			end
		end
		return out
	end)
	EyeService.onFlagged(onFlagged)
	task.spawn(function()
		while true do
			task.wait(R.thinkSeconds)
			local now = os.clock()
			for _, agent in table.clone(agents) do
				if agent.ready and not agent.dying and agent.model.Parent then
					local ok, err = pcall(think, agent, now)
					if not ok then
						warn("[Royale] Repris : " .. tostring(err))
					end
					animate(agent)
				end
			end
		end
	end)
end

return ReprisService
