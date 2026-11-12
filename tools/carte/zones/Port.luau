--!strict
--[[
	Le Port echoue — a l'ouest, sur la mer.

	Un quai de beton qui suit la vraie cote (on la cherche au rayon : elle
	ondule), avec ses bittes d'amarrage ; un cargo couche sur le flanc, a
	moitie echoue, dont la cale est une cachette solide ; des piles de
	conteneurs en labyrinthe (certains ouverts : on s'y enferme) ; deux
	grues portiques, dont une effondree ; des entrepots ; des pontons de bois
	et des barques echouees ; un phare au bout de la jetee nord.

	On marche un peu dans l'eau au pied du quai ; plus loin, c'est le large
	(choix de Josh : la mer est un bord).
]]

return function(K: any)
	local O, B = K.O, K.B
	local C, P = O.C, O.P
	local random: Random = K.random
	local folder = K.zoneFolder("PortEchoue")
	local concrete = Color3.fromRGB(132, 128, 120)

	local waterParams = RaycastParams.new()
	waterParams.FilterType = Enum.RaycastFilterType.Include
	waterParams.FilterDescendantsInstances = { workspace.Terrain }
	waterParams.IgnoreWater = false
	-- Ou commence l'eau sur cette ligne est-ouest.
	local function coastAt(z: number): number
		for x = -280, -1000, -3 do
			local hit =
				workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -400, 0), waterParams)
			if hit and hit.Material == Enum.Material.Water then
				return x
			end
		end
		return -720
	end

	-- LE QUAI : un ruban de beton le long de la cote, son mur plonge dans la
	-- mer, ses bittes d'amarrage.
	local quayY = 3
	local quay: { Vector3 } = {}
	for z = 30, 570, 18 do
		table.insert(quay, Vector3.new(coastAt(z) + 6, quayY, z))
	end
	do
		local m = O.model(folder, "Quai")
		for i = 1, #quay - 1 do
			local a, b = quay[i], quay[i + 1]
			local len = (b - a).Magnitude
			local cf = CFrame.lookAt((a + b) / 2, b)
			-- Le dessus du quai, de la cote vers la terre, et son mur.
			P(
				m,
				"Dalle",
				Vector3.new(34, 1.6, len + 0.4),
				cf * CFrame.new(-17, -0.8, 0),
				Enum.Material.Concrete,
				concrete
			)
			P(
				m,
				"MurDeQuai",
				Vector3.new(2, 16, len + 0.4),
				cf * CFrame.new(1, -8, 0),
				Enum.Material.Concrete,
				C.concreteDark
			)
			P(
				m,
				"Bordure",
				Vector3.new(1.2, 0.8, len + 0.4),
				cf * CFrame.new(0.4, 0.4, 0),
				Enum.Material.Concrete,
				C.concrete
			)
			if i % 3 == 0 then
				P(
					m,
					"Bitte",
					Vector3.new(1.4, 1.6, 1.4),
					cf * CFrame.new(-1.4, 0.8, 0),
					Enum.Material.Metal,
					C.black,
					{ shape = Enum.PartType.Cylinder }
				)
			end
			K.claim((a.X + b.X) / 2 + 17, (a.Z + b.Z) / 2, 18)
		end
		-- Le sol du port, de beton use, du quai jusqu'aux entrepots.
		for i = 1, #quay - 1, 2 do
			local a = quay[i]
			P(
				m,
				"Terreplein",
				Vector3.new(200, 1, 38),
				CFrame.new(a.X + 34 + 100, quayY - 0.6, a.Z + 9),
				Enum.Material.Concrete,
				concrete:Lerp(Color3.new(0, 0, 0), 0.08)
			)
		end
	end
	local function quayPoint(t: number, inland: number): CFrame
		local i = math.clamp(math.floor(t * (#quay - 1)) + 1, 1, #quay - 1)
		local a, b = quay[i], quay[i + 1]
		local cf = CFrame.lookAt(a, b)
		return cf * CFrame.new(-inland, 0, 0)
	end

	-- LE CARGO couche sur le flanc, a moitie dans l'eau, au milieu du port.
	do
		local m = O.model(folder, "Cargo")
		local base = quayPoint(0.5, -40)
		local hull = base * CFrame.new(0, 6, 0) * CFrame.Angles(0, math.rad(8), math.rad(-62))
		local red = Color3.fromRGB(96, 46, 40)
		local black = Color3.fromRGB(36, 36, 38)
		P(
			m,
			"Coque",
			Vector3.new(30, 26, 170),
			hull * CFrame.new(0, 13, 0),
			Enum.Material.Metal,
			black
		)
		P(
			m,
			"Carene",
			Vector3.new(30.4, 9, 170.4),
			hull * CFrame.new(0, 3, 0),
			Enum.Material.Metal,
			red
		)
		O.triangle(
			m,
			(hull * CFrame.new(-15, 0, 85)).Position,
			(hull * CFrame.new(15, 0, 85)).Position,
			(hull * CFrame.new(0, 0, 112)).Position,
			26,
			Enum.Material.Metal,
			black
		)
		P(
			m,
			"Chateau",
			Vector3.new(26, 22, 22),
			hull * CFrame.new(0, 37, -60),
			Enum.Material.Metal,
			Color3.fromRGB(180, 176, 166)
		)
		for k = 0, 4 do
			B.container(
				m,
				hull
					* CFrame.new(
						random:NextNumber(-8, 8),
						26 + random:NextNumber(0, 4),
						-30 + k * 22
					)
					* CFrame.Angles(0, random:NextNumber(-0.2, 0.2), 0),
				random:NextNumber() < 0.4
			)
		end
		-- Des conteneurs tombes du pont, eparpilles dans l'eau et sur le quai.
		for _ = 1, 6 do
			local cf = base
				* CFrame.new(random:NextNumber(-20, 40), -1, random:NextNumber(-90, 90))
				* CFrame.Angles(
					random:NextNumber(-0.3, 0.3),
					random:NextNumber(0, 6),
					random:NextNumber(-1.5, 1.5)
				)
			B.container(m, cf, false)
		end
		-- La cale, au pied de la coque, cote quai : une cachette solide.
		local spot = O.model(K.solid, "CaleDuCargo")
		local inside = (base * CFrame.new(18, 3, 0)).Position
		O.marker(spot, K.CONTRACT.inside, CFrame.new(inside.X, quayY + 2.5, inside.Z))
		O.marker(spot, K.CONTRACT.exit, CFrame.new(inside.X + 10, quayY + 3, inside.Z))
	end

	-- LES CONTENEURS sur le terre-plein : des piles en labyrinthe, de un a
	-- trois de haut. Quelques-uns ouverts : on s'y enferme (cachette solide).
	local opened = 0
	for row = 0, 11 do
		for col = 0, 5 do
			if random:NextNumber() < 0.7 then
				local t = 0.08 + row * 0.072
				local cf = quayPoint(t, 60 + col * 16) * CFrame.new(0, 0, random:NextNumber(-3, 3))
				local p = cf.Position
				if K.claim(p.X, p.Z, 11) then
					local height = random:NextInteger(1, 3)
					for level = 0, height - 1 do
						local open = level == 0 and random:NextNumber() < 0.4
						B.container(
							folder,
							CFrame.new(p.X, quayY + level * 8.8, p.Z)
								* (cf - cf.Position)
								* CFrame.Angles(0, random:NextNumber(-0.06, 0.06), 0),
							open
						)
						if open then
							opened += 1
							local spot = O.model(K.solid, "Conteneur" .. opened)
							O.marker(spot, K.CONTRACT.inside, CFrame.new(p.X, quayY + 3, p.Z))
							local out = (cf * CFrame.new(0, 0, 16)).Position
							O.marker(spot, K.CONTRACT.exit, CFrame.new(out.X, quayY + 3, out.Z))
						end
					end
				end
			end
		end
	end

	-- (Repere du quai : son X local pointe vers la mer, a l'ouest.)
	-- LES GRUES PORTIQUES : quatre jambes, une poutre, une fleche au-dessus
	-- de l'eau. La seconde s'est effondree en travers du quai.
	local function crane(cf: CFrame, collapsed: boolean)
		local m = O.model(folder, "Grue")
		local yellow = Color3.fromRGB(176, 140, 60)
		local tilt = if collapsed
			then CFrame.Angles(0, 0, math.rad(-72)) * CFrame.new(-6, 0, 0)
			else CFrame.identity
		local base = cf * tilt
		for _, sx in { -10, 10 } do
			for _, sz in { -8, 8 } do
				P(
					m,
					"Jambe",
					Vector3.new(2, 46, 2),
					base * CFrame.new(sx, 23, sz),
					Enum.Material.Metal,
					yellow
				)
			end
		end
		P(
			m,
			"Portique",
			Vector3.new(24, 4, 20),
			base * CFrame.new(0, 47, 0),
			Enum.Material.Metal,
			yellow
		)
		P(
			m,
			"Fleche",
			Vector3.new(80, 3, 4),
			base * CFrame.new(34, 50, 0),
			Enum.Material.Metal,
			yellow
		)
		P(
			m,
			"Cabine",
			Vector3.new(6, 5, 6),
			base * CFrame.new(4, 43, 0),
			Enum.Material.Metal,
			Color3.fromRGB(150, 150, 146)
		)
		P(
			m,
			"Cable",
			Vector3.new(0.2, 30, 0.2),
			base * CFrame.new(50, 34, 0),
			Enum.Material.Metal,
			C.black,
			{ collide = false }
		)
	end
	-- A 16 studs du bord : a 8, deux pieds depassaient au-dessus de l'eau
	-- (mesure : la grue flottait).
	crane(quayPoint(0.25, 16), false)
	crane(quayPoint(0.78, 16), true)

	-- LES ENTREPOTS, au fond du port.
	for i, t in { 0.2, 0.62 } do
		local cf = quayPoint(t, 150) * CFrame.Angles(0, math.rad(-90), 0)
		local p = cf.Position
		B.hangar(
			folder,
			CFrame.new(p.X, K.ground(p.X, p.Z), p.Z) * (cf - cf.Position),
			46,
			70,
			15,
			"Entrepot" .. i
		)
		K.claim(p.X, p.Z, 40)
		for _ = 1, 4 do
			K.crate(
				cf * CFrame.new(random:NextNumber(-16, 16), 0.6, random:NextNumber(10, 60)),
				"port"
			)
		end
	end

	-- LES PONTONS et les barques, au nord du cargo.
	for k = 0, 2 do
		local root = quayPoint(0.06 + k * 0.06, 0)
		local m = O.model(folder, "Ponton")
		local len = random:NextNumber(30, 46)
		P(
			m,
			"Platelage",
			Vector3.new(len, 0.6, 6),
			root * CFrame.new(len / 2, -1.2, 0),
			Enum.Material.WoodPlanks,
			C.woodGray
		)
		for x = 4, len, 8 do
			for _, sz in { -2.6, 2.6 } do
				P(
					m,
					"Pieu",
					Vector3.new(1, 10, 1),
					root * CFrame.new(x, -6, sz),
					Enum.Material.Wood,
					C.wood
				)
			end
		end
		-- Une barque echouee contre le ponton, couchee.
		local boat = root
			* CFrame.new(len * 0.6, -2.6, 7)
			* CFrame.Angles(
				0,
				math.rad(random:NextNumber(-20, 20)),
				math.rad(random:NextNumber(10, 30))
			)
		P(
			m,
			"Barque",
			Vector3.new(14, 2.4, 5),
			boat,
			Enum.Material.WoodPlanks,
			Color3.fromRGB(80, 96, 104)
		)
		P(
			m,
			"Proue",
			Vector3.new(3, 2.4, 3),
			boat * CFrame.new(8, 0, 0) * CFrame.Angles(0, math.rad(45), 0),
			Enum.Material.WoodPlanks,
			Color3.fromRGB(80, 96, 104)
		)
	end

	-- LE PHARE, au bout de la jetee nord : on le voit de loin.
	do
		local root = quayPoint(1, 0)
		local m = O.model(folder, "Phare")
		local jetty = root * CFrame.new(40, 0, -30)
		P(
			m,
			"Jetee",
			Vector3.new(8, 2, 70),
			root * CFrame.new(20, -1, -15) * CFrame.Angles(0, math.rad(60), 0),
			Enum.Material.Concrete,
			C.concreteDark
		)
		-- La jetee et le phare reposent sur des enrochements jusqu'au fond (sans
		-- eux, ils flottaient sur la mer, mesure le 12 novembre 2026).
		for t = 0, 4 do
			local foot = (
				root
				* CFrame.new(20, 0, -15)
				* CFrame.Angles(0, math.rad(60), 0)
				* CFrame.new(0, 0, -30 + t * 15)
			).Position
			P(
				m,
				"Enrochement",
				Vector3.new(10, 22, 10),
				CFrame.new(foot.X, -12, foot.Z) * CFrame.Angles(0, random:NextNumber(0, 6), 0),
				Enum.Material.Rock,
				Color3.fromRGB(86, 84, 80)
			)
		end
		do
			local base = jetty.Position
			P(
				m,
				"SocleDuPhare",
				Vector3.new(14, 24, 14),
				CFrame.new(base.X, -11, base.Z),
				Enum.Material.Rock,
				Color3.fromRGB(86, 84, 80)
			)
		end
		for k = 0, 5 do
			P(
				m,
				"Tour",
				Vector3.new(5, 7 - k * 0.5, 7 - k * 0.5),
				jetty * CFrame.new(0, 2.5 + k * 5, 0) * CFrame.Angles(0, 0, math.rad(90)),
				Enum.Material.Plaster,
				if k % 2 == 0 then C.trim else Color3.fromRGB(150, 70, 62),
				{ shape = Enum.PartType.Cylinder }
			)
		end
		P(
			m,
			"Lanterne",
			Vector3.new(4, 4, 4),
			jetty * CFrame.new(0, 33, 0),
			Enum.Material.Glass,
			C.glass,
			{ transparency = 0.3 }
		)
		P(
			m,
			"Coiffe",
			Vector3.new(5, 2, 5),
			jetty * CFrame.new(0, 36, 0),
			Enum.Material.Metal,
			C.black
		)
	end

	-- Des cachettes fragiles et des caisses partout sur le terre-plein.
	for _ = 1, 16 do
		local cf = quayPoint(random:NextNumber(0.05, 0.95), random:NextNumber(30, 140))
		local p = cf.Position
		if K.claim(p.X, p.Z, 5) then
			local roll = random:NextNumber()
			local base = CFrame.new(p.X, K.ground(p.X, p.Z), p.Z)
				* CFrame.Angles(0, random:NextNumber(0, 6), 0)
			if roll < 0.4 then
				K.anchor("Caisses", "fragile", base)
			elseif roll < 0.7 then
				K.anchor("Benne", "fragile", base)
			else
				K.crate(base, "port")
			end
		end
	end

	-- Le sol du port cote terre : des dalles de beton, comme le terre-plein.
	-- Sur la pelouse, le chantier et les camions semblaient poses dans un
	-- pre (vu a l'ecran le 12 novembre 2026).
	do
		local region = Region3.new(Vector3.new(-560, -20, 16), Vector3.new(-292, 80, 596))
			:ExpandToGrid(4)
		for _, from in
			{
				Enum.Material.Grass,
				Enum.Material.LeafyGrass,
				Enum.Material.Ground,
				Enum.Material.Sand,
			}
		do
			workspace.Terrain:ReplaceMaterial(region, 4, from, Enum.Material.Pavement)
		end
	end
	-- LE PORT COTE TERRE : sa moitie est restait vide (mesure le 12 novembre
	-- 2026). La capitainerie, un chantier naval avec une coque sur ses
	-- tins, un parking de camions, des bureaux, des citernes.
	local function land(x: number, z: number): Vector3
		return Vector3.new(x, K.ground(x, z), z)
	end
	do
		-- La capitainerie : un batiment de trois etages et sa tour de guet.
		local base = land(-420, 470)
		local cf = CFrame.lookAt(base, base + Vector3.new(-1, 0, 0))
		B.building(folder, cf, {
			name = "Capitainerie",
			w = 34,
			d = 20,
			floors = 3,
			floorH = 11,
			material = Enum.Material.Plaster,
			color = Color3.fromRGB(190, 184, 170),
			roof = "plat",
			windowEvery = 6,
			doors = 1,
		})
		P(
			folder,
			"TourDeGuet",
			Vector3.new(10, 10, 10),
			cf * CFrame.new(10, 38, 10),
			Enum.Material.Glass,
			C.glass,
			{ transparency = 0.35 }
		)
		P(
			folder,
			"ToitTour",
			Vector3.new(12, 1, 12),
			cf * CFrame.new(10, 43.5, 10),
			Enum.Material.Metal,
			C.black
		)
		for f = 0, 2 do
			local desk = P(
				K.containers,
				"Bureau",
				Vector3.new(5, 3, 2.6),
				cf * CFrame.new(random:NextNumber(-10, 10), f * 11 + 2.4, random:NextNumber(5, 15)),
				Enum.Material.WoodPlanks,
				C.wood
			)
			desk:SetAttribute("Table", "bureau")
		end
		K.anchor(
			"Armoire",
			"moyenne",
			cf * CFrame.new(-14, 0.8, 16) * CFrame.Angles(0, math.rad(90), 0)
		)
		K.claim(base.X + 10, base.Z, 26)
	end
	do
		-- Le chantier naval : une cale seche, une coque de chalutier sur ses
		-- tins, des echafaudages.
		local base = land(-430, 180)
		local cf = CFrame.lookAt(base, base + Vector3.new(-1, 0, 0))
		local m = O.model(folder, "ChantierNaval")
		P(
			m,
			"Cale",
			Vector3.new(30, 1, 70),
			cf * CFrame.new(0, 0.4, 0),
			Enum.Material.Concrete,
			C.concreteDark
		)
		local hull = cf * CFrame.new(0, 7, 0)
		local blue = Color3.fromRGB(60, 84, 100)
		P(m, "Coque", Vector3.new(14, 10, 50), hull, Enum.Material.Metal, blue)
		P(
			m,
			"Quille",
			Vector3.new(4, 4, 46),
			hull * CFrame.new(0, -6, 0),
			Enum.Material.Metal,
			Color3.fromRGB(96, 46, 40)
		)
		O.triangle(
			m,
			(hull * CFrame.new(-7, 5, -25)).Position,
			(hull * CFrame.new(7, 5, -25)).Position,
			(hull * CFrame.new(0, 5, -36)).Position,
			10,
			Enum.Material.Metal,
			blue
		)
		P(
			m,
			"Timonerie",
			Vector3.new(10, 7, 10),
			hull * CFrame.new(0, 8.5, 12),
			Enum.Material.Plaster,
			C.trim
		)
		for z = -20, 20, 10 do
			for _, sx in { -5, 5 } do
				P(
					m,
					"Tin",
					Vector3.new(2, 3, 2),
					cf * CFrame.new(sx, 1.5, z),
					Enum.Material.Wood,
					C.wood
				)
			end
		end
		for z = -24, 24, 12 do
			P(
				m,
				"Echafaudage",
				Vector3.new(0.4, 16, 0.4),
				cf * CFrame.new(10, 8, z),
				Enum.Material.Metal,
				C.metal
			)
			P(
				m,
				"Plancher",
				Vector3.new(3, 0.3, 12),
				cf * CFrame.new(11, 10, z + 6),
				Enum.Material.WoodPlanks,
				C.woodGray
			)
		end
		-- Sous la coque, entre les tins : une cachette solide.
		local spot = O.model(K.solid, "SousLaCoque")
		O.marker(spot, K.CONTRACT.inside, cf * CFrame.new(0, 1.5, 0))
		O.marker(spot, K.CONTRACT.exit, cf * CFrame.new(12, 3, 0))
		K.claim(base.X, base.Z, 38)
	end
	do
		-- Le parking des camions : des semi-remorques alignees, cabines
		-- ouvertes (cachettes solides).
		for k = 0, 4 do
			local base = land(-345, 300 + k * 20)
			if K.claim(base.X, base.Z, 10) then
				local cf = CFrame.lookAt(base, base + Vector3.new(-1, 0, 0.1))
				P(
					folder,
					"Remorque",
					Vector3.new(8.6, 10, 34),
					cf * CFrame.new(0, 6.5, 6),
					Enum.Material.Metal,
					Color3.fromRGB(176 - k * 8, 172 - k * 6, 160)
				)
				P(
					folder,
					"Cabine",
					Vector3.new(8.6, 8, 8),
					cf * CFrame.new(0, 5, -16),
					Enum.Material.Metal,
					O.CAR_COLORS[(k % #O.CAR_COLORS) + 1]
				)
				if k % 2 == 0 then
					local spot = O.model(K.solid, "CamionPort" .. k)
					O.marker(spot, K.CONTRACT.inside, cf * CFrame.new(0, 4, -16))
					O.marker(spot, K.CONTRACT.exit, cf * CFrame.new(6, 3, -16))
				end
			end
		end
	end
	do
		-- Deux citernes de carburant, rouillees, et leur muret.
		for k = 0, 1 do
			local base = land(-360, 80 + k * 34)
			if K.claim(base.X, base.Z, 16) then
				P(
					folder,
					"Citerne",
					Vector3.new(18, 26, 26),
					CFrame.new(base + Vector3.new(0, 9, 0)) * CFrame.Angles(0, 0, math.rad(90)),
					Enum.Material.Metal,
					Color3.fromRGB(118, 114, 106),
					{ shape = Enum.PartType.Cylinder }
				)
				K.anchor("Tole", "fragile", CFrame.new(base + Vector3.new(16, 0, 0)))
			end
		end
	end
	-- Des cachettes et des caisses partout cote terre.
	for _ = 1, 30 do
		local x, z = random:NextNumber(-520, -290), random:NextNumber(30, 590)
		if K.claim(x, z, 5) then
			local cf = CFrame.new(land(x, z)) * CFrame.Angles(0, random:NextNumber(0, 6), 0)
			local roll = random:NextNumber()
			if roll < 0.3 then
				K.anchor("Caisses", "fragile", cf)
			elseif roll < 0.5 then
				K.anchor("Voiture", "moyenne", cf)
			elseif roll < 0.7 then
				K.anchor(if random:NextNumber() < 0.5 then "Benne" else "Buisson", "fragile", cf)
			else
				K.crate(cf, "port")
			end
		end
	end

	local function measure(problems: { string })
		if #quay < 20 then
			table.insert(problems, "Port : le quai est trop court")
		end
		if opened < 3 then
			table.insert(
				problems,
				string.format("Port : %d conteneur(s) ouvert(s) seulement", opened)
			)
		end
	end

	return {
		measure = measure,
		summary = string.format(
			"Port : quai de %d troncons, cargo couche, %d conteneurs ouverts, 2 grues, phare",
			#quay,
			opened
		),
	}
end
