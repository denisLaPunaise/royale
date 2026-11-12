--!strict
--[[
	LobbyView — l'ecran du salon, et ses boutons (Config.controls.lobby).

	A gauche : son groupe, le mode, pret ou non, et ce qu'on peut faire. Au
	centre : une invitation recue (X pour accepter), le compte a rebours du
	depart. Les boutons ne servent qu'au salon (hors partie) ; en partie, ils
	laissent passer aux commandes du jeu.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local LobbyView = {}

local LB = Config.lobby
local V = Config.view
local K = Config.controls.contexts.lobby

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- « texte|heure » encore valable ?
local function recent(value: any, seconds: number): string?
	if typeof(value) ~= "string" then
		return nil
	end
	local text, at = string.match(value, "^(.-)|(.+)$")
	local t = tonumber(at)
	if text and t and workspace:GetServerTimeNow() - t < seconds then
		return text
	end
	return nil
end

local function label(
	parent: Instance,
	size: UDim2,
	position: UDim2,
	anchor: Vector2,
	textSize: number
): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = position
	l.AnchorPoint = anchor
	l.Font = (Enum.Font :: any)[V.font]
	l.TextScaled = true
	l.TextWrapped = true
	l.TextColor3 = Color3.fromRGB(240, 232, 220)
	l.TextStrokeTransparency = 0.4
	l.Text = ""
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = textSize
	limit.Parent = l
	l.Parent = parent
	return l
end

function LobbyView.start()
	local player = Players.LocalPlayer
	local remote =
		Royale:WaitForChild(Config.remotes.folder):WaitForChild(Config.remotes.lobby) :: RemoteEvent

	local gui = Instance.new("ScreenGui")
	gui.Name = "RoyaleSalon"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")
	local panel =
		label(gui, UDim2.new(0.42, 0, 0, 230), UDim2.new(0, 20, 0, 60), Vector2.new(0, 0), 22)
	panel.TextXAlignment = Enum.TextXAlignment.Left
	panel.TextYAlignment = Enum.TextYAlignment.Top
	local center =
		label(gui, UDim2.new(0.8, 0, 0, 80), UDim2.fromScale(0.5, 0.22), Vector2.new(0.5, 0), 30)
	center.TextColor3 = rgb(LB.colors.lantern)

	-- Au salon : pas participant d'une partie (l'attribut n'existe pas).
	local function inLobby(): boolean
		return player:GetAttribute(Config.match.aliveAttribute) == nil
	end

	local function bind(
		name: string,
		binding: { gamepad: string, keyboard: string },
		fn: () -> boolean
	)
		-- En priorite haute : les commandes du jeu (Y pousser) avalaient le
		-- bouton (vu en sonde).
		ContextActionService:BindActionAtPriority(
			name,
			function(_, state: Enum.UserInputState)
				if state ~= Enum.UserInputState.Begin or not inLobby() then
					return Enum.ContextActionResult.Pass
				end
				return if fn() then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
			end,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode[binding.gamepad],
			Enum.KeyCode[binding.keyboard]
		)
	end
	bind("RoyaleSalonMode", K.mode, function()
		remote:FireServer("mode")
		return true
	end)
	bind("RoyaleSalonPret", K.ready, function()
		remote:FireServer("ready")
		return true
	end)
	bind("RoyaleSalonQuitter", K.leaveGroup, function()
		remote:FireServer("leave")
		return true
	end)
	-- X : accepter une invitation en cours ; sinon X sert aux invites
	-- (maintenu sur quelqu'un, on l'invite).
	bind("RoyaleSalonAccepter", K.invite, function()
		if recent(player:GetAttribute(LB.inviteAttribute), LB.inviteSeconds) then
			remote:FireServer("accept")
			return true
		end
		return false
	end)
	bind("RoyaleSalonAmis", K.robloxInvite, function()
		local ok, err = pcall(function()
			SocialService:PromptGameInvite(player)
		end)
		if not ok then
			warn("[Royale] Invitation Roblox : " .. tostring(err))
		end
		return true
	end)

	RunService.RenderStepped:Connect(function()
		local here = inLobby() and workspace:GetAttribute(Config.match.phaseAttribute) ~= nil
		gui.Enabled = here
		if not here then
			return
		end
		local group = player:GetAttribute(LB.groupAttribute)
		local mode = player:GetAttribute(LB.modeAttribute)
		local ready = player:GetAttribute(LB.readyAttribute) == true
		local modeName = if typeof(mode) == "string" then LB.modeNames[mode] or mode else "?"
		panel.Text = table.concat({
			"LE SALON",
			"Ton groupe : " .. (if typeof(group) == "string" then group else player.DisplayName),
			"Mode : " .. modeName .. "   (Y changer — le chef)",
			if ready then "PRÊT — R2 pour annuler" else "R2 : se dire prêt",
			"X maintenu sur un joueur : l'inviter",
			"Croix haut : inviter des amis Roblox",
			"B : quitter son groupe",
		}, "\n")
		local text = ""
		local invite = recent(player:GetAttribute(LB.inviteAttribute), LB.inviteSeconds)
		if invite then
			text = invite .. " t'invite dans son groupe — X pour accepter"
		end
		local depart = workspace:GetAttribute(LB.countdownAttribute)
		if typeof(depart) == "string" then
			local m, at = string.match(depart, "^(.-)|(.+)$")
			local t = tonumber(at)
			if m and t then
				local line = string.format(
					"Départ en %s dans %d s",
					LB.modeNames[m] or m,
					math.max(0, math.ceil(t - workspace:GetServerTimeNow()))
				)
				text = if text == "" then line else text .. "\n" .. line
			end
		end
		center.Text = text
	end)
end

return LobbyView
