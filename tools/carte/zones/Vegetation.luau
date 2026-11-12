--!strict
--[[
	La vegetation — en dernier, dans la place qui reste : des bois sur les
	collines et au pied des montagnes, des bosquets et des arbres isoles dans
	la campagne, des haies le long de certaines routes, des rochers.

	Pas de semis regulier : la densite suit un bruit (des bois, des
	clairieres) et le relief (plus d'arbres sur les pentes douces et les
	collines, aucun dans l'eau ni sur les zones construites).
]]

-- Au-dela, la place et le jeu ralentiraient : un arbre genere est un
-- maillage complet.
local MAX_TREES = 700
local GRID = 22

return function(K: any)
	local O, V = K.O, K.V
	local C, P = O.C, O.P
	local random: Random = K.random
	local folder = K.zoneFolder("Vegetation")
	local half = K.Plan.HALF + 220

	local waterParams = RaycastParams.new()
	waterParams.FilterType = Enum.RaycastFilterType.Include
	waterParams.FilterDescendantsInstances = { workspace.Terrain }
	waterParams.IgnoreWater = false

	local function inZone(x: number, z: number): boolean
		for _, zone in K.Plan.zones do
			if
				x > zone.minX - 8
				and x < zone.maxX + 8
				and z > zone.minZ - 8
				and z < zone.maxZ + 8
			then
				return true
			end
		end
		local c = K.Plan.CRATER
		return (x - c.x) ^ 2 + (z - c.z) ^ 2 < (c.radius * 1.3) ^ 2
	end

	-- Les modeles du magasin (docs/ASSETS.md), s'ils sont dans la place.
	local library = game:GetService("ServerStorage"):FindFirstChild("RoyaleModeles")
	local pineTemplate: Model? = library and library:FindFirstChild("Pin") :: Model?
	local bushTemplate: Model? = library and library:FindFirstChild("BuissonReel") :: Model?
	local pines = 0
	local trees, rocks, bushes = 0, 0, 0
	for gx = -half, half, GRID do
		for gz = -half, half, GRID do
			if trees >= MAX_TREES then
				break
			end
			local x = gx + random:NextNumber(-GRID * 0.45, GRID * 0.45)
			local z = gz + random:NextNumber(-GRID * 0.45, GRID * 0.45)
			if inZone(x, z) then
				continue
			end
			local hit =
				workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -700, 0), waterParams)
			if
				hit == nil
				or hit.Material == Enum.Material.Water
				or hit.Material == Enum.Material.Sand
			then
				continue
			end
			local y = hit.Position.Y
			-- Pas sur les pentes raides (rocher) ni sur les sommets pelés.
			if hit.Normal.Y < 0.82 or y > 150 then
				continue
			end
			-- Des bois et des clairieres ; plus dense sur les collines.
			local forest = math.noise(x / 260, z / 260, 61.3)
				+ 0.4 * math.noise(x / 70, z / 70, 62.9)
			local height = math.clamp((y - 10) / 60, 0, 1)
			local chance = 0.05 + 0.65 * math.clamp(forest + 0.15 + height * 0.5, 0, 1)
			local roll = random:NextNumber()
			if roll < chance and K.claim(x, z, 6) then
				-- En montant, et au coeur des bois, des pins ; plus bas, des
				-- feuillus. Deux essences : un bois n'est pas un seul arbre copie.
				if
					pineTemplate
					and (height > 0.35 or forest > 0.35)
					and random:NextNumber() < 0.75
				then
					local pine = pineTemplate:Clone()
					pine.Name = "Pin"
					pine:ScaleTo(pine:GetScale() * random:NextNumber(0.3, 0.5))
					pine:PivotTo(
						CFrame.new(x, y - 0.5, z)
							* CFrame.Angles(
								0,
								random:NextNumber(0, math.pi * 2),
								math.rad(random:NextNumber(-3, 3))
							)
					)
					for _, part in pine:GetDescendants() do
						if part:IsA("BasePart") then
							part:SetAttribute(K.CONTRACT.cover, 0.6)
						end
					end
					pine.Parent = folder
					pines += 1
				else
					V.tree(folder, Vector3.new(x, y, z), random:NextNumber() < 0.12)
				end
				trees += 1
			elseif roll < chance + 0.05 and K.claim(x, z, 3) then
				-- Un buisson bas, qui couvre a moitie (le modele du magasin s'il
				-- est la, sinon une boule de feuillage).
				if bushTemplate then
					local bush = bushTemplate:Clone()
					bush.Name = "Buisson"
					bush:ScaleTo(bush:GetScale() * random:NextNumber(0.35, 0.6))
					bush:PivotTo(
						CFrame.new(x, y - 0.3, z)
							* CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
					)
					for _, part in bush:GetDescendants() do
						if part:IsA("BasePart") then
							part:SetAttribute(K.CONTRACT.cover, 0.5)
						end
					end
					bush.Parent = folder
				else
					local bush = P(
						folder,
						"Buisson",
						Vector3.new(
							random:NextNumber(4, 7),
							random:NextNumber(2.5, 4),
							random:NextNumber(4, 7)
						),
						CFrame.new(x, y + 1.2, z) * CFrame.Angles(0, random:NextNumber(0, 6), 0),
						Enum.Material.LeafyGrass,
						C.hedge,
						{ collide = false }
					)
					bush.Shape = Enum.PartType.Ball
					bush:SetAttribute(K.CONTRACT.cover, 0.5)
				end
				bushes += 1
			elseif roll > 0.985 and K.claim(x, z, 4) then
				P(
					folder,
					"Rocher",
					Vector3.new(
						random:NextNumber(3, 9),
						random:NextNumber(2, 6),
						random:NextNumber(3, 9)
					),
					CFrame.new(x, y + 0.8, z)
						* CFrame.Angles(
							random:NextNumber(-0.3, 0.3),
							random:NextNumber(0, 6),
							random:NextNumber(-0.3, 0.3)
						),
					Enum.Material.Rock,
					Color3.fromRGB(104, 102, 98)
				)
				rocks += 1
			end
		end
		task.wait()
	end

	-- Des cachettes fragiles dans la campagne aussi : buissons et toles.
	local countryside = 0
	for _ = 1, 400 do
		if countryside >= 40 then
			break
		end
		local x, z =
			random:NextNumber(-K.Plan.HALF, K.Plan.HALF),
			random:NextNumber(-K.Plan.HALF, K.Plan.HALF)
		if not inZone(x, z) and K.claim(x, z, 6) then
			local hit =
				workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -700, 0), waterParams)
			if hit and hit.Material ~= Enum.Material.Water and hit.Normal.Y > 0.9 then
				K.anchor(
					if random:NextNumber() < 0.65 then "Buisson" else "Tole",
					"fragile",
					CFrame.new(hit.Position) * CFrame.Angles(0, random:NextNumber(0, 6), 0)
				)
				countryside += 1
			end
		end
	end

	local function measure(problems: { string })
		if trees < 250 then
			table.insert(problems, string.format("Vegetation : %d arbres seulement", trees))
		end
	end

	return {
		measure = measure,
		summary = string.format(
			"Vegetation : %d arbres, %d buissons, %d rochers, %d cachettes dans la campagne",
			trees,
			bushes,
			rocks,
			countryside
		),
	}
end
