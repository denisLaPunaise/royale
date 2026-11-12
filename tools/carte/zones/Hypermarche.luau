--!strict
--[[
	L'Hypermarche eventre — au sud-est, dans la plaine, de l'autre cote du
	pont de l'est.

	Une grande boite de beton dont l'Oeil a aspire la moitie du toit : on voit
	les rayons a ciel ouvert. Dedans, des rangees de rayonnages (a fouiller),
	les caisses, le fond ou se trouve la chambre froide (cachette solide).
	Devant, un immense parking a decouvert, ses lampadaires, des voitures et
	des caddies abandonnes, un totem d'enseigne. Derriere, les quais de
	livraison et des semi-remorques (la cabine du camion est une cachette).
]]

return function(K: any)
	local O, V, B = K.O, K.V, K.B
	local C, P = O.C, O.P
	local random: Random = K.random
	local zone = K.Plan.zones[5]
	assert(zone.name == "Hypermarche", "le plan a change : l'Hypermarche n'est plus la 5e zone")
	local folder = K.zoneFolder("Hypermarche")
	local function g(x: number, z: number): Vector3
		return Vector3.new(x, K.ground(x, z), z)
	end

	-- Le magasin : 150 x 80, un peu de biais, l'entree vers le nord (le pont).
	local yaw = math.rad(6)
	local front = g(560, -420)
	local cf = CFrame.new(front) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, math.pi, 0)
	local W, D, H = 150, 80, 14
	local m = O.model(folder, "Magasin")
	local wallColor = Color3.fromRGB(176, 172, 162)
	P(
		m,
		"Dalle",
		Vector3.new(W, 0.8, D),
		cf * CFrame.new(0, 0.4, D / 2),
		Enum.Material.Concrete,
		C.concrete
	)
	-- La facade vitree, la plupart des vitres brisees.
	local openings = {}
	for k = -6, 6 do
		table.insert(openings, {
			x = k * 10,
			w = 8,
			b = if math.abs(k) <= 1 then 0 else 1,
			t = 11,
			kind = if math.abs(k) <= 1 then "door" else "window",
		})
	end
	O.wall(m, cf, W, H, 1, openings, Enum.Material.Concrete, wallColor)
	O.wall(m, cf * CFrame.new(0, 0, D) * CFrame.Angles(0, math.pi, 0), W, H, 1, {
		{ x = -40, w = 10, b = 0, t = 10, kind = "garage" },
		{ x = 0, w = 10, b = 0, t = 10, kind = "garage" },
		{ x = 40, w = 10, b = 0, t = 10, kind = "garage" },
	}, Enum.Material.Concrete, wallColor)
	for _, sx in { -1, 1 } do
		O.wall(
			m,
			cf * CFrame.new(sx * W / 2, 0, D / 2) * CFrame.Angles(0, math.rad(90 * sx), 0),
			D,
			H,
			1,
			{},
			Enum.Material.Concrete,
			wallColor
		)
	end
	-- Le bandeau de l'enseigne au-dessus de l'entree.
	P(
		m,
		"Bandeau",
		Vector3.new(60, 4, 1),
		cf * CFrame.new(0, H + 2, -0.6),
		Enum.Material.SmoothPlastic,
		Color3.fromRGB(80, 104, 130)
	)
	-- Le toit : la moitie est (cote entree) est partie ; il reste les poutres.
	P(
		m,
		"Toit",
		Vector3.new(W, 1, D * 0.45),
		cf * CFrame.new(0, H + 0.5, D * 0.775),
		Enum.Material.Concrete,
		C.concrete
	)
	for k = -7, 7 do
		if random:NextNumber() < 0.75 then
			P(
				m,
				"Poutre",
				Vector3.new(1, 1.4, D * random:NextNumber(0.4, 0.6)),
				cf
					* CFrame.new(k * 10, H + 0.7, D * 0.3)
					* CFrame.Angles(math.rad(random:NextNumber(-6, 2)), 0, 0),
				Enum.Material.Metal,
				C.rust
			)
		end
	end
	V.tagBuilding(m, front.Y)
	local center = (cf * CFrame.new(0, 0, D / 2)).Position
	K.claim(center.X, center.Z, 90)

	-- Les rayonnages : de longues rangees, quelques-unes renversees.
	local shelves = 0
	local productColors = {
		Color3.fromRGB(150, 70, 62),
		Color3.fromRGB(196, 176, 120),
		Color3.fromRGB(80, 104, 130),
		Color3.fromRGB(96, 128, 98),
	}
	for row = -5, 5 do
		local rcf = cf * CFrame.new(row * 12, 0.8, D * 0.45)
		local fallen = random:NextNumber() < 0.15
		local tilt = if fallen
			then CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(78))
			else CFrame.identity
		local shelf = P(
			m,
			"Rayon",
			Vector3.new(2.4, 7, 44),
			rcf * tilt * CFrame.new(0, 3.5, 0),
			Enum.Material.Metal,
			Color3.fromRGB(150, 150, 146)
		)
		_ = shelf
		for level = 0, 2 do
			for _ = 1, 6 do
				P(
					m,
					"Produit",
					Vector3.new(
						random:NextNumber(0.8, 1.6),
						random:NextNumber(0.8, 1.8),
						random:NextNumber(0.8, 1.6)
					),
					rcf
						* tilt
						* CFrame.new(
							random:NextNumber(-1.6, 1.6),
							1.2 + level * 2.3,
							random:NextNumber(-20, 20)
						),
					Enum.Material.SmoothPlastic,
					productColors[random:NextInteger(1, #productColors)]
				)
			end
		end
		local c = P(
			K.containers,
			"Rayonnage",
			Vector3.new(3, 2, 6),
			rcf * CFrame.new(0, 1, random:NextNumber(-16, 16)),
			Enum.Material.Metal,
			Color3.fromRGB(150, 150, 146),
			{ transparency = 1 }
		)
		c:SetAttribute("Table", "hypermarche")
		shelves += 1
	end
	-- Les caisses enregistreuses, pres de l'entree.
	for k = -4, 4 do
		local ccf = cf * CFrame.new(k * 9, 0.8, 9)
		P(
			m,
			"Caisse",
			Vector3.new(2, 3, 6),
			ccf * CFrame.new(0, 1.5, 0),
			Enum.Material.SmoothPlastic,
			Color3.fromRGB(70, 72, 76)
		)
		if k % 3 == 0 then
			K.anchor("Carton", "fragile", ccf * CFrame.new(4, 0, 0))
		end
	end
	-- La chambre froide, au fond : une cachette solide.
	do
		local fcf = cf * CFrame.new(-55, 0.8, D - 12)
		local cold = O.model(m, "ChambreFroide")
		O.wall(
			cold,
			fcf * CFrame.new(0, 0, -8),
			22,
			10,
			1,
			{ { x = 0, w = 4, b = 0, t = 8, kind = "door" } },
			Enum.Material.Metal,
			Color3.fromRGB(196, 200, 204)
		)
		for _, sx in { -11, 11 } do
			O.wall(
				cold,
				fcf * CFrame.new(sx, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
				16,
				10,
				1,
				{},
				Enum.Material.Metal,
				Color3.fromRGB(196, 200, 204)
			)
		end
		P(
			cold,
			"Plafond",
			Vector3.new(22, 1, 16),
			fcf * CFrame.new(0, 10.5, 0),
			Enum.Material.Metal,
			Color3.fromRGB(196, 200, 204)
		)
		local spot = O.model(K.solid, "ChambreFroide")
		O.marker(spot, K.CONTRACT.inside, fcf * CFrame.new(0, 3, 2))
		O.marker(spot, K.CONTRACT.exit, fcf * CFrame.new(0, 3, -12))
	end

	-- Le parking, immense et a decouvert, devant l'entree.
	local parked = 0
	do
		local pcf = cf * CFrame.new(0, 0, -45)
		local p = pcf.Position
		P(
			folder,
			"Parking",
			Vector3.new(170, 0.4, 70),
			CFrame.new(p.X, K.ground(p.X, p.Z) + 0.2, p.Z) * (cf - cf.Position),
			Enum.Material.Asphalt,
			C.asphalt
		)
		for row = 0, 2 do
			for k = -7, 7 do
				local scf = pcf * CFrame.new(k * 10, 0.45, -24 + row * 22)
				P(
					folder,
					"Marquage",
					Vector3.new(0.3, 0.05, 9),
					scf,
					Enum.Material.SmoothPlastic,
					C.line
				)
				local roll = random:NextNumber()
				if roll < 0.18 then
					K.anchor("Voiture", "moyenne", scf * CFrame.new(5, -0.45, 0))
					parked += 1
				elseif roll < 0.26 then
					-- Un caddie renverse.
					P(
						folder,
						"Caddie",
						Vector3.new(2.4, 2.6, 3.4),
						scf
							* CFrame.new(5, 1.3, 0)
							* CFrame.Angles(
								random:NextNumber(-1.5, 1.5),
								random:NextNumber(0, 6),
								0
							),
						Enum.Material.Metal,
						C.metal,
						{ transparency = 0.25 }
					)
				end
			end
			if row < 2 then
				for k = -6, 6, 4 do
					V.lamp(
						folder,
						(pcf * CFrame.new(k * 10, 0, -13 + row * 22)).Position,
						cf.LookVector
					)
				end
			end
		end
		-- Le totem de l'enseigne, au bord du parking.
		local t = pcf * CFrame.new(80, 0, -30)
		P(
			folder,
			"Totem",
			Vector3.new(3, 24, 10),
			t * CFrame.new(0, 12, 0),
			Enum.Material.Concrete,
			wallColor
		)
		P(
			folder,
			"Enseigne",
			Vector3.new(3.4, 8, 10.4),
			t * CFrame.new(0, 20, 0),
			Enum.Material.SmoothPlastic,
			Color3.fromRGB(80, 104, 130)
		)
	end

	-- Les quais de livraison, derriere, et des semi-remorques.
	for k = -1, 1 do
		local dcf = cf * CFrame.new(k * 40, 0, D + 14)
		local p = dcf.Position
		P(
			folder,
			"QuaiLivraison",
			Vector3.new(14, 4, 10),
			CFrame.new(p.X, K.ground(p.X, p.Z) + 2, p.Z) * (cf - cf.Position),
			Enum.Material.Concrete,
			C.concreteDark
		)
		if random:NextNumber() < 0.8 then
			local trailer = dcf * CFrame.new(0, 0, 22)
			P(
				folder,
				"Remorque",
				Vector3.new(8.6, 10, 34),
				trailer * CFrame.new(0, 6.5, 0),
				Enum.Material.Metal,
				Color3.fromRGB(190, 186, 176)
			)
			P(
				folder,
				"Cabine",
				Vector3.new(8.6, 8, 8),
				trailer * CFrame.new(0, 5, 22),
				Enum.Material.Metal,
				Color3.fromRGB(96, 60, 52)
			)
			local spot = O.model(K.solid, "Cabine" .. (k + 2))
			O.marker(spot, K.CONTRACT.inside, trailer * CFrame.new(0, 4, 22))
			O.marker(spot, K.CONTRACT.exit, trailer * CFrame.new(6, 3, 22))
		end
	end

	-- Le sol de la zone commerciale : de l'asphalte partout, comme une
	-- vraie zone de magasins ; sur la pelouse, tout semblait eparpille.
	do
		local region = Region3.new(Vector3.new(240, -20, -584), Vector3.new(756, 80, -344))
			:ExpandToGrid(4)
		for _, from in { Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground } do
			workspace.Terrain:ReplaceMaterial(region, 4, from, Enum.Material.Asphalt)
		end
	end
	-- LA ZONE COMMERCIALE autour de l'hypermarche : il n'occupait qu'un
	-- quart de sa place (mesure le 12 novembre 2026). Une station-service a
	-- l'entree, un restaurant rapide, un magasin de bricolage, un rond-point.
	local extras = 0
	local function standing(x: number, z: number, facing: Vector3): CFrame
		local p = g(x, z)
		return CFrame.lookAt(p, p + facing)
	end

	-- La station-service, pres du pont : un auvent sur piliers, des pompes,
	-- la boutique, le totem des prix.
	do
		local cf = standing(300, -410, Vector3.new(0, 0, 1))
		local m = O.model(folder, "StationService")
		local white = Color3.fromRGB(200, 198, 190)
		P(
			m,
			"Piste",
			Vector3.new(56, 0.4, 36),
			cf * CFrame.new(0, 0.2, 0),
			Enum.Material.Concrete,
			C.concrete
		)
		P(
			m,
			"Auvent",
			Vector3.new(44, 2, 24),
			cf * CFrame.new(0, 15, 0),
			Enum.Material.SmoothPlastic,
			white
		)
		P(
			m,
			"BandeauAuvent",
			Vector3.new(44.4, 1.2, 24.4),
			cf * CFrame.new(0, 14, 0),
			Enum.Material.SmoothPlastic,
			Color3.fromRGB(70, 110, 96)
		)
		for _, x in { -14, 14 } do
			for _, z in { -6, 6 } do
				P(
					m,
					"Pilier",
					Vector3.new(1.4, 14, 1.4),
					cf * CFrame.new(x, 7, z),
					Enum.Material.Metal,
					white
				)
			end
			for _, z in { -6, 6 } do
				P(
					m,
					"Pompe",
					Vector3.new(2, 5, 1.4),
					cf * CFrame.new(x * 0.5, 2.5, z),
					Enum.Material.SmoothPlastic,
					Color3.fromRGB(70, 110, 96)
				)
			end
		end
		V.tagBuilding(m, cf.Position.Y)
		K.anchor(
			"Voiture",
			"moyenne",
			cf * CFrame.new(-7, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
		)
		local shop = cf * CFrame.new(0, 0, 26)
		B.building(folder, shop * CFrame.Angles(0, math.pi, 0), {
			name = "BoutiqueStation",
			w = 30,
			d = 16,
			floors = 1,
			floorH = 11,
			material = Enum.Material.Plaster,
			color = white,
			roof = "plat",
			windowEvery = 7,
			doors = 1,
		})
		for k = -1, 1 do
			local shelf = P(
				K.containers,
				"Etagere",
				Vector3.new(8, 4, 2),
				shop * CFrame.new(k * 9, 2.4, 8),
				Enum.Material.Metal,
				C.metal
			)
			shelf:SetAttribute("Table", "station")
		end
		local totem = cf * CFrame.new(-34, 0, -14)
		P(
			m,
			"Totem",
			Vector3.new(2, 18, 6),
			totem * CFrame.new(0, 9, 0),
			Enum.Material.SmoothPlastic,
			Color3.fromRGB(70, 110, 96)
		)
		for k = 0, 2 do
			P(
				m,
				"Prix",
				Vector3.new(2.2, 1.6, 5),
				totem * CFrame.new(0, 12 + k * 1.9, 0),
				Enum.Material.SmoothPlastic,
				Color3.fromRGB(30, 30, 30)
			)
		end
		K.claim(cf.Position.X, cf.Position.Z + 10, 34)
		extras += 1
	end

	-- Le restaurant rapide et son drive, entre la station et l'hypermarche.
	do
		local cf = standing(330, -520, Vector3.new(1, 0, 0))
		B.building(folder, cf, {
			name = "RestaurantRapide",
			w = 30,
			d = 22,
			floors = 1,
			floorH = 10,
			material = Enum.Material.Brick,
			color = Color3.fromRGB(150, 90, 70),
			roof = "plat",
			windowEvery = 6,
			doors = 1,
		})
		P(
			folder,
			"Enseigne",
			Vector3.new(14, 3, 0.6),
			cf * CFrame.new(0, 12, -0.6),
			Enum.Material.SmoothPlastic,
			Color3.fromRGB(196, 176, 120)
		)
		for _, z in { 5, 12, 18 } do
			local c = P(
				K.containers,
				"Comptoir",
				Vector3.new(6, 3.4, 2),
				cf * CFrame.new(random:NextNumber(-8, 8), 1.7, z),
				Enum.Material.SmoothPlastic,
				C.metal
			)
			c:SetAttribute("Table", "restaurant")
		end
		for k = 0, 3 do
			P(
				folder,
				"Table",
				Vector3.new(4, 0.4, 4),
				cf * CFrame.new(-10 + k * 6, 2.6, -8),
				Enum.Material.SmoothPlastic,
				Color3.fromRGB(196, 176, 120)
			)
		end
		K.anchor("Benne", "fragile", cf * CFrame.new(18, 0, 18))
		K.claim(cf.Position.X + 10, cf.Position.Z, 22)
		extras += 1
	end

	-- Le magasin de bricolage : un grand hangar, des palettes, des sacs de
	-- ciment, une cour de materiaux grillagee.
	do
		local cf = standing(705, -470, Vector3.new(-1, 0, 0))
		B.hangar(folder, cf, 56, 76, 16, "Bricolage")
		for _ = 1, 6 do
			local c = P(
				K.containers,
				"Palette",
				Vector3.new(5, 3, 5),
				cf
					* CFrame.new(random:NextNumber(-20, 20), 1.5, random:NextNumber(10, 66))
					* CFrame.Angles(0, random:NextNumber(0, 6), 0),
				Enum.Material.WoodPlanks,
				C.wood
			)
			c:SetAttribute("Table", "bricolage")
		end
		for _ = 1, 4 do
			K.anchor(
				if random:NextNumber() < 0.5 then "Caisses" else "Carton",
				"fragile",
				cf * CFrame.new(random:NextNumber(-22, 22), 0, random:NextNumber(-14, -4))
			)
		end
		local p = (cf * CFrame.new(0, 0, 38)).Position
		K.claim(p.X, p.Z, 44)
		extras += 1
	end

	-- Le rond-point a la sortie du pont, avec son terre-plein d'herbe et un
	-- panneau de direction.
	do
		local c = g(440, -372)
		P(
			folder,
			"RondPoint",
			Vector3.new(0.4, 40, 40),
			CFrame.new(c + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.Asphalt,
			C.asphalt,
			{ shape = Enum.PartType.Cylinder }
		)
		P(
			folder,
			"TerrePlein",
			Vector3.new(1.2, 18, 18),
			CFrame.new(c + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.Grass,
			Color3.fromRGB(88, 96, 68),
			{ shape = Enum.PartType.Cylinder }
		)
		V.tree(folder, c + Vector3.new(0, 1, 0), true)
		local post = c + Vector3.new(14, 0, -14)
		P(
			folder,
			"Panneau",
			Vector3.new(0.4, 8, 0.4),
			CFrame.new(post + Vector3.new(0, 4, 0)),
			Enum.Material.Metal,
			C.metal
		)
		P(
			folder,
			"Direction",
			Vector3.new(0.2, 1.6, 8),
			CFrame.new(post + Vector3.new(0, 7.4, 0)) * CFrame.Angles(0, math.rad(30), 0),
			Enum.Material.SmoothPlastic,
			Color3.fromRGB(70, 90, 140)
		)
		K.claim(c.X, c.Z, 22)
	end

	-- Des caddies et des cachettes sur toute la zone, pas seulement au parking.
	for _ = 1, 26 do
		local x, z =
			random:NextNumber(zone.minX + 15, zone.maxX - 15),
			random:NextNumber(zone.minZ + 10, zone.maxZ - 10)
		if K.claim(x, z, 5) then
			local cf = CFrame.new(g(x, z)) * CFrame.Angles(0, random:NextNumber(0, 6), 0)
			local roll = random:NextNumber()
			if roll < 0.35 then
				K.anchor("Voiture", "moyenne", cf)
			elseif roll < 0.6 then
				K.anchor(if random:NextNumber() < 0.5 then "Benne" else "Buisson", "fragile", cf)
			elseif roll < 0.8 then
				K.crate(cf, "hypermarche")
			else
				P(
					folder,
					"Caddie",
					Vector3.new(2.4, 2.6, 3.4),
					cf * CFrame.new(0, 1.3, 0) * CFrame.Angles(random:NextNumber(-1.5, 1.5), 0, 0),
					Enum.Material.Metal,
					C.metal,
					{ transparency = 0.25 }
				)
			end
		end
	end

	local function measure(problems: { string })
		if shelves < 8 then
			table.insert(problems, "Hypermarche : trop peu de rayons")
		end
	end

	return {
		measure = measure,
		summary = string.format(
			"Hypermarche : magasin eventre, %d rayons, parking (%d voitures), chambre froide, quais",
			shelves,
			parked
		),
	}
end
