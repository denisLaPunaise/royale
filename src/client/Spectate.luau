--!strict
--[[
	Spectate — apres l'aspiration (ou arrive en cours de partie), on regarde
	ceux qui restent : la camera derriere eux, L1 / R1 pour changer.
	(Le goulag viendra s'intercaler ici.)
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
	type Watched = { key: string, character: Model }
	local function candidates(): { Watched }
		local out: { Watched } = {}
		for _, other in Players:GetPlayers() do
			if
				other ~= player
				and other:GetAttribute(Config.match.aliveAttribute) == true
				and other.Character
			then
				table.insert(out, { key = other.Name, character = other.Character })
			end
		end
		local bots = workspace:FindFirstChild(Config.bots.folder)
		if bots then
			for _, model in bots:GetChildren() do
				if
					model:IsA("Model")
					and model:GetAttribute(Config.match.aliveAttribute) == true
				then
					table.insert(out, { key = model.Name, character = model })
				end
			end
		end
		table.sort(out, function(a, b)
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

	RunService:BindToRenderStep("RoyaleSpectateur", Enum.RenderPriority.Camera.Value + 2, function()
		local phase = workspace:GetAttribute(Config.match.phaseAttribute)
		local mine = player:GetAttribute(Config.match.aliveAttribute)
		local should = (phase == "Partie" or phase == "Fin") and mine ~= true
		local list = if should then candidates() else {}
		if not should or #list == 0 then
			if watching then
				watching = false
				camera.CameraType = Enum.CameraType.Custom
			end
			return
		end
		watching = true
		index = ((index - 1) % #list) + 1
		local root = list[index].character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			camera.CameraType = Enum.CameraType.Scriptable
			local look = root.CFrame.LookVector
			local from = root.Position
				- look * V.spectateDistance
				+ Vector3.new(0, V.spectateHeight, 0)
			camera.CFrame = CFrame.lookAt(from, root.Position)
		end
	end)
end

return Spectate
