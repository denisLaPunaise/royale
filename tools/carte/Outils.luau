--!strict
--[[
	Outils — les briques de construction communes a toutes les recettes de la
	carte : la palette, `P` (une part ancree), les dossiers, les triangles,
	les murs perces d'ouvertures, les pentes.

	Repris tels quels de la recette de Survivor (tools/BuildBanlieue.luau), ou
	ils ont ete regles et verifies a l'ecran. Une recette les recoit en
	argument : elle ne les recopie pas.
]]

-- L'attribut qui dit qu'une part couvre du regard (lu par le jeu).
local COVER = "Couvert"

-- Un seul tirage pour toute la construction : meme graine, meme carte.
local random = Random.new(2611)

--------------------------------------------------------------------------------
-- Palette : une ville grise et passee. Un accent depense partout ne designe
-- plus rien : le rouge est reserve a l'Oeil.
--------------------------------------------------------------------------------

local C = {
	-- Plus clairs depuis les matieres generees (docs/ASSETS.md) : elles
	-- assombrissent la couleur des pieces (la route etait devenue noire).
	asphalt = Color3.fromRGB(132, 132, 134),
	asphaltPatch = Color3.fromRGB(112, 112, 114),
	line = Color3.fromRGB(176, 170, 150),
	concrete = Color3.fromRGB(150, 146, 138),
	concreteDark = Color3.fromRGB(104, 101, 96),
	curb = Color3.fromRGB(128, 125, 118),
	sidingCream = Color3.fromRGB(196, 186, 164),
	sidingSage = Color3.fromRGB(132, 140, 122),
	sidingBlue = Color3.fromRGB(116, 126, 136),
	sidingGray = Color3.fromRGB(150, 148, 142),
	brickRed = Color3.fromRGB(128, 78, 62),
	brickBrown = Color3.fromRGB(110, 88, 72),
	roofSlate = Color3.fromRGB(58, 58, 62),
	roofBrown = Color3.fromRGB(86, 62, 52),
	trim = Color3.fromRGB(210, 204, 192),
	wood = Color3.fromRGB(150, 120, 92),
	woodGray = Color3.fromRGB(162, 152, 140),
	glass = Color3.fromRGB(150, 168, 176),
	leaves = Color3.fromRGB(78, 92, 58),
	leavesDry = Color3.fromRGB(110, 104, 64),
	hedge = Color3.fromRGB(64, 80, 50),
	bark = Color3.fromRGB(72, 60, 50),
	metal = Color3.fromRGB(88, 92, 94),
	rust = Color3.fromRGB(112, 70, 48),
	black = Color3.fromRGB(22, 22, 24),
	fabric = Color3.fromRGB(96, 84, 74),
	plaster = Color3.fromRGB(184, 178, 168),
	eyeWhite = Color3.fromRGB(232, 226, 214),
	eyeIris = Color3.fromRGB(196, 72, 50),
	rift = Color3.fromRGB(255, 120, 80),
}

local SIDINGS = { C.sidingCream, C.sidingSage, C.sidingBlue, C.sidingGray }
local CAR_COLORS = {
	Color3.fromRGB(120, 124, 128),
	Color3.fromRGB(86, 96, 110),
	Color3.fromRGB(128, 112, 92),
	Color3.fromRGB(96, 60, 52),
	Color3.fromRGB(170, 168, 160),
}

--------------------------------------------------------------------------------
-- Outils de construction
--------------------------------------------------------------------------------

local partCount = 0

local function P(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	material: Enum.Material,
	color: Color3,
	options: { [string]: any }?
): BasePart
	local o = options or {}
	local p: BasePart = Instance.new(o.class or "Part") :: BasePart
	if o.shape and p:IsA("Part") then
		p.Shape = o.shape
	end
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Material = material
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if o.transparency then
		p.Transparency = o.transparency
	end
	if o.collide == false then
		p.CanCollide = false
	end
	if o.query == false then
		p.CanQuery = false
		p.CanTouch = false
	end
	if o.shadow == false then
		p.CastShadow = false
	end
	if o.cover then
		p:SetAttribute(COVER, o.cover)
	end
	p.Parent = parent
	partCount += 1
	return p
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Un marqueur invisible : interieur, sortie, depart.
local function marker(parent: Instance, name: string, cframe: CFrame): BasePart
	return P(parent, name, Vector3.new(2, 2, 2), cframe, Enum.Material.SmoothPlastic, C.black, {
		transparency = 1,
		collide = false,
		query = false,
		shadow = false,
	})
end

