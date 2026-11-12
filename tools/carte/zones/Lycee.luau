--!strict
--[[
	Le Lycee — au nord, sur son plateau, adosse a la butte.

	Un batiment principal de trois etages en L (couloirs, salles de classe,
	casiers), une aile plus basse, un gymnase de tole, une cour avec ses
	arbres et ses bancs, un terrain de sport, un parking. Le tout ferme par
	une grille qui a cede par endroits. Le toit plat se gagne en
	s'agrippant : on y voit loin, a decouvert.

	Sa cachette propre : les casiers des couloirs, a une place.
]]

return function(K: any)
	local O, V, B = K.O, K.V, K.B
	local C, P = O.C, O.P
	local random: Random = K.random
	local zone = K.Plan.zones[2]
	assert(zone.name == "Lycee", "le plan a change : le Lycee n'est plus la 2e zone")
	local folder = K.zoneFolder("Lycee")
	local function g(x: number, z: number): Vector3
		return Vector3.new(x, K.ground(x, z), z)
	end

	-- Le plateau n'est pas aligne sur les axes de la carte : le lycee est un
	-- peu de biais, face a la route qui monte du Cratere.
	local yaw = math.rad(-12)
	local origin = g(-30, 520)
	local frame = CFrame.new(origin) * CFrame.Angles(0, yaw, 0)
	local function at(x: number, z: number): CFrame
		local p = (frame * CFrame.new(x, 0, z)).Position
		return CFrame.new(p.X, K.ground(p.X, p.Z), p.Z) * CFrame.Angles(0, yaw, 0)
	end

	local brick = Color3.fromRGB(150, 112, 92)
	local cream = Color3.fromRGB(196, 186, 164)
	local classrooms = 0

	-- Le batiment principal (la barre du L) : 120 de long, 3 etages.
	local mainCf = at(0, 40)
	local main = B.building(folder, mainCf * CFrame.Angles(0, math.pi, 0), {
		name = "BatimentPrincipal",
		w = 120,
		d = 30,
		floors = 3,
		floorH = 12,
		material = Enum.Material.Brick,
		color = brick,
		roof = "plat",
		windowEvery = 8,
		doors = 2,
	})
	-- L'aile, en retour, plus basse et a moitie decoiffee par l'Oeil.
	local wingCf = at(-75, 0)
	B.building(folder, wingCf * CFrame.Angles(0, math.rad(90), 0), {
		name = "Aile",
		w = 70,
		d = 28,
		floors = 2,
		floorH = 12,
		material = Enum.Material.Plaster,
		color = cream,
		roof = "aspire",
		windowEvery = 8,
		doors = 1,
	})
	K.claim(origin.X, origin.Z + 25, 66)
	local wingCenter = (wingCf * CFrame.new(14, 0, 35)).Position
	K.claim(wingCenter.X, wingCenter.Z, 40)

	-- Les couloirs : des rangees de casiers contre les murs interieurs du rez
	-- (emplacements de cachettes) et des salles de classe a fouiller.
	for k = -5, 5 do
		local cf = mainCf * CFrame.Angles(0, math.pi, 0) * CFrame.new(k * 10, 0.8, 4)
		if random:NextNumber() < 0.7 then
			K.anchor("Casier", "moyenne", cf * CFrame.Angles(0, math.pi, 0))
		end
		if k % 2 == 0 then
			-- Un bureau de professeur et des tables renversees.
			local desk = P(
				K.containers,
				"Bureau",
				Vector3.new(6, 3, 3),
				cf * CFrame.new(0, 1.5, 18),
				Enum.Material.WoodPlanks,
				C.wood
			)
			desk:SetAttribute("Table", "classe")
			for _ = 1, 4 do
				P(
					main,
					"Table",
					Vector3.new(4, 0.3, 2.6),
					cf
						* CFrame.new(
							random:NextNumber(-4, 4),
							random:NextNumber(0.8, 2.4),
							random:NextNumber(10, 24)
						)
						* CFrame.Angles(random:NextNumber(-1.4, 1.4), random:NextNumber(0, 6), 0),
					Enum.Material.WoodPlanks,
					C.wood
				)
			end
			classrooms += 1
		end
	end
	-- Des casiers aussi dans l'aile.
	for k = -2, 2 do
		K.anchor(
			"Casier",
			"moyenne",
			wingCf
				* CFrame.Angles(0, math.rad(90), 0)
				* CFrame.new(k * 12, 0.8, 4)
				* CFrame.Angles(0, math.pi, 0)
		)
	end

	-- Le gymnase : un grand hangar de tole, derriere.
	local gymCf = at(70, -40)
	B.hangar(folder, gymCf, 52, 40, 16, "Gymnase")
	do
		local p = (gymCf * CFrame.new(0, 0, 20)).Position
		K.claim(p.X, p.Z, 34)
		-- Des tapis, des ballons, un panier tombe.
		for _ = 1, 3 do
			local mat = P(
				K.containers,
				"Tapis",
				Vector3.new(6, 1, 10),
				gymCf
					* CFrame.new(random:NextNumber(-18, 18), 0.8, random:NextNumber(8, 32))
					* CFrame.Angles(0, random:NextNumber(0, 6), 0),
				Enum.Material.Fabric,
				Color3.fromRGB(70, 90, 120)
			)
			mat:SetAttribute("Table", "gymnase")
		end
	end

	-- Le sol de la cour, de bitume use, entre les batiments.
	do
		local cf = at(-5, -2)
		P(
			folder,
			"Cour",
			Vector3.new(130, 0.3, 44),
			cf * CFrame.new(0, 0.12, 0),
			Enum.Material.Asphalt,
			C.asphaltPatch
		)
	end
	-- La cour : des arbres dans leurs grilles, des bancs, un preau.
	for k = 0, 5 do
		local cf = at(-40 + k * 18, 0)
		-- Le gymnase a pu prendre la place : pas d'arbre dans un mur.
		if not K.claim(cf.Position.X, cf.Position.Z, 4) then
			continue
		end
		V.tree(folder, cf.Position, random:NextNumber() < 0.2)
		P(
			folder,
			"GrilleArbre",
			Vector3.new(6, 0.3, 6),
			cf * CFrame.new(0, 0.15, 0),
			Enum.Material.Metal,
			C.metal
		)
		if k % 2 == 1 then
			P(
				folder,
				"Banc",
				Vector3.new(6, 0.5, 1.6),
				cf * CFrame.new(0, 1.6, 6),
				Enum.Material.WoodPlanks,
				C.wood
			)
		end
	end
	do
		local m = O.model(folder, "Preau")
		local cf = at(30, -5)
		P(
			m,
			"Toit",
			Vector3.new(30, 0.6, 12),
			cf * CFrame.new(0, 9, 0),
			Enum.Material.Metal,
			C.metal
		)
		for _, x in { -14, -5, 5, 14 } do
			P(
				m,
				"Poteau",
				Vector3.new(0.8, 9, 0.8),
				cf * CFrame.new(x, 4.5, -5.5),
				Enum.Material.Metal,
				C.metal
			)
		end
		V.tagBuilding(m, cf.Position.Y)
	end
	-- Des bennes et des cartons dans la cour.
	for _ = 1, 6 do
		local cf = at(random:NextNumber(-60, 60), random:NextNumber(-30, 10))
		if K.claim(cf.Position.X, cf.Position.Z, 4) then
			K.anchor(
				if random:NextNumber() < 0.5 then "Carton" else "Benne",
				"fragile",
				cf * CFrame.Angles(0, random:NextNumber(0, 6), 0)
			)
		end
	end

	-- Le terrain de sport : une piste ovale et un terrain au milieu.
	do
		local cf = at(-20, -120)
		local m = O.model(folder, "TerrainDeSport")
		P(
			m,
			"Pelouse",
			Vector3.new(80, 0.3, 46),
			cf * CFrame.new(0, 0.2, 0),
			Enum.Material.Grass,
			Color3.fromRGB(84, 96, 62)
		)
		for _, sz in { -1, 1 } do
			P(
				m,
				"Piste",
				Vector3.new(96, 0.25, 6),
				cf * CFrame.new(0, 0.3, sz * 26),
				Enum.Material.Ground,
				Color3.fromRGB(130, 76, 58)
			)
		end
		for _, sx in { -1, 1 } do
			-- Un but : deux poteaux et une barre (un panneau plein ressemblait a
			-- un mur blanc couche dans l'herbe, vu a l'ecran).
			for _, sz in { -8, 8 } do
				P(
					m,
					"Poteau",
					Vector3.new(0.5, 8, 0.5),
					cf * CFrame.new(sx * 38, 4, sz),
					Enum.Material.Metal,
					C.trim
				)
			end
			P(
				m,
				"Barre",
				Vector3.new(0.5, 0.5, 16.5),
				cf * CFrame.new(sx * 38, 8, 0),
				Enum.Material.Metal,
				C.trim
			)
		end
		K.claim((cf).Position.X, (cf).Position.Z, 50)
	end

	-- Le parking, devant : des voitures en epi, abandonnees.
	for k = 0, 6 do
		local cf = at(-50 + k * 12, 100)
			* CFrame.Angles(0, math.rad(90 + random:NextNumber(-8, 8)), 0)
		P(
			folder,
			"Marquage",
			Vector3.new(0.3, 0.2, 12),
			cf * CFrame.new(0, 0.1, 0),
			Enum.Material.SmoothPlastic,
			C.line
		)
		if random:NextNumber() < 0.6 then
			K.anchor("Voiture", "moyenne", cf * CFrame.new(0, 0, 6))
		end
	end
	do
		local cf = at(-14, 100)
		P(
			folder,
			"Parking",
			Vector3.new(100, 0.3, 26),
			cf * CFrame.new(0, 0.1, 0),
			Enum.Material.Asphalt,
			C.asphalt
		)
		K.claim(cf.Position.X, cf.Position.Z, 30)
	end

	-- La grille autour, qui a cede par endroits.
	local corners = { at(-120, -160), at(120, -160), at(120, 130), at(-120, 130) }
	for i = 1, 4 do
		local a, b = corners[i].Position, corners[(i % 4) + 1].Position
		local pieces = math.floor((b - a).Magnitude / 20)
		for k = 0, pieces - 1 do
			if random:NextNumber() > 0.15 then
				local p0, p1 = a:Lerp(b, k / pieces), a:Lerp(b, (k + 1) / pieces)
				V.fence(
					folder,
					Vector3.new(p0.X, K.ground(p0.X, p0.Z), p0.Z),
					Vector3.new(p1.X, K.ground(p1.X, p1.Z), p1.Z),
					6
				)
			end
		end
	end

	-- LE RESTE DU PLATEAU : le lycee n'en occupait que le centre (mesure le
	-- 12 novembre 2026). L'internat, la cantine, un terrain de basket, un
	-- abri a velos, et des cachettes partout.
	do
		local cf = at(115, 150)
		B.building(folder, cf * CFrame.Angles(0, math.pi, 0), {
			name = "Internat",
			w = 60,
			d = 20,
			floors = 3,
			floorH = 11,
			material = Enum.Material.Plaster,
			color = Color3.fromRGB(176, 170, 156),
			roof = "pente",
			windowEvery = 6,
			doors = 1,
		})
		for f = 0, 2 do
			for k = -2, 2 do
				if random:NextNumber() < 0.5 then
					local bed = P(
						K.containers,
						"Lit",
						Vector3.new(4, 1.6, 7),
						cf * CFrame.Angles(0, math.pi, 0) * CFrame.new(k * 11, f * 11 + 1.6, 12),
						Enum.Material.Fabric,
						C.fabric
					)
					bed:SetAttribute("Table", "chambre")
				end
			end
			K.anchor(
				"Armoire",
				"moyenne",
				cf
					* CFrame.Angles(0, math.pi, 0)
					* CFrame.new(random:NextNumber(-24, 24), f * 11 + 0.8, 17)
			)
		end
		K.claim(cf.Position.X, cf.Position.Z - 10, 34)
	end
	do
		local cf = at(-160, -40)
		B.building(folder, cf * CFrame.Angles(0, math.rad(90), 0), {
			name = "Cantine",
			w = 40,
			d = 26,
			floors = 1,
			floorH = 11,
			material = Enum.Material.Brick,
			color = Color3.fromRGB(150, 112, 92),
			roof = "aspire",
			windowEvery = 7,
			doors = 2,
		})
		for k = 0, 3 do
			P(
				folder,
				"TableCantine",
				Vector3.new(14, 0.5, 4),
				cf * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, 3, 4 + k * 5),
				Enum.Material.SmoothPlastic,
				Color3.fromRGB(196, 186, 164)
			)
		end
		local kitchen = P(
			K.containers,
			"Cuisine",
			Vector3.new(8, 4, 3),
			cf * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(-12, 2.8, 22),
			Enum.Material.Metal,
			C.metal
		)
		kitchen:SetAttribute("Table", "cuisine")
		K.claim(cf.Position.X + 13, cf.Position.Z, 26)
	end
	do
		local cf = at(150, -110)
		local m = O.model(folder, "TerrainDeBasket")
		P(
			m,
			"Sol",
			Vector3.new(34, 0.3, 20),
			cf * CFrame.new(0, 0.15, 0),
			Enum.Material.Asphalt,
			Color3.fromRGB(70, 84, 96)
		)
		for _, sx in { -1, 1 } do
			P(
				m,
				"Mat",
				Vector3.new(0.5, 10, 0.5),
				cf * CFrame.new(sx * 16, 5, 0),
				Enum.Material.Metal,
				C.metal
			)
			P(
				m,
				"Panneau",
				Vector3.new(0.3, 3, 5),
				cf * CFrame.new(sx * 15.6, 10, 0),
				Enum.Material.SmoothPlastic,
				C.trim
			)
		end
		K.claim(cf.Position.X, cf.Position.Z, 20)
	end
	do
		local cf = at(60, 118)
		local m = O.model(folder, "AbriVelos")
		P(
			m,
			"Toit",
			Vector3.new(24, 0.4, 6),
			cf * CFrame.new(0, 7, 0) * CFrame.Angles(math.rad(8), 0, 0),
			Enum.Material.Metal,
			C.metal
		)
		for _, x in { -11, 0, 11 } do
			P(
				m,
				"Poteau",
				Vector3.new(0.5, 7, 0.5),
				cf * CFrame.new(x, 3.5, -2.6),
				Enum.Material.Metal,
				C.metal
			)
		end
		for k = -4, 4 do
			if random:NextNumber() < 0.6 then
				P(
					m,
					"Velo",
					Vector3.new(0.3, 3, 5),
					cf
						* CFrame.new(k * 2.4, 1.6, 0)
						* CFrame.Angles(0, 0, math.rad(random:NextNumber(-10, 10))),
					Enum.Material.Metal,
					O.CAR_COLORS[(k % #O.CAR_COLORS) + 1]
				)
			end
		end
		V.tagBuilding(m, cf.Position.Y)
		K.claim(cf.Position.X, cf.Position.Z, 13)
	end
	for _ = 1, 22 do
		local x, z =
			random:NextNumber(zone.minX + 15, zone.maxX - 15),
			random:NextNumber(zone.minZ + 15, zone.maxZ - 15)
		if K.claim(x, z, 5) then
			local cf = CFrame.new(x, K.ground(x, z), z)
				* CFrame.Angles(0, random:NextNumber(0, 6), 0)
			local roll = random:NextNumber()
			if roll < 0.35 then
				K.anchor("Buisson", "fragile", cf)
			elseif roll < 0.55 then
				K.anchor(if random:NextNumber() < 0.5 then "Carton" else "Benne", "fragile", cf)
			elseif roll < 0.7 then
				K.anchor("Voiture", "moyenne", cf)
			else
				V.tree(folder, cf.Position, random:NextNumber() < 0.2)
			end
		end
	end

	local function measure(problems: { string })
		if classrooms < 4 then
			table.insert(problems, "Lycee : trop peu de salles de classe")
		end
		local roofY = mainCf.Position.Y + 36
		if roofY - K.ground(origin.X, origin.Z) < 30 then
			table.insert(problems, "Lycee : le batiment principal est trop bas")
		end
	end

	return {
		measure = measure,
		summary = string.format(
			"Lycee : batiment en L, gymnase, cour, terrain, %d salles a fouiller",
			classrooms
		),
	}
end
