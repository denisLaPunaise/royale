--!strict
--[[
	La Banlieue — a l'est, a mi-pente : un lotissement abandonne.

	Pas de quadrillage (Josh : « naturel, pas symetrique ») : une rue
	principale qui serpente d'ouest en est, une boucle au nord, une rue qui
	descend vers la riviere (et le pont vers l'Hypermarche), deux impasses
	avec leur rond de retournement. Les maisons suivent leur rue, chacune un
	peu en retrait ou de biais, avec un jardin derriere (haie devant,
	palissade derriere, un arbre, parfois un abri). Les maisons, leurs
	interieurs et leurs toits arrachables viennent de Survivor.

	Cachettes posees ici (emplacements) : buissons devant les maisons, toles
	au fond des jardins, abris de jardin, voitures garees, bennes.
]]

local ROAD_WIDTH = 16
-- Le pas entre deux maisons le long d'une rue : assez serre pour une rue
-- de lotissement, assez large pour un jardin sur le cote.
local HOUSE_STEP = { min = 38, max = 46 }

local SIDINGS_MATERIALS = { Enum.Material.WoodPlanks, Enum.Material.Brick, Enum.Material.Plaster }

return function(K: any)
	local O, V = K.O, K.V
	local C, P = O.C, O.P
	local random: Random = K.random
	local zone = K.Plan.zones[4]
	assert(zone.name == "Banlieue", "le plan a change : la Banlieue n'est plus la 4e zone")
	local folder = K.zoneFolder("Banlieue")

	local function inside(x: number, z: number, margin: number): boolean
		return x > zone.minX + margin
			and x < zone.maxX - margin
			and z > zone.minZ + margin
			and z < zone.maxZ - margin
	end

	-- Les rues, en points de passage ; la courbe les lisse.
	local streets = {
		-- La rue principale, de l'ouest (vers le Cratere) a l'est.
		{
			Vector2.new(150, 40),
			Vector2.new(270, 28),
			Vector2.new(390, 64),
			Vector2.new(510, 38),
			Vector2.new(630, -12),
			Vector2.new(790, -40),
		},
		-- La boucle du nord.
		{
			Vector2.new(390, 64),
			Vector2.new(400, 150),
			Vector2.new(450, 228),
			Vector2.new(560, 262),
			Vector2.new(660, 220),
			Vector2.new(705, 130),
			Vector2.new(690, 30),
			Vector2.new(640, -8),
		},
		-- La rue qui descend vers la riviere.
		{
			Vector2.new(510, 38),
			Vector2.new(486, -58),
			Vector2.new(448, -150),
			Vector2.new(430, -250),
		},
		-- L'impasse de l'est, avec son rond.
		{ Vector2.new(458, -118), Vector2.new(545, -142), Vector2.new(635, -175) },
		-- L'impasse de l'ouest.
		{ Vector2.new(270, 28), Vector2.new(252, -60), Vector2.new(292, -152) },
	}
	local turnarounds = { Vector2.new(642, -178), Vector2.new(296, -160) }

	local curves: { { Vector2 } } = {}
	for _, s in streets do
		local curve = K.spline(s, 14)
		table.insert(curves, curve)
		K.road(folder, curve, ROAD_WIDTH, true)
	end
	for _, t in turnarounds do
		local y = K.ground(t.X, t.Y) + 0.15
		P(
			folder,
			"RondDeRetournement",
			Vector3.new(0.4, 34, 34),
			CFrame.new(t.X, y, t.Y) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.Asphalt,
			C.asphalt,
			{ shape = Enum.PartType.Cylinder }
		)
		K.claim(t.X, t.Y, 20)
	end

	local houses = 0
	local carsParked = 0
	local stories = { "barricadee", "brulee", "mot" }

	-- Une maison et son jardin, face a la rue. `front` : le milieu du bas de
	-- la facade ; `inward` : de la rue vers la maison.
	local function plot(front: Vector3, inward: Vector3, index: number)
		local w, d = V.HOUSE_W, V.HOUSE_D
		local center = front + inward * (d / 2)
		local right = Vector3.new(-inward.Z, 0, inward.X)
		-- La maison et son jardin doivent tenir dans la zone et sur la place
		-- libre ; sinon on laisse un terrain vague.
		if not inside(center.X, center.Z, 20) then
			return
		end
		if
			not K.isFree(center.X, center.Z, 18)
			or not K.isFree(center.X + inward.X * 26, center.Z + inward.Z * 26, 12)
		then
			return
		end
		-- Pas sur une pente trop forte : la maison flotterait d'un cote.
		local low, high = math.huge, -math.huge
		for _, corner in { { -1, 0 }, { 1, 0 }, { -1, 1 }, { 1, 1 } } do
			local p = front + right * (corner[1] * w / 2) + inward * (corner[2] * d)
			local y = K.ground(p.X, p.Z)
			low, high = math.min(low, y), math.max(high, y)
		end
		if high - low > 4 then
			return
		end
		K.claim(center.X, center.Z, 18)
		K.claim(center.X + inward.X * 26, center.Z + inward.Z * 26, 12)

		local floorY = high
		local base = Vector3.new(front.X, floorY, front.Z)
		local cf = CFrame.lookAt(base, base - inward)
		-- Le bois genere assombrit la couleur : un bardage de bois est peint
		-- plus clair, sinon les maisons de bois semblaient noires (vu a
		-- l'ecran le 12 novembre 2026).
		local sidingMaterial = SIDINGS_MATERIALS[random:NextInteger(1, #SIDINGS_MATERIALS)]
		local siding = O.SIDINGS[random:NextInteger(1, #O.SIDINGS)]
		if sidingMaterial == Enum.Material.WoodPlanks then
			siding = siding:Lerp(Color3.new(1, 1, 1), 0.45)
		end
		local roll = random:NextNumber()
		local damage = if roll < 0.14 then "ruine" elseif roll < 0.3 then "trou" else "intact"
		local storyRoll = random:NextNumber()
		local m = V.house(folder, cf, {
			name = "Maison" .. index,
			siding = siding,
			material = sidingMaterial,
			roof = if random:NextNumber() < 0.5 then C.roofSlate else C.roofBrown,
			damage = damage,
			garage = random:NextNumber() < 0.25
				and K.isFree(center.X + right.X * 20, center.Z + right.Z * 20, 8),
			storeys = if random:NextNumber() < 0.4 then 2 else 1,
			mirror = random:NextNumber() < 0.5,
			bedroom = random:NextNumber() < 0.5,
			story = if storyRoll < 0.3 then stories[random:NextInteger(1, #stories)] else nil,
		}, K.containers)
		houses += 1
		-- Un soubassement : sur une legere pente, la maison ne flotte pas.
		if high - low > 0.3 then
			P(
				folder,
				"Soubassement",
				Vector3.new(w + 0.6, high - low + 1.2, d + 0.6),
				cf * CFrame.new(0, -(high - low) / 2 - 0.4, d / 2),
				Enum.Material.Concrete,
				C.concreteDark
			)
		end
		_ = m

		-- Le jardin de devant : une haie basse, un buisson-cachette dans le
		-- coin, parfois une voiture garee devant.
		local yard = cf * CFrame.new(0, 0, -6)
		V.hedge(
			folder,
			(yard * CFrame.new(-w / 2, 0, 0)).Position,
			(yard * CFrame.new(-5, 0, 0)).Position
		)
		if random:NextNumber() < 0.8 then
			K.anchor("Buisson", "fragile", cf * CFrame.new(w / 2 - 3, 0, -4))
		end
		if random:NextNumber() < 0.45 then
			K.anchor(
				"Voiture",
				"moyenne",
				cf
					* CFrame.new(random:NextNumber(-6, 6), 0, -12)
					* CFrame.Angles(0, math.rad(90), 0)
			)
			carsParked += 1
		end

		-- Le jardin de derriere : palissade, un arbre, une tole ou un abri.
		local back = cf * CFrame.new(0, 0, d)
		local gardenDepth = random:NextNumber(14, 20)
		local function fencePoint(x: number, z: number): Vector3
			local p = (back * CFrame.new(x, 0, z)).Position
			return Vector3.new(p.X, K.ground(p.X, p.Z), p.Z)
		end
		V.fence(folder, fencePoint(-w / 2 - 2, gardenDepth), fencePoint(w / 2 + 2, gardenDepth), 5)
		if random:NextNumber() < 0.7 then
			V.fence(folder, fencePoint(-w / 2 - 2, 0), fencePoint(-w / 2 - 2, gardenDepth), 5)
		end
		local treeAt = fencePoint(random:NextNumber(-w / 2 + 3, w / 2 - 3), gardenDepth - 4)
		V.tree(folder, treeAt, random:NextNumber() < 0.15)
		local tail = random:NextNumber()
		if tail < 0.3 then
			K.anchor(
				"Abri",
				"moyenne",
				back
					* CFrame.new(random:NextNumber(-6, 6), 0, gardenDepth - 6)
					* CFrame.Angles(0, math.pi, 0)
			)
		elseif tail < 0.75 then
			K.anchor(
				"Tole",
				"fragile",
				back
					* CFrame.new(random:NextNumber(-8, 8), 0, gardenDepth - 3)
					* CFrame.Angles(0, math.pi, 0)
			)
		end
	end

	-- Les maisons le long de chaque rue, des deux cotes, un peu en retrait
	-- ou de biais : une rue reelle n'est pas alignee a la regle.
	local index = 0
	for _, curve in curves do
		local walked = random:NextNumber(10, 24)
		local nextAt = walked
		local acc = 0
		for i = 1, #curve - 1 do
			local a, b = curve[i], curve[i + 1]
			local seg = (b - a).Magnitude
			while acc + seg >= nextAt do
				local t = (nextAt - acc) / seg
				local p = a:Lerp(b, t)
				local dir = (b - a).Unit
				for _, side in { -1, 1 } do
					local normal = Vector2.new(-dir.Y, dir.X) * side
					local setback = ROAD_WIDTH / 2 + 3 + random:NextNumber(7, 13)
					local f = p + normal * setback
					local skew = math.rad(random:NextNumber(-6, 6))
					local inward2 = Vector2.new(
						normal.X * math.cos(skew) - normal.Y * math.sin(skew),
						normal.X * math.sin(skew) + normal.Y * math.cos(skew)
					)
					index += 1
					plot(Vector3.new(f.X, 0, f.Y), Vector3.new(inward2.X, 0, inward2.Y), index)
				end
				nextAt += random:NextNumber(HOUSE_STEP.min, HOUSE_STEP.max)
			end
			acc += seg
		end
	end

	-- Des lampadaires le long des rues, et des voitures abandonnees au
	-- milieu de la chaussee (decor), quelques bennes.
	for ci, curve in curves do
		for i = 3, #curve - 1, 5 do
			local a, b = curve[i], curve[i + 1]
			local dir = (b - a).Unit
			local side = if (i + ci) % 2 == 0 then 1 else -1
			local normal = Vector2.new(-dir.Y, dir.X) * side
			local p = a + normal * (ROAD_WIDTH / 2 + 1.2)
			V.lamp(
				folder,
				Vector3.new(p.X, K.ground(p.X, p.Y), p.Y),
				Vector3.new(-normal.X, 0, -normal.Y)
			)
			if random:NextNumber() < 0.18 then
				local q = a + normal * (ROAD_WIDTH / 4)
				local y = K.ground(q.X, q.Y)
				K.anchor(
					"Voiture",
					"moyenne",
					CFrame.lookAt(
						Vector3.new(q.X, y, q.Y),
						Vector3.new(q.X + dir.X, y, q.Y + dir.Y)
					) * CFrame.Angles(0, math.rad(random:NextNumber(-25, 25)), 0)
				)
			end
			if random:NextNumber() < 0.08 then
				local q = a + normal * (ROAD_WIDTH / 2 + 4)
				K.anchor(
					"Benne",
					"fragile",
					CFrame.new(q.X, K.ground(q.X, q.Y), q.Y)
						* CFrame.Angles(0, math.atan2(dir.X, dir.Y), 0)
				)
			end
		end
	end

	-- Les objets de rue : des bornes a incendie au bord des trottoirs, des
	-- poubelles devant les maisons (une sur trois renversee), des cones.
	for _, curve in curves do
		for i = 2, #curve - 1, 4 do
			local a, b = curve[i], curve[i + 1]
			local dir = (b - a).Unit
			for _, side in { -1, 1 } do
				local normal = Vector2.new(-dir.Y, dir.X) * side
				local p = a + normal * (ROAD_WIDTH / 2 + 1.8) + dir * random:NextNumber(-4, 4)
				local roll = random:NextNumber()
				local base = CFrame.new(p.X, K.ground(p.X, p.Y), p.Y)
					* CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
				if roll < 0.12 then
					K.prop(folder, "BorneIncendie", base)
				elseif roll < 0.4 then
					local knocked = random:NextNumber() < 0.35
					K.prop(
						folder,
						"Poubelle",
						if knocked
							then base * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.rad(88))
							else base
					)
				elseif roll < 0.46 then
					K.prop(
						folder,
						"Cone",
						if random:NextNumber() < 0.5
							then base * CFrame.new(0, 0.8, 0) * CFrame.Angles(math.rad(85), 0, 0)
							else base
					)
				end
			end
		end
	end

	-- Ce que la recette doit pouvoir verifier.
	local function measure(problems: { string })
		if houses < 30 then
			table.insert(problems, string.format("Banlieue : seulement %d maisons", houses))
		end
		if carsParked < 8 then
			table.insert(
				problems,
				string.format("Banlieue : seulement %d voitures garees", carsParked)
			)
		end
	end

	return {
		measure = measure,
		summary = string.format("Banlieue : %d maisons, %d voitures garees", houses, carsParked),
	}
end
