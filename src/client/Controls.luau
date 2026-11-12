--!strict
--[[
	Controls — le corps : courir (L3 bascule, Maj maintenu), s'accroupir (B ou
	C), et sortir de sa cachette (X ou E). Les boutons viennent de
	Config.controls, jamais d'ici.

	La vitesse et la hauteur se reglent sur le client : c'est lui qui fait
	bouger son personnage. Accroupi, la tete descend vraiment : derriere un
	muret, l'Oeil (qui vise la tete et le bassin) ne te voit plus.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Controls = {}

local onFoot = Config.controls.contexts.onFoot
local hiddenCtx = Config.controls.contexts.hidden
local Mv = Config.movement

local function keys(
	binding: { gamepad: string, keyboard: string }
): { Enum.KeyCode | Enum.UserInputType }
	local out: { Enum.KeyCode | Enum.UserInputType } = {}
	for _, name in { binding.gamepad, binding.keyboard } do
		local ok, code = pcall(function()
			return (Enum.KeyCode :: any)[name]
		end)
		if ok and code then
			table.insert(out, code)
		else
			table.insert(out, (Enum.UserInputType :: any)[name])
		end
	end
	return out
end

function Controls.start()
	local player = Players.LocalPlayer
	local leaveRemote = Royale:WaitForChild(Config.remotes.folder)
		:WaitForChild(Config.remotes.leave) :: RemoteEvent

	local running = false
	local crouched = false
	local baseHip: number? = nil

	local function apply()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid == nil then
			return
		end
		if baseHip == nil then
			baseHip = humanoid.HipHeight
		end
		humanoid.WalkSpeed = if crouched
			then Mv.crouchSpeed
			elseif running then Mv.runSpeed
			else Mv.walkSpeed
		humanoid.HipHeight = (baseHip :: number) - (if crouched then Mv.crouchHipDrop else 0)
	end

	player.CharacterAdded:Connect(function()
		running, crouched, baseHip = false, false, nil
		task.defer(apply)
	end)

	ContextActionService:BindAction(
		"RoyaleCourir",
		function(_, state: Enum.UserInputState, input: InputObject)
			if input.KeyCode == Enum.KeyCode[onFoot.sprint.gamepad] then
				-- A la manette : bascule.
				if state == Enum.UserInputState.Begin then
					running = not running
					crouched = false
				end
			else
				running = state == Enum.UserInputState.Begin
				if running then
					crouched = false
				end
			end
			apply()
			return Enum.ContextActionResult.Pass
		end,
		false,
		table.unpack(keys(onFoot.sprint))
	)

	ContextActionService:BindAction("RoyalePosture", function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			crouched = not crouched
			if crouched then
				running = false
			end
			apply()
		end
		return Enum.ContextActionResult.Pass
	end, false, table.unpack(keys(onFoot.posture)))

	-- Sortir : seulement quand on est cache (sinon X sert aux invites).
	ContextActionService:BindAction("RoyaleSortir", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if player:GetAttribute(Config.hiding.hiddenAttribute) == nil then
			return Enum.ContextActionResult.Pass
		end
		leaveRemote:FireServer()
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(keys(hiddenCtx.leave)))
end

return Controls
