--!strict
--[[
	SkyView — l'Oeil vivant dans le ciel, et ses faisceaux.

	Le serveur garde l'Oeil immobile (il ne s'en sert que pour mesurer la
	pupille) ; ici, chaque client le tourne vers ce qu'il chasse, ouvre et
	ferme ses paupieres, rougit le ciel, et dessine les faisceaux publies dans
	Workspace.Faisceaux (attributs F1, F2... = x, rayon, z).
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Cracks = require(script.Parent.Cracks)

local SkyView = {}

local V = Config.view

-- Les couleurs de Config sont des { r, v, b } (Config se charge sans Roblox).
local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end
local W = Config.world

-- Le bout de la pupille, mesure comme cote serveur (le modele n'a pas encore
-- tourne quand on le lit).
SkyView.eyeOrigin = Vector3.zero

local function measure(eye: Model): Vector3
	local globe = eye.PrimaryPart :: BasePart
	local tip = globe.Position - Vector3.new(0, globe.Size.Y / 2, 0)
	for _, part in eye:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "Pupille" then
			local bottom = part.Position.Y - part.Size.Z / 2
			if bottom < tip.Y then
				tip = Vector3.new(globe.Position.X, bottom, globe.Position.Z)
			end
		end
	end
	return tip
end

function SkyView.start()
	local root = workspace:WaitForChild(W.folder)
	local sky = root:WaitForChild(W.sky)
	local eye = sky:WaitForChild(W.eye) :: Model
	if eye.PrimaryPart == nil then
		eye:GetPropertyChangedSignal("PrimaryPart"):Wait()
	end
	SkyView.eyeOrigin = measure(eye)
	local globe = eye.PrimaryPart :: BasePart
	local center = globe.Position
	local basePivot = eye:GetPivot()
	local down = CFrame.lookAt(center, center - Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))
	-- Le reste du modele, exprime depuis « regarder droit en bas ».
	local fromDown = down:ToObjectSpace(basePivot)

	type Lid = { model: Model, base: CFrame, open: number, closed: number }
	local lids: { Lid } = {}
	local lidFolder = sky:FindFirstChild(W.lids)
	if lidFolder then
		for _, m in lidFolder:GetChildren() do
			if m:IsA("Model") then
				local open = m:GetAttribute("Ouvert")
				local closed = m:GetAttribute("Ferme")
				if typeof(open) == "number" and typeof(closed) == "number" then
					-- Construites ouvertes : la pose de depart est l'ouverture.
					table.insert(
						lids,
						{ model = m, base = m:GetPivot(), open = open, closed = closed }
					)
				end
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

	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "RoyaleRegard"
	tint.Parent = Lighting

	local beamFolder = workspace:WaitForChild(Config.eye.beamsFolder, math.huge) :: Folder
	type Drawn = { shaft: Part, spot: Part, x: number, z: number }
	local drawn: { [string]: Drawn } = {}
	local visuals = Instance.new("Folder")
	visuals.Name = "RoyaleFaisceauxVus"
	visuals.Parent = workspace

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { sky, visuals }

	local function makeBeam(): Drawn
		local shaft = Instance.new("Part")
		shaft.Name = "Colonne"
		shaft.Shape = Enum.PartType.Cylinder
		shaft.Material = Enum.Material.Neon
		shaft.Color = rgb(V.beamColor)
		shaft.Transparency = V.beamTransparency
		shaft.Anchored = true
		shaft.CanCollide = false
		shaft.CanQuery = false
		shaft.CanTouch = false
		shaft.CastShadow = false
		shaft.Parent = visuals
		local spot = shaft:Clone()
		spot.Name = "Tache"
		spot.Transparency = V.spotTransparency
		spot.Parent = visuals
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Right
		light.Color = rgb(V.beamColor)
		light.Brightness = V.spotBrightness
		light.Range = V.spotRange
		light.Angle = V.spotAngle
		light.Parent = spot
		return { shaft = shaft, spot = spot, x = 0, z = 0 }
	end

	local lidAmount = 1
	local look = down
	local pulseCracks = Cracks.track(sky)
	RunService.RenderStepped:Connect(function(dt: number)
		pulseCracks(os.clock())
		local open = workspace:GetAttribute(Config.match.eyeOpenAttribute) == true
		local warning = workspace:GetAttribute(Config.eye.warningAttribute) == true

		-- Les faisceaux.
		local seenNames: { [string]: boolean } = {}
		local nearest: Vector3? = nil
		local character = Players.LocalPlayer.Character
		local me = character and character:FindFirstChild("HumanoidRootPart")
		for name, value in beamFolder:GetAttributes() do
			if typeof(value) ~= "Vector3" then
				continue
			end
			seenNames[name] = true
			local d = drawn[name]
			if d == nil then
				d = makeBeam()
				d.x, d.z = value.X, value.Z
				drawn[name] = d
			end
			local k = math.clamp(dt * V.beamSmoothing, 0, 1)
			d.x += (value.X - d.x) * k
			d.z += (value.Z - d.z) * k
			local radius = value.Y
			local hit = workspace:Raycast(
				Vector3.new(d.x, SkyView.eyeOrigin.Y - 5, d.z),
				Vector3.new(0, -SkyView.eyeOrigin.Y - 200, 0),
				rayParams
			)
			local groundY = if hit then hit.Position.Y else 0
			local foot = Vector3.new(d.x, groundY, d.z)
			local top = SkyView.eyeOrigin
			local length = (top - foot).Magnitude
			d.shaft.Size = Vector3.new(length, radius * 2, radius * 2)
			d.shaft.CFrame = CFrame.lookAt((top + foot) / 2, foot)
				* CFrame.Angles(0, math.pi / 2, 0)
			d.spot.Size = Vector3.new(0.3, radius * 2, radius * 2)
			d.spot.CFrame = CFrame.new(foot + Vector3.new(0, 0.2, 0))
				* CFrame.Angles(0, 0, math.pi / 2)
			if me and me:IsA("BasePart") then
				if
					nearest == nil
					or (foot - me.Position).Magnitude < (nearest - me.Position).Magnitude
				then
					nearest = foot
				end
			elseif nearest == nil then
				nearest = foot
			end
		end
		for name, d in drawn do
			if not seenNames[name] then
				d.shaft:Destroy()
				d.spot:Destroy()
				drawn[name] = nil
			end
		end

		-- L'Oeil regarde son faisceau le plus proche de toi, sinon toi.
		local goal = nearest
		if goal == nil and me and me:IsA("BasePart") then
			goal = me.Position
		end
		local wanted = down
		if goal then
			local dir = (goal - center).Unit
			local angle = math.acos(math.clamp(dir:Dot(Vector3.new(0, -1, 0)), -1, 1))
			local maxAngle = math.rad(V.eyeTurnMax)
			if angle > maxAngle then
				local flat = Vector3.new(dir.X, 0, dir.Z)
				if flat.Magnitude > 0 then
					flat = flat.Unit
					dir = Vector3.new(0, -math.cos(maxAngle), 0) + flat * math.sin(maxAngle)
				end
			end
			wanted = CFrame.lookAt(center, center + dir, Vector3.new(0, 0, 1))
		end
		look = look:Lerp(wanted, math.clamp(dt * V.eyeTurnRate, 0, 1))
		eye:PivotTo(look * fromDown)

		-- Les paupieres.
		local target = if open then 1 else 0
		local step = dt / V.lidSeconds
		if lidAmount < target then
			lidAmount = math.min(lidAmount + step, target)
		elseif lidAmount > target then
			lidAmount = math.max(lidAmount - step, target)
		end
		for _, lid in lids do
			local angle = lid.closed + (lid.open - lid.closed) * lidAmount
			lid.model:PivotTo(lid.base * CFrame.Angles(math.rad(angle - lid.open), 0, 0))
		end

		local hide = math.clamp(1 - lidAmount / V.irisShowAt, 0, 1)
		for _, part in iris do
			part.LocalTransparencyModifier = hide
		end

		-- Le ciel.
		tint.TintColor = if open
			then rgb(V.openTint)
			elseif warning then rgb(V.warningTint)
			else Color3.new(1, 1, 1)
	end)
end

return SkyView
