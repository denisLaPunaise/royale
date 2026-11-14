--!strict
--[[
	LobbyScene — ce que le salon montre autour du joueur : les panneaux
	illustres « Comment jouer » (dessines ici pour avoir les icones de sa
	manette), l'Oeil qui le suit des yeux, les rochers qui flottent.

	Tout est local : chaque joueur voit l'Oeil le regarder, lui.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local ButtonIcons = require(script.Parent.ButtonIcons)
local Cracks = require(script.Parent.Cracks)

local LobbyScene = {}

local LB = Config.lobby
local T = LB.tutorial
local D = LB.decor
local V = Config.view

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local LANTERN = rgb(LB.colors.lantern)
local RED = rgb(D.eyeGlow)
local DARK = Color3.fromRGB(26, 21, 19)
-- Le fond des panneaux : un brun chaud, le noir pur faisait un trou.
local BOARD = Color3.fromRGB(44, 35, 30)
local PALE = rgb(LB.hud.text)

--------------------------------------------------------------------------------
-- Les dessins : formes simples sur une toile carree de 100 x 100 unites,
-- mises a l'echelle de la toile (un dessin ne depend pas de la taille du
-- panneau).
--------------------------------------------------------------------------------

type Shape = {
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	round: boolean?,
	stroke: number?,
	hollow: boolean?,
	rotation: number?,
	fade: boolean?,
	z: number?,
}

local function shape(canvas: Frame, s: Shape)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(s.x / 100, s.y / 100)
	f.Size = UDim2.fromScale(s.w / 100, s.h / 100)
	f.BackgroundColor3 = s.color
	f.BackgroundTransparency = if s.hollow then 1 else 0
	f.BorderSizePixel = 0
	f.Rotation = s.rotation or 0
	f.ZIndex = s.z or 1
	if s.round then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
	end
	if s.stroke then
		local st = Instance.new("UIStroke")
		st.Color = s.color
		st.Thickness = s.stroke
		st.Parent = f
	end
	if s.fade then
		-- Un faisceau : plein en haut, efface en bas.
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Transparency = NumberSequence.new(0.35, 1)
		g.Parent = f
	end
	f.Parent = canvas
end

-- Un petit bonhomme : une tete et un corps arrondi.
local function person(canvas: Frame, x: number, y: number, scale: number, color: Color3, z: number?)
	shape(canvas, {
		x = x,
		y = y - 15 * scale,
		w = 11 * scale,
		h = 11 * scale,
		color = color,
		round = true,
		z = z,
	})
	shape(canvas, {
		x = x,
		y = y + 2 * scale,
		w = 13 * scale,
		h = 22 * scale,
		color = color,
		round = true,
		z = z,
	})
end

local ART: { [string]: (canvas: Frame) -> () } = {
	eye = function(c)
		shape(c, { x = 50, y = 62, w = 34, h = 44, color = RED, fade = true })
		shape(c, {
			x = 50,
			y = 30,
			w = 86,
			h = 40,
			color = LANTERN,
			round = true,
			stroke = 4,
			hollow = true,
		})
		shape(c, { x = 50, y = 30, w = 30, h = 30, color = RED, round = true })
		shape(c, { x = 50, y = 30, w = 7, h = 22, color = DARK, round = true, z = 2 })
		person(c, 50, 84, 0.7, PALE)
	end,
	hide = function(c)
		person(c, 50, 52, 1.1, PALE)
		shape(c, { x = 46, y = 33, w = 3, h = 3, color = DARK, round = true, z = 2 })
		shape(c, { x = 54, y = 33, w = 3, h = 3, color = DARK, round = true, z = 2 })
		shape(c, { x = 50, y = 70, w = 74, h = 40, color = Color3.fromRGB(70, 58, 52), z = 3 })
		shape(
			c,
			{ x = 50, y = 70, w = 74, h = 40, color = LANTERN, stroke = 3, hollow = true, z = 4 }
		)
		shape(c, { x = 50, y = 70, w = 74, h = 3, color = LANTERN, z = 4 })
	end,
	crouch = function(c)
		person(c, 20, 55, 1.4, PALE)
		person(c, 50, 66, 0.95, PALE)
		-- Allonge : la tete au bout d'un corps couche.
		shape(c, { x = 74, y = 80, w = 8, h = 8, color = PALE, round = true })
		shape(c, { x = 87, y = 81, w = 18, h = 9, color = PALE, round = true })
		shape(c, { x = 50, y = 89, w = 96, h = 2, color = LANTERN })
	end,
	loot = function(c)
		shape(c, { x = 50, y = 70, w = 70, h = 36, color = Color3.fromRGB(70, 58, 52) })
		shape(
			c,
			{ x = 50, y = 70, w = 70, h = 36, color = LANTERN, stroke = 3, hollow = true, z = 2 }
		)
		shape(c, { x = 46, y = 46, w = 74, h = 9, color = LANTERN, rotation = -14 })
		for _, d in { { 30, 22, 9 }, { 62, 16, 12 }, { 80, 32, 7 } } do
			shape(c, { x = d[1], y = d[2], w = d[3], h = d[3], color = LANTERN, rotation = 45 })
		end
	end,
	fight = function(c)
		for i = 0, 7 do
			shape(c, {
				x = 50,
				y = 50,
				w = if i % 2 == 0 then 84 else 60,
				h = 5,
				color = if i % 2 == 0 then LANTERN else RED,
				rotation = i * 22.5,
			})
		end
		shape(c, { x = 50, y = 50, w = 34, h = 34, color = DARK, round = true, z = 2 })
		shape(c, {
			x = 50,
			y = 50,
			w = 34,
			h = 34,
			color = LANTERN,
			round = true,
			stroke = 3,
			hollow = true,
			z = 3,
		})
	end,
	win = function(c)
		shape(
			c,
			{ x = 50, y = 52, w = 86, h = 86, color = RED, round = true, stroke = 5, hollow = true }
		)
		shape(
			c,
			{ x = 50, y = 52, w = 62, h = 62, color = RED, round = true, stroke = 2, hollow = true }
		)
		person(c, 50, 58, 1, LANTERN)
	end,
}

--------------------------------------------------------------------------------
-- Les panneaux
--------------------------------------------------------------------------------

local function drawPanel(gui: SurfaceGui, index: number)
	gui:ClearAllChildren()
	local def = T.panels[index]
	local h = T.panelHeight * T.pixelsPerStud
	local pad = math.floor(h * 0.07)
	local back = Instance.new("Frame")
	back.Name = "Fond"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = BOARD
	back.Parent = gui
	local frame = Instance.new("Frame")
	frame.Name = "Cadre"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.new(1, -pad, 1, -pad)
	frame.BackgroundTransparency = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, pad)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = LANTERN
	stroke.Thickness = math.max(2, math.floor(pad / 5))
	stroke.Transparency = 0.35
	stroke.Parent = frame
	frame.Parent = back
	local title = Instance.new("TextLabel")
	title.Name = "Titre"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(pad * 1.5, pad)
	title.Size = UDim2.new(1, -pad * 3, 0, h * 0.17)
	title.Font = (Enum.Font :: any)[V.font]
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = LANTERN
	title.Text = def.title
	title.Parent = back
	local artSize = math.floor(h * 0.48)
	local top = math.floor(pad + h * 0.17 + pad * 0.6)
	local canvas = Instance.new("Frame")
	canvas.Name = "Dessin"
	canvas.BackgroundTransparency = 1
	canvas.Position = UDim2.fromOffset(pad * 1.5, top)
	canvas.Size = UDim2.fromOffset(artSize, artSize)
	canvas.Parent = back
	local draw = ART[def.art]
	if draw then
		draw(canvas)
	else
		warn("[Royale] Salon : pas de dessin « " .. tostring(def.art) .. " »")
	end
	local text = Instance.new("TextLabel")
	text.Name = "Texte"
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromOffset(pad * 2.5 + artSize, top)
	text.Size = UDim2.new(1, -(pad * 4 + artSize), 0, artSize)
	text.Font = (Enum.Font :: any)[V.bodyFont]
	text.TextSize = math.floor(h * 0.115)
	text.TextWrapped = true
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.TextColor3 = PALE
	text.Text = def.text
	text.Parent = back
	if #def.buttons > 0 then
		local row = Instance.new("Frame")
		row.Name = "Boutons"
		row.BackgroundTransparency = 1
		local rowHeight = math.floor(h * 0.13)
		row.Position = UDim2.new(0, pad * 1.5, 1, -(pad + rowHeight))
		row.Size = UDim2.new(1, -pad * 3, 0, rowHeight)
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Padding = UDim.new(0, pad * 2)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = row
		for i, b in def.buttons do
			local binding = (Config.controls.contexts :: any)[b[1]][b[2]]
			ButtonIcons.chip(row, binding, b[3], rowHeight, math.floor(rowHeight * 0.62), i)
		end
		row.Parent = back
	end
