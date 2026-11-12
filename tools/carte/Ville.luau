--!strict
--[[
	Ville — les pieces d'une ville abandonnee : arbres, haies, clotures,
	lampadaires, voitures, gravats, maisons (avec leurs interieurs, leurs
	toits que l'Oeil arrache, leurs mots sur les murs) et les modeles des
	cachettes fragiles.

	Reprises de la recette de Survivor (tools/BuildBanlieue.luau), ou elles
	ont ete reglees avec Josh et verifiees a l'ecran. Les modeles generes
	(arbre, voitures) se lisent dans ServerStorage.RoyaleModeles
	(docs/ASSETS.md) ; sans eux, les pieces se construisent en parts.
]]

local ServerStorage = game:GetService("ServerStorage")

return function(O: any, CONTRACT: any)
	local C = O.C
	local CAR_COLORS = O.CAR_COLORS
	local P = O.P
	local model = O.model
	local marker = O.marker
	local triangle = O.triangle
	local wall = O.wall
	local slab = O.slab
	local random = O.random

	local library = ServerStorage:FindFirstChild("RoyaleModeles")
	-- Les feuillus du magasin (docs/ASSETS.md), trois essences ; a defaut,
	-- l'arbre genere de Survivor (plus pale, plus geometrique).
	local treeTemplates: { Model } = {}
	for _, name in { "Feuillu1", "Feuillu2", "Feuillu3" } do
		local found = library and library:FindFirstChild(name)
		if found and found:IsA("Model") then
			table.insert(treeTemplates, found)
		end
	end
	if #treeTemplates == 0 then
		local template = library and library:FindFirstChild("Arbre")
		if template and template:IsA("Model") then
			table.insert(treeTemplates, template)
		end
	end
	local treeTemplate: Model? = treeTemplates[1]
	local deadTemplates: { Model } = {}
	for _, name in { "Mort1", "Mort2" } do
		local found = library and library:FindFirstChild(name)
		if found and found:IsA("Model") then
			table.insert(deadTemplates, found)
		end
	end
	local carTemplates: { Model } = {}
	-- Les epaves du magasin (docs/ASSETS.md) d'abord ; a defaut, les
	-- voitures generees de Survivor.
	for _, name in { "Epave1", "Epave2", "Epave3", "Epave4" } do
		local carModel = library and library:FindFirstChild(name)
		if carModel and carModel:IsA("Model") then
			table.insert(carTemplates, carModel)
		end
	end
	for _, name in (if #carTemplates > 0 then {} else { "Voiture1", "Voiture2" }) :: { string } do
		local carModel = library and library:FindFirstChild(name)
		if carModel and carModel:IsA("Model") then
			table.insert(carTemplates, carModel)
		end
	end

	-- Le modele d'arbre genere (docs/ASSETS.md), s'il est dans la place.
	local generatedTrees = 0

	local function tree(parent: Instance, position: Vector3, dead: boolean)
		-- Les arbres morts du magasin s'ils sont la (le tronc en blocs de
		-- Survivor faisait un baton geometrique, vu a l'ecran).
		local pool = if dead then deadTemplates else treeTemplates
		if #pool > 0 and (dead or treeTemplate) then
			local clone = pool[random:NextInteger(1, #pool)]:Clone()
			clone.Name = "Arbre"
			-- ScaleTo est absolu (par rapport au modele d'origine) : on multiplie
			-- l'echelle deja reglee du modele, sinon les arbres du magasin
			-- devenaient geants (vu a l'ecran le 12 novembre 2026).
			clone:ScaleTo(clone:GetScale() * random:NextNumber(0.9, 1.3))
			local size = clone:GetExtentsSize()
			-- On pose le bas de l'arbre au sol, quel que soit son pivot : les
			-- modeles du magasin flottaient, racines en l'air.
			clone:PivotTo(
				CFrame.new(position) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
			)
			local box, boxSize = clone:GetBoundingBox()
			local bottom = box.Position.Y - boxSize.Y / 2
			clone:PivotTo(clone:GetPivot() + Vector3.new(0, position.Y - bottom - 0.4, 0))
			for _, part in clone:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
					-- Le feuillage ne bloque pas les joueurs et ne couvre qu'a
					-- moitie vu du ciel ; le tronc, lui, est une part a part.
					part.CanCollide = false
					part:SetAttribute(CONTRACT.cover, 0.55)
				end
			end
			clone.Parent = parent
			P(
				clone,
				"Tronc",
				Vector3.new(size.Y * 0.45, 1.6, 1.6),
				CFrame.new(position + Vector3.new(0, size.Y * 0.225, 0))
					* CFrame.Angles(0, 0, math.rad(90)),
				Enum.Material.Wood,
				C.bark,
				{
					shape = Enum.PartType.Cylinder,
					transparency = 1,
					shadow = false,
				}
			)
			generatedTrees += 1
			return
		end
		local m = model(parent, "Arbre")
		local height = random:NextNumber(14, 20)
		-- Un cylindre prend sa longueur sur X : on le redresse.
		P(
			m,
			"Tronc",
			Vector3.new(height, 1.6, 1.6),
			CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.Wood,
			C.bark,
			{ shape = Enum.PartType.Cylinder }
		)
		if dead then
			for i = 1, 4 do
				local yaw = math.rad(i * 90 + random:NextNumber(-20, 20))
				local branch = Vector3.new(math.cos(yaw), 0.8, math.sin(yaw)).Unit
				local start = position + Vector3.new(0, height * random:NextNumber(0.55, 0.85), 0)
				slab(m, start, start + branch * 6, 0.6, 0.6, Enum.Material.Wood, C.bark, "Branche")
			end
			return
		end
		local color = if random:NextNumber() < 0.4 then C.leavesDry else C.leaves
		for i = 1, 5 do
			local size = random:NextNumber(7, 11)
			local offset = Vector3.new(
				random:NextNumber(-3, 3),
				random:NextNumber(-1.5, 2.5),
				random:NextNumber(-3, 3)
			)
			if i == 1 then
				offset = Vector3.zero
			end
			-- Un Ball est une sphere du plus petit cote : taille cubique.
			P(
				m,
				"Feuillage",
				Vector3.new(size, size, size),
				CFrame.new(position + Vector3.new(0, height, 0) + offset),
				Enum.Material.LeafyGrass,
				color,
				{ shape = Enum.PartType.Ball, collide = false, cover = 0.55 }
			)
		end
	end

	local function hedge(parent: Instance, from: Vector3, to: Vector3)
		local length = (to - from).Magnitude
		P(
			parent,
			"Haie",
			Vector3.new(2.6, 3.6, length),
			CFrame.lookAt((from + to) / 2 + Vector3.new(0, 1.8, 0), to + Vector3.new(0, 1.8, 0)),
			Enum.Material.LeafyGrass,
			C.hedge,
			{ cover = 0.5 }
		)
	end

	local function fence(parent: Instance, from: Vector3, to: Vector3, height: number)
		local length = (to - from).Magnitude
		local dir = (to - from).Unit
		local cf = CFrame.lookAt(from, to)
		local posts = math.max(2, math.floor(length / 8) + 1)
		for i = 0, posts - 1 do
			local at = from + dir * (length * i / (posts - 1))
			P(
				parent,
				"Poteau",
				Vector3.new(0.6, height + 0.6, 0.6),
				CFrame.new(at + Vector3.new(0, (height + 0.6) / 2, 0)),
				Enum.Material.Wood,
				C.woodGray
			)
		end
		-- Des planches verticales serrees : on ne voit pas au travers.
		P(
			parent,
			"Palissade",
			Vector3.new(0.3, height, length),
			cf * CFrame.new(0, height / 2, -length / 2),
			Enum.Material.WoodPlanks,
			C.woodGray
		)
	end

	local function lamp(parent: Instance, position: Vector3, facing: Vector3)
		local m = model(parent, "Lampadaire")
		P(
			m,
			"Mat",
			Vector3.new(14, 0.7, 0.7),
			CFrame.new(position + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.Metal,
			C.metal,
			{ shape = Enum.PartType.Cylinder }
		)
		local arm = position + Vector3.new(0, 14, 0)
		slab(m, arm, arm + facing * 3.5, 0.5, 0.5, Enum.Material.Metal, C.metal, "Bras")
		local head = P(
			m,
			"Tete",
			Vector3.new(1.6, 0.6, 2.4),
			CFrame.lookAt(
				arm + facing * 3.8 - Vector3.new(0, 0.3, 0),
				arm + facing * 8 - Vector3.new(0, 0.3, 0)
			),
			Enum.Material.Metal,
			C.metal
		)
		-- Eteint : il n'y a plus de courant. Un seul, au carrefour, clignote
		-- faiblement (pose par l'appelant).
		return head
	end

	-- Une voiture, le long de son Z local. Rend le modele et le point de la
	-- cabine (pour se cacher dedans).
	-- Les modeles de voitures generees (docs/ASSETS.md), s'ils sont dans la place.
	local generatedCars = 0

	local function car(
		parent: Instance,
		cf: CFrame,
		color: Color3,
		wrecked: boolean
	): (Model, CFrame)
		if #carTemplates > 0 then
			local clone = carTemplates[random:NextInteger(1, #carTemplates)]:Clone()
			clone.Name = "Voiture"
			local size = clone:GetExtentsSize()
			local tilt = if wrecked
				then CFrame.Angles(
					math.rad(random:NextNumber(-2, 2)),
					0,
					math.rad(random:NextNumber(2, 5))
				)
				else CFrame.identity
			clone:PivotTo(cf * tilt * CFrame.new(0, size.Y / 2, 0))
			for _, part in clone:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
			clone.Parent = parent
			generatedCars += 1
			return clone, cf * CFrame.new(0, size.Y * 0.5, 0)
		end
		local m = model(parent, "Voiture")
		local tilt = if wrecked
			then CFrame.Angles(
				math.rad(random:NextNumber(-2, 2)),
				0,
				math.rad(random:NextNumber(2, 5))
			)
			else CFrame.identity
		local base = cf * tilt
		local paint = if wrecked then color:Lerp(C.rust, 0.45) else color
		P(
			m,
			"Carrosserie",
			Vector3.new(6.2, 2.1, 14),
			base * CFrame.new(0, 1.75, 0),
			Enum.Material.SmoothPlastic,
			paint
		)
		P(
			m,
			"Capot",
			Vector3.new(6.0, 0.5, 4.2),
			base * CFrame.new(0, 2.95, -4.6),
			Enum.Material.SmoothPlastic,
			paint
		)
		P(
			m,
			"Coffre",
			Vector3.new(6.0, 0.5, 3.0),
			base * CFrame.new(0, 2.95, 5.2),
			Enum.Material.SmoothPlastic,
			paint
		)
		P(
			m,
			"Toit",
			Vector3.new(5.6, 0.4, 6.0),
			base * CFrame.new(0, 4.75, 0.4),
			Enum.Material.SmoothPlastic,
			paint
		)
		-- Cabine vitree, sombre.
		P(
			m,
			"Vitres",
			Vector3.new(5.5, 1.6, 6.6),
			base * CFrame.new(0, 3.75, 0.4),
			Enum.Material.Glass,
			Color3.fromRGB(40, 46, 52),
			{ transparency = if wrecked then 0.75 else 0.35 }
		)
		for _, side in { -1, 1 } do
			for _, front in { -1, 1 } do
				if wrecked and side == 1 and front == 1 then
					continue
				end
				P(
					m,
					"Roue",
					Vector3.new(1.1, 2.5, 2.5),
					base * CFrame.new(side * 2.85, 1.25, front * 4.6),
					Enum.Material.SmoothPlastic,
					C.black,
					{ shape = Enum.PartType.Cylinder }
				)
			end
			P(
				m,
				"Phare",
				Vector3.new(1.2, 0.5, 0.2),
				base * CFrame.new(side * 2.2, 2.3, -7.05),
				Enum.Material.Glass,
				C.trim
			)
			P(
				m,
				"Feu",
				Vector3.new(1.2, 0.5, 0.2),
				base * CFrame.new(side * 2.2, 2.3, 7.05),
				Enum.Material.Glass,
				Color3.fromRGB(120, 40, 36)
			)
		end
		P(
			m,
			"PareChoc",
			Vector3.new(6.4, 0.6, 0.5),
			base * CFrame.new(0, 1.0, -7.1),
			Enum.Material.Metal,
			C.metal
		)
		P(
			m,
			"PareChoc",
			Vector3.new(6.4, 0.6, 0.5),
			base * CFrame.new(0, 1.0, 7.1),
			Enum.Material.Metal,
			C.metal
		)
		return m, base * CFrame.new(0, 3.2, 0.4)
	end

	local function rubble(parent: Instance, center: Vector3, radius: number, count: number)
		for _ = 1, count do
			local angle = random:NextNumber(0, math.pi * 2)
			local dist = random:NextNumber(0, radius)
			local at = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
			local s = random:NextNumber(0.8, 2.6)
			local isWood = random:NextNumber() < 0.45
			P(
				parent,
				"Gravat",
				if isWood
					then Vector3.new(0.4, 0.4 * s, s * 2.2)
					else Vector3.new(s, s * 0.6, s * 0.9),
				CFrame.new(at + Vector3.new(0, s * 0.25, 0))
					* CFrame.Angles(
						random:NextNumber(-0.6, 0.6),
						random:NextNumber(0, math.pi),
						random:NextNumber(-0.6, 0.6)
					),
				if isWood then Enum.Material.WoodPlanks else Enum.Material.Concrete,
				if isWood then C.woodGray else C.concreteDark
			)
		end
	end

	--------------------------------------------------------------------------------
	-- Les maisons
	--------------------------------------------------------------------------------

	type HouseOptions = {
		name: string,
		siding: Color3,
		material: Enum.Material,
		roof: Color3,
		damage: string, -- "intact" | "trou" | "ruine"
		garage: boolean,
		-- 2 : une maison a etage. L'etage n'est pas accessible (pas d'escalier) :
		-- c'est la silhouette qui compte, la rue ne doit pas etre une rangee de
		-- bungalows identiques.
		storeys: number,
		-- La variete des interieurs : le plan en miroir (cuisine a gauche, salle
		-- de bain a droite), et une chambre a la place de la salle a manger.
		mirror: boolean,
		bedroom: boolean,
		-- Une maison qui raconte : "barricadee", "brulee", "mot", ou rien.
		story: string?,
	}

	type HouseResult = {
		inside: Vector3, -- un point du salon, pour la mesure de couverture
		kitchen: CFrame,
		bathroom: CFrame,
		garage: CFrame?,
	}

	local HOUSE_W, HOUSE_D, WALL_H, FLOOR_Y, THICK = 26, 22, 10, 0.6, 0.8

	-- Ce que l'Oeil arrache quand il vient chercher ceux qui s'abritent dans un
	-- batiment : les toits, les plafonds, et tout ce qui est au-dessus du
	-- rez-de-chaussee. Le serveur les retrouve par l'attribut.
	local ROOF_NAMES = {
		Toit = true,
		Plafond = true,
		PlafondRez = true,
		Pignon = true,
		Cheminee = true,
		Gouttiere = true,
		Chevron = true,
	}

	-- Les mots laisses sur les murs. Pas d'explication : des bribes.
	local NOTES = {
		"Ne restez jamais deux fois sous le même toit. Il s'en souvient.",
		"Maman est montée. Elle souriait en montant.",
		"Ils dorment dans les maisons. Ne courez pas.",
		"Le ciel rougit avant. Toujours avant.",
		"On a entendu frapper à la cave toute la nuit. De l'intérieur.",
		"La radio parle encore, parfois. Une voix, vers l'ouest.",
		"Si tu lis ça, prends les conserves. On n'en aura plus besoin.",
	}

	-- Ce que l'aspiration emporte de l'interieur en meme temps que le toit.
	local LOOSE_NAMES = {
		Chaise = true,
		Papier = true,
		Tapis = true,
		Oreiller = true,
		Fauteuil = true,
		Lampadaire = true,
		Tele = true,
		Cadre = false,
		Banc = true,
		Produit = true,
	}

	local function tagBuilding(m: Model, groundY: number)
		local covered = false
		for _, part in m:GetDescendants() do
			if part:IsA("BasePart") then
				local bottom = part.Position.Y - part.Size.Y / 2
				-- Avec le toit partent aussi les linteaux et tout ce qui est au-dessus
				-- des fenetres : le haut des murs est dechiquete, pas tranche net.
				if ROOF_NAMES[part.Name] or bottom >= groundY + FLOOR_Y + 7 then
					part:SetAttribute(CONTRACT.roof, true)
					covered = true
				elseif LOOSE_NAMES[part.Name] then
					part:SetAttribute(CONTRACT.loose, true)
				end
			end
		end
		-- Une ruine sans toit n'abrite personne : ce n'est pas un batiment pour
		-- l'Oeil.
		if covered then
			m:SetAttribute(CONTRACT.building, true)
		end
	end

	-- `cf` : le milieu du bas de la facade, l'axe Z local entrant dans la maison.
	local function house(
		parent: Instance,
		cf: CFrame,
		o: HouseOptions,
		containers: Instance
	): HouseResult
		local m = model(parent, o.name)
		local w, d = HOUSE_W, HOUSE_D
		local tall = o.storeys == 2
		local h = if tall then WALL_H * 1.8 else WALL_H
		local upperB, upperT = WALL_H + 2.2, WALL_H + 6.4
		local floorCf = cf * CFrame.new(0, FLOOR_Y, 0)
		-- Le miroir ne touche que l'interieur : la porte d'entree reste face a son
		-- allee.
		local mx = if o.mirror then -1 else 1
		local function mirror(c: CFrame): CFrame
			if mx == 1 then
				return c
			end
			return CFrame.new(-c.X, c.Y, c.Z) * (c - c.Position)
		end

		P(
			m,
			"Fondation",
			Vector3.new(w + 0.4, FLOOR_Y + 1, d + 0.4),
			cf * CFrame.new(0, (FLOOR_Y - 1) / 2, d / 2),
			Enum.Material.Concrete,
			C.concreteDark
		)
		P(
			m,
			"Plancher",
			Vector3.new(w - 1, 0.2, d - 1),
			floorCf * CFrame.new(0, 0.1, d / 2),
			Enum.Material.WoodPlanks,
			C.wood
		)

		-- Facade : porte, deux fenetres (et deux a l'etage).
		local frontOpenings: { Opening } = {
			{ x = -2.5, w = 4, b = 0, t = 7.5, kind = "door" },
			{ x = 6.5, w = 5, b = 3, t = 7.2, kind = "window" },
			{ x = -9.5, w = 4, b = 3, t = 7.2, kind = "window" },
		}
		local backOpenings: { Opening } = {
			{ x = 3 * mx, w = 3.6, b = 0, t = 7.5, kind = "door" },
			{ x = -6 * mx, w = 4, b = 3.5, t = 7, kind = "window" },
		}
		-- Le mur se construit par etage : deux rangees d'ouvertures qui se
		-- chevauchent en largeur casseraient le decoupage d'un mur d'un seul tenant.
		wall(
			m,
			floorCf * CFrame.new(0, 0, THICK / 2),
			w,
			WALL_H,
			THICK,
			frontOpenings,
			o.material,
			o.siding
		)
		wall(
			m,
			floorCf * CFrame.new(0, 0, d - THICK / 2),
			w,
			WALL_H,
			THICK,
			backOpenings,
			o.material,
			o.siding
		)
		if tall then
			local up = h - WALL_H
			local b, t = upperB - WALL_H, upperT - WALL_H
			wall(m, floorCf * CFrame.new(0, WALL_H, THICK / 2), w, up, THICK, {
				{ x = -7, w = 4, b = b, t = t, kind = "window" },
				{ x = 6, w = 4, b = b, t = t, kind = "window" },
			}, o.material, o.siding)
			wall(m, floorCf * CFrame.new(0, WALL_H, d - THICK / 2), w, up, THICK, {
				{ x = 0, w = 4, b = b, t = t, kind = "window" },
			}, o.material, o.siding)
			for _, side in { -1, 1 } do
				wall(
					m,
					floorCf
						* CFrame.new(side * (w / 2 - THICK / 2), WALL_H, d / 2)
						* CFrame.Angles(0, math.rad(90), 0),
					d - THICK * 2,
					up,
					THICK,
					{ { x = 0, w = 4, b = b, t = t, kind = "window" } },
					o.material,
					o.siding
				)
			end
		end
		-- Cotes.
		for _, side in { -1, 1 } do
			wall(
				m,
				floorCf
					* CFrame.new(side * (w / 2 - THICK / 2), 0, d / 2)
					* CFrame.Angles(0, math.rad(90), 0),
				d - THICK * 2,
				WALL_H,
				THICK,
				{ { x = 0, w = 4, b = 3, t = 7, kind = "window" } },
				o.material,
				o.siding
			)
		end
		-- Cloison : la salle de bain au fond a gauche.
		wall(m, floorCf * CFrame.new((-w / 4 - 0.5) * mx, 0, d - 8), w / 2 - 1, WALL_H, 0.5, {
			{ x = 2 * mx, w = 3.4, b = 0, t = 7.4, kind = "door" },
		}, Enum.Material.SmoothPlastic, C.plaster)

		-- Le seuil et la marche devant la porte.
		P(
			m,
			"Marche",
			Vector3.new(5, 0.6, 2.4),
			cf * CFrame.new(-2.5, 0.3, -1.2),
			Enum.Material.Concrete,
			C.concrete
		)
		-- La porte, entrouverte contre le mur.
		P(
			m,
			"Porte",
			Vector3.new(3.8, 7.3, 0.3),
			floorCf * CFrame.new(-4.5, 3.65, 1.9) * CFrame.Angles(0, math.rad(80), 0),
			Enum.Material.WoodPlanks,
			o.siding:Lerp(C.wood, 0.6)
		)

		-- Meubles : un canape, une table, une chaise renversee.
		P(
			m,
			"Canape",
			Vector3.new(7, 2.4, 2.6),
			floorCf * CFrame.new(5 * mx, 1.2, 9),
			Enum.Material.Fabric,
			C.fabric
		)
		if o.bedroom then
			-- Une chambre : un lit defait et une armoire a fouiller.
			P(
				m,
				"Lit",
				Vector3.new(4.4, 1.6, 7),
				floorCf * mirror(CFrame.new(-8, 0.8, 6)),
				Enum.Material.Fabric,
				C.fabric:Lerp(C.trim, 0.3)
			)
			P(
				m,
				"Oreiller",
				Vector3.new(3, 0.5, 1.2),
				floorCf * mirror(CFrame.new(-8, 1.85, 3.2)),
				Enum.Material.Fabric,
				C.trim
			)
			local wardrobe = P(
				containers,
				o.name .. "_Armoire",
				Vector3.new(1.6, 6, 4),
				floorCf * mirror(CFrame.new(-w / 2 + 1.6, 3, 10)),
				Enum.Material.WoodPlanks,
				C.wood
			)
			wardrobe:SetAttribute("Table", "chambre")
		else
			P(
				m,
				"Table",
				Vector3.new(4, 2.6, 2.6),
				floorCf * CFrame.new(-6 * mx, 1.3, 6),
				Enum.Material.WoodPlanks,
				C.wood
			)
			P(
				m,
				"Chaise",
				Vector3.new(1.6, 2.8, 1.6),
				floorCf
					* CFrame.new(-3.5 * mx, 0.8, 8)
					* CFrame.Angles(math.rad(85), math.rad(30), 0),
				Enum.Material.WoodPlanks,
				C.wood
			)
		end

		-- Les contenants a fouiller (le serveur y pose les invites).
		local kitchenCf = floorCf * CFrame.new((w / 2 - 3.2) * mx, 1.5, d - 1.6)
		local kitchen = P(
			containers,
			o.name .. "_Cuisine",
			Vector3.new(4.6, 3, 1.8),
			kitchenCf,
			Enum.Material.WoodPlanks,
			C.trim:Lerp(C.wood, 0.3)
		)
		kitchen:SetAttribute("Table", "cuisine")
		P(
			m,
			"Plan",
			Vector3.new(6, 0.25, 2.2),
			floorCf * CFrame.new((w / 2 - 4) * mx, 3.1, d - 1.7),
			Enum.Material.Granite,
			C.concrete
		)
		local bathCf = floorCf * CFrame.new((-w / 2 + 2.6) * mx, 4, d - 1.1)
		local bath = P(
			containers,
			o.name .. "_SalleDeBain",
			Vector3.new(2.6, 2.6, 0.9),
			bathCf,
			Enum.Material.SmoothPlastic,
			C.trim
		)
		bath:SetAttribute("Table", "salleDeBain")
		P(
			m,
			"Baignoire",
			Vector3.new(4.2, 2, 7),
			floorCf * CFrame.new((-w / 2 + 3) * mx, 1, d - 4.6),
			Enum.Material.SmoothPlastic,
			C.plaster
		)

		-- L'interieur : la cuisine, le salon, la salle de bain. Un decor qu'on a
		-- quitte en courant.
		local furniture = {
			{
				"Frigo",
				Vector3.new(2.6, 6.6, 2.4),
				CFrame.new(w / 2 - 1.8, 3.3, d - 6.2),
				Enum.Material.SmoothPlastic,
				C.trim,
			},
			{
				"Cuisiniere",
				Vector3.new(2.6, 3, 2.2),
				CFrame.new(w / 2 - 6.6, 1.5, d - 1.6),
				Enum.Material.Metal,
				C.metal,
			},
			{
				"Meuble",
				Vector3.new(6, 2.2, 1.6),
				CFrame.new(5, 1.1, 1.6),
				Enum.Material.WoodPlanks,
				C.wood,
			},
			{
				"Tele",
				Vector3.new(3.6, 2.2, 0.5),
				CFrame.new(5, 3.3, 1.6),
				Enum.Material.SmoothPlastic,
				C.black,
			},
			{
				"Tapis",
				Vector3.new(8, 0.1, 6),
				CFrame.new(4, 0.25, 6),
				Enum.Material.Fabric,
				Color3.fromRGB(102, 66, 58),
			},
			{
				"Fauteuil",
				Vector3.new(3, 2.6, 3),
				CFrame.new(9.5, 1.3, 6) * CFrame.Angles(0, math.rad(-70), 0),
				Enum.Material.Fabric,
				C.fabric:Lerp(C.sidingSage, 0.4),
			},
			{
				"Lavabo",
				Vector3.new(2.4, 3, 1.6),
				CFrame.new(-w / 2 + 6.5, 1.5, d - 1.3),
				Enum.Material.SmoothPlastic,
				C.plaster,
			},
			{
				"Toilettes",
				Vector3.new(1.6, 2.2, 2.4),
				CFrame.new(-4.4, 1.1, d - 1.6),
				Enum.Material.SmoothPlastic,
				C.plaster,
			},
			{
				"Cadre",
				Vector3.new(2.6, 2, 0.2),
				CFrame.new(-9, 6, d - 8.4),
				Enum.Material.WoodPlanks,
				C.wood,
			},
			{
				"Lampadaire",
				Vector3.new(0.4, 5.6, 0.4),
				CFrame.new(-11.5, 2.8, 2),
				Enum.Material.Metal,
				C.metal,
			},
		}
		for _, f in furniture do
			P(m, f[1], f[2], floorCf * mirror(f[3]), f[4], f[5])
		end
		-- Des papiers et des objets tombes par terre.
		for _ = 1, 6 do
			P(
				m,
				"Papier",
				Vector3.new(random:NextNumber(0.6, 1.4), 0.05, random:NextNumber(0.8, 1.6)),
				floorCf
					* CFrame.new(random:NextNumber(-10, 10), 0.24, random:NextNumber(2, d - 9))
					* CFrame.Angles(0, random:NextNumber(0, 6), 0),
				Enum.Material.SmoothPlastic,
				Color3.fromRGB(214, 208, 192),
				{ collide = false, query = false }
			)
		end
		if tall then
			-- Le plancher de l'etage : il couvre le rez-de-chaussee du ciel, et
			-- la seule facon de le savoir est de lever les yeux.
			P(
				m,
				"PlafondRez",
				Vector3.new(w - 1, 0.6, d - 1),
				floorCf * CFrame.new(0, WALL_H + 0.3, d / 2),
				Enum.Material.SmoothPlastic,
				C.plaster
			)
		end

		-- Plafond et toit, selon les degats.
		local top = FLOOR_Y + h
		if o.damage ~= "ruine" then
			if o.damage == "trou" then
				-- Le salon est a ciel ouvert : on y croit etre a l'abri, a tort.
				P(
					m,
					"Plafond",
					Vector3.new(w, 0.4, d * 0.45),
					cf * CFrame.new(0, top + 0.2, d * 0.775),
					Enum.Material.SmoothPlastic,
					C.plaster
				)
				rubble(m, (cf * CFrame.new(2, FLOOR_Y, 6)).Position, 5, 10)
			else
				P(
					m,
					"Plafond",
					Vector3.new(w, 0.4, d),
					cf * CFrame.new(0, top + 0.2, d / 2),
					Enum.Material.SmoothPlastic,
					C.plaster
				)
			end
			local ridgeH = 6.5
			local eaveFront = (cf * CFrame.new(0, top, -1.4)).Position
			local eaveBack = (cf * CFrame.new(0, top, d + 1.4)).Position
			local ridge = (cf * CFrame.new(0, top + ridgeH, d / 2)).Position
			if o.damage ~= "trou" then
				slab(m, eaveFront, ridge, w + 2.4, 0.6, Enum.Material.Slate, o.roof, "Toit")
			else
				-- Il reste quelques chevrons du pan arrache.
				for i = -2, 2 do
					local offset = (cf.RightVector * i * 5)
					slab(
						m,
						eaveFront + offset,
						ridge + offset,
						0.5,
						0.5,
						Enum.Material.Wood,
						C.wood,
						"Chevron"
					)
				end
			end
			slab(m, eaveBack, ridge, w + 2.4, 0.6, Enum.Material.Slate, o.roof, "Toit")
			for _, side in { -1, 1 } do
				local x = side * (w / 2 - THICK / 2)
				triangle(
					m,
					(cf * CFrame.new(x, top, 0)).Position,
					(cf * CFrame.new(x, top, d)).Position,
					(cf * CFrame.new(x, top + ridgeH, d / 2)).Position,
					THICK,
					o.material,
					o.siding
				)
			end
			-- Gouttieres le long des egouts.
			for _, eave in { eaveFront, eaveBack } do
				P(
					m,
					"Gouttiere",
					Vector3.new(w + 2.4, 0.5, 0.5),
					CFrame.new(eave - Vector3.new(0, 0.45, 0)) * (cf - cf.Position),
					Enum.Material.Metal,
					C.metal
				)
			end
			-- Cheminee.
			P(
				m,
				"Cheminee",
				Vector3.new(2.4, 6, 2.4),
				cf * CFrame.new(w / 2 - 5, top + 5, d * 0.7),
				Enum.Material.Brick,
				C.brickBrown
			)
		else
			rubble(m, (cf * CFrame.new(0, FLOOR_Y, d / 2)).Position, 9, 24)
		end

		-- Le porche : un petit auvent sur deux poteaux.
		if o.damage == "intact" then
			P(
				m,
				"Auvent",
				Vector3.new(7, 0.4, 4),
				cf * CFrame.new(-2.5, FLOOR_Y + 8.4, -2),
				Enum.Material.WoodPlanks,
				C.trim
			)
			for _, side in { -1, 1 } do
				P(
					m,
					"Poteau",
					Vector3.new(0.5, 8.2, 0.5),
					cf * CFrame.new(-2.5 + side * 3.1, 4.4, -3.6),
					Enum.Material.Wood,
					C.trim
				)
			end
		end

		local result: HouseResult = {
			inside = (cf * CFrame.new(5, FLOOR_Y + 3, 5)).Position,
			kitchen = kitchenCf,
			bathroom = bathCf,
			garage = nil,
		}

		if o.garage then
			local gx = w / 2 + 6.2
			local gcf = cf * CFrame.new(gx, 0, 2)
			local gm = model(m, "Garage")
			P(
				gm,
				"Dalle",
				Vector3.new(12, 0.6, 16),
				gcf * CFrame.new(0, 0.3, 8),
				Enum.Material.Concrete,
				C.concrete
			)
			wall(gm, gcf * CFrame.new(0, 0.6, 0.4), 12, 8, THICK, {
				{ x = 0, w = 9, b = 0, t = 6.6, kind = "garage" },
			}, o.material, o.siding)
			-- La porte basculante, coincee a mi-hauteur.
			P(
				gm,
				"PorteGarage",
				Vector3.new(9, 3.4, 0.3),
				gcf * CFrame.new(0, 5.5, 0.9),
				Enum.Material.Metal,
				C.trim
			)
			wall(gm, gcf * CFrame.new(0, 0.6, 15.6), 12, 8, THICK, {}, o.material, o.siding)
			wall(
				gm,
				gcf * CFrame.new(5.6, 0.6, 8) * CFrame.Angles(0, math.rad(90), 0),
				14.4,
				8,
				THICK,
				{},
				o.material,
				o.siding
			)
			P(
				gm,
				"Toit",
				Vector3.new(13, 0.6, 17),
				gcf * CFrame.new(0, 8.9, 8),
				Enum.Material.Slate,
				o.roof
			)
			local shelfCf = gcf * CFrame.new(0, 2.4, 14.6)
			local shelf = P(
				containers,
				o.name .. "_Garage",
				Vector3.new(7, 4.2, 1.6),
				shelfCf,
				Enum.Material.Metal,
				C.metal
			)
			shelf:SetAttribute("Table", "garage")
			P(
				gm,
				"Etabli",
				Vector3.new(4, 3, 2),
				gcf * CFrame.new(-3.5, 2.1, 12),
				Enum.Material.WoodPlanks,
				C.wood
			)
			result.garage = shelfCf
		end

		-- LES MAISONS QUI RACONTENT.
		if o.story == "barricadee" then
			-- Ceux d'ici se sont enfermes : planches sur la porte, meuble contre la
			-- porte du jardin. On entre par une fenetre.
			for i = -1, 1 do
				P(
					m,
					"Planche",
					Vector3.new(5, 0.8, 0.3),
					floorCf
						* CFrame.new(-2.5, 3.6 + i * 2, -0.25)
						* CFrame.Angles(0, 0, math.rad(i * 9)),
					Enum.Material.WoodPlanks,
					C.woodGray
				)
			end
			P(
				m,
				"Buffet",
				Vector3.new(5, 5, 1.8),
				floorCf * mirror(CFrame.new(3, 2.5, d - 2)),
				Enum.Material.WoodPlanks,
				C.wood
			)
		elseif o.story == "brulee" then
			-- Un feu, il y a longtemps : tout est noirci, et ca sent encore.
			for _, part in m:GetDescendants() do
				if part:IsA("BasePart") then
					part.Color = part.Color:Lerp(Color3.fromRGB(26, 24, 22), 0.75)
				end
			end
		elseif o.story == "mot" then
			local note = P(
				m,
				"Mot",
				Vector3.new(3.4, 2.4, 0.05),
				floorCf * mirror(CFrame.new(-7, 5.4, d - 8.3)),
				Enum.Material.SmoothPlastic,
				Color3.fromRGB(214, 206, 186),
				{ collide = false }
			)
			local surface = Instance.new("SurfaceGui")
			surface.Face = Enum.NormalId.Front
			surface.PixelsPerStud = 60
			surface.LightInfluence = 1
			surface.Parent = note
			local text = Instance.new("TextLabel")
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.TextWrapped = true
			text.TextScaled = true
			text.Font = Enum.Font.IndieFlower
			text.TextColor3 = Color3.fromRGB(40, 32, 28)
			text.Text = NOTES[random:NextInteger(1, #NOTES)]
			text.Parent = surface
		end

		tagBuilding(m, cf.Position.Y)
		return result
	end

	--------------------------------------------------------------------------------
	-- Les cachettes fragiles (modeles dans ServerStorage)
	--------------------------------------------------------------------------------

	-- Chaque modele a une part `Socle` invisible : c'est elle qui se pose sur
	-- l'emplacement (centre a y = 0,5 au-dessus du sol).
	local function prefabRoot(parent: Instance, name: string, footprint: Vector3): (Model, CFrame)
		local m = model(parent, name)
		local base = CFrame.new(0, 0.5, 0)
		local socle = P(
			m,
			"Socle",
			Vector3.new(footprint.X, 1, footprint.Z),
			base,
			Enum.Material.SmoothPlastic,
			C.black,
			{
				transparency = 1,
				collide = false,
				query = false,
				shadow = false,
			}
		)
		m.PrimaryPart = socle
		-- Le sol est a y = 0 : on construit depuis lui.
		return m, CFrame.new(0, 0, 0)
	end

	local function buildPrefabs(storage: Instance)
		-- L'abri de jardin : on se cache dedans.
		do
			local m, g = prefabRoot(storage, "Abri", Vector3.new(8, 1, 9))
			P(
				m,
				"Plancher",
				Vector3.new(7, 0.4, 8),
				g * CFrame.new(0, 0.2, 0),
				Enum.Material.WoodPlanks,
				C.woodGray
			)
			wall(
				m,
				g * CFrame.new(0, 0.4, -3.8),
				7,
				7,
				0.4,
				{ { x = 0, w = 3, b = 0, t = 6, kind = "door" } },
				Enum.Material.WoodPlanks,
				C.sidingSage:Lerp(C.woodGray, 0.5)
			)
			wall(
				m,
				g * CFrame.new(0, 0.4, 3.8),
				7,
				6,
				0.4,
				{},
				Enum.Material.WoodPlanks,
				C.sidingSage:Lerp(C.woodGray, 0.5)
			)
			for _, side in { -1, 1 } do
				wall(
					m,
					g * CFrame.new(side * 3.3, 0.4, 0) * CFrame.Angles(0, math.rad(90), 0),
					7.2,
					6.5,
					0.4,
					{},
					Enum.Material.WoodPlanks,
					C.sidingSage:Lerp(C.woodGray, 0.5)
				)
			end
			slab(
				m,
				Vector3.new(0, 7.6, -4.6),
				Vector3.new(0, 6.6, 4.6),
				8.4,
				0.4,
				Enum.Material.CorrodedMetal,
				C.metal,
				"Toit"
			)
			P(
				m,
				"PorteAbri",
				Vector3.new(2.9, 5.8, 0.25),
				g * CFrame.new(-2.4, 3.3, -5) * CFrame.Angles(0, math.rad(70), 0),
				Enum.Material.WoodPlanks,
				C.woodGray
			)
			marker(m, CONTRACT.inside, CFrame.new(0, 3, 1))
			marker(m, CONTRACT.exit, CFrame.new(0, 3, -6.5))
		end
		-- Les voitures : on se cache dans l'habitacle. Une variante par modele
		-- genere, pour que les rues ne soient pas pleines de la meme voiture.
		local all = carTemplates
		for variant = 1, math.max(#all, 1) do
			local name = if variant == 1 then "Voiture" else "Voiture" .. variant
			local m = prefabRoot(storage, name, Vector3.new(7, 1, 15))
			if #all > 0 then
				carTemplates = { all[variant] }
			end
			local color = CAR_COLORS[random:NextInteger(1, #CAR_COLORS)]
			local _, cabin = car(m, CFrame.new(0, 0, 0), color, false)
			-- Le modele de voiture est un sous-modele : on remonte ses parts.
			local sub = m:FindFirstChild("Voiture")
			if sub and sub ~= m then
				for _, child in sub:GetChildren() do
					child.Parent = m
				end
				sub:Destroy()
			end
			marker(m, CONTRACT.inside, cabin)
			-- Une portiere de chaque cote : on y entre (et on en ressort) par le
			-- cote ou l'on est (Josh : « que d'un cote, c'est un peu chiant »).
			marker(m, CONTRACT.exit, CFrame.new(5.2, 3, 0))
			marker(m, CONTRACT.exit, CFrame.new(-5.2, 3, 0))
		end
		carTemplates = all
		-- La benne : dedans, couvercle ferme.
		do
			local m, g = prefabRoot(storage, "Benne", Vector3.new(8.5, 1, 5.5))
			P(
				m,
				"Cuve",
				Vector3.new(8, 4.4, 5),
				g * CFrame.new(0, 2.5, 0),
				Enum.Material.Metal,
				Color3.fromRGB(58, 74, 60)
			)
			P(
				m,
				"Couvercle",
				Vector3.new(8.2, 0.3, 5.3),
				g * CFrame.new(0, 4.85, 0.1) * CFrame.Angles(math.rad(-4), 0, 0),
				Enum.Material.Plastic,
				C.black
			)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					P(
						m,
						"Roulette",
						Vector3.new(0.5, 0.8, 0.8),
						g * CFrame.new(sx * 3.4, 0.4, sz * 2),
						Enum.Material.SmoothPlastic,
						C.black,
						{ shape = Enum.PartType.Cylinder }
					)
				end
			end
			marker(m, CONTRACT.inside, CFrame.new(0, 2.2, 0))
			marker(m, CONTRACT.exit, CFrame.new(0, 3, -5))
		end
		-- Une pile de caisses creuse.
		do
			local m, g = prefabRoot(storage, "Caisses", Vector3.new(9, 1, 9))
			for layer = 0, 1 do
				for ix = -1, 1 do
					for iz = -1, 1 do
						if ix == 0 and iz == 0 and layer == 0 then
							continue
						end
						if ix == 0 and iz == -1 and layer == 0 then
							-- L'entree, devant.
							continue
						end
						P(
							m,
							"Caisse",
							Vector3.new(2.9, 2.9, 2.9),
							g
								* CFrame.new(ix * 3, 1.5 + layer * 3, iz * 3)
								* CFrame.Angles(0, math.rad(random:NextNumber(-6, 6)), 0),
							Enum.Material.WoodPlanks,
							C.wood:Lerp(C.woodGray, random:NextNumber(0, 0.6))
						)
					end
				end
			end
			P(
				m,
				"Bache",
				Vector3.new(9.6, 0.2, 9.6),
				g * CFrame.new(0, 6.2, 0) * CFrame.Angles(math.rad(3), 0, math.rad(-2)),
				Enum.Material.Fabric,
				Color3.fromRGB(62, 78, 92)
			)
			marker(m, CONTRACT.inside, CFrame.new(0, 2.4, 0))
			marker(m, CONTRACT.exit, CFrame.new(0, 3, -6))
		end
		-- Les petites cachettes de partout (Josh : « pas de petits recoins ») :
		-- un buisson touffu ou l'on se glisse, une tole appuyee contre un mur.
		do
			local m, g = prefabRoot(storage, "Buisson", Vector3.new(7, 1, 7))
			local leaf = Color3.fromRGB(56, 76, 42)
			-- Un Ball est une sphere du plus petit cote : tailles cubiques.
			local function ball(at: Vector3, size: number)
				P(
					m,
					"Feuillage",
					Vector3.new(size, size, size),
					g * CFrame.new(at),
					Enum.Material.LeafyGrass,
					leaf:Lerp(Color3.fromRGB(78, 96, 52), random:NextNumber(0, 1)),
					{ shape = Enum.PartType.Ball, collide = false, cover = 0.4 }
				)
			end
			for k = 0, 5 do
				local a = k * math.pi / 3 + random:NextNumber(-0.2, 0.2)
				ball(
					Vector3.new(math.cos(a) * 2.4, 1.9, math.sin(a) * 2.4),
					random:NextNumber(3.8, 4.6)
				)
			end
			for k = 0, 3 do
				local a = k * math.pi / 2 + 0.6
				ball(
					Vector3.new(math.cos(a) * 1.3, 3.9, math.sin(a) * 1.3),
					random:NextNumber(3.4, 4)
				)
			end
			ball(Vector3.new(0, 5.1, 0), 3.2)
			marker(m, CONTRACT.inside, CFrame.new(0, 2.2, 0))
			marker(m, CONTRACT.exit, CFrame.new(0, 3, -5))
		end
		do
			local m, g = prefabRoot(storage, "Tole", Vector3.new(8, 1, 6))
			-- Un panneau de planches derriere : la tole tient seule, contre un mur
			-- ou au milieu d'un champ.
			P(
				m,
				"Panneau",
				Vector3.new(7.6, 5.8, 0.4),
				g * CFrame.new(0, 2.9, 2.2),
				Enum.Material.WoodPlanks,
				C.woodGray
			)
			-- La tole : du sol (z = -2,6) au haut du panneau (z = 1,9, y = 5,6).
			-- Angle negatif autour de X : l'axe Z local monte vers +Z.
			local rise, run = 5.6, 4.5
			P(
				m,
				"Tole",
				Vector3.new(7.2, 0.2, math.sqrt(rise * rise + run * run)),
				g
					* CFrame.new(0, rise / 2, -2.6 + run / 2)
					* CFrame.Angles(-math.atan2(rise, run), 0, 0),
				Enum.Material.CorrodedMetal,
				C.metal
			)
			P(
				m,
				"Planche",
				Vector3.new(0.6, 0.3, 6),
				g * CFrame.new(3.2, 0.15, -0.6) * CFrame.Angles(0, math.rad(8), 0),
				Enum.Material.WoodPlanks,
				C.wood
			)
			marker(m, CONTRACT.inside, CFrame.new(0, 2.2, 0.6))
			marker(m, CONTRACT.exit, CFrame.new(0, 3, -5))
		end
	end

	--------------------------------------------------------------------------------

	return {
		tree = tree,
		hedge = hedge,
		fence = fence,
		lamp = lamp,
		car = car,
		rubble = rubble,
		house = house,
		tagBuilding = tagBuilding,
		buildPrefabs = buildPrefabs,
		HOUSE_W = HOUSE_W,
		HOUSE_D = HOUSE_D,
		generated = function(): (number, number)
			return generatedTrees, generatedCars
		end,
	}
end
