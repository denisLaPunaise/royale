--!strict
--[[
	Le Cratere — au centre, juste sous la Fissure : la ou l'Oeil a frappe en
	premier. Le fond de la cuvette est jonche de ce qu'il a arrache a toutes
	les zones et laisse retomber : pans de murs, voitures a moitie enterrees,
	un conteneur, un wagon, une nacelle de la grande roue, des casiers, des
	lampadaires tordus, des tas de gravats. Des fissures brulantes courent
	au fond, et des debris flottent encore au-dessus du centre, aspires vers
	le ciel.

	C'est la que tombe le meilleur butin (caisses « cratere »), mais rien n'y
	couvre d'en haut : on y entre vite, on en sort plus vite (CONCEPT.md).
]]

return function(K: any)
	local O, V, B = K.O, K.V, K.B
	local C, P = O.C, O.P
	local random: Random = K.random
	local crater = K.Plan.CRATER
	local folder = K.zoneFolder("Cratere")

	-- Un point au hasard dans la cuvette, plutot vers le fond, au sol.
	local function spot(maxR: number): (Vector3, number)
		local r = math.sqrt(random:NextNumber()) * maxR
		local a = random:NextNumber(0, math.pi * 2)
		local x, z = crater.x + math.cos(a) * r, crater.z + math.sin(a) * r
		return Vector3.new(x, K.ground(x, z), z), r
	end
	-- Penche comme une chose tombee du ciel : plantee de biais dans le sol.
	local function fallen(at: Vector3, sink: number): CFrame
		return CFrame.new(at - Vector3.new(0, sink, 0))
			* CFrame.Angles(
				math.rad(random:NextNumber(-25, 25)),
				random:NextNumber(0, math.pi * 2),
				math.rad(random:NextNumber(-25, 25))
			)
	end

	local pieces = 0
	-- Des pans de murs de maison, fenetre comprise, plantes de travers.
	for _ = 1, 22 do
		local at = spot(crater.radius * 0.85)
		local m = O.model(folder, "PanDeMur")
		O.wall(m, fallen(at, 1.5), random:NextNumber(16, 30), random:NextNumber(9, 16), 0.8, {
			{ x = random:NextNumber(-3, 3), w = 4, b = 3, t = 7, kind = "window" },
		}, Enum.Material.Brick, O.SIDINGS[random:NextInteger(1, #O.SIDINGS)])
		pieces += 1
	end
	-- Des voitures a moitie enterrees, retournees ou sur le flanc.
	for _ = 1, 6 do
		local at = spot(crater.radius * 0.8)
		V.car(
			folder,
			fallen(at, 1.8) * CFrame.Angles(0, 0, math.rad(random:NextNumber(0, 180))),
			O.CAR_COLORS[random:NextInteger(1, #O.CAR_COLORS)],
			true
		)
		pieces += 1
	end
	-- Un conteneur venu du Port, un wagon venu de la Gare.
	B.container(folder, fallen((spot(crater.radius * 0.5)), 3), true)
	B.wagon(folder, fallen((spot(crater.radius * 0.6)), 2), false, true)
	pieces += 2
	-- Une nacelle de la grande roue, et une rangee de casiers du Lycee.
	do
		local at = spot(crater.radius * 0.6)
		local m = O.model(folder, "Nacelle")
		local cf = fallen(at, 1)
		P(
			m,
			"Caisse",
			Vector3.new(6, 5, 6),
			cf * CFrame.new(0, 2.5, 0),
			Enum.Material.Metal,
			Color3.fromRGB(150, 60, 54)
		)
		P(
			m,
			"Toit",
			Vector3.new(7, 0.6, 7),
			cf * CFrame.new(0, 5.6, 0),
			Enum.Material.Metal,
			Color3.fromRGB(190, 170, 120)
		)
		P(
			m,
			"Siege",
			Vector3.new(5, 1, 2),
			cf * CFrame.new(0, 1.2, 1.5),
			Enum.Material.Fabric,
			C.fabric
		)
		local lockers = O.model(folder, "Casiers")
		local lcf = fallen((spot(crater.radius * 0.7)), 0.5)
		for k = -2, 2 do
			P(
				lockers,
				"Casier",
				Vector3.new(2, 7, 2.2),
				lcf * CFrame.new(k * 2.05, 3.5, 0),
				Enum.Material.Metal,
				Color3.fromRGB(70, 90, 104)
			)
		end
		pieces += 2
	end
	-- Des lampadaires tordus et des poutres d'acier plantees.
	for _ = 1, 10 do
		local at = spot(crater.radius * 0.9)
		P(
			folder,
			"Poutre",
			Vector3.new(1.4, random:NextNumber(10, 22), 1.4),
			fallen(at, 2) * CFrame.new(0, 5, 0),
			Enum.Material.Metal,
			C.rust
		)
	end
	-- Des tas de gravats.
	for _ = 1, 22 do
		local at = spot(crater.radius * 0.95)
		V.rubble(folder, at, random:NextNumber(5, 10), random:NextInteger(6, 12))
	end

	-- Les fissures brulantes au fond : de longues lignes brisees, a peine
	-- au-dessus du sol. Le rouge, ici, c'est l'Oeil : on est chez lui.
	for _ = 1, 9 do
		local at = spot(crater.radius * 0.6)
		local dir = random:NextNumber(0, math.pi * 2)
		local p = Vector2.new(at.X, at.Z)
		for _ = 1, random:NextInteger(4, 8) do
			local len = random:NextNumber(5, 12)
			dir += random:NextNumber(-0.7, 0.7)
			local q = p + Vector2.new(math.cos(dir), math.sin(dir)) * len
			local a3 = Vector3.new(p.X, K.ground(p.X, p.Y) + 0.05, p.Y)
			local b3 = Vector3.new(q.X, K.ground(q.X, q.Y) + 0.05, q.Y)
			P(
				folder,
				"Fissure",
				Vector3.new(random:NextNumber(0.4, 1), 0.2, (b3 - a3).Magnitude),
				CFrame.lookAt((a3 + b3) / 2, b3),
				Enum.Material.Neon,
				C.rift,
				{ collide = false, query = false, shadow = false }
			)
			p = q
		end
	end
	-- Une lueur au fond, et des debris qui flottent encore au-dessus du
	-- centre (decor, ils ne bloquent rien).
	do
		local center = Vector3.new(crater.x, K.ground(crater.x, crater.z), crater.z)
		local glow = P(
			folder,
			"Lueur",
			Vector3.new(2, 2, 2),
			CFrame.new(center + Vector3.new(0, 3, 0)),
			Enum.Material.SmoothPlastic,
			C.black,
			{ transparency = 1, collide = false, query = false, shadow = false }
		)
		local light = Instance.new("PointLight")
		light.Color = C.rift
		light.Range = 60
		light.Brightness = 1.4
		light.Parent = glow
		for _ = 1, 40 do
			local r = random:NextNumber(5, 70)
			local a = random:NextNumber(0, math.pi * 2)
			P(
				folder,
				"DebrisFlottant",
				Vector3.new(
					random:NextNumber(0.6, 3),
					random:NextNumber(0.4, 1.5),
					random:NextNumber(0.6, 3)
				),
				CFrame.new(
					center + Vector3.new(math.cos(a) * r, random:NextNumber(8, 60), math.sin(a) * r)
				)
					* CFrame.Angles(
						random:NextNumber(0, 6),
						random:NextNumber(0, 6),
						random:NextNumber(0, 6)
					),
				if random:NextNumber() < 0.5
					then Enum.Material.Concrete
					else Enum.Material.WoodPlanks,
				if random:NextNumber() < 0.5 then C.concrete else C.wood,
				{ collide = false, query = false, shadow = false }
			)
		end
	end

	-- Des fumees grises qui montent lentement du fond, eclairees en dessous
	-- par les fissures : le Cratere fume encore, un an apres.
	for _ = 1, 4 do
		local at = spot(crater.radius * 0.5)
		local source = P(
			folder,
			"Fumee",
			Vector3.new(4, 1, 4),
			CFrame.new(at),
			Enum.Material.SmoothPlastic,
			C.black,
			{ transparency = 1, collide = false, query = false, shadow = false }
		)
		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Color = ColorSequence.new(Color3.fromRGB(90, 86, 84), Color3.fromRGB(60, 58, 58))
		smoke.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 6),
			NumberSequenceKeypoint.new(1, 22),
		})
		smoke.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.75),
			NumberSequenceKeypoint.new(0.3, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		smoke.Lifetime = NumberRange.new(10, 16)
		smoke.Rate = 2
		smoke.Speed = NumberRange.new(2, 4)
		smoke.Rotation = NumberRange.new(0, 360)
		smoke.RotSpeed = NumberRange.new(-8, 8)
		smoke.LightEmission = 0.05
		smoke.Parent = source
	end

	-- Le butin : des caisses eparpillees, plutot vers le fond. Et des
	-- cachettes fragiles seulement (tole, caisses) : rien n'abrite d'en haut.
	local crates = 0
	for _ = 1, 14 do
		local at = spot(crater.radius * 0.75)
		K.crate(fallen(at, 0.3), "cratere")
		crates += 1
	end
	for _ = 1, 8 do
		local at = spot(crater.radius * 0.9)
		K.anchor(
			if random:NextNumber() < 0.5 then "Tole" else "Caisses",
			"fragile",
			CFrame.new(at) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
		)
	end
	K.claim(crater.x, crater.z, crater.radius)

	local function measure(problems: { string })
		if crates < 10 then
			table.insert(problems, "Cratere : trop peu de caisses")
		end
	end

	return {
		measure = measure,
		summary = string.format("Cratere : %d grandes epaves, %d caisses", pieces, crates),
	}
end
