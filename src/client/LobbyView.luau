--!strict
--[[
	LobbyView — l'ecran du salon, et ses boutons (Config.controls.lobby).

	En haut : une barre discrete (niveau, mode, groupe, pret). En bas : les
	boutons, avec l'icone de la manette. Au centre : une invitation recue (X
	pour accepter), le compte a rebours du depart. Les boutons ne servent qu'au salon (hors partie) ; en partie, ils
	laissent passer aux commandes du jeu.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local ButtonIcons = require(script.Parent.ButtonIcons)

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
	-- En haut, la barre ; en bas, les boutons (Config.lobby.hud).
	local H = LB.hud
	local lantern = rgb(LB.colors.lantern)
	local pale = rgb(H.text)
	local function round(f: GuiObject, radius: UDim)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = radius
		corner.Parent = f
	end
	local function outline(f: GuiObject, color: Color3, transparency: number): UIStroke
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = color
		stroke.Transparency = transparency
		stroke.Parent = f
		return stroke
	end
	local function row(f: GuiObject, gap: number)
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.Padding = UDim.new(0, gap)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = f
	end
	local function padX(f: GuiObject, px: number)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, px)
		pad.PaddingRight = UDim.new(0, px)
		pad.Parent = f
	end
	local function newLabel(
		parent: Instance,
		order: number,
		size: number,
		color: Color3,
		bold: boolean
	): TextLabel
		local l = Instance.new("TextLabel")
		l.LayoutOrder = order
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromOffset(0, size + 4)
		l.AutomaticSize = Enum.AutomaticSize.X
		l.Font = (Enum.Font :: any)[if bold then V.bodyBoldFont else V.bodyFont]
		l.TextSize = size
		l.TextColor3 = color
		l.Text = ""
		l.Parent = parent
		return l
	end
	local function separator(parent: Instance, order: number)
		local s = Instance.new("Frame")
		s.LayoutOrder = order
		s.BorderSizePixel = 0
		s.Size = UDim2.fromOffset(1, H.separatorHeight)
		s.BackgroundColor3 = lantern
		s.BackgroundTransparency = H.separatorTransparency
		s.Parent = parent
	end

	-- La barre : un medaillon de niveau, l'XP en jauge, les credits, le
	-- mode, le groupe, et « pret » en pastille verte.
	local bar = Instance.new("Frame")
	bar.Name = "Barre"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, H.barTop)
	bar.Size = UDim2.fromOffset(0, H.barHeight)
	bar.AutomaticSize = Enum.AutomaticSize.X
	bar.BackgroundColor3 = rgb(H.background)
	bar.BackgroundTransparency = H.transparency
	round(bar, UDim.new(0.5, 0))
	outline(bar, lantern, H.strokeTransparency)
	padX(bar, H.barPadding)
	row(bar, H.barGap)
	bar.Parent = gui
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Transparency = NumberSequence.new(0, 0.25)
	shade.Parent = bar

	local badge = Instance.new("TextLabel")
	badge.Name = "Niveau"
	badge.LayoutOrder = 1
	badge.Size = UDim2.fromOffset(H.badgeSize, H.badgeSize)
	badge.BackgroundColor3 = lantern
	badge.Font = (Enum.Font :: any)[V.bodyBoldFont]
	badge.TextSize = math.floor(H.badgeSize * 0.5)
	badge.TextColor3 = rgb(H.background)
	round(badge, UDim.new(0.5, 0))
	badge.Parent = bar
	local badgeShine = Instance.new("UIGradient")
	badgeShine.Rotation = 90
	badgeShine.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200))
	badgeShine.Parent = badge

	local xpBox = Instance.new("Frame")
	xpBox.Name = "XP"
	xpBox.LayoutOrder = 2
	xpBox.BackgroundTransparency = 1
	xpBox.Size = UDim2.fromOffset(H.xpWidth, H.badgeSize)
	xpBox.Parent = bar
	local xpTitle = newLabel(xpBox, 1, H.smallTextSize, lantern, true)
	xpTitle.Position = UDim2.fromOffset(0, 0)
	local xpTrack = Instance.new("Frame")
	xpTrack.Name = "Jauge"
	xpTrack.AnchorPoint = Vector2.new(0, 1)
	xpTrack.Position = UDim2.new(0, 0, 1, -2)
	xpTrack.Size = UDim2.new(1, 0, 0, H.xpBarHeight)
	xpTrack.BackgroundColor3 = Color3.new(0, 0, 0)
	xpTrack.BackgroundTransparency = 0.4
	round(xpTrack, UDim.new(0.5, 0))
	xpTrack.Parent = xpBox
	local xpFill = Instance.new("Frame")
	xpFill.Name = "Rempli"
	xpFill.Size = UDim2.fromScale(0, 1)
	xpFill.BackgroundColor3 = lantern
	round(xpFill, UDim.new(0.5, 0))
	xpFill.Parent = xpTrack

	separator(bar, 3)
	local coin = Instance.new("Frame")
	coin.Name = "Piece"
	coin.LayoutOrder = 4
	coin.Size = UDim2.fromOffset(H.coinSize, H.coinSize)
	-- Une piece ronde (tournee de 45 degres dans la rangee, le carre restait
	-- un carre, vu en image), avec un liseré sombre.
	coin.BackgroundColor3 = lantern
	round(coin, UDim.new(0.5, 0))
	outline(coin, Color3.fromRGB(120, 70, 30), 0).Thickness = 2
	coin.Parent = bar
	local credits = newLabel(bar, 5, H.barTextSize, pale, true)
	separator(bar, 6)
	local modeChip = Instance.new("Frame")
	modeChip.Name = "Mode"
	modeChip.LayoutOrder = 7
	modeChip.BackgroundTransparency = 1
	modeChip.Size = UDim2.fromOffset(0, H.chipHeight)
	modeChip.AutomaticSize = Enum.AutomaticSize.X
	round(modeChip, UDim.new(0.5, 0))
	outline(modeChip, lantern, 0.2)
	padX(modeChip, H.chipPadding)
	row(modeChip, 0)
	modeChip.Parent = bar
	local modeText = newLabel(modeChip, 1, H.smallTextSize, lantern, true)
	local groupText = newLabel(bar, 8, H.barTextSize, pale, false)
	local readyChip = Instance.new("Frame")
	readyChip.Name = "Pret"
	readyChip.LayoutOrder = 9
	readyChip.Size = UDim2.fromOffset(0, H.chipHeight)
	readyChip.AutomaticSize = Enum.AutomaticSize.X
	round(readyChip, UDim.new(0.5, 0))
	local readyStroke = outline(readyChip, pale, 0.6)
	padX(readyChip, H.chipPadding)
	row(readyChip, 0)
	readyChip.Parent = bar
	local readyText = newLabel(readyChip, 1, H.smallTextSize, pale, true)

	-- En bas, chaque bouton dans sa pastille ; « Pret » est l'action
	-- principale, en couleur lanterne.
	local hints = Instance.new("Frame")
	hints.Name = "Boutons"
	hints.AnchorPoint = Vector2.new(0.5, 1)
	hints.Position = UDim2.new(0.5, 0, 1, -H.hintBottom)
	hints.Size = UDim2.fromOffset(0, H.hintHeight)
	hints.AutomaticSize = Enum.AutomaticSize.X
	hints.BackgroundTransparency = 1
	row(hints, H.hintGap)
	hints.Parent = gui
	-- Les boutons ne se redessinent que si leur liste change (Roblox deplace
	-- la selection quand un element detruit la portait).
	local shownHints = ""
	local function showHints(list: { { binding: ButtonIcons.Binding, text: string } })
		local key = (if ButtonIcons.gamepad() then "m" else "c")
		for _, h in list do
			key ..= "|" .. h.text
		end
		if key == shownHints then
			return
		end
		shownHints = key
		for _, c in hints:GetChildren() do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		for i, h in list do
			local primary = i == 1
			local p = Instance.new("Frame")
			p.Name = "Pastille" .. i
			p.LayoutOrder = i
			p.Size = UDim2.fromOffset(0, H.hintHeight)
			p.AutomaticSize = Enum.AutomaticSize.X
			p.BackgroundColor3 = if primary then rgb(H.primaryBackground) else rgb(H.background)
			p.BackgroundTransparency = H.transparency
			round(p, UDim.new(0.5, 0))
			outline(p, lantern, if primary then 0 else H.strokeTransparency)
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, H.hintInset)
			pad.PaddingRight = UDim.new(0, H.chipPadding + H.hintInset)
			pad.Parent = p
			p.Parent = hints
			local chip = ButtonIcons.chip(p, h.binding, h.text, H.hintIcon, H.hintTextSize, 1)
			chip.AnchorPoint = Vector2.new(0, 0.5)
			chip.Position = UDim2.fromScale(0, 0.5)
		end
	end
	-- Barre et boutons tiennent dans l'ecran : la mesure part de leur taille
	-- sans echelle (AbsoluteSize / Scale), jamais d'une largeur recopiee.
	-- Une echelle par element : elle les reduit autour de leur ancre (en
	-- haut au milieu, en bas au milieu).
	local fit = Instance.new("UIScale")
	fit.Parent = bar
	local fitHints = Instance.new("UIScale")
	fitHints.Parent = hints
	local function refit()
		local camera = workspace.CurrentCamera
		if camera == nil or fit.Scale <= 0 then
			return
		end
		local widest = math.max(bar.AbsoluteSize.X, hints.AbsoluteSize.X) / fit.Scale
		if widest > 0 then
			fit.Scale = math.min(1, (camera.ViewportSize.X - 2 * H.screenMargin) / widest)
			fitHints.Scale = fit.Scale
		end
	end
	-- « 1450 » se lit « 1 450 ».
	local function thousands(n: number): string
		local s = tostring(math.floor(n))
		return (string.reverse((string.gsub(string.reverse(s), "(%d%d%d)", "%1 "))):gsub("^ ", ""))
	end
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
		local A = Config.progression.attributes
		local level = player:GetAttribute(A.level)
		if typeof(level) == "number" then
			local xp = player:GetAttribute(A.xp) or 0
			local needed = player:GetAttribute(A.xpNeeded) or 0
			badge.Text = tostring(level)
			xpTitle.Text = string.format("%d / %d XP", xp, needed)
			xpFill.Size =
				UDim2.fromScale(if needed > 0 then math.clamp(xp / needed, 0, 1) else 0, 1)
			credits.Text = thousands(player:GetAttribute(A.credits) or 0)
		else
			badge.Text = "…"
			xpTitle.Text = "Profil en chargement…"
			credits.Text = "…"
		end
		if player:GetAttribute(A.unreadable) == true then
			xpTitle.Text = "Profil illisible : rien ne sera sauvegardé"
		end
		local members = if typeof(group) == "string" then group else player.DisplayName
		local count = #string.split(members, ", ")
		modeText.Text = string.upper(modeName)
		groupText.Text =
			string.format("%s  %d/%d", if count > 1 then members else "Seul", count, LB.maxGroup)
		readyText.Text = if ready then "PRÊT" else "PAS PRÊT"
		readyText.TextColor3 = if ready then rgb(H.background) else pale
		readyChip.BackgroundColor3 = rgb(H.ready)
		readyChip.BackgroundTransparency = if ready then 0 else 1
		readyStroke.Transparency = if ready then 1 else 0.6
		local list = {
			{ binding = K.ready, text = if ready then "Annuler" else "Prêt" },
			{ binding = K.mode, text = "Mode" },
			{ binding = K.invite, text = "Inviter (maintenu)" },
			{ binding = K.robloxInvite, text = "Amis Roblox" },
		}
		if count > 1 then
			table.insert(list, { binding = K.leaveGroup, text = "Quitter le groupe" })
		end
		showHints(list)
		refit()
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
		local reward = recent(
			player:GetAttribute(Config.progression.attributes.lastReward),
			Config.progression.rewardSeconds
		)
		if reward then
			text = if text == ""
				then "Dernière partie : " .. reward
				else text .. "\nDernière partie : " .. reward
		end
		center.Text = text
	end)
end

return LobbyView
