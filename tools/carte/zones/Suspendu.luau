--!strict
--[[
	Le Quartier suspendu — des morceaux de la Banlieue que l'Oeil a arraches
	du sol et laisses flotter au-dessus d'elle, a mi-chemin du ciel.

	Cinq ilots a des hauteurs et des inclinaisons differentes, chacun avec ce
	qu'il a emporte (un bout de rue et sa voiture, une maison et son jardin,
	des arbres), une motte de terre et de roche dechiree en dessous, des
	racines et des tuyaux qui pendent. Des poutres et des planches les
	relient ; on y monte par une dalle de rue retombee en pente, ou en
	s'agrippant (CONCEPT.md : « on s'agrippe, on saute, on tombe »).

	En haut on voit loin, mais on est a decouvert sous l'Oeil.
]]

-- Ilots : centre au sol (x, z), hauteur au-dessus du sol, taille du dessus,
-- inclinaison (degres), et ce qu'il porte.
local ISLANDS = {
	{ x = 352, z = 122, lift = 46, w = 52, d = 40, tilt = { 3, -2 }, kind = "rue" },
	{ x = 446, z = 205, lift = 60, w = 48, d = 44, tilt = { -2, 4 }, kind = "maison" },
	{ x = 548, z = 138, lift = 52, w = 46, d = 38, tilt = { 5, 1 }, kind = "jardin" },
	{ x = 642, z = 232, lift = 68, w = 50, d = 44, tilt = { -4, -3 }, kind = "ruine" },
	{ x = 712, z = 118, lift = 57, w = 44, d = 36, tilt = { 2, 6 }, kind = "epave" },
}

