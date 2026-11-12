--!strict
--[[
	Spectate — elimine pour de bon (ou arrive en cours de partie), on regarde
	ceux qui restent : la camera derriere eux, ses coequipiers d'abord
	(CONCEPT.md : regarder un coequipier). L1 / R1 pour changer, X pour
	parier sur celui qu'on regarde, B pour quitter.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Spectate = {}

local V = Config.view
local S = Config.controls.contexts.spectating

function Spectate.start()
	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera
	local index = 1
	local watching = false

	-- Ceux qu'on peut regarder : les joueurs et les bots encore en vie (on ne
	-- doit pas pouvoir les distinguer).
	type Watched = { key: string, character: Model, actor: Instance, mate: boolean }
	local function isMate(actor: Instance): boolean
		local mine = player:GetAttribute(Config.squads.attribute)
		return mine ~= nil and actor:GetAttribute(Config.squads.attribute) == mine
	end
	local function candidates(): { Watched }
		local out: { Watched } = {}
		for _, other in Players:GetPlayers() do
			if
				other ~= player
				and other:GetAttribute(Config.match.aliveAttribute) == true
				and other.Character
			then
				table.insert(out, {
					key = other.Name,
					character = other.Character,
					actor = other,
					mate = isMate(other),
				})
			end
		end
		local bots = workspace:FindFirstChild(Config.bots.folder)
		if bots then
			for _, model in bots:GetChildren() do
				if
					model:IsA("Model")
					and model:GetAttribute(Config.match.aliveAttribute) == true
				then
					table.insert(
						out,
						{ key = model.Name, character = model, actor = model, mate = isMate(model) }
					)
				end
			end
		end
		table.sort(out, function(a, b)
			if a.mate ~= b.mate then
				return a.mate
			end
			return a.key < b.key
		end)
		return out
	end

	local function shift(_, state: Enum.UserInputState, input: InputObject)
		if not watching or state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		local forward = input.KeyCode == Enum.KeyCode[S.nextPlayer.gamepad]
			or input.KeyCode == Enum.KeyCode[S.nextPlayer.keyboard]
		index += if forward then 1 else -1
		return Enum.ContextActionResult.Sink
	end
	ContextActionService:BindAction(
		"RoyaleRegarder",
		shift,
		false,
		Enum.KeyCode[S.nextPlayer.gamepad],
		Enum.KeyCode[S.nextPlayer.keyboard],
		Enum.KeyCode[S.previousPlayer.gamepad],
		Enum.KeyCode[S.previousPlayer.keyboard]
	)

	-- Ce qu'on regarde et ce qu'on peut faire, en bas de l'ecran.
	local gui = Instance.new("ScreenGui")
	gui.Name = "RoyaleSpectateur"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local info = Instance.new("TextLabel")
	info.BackgroundTransparency = 1
	info.AnchorPoint = Vector2.new(0.5, 1)
	info.Position = UDim2.new(0.5, 0, 1, -V.spectateInfoBottom)
	info.Size = UDim2.new(0.9, 0, 0, V.spectateInfoHeight)
	info.Font = (Enum.Font :: any)[V.font]
	info.TextScaled = true
	info.TextColor3 = Color3.fromRGB(240, 232, 220)
	info.TextStrokeTransparency = 0.4
	info.Text = ""
	info.Parent = gui
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = V.spectateInfoTextSize
	limit.Parent = info

	local remotes = Royale:WaitForChild(Config.remotes.folder)
	local betRemote = remotes:WaitForChild(Config.remotes.bet) :: RemoteEvent
	local quitRemote = remotes:WaitForChild(Config.remotes.quit) :: RemoteEvent
	local current: Instance? = nil
	ContextActionService:BindAction("RoyaleParier", function(_, state: Enum.UserInputState)
		if not watching or state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if current then
			betRemote:FireServer(current)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode[S.bet.gamepad], Enum.KeyCode[S.bet.keyboard])
	ContextActionService:BindAction("RoyaleQuitter", function(_, state: Enum.UserInputState)
		if not watching or state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		quitRemote:FireServer()
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode[S.leave.gamepad], Enum.KeyCode[S.leave.keyboard])

	RunService:BindToRenderStep("RoyaleSpectateur", Enum.RenderPriority.Camera.Value + 2, function()
		local phase = workspace:GetAttribute(Config.match.phaseAttribute)
		local mine = player:GetAttribute(Config.match.aliveAttribute)
		-- Au Ventre (le goulag), on joue encore : pas de spectateur.
		local inBelly = player:GetAttribute(Config.goulag.stateAttribute) ~= nil
		local left = player:GetAttribute(Config.bets.leftAttribute) == true
		-- Seulement un participant elimine (ceux du salon n'ont pas l'attribut).
		local should = (phase == "Partie" or phase == "Fin")
			and mine == false
			and not inBelly
			and not left
		local list = if should then candidates() else {}
		info.Text = if left and phase == "Partie"
			then "Tu as quitté la partie — retour au salon à la fin"
			else ""
		if not should or #list == 0 then
			current = nil
			if watching then
				watching = false
				camera.CameraType = Enum.CameraType.Custom
			end
			return
		end
		watching = true
		index = ((index - 1) % #list) + 1
		local watched = list[index]
		current = watched.actor
		local bet = player:GetAttribute(Config.bets.attribute)
		info.Text = string.format(
			"Tu regardes %s%s — L1 / R1 changer · %s · B quitter",
			watched.key,
			if watched.mate then " (ton équipe)" else "",
			if typeof(bet) == "string" then "pari sur " .. bet else "X parier sur lui"
		)
		local root = list[index].character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			camera.CameraType = Enum.CameraType.Scriptable
			local look = root.CFrame.LookVector
			local from = root.Position
				- look * V.spectateDistance
				+ Vector3.new(0, V.spectateHeight, 0)
			-- Un mur entre lui et la camera : elle s'arrete devant (vu en
			-- image : derriere un batiment, l'ecran etait noir).
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { list[index].character }
			local hit = workspace:Raycast(root.Position, from - root.Position, params)
			if hit then
				from = hit.Position + (root.Position - hit.Position).Unit * V.spectateWallGap
			end
			camera.CFrame = CFrame.lookAt(from, root.Position)
		end
	end)
end

return Spectate
