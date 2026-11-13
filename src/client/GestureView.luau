--!strict
--[[
	GestureView — la croix de la manette (CONCEPT.md, Les boutons) :
	haut « Danger ! », bas « Ici ! » (la ou l'on regarde, vus par ses
	coequipiers a travers les murs), gauche la carte (le cercle, le prochain,
	soi et ses coequipiers), droite une emote.
]]

local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local GestureView = {}

local SG = Config.signals
local MP = Config.map
local V = Config.view
local onFoot = Config.controls.contexts.onFoot
local hiddenCtx = Config.controls.contexts.hidden

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function keys(
	binding: { gamepad: string, keyboard: string }
): { Enum.KeyCode | Enum.UserInputType }
	local out: { Enum.KeyCode | Enum.UserInputType } = { Enum.KeyCode[binding.gamepad] }
	local ok, key = pcall(function()
		return (Enum.KeyCode :: any)[binding.keyboard]
	end)
	table.insert(out, if ok and key then key else (Enum.UserInputType :: any)[binding.keyboard])
	return out
end

local function merged(list: { { gamepad: string, keyboard: string } }): { any }
	local out: { any } = {}
	local seen: { [any]: boolean } = {}
	for _, b in list do
		for _, k in keys(b) do
			if not seen[k] then
				seen[k] = true
				table.insert(out, k)
			end
		end
	end
	return out
end

-- Le point regarde : le centre de l'ecran, jusqu'a la portee des signaux.
local function lookedAt(player: Player): Vector3?
	local camera = workspace.CurrentCamera
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * SG.range, params)
	return hit and hit.Position
end

local function showSignal(kind: string, at: Vector3, from: string)
	local def = SG.kinds[kind]
	if def == nil then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = at
	anchor.Parent = workspace
	local tag = Instance.new("BillboardGui")
	tag.AlwaysOnTop = true
	tag.Size = UDim2.fromOffset(SG.tagWidth, SG.tagHeight)
	tag.StudsOffset = Vector3.new(0, 2, 0)
	tag.LightInfluence = 0
	tag.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = (Enum.Font :: any)[V.font]
	label.TextScaled = true
	label.TextColor3 = rgb(def.color)
	label.TextStrokeTransparency = 0.2
	label.Text = def.text .. "\n" .. from
	label.Parent = tag
	Debris:AddItem(anchor, SG.seconds)
end

local function buildMap(gui: ScreenGui): (Frame, (Vector3) -> UDim2)
	local frame = Instance.new("Frame")
	frame.Name = "Carte"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(MP.screenFraction, MP.screenFraction)
	frame.BackgroundColor3 = rgb(MP.background)
	frame.BackgroundTransparency = 0.15
	frame.Visible = false
	-- Le premier cercle deborde de la carte (vu en image) : on le coupe au bord.
	frame.ClipsDescendants = true
	frame.Parent = gui
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = rgb(MP.current)
	stroke.Thickness = 2
	stroke.Parent = frame
	local half = Config.world.half
	local function toMap(p: Vector3): UDim2
		return UDim2.fromScale((p.X + half) / (half * 2), (p.Z + half) / (half * 2))
	end
	return frame, toMap
end

local function circleFrame(parent: Frame, name: string, color: Color3): Frame
	local c = Instance.new("Frame")
	c.Name = name
	c.AnchorPoint = Vector2.new(0.5, 0.5)
	c.BackgroundTransparency = 1
	c.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = c
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Parent = c
	return c
end

