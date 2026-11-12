--!strict
--[[
	Le Marais — au sud-ouest, a l'embouchure de la riviere : une foret noyee.

	Des cabanes de pecheurs sur pilotis au-dessus des mares, reliees par des
	pontons de bois qui zigzaguent (il en manque des planches) ; des arbres
	morts, gris, les pieds dans l'eau ; des arbres vivants sur les ilots ;
	une barque retournee ; un vieil affut de chasseur. Sa cachette propre :
	les roseaux, un volume ou l'on bouge librement, partout au bord de l'eau.
]]

local CABINS = 8

return function(K: any)
	local O, V = K.O, K.V
	local C, P = O.C, O.P
	local random: Random = K.random
	local zone = K.Plan.zones[6]
	assert(zone.name == "Marais", "le plan a change : le Marais n'est plus la 6e zone")
	local folder = K.zoneFolder("Marais")
	local sea = K.Plan.SEA_LEVEL

	local waterParams = RaycastParams.new()
	waterParams.FilterType = Enum.RaycastFilterType.Include
	waterParams.FilterDescendantsInstances = { workspace.Terrain }
	waterParams.IgnoreWater = false
	local function isWater(x: number, z: number): boolean
		local hit = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -400, 0), waterParams)
		return hit ~= nil and hit.Material == Enum.Material.Water
	end
	local function randomPoint(margin: number): (number, number)
		return random:NextNumber(zone.minX + margin, zone.maxX - margin),
			random:NextNumber(zone.minZ + margin, zone.maxZ - margin)
	end

	-- LES CABANES sur pilotis, au-dessus de l'eau de preference.
	local cabins: { Vector3 } = {}
	local tries = 0
	while #cabins < CABINS and tries < 200 do
		tries += 1
		local x, z = randomPoint(30)
		if (isWater(x, z) or tries > 120) and K.claim(x, z, 16) then
			local deckY = math.max(K.ground(x, z), sea) + random:NextNumber(4, 6)
			local cf = CFrame.new(x, deckY, z)
				* CFrame.Angles(
					0,
					random:NextNumber(0, math.pi * 2),
					math.rad(random:NextNumber(-3, 3))
				)
			local m = O.model(folder, "Cabane")
			local plank = Color3.fromRGB(96, 82, 66)
			-- Les pilotis, jusqu'au fond.
			for _, sx in { -6, 6 } do
				for _, sz in { -5, 5 } do
					local foot = (cf * CFrame.new(sx, 0, sz)).Position
					local floorY = K.ground(foot.X, foot.Z) - 2
					P(
						m,
						"Pilotis",
						Vector3.new(1, deckY - floorY, 1),
						CFrame.new(foot.X, (deckY + floorY) / 2, foot.Z),
						Enum.Material.Wood,
						C.bark
					)
				end
			end
			P(m, "Plancher", Vector3.new(16, 0.6, 14), cf, Enum.Material.WoodPlanks, plank)
			O.wall(m, cf * CFrame.new(0, 0.3, -4), 11, 7, 0.4, {
				{ x = -2, w = 3.2, b = 0, t = 6, kind = "door" },
				{ x = 3, w = 2.4, b = 3, t = 5, kind = "window" },
			}, Enum.Material.WoodPlanks, plank)
			O.wall(
				m,
				cf * CFrame.new(0, 0.3, 4) * CFrame.Angles(0, math.pi, 0),
				11,
				7,
				0.4,
				{ { x = 0, w = 2.4, b = 3, t = 5, kind = "window" } },
				Enum.Material.WoodPlanks,
				plank
			)
			for _, sx in { -5.5, 5.5 } do
				O.wall(
					m,
					cf * CFrame.new(sx, 0.3, 0) * CFrame.Angles(0, math.rad(90), 0),
					8,
					7,
					0.4,
					{},
					Enum.Material.WoodPlanks,
					plank
				)
			end
			O.slab(
				m,
				(cf * CFrame.new(-6.5, 7.3, -5)).Position,
				(cf * CFrame.new(-6.5, 9.5, 5)).Position,
				13,
				0.4,
				Enum.Material.Metal,
				C.rust,
				"Toit"
			)
			V.tagBuilding(m, deckY)
			K.crate(cf * CFrame.new(3, 0.3, 1.5), "marais")
			table.insert(cabins, cf.Position)
		end
	end

	-- LES PONTONS : de cabane en cabane, en zigzag, avec des planches qui
	-- manquent. Le premier part de la route du pont de l'ouest.
	local walked = 0
	local function boardwalk(a: Vector3, b: Vector3)
		local m = O.model(folder, "Ponton")
		local mid = (a + b) / 2
			+ Vector3.new(random:NextNumber(-12, 12), 0, random:NextNumber(-12, 12))
		for _, pair in { { a, mid }, { mid, b } } do
			local p0, p1 = pair[1], pair[2]
			local len = (p1 - p0).Magnitude
			local cf = CFrame.lookAt((p0 + p1) / 2, p1)
			for k = 0, math.floor(len / 1.6) do
				if random:NextNumber() > 0.07 then
					P(
						m,
						"Planche",
						Vector3.new(4, 0.3, 1.4),
						cf
							* CFrame.new(0, 0, -len / 2 + k * 1.6)
							* CFrame.Angles(0, math.rad(random:NextNumber(-4, 4)), 0),
						Enum.Material.WoodPlanks,
						C.woodGray
					)
				end
			end
			for k = 0, math.floor(len / 8) do
				local foot = (cf * CFrame.new(0, 0, -len / 2 + k * 8)).Position
				local floorY = K.ground(foot.X, foot.Z) - 1
				P(
					m,
					"Pieu",
					Vector3.new(0.7, foot.Y - floorY, 0.7),
					CFrame.new(foot.X, (foot.Y + floorY) / 2, foot.Z),
					Enum.Material.Wood,
					C.bark
				)
			end
			walked += len
		end
	end
	local entry = Vector3.new(-430, math.max(K.ground(-430, -380), sea) + 1.5, -380)
	-- Chaque cabane se relie a la plus proche deja reliee (un arbre couvrant) :
	-- des pontons courts qui se ramifient. En chaine, ils traversaient tout le
	-- Marais en longues lignes droites (vu a l'ecran le 12 novembre 2026).
	local linked: { Vector3 } = { entry }
	local pending = table.clone(cabins)
	while #pending > 0 do
		local bestI, bestFrom, bestD = 1, entry, math.huge
		for pi, c in pending do
			for _, l in linked do
				local d = (Vector3.new(c.X, 0, c.Z) - Vector3.new(l.X, 0, l.Z)).Magnitude
				if d < bestD then
					bestI, bestFrom, bestD = pi, l, d
				end
			end
		end
		local c = table.remove(pending, bestI) :: Vector3
		boardwalk(bestFrom, Vector3.new(c.X, c.Y - 0.1, c.Z))
		table.insert(linked, c)
	end

	-- LES ROSEAUX, au bord de l'eau : la cachette du Marais.
	local reeds = 0
	for _ = 1, 160 do
		local x, z = randomPoint(10)
		local wet = isWater(x, z)
		local nearWater = wet or isWater(x + 8, z) or isWater(x - 8, z) or isWater(x, z + 8)
		if nearWater and K.claim(x, z, 6) then
			K.anchor(
				"Roseaux",
				"fragile",
				CFrame.new(x, math.max(K.ground(x, z), sea - 0.5), z)
					* CFrame.Angles(0, random:NextNumber(0, 6), 0)
			)
			reeds += 1
			if reeds >= 34 then
				break
			end
		end
	end

	-- LES ARBRES : des morts dans l'eau, des vivants sur les ilots.
	local trees = 0
	for _ = 1, 90 do
		local x, z = randomPoint(5)
		if K.claim(x, z, 6) then
			local wet = isWater(x, z)
			V.tree(folder, Vector3.new(x, K.ground(x, z), z), wet or random:NextNumber() < 0.3)
			trees += 1
			if trees >= 46 then
				break
			end
		end
	end

	-- La barque retournee et l'affut de chasseur.
	do
		local x, z = randomPoint(40)
		local y = math.max(K.ground(x, z), sea)
		P(
			folder,
			"BarqueRetournee",
			Vector3.new(14, 2.2, 5),
			CFrame.new(x, y + 0.6, z) * CFrame.Angles(math.pi, random:NextNumber(0, 6), math.rad(8)),
			Enum.Material.WoodPlanks,
			Color3.fromRGB(70, 84, 72)
		)
		local hx, hz = randomPoint(40)
		if K.claim(hx, hz, 6) then
			local m = O.model(folder, "Affut")
			local base = Vector3.new(hx, K.ground(hx, hz), hz)
			for _, sx in { -2, 2 } do
				for _, sz in { -2, 2 } do
					P(
						m,
						"Pied",
						Vector3.new(0.6, 12, 0.6),
						CFrame.new(base + Vector3.new(sx, 6, sz)),
						Enum.Material.Wood,
						C.bark
					)
				end
			end
			P(
				m,
				"Plateforme",
				Vector3.new(5.6, 0.4, 5.6),
				CFrame.new(base + Vector3.new(0, 12, 0)),
				Enum.Material.WoodPlanks,
				C.woodGray
			)
			P(
				m,
				"Echelle",
				Vector3.new(1.6, 12.5, 0.3),
				CFrame.new(base + Vector3.new(0, 6, 3)) * CFrame.Angles(math.rad(-12), 0, 0),
				Enum.Material.Wood,
				C.wood
			)
		end
	end

	local function measure(problems: { string })
		if #cabins < 5 then
			table.insert(problems, string.format("Marais : %d cabanes seulement", #cabins))
		end
		if reeds < 15 then
			table.insert(
				problems,
				string.format("Marais : %d roseaux seulement (pas assez d'eau trouvee ?)", reeds)
			)
		end
	end

	return {
		measure = measure,
		summary = string.format(
			"Marais : %d cabanes sur pilotis, %.0f studs de pontons, %d roseaux, %d arbres",
			#cabins,
			walked,
			reeds,
			trees
		),
	}
end
