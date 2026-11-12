--!strict
--[[
	La campagne habitee — entre les zones, la ou la carte etait vide (mesure
	le 12 novembre 2026 : des carres de 200 studs sans une cachette ni une
	fouille). Des fermes isolees et deux hameaux, une chapelle en ruine sur
	la colline du nord-ouest, une station de pompage au bord de la riviere.

	Chaque ferme a sa maison, sa grange de bois, son silo, son enclos, ses
	bottes de foin, un vieux tracteur, des caisses a fouiller et des
	cachettes : il y a quelque chose a trouver partout, pas seulement en
	ville.
]]

-- Ou poser les fermes : dans les vides mesures, loin du Cratere et des
-- zones. (x, z, orientation en degres)
local FARMS = {
	{ -385, 225, 20 },
	{ -240, 205, -15 },
	{ -150, -205, 70 },
	{ 150, -480, 160 },
	{ -560, 690, -40 },
	{ 95, 255, 110 },
}

return function(K: any)
	local O, V = K.O, K.V
	local C, P = O.C, O.P
	local random: Random = K.random
	local folder = K.zoneFolder("Campagne")
	local barnRed = Color3.fromRGB(110, 62, 50)
	local hay = Color3.fromRGB(176, 150, 92)

	local function land(x: number, z: number): Vector3
		return Vector3.new(x, K.ground(x, z), z)
	end

	local farms = 0
	local function farm(x: number, z: number, yawDeg: number, index: number)
		if not K.isFree(x, z, 30) then
			return
		end
		local yaw = math.rad(yawDeg)
		local origin = CFrame.new(land(x, z)) * CFrame.Angles(0, yaw, 0)
		local function at(dx: number, dz: number): CFrame
			local p = (origin * CFrame.new(dx, 0, dz)).Position
			return CFrame.new(p.X, K.ground(p.X, p.Z), p.Z) * CFrame.Angles(0, yaw, 0)
		end
		local m = O.model(folder, "Ferme" .. index)
		K.claim(x, z, 34)

		-- La maison, en pierre, a etage.
		V.house(m, at(-14, -10), {
			name = "Ferme" .. index .. "Maison",
			siding = Color3.fromRGB(150, 140, 120),
			material = Enum.Material.Cobblestone,
			roof = C.roofBrown,
			damage = if random:NextNumber() < 0.3 then "trou" else "intact",
			garage = false,
			storeys = 2,
			mirror = random:NextNumber() < 0.5,
			bedroom = true,
			story = if random:NextNumber() < 0.3 then "mot" else nil,
		}, K.containers)

		-- La grange : murs de planches, grande porte, toit a deux pentes.
		local barn = at(22, 6)
		local bw, bd, bh = 26, 34, 12
		local b = O.model(m, "Grange")
		O.wall(
			b,
			barn,
			bw,
			bh,
			0.8,
			{ { x = 0, w = 10, b = 0, t = 10, kind = "garage" } },
			Enum.Material.WoodPlanks,
			barnRed
		)
		O.wall(
			b,
			barn * CFrame.new(0, 0, bd) * CFrame.Angles(0, math.pi, 0),
			bw,
			bh,
			0.8,
			{},
			Enum.Material.WoodPlanks,
			barnRed
		)
		for _, sx in { -1, 1 } do
			O.wall(
				b,
				barn * CFrame.new(sx * bw / 2, 0, bd / 2) * CFrame.Angles(0, math.rad(90 * sx), 0),
				bd,
				bh,
				0.8,
				{ { x = 0, w = 4, b = 7, t = 10, kind = "window" } },
				Enum.Material.WoodPlanks,
				barnRed
			)
			O.slab(
				b,
				(barn * CFrame.new(sx * (bw / 2 + 1), bh, bd / 2)).Position,
				(barn * CFrame.new(0, bh + 8, bd / 2)).Position,
				bd + 2,
				0.6,
				Enum.Material.Metal,
				Color3.fromRGB(86, 88, 90),
				"Toit"
			)
		end
		for _, sx in { -1, 1 } do
			O.triangle(
				b,
				(barn * CFrame.new(-bw / 2, bh, if sx < 0 then 0 else bd)).Position,
				(barn * CFrame.new(bw / 2, bh, if sx < 0 then 0 else bd)).Position,
				(barn * CFrame.new(0, bh + 8, if sx < 0 then 0 else bd)).Position,
				0.8,
				Enum.Material.WoodPlanks,
				barnRed
			)
		end
		V.tagBuilding(b, barn.Position.Y)
		for _ = 1, 3 do
			local bale = P(
				b,
				"Botte",
				Vector3.new(5, 4, 4),
				barn
					* CFrame.new(random:NextNumber(-8, 8), 2, random:NextNumber(8, 28))
					* CFrame.Angles(0, 0, math.rad(90)),
				Enum.Material.Grass,
				hay,
				{ shape = Enum.PartType.Cylinder }
			)
			_ = bale
		end
		K.crate(barn * CFrame.new(-9, 0, 26), "ferme")
		K.anchor("Caisses", "fragile", barn * CFrame.new(9, 0, 24))

		-- Le silo et son dome.
		local silo = at(42, -12)
		P(
			m,
			"Silo",
			Vector3.new(26, 12, 12),
			silo * CFrame.new(0, 13, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.Metal,
			Color3.fromRGB(150, 150, 146),
			{ shape = Enum.PartType.Cylinder }
		)
		P(
			m,
			"Dome",
			Vector3.new(12, 12, 12),
			silo * CFrame.new(0, 26, 0),
			Enum.Material.Metal,
			Color3.fromRGB(130, 130, 126),
			{ shape = Enum.PartType.Ball }
		)

		-- L'enclos, en barrieres de bois, avec des trous.
		local corners = { at(-34, 14), at(-2, 14), at(-2, 44), at(-34, 44) }
		for i = 1, 4 do
			if random:NextNumber() > 0.25 then
				V.fence(m, corners[i].Position, corners[(i % 4) + 1].Position, 4)
			end
		end
		-- Des bottes de foin dans le pre, une auge, un vieux tracteur.
		for _ = 1, 4 do
			local p = at(random:NextNumber(-30, -6), random:NextNumber(18, 40))
			P(
				m,
				"Botte",
				Vector3.new(5, 5, 5),
				p * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, random:NextNumber(0, 6), math.rad(90)),
				Enum.Material.Grass,
				hay,
				{ shape = Enum.PartType.Cylinder }
			)
		end
		do
			local t = at(8, -24) * CFrame.Angles(0, random:NextNumber(-0.5, 0.5), 0)
			local green = Color3.fromRGB(64, 92, 64)
			P(
				m,
				"Tracteur",
				Vector3.new(5, 4, 9),
				t * CFrame.new(0, 4, 0),
				Enum.Material.Metal,
				green
			)
			P(
				m,
				"Cabine",
				Vector3.new(4.6, 4, 4),
				t * CFrame.new(0, 8, 2),
				Enum.Material.Glass,
				C.glass,
				{ transparency = 0.4 }
			)
			for _, sx in { -3, 3 } do
				P(
					m,
					"GrandeRoue",
					Vector3.new(1.6, 7, 7),
					t * CFrame.new(sx, 3.5, 2.5),
					Enum.Material.Rubber,
					C.black,
					{ shape = Enum.PartType.Cylinder }
				)
				P(
					m,
					"PetiteRoue",
					Vector3.new(1.2, 4, 4),
					t * CFrame.new(sx * 0.9, 2, -3.5),
					Enum.Material.Rubber,
					C.black,
					{ shape = Enum.PartType.Cylinder }
				)
			end
		end
		-- Les cachettes autour : un abri, une tole, des buissons.
		K.anchor("Abri", "moyenne", at(-30, -18) * CFrame.Angles(0, math.rad(90), 0))
		K.anchor("Tole", "fragile", at(30, 40))
		K.anchor("Buisson", "fragile", at(-38, -2))
		V.tree(m, at(-40, 20).Position, false)
		V.tree(m, at(48, 24).Position, random:NextNumber() < 0.3)
		farms += 1
	end

	for i, f in FARMS do
		farm(f[1], f[2], f[3], i)
	end

	-- La chapelle en ruine, sur la colline du nord-ouest : un repere.
	do
		local base = land(-300, 690)
		local cf = CFrame.new(base) * CFrame.Angles(0, math.rad(25), 0)
		local m = O.model(folder, "Chapelle")
		local stone = Color3.fromRGB(150, 146, 136)
		local w, d, h = 18, 34, 14
		-- Une fondation de pierre : sur la pente de la colline, la chapelle
		-- flottait d'un cote (mesure le 12 novembre 2026).
		P(
			m,
			"Fondation",
			Vector3.new(w + 2, 14, d + 2),
			cf * CFrame.new(0, -6.8, d / 2),
			Enum.Material.Cobblestone,
			Color3.fromRGB(120, 116, 108)
		)
		O.wall(
			m,
			cf,
			w,
			h,
			1.2,
			{ { x = 0, w = 5, b = 0, t = 9, kind = "door" } },
			Enum.Material.Cobblestone,
			stone
		)
		for _, sx in { -1, 1 } do
			O.wall(
				m,
				cf * CFrame.new(sx * w / 2, 0, d / 2) * CFrame.Angles(0, math.rad(90 * sx), 0),
				d,
				h * (if sx < 0 then 1 else 0.6),
				1.2,
				{
					{ x = -8, w = 3, b = 5, t = 11, kind = "window" },
					{ x = 8, w = 3, b = 5, t = 11, kind = "window" },
				},
				Enum.Material.Cobblestone,
				stone
			)
		end
		O.wall(
			m,
			cf * CFrame.new(0, 0, d) * CFrame.Angles(0, math.pi, 0),
			w,
			h,
			1.2,
			{},
			Enum.Material.Cobblestone,
			stone
		)
		-- Le clocher, a moitie debout.
		P(
			m,
			"Clocher",
			Vector3.new(8, 30, 8),
			cf * CFrame.new(0, 15, -2),
			Enum.Material.Cobblestone,
			stone
		)
		P(
			m,
			"Fleche",
			Vector3.new(6, 6, 6),
			cf * CFrame.new(0, 33, -2) * CFrame.Angles(math.rad(20), 0, math.rad(15)),
			Enum.Material.Slate,
			C.roofSlate
		)
		V.rubble(m, (cf * CFrame.new(4, 0, 14)).Position, 7, 12)
		V.tagBuilding(m, base.Y)
		K.crate(cf * CFrame.new(-4, 0.6, 26), "chapelle")
		local spot = O.model(K.solid, "CryptChapelle")
		O.marker(spot, K.CONTRACT.inside, cf * CFrame.new(0, 2.5, 28))
		O.marker(spot, K.CONTRACT.exit, cf * CFrame.new(0, 3, -4))
		K.claim(base.X, base.Z, 24)
		-- Le petit cimetiere.
		for _ = 1, 10 do
			local p = cf * CFrame.new(random:NextNumber(-20, 20), 0, random:NextNumber(38, 56))
			P(
				m,
				"Tombe",
				Vector3.new(2.4, 3, 0.6),
				p
					* CFrame.new(0, 1.2, 0)
					* CFrame.Angles(
						math.rad(random:NextNumber(-12, 12)),
						0,
						math.rad(random:NextNumber(-10, 10))
					),
				Enum.Material.Slate,
				stone:Lerp(Color3.new(0, 0, 0), 0.2)
			)
		end
	end

	-- La station de pompage, au bord de la riviere, entre la Banlieue et
	-- l'Hypermarche : un petit batiment de brique et ses tuyaux.
	do
		local base = land(260, -262)
		if K.claim(base.X, base.Z, 16) then
			local cf = CFrame.new(base) * CFrame.Angles(0, math.rad(10), 0)
			local m = O.model(folder, "StationDePompage")
			K.B.building(m, cf, {
				name = "Pompage",
				w = 18,
				d = 14,
				floors = 1,
				floorH = 10,
				material = Enum.Material.Brick,
				color = Color3.fromRGB(130, 86, 70),
				roof = "plat",
				windowEvery = 6,
				doors = 1,
			})
			for k = 0, 2 do
				P(
					m,
					"Tuyau",
					Vector3.new(30, 2, 2),
					cf
						* CFrame.new(-4 + k * 4, 1, -14)
						* CFrame.Angles(0, math.rad(90), math.rad(90)),
					Enum.Material.Metal,
					C.rust,
					{ shape = Enum.PartType.Cylinder }
				)
			end
			K.crate(cf * CFrame.new(4, 0.6, 8), "atelier")
			K.anchor("Tole", "fragile", cf * CFrame.new(14, 0, 0))
		end
	end

	local function measure(problems: { string })
		if farms < 4 then
			table.insert(
				problems,
				string.format("Campagne : %d fermes seulement (pas de place ?)", farms)
			)
		end
	end

	return {
		measure = measure,
		summary = string.format(
			"Campagne : %d fermes, une chapelle en ruine, une station de pompage",
			farms
		),
	}
end
