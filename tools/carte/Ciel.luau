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

	-- LES FISSURES qui courent dans le ciel autour de la dechirure. Chacune
	-- est une fente sombre qui s'amincit vers sa pointe, une braise en son
	-- coeur, et des ramifications (des batons de neon orange tout droits
	-- faisaient bon marche, vu par Josh le 14 novembre 2026). La vue du ciel
	-- fait courir une lueur le long de chaque branche, du trou vers le dehors
	-- (attributs Branche et Rang).
	-- Le bord en amande de la dechirure (le trou et son contour), partage par
	-- la dechirure et les fissures qui en partent.
	local function almondPoint(
		angle: number,
		grow: number,
		riftY: number,
		halfLong: number,
		halfShort: number
	): Vector3
		local sx = math.cos(angle)
		local sz = math.sin(angle) * (0.55 + 0.45 * math.abs(math.sin(angle)))
		return Vector3.new(sx * (halfLong + grow), riftY, sz * (halfShort + grow))
	end
	local CRACK_DARK = Color3.fromRGB(12, 6, 8)
	local CRACK_EMBER = Color3.fromRGB(255, 96, 40)
	local function buildCracks(m: Instance, riftY: number, halfLong: number, halfShort: number)
		for _, old in m:GetChildren() do
			if old.Name == "Fissure" or old.Name == "FissureFond" then
				old:Destroy()
			end
		end
		local function piece(
			from: Vector3,
			to: Vector3,
			width: number,
			branch: number,
			rank: number,
			fade: number
		)
			-- Les segments se chevauchent un peu : sans ca, chaque coude laissait
			-- un trou.
			local dir = (to - from).Unit
			local a, b = from - dir * width * 0.4, to + dir * width * 0.4
			local dark =
				slab(m, a, b, width, 1.2, Enum.Material.SmoothPlastic, CRACK_DARK, "FissureFond")
			-- La braise, un peu plus bas que la fente : vue du sol, elle passe
			-- devant.
			local ember = slab(
				m,
				a - Vector3.new(0, 0.8, 0),
				b - Vector3.new(0, 0.8, 0),
				math.max(width * 0.32, 0.5),
				1,
				Enum.Material.Neon,
				CRACK_EMBER,
				"Fissure"
			)
			ember.Transparency = fade
			ember:SetAttribute("Branche", branch)
			ember:SetAttribute("Rang", rank)
			for _, p in { dark, ember } do
				p.CanCollide = false
				p.CanQuery = false
				p.CastShadow = false
			end
		end
		local function grow(
			start: Vector3,
			heading: number,
			width: number,
			ranks: number,
			branch: number,
			firstRank: number,
			depth: number
		)
			local at = start
			for rank = 1, ranks do
				heading += random:NextNumber(-0.45, 0.45)
				local length = random:NextNumber(16, 34) * (0.6 + 0.4 * width / 5)
				local step = Vector3.new(math.cos(heading), 0, math.sin(heading)) * length
				-- Plus fine et plus pale vers la pointe.
				local k = (rank - 1) / ranks
				local w = width * (1 - 0.8 * k)
				piece(at, at + step, w, branch, firstRank + rank, 0.05 + 0.6 * k)
				-- Une ramification de temps en temps, plus fine, qui part de biais.
				if depth < 2 and rank < ranks - 1 and random:NextNumber() < 0.3 then
					local side = if random:NextNumber() < 0.5 then -1 else 1
					grow(
						at + step,
						heading + side * random:NextNumber(0.6, 1.1),
						w * 0.6,
						random:NextInteger(2, 4),
						branch,
						firstRank + rank,
						depth + 1
					)
				end
				at += step
			end
		end
		for i = 1, 18 do
			local angle = (i / 18) * math.pi * 2 + random:NextNumber(-0.15, 0.15)
			-- Elle part de la levre du trou et passe sous le bord noir : partie
			-- d'un cercle fixe, elle commencait parfois au-dela d'un bord etroit
			-- et flottait dans le vide (vu par Josh).
			-- Juste apres la levre (qui ondule de 6 studs) : ni au-dessus du trou,
			-- ni dans le vide.
			local start = almondPoint(angle, 10, riftY - 1, halfLong, halfShort)
			grow(start, angle, random:NextNumber(6.5, 9.5), random:NextInteger(6, 10), i, 0, 0)
		end
	end

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
			return almondPoint(angle, grow, riftY, halfLong, halfShort)
		end
		local inner: { Vector3 } = {}
		local outer: { Vector3 } = {}
		for i = 0, segments - 1 do
			local a = (i / segments) * math.pi * 2
			table.insert(inner, almond(a, random:NextNumber(-6, 6)))
			-- Le contour exterieur : une dechirure irreguliere, pas une etoile.
			-- Un bord qui ondule (bruit), avec de loin en loin une longue fente.
			-- (Des pointes regulieres faisaient un dessin d'enfant, vu par Josh.)
			local reach = 55 + 45 * math.noise(i / 7, 3.3) + random:NextNumber(-12, 12)
			if random:NextNumber() < 0.14 then
				reach += random:NextNumber(70, 140)
			end
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
		buildCracks(m, riftY, halfLong, halfShort)
		-- Le fond de la dechirure : une voute sombre et courbe derriere l'Oeil,
		-- eclairee de l'interieur par une lueur rouge. (Une plaque noire plate
		-- faisait un carre au-dessus de l'Oeil, vu par Josh le 12 novembre 2026.)
		do
			local vault = P(
				m,
				"Neant",
				Vector3.new(halfLong * 2.15, 120, halfShort * 2.3),
				CFrame.new(0, riftY + 70, 0),
				Enum.Material.SmoothPlastic,
				-- Assez petite et plate pour rester cachee derriere la dechirure : plus
				-- grande, elle debordait en un enorme oeuf noir (vu a l'ecran).
				Color3.fromRGB(34, 10, 10),
				noRay
			)
			local shape = Instance.new("SpecialMesh")
			shape.MeshType = Enum.MeshType.Sphere
			shape.Parent = vault
			local glow = Instance.new("PointLight")
			glow.Color = Color3.fromRGB(170, 40, 24)
			glow.Range = 60
			glow.Brightness = 2
			glow.Shadows = false
			glow.Parent = vault
		end

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

		-- LES PAUPIERES : deux vraies paupieres qui epousent le globe, une en
		-- haut (vers le nord), une en bas. Chacune est une coque de peau sombre
		-- faite de plaques posees sur une sphere un peu plus grande que le globe,
		-- avec un bord humide, une braise le long de la jointure et des cils.
		-- Elles s'ouvrent et se ferment en TOURNANT autour de l'axe est-ouest du
		-- globe : la vue du ciel n'a qu'un angle a changer (attributs `Cote`,
		-- `Ouvert`, `Ferme`, en degres). Construites ouvertes. (Les anciennes
		-- bandes plates faisaient des rectangles noirs, vu par Josh.)
		do
			local lids = folder(m, SKY.lids)
			local look = CFrame.lookAt(eyeAt, eyeAt - Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))
			local shell = 123
			local skinFar = Color3.fromRGB(58, 26, 24)
			local skinNear = Color3.fromRGB(96, 44, 38)
			for _, side in { 1, -1 } do
				local lid = model(lids, if side == 1 then "PaupiereHaut" else "PaupiereBas")
				local openDeg = if side == 1 then 34 else -26
				lid:SetAttribute("Cote", side)
				lid:SetAttribute("Ouvert", openDeg)
				lid:SetAttribute("Ferme", 0)
				local reach = if side == 1 then 104 else 96
				local stepA, stepB = 6, 8.5
				-- La coque, plaque par plaque, construite fermee (le bord sur l'axe
				-- de la pupille), puis tournee jusqu'a l'ouverture.
				for aDeg = 0, reach - stepA, stepA do
					for bDeg = -85, 85 - stepB, stepB do
						local alpha = math.rad((aDeg + stepA / 2) * side)
						local beta = math.rad(bDeg + stepB / 2)
						local cf = look
							* CFrame.Angles(0, beta, 0)
							* CFrame.Angles(alpha, 0, 0)
							* CFrame.new(0, 0, -shell)
						local width = shell * math.rad(stepB) * math.abs(math.cos(alpha)) * 1.25
							+ 1.5
						local height = shell * math.rad(stepA) * 1.2
						local t = math.clamp(aDeg / reach, 0, 1)
						local plate = P(
							lid,
							"Peau",
							Vector3.new(width, height, 1.6),
							cf,
							Enum.Material.Slate,
							skinNear:Lerp(skinFar, t),
							noRay
						)
						_ = plate
						-- Quelques veines sur la peau, pres du bord.
						if aDeg < 30 and random:NextNumber() < 0.18 then
							P(
								lid,
								"VeinePaupiere",
								Vector3.new(width * random:NextNumber(0.5, 1), 0.6, 0.4),
								cf
									* CFrame.new(
										0,
										random:NextNumber(-height / 3, height / 3),
										-0.9
									)
									* CFrame.Angles(0, 0, random:NextNumber(-0.6, 0.6)),
								Enum.Material.SmoothPlastic,
								Color3.fromRGB(110, 26, 22),
								noRay
							)
						end
					end
				end
				-- Le bord : un bourrelet humide, une braise dessous, des cils.
				for bDeg = -84, 84, 4 do
					local beta = math.rad(bDeg)
					local a0 = look * CFrame.Angles(0, beta, 0) * CFrame.new(0, 0, -(shell + 1.2))
					local a1 = look
						* CFrame.Angles(0, math.rad(bDeg + 4), 0)
						* CFrame.new(0, 0, -(shell + 1.2))
					local mid = (a0.Position + a1.Position) / 2
					local len = (a1.Position - a0.Position).Magnitude + 0.6
					-- Le bourrelet s'amincit vers les coins de l'oeil.
					local thick = 4.2 * (1 - (math.abs(bDeg) / 90) ^ 2) + 1.2
					P(
						lid,
						"Bord",
						Vector3.new(len, thick, thick),
						CFrame.lookAt(mid, a1.Position) * CFrame.Angles(0, math.rad(90), 0),
						Enum.Material.SmoothPlastic,
						Color3.fromRGB(72, 16, 16),
						{
							shape = Enum.PartType.Cylinder,
							collide = false,
							query = false,
							shadow = false,
						}
					)
					local ember = P(
						lid,
						"Braise",
						Vector3.new(len, 0.8, 0.8),
						CFrame.lookAt(mid, a1.Position)
							* CFrame.Angles(0, math.rad(90), 0)
							* CFrame.new(0, -side * thick * 0.35, 0),
						Enum.Material.Neon,
						Color3.fromRGB(150, 38, 18),
						{
							shape = Enum.PartType.Cylinder,
							collide = false,
							query = false,
							shadow = false,
						}
					)
					ember.Transparency = 0.25
					-- Des cils, longs et irreguliers, tournes vers le dehors.
					for _ = 1, 2 do
						local base = look
							* CFrame.Angles(0, beta + math.rad(random:NextNumber(0, 4)), 0)
							* CFrame.new(0, 0, -(shell + 2))
						local out = (base.LookVector * 0.75 - base.UpVector * side * 0.65).Unit
						local length = random:NextNumber(8, 20) * (1 - (math.abs(bDeg) / 100) ^ 2)
						local tip = base.Position + out * length
						P(
							lid,
							"Cil",
							Vector3.new(0.45, 0.45, length),
							CFrame.lookAt((base.Position + tip) / 2, tip),
							Enum.Material.SmoothPlastic,
							Color3.fromRGB(14, 8, 8),
							noRay
						)
					end
				end
				lid.WorldPivot = look
				lid:PivotTo(look * CFrame.Angles(math.rad(openDeg), 0, 0))
			end
		end

		-- LA CHAIR autour de l'Oeil, la ou il sort de la dechirure : un
		-- bourrelet gonfle, sombre, veine de braise. Sans elle, le globe
		-- traversait une plaque noire a angle vif.
		do
			-- L'orbite : de la chair qui descend du bord de la dechirure jusqu'au
			-- globe, en anneaux de bourrelets serres qui se chevauchent. Sans elle,
			-- un vide noir separait l'anneau du globe (vu a l'ecran).
			local section = math.sqrt(math.max(radius * radius - (eyeAt.Y - riftY) ^ 2, 0))
			for ring = 0, 4 do
				local t = ring / 4
				for i = 0, 71 do
					local a = i / 72 * math.pi * 2 + ring * 0.04
					local rim = almond(a, random:NextNumber(0, 6))
					-- Du bord du trou jusqu'a la section du globe, en s'enfoncant.
					local toward =
						Vector3.new(math.cos(a) * (section + 4), riftY, math.sin(a) * (section + 4))
					local p = rim:Lerp(toward, t * 0.95)
					local nextP = almond(a + 0.1, 3):Lerp(
						Vector3.new(
							math.cos(a + 0.1) * (section + 4),
							riftY,
							math.sin(a + 0.1) * (section + 4)
						),
						t * 0.95
					)
					local long = random:NextNumber(22, 34) * (1 - t * 0.4)
					local y = riftY - 4 - t * 16 + random:NextNumber(-2, 2)
					local lump = P(
						m,
						"Chair",
						Vector3.new(
							long,
							random:NextNumber(10, 16),
							random:NextNumber(14, 22) * (1 - t * 0.3)
						),
						CFrame.lookAt(Vector3.new(p.X, y, p.Z), Vector3.new(nextP.X, y, nextP.Z))
							* CFrame.Angles(0, math.rad(90), random:NextNumber(-0.25, 0.25)),
						Enum.Material.Slate,
						Color3.fromRGB(
							84 - ring * 6 + random:NextInteger(-8, 8),
							32 - ring * 2,
							28 - ring * 2
						),
						noRay
					)
					local shape = Instance.new("SpecialMesh")
					shape.MeshType = Enum.MeshType.Sphere
					shape.Parent = lump
					if random:NextNumber() < 0.2 then
						P(
							m,
							"VeineChair",
							Vector3.new(random:NextNumber(8, 16), 0.7, 0.7),
							CFrame.new(p.X, y - 6, p.Z)
								* CFrame.Angles(0, random:NextNumber(0, 6), 0),
							Enum.Material.Neon,
							Color3.fromRGB(140, 34, 18),
							noRay
						)
					end
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

	-- Les matieres generees (docs/ASSETS.md) remplacent les matieres de base
	-- dans toute la place : MaterialService est un reglage de place, la
	-- recette le pose elle-meme. Sans les variantes, rien ne change.
	local function applyMaterials()
		local MaterialService = game:GetService("MaterialService")
		local overrides = {
			RoyaleAsphalte = Enum.Material.Asphalt,
			RoyaleBeton = Enum.Material.Concrete,
			RoyaleBrique = Enum.Material.Brick,
			-- Pas le bois : la variante generee assombrissait trop les murs et les
			-- planchers des interieurs (vu a l'ecran) ; le bois de Roblox est
			-- plus clair et bien texture.
		}
		for _, v in MaterialService:GetDescendants() do
			if v:IsA("MaterialVariant") and overrides[v.Name] then
				MaterialService:SetBaseMaterialOverride(overrides[v.Name], v.Name)
			end
		end
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
		buildCracks = buildCracks,
		buildLighting = buildLighting,
		applyMaterials = applyMaterials,
		EYE_HEIGHT = EYE_HEIGHT,
		SKY = SKY,
	}
end
