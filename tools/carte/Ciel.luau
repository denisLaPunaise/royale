--!strict
--[[
	Ciel — la Fissure, l'Oeil et ses paupieres, les debris aspires, et la
	lumiere de la carte.

	Repris de la recette de Survivor, ou l'Oeil a ete regle avec Josh (le
	laser qui sort de la pupille, la jointure en braise, les eclairs). Le jeu
	fait partir le regard du bout de la pupille, mesure sur ce modele.
]]

local Lighting = game:GetService("Lighting")

-- La hauteur de l'Oeil au-dessus du sol, comme dans Survivor : de la, le
-- regard arrive en biais au bord de la carte (CONCEPT.md, La carte).
local EYE_HEIGHT = 600

-- Le contrat de nommage du ciel, lu par le jeu.
local SKY = { folder = "Ciel", eye = "Oeil", debris = "Debris", lids = "Paupieres" }

return function(O: any)
	local C = O.C
	local P = O.P
	local folder = O.folder
	local model = O.model
	local triangle = O.triangle
	local slab = O.slab
	local random = O.random

	local function buildSky(root: Instance, center: Vector3)
		local m = model(root, SKY.folder)
		-- Toujours charge chez chaque client : l'Oeil se voit de partout, et la
		-- vue du ciel ne prend que les debris presents au demarrage.
		m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		local noRay = { collide = false, query = false, shadow = false }
		local riftY = center.Y + EYE_HEIGHT + 10
		local eyeAt = center + Vector3.new(0, EYE_HEIGHT + 95, 0)

		-- LA FISSURE : une dechirure noire en amande, orientee est-ouest, aux
		-- bords irreguliers et brulants. On voit l'Oeil par le trou.
		local halfLong, halfShort = 190, 105
		local segments = 44
		-- Le bord : une couronne pleine entre le trou et un contour exterieur
		-- dechiquete, remplie de triangles (un seul plan, pas des pics).
		local function almond(angle: number, grow: number): Vector3
			local sx = math.cos(angle)
			local sz = math.sin(angle) * (0.55 + 0.45 * math.abs(math.sin(angle)))
			return Vector3.new(sx * (halfLong + grow), riftY, sz * (halfShort + grow))
		end
		local inner: { Vector3 } = {}
		local outer: { Vector3 } = {}
		for i = 0, segments - 1 do
			local a = (i / segments) * math.pi * 2
			table.insert(inner, almond(a, random:NextNumber(-6, 6)))
			-- Le contour exterieur alterne pointes et creux : une dechirure.
			local reach = if i % 2 == 0
				then random:NextNumber(90, 190)
				else random:NextNumber(35, 80)
			table.insert(outer, almond(a, reach))
		end
		local black = Color3.fromRGB(10, 7, 9)
		for i = 1, segments do
			local j = (i % segments) + 1
			triangle(m, inner[i], outer[i], outer[j], 3, Enum.Material.SmoothPlastic, black)
			triangle(m, inner[i], outer[j], inner[j], 3, Enum.Material.SmoothPlastic, black)
			-- La levre brulante, juste au bord du trou.
			local lip = slab(
				m,
				inner[i] - Vector3.new(0, 2, 0),
				inner[j] - Vector3.new(0, 2, 0),
				random:NextNumber(3, 6),
				1.5,
				Enum.Material.Neon,
				C.rift,
				"Levre"
			)
			lip.CanCollide = false
			lip.CanQuery = false
			lip.CastShadow = false
			-- Les coins du remplissage ne doivent ni bloquer ni ombrer.
			for _, child in m:GetChildren() do
				if child:IsA("BasePart") and child.Name == "Pignon" then
					child.CanCollide = false
					child.CanQuery = false
					child.CastShadow = false
					child.Name = "Dechirure"
				end
			end
		end
		-- Les fissures qui courent dans le ciel autour de la dechirure, en zigzag.
		for i = 1, 16 do
			local angle = (i / 16) * math.pi * 2 + random:NextNumber(-0.15, 0.15)
			local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local at = Vector3.new(dir.X * (halfLong + 80), riftY - 1, dir.Z * (halfShort + 80))
			for rank = 1, random:NextInteger(4, 8) do
				local turn = random:NextNumber(-0.7, 0.7)
				local step = Vector3.new(
					dir.X * math.cos(turn) - dir.Z * math.sin(turn),
					0,
					dir.X * math.sin(turn) + dir.Z * math.cos(turn)
				) * random:NextNumber(40, 90)
				local crack = slab(
					m,
					at,
					at + step,
					random:NextNumber(1.5, 4),
					1.5,
					Enum.Material.Neon,
					C.rift,
					"Fissure"
				)
				crack.CanCollide = false
				crack.CanQuery = false
				crack.CastShadow = false
				crack.Transparency = random:NextNumber(0.1, 0.45)
				-- La vue du ciel fait courir une lueur le long de chaque branche,
				-- du trou vers le dehors.
				crack:SetAttribute("Branche", i)
				crack:SetAttribute("Rang", rank)
				at += step
			end
		end
		-- Le fond de la dechirure : un noir profond derriere l'Oeil.
		P(
			m,
			"Neant",
			Vector3.new(halfLong * 2.4, 4, halfShort * 2.4),
			CFrame.new(0, eyeAt.Y + 120, 0),
			Enum.Material.SmoothPlastic,
			Color3.fromRGB(4, 2, 4),
			noRay
		)

		-- L'OEIL. Un modele dont l'avant (-Z) regarde le sol ; la vue du ciel le
		-- tourne vers ce qu'il cherche.
		local eye = model(m, SKY.eye)
		local look = CFrame.lookAt(eyeAt, eyeAt - Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))
		local radius = 120
		local globe = P(
			eye,
			"Globe",
			Vector3.new(radius * 2, radius * 2, radius * 2),
			look,
			Enum.Material.SmoothPlastic,
			Color3.fromRGB(184, 168, 136),
			{
				shape = Enum.PartType.Ball,
				collide = false,
				query = false,
				shadow = false,
			}
		)
		eye.PrimaryPart = globe
		-- Des veines sur le devant du globe, qui se ramifient en allant vers le
		-- bord : sombres pour la plupart, quelques-unes brulantes. Toutes en neon,
		-- le globe paraissait un jouet propre (vu en image le 5 novembre 2026).
		local function onGlobe(a: number, r: number): Vector3
			local z = -math.sqrt(math.max(radius * radius - r * r, 0)) - 0.4
			return (look * CFrame.new(math.cos(a) * r, math.sin(a) * r, z)).Position
		end
		local function vein(a0: number, r0: number, a1: number, r1: number, width: number)
			local hot = random:NextNumber() < 0.25
			local v = slab(
				eye,
				onGlobe(a0, r0),
				onGlobe(a1, r1),
				width,
				0.6,
				if hot then Enum.Material.Neon else Enum.Material.SmoothPlastic,
				if hot then Color3.fromRGB(150, 30, 26) else Color3.fromRGB(112, 30, 26),
				"Veine"
			)
			v.CanCollide = false
			v.CanQuery = false
			v.CastShadow = false
		end
		for i = 1, 34 do
			local a = (i / 34) * math.pi * 2 + random:NextNumber(-0.08, 0.08)
			local r0 = random:NextNumber(60, 66)
			local mid = random:NextNumber(82, 92)
			local bend = a + random:NextNumber(-0.08, 0.08)
			vein(a, r0, bend, mid, random:NextNumber(1, 2.2))
			-- Deux branches plus fines vers le bord.
			for _, side in { -1, 1 } do
				if random:NextNumber() < 0.7 then
					vein(
						bend,
						mid,
						bend + side * random:NextNumber(0.04, 0.12),
						random:NextNumber(100, 114),
						random:NextNumber(0.5, 1.1)
					)
				end
			end
		end
		-- Un reflet humide, fixe sur le globe : il lui donne du volume.
		do
			local a, r = math.rad(135), 78
			local at = onGlobe(a, r)
			local normal = (at - look.Position).Unit
			P(
				eye,
				"Reflet",
				Vector3.new(0.4, 16, 16),
				CFrame.lookAt(at + normal * 0.6, at + normal * 2)
					* CFrame.Angles(0, math.rad(90), 0),
				Enum.Material.Neon,
				Color3.fromRGB(255, 246, 232),
				{
					shape = Enum.PartType.Cylinder,
					collide = false,
					query = false,
					shadow = false,
					transparency = 0.35,
				}
			)
		end
		-- Iris, anneau sombre, pupille fendue. Un cylindre a son axe sur X : on le
		-- tourne pour que son axe soit l'avant de l'Oeil.
		local face = look * CFrame.Angles(0, math.rad(90), 0)
		local front = radius - 6
		-- Un liseré brulant autour d'un iris sombre : le neon partout faisait un
		-- jouet rouge (vu en image le 5 novembre 2026).
		P(
			eye,
			"Lisere",
			Vector3.new(13, 122, 122),
			face * CFrame.new(front - 0.5, 0, 0),
			Enum.Material.Neon,
			Color3.fromRGB(170, 56, 26),
			{
				shape = Enum.PartType.Cylinder,
				collide = false,
				query = false,
				shadow = false,
			}
		)
		P(
			eye,
			"Iris",
			Vector3.new(14, 116, 116),
			face * CFrame.new(front, 0, 0),
			Enum.Material.SmoothPlastic,
			Color3.fromRGB(66, 20, 12),
			{
				shape = Enum.PartType.Cylinder,
				collide = false,
				query = false,
				shadow = false,
			}
		)
		-- Un anneau chaud qui rougeoie, puis le coeur sombre autour de la pupille.
		P(
			eye,
			"IrisChaud",
			Vector3.new(14, 98, 98),
			face * CFrame.new(front + 0.6, 0, 0),
			Enum.Material.Neon,
			Color3.fromRGB(176, 62, 22),
			{
				shape = Enum.PartType.Cylinder,
				collide = false,
				query = false,
				shadow = false,
				transparency = 0.25,
			}
		)
		P(
			eye,
			"AnneauIris",
			Vector3.new(14, 74, 74),
			face * CFrame.new(front + 1.2, 0, 0),
			Enum.Material.SmoothPlastic,
			Color3.fromRGB(58, 16, 8),
			{
				shape = Enum.PartType.Cylinder,
				collide = false,
				query = false,
				shadow = false,
			}
		)
		-- Les fibres de l'iris, du coeur vers l'anneau chaud.
		local irisFace = front + 8.4
		for i = 1, 48 do
			local a = (i / 48) * math.pi * 2 + random:NextNumber(-0.04, 0.04)
			local r0 = random:NextNumber(16, 22)
			local r1 = random:NextNumber(40, 50)
			local fiber = slab(
				eye,
				(look * CFrame.new(math.cos(a) * r0, math.sin(a) * r0, -irisFace)).Position,
				(look * CFrame.new(math.cos(a) * r1, math.sin(a) * r1, -irisFace)).Position,
				random:NextNumber(0.8, 1.8),
				0.4,
				Enum.Material.Neon,
				Color3.fromRGB(220, 110, 44)
					:Lerp(Color3.fromRGB(120, 30, 14), random:NextNumber(0, 0.7)),
				"Fibre"
			)
			fiber.CanCollide = false
			fiber.CanQuery = false
			fiber.CastShadow = false
			fiber.Transparency = random:NextNumber(0.2, 0.55)
		end
		-- La pupille fendue, DEVANT les fibres (avant, elle etait derriere les
		-- anneaux et l'on ne voyait qu'un disque noir). Une amande faite de
		-- tranches : une seule barre droite barrait l'iris comme un panneau
		-- d'interdiction (vu en image). Leur largeur est sur X : la vue du ciel
		-- les resserre quand il cherche.
		for _, cut in { { 0, 16, 34 }, { 22, 11, 12 }, { 32, 6, 9 }, { 39, 2.5, 6 } } do
			for _, sign in (if cut[1] == 0 then { 1 } else { -1, 1 }) do
				P(
					eye,
					"Pupille",
					Vector3.new(cut[2], cut[3], 4),
					look * CFrame.new(0, sign * cut[1], -(front + 9.5)),
					Enum.Material.SmoothPlastic,
					Color3.fromRGB(4, 2, 2),
					noRay
				)
			end
		end

		-- LES PAUPIERES : la Fissure se referme sur l'Oeil entre deux Balayages et
		-- la nuit (Josh : « qu'il se ferme quand il est pas actif »). Deux rideaux
		-- noirs aux bords brulants, faits de bandes que la vue du ciel allonge ;
		-- fermees, il ne reste qu'une couture rougeoyante. Elles passent SOUS le
		-- globe (qui deborde de la dechirure), et depassent largement le trou pour
		-- le cacher aussi vu de biais. Construites fermees.
		do
			local lids = folder(m, SKY.lids)
			local lidY = eyeAt.Y - radius - 6
			local strips = 32
			local span = (halfLong + 30) * 2
			local stripW = span / strips
			for i = 1, strips do
				local x = -span / 2 + (i - 0.5) * stripW
				-- La demi-largeur du trou a cet endroit : le plus grand ecart des
				-- points du bord dont l'abscisse tombe dans la bande.
				local h = 0
				for k = 0, 719 do
					local a = k / 720 * math.pi * 2
					local p = almond(a, 0)
					if math.abs(p.X - x) <= stripW / 2 + 4 then
						h = math.max(h, math.abs(p.Z))
					end
				end
				h += 45
				for _, side in { -1, 1 } do
					local lid = P(
						lids,
						"Paupiere",
						Vector3.new(stripW + 1, 2, h),
						CFrame.new(x, lidY, side * h / 2),
						Enum.Material.SmoothPlastic,
						-- Une chair sombre, pas le noir de la dechirure : fermee,
						-- on doit voir l'amande d'une paupiere (en noir, ce n'etait
						-- qu'une tache, vu en jeu).
						Color3.fromRGB(46, 18, 16),
						noRay
					)
					lid:SetAttribute("X", x)
					lid:SetAttribute("Demi", h)
					lid:SetAttribute("Cote", side)
					local edge = P(
						lids,
						"Bord",
						Vector3.new(stripW + 1, 2.4, 6),
						CFrame.new(x, lidY - 1.8, 0),
						Enum.Material.Neon,
						C.rift,
						noRay
					)
					edge:SetAttribute("X", x)
					edge:SetAttribute("Demi", h)
					edge:SetAttribute("Cote", side)
				end
			end
		end

		-- LES DEBRIS : la ville qui monte vers la Fissure. Des morceaux de murs,
		-- de toits, une voiture, un canape, des planches. La vue du ciel les fait
		-- monter ; ils sont ancres et hors de portee des rayons.
		local debris = folder(m, SKY.debris)
		local kinds = {
			{ Vector3.new(14, 10, 0.8), Enum.Material.WoodPlanks, C.sidingCream },
			{ Vector3.new(12, 0.6, 9), Enum.Material.Slate, C.roofSlate },
			{ Vector3.new(6, 2.4, 2.6), Enum.Material.Fabric, C.fabric },
			{ Vector3.new(0.4, 0.4, 9), Enum.Material.WoodPlanks, C.woodGray },
			{ Vector3.new(8, 8, 0.8), Enum.Material.Brick, C.brickRed },
			{ Vector3.new(3, 3, 3), Enum.Material.WoodPlanks, C.wood },
		}
		for i = 1, 34 do
			local k = kinds[(i % #kinds) + 1]
			local angle = random:NextNumber(0, math.pi * 2)
			local dist = random:NextNumber(40, 230)
			local at = Vector3.new(
				math.cos(angle) * dist,
				random:NextNumber(120, 560),
				math.sin(angle) * dist
			)
			P(
				debris,
				"Debris",
				k[1],
				CFrame.new(at)
					* CFrame.Angles(
						random:NextNumber(0, 6),
						random:NextNumber(0, 6),
						random:NextNumber(0, 6)
					),
				k[2],
				k[3],
				noRay
			)
		end
		-- Survivor faisait aussi monter deux voitures : elles reviendront avec
		-- les voitures de la Banlieue (le modele de voiture n'est pas encore
		-- dans les outils de Royale).
	end

	-- La lumiere : basse, grise, sans soleil franc
	local function buildLighting()
		for _, child in Lighting:GetChildren() do
			if
				string.sub(child.Name, 1, 6) == "Royale"
				or child:IsA("Sky")
				or child:IsA("Atmosphere")
			then
				child:Destroy()
			end
		end
		-- Lighting.Technology ne se lit ni ne s'ecrit depuis le pont : a regler a
		-- la main sur Future (Lighting > Technology), une fois pour la place.
		-- Soleil rasant (10 a 22 degres), pour que les ombres existent.
		Lighting.ClockTime = 16.9
		Lighting.GeographicLatitude = 40
		Lighting.Brightness = 2.2
		Lighting.Ambient = Color3.fromRGB(34, 34, 38)
		Lighting.OutdoorAmbient = Color3.fromRGB(112, 110, 108)
		Lighting.EnvironmentDiffuseScale = 1
		Lighting.EnvironmentSpecularScale = 0.6
		Lighting.ShadowSoftness = 0.25
		Lighting.ExposureCompensation = 0.1
		Lighting.FogEnd = 100000

		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "RoyaleAtmosphere"
		-- Assez dense pour noyer le lointain, pas au point de cacher la rue d'en
		-- face.
		atmosphere.Density = 0.42
		atmosphere.Offset = 0.12
		atmosphere.Color = Color3.fromRGB(178, 172, 164)
		atmosphere.Decay = Color3.fromRGB(110, 96, 88)
		atmosphere.Glare = 0.2
		atmosphere.Haze = 2.2
		atmosphere.Parent = Lighting

		local grade = Instance.new("ColorCorrectionEffect")
		grade.Name = "RoyaleEtalonnage"
		grade.Saturation = -0.28
		grade.Contrast = 0.12
		grade.Brightness = -0.02
		grade.TintColor = Color3.fromRGB(255, 248, 240)
		grade.Parent = Lighting

		local bloom = Instance.new("BloomEffect")
		bloom.Name = "RoyaleBloom"
		bloom.Intensity = 0.6
		bloom.Size = 28
		bloom.Threshold = 1.6
		bloom.Parent = Lighting

		local rays = Instance.new("SunRaysEffect")
		rays.Name = "RoyaleRayons"
		rays.Intensity = 0.04
		rays.Spread = 0.6
		rays.Parent = Lighting

		local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
		-- Un ciel couvert, sans trouee bleue : le bleu disait « beau temps ».
		clouds.Cover = 0.92
		clouds.Density = 0.7
		clouds.Color = Color3.fromRGB(140, 136, 134)
		clouds.Parent = workspace.Terrain
	end

	return {
		buildSky = buildSky,
		buildLighting = buildLighting,
		EYE_HEIGHT = EYE_HEIGHT,
		SKY = SKY,
	}
end
