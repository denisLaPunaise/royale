--!strict
--[[
	La Gare de triage — tout le long du sud : un faisceau de voies d'ouest en
	est, au fond de la plaine.

	Six voies paralleles qui s'ecartent un peu (un faisceau n'est pas une
	grille), des rames de wagons arretees, certaines couchees en travers par
	l'Oeil ; une gare de voyageurs avec son quai et sa marquise ; une
	passerelle au-dessus des voies ; un depot ; des tas de rails et de
	traverses, des signaux. Sa cachette propre : le wagon, deux portes, une
	de chaque cote (CONCEPT.md).
]]

return function(K: any)
	local O, V, B = K.O, K.V, K.B
	local C, P = O.C, O.P
	local random: Random = K.random
	local zone = K.Plan.zones[7]
	assert(zone.name == "GareDeTriage", "le plan a change : la Gare n'est plus la 7e zone")
	local folder = K.zoneFolder("GareDeTriage")
	local function g(x: number, z: number): Vector3
		return Vector3.new(x, K.ground(x, z), z)
	end

	-- Les voies : chacune ondule doucement, et elles s'ecartent vers l'est.
	local tracks: { { Vector3 } } = {}
	local midZ = (zone.minZ + zone.maxZ) / 2
	for i = -3, 2 do
		local pts: { Vector3 } = {}
		for x = zone.minX + 10, zone.maxX + 40, 60 do
			local spread = 1 + (x - zone.minX) / 2600
			local z = midZ + i * 18 * spread + 6 * math.noise(x / 300, i)
			table.insert(pts, g(x, z) + Vector3.new(0, 0.3, 0))
		end
		table.insert(tracks, pts)
		for k = 1, #pts - 1 do
			B.rails(folder, pts[k], pts[k + 1])
			K.claim(pts[k].X, pts[k].Z, 6)
		end
	end

	-- La gare de voyageurs, au milieu, au nord des voies, et son quai.
	local stationX = 40
	do
		local base = g(stationX, zone.maxZ - 10)
		local cf = CFrame.lookAt(base, base + Vector3.new(0, 0, 1))
		B.building(folder, cf, {
			name = "Gare",
			w = 70,
			d = 22,
			floors = 2,
			floorH = 11,
			material = Enum.Material.Brick,
			color = Color3.fromRGB(160, 128, 100),
			roof = "pente",
			windowEvery = 7,
			doors = 3,
		})
		K.claim(base.X, base.Z - 11, 38)
		-- L'horloge, arretee.
		local clock = P(
			folder,
			"Horloge",
			Vector3.new(0.4, 5, 5),
			cf * CFrame.new(0, 24, -0.5) * CFrame.Angles(0, math.rad(90), 0),
			Enum.Material.SmoothPlastic,
			C.trim,
			{ shape = Enum.PartType.Cylinder }
		)
		_ = clock
		-- Le quai et sa marquise, le long de la voie la plus au nord.
		local q = O.model(folder, "Quai")
		local quayCf = CFrame.new(stationX, base.Y + 1.4, zone.maxZ - 34)
		P(q, "Quai", Vector3.new(140, 2.8, 10), quayCf, Enum.Material.Concrete, C.concrete)
		P(
			q,
			"Marquise",
			Vector3.new(120, 0.5, 9),
			quayCf * CFrame.new(0, 10, 0),
			Enum.Material.Metal,
			C.metal
		)
		for x = -54, 54, 18 do
			P(
				q,
				"Colonne",
				Vector3.new(0.8, 9, 0.8),
				quayCf * CFrame.new(x, 5.6, 0),
				Enum.Material.Metal,
				Color3.fromRGB(60, 80, 70)
			)
		end
		for _ = 1, 4 do
			P(
				q,
				"Banc",
				Vector3.new(5, 0.5, 1.6),
				quayCf * CFrame.new(random:NextNumber(-60, 60), 2.4, 2),
				Enum.Material.WoodPlanks,
				C.wood
			)
		end
		V.tagBuilding(q, base.Y)
		for _ = 1, 4 do
			K.crate(
				quayCf * CFrame.new(random:NextNumber(-60, 60), 1.4, random:NextNumber(-3, 3)),
				"gare"
			)
		end
	end

	-- La passerelle au-dessus des voies, a l'est de la gare.
	do
		local m = O.model(folder, "Passerelle")
		local x = stationX + 120
		local a = g(x, zone.maxZ - 8) + Vector3.new(0, 16, 0)
		local b = g(x, zone.minZ + 8) + Vector3.new(0, 16, 0)
		local cf = CFrame.lookAt((a + b) / 2, b)
		local len = (b - a).Magnitude
		P(
			m,
			"Tablier",
			Vector3.new(6, 0.8, len),
			cf,
			Enum.Material.Metal,
			Color3.fromRGB(60, 80, 70)
		)
		for _, sx in { -3, 3 } do
			P(
				m,
				"GardeCorps",
				Vector3.new(0.3, 3, len),
				cf * CFrame.new(sx, 1.8, 0),
				Enum.Material.Metal,
				Color3.fromRGB(60, 80, 70)
			)
		end
		for _, endPoint in { a, b } do
			local foot =
				Vector3.new(endPoint.X + 22, K.ground(endPoint.X + 22, endPoint.Z), endPoint.Z)
			P(
				m,
				"Escalier",
				Vector3.new(4, 0.8, (endPoint - foot).Magnitude),
				CFrame.lookAt((endPoint + foot) / 2, endPoint),
				Enum.Material.Metal,
				Color3.fromRGB(60, 80, 70)
			)
			P(
				m,
				"Pile",
				Vector3.new(1.5, 16, 1.5),
				CFrame.new(endPoint - Vector3.new(0, 8, 0)),
				Enum.Material.Metal,
				Color3.fromRGB(60, 80, 70)
			)
		end
	end

	-- Le depot, a l'est : un hangar ou dorment des wagons.
	do
		local base = g(zone.maxX - 70, midZ)
		local cf = CFrame.lookAt(base, base + Vector3.new(-1, 0, 0))
		B.hangar(folder, cf, 50, 80, 17, "Depot")
		K.claim(base.X + 40, base.Z, 44)
	end

	-- Les rames : des wagons arretes sur les voies, certains couches en
	-- travers. Les wagons ouverts sont des cachettes (deux portes).
	local wagons, open = 0, 0
	for ti, pts in tracks do
		local x = zone.minX + random:NextNumber(40, 200)
		while x < zone.maxX - 160 do
			if random:NextNumber() < 0.55 then
				local rame = random:NextInteger(2, 5)
				for k = 0, rame - 1 do
					local wx = x + k * 38
					local seg =
						math.clamp(math.floor((wx - (zone.minX + 10)) / 60) + 1, 1, #pts - 1)
					local a, b = pts[seg], pts[seg + 1]
					local t = math.clamp((wx - a.X) / (b.X - a.X), 0, 1)
					local p = a:Lerp(b, t)
					local tipped = random:NextNumber() < 0.12
					local tank = random:NextNumber() < 0.25
					local cf = CFrame.lookAt(p, p + (b - a).Unit)
						* (
							if tipped
								then CFrame.new(random:NextNumber(4, 10), 0, 0) * CFrame.Angles(
									0,
									random:NextNumber(-0.6, 0.6),
									0
								)
								else CFrame.identity
						)
					B.wagon(folder, cf, tank, tipped)
					wagons += 1
					if not tank and not tipped and random:NextNumber() < 0.45 then
						open += 1
						local spot = O.model(K.solid, "Wagon" .. open)
						O.marker(spot, K.CONTRACT.inside, cf * CFrame.new(0, 6, 0))
						O.marker(spot, K.CONTRACT.exit, cf * CFrame.new(7, 3, 0))
						O.marker(spot, K.CONTRACT.exit, cf * CFrame.new(-7, 3, 0))
					end
				end
				x += rame * 38 + random:NextNumber(40, 140)
			else
				x += random:NextNumber(60, 160)
			end
		end
		_ = ti
	end

	-- Des tas de rails et de traverses, des signaux, des cachettes.
	for _ = 1, 14 do
		local x, z =
			random:NextNumber(zone.minX + 20, zone.maxX - 20),
			random:NextNumber(zone.minZ + 4, zone.maxZ - 4)
		if K.claim(x, z, 6) then
			local base = CFrame.new(g(x, z)) * CFrame.Angles(0, random:NextNumber(0, 6), 0)
			local roll = random:NextNumber()
			if roll < 0.35 then
				for k = 0, random:NextInteger(3, 7) do
					P(
						folder,
						"Traverse",
						Vector3.new(7.2, 0.6, 1.2),
						base
							* CFrame.new(0, 0.3 + k * 0.6, random:NextNumber(-0.3, 0.3))
							* CFrame.Angles(0, random:NextNumber(-0.2, 0.2), 0),
						Enum.Material.Wood,
						C.woodGray
					)
				end
				K.anchor("Caisses", "fragile", base * CFrame.new(7, 0, 0))
			elseif roll < 0.6 then
				P(
					folder,
					"Signal",
					Vector3.new(0.6, 12, 0.6),
					base * CFrame.new(0, 6, 0),
					Enum.Material.Metal,
					C.black
				)
				P(
					folder,
					"Feu",
					Vector3.new(1.6, 3, 1),
					base * CFrame.new(0, 12, 0),
					Enum.Material.Metal,
					C.black
				)
			else
				K.anchor(if random:NextNumber() < 0.5 then "Benne" else "Tole", "fragile", base)
			end
		end
	end

	local function measure(problems: { string })
		if wagons < 25 then
			table.insert(problems, string.format("Gare : %d wagons seulement", wagons))
		end
		if open < 6 then
			table.insert(problems, string.format("Gare : %d wagons-cachettes seulement", open))
		end
	end

	return {
		measure = measure,
		summary = string.format(
			"Gare : 6 voies, %d wagons (%d cachettes), gare et quai, passerelle, depot",
			wagons,
			open
		),
	}
end
