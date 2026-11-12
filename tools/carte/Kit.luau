--!strict
--[[
	Kit — ce que chaque zone recoit pour se construire : les outils, les
	pieces de ville, le plan, les dossiers du contrat, et quelques gestes
	communs (lire le sol, poser une route qui suit le relief, reserver de la
	place, poser un emplacement de cachette ou un contenant a fouiller).

	Une zone ne pose jamais rien sans demander la place (`claim`) : sinon une
	maison finit sur une route, ou un arbre dans un salon.
]]

-- Le contrat de nommage avec le jeu (repris de Survivor, ou le jeu le lit
-- deja) : des dossiers sous Workspace.Carte et des attributs.
local CONTRACT = {
	folder = "Carte",
	report = "RapportRecette",
	zones = "Zones",
	-- Les emplacements possibles des cachettes : des parts invisibles qui
	-- portent l'attribut `Prefab` (le modele a poser) et `Famille`
	-- (fragile, moyenne). Noms uniques.
	anchors = "Emplacements",
	-- Les cachettes solides, fixes (caves, dessous de pont, tunnels).
	solidSpots = "CachettesSolides",
	-- Les contenants a fouiller : parts ou modeles portant l'attribut `Table`.
	containers = "Fouilles",
	-- Les modeles des cachettes fragiles, dans ServerStorage.
	prefabs = "RoyaleCachettes",
	inside = "Interieur",
	exit = "Sortie",
	cover = "Couvert",
	building = "Batiment",
	roof = "Toiture",
	loose = "Aspirable",
}

export type Kit = {
	O: any,
	V: any,
	Plan: any,
	CONTRACT: typeof(CONTRACT),
	root: Folder,
	anchors: Folder,
	containers: Folder,
	solid: Folder,
	random: Random,
	ground: (x: number, z: number) -> number,
	claim: (x: number, z: number, radius: number) -> boolean,
	isFree: (x: number, z: number, radius: number) -> boolean,
	road: (parent: Instance, points: { Vector2 }, width: number, sidewalk: boolean) -> (),
	anchor: (prefab: string, family: string, cf: CFrame) -> BasePart,
	zoneFolder: (name: string) -> Folder,
	counts: { [string]: number },
	spline: (points: { Vector2 }, step: number) -> { Vector2 },
	crate: (cf: CFrame, lootTable: string, name: string?) -> BasePart,
	prop: (parent: Instance, name: string, cf: CFrame) -> Model?,
	B: any,
}

