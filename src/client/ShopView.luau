--!strict
--[[
	ShopView — la boutique au salon (croix gauche), a la manette : la croix
	choisit une ligne, L1 / R1 changent d'onglet, A achete ou equipe, B ferme.
	Une navigation a nous, plutot que celle de Roblox : elle marche pareil au
	clavier et se teste sans manette.

	Onglets : la boutique du jour et les permanents, les tirages (avec TOUTES
	les chances affichees avant d'acheter), le passe, ses cosmetiques, les
	credits en Robux. Le serveur verifie tout (ShopService).
]]

local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local ShopView = {}

local CO = Config.cosmetics
local SH = Config.shop
local PA = Config.pass
local V = Config.view
local K = Config.controls.contexts.shopPanel
local TABS = { "Boutique", "Tirages", "Passe", "Défis", "Mes cosmétiques", "Crédits" }

type Row = { text: string, action: string?, arg: any? }

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function decode(value: any): any
	if typeof(value) ~= "string" then
		return nil
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(value)
	end)
	return if ok then data else nil
end

local function describe(id: string): string
	local def = CO.items[id]
	if def == nil then
		return id
	end
	local rarity = Config.rarities[def.rarity]
	return string.format(
		"%s (%s, %s)",
		def.name,
		CO.slotNames[def.slot],
		rarity and rarity.name or def.rarity
	)
end

