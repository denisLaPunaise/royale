--!strict
--[[
	LobbyService — le salon (DECISIONS.md, choisi avec Josh le 12 novembre
	2026 : « les deux »).

	Une place en ruine flottant loin de la carte, construite au demarrage. On
	y attend, on forme son groupe (X maintenu sur quelqu'un l'invite ; il
	accepte avec X), le chef choisit le mode (Y) et se dit pret (R2). Un
	compte a rebours part : a la fin, tous les groupes prets de ce mode
	partent ensemble. `onLaunch` decide ou ils jouent (MatchService : sur
	place dans Studio, sur un serveur reserve dans le jeu publie).

	Les invitations et « rejoindre » de Roblox amenent les amis sur ce
	serveur ; croix haut ouvre la fenetre d'invitation de Roblox (client).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local Lobby = require(Royale:WaitForChild("Lobby"))

local RemoteGuard = require(script.Parent.RemoteGuard)
local World = require(script.Parent.World)

local LobbyService = {}

local LB = Config.lobby
local SIZES = Config.squads.sizes
local ORIGIN = Vector3.new(LB.origin[1], LB.origin[2], LB.origin[3])

local state = Lobby.new()
local byId: { [string]: Player } = {}
-- Ceux qui jouent une partie sur ce serveur : hors du salon jusqu'a la fin.
local away: { [Player]: boolean } = {}
-- L'invitation recue par chacun : qui, et quand.
local invites: { [Player]: { from: Player, at: number } } = {}
local countdown: { mode: string, ends: number }? = nil
local launching = false
local onLaunch: ((players: { Player }, mode: string, groups: { { Player } }) -> ())? = nil
local folder: Folder? = nil
local random = Random.new()

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function idOf(player: Player): string
	return tostring(player.UserId)
end

local function part(
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

-- La place : un disque de pavés uses, un muret effondre tout autour (et un
-- mur invisible pour ne pas tomber), des lanternes, un brasero au centre.
local function build()
	local old = workspace:FindFirstChild(LB.folder)
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = LB.folder
	f.Parent = workspace
	World.ignore(f)
	folder = f
	local stone, dark, lantern = rgb(LB.colors.stone), rgb(LB.colors.dark), rgb(LB.colors.lantern)
	local flat = CFrame.Angles(0, 0, math.pi / 2)
	local r = LB.radius
	local floor = part(
		"Sol",
		Vector3.new(4, r * 2, r * 2),
		CFrame.new(ORIGIN - Vector3.new(0, 2, 0)) * flat,
		stone,
		Enum.Material.Cobblestone
	)
	floor.Shape = Enum.PartType.Cylinder
	local under = part(
		"Dessous",
		Vector3.new(14, r * 2 - 6, r * 2 - 6),
		CFrame.new(ORIGIN - Vector3.new(0, 11, 0)) * flat,
		dark,
		Enum.Material.Rock
	)
	under.Shape = Enum.PartType.Cylinder
	local segments = 36
	for i = 1, segments do
		local a = (i - 0.5) / segments * math.pi * 2
		local at = ORIGIN + Vector3.new(math.cos(a) * (r - 1), 0, math.sin(a) * (r - 1))
		local facing = CFrame.lookAt(at, ORIGIN)
		local h = random:NextNumber(1.5, 6)
		local width = 2 * math.pi * r / segments + 0.4
		part(
			"Muret",
			Vector3.new(width, h, 1.6),
			facing + Vector3.new(0, h / 2, 0),
			dark,
			Enum.Material.Slate
		)
		local barrier = part(
			"MurInvisible",
			Vector3.new(width, 14, 1),
			facing + Vector3.new(0, 7, 0),
			dark,
			Enum.Material.SmoothPlastic
		)
		barrier.Transparency = 1
	end
	for i = 1, 8 do
		local a = (i - 1) / 8 * math.pi * 2
		local at = ORIGIN + Vector3.new(math.cos(a) * (r - 8), 0, math.sin(a) * (r - 8))
		part(
			"Poteau",
			Vector3.new(0.6, 9, 0.6),
			CFrame.new(at + Vector3.new(0, 4.5, 0)),
			dark,
			Enum.Material.Metal
		)
		local lamp = part(
			"Lanterne",
			Vector3.new(1.4, 1.6, 1.4),
			CFrame.new(at + Vector3.new(0, 9.5, 0)),
			lantern,
			Enum.Material.Neon
		)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = lantern
		light.Range = 26
		light.Brightness = 1.6
		light.Parent = lamp
	end
	local brazier = part(
		"Brasero",
		Vector3.new(3, 6, 6),
		CFrame.new(ORIGIN + Vector3.new(0, 1.5, 0)) * flat,
		dark,
		Enum.Material.CorrodedMetal
	)
	brazier.Shape = Enum.PartType.Cylinder
	local fire = Instance.new("Fire")
	fire.Size = 7
	fire.Heat = 12
	fire.Parent = brazier
	local glow = Instance.new("PointLight")
	glow.Color = lantern
	glow.Range = 30
	glow.Brightness = 2
	glow.Parent = brazier
	for _ = 1, 24 do
		local a = random:NextNumber(0, math.pi * 2)
		local d = random:NextNumber(12, r - 6)
		local s = random:NextNumber(0.8, 2.4)
		local rubble = part(
			"Gravat",
			Vector3.new(s, s * 0.6, s * 1.2),
			CFrame.new(ORIGIN + Vector3.new(math.cos(a) * d, s * 0.3, math.sin(a) * d))
				* CFrame.Angles(
					random:NextNumber(-0.3, 0.3),
					random:NextNumber(0, 6.3),
					random:NextNumber(-0.3, 0.3)
				),
			dark,
			Enum.Material.Rock
		)
		rubble.CanCollide = false
	end
end

-- Un point ou se poser dans le salon.
function LobbyService.spot(): Vector3
	local a = random:NextNumber(0, math.pi * 2)
	local d = random:NextNumber(10, LB.radius - 12)
	return ORIGIN + Vector3.new(math.cos(a) * d, 4, math.sin(a) * d)
end

local function publish()
	for id, player in byId do
		local leader = state.groupOf[id]
		local g = leader and state.groups[leader]
		if g then
			local names: { string } = {}
			for _, m in g.members do
				local p = byId[m]
				table.insert(names, if p then p.DisplayName else "?")
			end
			player:SetAttribute(LB.groupAttribute, table.concat(names, ", "))
			player:SetAttribute(LB.modeAttribute, g.mode)
			player:SetAttribute(LB.readyAttribute, g.ready)
		end
	end
	workspace:SetAttribute(
		LB.countdownAttribute,
		if countdown
			then countdown.mode .. "|" .. tostring(
				workspace:GetServerTimeNow() + (countdown.ends - os.clock())
			)
			else nil
	)
end

local function addInvitePrompt(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or root:FindFirstChild("RoyaleInviter") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RoyaleInviter"
	prompt.ActionText = "Inviter dans mon groupe"
	prompt.ObjectText = player.DisplayName
	prompt.HoldDuration = LB.inviteHoldSeconds
	prompt.MaxActivationDistance = LB.inviteDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode[Config.controls.contexts.lobby.invite.keyboard]
	prompt.GamepadKeyCode = Enum.KeyCode[Config.controls.contexts.lobby.invite.gamepad]
	prompt.Parent = root
	prompt.Triggered:Connect(function(from: Player)
		LobbyService.invite(from, player)
	end)
end

-- Pose un joueur dans le salon (personnage neuf).
function LobbyService.place(player: Player)
	if away[player] then
		return
	end
	player:LoadCharacter()
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(LobbyService.spot()))
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.movement.walkSpeed
			humanoid.Died:Connect(function()
				task.wait(2)
				if player.Parent and not away[player] then
					LobbyService.place(player)
				end
			end)
		end
		addInvitePrompt(player)
	end
end

-- `from` invite `to` dans son groupe.
function LobbyService.invite(from: Player, to: Player)
	if from == to or away[from] or away[to] then
		return
	end
	invites[to] = { from = from, at = os.clock() }
	to:SetAttribute(
		LB.inviteAttribute,
		from.DisplayName .. "|" .. tostring(workspace:GetServerTimeNow())
	)
end

local function accept(player: Player)
	local invite = invites[player]
	invites[player] = nil
	player:SetAttribute(LB.inviteAttribute, nil)
	if invite == nil or os.clock() - invite.at > LB.inviteSeconds or invite.from.Parent == nil then
		return
	end
	if Lobby.join(state, idOf(invite.from), idOf(player), LB.maxGroup) then
		print(
			string.format(
				"[Royale] %s rejoint le groupe de %s",
				player.DisplayName,
				invite.from.DisplayName
			)
		)
	end
	publish()
end

local function action(player: Player, name: any)
	if away[player] or typeof(name) ~= "string" then
		return
	end
	local id = idOf(player)
	if name == "accept" then
		accept(player)
		return
	elseif name == "leave" then
		Lobby.leave(state, id, true)
	elseif name == "mode" then
		Lobby.cycleMode(state, id, LB.modes, SIZES)
	elseif name == "ready" then
		local g = state.groups[state.groupOf[id] or ""]
		Lobby.setReady(state, id, not (g and g.ready), SIZES)
	end
	publish()
end

local function launch(mode: string)
	local groups: { { Player } } = {}
	local players: { Player } = {}
	for _, g in Lobby.readyGroups(state, mode) do
		local list: { Player } = {}
		for _, m in g.members do
			local p = byId[m]
			if p and p.Parent then
				table.insert(list, p)
				table.insert(players, p)
			end
		end
		if #list > 0 then
			table.insert(groups, list)
		end
		g.ready = false
	end
	publish()
	if #players == 0 or onLaunch == nil then
		return
	end
	print(string.format("[Royale] Départ du salon : %d joueur(s), mode %s", #players, mode))
	launching = true
	local ok, err = pcall(onLaunch :: any, players, mode, groups)
	launching = false
	if not ok then
		warn("[Royale] Le départ a échoué : " .. tostring(err))
	end
end

local function step()
	if launching then
		return
	end
	if countdown == nil then
		-- Le premier groupe pret lance le compte a rebours de son mode.
		for _, mode in LB.modes do
			if #Lobby.readyGroups(state, mode) > 0 then
				countdown = { mode = mode, ends = os.clock() + LB.countdownSeconds }
				publish()
				break
			end
		end
	elseif #Lobby.readyGroups(state, countdown.mode) == 0 then
		countdown = nil
		publish()
	elseif os.clock() >= countdown.ends then
		local mode = countdown.mode
		countdown = nil
		launch(mode)
	end
end

-- Ces joueurs partent jouer sur ce serveur (Studio) : hors du salon.
function LobbyService.setAway(players: { Player }, isAway: boolean)
	for _, p in players do
		away[p] = if isAway then true else nil
	end
end

function LobbyService.isAway(player: Player): boolean
	return away[player] == true
end

function LobbyService.start(
	remote: RemoteEvent,
	launcher: (players: { Player }, mode: string, groups: { { Player } }) -> ()
)
	onLaunch = launcher
	build()
	workspace:SetAttribute(Config.match.phaseAttribute, "Salon")
	remote.OnServerEvent:Connect(RemoteGuard.wrap(Config.remotes.lobby, action))
	local function joined(player: Player)
		local id = idOf(player)
		byId[id] = player
		Lobby.add(state, id, Config.squads.mode)
		publish()
		LobbyService.place(player)
	end
	for _, player in Players:GetPlayers() do
		joined(player)
	end
	Players.PlayerAdded:Connect(joined)
	Players.PlayerRemoving:Connect(function(player: Player)
		local id = idOf(player)
		Lobby.leave(state, id, false)
		byId[id] = nil
		away[player] = nil
		invites[player] = nil
		publish()
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local ok, err = pcall(step)
			if not ok then
				warn("[Royale] Salon : " .. tostring(err))
			end
		end
	end)
end

return LobbyService
