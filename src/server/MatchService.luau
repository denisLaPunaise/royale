--!strict
--[[
	MatchService — le deroule d'une partie (CONCEPT.md, Une partie).

	Attente -> Visee (on choisit ou tomber, depuis la pupille) -> Chute (l'Oeil
	crache tout le monde en cometes, en ligne droite) -> Partie (les Regards
	s'enchainent, l'Oeil s'ouvre et se ferme, le cercle se resserre) -> Fin
	(le dernier en vie gagne). Puis, tant qu'il n'y a pas de salon, une
	nouvelle partie recommence sur le meme serveur (Josh, 12 novembre 2026).

	Seul, la partie dure jusqu'a ce que l'Oeil te prenne : il n'y a personne a
	battre (les bots viendront).

	L'interface lit des attributs de Workspace : `Phase`, `PhaseFin` (heure du
	serveur), `Regard`, `RegardTitre`, `OeilOuvert`, `OeilChange`,
	`OeilBientot`, `EnVie`, `Gagnant`.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Circles = require(Royale:WaitForChild("Circles"))
local Config = require(Royale:WaitForChild("Config"))
local Regards = require(Royale:WaitForChild("Regards"))

local BetService = require(script.Parent.BetService)
local BotService = require(script.Parent.BotService)
local CombatService = require(script.Parent.CombatService)
local EyePowerService = require(script.Parent.EyePowerService)
local EyeService = require(script.Parent.EyeService)
local HidingService = require(script.Parent.HidingService)
local GoulagService = require(script.Parent.GoulagService)
local ItemService = require(script.Parent.ItemService)
local ReprisService = require(script.Parent.ReprisService)
local SignalService = require(script.Parent.SignalService)
local SquadService = require(script.Parent.SquadService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Roster = require(script.Parent.Roster)
local World = require(script.Parent.World)
local ZoneService = require(script.Parent.ZoneService)

local MatchService = {}

local M = Config.match
local random = Random.new()

local phase = "Attente"
local aims: { [Roster.Actor]: Vector2 } = {}
local durations: { number } = {}
for _, r in Config.regards do
	table.insert(durations, r.seconds)
end

local function setPhase(name: string, seconds: number?)
	phase = name
	workspace:SetAttribute(M.phaseAttribute, name)
	workspace:SetAttribute(
		M.phaseEndsAttribute,
		if seconds then workspace:GetServerTimeNow() + seconds else nil
	)
	print("[Royale] Phase : " .. name)
end

-- Un point au sol au hasard pres du centre, pour attendre.
local function waitingSpot(): Vector3
	local zone = ZoneService.current()
	for _ = 1, 20 do
		local a = random:NextNumber(0, math.pi * 2)
		local r = random:NextNumber(0, M.waitRadius)
		local hit = World.ground(zone.x + math.cos(a) * r, zone.z + math.sin(a) * r)
		if hit then
			return hit + Vector3.new(0, M.landingHeight, 0)
		end
	end
	return World.eyeOrigin
end

local function spawn(player: Player, at: Vector3)
	player:LoadCharacter()
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(at))
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.movement.walkSpeed
			humanoid.Died:Connect(function()
				Roster.take(player)
			end)
		end
	end
end

local function remote(name: string): RemoteEvent
	local folder = Royale:FindFirstChild(Config.remotes.folder)
	if folder == nil then
		local f = Instance.new("Folder")
		f.Name = Config.remotes.folder
		f.Parent = Royale
		folder = f
	end
	local existing = (folder :: Instance):FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	return event
end

-- Le point vise, ramene dans le cercle de depart.
local function clampAim(x: number, z: number): Vector2
	local zone = ZoneService.current()
	local limit = math.min(zone.radius, Config.world.half)
	local dx, dz = x - zone.x, z - zone.z
	local d = math.sqrt(dx * dx + dz * dz)
	if d > limit then
		dx, dz = dx / d * limit, dz / d * limit
	end
	return Vector2.new(zone.x + dx, zone.z + dz)
end

-- La chute : chacun file en ligne droite de la pupille a son point, en
-- comete, et s'ecrase. Rend quand tout le monde est au sol.
local function drop(players: { Roster.Actor })
	local origin = World.eyeOrigin
	local pending = 0
	for _, player in players do
		local root = Roster.rootOf(player)
		if root == nil then
			continue
		end
		local aim = aims[player]
		if aim == nil then
			local zone = ZoneService.current()
			local spot = Circles.place(
				{ x = zone.x, z = zone.z, radius = math.min(zone.radius, Config.world.half) },
				0,
				0,
				random:NextNumber(),
				random:NextNumber()
			)
			aim = Vector2.new(spot.x, spot.z)
		end
		local ground = World.ground(aim.X, aim.Y) or Vector3.new(aim.X, 0, aim.Y)
		local landing = ground + Vector3.new(0, M.landingHeight, 0)
		local distance = (landing - origin).Magnitude
		local seconds = distance / M.cometSpeed
		pending += 1
		root.Anchored = true
		local fire = Instance.new("Fire")
		fire.Heat = M.cometFireHeat
		fire.Size = M.cometFireSize
		fire.Color = Color3.fromRGB(255, 120, 40)
		fire.SecondaryColor = Color3.fromRGB(120, 20, 10)
		fire.Parent = root
		local facing = CFrame.lookAt(
			origin,
			Vector3.new(landing.X, origin.Y, landing.Z) + Vector3.new(0, 0, -1)
		)
		task.spawn(function()
			local started = os.clock()
			while true do
				local k = math.clamp((os.clock() - started) / seconds, 0, 1)
				if root.Parent == nil then
					break
				end
				root.CFrame = CFrame.new(origin:Lerp(landing, k)) * (facing - facing.Position)
				if k >= 1 then
					break
				end
				RunService.Heartbeat:Wait()
			end
			fire:Destroy()
			if root.Parent then
				root.Anchored = false
				local blast = Instance.new("Explosion")
				blast.Position = ground
				blast.BlastPressure = 0
				blast.BlastRadius = M.impactRadius
				blast.DestroyJointRadiusPercent = 0
				blast.Parent = workspace
			end
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait(0.1)
	end
end

local function realPlayers(): { Player }
	return Players:GetPlayers()
end

local function playOnce()
	-- L'ATTENTE.
	EyeService.reset()
	EyePowerService.reset()
	ZoneService.reset()
	CombatService.clear()
	ItemService.clear()
	ReprisService.clear()
	GoulagService.reset()
	SquadService.clear()
	BetService.reset()
	HidingService.clear()
	BotService.clear()
	Roster.clear()
	workspace:SetAttribute(M.winnerAttribute, nil)
	workspace:SetAttribute(M.regardAttribute, nil)
	workspace:SetAttribute(M.regardTitleAttribute, nil)
	workspace:SetAttribute(Config.eye.changeAttribute, nil)
	workspace:SetAttribute(Config.eye.warningAttribute, false)
	while #realPlayers() < M.minRealPlayers do
		task.wait(0.5)
	end
	setPhase("Attente", M.waitSeconds)
	for _, player in realPlayers() do
		spawn(player, waitingSpot())
	end
	local waitEnds = os.clock() + M.waitSeconds
	while os.clock() < waitEnds do
		task.wait(0.25)
	end

	-- LA VISEE, depuis la pupille. Les bots completent jusqu'a un total tire
	-- au sort (CONCEPT.md) ; ils visent au hasard, comme quelqu'un qui ne
	-- touche pas au stick.
	local humans = realPlayers()
	local total = random:NextInteger(Config.bots.totalMin, Config.bots.totalMax)
	-- Des equipes pleines : arrondi a la taille d'equipe, sans depasser le
	-- maximum (vu en sonde : 17 en escouade laissait un bot seul).
	local size = SquadService.size()
	total = math.min(math.ceil(total / size) * size, Config.bots.totalMax)
	local players: { Roster.Actor } = table.clone(humans)
	for _, bot in BotService.spawn(math.max(total - #humans, 0), waitingSpot) do
		table.insert(players, bot)
	end
	Roster.start(players)
	SquadService.assign(players)
	HidingService.setup(#players)
	ItemService.setup(players)
	table.clear(aims)
	setPhase("Visee", M.aimSeconds)
	for _, player in players do
		if player:IsA("Player") and player.Character == nil then
			spawn(player, waitingSpot())
		end
		local root = Roster.rootOf(player)
		if root then
			root.Anchored = true
			root.CFrame = CFrame.new(World.eyeOrigin)
		end
	end
	task.wait(M.aimSeconds)

	-- LA CHUTE.
	setPhase("Chute")
	drop(players)

	-- LA PARTIE.
	local start = os.clock()
	local regardIndex = 0
	local wasOpen, lastBurst = false, 0
	local tick = Config.eye.tickSeconds
	setPhase("Partie")
	local lastStep = os.clock()
	while true do
		task.wait(tick)
		local now = os.clock()
		local dt = now - lastStep
		lastStep = now
		local t = now - start
		local index, regardStart = Regards.at(durations, t)
		local regard = Config.regards[index]
		if index ~= regardIndex then
			regardIndex = index
			ZoneService.announce(index, Roster.count(), now)
			workspace:SetAttribute(M.regardAttribute, index)
			ItemService.onRegard(index)
			EyePowerService.onRegard(index)
			ReprisService.onRegard(index)
			GoulagService.onRegard(index)
			workspace:SetAttribute(M.regardTitleAttribute, regard.title)
			workspace:SetAttribute(
				M.phaseEndsAttribute,
				if index < #durations
					then workspace:GetServerTimeNow() + (regardStart + regard.seconds - t)
					else nil
			)
			print(string.format("[Royale] Regard %d : %s", index, regard.title))
		end
		-- Le Regard tel que l'Oeil le joue, avec ses pouvoirs.
		regard = EyePowerService.regardFor(index)
		ZoneService.step(now)
		-- Au premier Regard, l'Oeil laisse d'abord le temps de se poser.
		local within = t - regardStart
		if index == 1 then
			within -= M.firstOpenDelay
		end
		local open, left, burst = false, -within, 0
		if within >= 0 then
			open, left, burst = Regards.burst(regard, within)
		end
		workspace:SetAttribute(
			Config.eye.changeAttribute,
			if left < math.huge then workspace:GetServerTimeNow() + left else nil
		)
		workspace:SetAttribute(
			Config.eye.warningAttribute,
			not open and left <= Config.eye.warningSeconds
		)
		EyeService.step(dt, regard, open, burst, true)
		-- Les Repris : a chaque fermeture, et a chaque rafale quand il ne se
		-- ferme plus (CONCEPT.md).
		if
			(wasOpen and not open)
			or (regard.closedSeconds <= 0 and open and burst ~= lastBurst and lastBurst > 0)
		then
			ReprisService.onClose(index)
		end
		wasOpen, lastBurst = open, burst

		-- Une seule equipe en vie (en solo, une equipe = un joueur).
		if SquadService.over() then
			break
		end
	end

	-- LA FIN.
	local winners = SquadService.winners()
	local names: { string } = {}
	for _, actor in winners do
		table.insert(names, Roster.nameOf(actor))
	end
	local winner = winners[1]
	BetService.settle(winners)
	workspace:SetAttribute(M.winnerAttribute, table.concat(names, ", "))
	workspace:SetAttribute(Config.match.eyeOpenAttribute, false)
	EyeService.step(0, Config.regards[1], false, 0, false)
	setPhase("Fin", M.endSeconds)
	print(
		if winner
			then string.format("[Royale] %s gagne la partie", table.concat(names, ", "))
			else "[Royale] L'Œil a pris tout le monde"
	)
	task.wait(M.endSeconds)
end

function MatchService.start()
	Players.CharacterAutoLoads = false
	BotService.start()
	CombatService.start(remote(Config.remotes.gesture))
	EyePowerService.start()
	ReprisService.start()
	GoulagService.start()
	SquadService.start()
	SignalService.start(remote(Config.remotes.signal))
	BetService.start(remote(Config.remotes.bet), remote(Config.remotes.quit))
	ItemService.start(
		remote(Config.remotes.item),
		remote(Config.remotes.projectile),
		remote(Config.remotes.steer)
	)
	remote(Config.remotes.aim).OnServerEvent:Connect(
		RemoteGuard.wrap(Config.remotes.aim, function(player: Player, x: any, z: any)
			if phase ~= "Visee" or typeof(x) ~= "number" or typeof(z) ~= "number" then
				return
			end
			if x ~= x or z ~= z then
				return
			end
			aims[player] = clampAim(x, z)
		end)
	)
	remote(Config.remotes.leave).OnServerEvent:Connect(
		RemoteGuard.wrap(Config.remotes.leave, function(player: Player)
			HidingService.leave(player)
		end)
	)
	-- Celui qui arrive en cours de partie regarde ; il jouera la suivante.
	Players.PlayerAdded:Connect(function(player: Player)
		if phase == "Attente" then
			spawn(player, waitingSpot())
		end
	end)
	task.spawn(function()
		repeat
			local ok, err = pcall(playOnce)
			if not ok then
				warn("[Royale] La partie s'est arrêtée sur une erreur : " .. tostring(err))
				task.wait(2)
			end
		until not M.restartAfterEnd
	end)
end

return MatchService