-- Une courbe douce qui passe par les points donnes (Catmull-Rom), decoupee
-- tous les `step` studs : une rue de lotissement tourne, elle ne casse pas.
local function spline(points: { Vector2 }, step: number): { Vector2 }
	local out: { Vector2 } = { points[1] }
	for i = 1, #points - 1 do
		local p0 = points[math.max(i - 1, 1)]
		local p1 = points[i]
		local p2 = points[i + 1]
		local p3 = points[math.min(i + 2, #points)]
		local n = math.max(1, math.ceil((p2 - p1).Magnitude / step))
		for s = 1, n do
			local t = s / n
			local t2, t3 = t * t, t * t * t
			table.insert(
				out,
				0.5
					* (
						(2 * p1)
						+ (-p0 + p2) * t
						+ (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
						+ (-p0 + 3 * p1 - 3 * p2 + p3) * t3
					)
			)
		end
	end
	return out
end

local function create(O: any, V: any, Plan: any): Kit
	local random: Random = O.random
	local C = O.C
	local P = O.P

	local root = O.folder(workspace, CONTRACT.folder)
	local zonesFolder = O.folder(root, CONTRACT.zones)
	local anchors = O.folder(root, CONTRACT.anchors)
	local containers = O.folder(root, CONTRACT.containers)
	local solid = O.folder(root, CONTRACT.solidSpots)

	local counts: { [string]: number } = {}

	-- Le sol reel, lu au rayon sur le terrain (et non recalcule) : ce qu'on
	-- pose touche ce que le joueur verra.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	params.IgnoreWater = true
	local function ground(x: number, z: number): number
		local hit = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -700, 0), params)
		return if hit then hit.Position.Y else 0
	end

	-- La place prise, en cercles. Grossier, mais suffisant pour ne jamais
	-- poser deux choses l'une dans l'autre.
	local taken: { { number } } = {}
	local function isFree(x: number, z: number, radius: number): boolean
		for _, c in taken do
			local dx, dz = x - c[1], z - c[2]
			if dx * dx + dz * dz < (radius + c[3]) ^ 2 then
				return false
			end
		end
		return true
	end
	local function claim(x: number, z: number, radius: number): boolean
		if not isFree(x, z, radius) then
			return false
		end
		table.insert(taken, { x, z, radius })
		return true
	end

	-- Une route qui suit le relief : un troncon incline par segment, une
	-- rotule a chaque coude (pas de fente aux virages), des trottoirs si
	-- demande. Elle reserve sa place.
	local function road(parent: Instance, points: { Vector2 }, width: number, sidewalk: boolean)
		local m = O.model(parent, "Route")
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local pa = Vector3.new(a.X, ground(a.X, a.Y) + 0.15, a.Y)
			local pb = Vector3.new(b.X, ground(b.X, b.Y) + 0.15, b.Y)
			local len = (pb - pa).Magnitude
			local cf = CFrame.lookAt((pa + pb) / 2, pb)
			-- Le terrain se plie a la route : on retire ce qui depasse au-dessus. Sans ca, entre deux points, une bosse
			-- mangeait l'asphalte (vu a l'ecran : des flaques sombres).
			local edge = width + (if sidewalk then 8 else 4)
			workspace.Terrain:FillBlock(
				cf * CFrame.new(0, 3.4, 0),
				Vector3.new(edge, 6.4, len + 2),
				Enum.Material.Air
			)
			-- Pas de remblai dessous : aux carrefours, celui d'une route plus
			-- haute enterrait sa voisine, et il s'accumulait a chaque
			-- reconstruction (vu a l'ecran le 12 novembre 2026).
			P(
				m,
				"Chaussee",
				Vector3.new(width, 0.4, len + 0.2),
				cf,
				Enum.Material.Asphalt,
				C.asphalt
			)
			if sidewalk then
				for _, side in { -1, 1 } do
					P(
						m,
						"Trottoir",
						Vector3.new(3, 0.7, len + 0.2),
						cf * CFrame.new(side * (width / 2 + 1.5), 0.15, 0),
						Enum.Material.Concrete,
						C.concrete
					)
				end
			end
			-- Une ligne blanche effacee au milieu des routes de campagne ; des
			-- flaques qui refletent le ciel ; des plaques d'egout en ville.
			if not sidewalk and i % 2 == 0 then
				P(
					m,
					"Marquage",
					Vector3.new(0.4, 0.05, len * 0.45),
					cf * CFrame.new(0, 0.22, 0),
					Enum.Material.SmoothPlastic,
					C.line,
					{ collide = false, query = false, shadow = false }
				)
			end
			if random:NextNumber() < 0.12 then
				-- Une flaque : deux ou trois disques sombres et a peine
				-- brillants. En rectangle de verre, elles faisaient des taches
				-- bleu vif (vu a l'ecran).
				local center = cf
					* CFrame.new(
						random:NextNumber(-width / 3, width / 3),
						0.22,
						random:NextNumber(-len / 3, len / 3)
					)
				for _ = 1, random:NextInteger(2, 3) do
					local d = random:NextNumber(2, 4.5)
					local puddle = P(
						m,
						"Flaque",
						Vector3.new(0.04, d, d),
						center
							* CFrame.new(random:NextNumber(-1.5, 1.5), 0, random:NextNumber(-2, 2))
							* CFrame.Angles(0, 0, math.rad(90)),
						Enum.Material.SmoothPlastic,
						Color3.fromRGB(44, 48, 52),
						{
							shape = Enum.PartType.Cylinder,
							collide = false,
							query = false,
							shadow = false,
							transparency = 0.35,
						}
					)
					puddle.Reflectance = 0.04
				end
			end
			if sidewalk and random:NextNumber() < 0.15 then
				P(
					m,
					"PlaqueEgout",
					Vector3.new(0.1, 3, 3),
					cf
						* CFrame.new(random:NextNumber(-width / 4, width / 4), 0.22, 0)
						* CFrame.Angles(0, 0, math.rad(90)),
					Enum.Material.DiamondPlate,
					Color3.fromRGB(56, 56, 58),
					{ shape = Enum.PartType.Cylinder, collide = false }
				)
			end
			-- Des rustines sur l'asphalte : une route abandonnee n'est pas neuve.
			if random:NextNumber() < 0.5 then
				P(
					m,
					"Rustine",
					Vector3.new(random:NextNumber(3, width * 0.6), 0.42, random:NextNumber(4, 10)),
					cf
						* CFrame.new(
							random:NextNumber(-width / 4, width / 4),
							0.01,
							random:NextNumber(-len / 3, len / 3)
						),
					Enum.Material.Asphalt,
					C.asphaltPatch
				)
			end
			local steps = math.ceil(len / 12)
			for s = 0, steps do
				local p = pa:Lerp(pb, s / steps)
				claim(p.X, p.Z, width / 2 + (if sidewalk then 3 else 1))
			end
		end
		for i = 2, #points - 1 do
			local a = points[i]
			local y = ground(a.X, a.Y) + 0.15
			P(
				m,
				"Coude",
				Vector3.new(0.4, width, width),
				CFrame.new(a.X, y, a.Y) * CFrame.Angles(0, 0, math.rad(90)),
				Enum.Material.Asphalt,
				C.asphalt,
				{ shape = Enum.PartType.Cylinder }
			)
		end
	end

	-- Un emplacement de cachette (le jeu y pose le modele choisi chaque
	-- partie). `cf` : au sol, l'avant vers ou l'on entre.
	local function anchor(prefab: string, family: string, cf: CFrame): BasePart
		counts[prefab] = (counts[prefab] or 0) + 1
		local part = O.marker(anchors, prefab .. "_" .. counts[prefab], cf * CFrame.new(0, 0.5, 0))
		part:SetAttribute("Prefab", prefab)
		part:SetAttribute("Famille", family)
		return part
	end

	-- Un contenant a fouiller (une caisse, par defaut) : le jeu y tire du
	-- butin dans la table nommee.
	local function crate(cf: CFrame, lootTable: string, name: string?): BasePart
		local part = P(
			containers,
			name or "Caisse",
			Vector3.new(3.2, 2.6, 3.2),
			cf * CFrame.new(0, 1.3, 0),
			Enum.Material.WoodPlanks,
			C.wood
		)
		part:SetAttribute("Table", lootTable)
		return part
	end

	-- Un objet du magasin (docs/ASSETS.md) pose au sol, s'il est dans la
	-- place : poubelle, borne a incendie, cone. Rend nil sinon (la zone
	-- s'en passe).
	local library = game:GetService("ServerStorage"):FindFirstChild("RoyaleModeles")
	local function prop(parent: Instance, name: string, cf: CFrame): Model?
		local template = library and library:FindFirstChild(name)
		if template == nil or not template:IsA("Model") then
			return nil
		end
		local m = template:Clone()
		m:PivotTo(cf)
		m.Parent = parent
		return m
	end

	local function zoneFolder(name: string): Folder
		return O.folder(zonesFolder, name)
	end

	return {
		O = O,
		V = V,
		Plan = Plan,
		CONTRACT = CONTRACT,
		root = root,
		anchors = anchors,
		containers = containers,
		solid = solid,
		random = random,
		ground = ground,
		claim = claim,
		isFree = isFree,
		road = road,
		anchor = anchor,
		zoneFolder = zoneFolder,
		counts = counts,
		spline = spline,
		crate = crate,
		prop = prop,
		B = nil,
	}
end

return { create = create, CONTRACT = CONTRACT, spline = spline }