-- Un triangle plein, fait de deux coins. Methode classique : on oriente
-- chaque coin par une base calculee, sans dependre du sens par defaut d'une
-- WedgePart.
local function triangle(
	parent: Instance,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	thickness: number,
	material: Enum.Material,
	color: Color3
)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	P(
		parent,
		"Pignon",
		Vector3.new(thickness, height, math.abs(ab:Dot(back))),
		CFrame.fromMatrix((a + b) / 2, right, up, back),
		material,
		color,
		{ class = "WedgePart" }
	)
	P(
		parent,
		"Pignon",
		Vector3.new(thickness, height, math.abs(ac:Dot(back))),
		CFrame.fromMatrix((a + c) / 2, -right, up, -back),
		material,
		color,
		{ class = "WedgePart" }
	)
end

type Opening = {
	x: number,
	w: number,
	b: number,
	t: number,
	kind: string?, -- "window" | "door" | "garage"
}

-- Un mur droit le long de son X local, du sol (y = 0) a `height`, perce
-- d'ouvertures. Les fenetres recoivent une vitre (parfois cassee, parfois
-- condamnee par des planches) et un encadrement.
local function wall(
	parent: Instance,
	cf: CFrame,
	length: number,
	height: number,
	thick: number,
	openings: { Opening },
	material: Enum.Material,
	color: Color3
)
	table.sort(openings, function(o1, o2)
		return o1.x < o2.x
	end)
	local function segment(x0: number, x1: number, y0: number, y1: number)
		if x1 - x0 < 0.05 or y1 - y0 < 0.05 then
			return
		end
		P(
			parent,
			"Mur",
			Vector3.new(x1 - x0, y1 - y0, thick),
			cf * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, 0),
			material,
			color
		)
	end
	local cursor = -length / 2
	for _, o in openings do
		local left, right = o.x - o.w / 2, o.x + o.w / 2
		segment(cursor, left, 0, height)
		segment(left, right, 0, o.b)
		segment(left, right, o.t, height)
		cursor = right

		-- L'encadrement : c'est lui qui fait d'un trou une fenetre.
		if o.kind == "window" or o.kind == "door" then
			local fw = 0.35
			for _, sx in { -1, 1 } do
				P(
					parent,
					"Cadre",
					Vector3.new(fw, o.t - o.b, thick + 0.3),
					cf * CFrame.new(o.x + sx * (o.w / 2 + fw / 2), (o.b + o.t) / 2, 0),
					Enum.Material.SmoothPlastic,
					C.trim
				)
			end
			P(
				parent,
				"Cadre",
				Vector3.new(o.w + fw * 2, fw, thick + 0.3),
				cf * CFrame.new(o.x, o.t + fw / 2, 0),
				Enum.Material.SmoothPlastic,
				C.trim
			)
		end
		if o.kind == "window" then
			local roll = random:NextNumber()
			local glassCf = cf * CFrame.new(o.x, (o.b + o.t) / 2, 0)
			if roll < 0.18 then
				-- Condamnee : des planches clouees, opaques.
				for i = 0, 2 do
					P(
						parent,
						"Planche",
						Vector3.new(o.w + 0.6, 0.7, 0.2),
						glassCf
							* CFrame.new(0, (i - 1) * (o.t - o.b) / 3, -thick / 2 - 0.1)
							* CFrame.Angles(0, 0, math.rad(random:NextNumber(-8, 8))),
						Enum.Material.WoodPlanks,
						C.woodGray
					)
				end
			elseif roll > 0.32 then
				P(
					parent,
					"Vitre",
					Vector3.new(o.w, o.t - o.b, 0.15),
					glassCf,
					Enum.Material.Glass,
					C.glass,
					{ transparency = 0.6, shadow = false }
				)
			end
			-- Rebord sous la fenetre.
			P(
				parent,
				"Rebord",
				Vector3.new(o.w + 0.6, 0.3, thick + 0.4),
				cf * CFrame.new(o.x, o.b - 0.15, 0),
				Enum.Material.SmoothPlastic,
				C.trim
			)
		end
	end
	segment(cursor, length / 2, 0, height)
end

-- Une pente de toit : une dalle de l'egout au faitage.
local function slab(
	parent: Instance,
	from: Vector3,
	to: Vector3,
	width: number,
	thick: number,
	material: Enum.Material,
	color: Color3,
	name: string
): BasePart
	local mid = (from + to) / 2
	return P(
		parent,
		name,
		Vector3.new(width, thick, (to - from).Magnitude),
		CFrame.lookAt(mid, to),
		material,
		color
	)
end

return {
	random = random,
	C = C,
	SIDINGS = SIDINGS,
	CAR_COLORS = CAR_COLORS,
	P = P,
	folder = folder,
	model = model,
	marker = marker,
	triangle = triangle,
	wall = wall,
	slab = slab,
	partCount = function(): number
		return partCount
	end,
}