return function(K: any)
	local O, V = K.O, K.V
	local C, P = O.C, O.P
	local random: Random = K.random
	local folder = K.zoneFolder("QuartierSuspendu")
	local islandTops: { CFrame } = {}

	for i, isl in ISLANDS do
		local m = O.model(folder, "Ilot" .. i)
		local y = K.ground(isl.x, isl.z) + isl.lift
		local top = CFrame.new(isl.x, y, isl.z)
			* CFrame.Angles(
				math.rad(isl.tilt[1]),
				random:NextNumber(0, math.pi * 2),
				math.rad(isl.tilt[2])
			)
		table.insert(islandTops, top)

		-- Le dessus : ce qui a ete arrache avec le sol.
		local surface = if isl.kind == "rue" or isl.kind == "epave"
			then Enum.Material.Asphalt
			else Enum.Material.Grass
		local surfaceColor = if surface == Enum.Material.Asphalt
			then C.asphalt
			else Color3.fromRGB(88, 96, 68)
		P(
			m,
			"Dessus",
			Vector3.new(isl.w, 1.2, isl.d),
			top * CFrame.new(0, -0.6, 0),
			surface,
			surfaceColor
		)
		-- Les bords dechires : des mottes de terre et d'herbe debordent du
		-- dessus, de travers. Sinon chaque ilot etait un rectangle de pelouse
		-- (vu a l'ecran).
		for k = 0, 13 do
			local a = k / 14 * math.pi * 2 + random:NextNumber(-0.2, 0.2)
			local edge = top * CFrame.new(math.cos(a) * isl.w * 0.5, 0, math.sin(a) * isl.d * 0.5)
			P(
				m,
				"Bord",
				Vector3.new(
					random:NextNumber(5, 10),
					random:NextNumber(2, 4),
					random:NextNumber(5, 10)
				),
				edge
					* CFrame.new(0, -1.2, 0)
					* CFrame.Angles(
						random:NextNumber(-0.4, 0.4),
						random:NextNumber(0, 6),
						random:NextNumber(-0.4, 0.4)
					),
				if random:NextNumber() < 0.5 then Enum.Material.Ground else Enum.Material.Grass,
				if random:NextNumber() < 0.5
					then Color3.fromRGB(86, 76, 62)
					else Color3.fromRGB(84, 92, 64)
			)
		end
		V.rubble(
			m,
			(top * CFrame.new(
				random:NextNumber(-isl.w / 4, isl.w / 4),
				0,
				random:NextNumber(-isl.d / 4, isl.d / 4)
			)).Position,
			6,
			8
		)
		-- Une couche de terre visible sur la tranche.
		P(
			m,
			"Tranche",
			Vector3.new(isl.w + 0.4, 3, isl.d + 0.4),
			top * CFrame.new(0, -2.6, 0),
			Enum.Material.Ground,
			C.concreteDark:Lerp(Color3.fromRGB(90, 80, 68), 0.7)
		)

		-- La motte en dessous : des blocs de terre et de roche de plus en plus
		-- petits, tournes au hasard : une dechirure, pas un cone propre.
		local layers = 6
		for k = 1, layers do
			local t = k / layers
			local scale = 1 - t * 0.85
			for _ = 1, 3 do
				local size = Vector3.new(
					isl.w * scale * random:NextNumber(0.5, 0.9),
					random:NextNumber(5, 9),
					isl.d * scale * random:NextNumber(0.5, 0.9)
				)
				P(
					m,
					"Motte",
					size,
					top
						* CFrame.new(
							random:NextNumber(-isl.w, isl.w) * 0.15 * (1 - t),
							-4 - t * 26,
							random:NextNumber(-isl.d, isl.d) * 0.15 * (1 - t)
						)
						* CFrame.Angles(
							random:NextNumber(-0.4, 0.4),
							random:NextNumber(0, 6),
							random:NextNumber(-0.4, 0.4)
						),
					if random:NextNumber() < 0.55 then Enum.Material.Ground else Enum.Material.Rock,
					if random:NextNumber() < 0.55
						then Color3.fromRGB(84, 74, 62)
						else Color3.fromRGB(92, 90, 86)
				)
			end
		end
		-- Racines, cables et tuyaux arraches qui pendent.
		for _ = 1, 9 do
			local length = random:NextNumber(6, 18)
			local isPipe = random:NextNumber() < 0.3
			P(
				m,
				if isPipe then "Tuyau" else "Racine",
				Vector3.new(length, if isPipe then 0.9 else 0.4, if isPipe then 0.9 else 0.4),
				top
					* CFrame.new(
						random:NextNumber(-isl.w / 3, isl.w / 3),
						-6 - length / 2,
						random:NextNumber(-isl.d / 3, isl.d / 3)
					)
					* CFrame.Angles(0, 0, math.rad(90 + random:NextNumber(-15, 15))),
				if isPipe then Enum.Material.Metal else Enum.Material.Wood,
				if isPipe then C.rust else C.bark,
				{ shape = Enum.PartType.Cylinder, collide = false }
			)
		end

		-- Ce que l'ilot a emporte.
		if isl.kind == "rue" then
			P(
				m,
				"Trottoir",
				Vector3.new(isl.w, 0.7, 3),
				top * CFrame.new(0, 0.3, isl.d / 2 - 1.5),
				Enum.Material.Concrete,
				C.concrete
			)
			V.lamp(
				m,
				(top * CFrame.new(-isl.w / 2 + 4, 0, isl.d / 2 - 2)).Position,
				-top.LookVector
			)
			K.anchor(
				"Voiture",
				"moyenne",
				top * CFrame.new(4, 0, -2) * CFrame.Angles(0, math.rad(80), 0)
			)
			K.anchor("Benne", "fragile", top * CFrame.new(-isl.w / 2 + 6, 0, -isl.d / 2 + 5))
		elseif isl.kind == "maison" or isl.kind == "ruine" then
			V.house(m, top * CFrame.new(0, 0, -isl.d / 2 + 6), {
				name = "MaisonSuspendue" .. i,
				siding = O.SIDINGS[random:NextInteger(1, #O.SIDINGS)],
				material = Enum.Material.WoodPlanks,
				roof = C.roofSlate,
				damage = if isl.kind == "ruine" then "ruine" else "trou",
				garage = false,
				storeys = 1,
				mirror = random:NextNumber() < 0.5,
				bedroom = true,
				story = if isl.kind == "ruine" then "mot" else nil,
			}, K.containers)
			V.tree(
				m,
				(top * CFrame.new(isl.w / 2 - 6, 0, isl.d / 2 - 6)).Position,
				isl.kind == "ruine"
			)
			K.anchor("Buisson", "fragile", top * CFrame.new(-isl.w / 2 + 4, 0, isl.d / 2 - 4))
		elseif isl.kind == "jardin" then
			for _ = 1, 3 do
				V.tree(
					m,
					(top * CFrame.new(
						random:NextNumber(-isl.w / 3, isl.w / 3),
						0,
						random:NextNumber(-isl.d / 3, isl.d / 3)
					)).Position,
					false
				)
			end
			K.anchor(
				"Abri",
				"moyenne",
				top * CFrame.new(isl.w / 2 - 7, 0, 0) * CFrame.Angles(0, math.rad(-90), 0)
			)
			K.anchor("Buisson", "fragile", top * CFrame.new(-isl.w / 2 + 5, 0, -isl.d / 2 + 5))
			V.fence(
				m,
				(top * CFrame.new(-isl.w / 2 + 1, 0, isl.d / 2 - 1)).Position,
				(top * CFrame.new(isl.w / 2 - 1, 0, isl.d / 2 - 1)).Position,
				4
			)
		else
			V.car(
				m,
				top * CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(30), 0),
				O.CAR_COLORS[2],
				true
			)
			V.rubble(m, (top * CFrame.new(-8, 0, 6)).Position, 8, 10)
			K.anchor("Tole", "fragile", top * CFrame.new(isl.w / 2 - 5, 0, -isl.d / 2 + 4))
		end
	end

	-- Les passerelles : une poutre de fer et des planches posees dessus,
	-- d'un ilot au suivant. Elles ne sont pas droites comme une rampe neuve.
	local function walkway(a: Vector3, b: Vector3)
		local m = O.model(folder, "Passerelle")
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		P(
			m,
			"Poutre",
			Vector3.new(1.4, 1.6, len),
			cf * CFrame.new(0, -1, 0),
			Enum.Material.Metal,
			C.rust
		)
		local planks = math.floor(len / 2.2)
		for k = 0, planks do
			if random:NextNumber() > 0.08 then
				P(
					m,
					"Planche",
					Vector3.new(random:NextNumber(3.6, 4.6), 0.35, 1.9),
					cf
						* CFrame.new(random:NextNumber(-0.3, 0.3), 0, -len / 2 + k * (len / planks))
						* CFrame.Angles(0, math.rad(random:NextNumber(-6, 6)), 0),
					Enum.Material.WoodPlanks,
					C.woodGray
				)
			end
		end
	end
	for i = 1, #islandTops - 1 do
		local a, b = islandTops[i].Position, islandTops[i + 1].Position
		local dir = (b - a) * Vector3.new(1, 0, 1)
		local from = a + dir.Unit * 20
		local to = b - dir.Unit * 20
		walkway(Vector3.new(from.X, a.Y + 0.2, from.Z), Vector3.new(to.X, b.Y + 0.2, to.Z))
	end

	-- La montee : une dalle de rue retombee en pente, du sol au premier ilot.
	do
		local first = islandTops[1].Position
		local foot = Vector3.new(first.X - 95, 0, first.Z - 40)
		foot = Vector3.new(foot.X, K.ground(foot.X, foot.Z), foot.Z)
		-- Le haut de la dalle repose sur le bord de l'ilot, cote sol.
		local toward = (Vector3.new(foot.X, first.Y, foot.Z) - first).Unit
		local head = first + toward * 22 + Vector3.new(0, -0.4, 0)
		local len = (head - foot).Magnitude
		local cf = CFrame.lookAt((foot + head) / 2, head)
		local m = O.model(folder, "DalleRetombee")
		P(m, "Dalle", Vector3.new(14, 1.4, len), cf, Enum.Material.Asphalt, C.asphalt)
		P(
			m,
			"Bordure",
			Vector3.new(3, 1.8, len),
			cf * CFrame.new(-7.5, 0.3, 0),
			Enum.Material.Concrete,
			C.concrete
		)
		V.rubble(m, foot, 10, 12)
		K.claim(foot.X, foot.Z, 14)
	end

	local function measure(problems: { string })
		for i, top in islandTops do
			local below = K.ground(top.Position.X, top.Position.Z)
			if top.Position.Y - below < 35 then
				table.insert(
					problems,
					string.format("Quartier suspendu : l'ilot %d flotte trop bas", i)
				)
			end
		end
	end

	return {
		measure = measure,
		summary = string.format("Quartier suspendu : %d ilots relies", #islandTops),
	}
end