end

local function panels(salon: Instance)
	local player = Players.LocalPlayer
	local holder = Instance.new("Folder")
	holder.Name = "RoyalePanneaux"
	holder.Parent = player:WaitForChild("PlayerGui")
	local guis: { [SurfaceGui]: number } = {}
	local function add(part: Instance)
		local index = part:GetAttribute("Panneau")
		if not part:IsA("BasePart") or typeof(index) ~= "number" or T.panels[index] == nil then
			return
		end
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Panneau" .. index
		gui.Adornee = part
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = T.pixelsPerStud
		gui.LightInfluence = 0
		gui.Parent = holder
		guis[gui] = index
		drawPanel(gui, index)
	end
	for _, d in salon:GetDescendants() do
		add(d)
	end
	salon.DescendantAdded:Connect(add)
	-- Les icones suivent la manette ou le clavier.
	local wasGamepad = ButtonIcons.gamepad()
	UserInputService.LastInputTypeChanged:Connect(function()
		local now = ButtonIcons.gamepad()
		if now ~= wasGamepad then
			wasGamepad = now
			for gui, index in guis do
				drawPanel(gui, index)
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- L'Oeil qui suit, les rochers qui flottent
--------------------------------------------------------------------------------

local function rocks(salon: Instance)
	local list: { { part: BasePart, base: CFrame, period: number, phase: number } } = {}
	local function addRock(r: Instance)
		local period, phase = r:GetAttribute("Periode"), r:GetAttribute("Phase")
		if r:IsA("BasePart") and typeof(period) == "number" and typeof(phase) == "number" then
			table.insert(list, { part = r, base = r.CFrame, period = period, phase = phase })
		end
	end
	local folder = salon:WaitForChild("Flottants", 30)
	if folder == nil then
		return
	end
	for _, r in folder:GetChildren() do
		addRock(r)
	end
	folder.ChildAdded:Connect(addRock)
	RunService.RenderStepped:Connect(function()
		if Players.LocalPlayer:GetAttribute(Config.match.aliveAttribute) ~= nil then
			return
		end
		local t = os.clock()
		for _, r in list do
			r.part.CFrame = r.base
				+ Vector3.new(0, math.sin(t * math.pi * 2 / r.period + r.phase) * D.rockBob, 0)
		end
	end)
end

local random = Random.new()
local function between(pair: { number }): number
	return random:NextNumber(pair[1], pair[2])
end

-- Le ciel de la carte en plus petit : la dechirure, ses levres, les
-- paupieres et l'Oeil (choisi avec Josh : « comme le vrai »), incline pour
-- que l'Oeil regarde la place. Construit ici, chez chaque joueur : le ciel
-- est toujours charge (Persistent), et 1 900 parts envoyees par le serveur
-- retardaient tout le reste (les remotes arrivaient apres 5 s, vu en jeu).
local function buildSky(): Model?
	local W = Config.world
	local map = workspace:WaitForChild(W.folder)
	local sky = map:WaitForChild(W.sky)
	local source = sky:WaitForChild(W.eye)
	if not sky:IsA("Model") or not source:IsA("Model") then
		warn("[Royale] Salon : le ciel de la carte n'est pas un modele, pas d'Oeil au salon")
		return nil
	end
	if source.PrimaryPart == nil then
		source:GetPropertyChangedSignal("PrimaryPart"):Wait()
	end
	local clone = sky:Clone()
	clone.Name = D.skyName
	local eye = clone:FindFirstChild(W.eye) :: Model
	local lids = clone:FindFirstChild(W.lids)
	local center = (eye.PrimaryPart :: BasePart).Position
	-- Les fissures lointaines ne se verraient pas : on garde ce qui entoure
	-- l'Oeil.
	for _, d in clone:GetDescendants() do
		if
			d:IsA("BasePart")
			and not d:IsDescendantOf(eye)
			and not (lids and d:IsDescendantOf(lids))
			and Vector2.new(d.Position.X - center.X, d.Position.Z - center.Z).Magnitude
				> D.skyKeep
		then
			d:Destroy()
		end
	end
	clone:ScaleTo(D.skyScale)
	local scaled = (eye.PrimaryPart :: BasePart).Position
	local origin = Vector3.new(LB.origin[1], LB.origin[2], LB.origin[3])
	local o = D.eyeOffset
	local target = origin + Vector3.new(o[1], o[2], o[3])
	-- Le ciel regarde vers le bas (-Y, le haut vers +Z) : on le tourne pour
	-- que ce « bas » vise le centre de la place.
	local fromDown = CFrame.lookAt(Vector3.zero, Vector3.new(0, -1, 0), Vector3.new(0, 0, 1))
	local toPlaza = CFrame.lookAt(Vector3.zero, (origin - target).Unit, Vector3.new(0, 1, 0))
	local turn = toPlaza * fromDown:Inverse()
	clone:PivotTo(CFrame.new(target) * turn * CFrame.new(-scaled) * clone:GetPivot())
	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		end
	end
	clone.Parent = workspace
	return clone
end

-- L'Oeil vivant : il regarde tantot toi, tantot ailleurs, et cligne.
local function watcher()
	local W = Config.world
	local sky = buildSky()
	local eye = sky and sky:FindFirstChild(W.eye)
	if eye == nil or not eye:IsA("Model") or eye.PrimaryPart == nil then
		return
	end
	local rest = eye:GetPivot()
	local center = (eye.PrimaryPart :: BasePart).Position
	-- Au repos, il regarde la place : c'est l'axe du cone ou sa paupiere le
	-- laisse tourner.
	local axis, up = rest.LookVector, rest.UpVector
	local side = axis:Cross(up)
	local fromRest = CFrame.lookAt(center, center + axis, up):ToObjectSpace(rest)
	local maxAngle = math.rad(V.eyeTurnMax)
	local function clamp(dir: Vector3): Vector3
		local cos = math.clamp(dir:Dot(axis), -1, 1)
		if math.acos(cos) <= maxAngle then
			return dir
		end
		local across = dir - axis * cos
		if across.Magnitude < 1e-4 then
			return axis
		end
		return axis * math.cos(maxAngle) + across.Unit * math.sin(maxAngle)
	end

	type Lid = { model: Model, base: CFrame, open: number, closed: number }
	local lids: { Lid } = {}
	local lidFolder = (sky :: Instance):FindFirstChild(W.lids)
	if lidFolder then
		for _, m in lidFolder:GetChildren() do
			local open, closed = m:GetAttribute("Ouvert"), m:GetAttribute("Ferme")
			if m:IsA("Model") and typeof(open) == "number" and typeof(closed) == "number" then
				-- Construites ouvertes, comme sur la carte (SkyView).
				table.insert(lids, { model = m, base = m:GetPivot(), open = open, closed = closed })
			end
		end
	end
	local irisNames: { [string]: boolean } = {}
	for _, name in V.irisParts do
		irisNames[name] = true
	end
	local iris: { BasePart } = {}
	for _, part in eye:GetDescendants() do
		if part:IsA("BasePart") and irisNames[part.Name] then
			table.insert(iris, part)
		end
	end

	local pulseCracks = Cracks.track(sky :: Instance)
	local look = axis
	local goal = axis
	local atPlayer = true
	local nextGlance = os.clock() + between(D.glanceSeconds)
	local nextBlink = os.clock() + between(D.blinkEvery)
	local blinkStart = -math.huge
	local lidShown = -1
	RunService.RenderStepped:Connect(function(dt: number)
		-- Au salon seulement (en partie, l'attribut existe).
		if Players.LocalPlayer:GetAttribute(Config.match.aliveAttribute) ~= nil then
			return
		end
		local camera = workspace.CurrentCamera
		if camera == nil then
			return
		end
		local now = os.clock()
		pulseCracks(now)
		if now >= nextGlance then
			nextGlance = now + between(D.glanceSeconds)
			atPlayer = random:NextNumber() < D.glanceAtPlayer
			if not atPlayer then
				local turn = random:NextNumber(0, math.pi * 2)
				local tilt = maxAngle * random:NextNumber(0.3, 1)
				goal = axis * math.cos(tilt)
					+ (up * math.cos(turn) + side * math.sin(turn)) * math.sin(tilt)
			end
		end
		if atPlayer then
			goal = clamp((camera.CFrame.Position - center).Unit)
		end
		look = clamp(look:Lerp(goal, math.min(1, dt * D.eyeTurnRate)).Unit)
		eye:PivotTo(CFrame.lookAt(center, center + look, up) * fromRest)

		-- Les clignements : fermer vite, rouvrir un peu moins vite.
		if now >= nextBlink then
			blinkStart = now
			nextBlink = now
				+ (
					if random:NextNumber() < D.doubleBlink
						then D.blinkCloseSeconds + D.blinkOpenSeconds
						else between(D.blinkEvery)
				)
		end
		local since = now - blinkStart
		local amount = 1
		if since < D.blinkCloseSeconds then
			amount = 1 - since / D.blinkCloseSeconds
		elseif since < D.blinkCloseSeconds + D.blinkOpenSeconds then
			amount = (since - D.blinkCloseSeconds) / D.blinkOpenSeconds
		end
		if amount ~= lidShown then
			lidShown = amount
			for _, lid in lids do
				local angle = lid.closed + (lid.open - lid.closed) * amount
				lid.model:PivotTo(lid.base * CFrame.Angles(math.rad(angle - lid.open), 0, 0))
			end
			local hide = math.clamp(1 - amount / V.irisShowAt, 0, 1)
			for _, part in iris do
				part.LocalTransparencyModifier = hide
			end
		end
	end)
end

function LobbyScene.start()
	local salon = workspace:WaitForChild(LB.folder)
	task.spawn(panels, salon)
	task.spawn(watcher)
	task.spawn(rocks, salon)
end

return LobbyScene