function ShopView.start()
	local player = Players.LocalPlayer
	local remote =
		Royale:WaitForChild(Config.remotes.folder):WaitForChild(Config.remotes.shop) :: RemoteEvent

	local gui = Instance.new("ScreenGui")
	gui.Name = "RoyaleBoutique"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = SH.displayOrder
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")
	-- Defilant : la liste des tirages depasse d'un petit ecran (vu en image).
	local frame = Instance.new("ScrollingFrame")
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.CanvasSize = UDim2.new()
	frame.ScrollBarThickness = 6
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	-- Large au plus de `panelWidth`, et jamais plus que l'ecran (vu en image :
	-- il debordait d'une petite fenetre).
	frame.Size = UDim2.fromScale(0.95, 0.8)
	frame.BackgroundColor3 = rgb(SH.background)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local scale = Instance.new("UISizeConstraint")
	scale.MaxSize = Vector2.new(SH.panelWidth, math.huge)
	scale.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	local labels: { TextLabel } = {}
	local footer = Instance.new("TextLabel")
	footer.BackgroundTransparency = 1
	footer.Size = UDim2.new(1, 0, 0, SH.rowHeight)
	footer.Font = (Enum.Font :: any)[V.bodyFont]
	footer.TextSize = SH.textSize
	footer.TextColor3 = Color3.fromRGB(170, 160, 150)
	footer.Text = "A : choisir   B : fermer"
	-- Toujours en bas, apres toutes les lignes.
	footer.LayoutOrder = 100000
	footer.Parent = frame

	local function line(i: number): TextLabel
		local l = labels[i]
		if l == nil then
			l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Size = UDim2.new(1, 0, 0, SH.rowHeight)
			l.Font = (Enum.Font :: any)[V.bodyFont]
			l.TextSize = SH.textSize
			l.TextScaled = true
			local limit = Instance.new("UITextSizeConstraint")
			limit.MaxTextSize = SH.textSize
			limit.Parent = l
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.TextColor3 = Color3.fromRGB(240, 232, 220)
			l.LayoutOrder = i
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 12)
			pad.Parent = l
			l.Parent = frame
			labels[i] = l
		end
		return l :: TextLabel
	end

	local tab, selected, open = 1, 1, false

	-- Les lignes de l'onglet en cours, d'apres ce que le serveur publie.
	local function rows(): { Row }
		local world = decode(workspace:GetAttribute(SH.worldAttribute)) or {}
		local me = decode(player:GetAttribute(SH.playerAttribute)) or {}
		local owned = me.owned or {}
		local equipped = me.equipped or {}
		local credits = player:GetAttribute(Config.progression.attributes.credits) or 0
		local fragments = player:GetAttribute(Config.progression.attributes.fragments) or 0
		local out: { Row } = {}
		local name = TABS[tab]
		if name == "Boutique" then
			table.insert(
				out,
				{ text = string.format("Tes crédits : %d   (prix provisoires)", credits) }
			)
			table.insert(out, { text = "— Aujourd'hui —" })
			for _, id in world.daily or {} do
				local price = CO.prices[CO.items[id].rarity]
				table.insert(out, {
					text = describe(id) .. (if owned[id]
						then " — à toi"
						else string.format(" — %d crédits", price)),
					action = if owned[id] then nil else "buy",
					arg = id,
				})
			end
			table.insert(out, { text = "— Toujours là —" })
			for _, id in SH.permanent do
				local price = CO.prices[CO.items[id].rarity]
				table.insert(out, {
					text = describe(id) .. (if owned[id]
						then " — à toi"
						else string.format(" — %d crédits", price)),
					action = if owned[id] then nil else "buy",
					arg = id,
				})
			end
		elseif name == "Tirages" then
			local cost = Config.progression.fragments.perDraw
			table.insert(out, {
				text = string.format(
					"Tirage gratuit : %d fragments (tu en as %d)",
					cost,
					fragments
				),
				action = "drawFragments",
			})
			if me.restricted then
				table.insert(out, { text = "Tirage en crédits : pas disponible pour toi" })
			else
				table.insert(out, {
					text = string.format(
						"Tirage : %d crédits (tu en as %d)",
						world.drawPrice or 0,
						credits
					),
					action = "drawCredits",
				})
			end
			table.insert(out, { text = "— Ce qui peut tomber, et ses chances —" })
			local chances = world.chances or {}
			-- Par rarete, de la plus rare a la plus commune : la part de chaque
			-- rarete, puis chaque objet et sa chance (deux decimales : avec
			-- ~90 objets, « 1 % » arrondissait 0,83 %).
			local order = { "legendary", "epic", "rare", "common" }
			for _, rarity in order do
				local ids: { string } = {}
				local part = 0
				for id, chance in chances do
					if CO.items[id] and CO.items[id].rarity == rarity then
						table.insert(ids, id)
						part += chance
					end
				end
				if #ids > 0 then
					table.sort(ids, function(x, y)
						return CO.items[x].name < CO.items[y].name
					end)
					local info = Config.rarities[rarity]
					table.insert(out, {
						text = string.format(
							"— %s : %s %% en tout —",
							info and info.name or rarity,
							string.gsub(string.format("%.0f", part * 100), "%.", ",")
						),
					})
					for _, id in ids do
						table.insert(out, {
							text = string.format(
								"%s — %s %%%s",
								describe(id),
								(string.gsub(string.format("%.2f", chances[id] * 100), "%.", ",")),
								if owned[id] then " (à toi : rend des crédits)" else ""
							),
						})
					end
				end
			end
			table.insert(out, { text = "Chaque tirage donne un objet. Total : 100 %." })
		elseif name == "Passe" then
			local tier = me.tier or 0
			table.insert(out, {
				text = string.format(
					"Saison %d — palier %d / %d (%d XP)",
					PA.season,
					tier,
					PA.tiers,
					me.passXp or 0
				),
			})
			if me.premium then
				table.insert(out, { text = "Passe premium : débloqué" })
			elseif PA.premiumProductId ~= 0 then
				table.insert(out, {
					text = string.format("Débloquer le passe premium : %d Robux", PA.premiumRobux),
					action = "pass",
				})
			else
				table.insert(out, { text = "Passe premium : pas encore en vente" })
			end
			table.insert(out, { text = "— Prochaines récompenses —" })
			local shown = 0
			for t = tier + 1, PA.tiers do
				for track, label in { [PA.free] = "gratuit", [PA.premium] = "premium" } do
					local reward = track[t]
					if reward and shown < SH.passPreview then
						shown += 1
						table.insert(out, {
							text = string.format(
								"Palier %d (%s) : %s",
								t,
								label,
								if reward.credits
									then reward.credits .. " crédits"
									else describe(reward.item)
							),
						})
					end
				end
			end
		elseif name == "Défis" then
			local defis = decode(player:GetAttribute(Config.challenges.attribute)) or {}
			for _, part in { { "Aujourd'hui", defis.daily }, { "Cette semaine", defis.weekly } } do
				table.insert(out, { text = "— " .. part[1] .. " —" })
				for _, c in part[2] or {} do
					table.insert(out, {
						text = string.format(
							"%s%s : %d / %d",
							if c.done then "✓ " else "",
							c.text,
							c.progress,
							c.goal
						),
					})
				end
			end
			table.insert(out, {
				text = string.format(
					"Un défi du jour : %d XP de passe et %d crédits (la semaine : x%d)",
					Config.challenges.passXp,
					Config.challenges.credits,
					Config.challenges.weeklyRewardFactor
				),
			})
		elseif name == "Mes cosmétiques" then
			local ids: { string } = {}
			for id in owned do
				table.insert(ids, id)
			end
			table.sort(ids)
			if #ids == 0 then
				table.insert(out, { text = "Rien encore : achète, tire ou monte le passe." })
			end
			for _, id in ids do
				local def = CO.items[id]
				if def then
					table.insert(out, {
						text = describe(id) .. (if equipped[def.slot] == id
							then " — porté (A enlever)"
							else " — A porter"),
						action = "equip",
						arg = id,
					})
				end
			end
		else
			local any = false
			for i, pack in SH.creditPacks do
				if pack.productId ~= 0 then
					any = true
					table.insert(out, {
						text = string.format(
							"%d crédits — %d Robux (provisoire)",
							pack.credits,
							pack.robux
						),
						action = "pack",
						arg = i,
					})
				end
			end
			if not any then
				table.insert(out, { text = "Les crédits en Robux ne sont pas encore en vente." })
			end
			table.insert(out, { text = "Tout se gagne aussi en jouant." })
		end
		return out
	end

	local function render()
		local list = rows()
		-- La selection reste sur une ligne qui fait quelque chose.
		selected = math.clamp(selected, 1, math.max(#list, 1))
		local header = line(1)
		local names = {}
		for i, n in TABS do
			table.insert(names, if i == tab then "[" .. n .. "]" else n)
		end
		header.Text = table.concat(names, "  ") .. "     L1 / R1"
		header.TextColor3 = rgb(SH.selected)
		for i, row in list do
			local l = line(i + 1)
			l.Visible = true
			local chosen = i == selected
			l.Text = (if chosen then "▶ " else "   ") .. row.text
			l.TextColor3 = if chosen
				then rgb(SH.selected)
				elseif row.action then Color3.fromRGB(240, 232, 220)
				else Color3.fromRGB(170, 160, 150)
		end
		for i = #list + 2, #labels do
			labels[i].Visible = false
		end
		-- La ligne choisie reste a l'ecran.
		local y = selected * SH.rowHeight
		frame.CanvasPosition = Vector2.new(0, math.max(0, y - frame.AbsoluteSize.Y / 2))
	end

	local function move(step: number)
		local list = rows()
		if #list == 0 then
			return
		end
		-- On saute les lignes qui ne font rien.
		for _ = 1, #list do
			selected = (selected - 1 + step) % #list + 1
			if list[selected].action then
				break
			end
		end
	end

	local function close()
		open = false
		gui.Enabled = false
		for _, name in
			{
				"RoyaleBoutiqueHaut",
				"RoyaleBoutiqueBas",
				"RoyaleBoutiqueOnglet",
				"RoyaleBoutiqueA",
				"RoyaleBoutiqueFermer",
			}
		do
			ContextActionService:UnbindAction(name)
		end
	end

	local function bind(
		name: string,
		binding: { gamepad: string, keyboard: string },
		fn: (Enum.KeyCode) -> ()
	)
		ContextActionService:BindActionAtPriority(
			name,
			function(_, state: Enum.UserInputState, input: InputObject)
				if state == Enum.UserInputState.Begin then
					fn(input.KeyCode)
					render()
				end
				return Enum.ContextActionResult.Sink
			end,
			false,
			Enum.ContextActionPriority.High.Value + 1,
			Enum.KeyCode[binding.gamepad],
			Enum.KeyCode[binding.keyboard]
		)
	end

	local function openShop()
		open = true
		gui.Enabled = true
		tab, selected = 1, 1
		move(1)
		bind("RoyaleBoutiqueHaut", K.up, function()
			move(-1)
		end)
		bind("RoyaleBoutiqueBas", K.down, function()
			move(1)
		end)
		ContextActionService:BindActionAtPriority(
			"RoyaleBoutiqueOnglet",
			function(_, state: Enum.UserInputState, input: InputObject)
				if state == Enum.UserInputState.Begin then
					local forward = input.KeyCode == Enum.KeyCode[K.nextTab.gamepad]
						or input.KeyCode == Enum.KeyCode[K.nextTab.keyboard]
					tab = (tab - 1 + (if forward then 1 else -1)) % #TABS + 1
					selected = 0
					move(1)
					render()
				end
				return Enum.ContextActionResult.Sink
			end,
			false,
			Enum.ContextActionPriority.High.Value + 1,
			Enum.KeyCode[K.nextTab.gamepad],
			Enum.KeyCode[K.nextTab.keyboard],
			Enum.KeyCode[K.previousTab.gamepad],
			Enum.KeyCode[K.previousTab.keyboard]
		)
		bind("RoyaleBoutiqueA", K.confirm, function()
			local row = rows()[selected]
			if row and row.action then
				remote:FireServer(row.action, row.arg)
			end
		end)
		bind("RoyaleBoutiqueFermer", K.close, function()
			close()
		end)
		render()
	end

	local shopKey = Config.controls.contexts.lobby.shop
	ContextActionService:BindActionAtPriority(
		"RoyaleBoutique",
		function(_, state: Enum.UserInputState)
			if state ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end
			-- Seulement au salon (pas participant d'une partie).
			if player:GetAttribute(Config.match.aliveAttribute) ~= nil then
				return Enum.ContextActionResult.Pass
			end
			if open then
				close()
			else
				openShop()
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode[shopKey.gamepad],
		Enum.KeyCode[shopKey.keyboard]
	)

	-- Ce que le serveur change (achat, credits) se voit tout de suite.
	RunService.Heartbeat:Connect(function()
		if open and player:GetAttribute(Config.match.aliveAttribute) ~= nil then
			close()
		end
	end)
	player:GetAttributeChangedSignal(Config.challenges.attribute):Connect(function()
		if open then
			render()
		end
	end)
	player:GetAttributeChangedSignal(SH.playerAttribute):Connect(function()
		if open then
			render()
		end
	end)
	player:GetAttributeChangedSignal(Config.progression.attributes.credits):Connect(function()
		if open then
			render()
		end
	end)
end

return ShopView