function GestureView.start()
	local player = Players.LocalPlayer
	local remote =
		Royale:WaitForChild(Config.remotes.folder):WaitForChild(Config.remotes.signal) :: RemoteEvent
	remote.OnClientEvent:Connect(showSignal)

	local gui = Instance.new("ScreenGui")
	gui.Name = "RoyaleCarte"
	gui.ResetOnSpawn = false
	-- Par-dessus l'ecran de jeu (vu en image : le texte du haut passait dessus).
	gui.DisplayOrder = MP.displayOrder
	gui.Parent = player:WaitForChild("PlayerGui")
	local frame, toMap = buildMap(gui)
	-- Les zones, mesurees une fois sur la carte construite (jamais recopiees
	-- de la recette) : l'etendue de leurs pieces, et leur nom au milieu.
	local zonesDrawn = false
	local function drawZones()
		if zonesDrawn then
			return
		end
		zonesDrawn = true
		local root = workspace:FindFirstChild(Config.world.folder)
		local zones = root and root:FindFirstChild(Config.world.zones)
		if zones == nil then
			return
		end
		local half = Config.world.half
		for name, label in MP.zoneNames do
			local folder = zones:FindFirstChild(name)
			if folder == nil then
				continue
			end
			local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
			for _, d in folder:GetDescendants() do
				if d:IsA("BasePart") then
					local p = d.Position
					minX, maxX = math.min(minX, p.X), math.max(maxX, p.X)
					minZ, maxZ = math.min(minZ, p.Z), math.max(maxZ, p.Z)
				end
			end
			if minX < maxX then
				local box = Instance.new("Frame")
				box.Name = "Zone_" .. name
				box.AnchorPoint = Vector2.new(0.5, 0.5)
				box.Position = toMap(Vector3.new((minX + maxX) / 2, 0, (minZ + maxZ) / 2))
				box.Size = UDim2.fromScale((maxX - minX) / (half * 2), (maxZ - minZ) / (half * 2))
				box.BackgroundColor3 = rgb(MP.zoneColor)
				box.BackgroundTransparency = MP.zoneTransparency
				box.BorderSizePixel = 0
				box.ZIndex = 0
				box.Parent = frame
				local text = Instance.new("TextLabel")
				text.BackgroundTransparency = 1
				text.Size = UDim2.fromScale(1, 1)
				text.Font = (Enum.Font :: any)[Config.view.font]
				text.TextScaled = true
				text.TextColor3 = rgb(MP.zoneText)
				text.Text = label
				local limit = Instance.new("UITextSizeConstraint")
				limit.MaxTextSize = MP.zoneTextSize
				limit.Parent = text
				text.Parent = box
			end
		end
	end
	local current = circleFrame(frame, "Cercle", rgb(MP.current))
	local nextOne = circleFrame(frame, "Prochain", rgb(MP.upcoming))
	local dots: { [Instance]: Frame } = {}
	local function dot(key: Instance, color: Color3): Frame
		local d = dots[key]
		if d == nil then
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Size = UDim2.fromOffset(MP.dotSize, MP.dotSize)
			f.BackgroundColor3 = color
			f.BorderSizePixel = 0
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = f
			f.Parent = frame
			dots[key] = f
			d = f
		end
		return d :: Frame
	end

	local function signal(kind: string)
		local at = lookedAt(player)
		if at then
			remote:FireServer(kind, at)
		end
	end

	ContextActionService:BindAction("RoyaleSignalDanger", function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			signal("danger")
		end
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(merged({ onFoot.signalDanger, hiddenCtx.signalDanger })))
	ContextActionService:BindAction("RoyaleSignalIci", function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			signal("here")
		end
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(merged({ onFoot.signalHere, hiddenCtx.signalHere })))
	ContextActionService:BindAction("RoyaleCarte", function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			frame.Visible = not frame.Visible
			if frame.Visible then
				drawZones()
			end
		end
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(keys(onFoot.map)))
	ContextActionService:BindAction("RoyaleEmote", function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local ok, err = pcall(function()
					-- L'emote portee (un cosmetique), sinon le salut.
					local id = player:GetAttribute(Config.cosmetics.attributePrefix .. "emote")
					local def = if typeof(id) == "string" then Config.cosmetics.items[id] else nil
					humanoid:PlayEmote(if def then def.emote else Config.emote.name)
				end)
				if not ok then
					warn("[Royale] Emote : " .. tostring(err))
				end
			end
		end
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(keys(onFoot.emote)))

	-- La pose de victoire : a l'ecran de fin, si l'on fait partie des
	-- gagnants, son emote se joue une fois.
	local celebrated = false
	workspace:GetAttributeChangedSignal(Config.match.phaseAttribute):Connect(function()
		local phase = workspace:GetAttribute(Config.match.phaseAttribute)
		if phase ~= "Fin" then
			celebrated = false
			return
		end
		local winners = workspace:GetAttribute(Config.match.winnerAttribute)
		if celebrated or typeof(winners) ~= "string" then
			return
		end
		for name in string.gmatch(winners, "[^,]+") do
			if string.match(name, "^%s*(.-)%s*$") == player.DisplayName then
				celebrated = true
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local id = player:GetAttribute(Config.cosmetics.attributePrefix .. "emote")
				local def = if typeof(id) == "string" then Config.cosmetics.items[id] else nil
				if humanoid then
					pcall(function()
						humanoid:PlayEmote(if def then def.emote else Config.emote.victory)
					end)
				end
			end
		end
	end)

	local acc = 0
	RunService.RenderStepped:Connect(function(dt: number)
		acc += dt
		if not frame.Visible or acc < MP.refreshSeconds then
			return
		end
		acc = 0
		local half = Config.world.half
		for c, attribute in
			{ [current] = Config.zone.attribute, [nextOne] = Config.zone.nextAttribute }
		do
			local v = workspace:GetAttribute(attribute)
			c.Visible = typeof(v) == "Vector3"
			if typeof(v) == "Vector3" then
				c.Position = toMap(v)
				local size = v.Y * 2 / (half * 2)
				c.Size = UDim2.fromScale(size, size)
			end
		end
		local mine = player:GetAttribute(Config.squads.attribute)
		local seen: { [Instance]: boolean } = {}
		local function place(key: Instance, character: Model?, color: Color3)
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local d = dot(key, color)
				d.Position = toMap(root.Position)
				seen[key] = true
			end
		end
		place(player, player.Character, rgb(MP.me))
		for _, other in Players:GetPlayers() do
			if
				other ~= player
				and mine ~= nil
				and other:GetAttribute(Config.squads.attribute) == mine
			then
				place(other, other.Character, rgb(Config.squads.markerColor))
			end
		end
		local bots = workspace:FindFirstChild(Config.bots.folder)
		if bots and mine ~= nil then
			for _, b in bots:GetChildren() do
				if
					b:IsA("Model")
					and b:GetAttribute(Config.squads.attribute) == mine
					and b:GetAttribute(Config.match.aliveAttribute) == true
				then
					place(b, b, rgb(Config.squads.markerColor))
				end
			end
		end
		for key, d in dots do
			if not seen[key] then
				d:Destroy()
				dots[key] = nil
			end
		end
	end)
end

return GestureView
