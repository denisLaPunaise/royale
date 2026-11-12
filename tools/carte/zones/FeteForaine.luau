--!strict
--[[
	La Fete foraine — au nord-est, en haut de la pente : une foire figee le
	jour ou le ciel s'est fendu.

	La grande roue penchee (on la voit de toute la carte : c'est un repere),
	des montagnes russes tordues dont un troncon pend dans le vide, un
	manege, des autos tamponneuses, des stands aux bannes delavees le long
	d'une allee qui serpente, des caravanes de forains, des guirlandes
	eteintes. Le train fantome est sa cachette propre : un tunnel noir, solide.
]]

local ALLEY_WIDTH = 10

return function(K: any)
	local O, V, B = K.O, K.V, K.B
	local C, P = O.C, O.P
	local random: Random = K.random
	local folder = K.zoneFolder("FeteForaine")
	local faded = {
		Color3.fromRGB(150, 70, 62),
		Color3.fromRGB(196, 176, 120),
		Color3.fromRGB(80, 104, 130),
		Color3.fromRGB(196, 190, 176),
		Color3.fromRGB(96, 128, 98),
	}
	local function g(x: number, z: number): Vector3
		return Vector3.new(x, K.ground(x, z), z)
	end

	-- Le sol de la foire : de la terre battue et du gravier, pas une
	-- pelouse (vu a l'ecran : la foire semblait posee dans un pre).
	do
		local region = Region3.new(Vector3.new(268, -20, 372), Vector3.new(752, 120, 752))
			:ExpandToGrid(4)
		workspace.Terrain:ReplaceMaterial(region, 4, Enum.Material.Grass, Enum.Material.Ground)
		workspace.Terrain:ReplaceMaterial(region, 4, Enum.Material.LeafyGrass, Enum.Material.Pebble)
	end

	-- L'allee qui serpente de l'entree au fond de la foire.
	local alley = K.spline({
		Vector2.new(252, 500),
		Vector2.new(330, 470),
		Vector2.new(420, 520),
		Vector2.new(480, 600),
		Vector2.new(560, 560),
		Vector2.new(660, 520),
		Vector2.new(700, 600),
		Vector2.new(640, 700),
		Vector2.new(470, 700),
		Vector2.new(360, 650),
	}, 12)
	K.road(folder, alley, ALLEY_WIDTH, false)

	-- L'entree : deux piliers, une arche, une enseigne.
	do
		local m = O.model(folder, "Entree")
		local base = g(262, 492)
		local cf = CFrame.lookAt(base, base + Vector3.new(1, 0, -0.35))
		for _, sx in { -1, 1 } do
			P(
				m,
				"Pilier",
				Vector3.new(2, 16, 2),
				cf * CFrame.new(sx * 8, 8, 0),
				Enum.Material.Metal,
				faded[2]
			)
		end
		P(
			m,
			"Arche",
			Vector3.new(19, 3, 1.2),
			cf * CFrame.new(0, 16.5, 0),
			Enum.Material.Metal,
			faded[1]
		)
		local sign = P(
			m,
			"Enseigne",
			Vector3.new(16, 2.6, 0.4),
			cf * CFrame.new(0, 16.5, -0.8),
			Enum.Material.SmoothPlastic,
			faded[4]
		)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.Fantasy
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(110, 40, 36)
		text.Text = "LA GRANDE FOIRE"
		text.Parent = gui
		gui.Parent = sign
	end

	-- LA GRANDE ROUE, penchee : le repere de tout le nord.
	local wheelHub: Vector3
	do
		local m = O.model(folder, "GrandeRoue")
		local foot = g(600, 640)
		local radius = 42
		local hub = foot + Vector3.new(0, radius + 8, 0)
		wheelHub = hub
		-- Elle penche de 14 degres sur le cote : un pied a cede.
		local frame = CFrame.new(hub)
			* CFrame.Angles(0, math.rad(35), 0)
			-- Penchee vers l'avant : un pied a cede. (Tourner autour de l'axe
			-- de la roue ne se voyait pas, vu a l'ecran.)
			* CFrame.Angles(math.rad(12), 0, 0)
		local segments = 40
		local function rim(i: number, offset: number): Vector3
			local a = (i / segments) * math.pi * 2
			return (frame * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, offset)).Position
		end
		for _, offset in { -3, 3 } do
			for i = 0, segments - 1 do
				local a, b = rim(i, offset), rim(i + 1, offset)
				P(
					m,
					"Jante",
					Vector3.new(0.8, 0.8, (b - a).Magnitude + 0.3),
					CFrame.lookAt((a + b) / 2, b),
					Enum.Material.Metal,
					faded[4]
				)
			end
		end
		for i = 0, segments - 1, 2 do
			for _, offset in { -3, 3 } do
				local a, b = (frame * CFrame.new(0, 0, offset)).Position, rim(i, offset)
				P(
					m,
					"Rayon",
					Vector3.new(0.35, 0.35, (b - a).Magnitude),
					CFrame.lookAt((a + b) / 2, b),
					Enum.Material.Metal,
					faded[4]
				)
			end
		end
		P(
			m,
			"Moyeu",
			Vector3.new(8, 4, 4),
			frame * CFrame.Angles(0, math.rad(90), 0),
			Enum.Material.Metal,
			faded[1],
			{ shape = Enum.PartType.Cylinder }
		)
		-- Les pieds en A, de chaque cote.
		for _, offset in { -7, 7 } do
			for _, spread in { -18, 18 } do
				local top = (frame * CFrame.new(0, 0, offset)).Position
				local bottom = (CFrame.new(foot) * CFrame.Angles(0, math.rad(35), 0) * CFrame.new(
					spread,
					0,
					offset * 1.6
				)).Position
				P(
					m,
					"Pied",
					Vector3.new(1.4, 1.4, (top - bottom).Magnitude),
					CFrame.lookAt((top + bottom) / 2, top),
					Enum.Material.Metal,
					faded[3]
				)
			end
		end
		-- Les nacelles, qui pendent toujours droites ; il en manque.
		for i = 0, segments - 1, 4 do
			if random:NextNumber() > 0.2 then
				local at = rim(i, 0) - Vector3.new(0, 4.5, 0)
				P(
					m,
					"Nacelle",
					Vector3.new(5, 4.4, 5),
					CFrame.new(at) * CFrame.Angles(0, math.rad(35), 0),
					Enum.Material.Metal,
					faded[random:NextInteger(1, #faded)]
				)
				P(
					m,
					"ToitNacelle",
					Vector3.new(6, 0.5, 6),
					CFrame.new(at + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, math.rad(35), 0),
					Enum.Material.Metal,
					faded[2]
				)
			end
		end
		-- Une nacelle tombee au pied.
		P(
			m,
			"NacelleTombee",
			Vector3.new(5, 4.4, 5),
			CFrame.new(foot + Vector3.new(14, 1.6, 6))
				* CFrame.Angles(math.rad(70), math.rad(20), 0),
			Enum.Material.Metal,
			faded[1]
		)
		K.claim(foot.X, foot.Z, 30)
	end

	-- LES MONTAGNES RUSSES : une voie qui monte, plonge, tourne, et dont un
	-- troncon s'est decroche.
	local coaster = 0
	do
		local m = O.model(folder, "MontagnesRusses")
		local path = {
			{ 450, 740, 6 },
			{ 520, 745, 30 },
			{ 590, 735, 44 },
			{ 650, 742, 16 },
			{ 720, 720, 28 },
			{ 735, 660, 12 },
			{ 715, 600, 30 },
			{ 690, 560, 10 },
			{ 640, 555, 22 },
		}
		local pts = {}
		for _, p in path do
			table.insert(pts, Vector3.new(p[1], K.ground(p[1], p[2]) + p[3], p[2]))
		end
		-- Une courbe dans l'espace : on lisse x, z et la hauteur.
		local flat = {}
		for _, p in pts do
			table.insert(flat, Vector2.new(p.X, p.Z))
		end
		local curve = K.spline(flat, 6)
		local heights = {}
		for i = 1, #curve do
			local t = (i - 1) / (#curve - 1) * (#pts - 1)
			local k = math.floor(t)
			local f = t - k
			local h0 = path[math.clamp(k + 1, 1, #path)][3]
			local h1 = path[math.clamp(k + 2, 1, #path)][3]
			local smooth = f * f * (3 - 2 * f)
			heights[i] = h0 + (h1 - h0) * smooth
		end
		local brokenAt = math.floor(#curve * 0.55)
		for i = 1, #curve - 1 do
			local a =
				Vector3.new(curve[i].X, K.ground(curve[i].X, curve[i].Y) + heights[i], curve[i].Y)
			local b = Vector3.new(
				curve[i + 1].X,
				K.ground(curve[i + 1].X, curve[i + 1].Y) + heights[i + 1],
				curve[i + 1].Y
			)
			if i == brokenAt or i == brokenAt + 1 then
				-- Le troncon decroche : il pend d'un bout, l'autre au sol.
				if i == brokenAt then
					local hang = Vector3.new(b.X, K.ground(b.X, b.Z) + 1, b.Z)
					P(
						m,
						"TronconTombe",
						Vector3.new(4, 0.6, (hang - a).Magnitude),
						CFrame.lookAt((a + hang) / 2, hang),
						Enum.Material.Metal,
						faded[1]
					)
				end
				continue
			end
			local cf = CFrame.lookAt((a + b) / 2, b)
			local len = (b - a).Magnitude
			for _, sx in { -1.6, 1.6 } do
				P(
					m,
					"Rail",
					Vector3.new(0.5, 0.5, len + 0.2),
					cf * CFrame.new(sx, 0, 0),
					Enum.Material.Metal,
					faded[1]
				)
			end
			P(m, "Traverse", Vector3.new(4, 0.4, 0.8), cf, Enum.Material.Metal, faded[4])
			coaster += 1
			-- Une pile tous les quelques troncons.
			if i % 4 == 0 then
				local floorY = K.ground(a.X, a.Z)
				P(
					m,
					"Pile",
					Vector3.new(1, a.Y - floorY, 1),
					CFrame.new(a.X, (a.Y + floorY) / 2, a.Z),
					Enum.Material.Metal,
					faded[3]
				)
			end
		end
		for _, p in flat do
			K.claim(p.X, p.Y, 6)
		end
	end

	-- LE MANEGE : un plateau rond, des chevaux sur leurs barres, un toit en
	-- pointe a rayures delavees.
	do
		local m = O.model(folder, "Manege")
		local c = g(420, 455)
		local r = 14
		P(
			m,
			"Plateau",
			Vector3.new(1.2, r * 2, r * 2),
			CFrame.new(c + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.WoodPlanks,
			faded[4],
			{ shape = Enum.PartType.Cylinder }
		)
		P(
			m,
			"Mat",
			Vector3.new(14, 2, 2),
			CFrame.new(c + Vector3.new(0, 7.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.Metal,
			faded[2],
			{ shape = Enum.PartType.Cylinder }
		)
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			local rimA = c + Vector3.new(math.cos(a) * (r + 1), 13, math.sin(a) * (r + 1))
			local rimB = c
				+ Vector3.new(
					math.cos(a + math.pi / 6) * (r + 1),
					13,
					math.sin(a + math.pi / 6) * (r + 1)
				)
			O.triangle(
				m,
				rimA,
				rimB,
				c + Vector3.new(0, 19, 0),
				0.4,
				Enum.Material.Fabric,
				if i % 2 == 0 then faded[1] else faded[4]
			)
		end
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			local at = c + Vector3.new(math.cos(a) * 10, 0, math.sin(a) * 10)
			P(
				m,
				"Barre",
				Vector3.new(0.3, 12, 0.3),
				CFrame.new(at + Vector3.new(0, 6.6, 0)),
				Enum.Material.Metal,
				faded[2]
			)
			local face = CFrame.new(at + Vector3.new(0, 4, 0)) * CFrame.Angles(0, -a, 0)
			P(m, "Cheval", Vector3.new(1.4, 1.8, 4), face, Enum.Material.SmoothPlastic, faded[4])
			P(
				m,
				"Tete",
				Vector3.new(1.2, 2, 1.4),
				face * CFrame.new(0, 1.2, -2.1) * CFrame.Angles(math.rad(-25), 0, 0),
				Enum.Material.SmoothPlastic,
				faded[4]
			)
		end
		K.claim(c.X, c.Z, r + 4)
	end

	-- LES AUTOS TAMPONNEUSES : une piste, une barriere, des voitures arretees
	-- en vrac.
	do
		local m = O.model(folder, "AutosTamponneuses")
		local c = g(560, 470)
		local cf = CFrame.new(c) * CFrame.Angles(0, math.rad(15), 0)
		P(
			m,
			"Piste",
			Vector3.new(34, 1, 22),
			cf * CFrame.new(0, 0.5, 0),
			Enum.Material.Metal,
			Color3.fromRGB(60, 62, 66)
		)
		for _, s in { { 0, 11, 34, 0 }, { 0, -11, 34, 0 }, { 17, 0, 22, 1 }, { -17, 0, 22, 1 } } do
			P(
				m,
				"Barriere",
				Vector3.new(s[3], 1.6, 0.8),
				cf
					* CFrame.new(s[1], 1.6, s[2])
					* CFrame.Angles(0, if s[4] == 1 then math.rad(90) else 0, 0),
				Enum.Material.Rubber,
				C.black
			)
		end
		for _ = 1, 7 do
			local car = cf
				* CFrame.new(random:NextNumber(-14, 14), 1.6, random:NextNumber(-8, 8))
				* CFrame.Angles(0, random:NextNumber(0, 6), 0)
			P(
				m,
				"Auto",
				Vector3.new(3.6, 1.6, 5),
				car,
				Enum.Material.SmoothPlastic,
				faded[random:NextInteger(1, #faded)]
			)
			P(
				m,
				"Perche",
				Vector3.new(0.2, 8, 0.2),
				car * CFrame.new(0, 4.5, 1.8),
				Enum.Material.Metal,
				faded[4]
			)
		end
		P(
			m,
			"Toit",
			Vector3.new(36, 0.6, 24),
			cf * CFrame.new(0, 10, 0),
			Enum.Material.Metal,
			faded[3]
		)
		for _, cx in { -16, 16 } do
			for _, cz in { -10, 10 } do
				P(
					m,
					"Poteau",
					Vector3.new(0.8, 9.5, 0.8),
					cf * CFrame.new(cx, 5.2, cz),
					Enum.Material.Metal,
					faded[2]
				)
			end
		end
		V.tagBuilding(m, c.Y)
		K.claim(c.X, c.Z, 20)
	end

	-- LE TRAIN FANTOME : un batiment noir, une facade peinte, et dedans un
	-- tunnel ou l'on se cache (cachette solide).
	do
		local base = g(330, 640)
		local cf = CFrame.lookAt(base, base + Vector3.new(0.3, 0, -1))
		local m = B.building(folder, cf, {
			name = "TrainFantome",
			w = 36,
			d = 26,
			floors = 1,
			floorH = 15,
			material = Enum.Material.WoodPlanks,
			color = Color3.fromRGB(40, 36, 44),
			roof = "plat",
			windowEvery = 40,
			doors = 1,
		})
		-- Deux grands yeux peints au-dessus de la porte, d'un violet eteint.
		for _, sx in { -7, 7 } do
			P(
				m,
				"OeilPeint",
				Vector3.new(5, 3, 0.2),
				cf * CFrame.new(sx, 11, -0.7),
				Enum.Material.SmoothPlastic,
				Color3.fromRGB(120, 96, 140)
			)
		end
		B.rails(m, (cf * CFrame.new(-12, 0.6, 4)).Position, (cf * CFrame.new(12, 0.6, 22)).Position)
		local spot = O.model(K.solid, "TrainFantome")
		O.marker(spot, K.CONTRACT.inside, cf * CFrame.new(0, 3, 14))
		O.marker(spot, K.CONTRACT.exit, cf * CFrame.new(0, 3, -3))
		K.claim(base.X, base.Z + 12, 24)
	end

	-- LES STANDS le long de l'allee : un comptoir, une banne a rayures, une
	-- caisse a fouiller derriere.
	local stands = 0
	for i = 4, #alley - 1, 3 do
		local a, b = alley[i], alley[i + 1]
		local dir = (b - a).Unit
		local side = if i % 2 == 0 then 1 else -1
		local normal = Vector2.new(-dir.Y, dir.X) * side
		local p = a + normal * (ALLEY_WIDTH / 2 + 6)
		if K.isFree(p.X, p.Y, 5) then
			K.claim(p.X, p.Y, 5)
			local base = g(p.X, p.Y)
			local cf = CFrame.lookAt(base, base - Vector3.new(normal.X, 0, normal.Y))
			local m = O.model(folder, "Stand")
			local color = faded[random:NextInteger(1, #faded)]
			P(
				m,
				"Comptoir",
				Vector3.new(8, 3.4, 1.4),
				cf * CFrame.new(0, 1.7, 0),
				Enum.Material.WoodPlanks,
				color
			)
			P(
				m,
				"Fond",
				Vector3.new(8, 8, 0.4),
				cf * CFrame.new(0, 4, 5),
				Enum.Material.WoodPlanks,
				color:Lerp(Color3.new(0, 0, 0), 0.2)
			)
			for _, sx in { -4, 4 } do
				P(
					m,
					"Montant",
					Vector3.new(0.4, 8, 0.4),
					cf * CFrame.new(sx, 4, 0),
					Enum.Material.Wood,
					C.wood
				)
				P(
					m,
					"Cote",
					Vector3.new(0.4, 8, 5),
					cf * CFrame.new(sx, 4, 2.5),
					Enum.Material.WoodPlanks,
					color
				)
			end
			for k = -3, 3 do
				P(
					m,
					"Banne",
					Vector3.new(1.15, 0.2, 4),
					cf * CFrame.new(k * 1.15, 8.4, -1) * CFrame.Angles(math.rad(-18), 0, 0),
					Enum.Material.Fabric,
					if k % 2 == 0 then faded[4] else color
				)
			end
			V.tagBuilding(m, base.Y)
			K.crate(cf * CFrame.new(0, 0, 3), "foire")
			stands += 1
		end
	end

	-- Des caravanes de forains au bord de la foire, et leurs cachettes.
	for _, p in
		{
			Vector2.new(720, 400),
			Vector2.new(690, 380),
			Vector2.new(300, 720),
			Vector2.new(745, 470),
		}
	do
		if K.claim(p.X, p.Y, 9) then
			local base = g(p.X, p.Y)
			local cf = CFrame.new(base) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
			local m = O.model(folder, "Caravane")
			P(
				m,
				"Caisse",
				Vector3.new(7, 7, 16),
				cf * CFrame.new(0, 4.4, 0),
				Enum.Material.SmoothPlastic,
				faded[4]
			)
			P(
				m,
				"Bande",
				Vector3.new(7.1, 1, 16.1),
				cf * CFrame.new(0, 4, 0),
				Enum.Material.SmoothPlastic,
				faded[random:NextInteger(1, 3)]
			)
			P(
				m,
				"Fenetre",
				Vector3.new(7.2, 1.6, 4),
				cf * CFrame.new(0, 5.6, -3),
				Enum.Material.Glass,
				C.glass,
				{ transparency = 0.4 }
			)
			for _, z in { -4, 4 } do
				P(
					m,
					"Roue",
					Vector3.new(0.8, 2, 2),
					cf * CFrame.new(3.6, 1, z),
					Enum.Material.Rubber,
					C.black,
					{ shape = Enum.PartType.Cylinder }
				)
			end
			K.anchor("Caisses", "fragile", cf * CFrame.new(7, 0, 0))
		end
	end

	-- Les guirlandes eteintes, de lampadaire en lampadaire le long de l'allee.
	local posts: { Vector3 } = {}
	for i = 2, #alley, 4 do
		local a = alley[i]
		local b = alley[math.min(i + 1, #alley)]
		local dir = (b - a).Unit
		local p = a + Vector2.new(-dir.Y, dir.X) * (ALLEY_WIDTH / 2 + 1)
		local base = g(p.X, p.Y)
		P(
			folder,
			"PoteauGuirlande",
			Vector3.new(0.5, 10, 0.5),
			CFrame.new(base + Vector3.new(0, 5, 0)),
			Enum.Material.Metal,
			faded[2]
		)
		table.insert(posts, base + Vector3.new(0, 9.6, 0))
	end
	for i = 1, #posts - 1 do
		local a, b = posts[i], posts[i + 1]
		local mid = (a + b) / 2 - Vector3.new(0, 2, 0)
		for _, pair in { { a, mid }, { mid, b } } do
			P(
				folder,
				"Fil",
				Vector3.new(0.1, 0.1, (pair[2] - pair[1]).Magnitude),
				CFrame.lookAt((pair[1] + pair[2]) / 2, pair[2]),
				Enum.Material.SmoothPlastic,
				C.black,
				{ collide = false, query = false }
			)
			for k = 1, 3 do
				local at = pair[1]:Lerp(pair[2], k / 4)
				P(
					folder,
					"Ampoule",
					Vector3.new(0.5, 0.5, 0.5),
					CFrame.new(at - Vector3.new(0, 0.3, 0)),
					Enum.Material.Glass,
					faded[(k % #faded) + 1],
					{ shape = Enum.PartType.Ball, collide = false, query = false, shadow = false }
				)
			end
		end
	end

	-- Des bennes, des buissons et des arbres au bord.
	for _ = 1, 12 do
		local x, z = random:NextNumber(270, 750), random:NextNumber(370, 750)
		if K.claim(x, z, 6) then
			K.anchor(
				if random:NextNumber() < 0.5 then "Buisson" else "Benne",
				"fragile",
				CFrame.new(g(x, z)) * CFrame.Angles(0, random:NextNumber(0, 6), 0)
			)
		end
	end
	for _ = 1, 16 do
		local x, z = random:NextNumber(260, 760), random:NextNumber(360, 760)
		if K.claim(x, z, 7) then
			V.tree(folder, g(x, z), random:NextNumber() < 0.25)
		end
	end

	-- PLUS DENSE : la foire avait de grands vides (vu a l'ecran le 12
	-- novembre 2026). Un chapiteau de cirque (un second repere, a rayures
	-- delavees), un palais des glaces, des camions-buvettes, des bancs, des
	-- poubelles renversees, des papiers par terre.
	do
		-- Le chapiteau : un mat, une toile en cone a rayures, une jupe.
		local c = g(470, 660)
		local m = O.model(folder, "Chapiteau")
		local r, skirt, peak = 26, 9, 26
		local n = 18
		for i = 0, n - 1 do
			local a0, a1 = i / n * math.pi * 2, (i + 1) / n * math.pi * 2
			local p0 = c + Vector3.new(math.cos(a0) * r, skirt, math.sin(a0) * r)
			local p1 = c + Vector3.new(math.cos(a1) * r, skirt, math.sin(a1) * r)
			local color = if i % 2 == 0 then faded[1] else faded[4]
			O.triangle(m, p0, p1, c + Vector3.new(0, peak, 0), 0.4, Enum.Material.Fabric, color)
			-- La jupe : un pan vertical ; il en manque un (l'entree, dechiree).
			if i ~= 0 then
				local mid = (p0 + p1) / 2 - Vector3.new(0, skirt / 2, 0)
				P(
					m,
					"Jupe",
					Vector3.new((p1 - p0).Magnitude + 0.2, skirt, 0.3),
					-- Face au dehors : sa longueur suit le tour du chapiteau (tournee
					-- de 90 degres, elle ressortait en ailette).
					CFrame.lookAt(mid, mid + (mid - c) * Vector3.new(1, 0, 1)),
					Enum.Material.Fabric,
					color
				)
			end
		end
		P(
			m,
			"Mat",
			Vector3.new(0.8, peak + 6, 0.8),
			CFrame.new(c + Vector3.new(0, (peak + 6) / 2, 0)),
			Enum.Material.Metal,
			faded[2]
		)
		P(
			m,
			"Fanion",
			Vector3.new(0.1, 2, 3),
			CFrame.new(c + Vector3.new(1.5, peak + 5, 0)),
			Enum.Material.Fabric,
			faded[1]
		)
		P(
			m,
			"Piste",
			Vector3.new(1, 16, 16),
			CFrame.new(c + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.Sand,
			faded[2],
			{ shape = Enum.PartType.Cylinder }
		)
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			P(
				m,
				"Gradin",
				Vector3.new(10, 1.2 + (k % 2), 3),
				CFrame.new(c + Vector3.new(math.cos(a) * 16, 1, math.sin(a) * 16))
					* CFrame.Angles(0, -a + math.pi / 2, 0),
				Enum.Material.WoodPlanks,
				C.wood
			)
		end
		V.tagBuilding(m, c.Y)
		local spot = O.model(K.solid, "SousLesGradins")
		O.marker(spot, K.CONTRACT.inside, CFrame.new(c + Vector3.new(16, 1.5, 0)))
		O.marker(spot, K.CONTRACT.exit, CFrame.new(c + Vector3.new(0, 3, -r - 4)))
		K.crate(CFrame.new(c + Vector3.new(-6, 0, 6)), "foire")
		K.claim(c.X, c.Z, r + 3)
	end
	do
		-- Le palais des glaces : un petit batiment aux vitres, un labyrinthe.
		local base = g(630, 420)
		local cf = CFrame.lookAt(base, base + Vector3.new(-1, 0, 0.2))
		if K.claim(base.X, base.Z, 16) then
			local m = B.building(folder, cf, {
				name = "PalaisDesGlaces",
				w = 24,
				d = 20,
				floors = 1,
				floorH = 11,
				material = Enum.Material.SmoothPlastic,
				color = faded[3],
				roof = "plat",
				windowEvery = 5,
				doors = 1,
			})
			for _ = 1, 8 do
				P(
					m,
					"Miroir",
					Vector3.new(0.3, 8, 5),
					cf
						* CFrame.new(random:NextNumber(-9, 9), 4.6, random:NextNumber(4, 17))
						* CFrame.Angles(0, random:NextInteger(0, 3) * math.pi / 2, 0),
					Enum.Material.Glass,
					Color3.fromRGB(190, 200, 205),
					{ transparency = 0.2 }
				)
			end
		end
	end
	-- Les camions-buvettes, le long de l'allee.
	for _, p in { Vector2.new(400, 560), Vector2.new(610, 520), Vector2.new(560, 700) } do
		if K.claim(p.X, p.Y, 8) then
			local base = g(p.X, p.Y)
			local cf = CFrame.new(base) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
			local m = O.model(folder, "Buvette")
			local color = faded[random:NextInteger(1, #faded)]
			P(
				m,
				"Caisse",
				Vector3.new(7, 8, 14),
				cf * CFrame.new(0, 5, 0),
				Enum.Material.SmoothPlastic,
				color
			)
			P(
				m,
				"Volet",
				Vector3.new(0.3, 3, 8),
				cf * CFrame.new(3.8, 8.6, 0) * CFrame.Angles(0, 0, math.rad(-60)),
				Enum.Material.SmoothPlastic,
				faded[4]
			)
			P(
				m,
				"Comptoir",
				Vector3.new(1.2, 0.4, 8),
				cf * CFrame.new(4, 5.4, 0),
				Enum.Material.Metal,
				C.metal
			)
			for _, z in { -5, 5 } do
				P(
					m,
					"Roue",
					Vector3.new(0.8, 2.4, 2.4),
					cf * CFrame.new(3.4, 1.2, z),
					Enum.Material.Rubber,
					C.black,
					{ shape = Enum.PartType.Cylinder }
				)
			end
			K.crate(cf * CFrame.new(-1, 1, 0), "foire")
		end
	end
	-- Des stands de l'autre cote de l'allee aussi, et des bancs, des
	-- poubelles renversees, des papiers.
	for i = 3, #alley - 1, 3 do
		local a, b = alley[i], alley[i + 1]
		local dir = (b - a).Unit
		local side = if i % 2 == 0 then -1 else 1
		local normal = Vector2.new(-dir.Y, dir.X) * side
		local p = a + normal * (ALLEY_WIDTH / 2 + 2.5)
		if K.claim(p.X, p.Y, 3) then
			local base = g(p.X, p.Y)
			local cf = CFrame.lookAt(base, base + Vector3.new(dir.X, 0, dir.Y))
			if random:NextNumber() < 0.5 then
				P(
					folder,
					"Banc",
					Vector3.new(1.6, 0.5, 5),
					cf * CFrame.new(0, 1.6, 0),
					Enum.Material.WoodPlanks,
					C.wood
				)
				P(
					folder,
					"Dossier",
					Vector3.new(0.3, 1.6, 5),
					cf * CFrame.new(0.8, 2.5, 0),
					Enum.Material.WoodPlanks,
					C.wood
				)
			else
				P(
					folder,
					"Poubelle",
					Vector3.new(2, 3, 2),
					cf * CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(80)),
					Enum.Material.Metal,
					faded[5],
					{ shape = Enum.PartType.Cylinder }
				)
			end
		end
		for _ = 1, 3 do
			local q = a + Vector2.new(random:NextNumber(-6, 6), random:NextNumber(-6, 6))
			P(
				folder,
				"Papier",
				Vector3.new(1, 0.05, 1.3),
				CFrame.new(g(q.X, q.Y) + Vector3.new(0, 0.2, 0))
					* CFrame.Angles(0, random:NextNumber(0, 6), 0),
				Enum.Material.SmoothPlastic,
				faded[4],
				{ collide = false, query = false, shadow = false }
			)
		end
	end
	-- Plus de cachettes dans toute la foire.
	for _ = 1, 16 do
		local x, z = random:NextNumber(270, 750), random:NextNumber(370, 750)
		if K.claim(x, z, 5) then
			K.anchor(
				if random:NextNumber() < 0.6 then "Caisses" else "Carton",
				"fragile",
				CFrame.new(g(x, z)) * CFrame.Angles(0, random:NextNumber(0, 6), 0)
			)
		end
	end

	local function measure(problems: { string })
		if wheelHub.Y - K.ground(600, 640) < 40 then
			table.insert(problems, "Fete foraine : la grande roue est trop basse")
		end
		if stands < 6 then
			table.insert(problems, string.format("Fete foraine : %d stands seulement", stands))
		end
		if coaster < 20 then
			table.insert(problems, "Fete foraine : montagnes russes trop courtes")
		end
	end

	return {
		measure = measure,
		summary = string.format(
			"Fete foraine : grande roue, montagnes russes, manege, %d stands, train fantome",
			stands
		),
	}
end
