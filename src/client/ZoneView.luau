--!strict
--[[
	ZoneView — le cercle : un mur rouge translucide la ou il est, un trait
	blanc au sol la ou il va (attributs `Cercle` et `CercleSuivant` de
	Workspace, des Vector3 x, rayon, z).

	Des panneaux plutot qu'un cylindre : un cylindre ne se voit pas de
	l'interieur, et on est presque toujours a l'interieur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local ZoneView = {}

local V = Config.view

-- Les couleurs de Config sont des { r, v, b } (Config se charge sans Roblox).
local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end
local Z = Config.zone

local function ring(parent: Instance, color: Color3, transparency: number): { Part }
	local parts: { Part } = {}
	for _ = 1, V.wallSegments do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = transparency
		p.Parent = parent
		table.insert(parts, p)
	end
	return parts
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Le sol sous un point, pour que le trait suive les collines.
local function groundAt(x: number, z: number): number
	local hit = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -800, 0), rayParams)
	return if hit then hit.Position.Y else 0
end

-- `sink` : de combien le panneau s'enfonce sous le sol (un mur ne doit pas
-- flotter au-dessus d'un creux).
local function place(parts: { Part }, circle: Vector3?, height: number, sink: number)
	for i, p in parts do
		if circle == nil then
			p.Transparency = 1
			continue
		end
		local radius = circle.Y
		local a0 = (i - 1) / #parts * math.pi * 2
		local a1 = i / #parts * math.pi * 2
		local p0 =
			Vector3.new(circle.X + math.cos(a0) * radius, 0, circle.Z + math.sin(a0) * radius)
		local p1 =
			Vector3.new(circle.X + math.cos(a1) * radius, 0, circle.Z + math.sin(a1) * radius)
		local midXZ = (p0 + p1) / 2
		local baseY = groundAt(midXZ.X, midXZ.Z) - sink
		local mid = midXZ + Vector3.new(0, baseY + (height + sink) / 2, 0)
		p.Size = Vector3.new(0.4, height + sink, (p1 - p0).Magnitude + 0.2)
		p.CFrame = CFrame.lookAt(mid, mid + (p1 - p0)) * CFrame.Angles(0, math.pi / 2, 0)
	end
end

function ZoneView.start()
	local folder = Instance.new("Folder")
	folder.Name = "RoyaleCercleVu"
	folder.Parent = workspace
	local wall = ring(folder, rgb(V.wallColor), V.wallTransparency)
	local nextRing = ring(folder, rgb(V.nextColor), V.nextTransparency)
	rayParams.FilterDescendantsInstances = { folder }

	local function refresh()
		local current = workspace:GetAttribute(Z.attribute)
		local nextCircle = workspace:GetAttribute(Z.nextAttribute)
		local c = if typeof(current) == "Vector3" then current else nil
		local n = if typeof(nextCircle) == "Vector3" then nextCircle else nil
		-- Avant le premier cercle (toute la carte), pas de mur : il serait en mer.
		if c and c.Y >= Z.startRadius then
			c = nil
		end
		for _, p in wall do
			p.Transparency = V.wallTransparency
		end
		for _, p in nextRing do
			p.Transparency = V.nextTransparency
		end
		place(wall, c, V.wallHeight, V.wallHeight / 2)
		place(nextRing, n, V.nextHeight, V.nextHeight / 2)
	end
	workspace:GetAttributeChangedSignal(Z.attribute):Connect(refresh)
	workspace:GetAttributeChangedSignal(Z.nextAttribute):Connect(refresh)
	refresh()
end

return ZoneView
