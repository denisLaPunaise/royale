--!strict
--[[
	TeamView — ses coequipiers (CONCEPT.md, valide le 12 novembre 2026) : un
	repere et leur nom au-dessus d'eux, a travers les murs, et leur etat en
	bas a gauche (debout, K.O., cache, au Ventre, dans un cocon, aspire).

	Les invites des coequipiers changent de sens a l'ecran : « Voler » devient
	« Relever » sur un ami, et « Donner » ne se montre que sur un ami (le
	serveur verifie de toute facon).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local TeamView = {}

local SQ = Config.squads
local V = Config.view
local TV = Config.squads.view

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Tous les participants visibles : les joueurs et les bots.
local function everyone(): { Instance }
	local out: { Instance } = {}
	for _, p in Players:GetPlayers() do
		table.insert(out, p)
	end
	local bots = workspace:FindFirstChild(Config.bots.folder)
	if bots then
		for _, m in bots:GetChildren() do
			if m:IsA("Model") then
				table.insert(out, m)
			end
		end
	end
	return out
end

local function characterOf(actor: Instance): Model?
	if actor:IsA("Player") then
		return actor.Character
	end
	return actor :: Model
end

local function nameOf(actor: Instance): string
	if actor:IsA("Player") then
		return actor.DisplayName
	end
	local humanoid = actor:FindFirstChildOfClass("Humanoid")
	return if humanoid then humanoid.DisplayName else actor.Name
end

local function stateOf(actor: Instance): string
	if actor:GetAttribute(Config.goulag.stateAttribute) ~= nil then
		return "au Ventre"
	elseif actor:GetAttribute(Config.match.aliveAttribute) ~= true then
		return "aspiré"
	elseif actor:GetAttribute(SQ.cocoonAttribute) == true then
		return "dans un cocon — 3 coups (R2) pour l'ouvrir"
	elseif actor:GetAttribute(Config.combat.koAttribute) == true then
		return "K.O. — X maintenu pour le relever"
	elseif typeof(actor:GetAttribute(Config.hiding.hiddenAttribute)) == "string" then
		return "caché"
	end
	return "debout"
end

function TeamView.start()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "RoyaleEquipe"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local list = Instance.new("TextLabel")
	list.Name = "Equipe"
	list.BackgroundTransparency = 1
	list.AnchorPoint = Vector2.new(0, 1)
	list.Position = UDim2.new(0, 16, 1, -V.slotHeight - V.slotBottom - 16)
	list.Size = UDim2.fromOffset(TV.listWidth, TV.listHeight)
	list.TextXAlignment = Enum.TextXAlignment.Left
	list.TextYAlignment = Enum.TextYAlignment.Bottom
	list.Font = (Enum.Font :: any)[V.font]
	list.TextSize = TV.listTextSize
	list.TextColor3 = rgb(SQ.markerColor)
	list.TextStrokeTransparency = 0.4
	list.TextWrapped = true
	list.Text = ""
	list.Parent = gui

	local marked: { [Model]: boolean } = {}
	local function unmark(character: Model)
		for _, name in { "RoyaleCoequipier", "RoyaleNomAmi" } do
			local thing = character:FindFirstChild(name, true)
			if thing then
				thing:Destroy()
			end
		end
		marked[character] = nil
	end
	local function mark(character: Model, name: string)
		if marked[character] then
			return
		end
		local head = character:FindFirstChild("Head")
		if head == nil then
			return
		end
		marked[character] = true
		local h = Instance.new("Highlight")
		h.Name = "RoyaleCoequipier"
		h.FillTransparency = 1
		h.OutlineColor = rgb(SQ.markerColor)
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = character
		local tag = Instance.new("BillboardGui")
		tag.Name = "RoyaleNomAmi"
		tag.AlwaysOnTop = true
		tag.Size = UDim2.fromOffset(TV.tagWidth, TV.tagHeight)
		tag.StudsOffset = Vector3.new(0, TV.tagAbove, 0)
		tag.LightInfluence = 0
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = (Enum.Font :: any)[V.font]
		label.TextScaled = true
		label.TextColor3 = rgb(SQ.markerColor)
		label.TextStrokeTransparency = 0.3
		label.Text = "▼ " .. name
		label.Parent = tag
		tag.Parent = head
	end

	while true do
		task.wait(TV.refreshSeconds)
		local mine = player:GetAttribute(SQ.attribute)
		local lines: { string } = {}
		local keep: { [Model]: boolean } = {}
		for _, actor in everyone() do
			local character = characterOf(actor)
			local mate = actor ~= player
				and mine ~= nil
				and actor:GetAttribute(SQ.attribute) == mine
			if mate then
				table.insert(lines, nameOf(actor) .. " : " .. stateOf(actor))
				if character and actor:GetAttribute(Config.match.aliveAttribute) == true then
					mark(character, nameOf(actor))
					keep[character] = true
				end
			end
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local steal = root:FindFirstChild("RoyaleVoler")
				if steal and steal:IsA("ProximityPrompt") then
					steal.ActionText = if mate then SQ.reviveText else "Voler"
				end
				local giveTo = root:FindFirstChild("RoyaleDonner")
				if giveTo and giveTo:IsA("ProximityPrompt") and not mate then
					giveTo.Enabled = false
				end
			end
		end
		for character in marked do
			if not keep[character] then
				unmark(character)
			end
		end
		list.Text = if #lines > 0 then "TON ÉQUIPE\n" .. table.concat(lines, "\n") else ""
	end
end

return TeamView
