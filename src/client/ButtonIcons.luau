--!strict
--[[
	ButtonIcons — un bouton de Config.controls dessine comme le joueur le
	tient : l'icone de sa manette (celle que Roblox fournit, Xbox ou
	PlayStation), sinon la touche du clavier dans une pastille.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local ButtonIcons = {}

local V = Config.view

export type Binding = { gamepad: string, keyboard: string }

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- La manette d'abord : Josh joue a la manette, et un ecran sans manette
-- branchee montre les touches.
function ButtonIcons.gamepad(): boolean
	local last = UserInputService:GetLastInputType()
	if last == Enum.UserInputType.Keyboard or last == Enum.UserInputType.MouseButton1 then
		return false
	end
	return UserInputService.GamepadEnabled
end

-- Une pastille : l'icone (ou la touche) puis son texte, de hauteur `icon`.
function ButtonIcons.chip(
	parent: Instance,
	binding: Binding,
	text: string,
	icon: number,
	textSize: number,
	order: number
): Frame
	local chip = Instance.new("Frame")
	chip.Name = "Bouton" .. order
	chip.LayoutOrder = order
	chip.BackgroundTransparency = 1
	chip.Size = UDim2.fromOffset(0, icon)
	chip.AutomaticSize = Enum.AutomaticSize.X
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.Padding = UDim.new(0, math.floor(icon / 4))
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = chip
	if ButtonIcons.gamepad() then
		local image = Instance.new("ImageLabel")
		image.Name = "Icone"
		image.LayoutOrder = 1
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromOffset(icon, icon)
		image.Image = UserInputService:GetImageForKeyCode((Enum.KeyCode :: any)[binding.gamepad])
		image.Parent = chip
	else
		local key = Instance.new("TextLabel")
		key.Name = "Touche"
		key.LayoutOrder = 1
		key.BackgroundColor3 = rgb(V.keyBackground)
		key.Size = UDim2.fromOffset(Config.lobby.hud.keyMinWidth, icon)
		key.AutomaticSize = Enum.AutomaticSize.X
		key.Font = (Enum.Font :: any)[V.bodyFont]
		key.TextSize = textSize
		key.TextColor3 = rgb(V.keyText)
		key.Text = V.keyNames[binding.keyboard] or binding.keyboard
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, math.floor(icon / 5))
		corner.Parent = key
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, math.floor(icon / 5))
		pad.PaddingRight = UDim.new(0, math.floor(icon / 5))
		pad.Parent = key
		key.Parent = chip
	end
	if text ~= "" then
		local label = Instance.new("TextLabel")
		label.Name = "Texte"
		label.LayoutOrder = 2
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromOffset(0, icon)
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Font = (Enum.Font :: any)[V.bodyFont]
		label.TextSize = textSize
		label.TextColor3 = rgb(Config.lobby.hud.text)
		label.Text = text
		label.Parent = chip
	end
	chip.Parent = parent
	return chip
end

return ButtonIcons
