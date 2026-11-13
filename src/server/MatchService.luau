--!strict
--[[
	MatchService — le deroule d'une partie (CONCEPT.md, Une partie).

	Salon (LobbyService : on forme son groupe, on se dit pret) -> Visee (on
	choisit ou tomber, depuis la pupille) -> Chute (l'Oeil crache tout le
	monde en cometes, en ligne droite) -> Partie (les Regards s'enchainent,
	l'Oeil s'ouvre et se ferme, le cercle se resserre) -> Fin (la derniere
	equipe en vie gagne) -> retour au salon.

	Ou se joue la partie (choisi avec Josh, DECISIONS.md) : dans Studio, sur
	place ; dans le jeu publie, le salon envoie les joueurs prets sur un
	serveur reserve, qui joue une partie puis les renvoie au salon.

	Seul, la partie dure jusqu'a ce que l'Oeil te prenne : il n'y a personne a
	battre (les bots viendront).

	L'interface lit des attributs de Workspace : `Phase`, `PhaseFin` (heure du
	serveur), `Regard`, `RegardTitre`, `OeilOuvert`, `OeilChange`,
	`OeilBientot`, `EnVie`, `Gagnant`.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

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
local LeaderboardService = require(script.Parent.LeaderboardService)
local LobbyService = require(script.Parent.LobbyService)
local ProfileService = require(script.Parent.ProfileService)
local ReprisService = require(script.Parent.ReprisService)
local SignalService = require(script.Parent.SignalService)
local SquadService = require(script.Parent.SquadService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local ShopService = require(script.Parent.ShopService)
local ChallengeService = require(script.Parent.ChallengeService)
local Roster = require(script.Parent.Roster)
local Sfx = require(script.Parent.Sfx)
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
		-- La comete portee (un cosmetique), sinon la braise de base.
		local skin = if player:IsA("Player") then ShopService.equipped(player, "comet") else nil
		local c1 = if skin then skin.color else M.cometColor
		local c2 = if skin then skin.color2 else M.cometColor2
		fire.Color = Color3.fromRGB(c1[1], c1[2], c1[3])
		fire.SecondaryColor = Color3.fromRGB(c2[1], c2[2], c2[3])
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
				Sfx.at("chute", ground)
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

-- Tout remettre a zero (avant une partie, et apres, pour que le monde ne
-- garde ni bots, ni Repris, ni cachettes).
local function resetAll()
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
end

-- Une partie avec ces joueurs, ce mode et ces groupes (venus du salon).
local function playOnce(humans: { Player }, mode: string, groups: { { Player } })
	resetAll()
	SquadService.setMode(mode)
	for _, player in humans do
		spawn(player, waitingSpot())
	end

	-- LA VISEE, depuis la pupille. Les bots completent jusqu'a un total tire
	-- au sort (CONCEPT.md) ; ils visent au hasard, comme quelqu'un qui ne
	-- touche pas au stick.
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
	SquadService.assign(players, groups)
	Roster.refresh()
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

		SquadService.track(index, function(actor)
			return Roster.isAlive(actor) or GoulagService.isInside(actor)
		end)
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
	-- Les gagnants restent en jeu jusqu'au bout : leur equipe est premiere.
	SquadService.track(regardIndex, function(actor)
		return table.find(winners, actor) ~= nil
	end)
	BetService.settle(winners)
	-- Ce que la partie rapporte a chaque vrai joueur (CONCEPT.md).
	for _, player in humans do
		if player.Parent then
			ProfileService.grant(player, {
				regard = SquadService.regardOf(player),
				won = table.find(winners, player) ~= nil,
				place = SquadService.placeOf(player),
				betWon = BetService.won(player),
			})
		end
	end
	workspace:SetAttribute(M.winnerAttribute, table.concat(names, ", "))
	workspace:SetAttribute(Config.match.eyeOpenAttribute, false)
	EyeService.step(0, Config.regards[1], false, 0, false)
	setPhase("Fin", M.endSeconds)
	print(
		if winner
			then string.format(
				"[Royale] %s %s la partie",
				table.concat(names, ", "),
				if #names > 1 then "gagnent" else "gagne"
			)
			else "[Royale] L'Œil a pris tout le monde"
	)
	task.wait(M.endSeconds)
	resetAll()
end

-- Un serveur reserve (envoye par le salon) : un serveur de partie.
local function isMatchServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

-- Le salon a lance un depart : sur place dans Studio, sur un serveur
-- reserve dans le jeu publie (ReserveServer ne marche pas dans Studio).
local function launch(players: { Player }, mode: string, groups: { { Player } })
	if RunService:IsStudio() then
		LobbyService.setAway(players, true)
		local ok, err = pcall(playOnce, players, mode, groups)
		if not ok then
			warn("[Royale] La partie s'est arrêtée sur une erreur : " .. tostring(err))
			resetAll()
		end
		LobbyService.setAway(players, false)
		setPhase("Salon")
		for _, player in players do
			if player.Parent then
				LobbyService.place(player)
			end
		end
		return
	end
	local ids: { { number } } = {}
	for _, group in groups do
		local list: { number } = {}
		for _, player in group do
			table.insert(list, player.UserId)
		end
		table.insert(ids, list)
	end
	local code = TeleportService:ReserveServer(game.PlaceId)
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = code
	options:SetTeleportData({ mode = mode, groups = ids, expected = #players })
	TeleportService:TeleportAsync(game.PlaceId, players, options)
end

-- Le serveur de partie : attendre les arrivants, jouer, renvoyer au salon.
local function serveMatch()
	setPhase("Attente", Config.lobby.arrivalSeconds)
	while #realPlayers() == 0 do
		task.wait(0.5)
	end
	local data: any = nil
	local ok, err = pcall(function()
		data = realPlayers()[1]:GetJoinData().TeleportData
	end)
	if not ok then
		warn("[Royale] Données du salon illisibles : " .. tostring(err))
	end
	local expected = if typeof(data) == "table" and typeof(data.expected) == "number"
		then data.expected
		else 1
	local ends = os.clock() + Config.lobby.arrivalSeconds
	while #realPlayers() < expected and os.clock() < ends do
		task.wait(0.5)
	end
	local mode = if typeof(data) == "table" and Config.squads.sizes[data.mode]
		then data.mode
		else Config.squads.mode
	local groups: { { Player } } = {}
	if typeof(data) == "table" and typeof(data.groups) == "table" then
		for _, list in data.groups do
			local group: { Player } = {}
			for _, userId in list do
				local player = Players:GetPlayerByUserId(userId)
				if player then
					table.insert(group, player)
				end
			end
			if #group > 0 then
				table.insert(groups, group)
			end
		end
	end
	local ok2, err2 = pcall(playOnce, realPlayers(), mode, groups)
	if not ok2 then
		warn("[Royale] La partie s'est arrêtée sur une erreur : " .. tostring(err2))
	end
	-- Retour au salon : un serveur public de la meme place.
	local back = realPlayers()
	if #back > 0 then
		local sent, why = pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, back)
		end)
		if not sent then
			warn("[Royale] Retour au salon impossible : " .. tostring(why))
		end
	end
end

function MatchService.start()
	Players.CharacterAutoLoads = false
	ProfileService.start()
	ShopService.start(remote(Config.remotes.shop))
	ChallengeService.start()
	LeaderboardService.start()
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
	-- Un elimine qui quitte : retour au salon (un serveur public dans le jeu
	-- publie ; sur place dans Studio).
	BetService.onQuit(function(player: Player)
		if isMatchServer() then
			local ok, err = pcall(function()
				TeleportService:TeleportAsync(game.PlaceId, { player })
			end)
			if not ok then
				warn("[Royale] Retour au salon impossible : " .. tostring(err))
			end
		else
			-- Dans Studio, la partie se joue ici : il retourne tout de suite
			-- au salon (le salon ne relance rien tant qu'elle dure).
			-- Plus participant pour l'ecran (l'attribut fait afficher le salon).
			player:SetAttribute(M.aliveAttribute, nil)
			LobbyService.setAway({ player }, false)
			LobbyService.place(player)
		end
	end)
	if isMatchServer() then
		-- Celui qui arrive pendant l'attente se pose pres du centre.
		Players.PlayerAdded:Connect(function(player: Player)
			if phase == "Attente" then
				spawn(player, waitingSpot())
			end
		end)
		task.spawn(serveMatch)
	else
		LobbyService.start(remote(Config.remotes.lobby), launch)
	end
end

return MatchService
