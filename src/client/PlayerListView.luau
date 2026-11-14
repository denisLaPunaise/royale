--!strict
--[[
	PlayerListView — la liste des joueurs du jeu (CONCEPT.md : celle de
	Roblox ne montre que les vrais joueurs et trahirait les bots). R3 ou Tab
	l'ouvre et la ferme : chacun, son equipe, en vie ou aspire. Rien ne
	distingue un bot d'un joueur.
]]

local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local PlayerListView = {}

local V = Config.view
local PL = Config.playerList

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

function PlayerListView.start()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "RoyaleListe"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = PL.displayOrder
	gui.Parent = player:WaitForChild("PlayerGui")
	local frame = Instance.new("ScrollingFrame")
	frame.Name = "Liste"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -16, 0, PL.top)
	frame.Size = UDim2.new(0, PL.width, 0.6, 0)
	frame.BackgroundColor3 = rgb(PL.background)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.ScrollBarThickness = 6
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.CanvasSize = UDim2.new()
	frame.Visible = false
	frame.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 6)
	padding.Parent = frame

	local function rebuild()
		for _, child in frame:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local raw = workspace:GetAttribute(Config.match.listAttribute)
		if typeof(raw) ~= "string" then
			return
		end
		local ok, list = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if not ok or typeof(list) ~= "table" then
			return
		end
		local mine = player:GetAttribute(Config.squads.attribute)
		local alive = 0
		for _, e in list do
			if e.a then
				alive += 1
			end
		end
		-- Son equipe d'abord, puis par equipe, puis par nom.
		table.sort(list, function(a, b)
			local am, bm = a.t == mine, b.t == mine
			if am ~= bm then
				return am
			elseif a.t ~= b.t then
				return a.t < b.t
			end
			return a.n < b.n
		end)
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, -8, 0, PL.rowHeight)
		title.Font = (Enum.Font :: any)[V.font]
		title.TextSize = PL.textSize
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = rgb(PL.text)
		title.Text = string.format("JOUEURS — %d en vie sur %d", alive, #list)
		title.LayoutOrder = 0
		title.Parent = frame
		local mode = workspace:GetAttribute(Config.squads.modeAttribute)
		local solo = typeof(mode) ~= "string" or Config.squads.sizes[mode] <= 1
		for i, e in list do
			local row = Instance.new("TextLabel")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, -8, 0, PL.rowHeight)
			row.Font = (Enum.Font :: any)[V.bodyFont]
			row.TextSize = PL.textSize
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.TextColor3 = if e.t == mine and mine ~= nil
				then rgb(Config.squads.markerColor)
				elseif e.a then rgb(PL.text)
				else rgb(PL.out)
			row.Text = (if solo then "" else string.format("[%d] ", e.t))
				.. e.n
				.. (if typeof(e.ti) == "string" then " « " .. e.ti .. " »" else "")
				.. (if e.a then "" else " — aspiré")
			row.LayoutOrder = i
			row.Parent = frame
		end
	end

	workspace:GetAttributeChangedSignal(Config.match.listAttribute):Connect(function()
		if frame.Visible then
			rebuild()
		end
	end)
	local binding = Config.controls.contexts.onFoot.playerList
	ContextActionService:BindAction("RoyaleListe", function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			frame.Visible = not frame.Visible
			if frame.Visible then
				rebuild()
			end
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode[binding.gamepad], Enum.KeyCode[binding.keyboard])
end

return PlayerListView
