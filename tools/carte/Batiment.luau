--!strict
--[[
	Batiment — les grandes pieces que plusieurs zones partagent : un immeuble
	a etages perce de fenetres (lycee, hypermarche, gare), un hangar de tole,
	un conteneur, un wagon, des rails.

	Tout est construit avec les outils de Survivor (`wall`, `P`) : les
	fenetres ont leur encadrement, leurs vitres cassees ou condamnees, et les
	batiments sont marques pour que l'Oeil sache en arracher le toit.
]]

return function(O: any, V: any, _CONTRACT: any)
	local C, P = O.C, O.P
	local random: Random = O.random

	type BuildingOptions = {
		name: string,
		w: number,
		d: number,
		floors: number,
		floorH: number?,
		material: Enum.Material,
		color: Color3,
		-- "plat" | "pente" | "aspire" (le toit a moitie emporte par l'Oeil)
		roof: string,
		-- Pas de fenetre a moins de cette distance des coins.
		windowEvery: number?,
		doors: number?,
	}

	-- Les fenetres d'une facade, regulieres mais pas toutes pareilles : une
	-- sur cinq est condamnee ou sans vitre (c'est `wall` qui tire au sort).
	local function windowsFor(
		length: number,
		every: number,
		floorY: number,
		isGround: boolean,
		doors: number
	): { any }
		local openings = {}
		local count = math.max(1, math.floor((length - 6) / every))
		local start = -((count - 1) * every) / 2
		local doorSlots: { [number]: boolean } = {}
		if isGround then
			for k = 1, doors do
				doorSlots[math.clamp(math.floor(count * k / (doors + 1)) + 1, 1, count)] = true
			end
		end
		for k = 1, count do
			local x = start + (k - 1) * every
			if doorSlots[k] then
				table.insert(openings, { x = x, w = 6, b = floorY, t = floorY + 8, kind = "door" })
			else
				table.insert(
					openings,
					{ x = x, w = 4.5, b = floorY + 3, t = floorY + 8, kind = "window" }
				)
			end
		end
		return openings
	end

	-- Un immeuble : `cf` au milieu du bas de la facade, +Z entre dans le
	-- batiment. Rend le modele et un point a l'interieur du rez-de-chaussee.
	local function building(parent: Instance, cf: CFrame, o: BuildingOptions): (Model, Vector3)
		local m = O.model(parent, o.name)
		local fh = o.floorH or 12
		local h = fh * o.floors
		local every = o.windowEvery or 9
		local thick = 1
		P(
			m,
			"Fondation",
			Vector3.new(o.w + 1, 2, o.d + 1),
			cf * CFrame.new(0, -0.6, o.d / 2),
			Enum.Material.Concrete,
			C.concreteDark
		)
		-- Quatre facades, etage par etage (chaque etage a ses fenetres).
		local sides = {
			{ cf = cf * CFrame.new(0, 0, 0), len = o.w, front = true },
			{
				cf = cf * CFrame.new(0, 0, o.d) * CFrame.Angles(0, math.pi, 0),
				len = o.w,
				front = false,
			},
			{
				cf = cf * CFrame.new(-o.w / 2, 0, o.d / 2) * CFrame.Angles(0, math.rad(90), 0),
				len = o.d,
				front = false,
			},
			{
				cf = cf * CFrame.new(o.w / 2, 0, o.d / 2) * CFrame.Angles(0, math.rad(-90), 0),
				len = o.d,
				front = false,
			},
		}
		for _, side in sides do
			for f = 0, o.floors - 1 do
				local openings =
					windowsFor(side.len, every, 0, f == 0, if side.front then (o.doors or 1) else 0)
				O.wall(
					m,
					side.cf * CFrame.new(0, f * fh, 0),
					side.len,
					fh,
					thick,
					openings,
					o.material,
					o.color
				)
			end
		end
		-- Du lierre qui grimpe sur les facades : la nature reprend la ville
		-- depuis un an. Pas partout, et jamais de la meme taille.
		-- En touffes irregulieres (des rectangles plats ne trompaient
		-- personne, vu a l'ecran) : des feuilles serrees en bas, eparses en
		-- haut.
		for _, side in sides do
			for _ = 1, random:NextInteger(0, 2) do
				local cx = random:NextNumber(-side.len / 3, side.len / 3)
				local reach = random:NextNumber(5, math.max(6, h * 0.75))
				for k = 1, random:NextInteger(14, 24) do
					local up = random:NextNumber(0, 1) ^ 1.6 * reach
					local spread = 1.5 + (1 - up / reach) * 3
					local leaf = random:NextNumber(0.8, 2.2)
					P(
						m,
						"Lierre",
						Vector3.new(leaf * random:NextNumber(1, 1.8), leaf, 0.3),
						side.cf
							* CFrame.new(
								cx + random:NextNumber(-spread, spread),
								up + leaf / 2,
								-0.7 - k * 0.002
							)
							* CFrame.Angles(0, 0, random:NextNumber(-0.6, 0.6)),
						Enum.Material.LeafyGrass,
						Color3.fromRGB(
							58 + random:NextInteger(-8, 8),
							76 + random:NextInteger(-8, 8),
							46
						),
						{ collide = false, query = false, shadow = false }
					)
				end
			end
		end

		-- Les planchers et le plafond du dernier etage.
		for f = 0, o.floors do
			local name = if f == o.floors then "Toit" elseif f == 0 then "Sol" else "Plafond"
			if not (o.roof == "aspire" and f == o.floors) then
				P(
					m,
					name,
					Vector3.new(o.w - 0.4, 0.8, o.d - 0.4),
					cf * CFrame.new(0, f * fh + 0.4, o.d / 2),
					Enum.Material.Concrete,
					C.concrete
				)
			end
		end
		if o.roof == "aspire" then
			-- Le toit a moitie arrache : il reste des poutres et un bout de dalle.
			P(
				m,
				"Toit",
				Vector3.new(o.w - 0.4, 0.8, o.d * 0.35),
				cf * CFrame.new(0, h + 0.4, o.d * 0.18),
				Enum.Material.Concrete,
				C.concrete
			)
			for k = 1, math.floor(o.w / 8) do
				if random:NextNumber() < 0.6 then
					P(
						m,
						"Poutre",
						Vector3.new(1, 1.2, o.d * random:NextNumber(0.5, 1)),
						cf
							* CFrame.new(-o.w / 2 + k * 8, h + 0.6, o.d / 2)
							* CFrame.Angles(math.rad(random:NextNumber(-4, 4)), 0, 0),
						Enum.Material.Metal,
						C.rust
					)
				end
			end
		elseif o.roof == "pente" then
			O.slab(
				m,
				(cf * CFrame.new(-o.w / 2 - 1, h, -1)).Position,
				(cf * CFrame.new(-o.w / 2 - 1, h + 7, o.d / 2)).Position,
				o.w + 2,
				0.6,
				Enum.Material.Slate,
				C.roofSlate,
				"Toit"
			)
		else
			-- L'acrotere : le petit muret du toit plat.
			for _, s in sides do
				P(
					m,
					"Acrotere",
					Vector3.new(s.len, 1.4, 0.8),
					s.cf * CFrame.new(0, h + 1.4, 0),
					o.material,
					o.color
				)
			end
		end
		V.tagBuilding(m, cf.Position.Y)
		return m, (cf * CFrame.new(0, 3, o.d / 2)).Position
	end

	-- Un hangar de tole : murs de tole ondulee, grandes portes, toit a deux
	-- pentes avec des plaques manquantes.
	local function hangar(
		parent: Instance,
		cf: CFrame,
		w: number,
		d: number,
		h: number,
		name: string
	): Model
		local m = O.model(parent, name)
		-- Metal, pas CorrodedMetal : celui-ci impose sa couleur rouille et
		-- tout le port virait au rose (vu a l'ecran le 12 novembre 2026). La
		-- rouille reste pour les petites pieces.
		local metal = Color3.fromRGB(104, 108, 106)
		P(
			m,
			"Sol",
			Vector3.new(w, 0.6, d),
			cf * CFrame.new(0, 0.3, d / 2),
			Enum.Material.Concrete,
			C.concreteDark
		)
		-- Les cotes, perces de quelques fenetres hautes.
		for _, sx in { -1, 1 } do
			local openings = {}
			for k = -1, 1 do
				table.insert(
					openings,
					{ x = k * d / 3.2, w = 6, b = h - 6, t = h - 2.5, kind = "window" }
				)
			end
			O.wall(
				m,
				cf * CFrame.new(sx * w / 2, 0, d / 2) * CFrame.Angles(0, math.rad(90 * sx), 0),
				d,
				h,
				0.6,
				openings,
				Enum.Material.Metal,
				metal
			)
		end
		-- Le fond plein, l'avant avec une grande porte (parfois arrachee).
		O.wall(
			m,
			cf * CFrame.new(0, 0, d) * CFrame.Angles(0, math.pi, 0),
			w,
			h,
			0.6,
			{},
			Enum.Material.Metal,
			metal
		)
		local doorW = w * 0.45
		O.wall(
			m,
			cf,
			w,
			h,
			0.6,
			{ { x = 0, w = doorW, b = 0, t = h * 0.7, kind = "garage" } },
			Enum.Material.Metal,
			metal
		)
		if random:NextNumber() < 0.5 then
			P(
				m,
				"Porte",
				Vector3.new(doorW * 0.5, h * 0.7, 0.4),
				cf * CFrame.new(doorW * 0.55, h * 0.35, -1.5) * CFrame.Angles(0, math.rad(25), 0),
				Enum.Material.Metal,
				C.rust
			)
		end
		-- Le toit a deux pentes, plaque par plaque : certaines manquent.
		local ridge = h + w * 0.18
		local panels = math.floor(d / 6)
		for k = 0, panels - 1 do
			for _, sx in { -1, 1 } do
				if random:NextNumber() > 0.18 then
					local z = (k + 0.5) * (d / panels)
					O.slab(
						m,
						(cf * CFrame.new(sx * (w / 2 + 0.8), h, z)).Position,
						(cf * CFrame.new(0, ridge, z)).Position,
						d / panels - 0.1,
						0.4,
						Enum.Material.Metal,
						if random:NextNumber() < 0.3 then C.rust else metal,
						"Toit"
					)
				end
			end
		end
		V.tagBuilding(m, cf.Position.Y)
		return m
	end

	-- Un conteneur maritime. `open` : une porte battante ouverte (on y entre).
	local CONTAINER_COLORS = {
		Color3.fromRGB(124, 56, 44),
		Color3.fromRGB(52, 78, 98),
		Color3.fromRGB(70, 92, 66),
		Color3.fromRGB(150, 120, 60),
		Color3.fromRGB(112, 112, 108),
	}
	local function container(parent: Instance, cf: CFrame, open: boolean): Model
		local m = O.model(parent, "Conteneur")
		local color = CONTAINER_COLORS[random:NextInteger(1, #CONTAINER_COLORS)]
		local w, h, d = 8, 8.6, 24
		for _, sx in { -1, 1 } do
			P(
				m,
				"Flanc",
				Vector3.new(0.3, h, d),
				cf * CFrame.new(sx * w / 2, h / 2, 0),
				Enum.Material.Metal,
				color
			)
		end
		P(m, "Toit", Vector3.new(w, 0.3, d), cf * CFrame.new(0, h, 0), Enum.Material.Metal, color)
		P(
			m,
			"Plancher",
			Vector3.new(w, 0.4, d),
			cf * CFrame.new(0, 0.2, 0),
			Enum.Material.WoodPlanks,
			C.wood
		)
		P(
			m,
			"Fond",
			Vector3.new(w, h, 0.3),
			cf * CFrame.new(0, h / 2, -d / 2),
			Enum.Material.Metal,
			color
		)
		if open then
			P(
				m,
				"Porte",
				Vector3.new(w / 2, h - 0.4, 0.25),
				cf
					* CFrame.new(w / 2 + 1.6, h / 2, d / 2 + 1.8)
					* CFrame.Angles(0, math.rad(-70), 0),
				Enum.Material.Metal,
				color
			)
			P(
				m,
				"Porte",
				Vector3.new(w / 2, h - 0.4, 0.25),
				cf * CFrame.new(-w / 4, h / 2, d / 2),
				Enum.Material.Metal,
				color
			)
		else
			P(
				m,
				"Porte",
				Vector3.new(w, h - 0.4, 0.25),
				cf * CFrame.new(0, h / 2, d / 2),
				Enum.Material.Metal,
				color
			)
		end
		-- Les nervures : un conteneur se reconnait a elles.
		for k = -5, 5 do
			for _, sx in { -1, 1 } do
				P(
					m,
					"Nervure",
					Vector3.new(0.25, h - 0.6, 0.5),
					cf * CFrame.new(sx * (w / 2 + 0.15), h / 2, k * 2.1),
					Enum.Material.Metal,
					color:Lerp(Color3.new(0, 0, 0), 0.15)
				)
			end
		end
		return m
	end

	-- Des rails, du point a au point b (au sol), avec leurs traverses.
	local function rails(parent: Instance, a: Vector3, b: Vector3)
		local m = O.model(parent, "Voie")
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		P(
			m,
			"Ballast",
			Vector3.new(10, 1, len),
			cf * CFrame.new(0, 0.3, 0),
			Enum.Material.Pebble,
			Color3.fromRGB(96, 92, 86)
		)
		for _, sx in { -1, 1 } do
			P(
				m,
				"Rail",
				Vector3.new(0.5, 0.7, len),
				cf * CFrame.new(sx * 2.4, 1.3, 0),
				Enum.Material.Metal,
				C.rust
			)
		end
		for k = 0, math.floor(len / 2.6) do
			P(
				m,
				"Traverse",
				Vector3.new(7.2, 0.5, 1.2),
				cf * CFrame.new(0, 0.95, -len / 2 + k * 2.6),
				Enum.Material.Wood,
				C.woodGray
			)
		end
		return m
	end

	-- Un wagon de marchandises (couvert ou citerne), eventuellement couche.
	local function wagon(parent: Instance, cf: CFrame, tank: boolean, tipped: boolean): Model
		local m = O.model(parent, if tank then "Citerne" else "Wagon")
		local tilt = if tipped
			then CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(random:NextNumber(70, 95)))
			else CFrame.identity
		local base = cf * tilt
		local color = if tank then Color3.fromRGB(46, 48, 50) else Color3.fromRGB(112, 64, 48)
		P(
			m,
			"Chassis",
			Vector3.new(8, 1.2, 36),
			base * CFrame.new(0, 3.2, 0),
			Enum.Material.Metal,
			C.black
		)
		for _, z in { -13, 13 } do
			for _, sx in { -1, 1 } do
				P(
					m,
					"Roue",
					Vector3.new(0.8, 3, 3),
					base * CFrame.new(sx * 2.4, 1.7, z),
					Enum.Material.Metal,
					C.black,
					{ shape = Enum.PartType.Cylinder }
				)
			end
		end
		if tank then
			P(
				m,
				"Cuve",
				Vector3.new(32, 8, 8),
				base * CFrame.new(0, 8, 0) * CFrame.Angles(0, math.rad(90), 0),
				Enum.Material.Metal,
				color,
				{ shape = Enum.PartType.Cylinder }
			)
		else
			for _, sx in { -1, 1 } do
				O.wall(
					m,
					base * CFrame.new(sx * 4, 3.8, 0) * CFrame.Angles(0, math.rad(90), 0),
					36,
					8,
					0.4,
					{ { x = 0, w = 7, b = 0.2, t = 7.4, kind = "garage" } },
					Enum.Material.WoodPlanks,
					color
				)
			end
			for _, z in { -18, 18 } do
				P(
					m,
					"Bout",
					Vector3.new(8, 8, 0.4),
					base * CFrame.new(0, 7.8, z),
					Enum.Material.WoodPlanks,
					color
				)
			end
			P(
				m,
				"Toit",
				Vector3.new(8.6, 0.4, 36.6),
				base * CFrame.new(0, 12, 0),
				Enum.Material.Metal,
				C.rust
			)
			P(
				m,
				"Plancher",
				Vector3.new(7.6, 0.4, 35.6),
				base * CFrame.new(0, 4, 0),
				Enum.Material.WoodPlanks,
				C.wood
			)
		end
		return m
	end

	return {
		building = building,
		hangar = hangar,
		container = container,
		rails = rails,
		wagon = wagon,
	}
end
