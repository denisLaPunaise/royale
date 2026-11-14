--!strict
--[[
	LobbyService — le salon (DECISIONS.md, choisi avec Josh le 12 novembre
	2026 : « les deux »).

	Une place en ruine flottant loin de la carte, construite au demarrage. On
	y attend, on forme son groupe (X maintenu sur quelqu'un l'invite ; il
	accepte avec X), le chef choisit le mode (Y) et se dit pret (R2). Un
	compte a rebours part : a la fin, tous les groupes prets de ce mode
	partent ensemble. `onLaunch` decide ou ils jouent (MatchService : sur
	place dans Studio, sur un serveur reserve dans le jeu publie).

	Les invitations et « rejoindre » de Roblox amenent les amis sur ce
	serveur ; croix haut ouvre la fenetre d'invitation de Roblox (client).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local Lobby = require(Royale:WaitForChild("Lobby"))

local Avatar = require(script.Parent.Avatar)
local RemoteGuard = require(script.Parent.RemoteGuard)
local World = require(script.Parent.World)

local LobbyService = {}

local LB = Config.lobby
local SIZES = Config.squads.sizes
local ORIGIN = Vector3.new(LB.origin[1], LB.origin[2], LB.origin[3])

local state = Lobby.new()
local byId: { [string]: Player } = {}
-- Ceux qui jouent une partie sur ce serveur : hors du salon jusqu'a la fin.
local away: { [Player]: boolean } = {}
-- L'invitation recue par chacun : qui, et quand.
local invites: { [Player]: { from: Player, at: number } } = {}
local countdown: { mode: string, ends: number }? = nil
local launching = false
local onLaunch: ((players: { Player }, mode: string, groups: { { Player } }) -> ())? = nil
local folder: Folder? = nil
local random = Random.new()

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function idOf(player: Player): string
	return tostring(player.UserId)
end

local function part(
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

-- La place : un disque de pavés uses, un muret effondre tout autour (et un
-- mur invisible pour ne pas tomber), des lanternes, un brasero au centre.
local function build()
	local old = workspace:FindFirstChild(LB.folder)
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = LB.folder
	f.Parent = workspace
	World.ignore(f)
	folder = f
	local stone, dark, lantern = rgb(LB.colors.stone), rgb(LB.colors.dark), rgb(LB.colors.lantern)
	local flat = CFrame.Angles(0, 0, math.pi / 2)
	local r = LB.radius
	local floor = part(
		"Sol",
		Vector3.new(4, r * 2, r * 2),
		CFrame.new(ORIGIN - Vector3.new(0, 2, 0)) * flat,
		stone,
		Enum.Material.Cobblestone
	)
	floor.Shape = Enum.PartType.Cylinder
	local under = part(
		"Dessous",
		Vector3.new(14, r * 2 - 6, r * 2 - 6),
		CFrame.new(ORIGIN - Vector3.new(0, 11, 0)) * flat,
		dark,
		Enum.Material.Rock
	)
	under.Shape = Enum.PartType.Cylinder
	local segments = 36
	for i = 1, segments do
		local a = (i - 0.5) / segments * math.pi * 2
		local at = ORIGIN + Vector3.new(math.cos(a) * (r - 1), 0, math.sin(a) * (r - 1))
		local facing = CFrame.lookAt(at, ORIGIN)
		local h = random:NextNumber(1.5, 6)
		local width = 2 * math.pi * r / segments + 0.4
		part(
			"Muret",
			Vector3.new(width, h, 1.6),
			facing + Vector3.new(0, h / 2, 0),
			dark,
			Enum.Material.Slate
		)
		local barrier = part(
			"MurInvisible",
			Vector3.new(width, 14, 1),
			facing + Vector3.new(0, 7, 0),
			dark,
			Enum.Material.SmoothPlastic
		)
		barrier.Transparency = 1
	end
	-- Les lampadaires, decales d'un demi-cran : sur les angles ronds, l'un se
	-- plantait devant le panneau « Comment jouer » (vu en image).
	for i = 1, LB.lanterns do
		local a = (i - 0.5) / LB.lanterns * math.pi * 2
		local at = ORIGIN + Vector3.new(math.cos(a) * (r - 8), 0, math.sin(a) * (r - 8))
		part(
			"Poteau",
			Vector3.new(0.6, 9, 0.6),
			CFrame.new(at + Vector3.new(0, 4.5, 0)),
			dark,
			Enum.Material.Metal
		)
		local lamp = part(
			"Lanterne",
			Vector3.new(1.4, 1.6, 1.4),
			CFrame.new(at + Vector3.new(0, 9.5, 0)),
			lantern,
			Enum.Material.Neon
		)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = lantern
		light.Range = 26
		light.Brightness = 1.6
		light.Parent = lamp
	end
	local brazier = part(
		"Brasero",
		Vector3.new(3, 6, 6),
		CFrame.new(ORIGIN + Vector3.new(0, 1.5, 0)) * flat,
		dark,
		Enum.Material.CorrodedMetal
	)
	brazier.Shape = Enum.PartType.Cylinder
	local fire = Instance.new("Fire")
	fire.Size = 7
	fire.Heat = 12
	fire.Parent = brazier
	local glow = Instance.new("PointLight")
	glow.Color = lantern
	glow.Range = 30
	glow.Brightness = 2
	glow.Parent = brazier
	-- Des colonnes brisees en cercle, de hauteurs differentes (la silhouette
	-- d'une ruine, pas un disque nu). Les deux panneaux sont sur l'axe Z (90 et
	-- 270 degres) : avec un decalage d'un demi-cran, une colonne se dressait
	-- pile devant chacun (vu en image le 14 novembre 2026).
	local T = LB.tutorial
	local arcFrom = T.panelArcStart - T.panelArcStep
	local arcTo = T.panelArcStart + #T.panels * T.panelArcStep
	for i = 1, LB.columns do
		local degrees = i / LB.columns * 360
		-- Pas de colonne devant les panneaux « Comment jouer ».
		if degrees > arcFrom and degrees < arcTo then
			continue
		end
		local a = math.rad(degrees)
		local at = ORIGIN + Vector3.new(math.cos(a) * (r - 18), 0, math.sin(a) * (r - 18))
		-- Une colonne antique (choisi avec Josh : « plus belles ») : un socle
		-- a deux marches, un tore, un fut cannele ; entiere, un chapiteau ;
		-- brisee, une cassure de biais et son tambour tombe a cote. Du lierre
		-- grimpe sur certaines.
		local C = LB.columnStyle
		local whole = random:NextNumber() < C.wholeChance
		local h = if whole
			then C.wholeHeight
			else random:NextNumber(C.brokenHeight[1], C.brokenHeight[2])
		local yaw = CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
		local base = CFrame.new(at) * yaw
		part(
			"Socle",
			Vector3.new(5.2, 0.8, 5.2),
			base * CFrame.new(0, 0.4, 0),
			dark,
			Enum.Material.Slate
		)
		part(
			"Socle",
			Vector3.new(4.4, 0.6, 4.4),
			base * CFrame.new(0, 1.1, 0),
			stone,
			Enum.Material.Limestone
		)
		local foot = 1.4
		local torus = part(
			"Tore",
			Vector3.new(0.6, 4, 4),
			base * CFrame.new(0, foot + 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2),
			stone,
			Enum.Material.Limestone
		)
		torus.Shape = Enum.PartType.Cylinder
		local shaftFrom = foot + 0.6
		local column = part(
			"Colonne",
			Vector3.new(h, 3.2, 3.2),
			base * CFrame.new(0, shaftFrom + h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
			stone,
			Enum.Material.Limestone
		)
		column.Shape = Enum.PartType.Cylinder
		-- Les cannelures : des filets sombres tout autour du fut.
		for k = 1, C.flutes do
			local around = k / C.flutes * math.pi * 2
			local flute = part(
				"Cannelure",
				Vector3.new(0.22, h - 0.4, 0.22),
				base * CFrame.Angles(0, around, 0) * CFrame.new(0, shaftFrom + h / 2, 1.55),
				rgb(C.fluteColor),
				Enum.Material.Limestone
			)
			flute.CanCollide = false
			flute.CanQuery = false
		end
		local top = shaftFrom + h
		if whole then
			local neck = part(
				"Chapiteau",
				Vector3.new(0.6, 4, 4),
				base * CFrame.new(0, top + 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2),
				stone,
				Enum.Material.Limestone
			)
			neck.Shape = Enum.PartType.Cylinder
			part(
				"Chapiteau",
				Vector3.new(4.8, 1, 4.8),
				base * CFrame.new(0, top + 1.1, 0),
				stone,
				Enum.Material.Limestone
			)
		else
			-- La cassure : deux eclats de biais au sommet.
			for k = 0, 1 do
				local shard = part(
					"Eclat",
					Vector3.new(3.2, random:NextNumber(0.8, 1.6), 1.6),
					base
						* CFrame.new(0, top + 0.3, (k - 0.5) * 1.6)
						* CFrame.Angles(
							random:NextNumber(-0.25, 0.25),
							0,
							random:NextNumber(-0.4, 0.4)
						),
					stone,
					Enum.Material.Limestone
				)
				shard.CanCollide = false
			end
			-- Le tambour tombe, a cote.
			local piece = part(
				"Debris",
				Vector3.new(random:NextNumber(3, 5), 3.2, 3.2),
				CFrame.new(
					at + Vector3.new(random:NextNumber(-5, 5), 1.6, random:NextNumber(-5, 5))
				) * CFrame.Angles(0, random:NextNumber(0, 6.3), math.pi / 2),
				stone,
				Enum.Material.Limestone
			)
			piece.Shape = Enum.PartType.Cylinder
			piece.CanCollide = false
		end
		if random:NextNumber() < C.ivyChance then
			-- Le lierre : des feuilles plaquees sur une face, du pied vers le haut.
			local side = random:NextNumber(0, math.pi * 2)
			for k = 1, C.ivyLeaves do
				local up = shaftFrom + (k / C.ivyLeaves) * h * random:NextNumber(0.5, 0.95)
				local leaf = part(
					"Lierre",
					Vector3.new(random:NextNumber(0.5, 0.9), random:NextNumber(0.4, 0.8), 0.2),
					base
						* CFrame.Angles(0, side + random:NextNumber(-0.7, 0.7), 0)
						* CFrame.new(0, up, 1.65)
						* CFrame.Angles(0, 0, random:NextNumber(0, math.pi)),
					rgb(C.ivyColor),
					Enum.Material.LeafyGrass
				)
				leaf.CanCollide = false
				leaf.CanQuery = false
			end
		end
	end
	-- L'embleme de l'Oeil, au sol autour du brasero : un anneau sombre et un
	-- iris de braise.
	local ring = part(
		"Embleme",
		Vector3.new(0.2, 22, 22),
		CFrame.new(ORIGIN + Vector3.new(0, 0.05, 0)) * flat,
		dark,
		Enum.Material.Basalt
	)
	ring.Shape = Enum.PartType.Cylinder
	ring.CanCollide = false
	local iris = part(
		"Iris",
		Vector3.new(0.25, 14, 14),
		CFrame.new(ORIGIN + Vector3.new(0, 0.1, 0)) * flat,
		rgb(LB.colors.banner),
		Enum.Material.Neon
	)
	iris.Shape = Enum.PartType.Cylinder
	iris.CanCollide = false
	-- (Plus opaque, l'iris faisait un aplat rouge vif, vu en image.)
	iris.Transparency = 0.5
	for _ = 1, 24 do
		local a = random:NextNumber(0, math.pi * 2)
		local d = random:NextNumber(12, r - 6)
		local s = random:NextNumber(0.8, 2.4)
		local rubble = part(
			"Gravat",
			Vector3.new(s, s * 0.6, s * 1.2),
			CFrame.new(ORIGIN + Vector3.new(math.cos(a) * d, s * 0.3, math.sin(a) * d))
				* CFrame.Angles(
					random:NextNumber(-0.3, 0.3),
					random:NextNumber(0, 6.3),
					random:NextNumber(-0.3, 0.3)
				),
			dark,
			Enum.Material.Rock
		)
		rubble.CanCollide = false
	end
end

-- Le petit tutoriel (CONCEPT.md : les cachettes ne s'affichent pas, « un
-- petit tutoriel les presente au debut ») : un exemplaire de chaque
-- cachette sur un arc du salon, avec son nom et ses places, et les panneaux
-- illustres « Comment jouer » en face.
local function tutorial()
	local library = World.prefabs
	local T = LB.tutorial
	local shown = 0
	if library then
		local seen: { [string]: boolean } = {}
		local models: { Model } = {}
		for _, m in library:GetChildren() do
			local kind = string.gsub(m.Name, "%d+$", "")
			if m:IsA("Model") and not seen[kind] and m.PrimaryPart then
				seen[kind] = true
				table.insert(models, m)
			end
		end
		table.sort(models, function(a, b)
			return a.Name < b.Name
		end)
		local degrees = T.arcStart - T.arcStep
		for i, source in models do
			if i > T.maxSpots then
				break
			end
			-- Un arc au nord du salon, face au centre, avec un trou devant le
			-- classement.
			degrees += T.arcStep
			if math.abs(degrees - Config.leaderboard.angle) < T.boardClearance then
				degrees += T.arcStep
			end
			local a = math.rad(degrees)
			local at = ORIGIN + Vector3.new(math.cos(a) * T.radius, 0, math.sin(a) * T.radius)
			local model = source:Clone()
			local socle = model.PrimaryPart :: BasePart
			local facing = CFrame.lookAt(at, Vector3.new(ORIGIN.X, at.Y, ORIGIN.Z))
			model:PivotTo(facing * socle.CFrame:ToObjectSpace(model:GetPivot()))
			-- Une vitrine : rien n'y entre, et on ne s'y cogne pas.
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
				elseif d:IsA("ProximityPrompt") or d:IsA("Script") then
					d:Destroy()
				end
			end
			model.Parent = folder
			local kind = string.gsub(source.Name, "%d+$", "")
			local places = Config.hiding.capacity[kind] or Config.hiding.defaultCapacity
			local tag = Instance.new("BillboardGui")
			-- En studs : l'etiquette rapetisse avec la distance (en pixels,
			-- elles se chevauchaient de loin, vu en image).
			tag.Size = UDim2.fromScale(T.tagWidth, T.tagHeight)
			tag.StudsOffset = Vector3.new(0, T.tagAbove, 0)
			tag.LightInfluence = 0
			tag.MaxDistance = T.tagDistance
			tag.Adornee = socle
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Font = (Enum.Font :: any)[Config.view.bodyFont]
			label.TextScaled = true
			label.TextColor3 = rgb(LB.colors.lantern)
			label.TextStrokeTransparency = 0.3
			label.Text =
				string.format("%s\n%s", kind, if places > 1 then places .. " places" else "1 place")
			label.Parent = tag
			tag.Parent = model
			shown += 1
		end
	end
	-- Les panneaux illustres, sur l'arc d'en face (LobbyView les dessine :
	-- les icones de manette ne se lisent que chez le client).
	local w, h = T.panelWidth, T.panelHeight
	for i in T.panels do
		local a = math.rad(T.panelArcStart + (i - 1) * T.panelArcStep)
		local foot = ORIGIN
			+ Vector3.new(math.cos(a) * T.panelRadius, 0, math.sin(a) * T.panelRadius)
		local facing = CFrame.lookAt(foot, Vector3.new(ORIGIN.X, foot.Y, ORIGIN.Z))
		local board = part(
			"Panneau",
			Vector3.new(w, h, 0.6),
			facing + Vector3.new(0, T.panelLift + h / 2, 0),
			rgb(LB.colors.dark),
			Enum.Material.Wood
		)
		board:SetAttribute("Panneau", i)
		for side = -1, 1, 2 do
			part(
				"Pied",
				Vector3.new(0.5, T.panelLift + h, 0.5),
				facing * CFrame.new(side * (w / 2 - 0.6), (T.panelLift + h) / 2, 0.5),
				rgb(LB.colors.dark),
				Enum.Material.Wood
			)
		end
	end
	return shown
end

local function range(pair: { number }): number
	return random:NextNumber(pair[1], pair[2])
end

-- Le decor sous l'Oeil (Config.lobby.decor) : nuages, Oeil qui veille,
-- arbres morts, buissons, rochers flottants.
local function decor()
	local D = LB.decor
	local cloud = rgb(D.cloudColor)
	-- Une boule aplatie : une part « Ball » serait une sphere du plus petit
	-- cote, d'ou la maille.
	local function puff(at: Vector3, width: number, height: number, color: Color3)
		local p = part(
			"Nuage",
			Vector3.new(width, height, width * random:NextNumber(0.6, 1)),
			CFrame.new(at) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0),
			color,
			Enum.Material.SmoothPlastic
		)
		p.Transparency = D.cloudTransparency
		p.CastShadow = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	local function cluster(center: Vector3, width: number, height: number)
		for k = 1, D.cloudPuffs do
			-- La premiere boule au milieu, les autres plus petites a cote et un
			-- peu plus bas : une silhouette de nuage, pas une sphere.
			local s = if k == 1 then 1 else random:NextNumber(0.5, 0.8)
			local offset = if k == 1
				then Vector3.zero
				else Vector3.new(
					random:NextNumber(-0.5, 0.5) * width,
					-height * random:NextNumber(0.1, 0.3),
					random:NextNumber(-0.5, 0.5) * width
				)
			local shade = random:NextNumber(0.94, 1.02)
			puff(
				center + offset,
				width * s,
				height * s,
				Color3.new(
					math.min(1, cloud.R * shade),
					math.min(1, cloud.G * shade),
					math.min(1, cloud.B * shade)
				)
			)
		end
	end
	for _ = 1, D.cloudCount do
		local a = random:NextNumber(0, math.pi * 2)
		local d = math.sqrt(random:NextNumber(D.cloudInner ^ 2, D.cloudOuter ^ 2))
		cluster(
			ORIGIN
				+ Vector3.new(
					math.cos(a) * d,
					-D.cloudBelow + random:NextNumber(-D.cloudSpread, D.cloudSpread),
					math.sin(a) * d
				),
			range(D.cloudWidth),
			range(D.cloudHeight)
		)
	end
	for i = 1, D.bankCount do
		local a = (i + random:NextNumber(-0.4, 0.4)) / D.bankCount * math.pi * 2
		local d = range(D.bankRadius)
		cluster(
			ORIGIN + Vector3.new(math.cos(a) * d, -D.bankBelow, math.sin(a) * d),
			range(D.bankWidth),
			range(D.bankHeight)
		)
	end
	local floor = part(
		"MerDeNuages",
		Vector3.new(1, D.cloudFloorSize, D.cloudFloorSize),
		CFrame.new(ORIGIN - Vector3.new(0, D.cloudFloorBelow, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		rgb(D.cloudFloorColor),
		Enum.Material.SmoothPlastic
	)
	floor.Shape = Enum.PartType.Cylinder
	floor.CastShadow = false
	floor.CanCollide = false
	floor.CanQuery = false
	-- Arbres morts et buissons, contre le muret.
	local library = game:GetService("ServerStorage"):FindFirstChild(D.models)
	if library == nil then
		warn("[Royale] Salon : ServerStorage." .. D.models .. " manque, pas d'arbres")
	else
		local function plant(name: string, angle: number, radius: number, scale: number)
			local model = library:FindFirstChild(name)
			if model == nil or not model:IsA("Model") then
				warn("[Royale] Salon : modele " .. name .. " manquant")
				return
			end
			local m = model:Clone()
			m:ScaleTo(scale)
			local cf, size = m:GetBoundingBox()
			local bottom = m:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2)
			local a = math.rad(angle)
			m:PivotTo(
				CFrame.new(ORIGIN + Vector3.new(math.cos(a) * radius, bottom, math.sin(a) * radius))
					* CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
			)
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
				end
			end
			m.Parent = folder
		end
		for i, angle in D.treeAngles do
			plant(D.trees[(i - 1) % #D.trees + 1], angle, D.treeRadius, 1)
		end
		for _, angle in D.bushAngles do
			plant(D.bushes, angle, D.bushRadius, D.bushScale)
		end
	end
	-- Les rochers flottants (LobbyView les fait monter et descendre).
	local rocks = Instance.new("Folder")
	rocks.Name = "Flottants"
	rocks.Parent = folder
	for _ = 1, D.rocks do
		local a = random:NextNumber(0, math.pi * 2)
		local d = range(D.rockRadius)
		local s = range(D.rockSize)
		local center = ORIGIN + Vector3.new(math.cos(a) * d, -range(D.rockBelow), math.sin(a) * d)
		-- Les morceaux d'un meme rocher bougent ensemble (meme periode, meme
		-- phase).
		local period, phase = range(D.rockPeriod), random:NextNumber(0, math.pi * 2)
		for k = 1, D.rockPieces do
			local size = s * (if k == 1 then 1 else random:NextNumber(0.5, 0.8))
			local offset = if k == 1
				then Vector3.zero
				else Vector3.new(
					random:NextNumber(-0.4, 0.4),
					random:NextNumber(-0.4, 0.4),
					random:NextNumber(-0.4, 0.4)
				) * s
			local rock = part(
				"Rocher",
				Vector3.new(
					size,
					size * random:NextNumber(0.6, 1),
					size * random:NextNumber(0.7, 1.2)
				),
				CFrame.new(center + offset)
					* CFrame.Angles(
						random:NextNumber(0, math.pi),
						random:NextNumber(0, math.pi),
						random:NextNumber(0, math.pi)
					),
				rgb(LB.colors.dark),
				Enum.Material.Rock
			)
			rock.CanCollide = false
			rock.CanQuery = false
			rock:SetAttribute("Periode", period)
			rock:SetAttribute("Phase", phase)
			rock.Parent = rocks
		end
	end
	-- Le dessous s'effile en pointe : une ile arrachee, pas un palet.
	for _, layer in D.islandLayers do
		local radius = LB.radius * layer[1]
		local cone = part(
			"Ile",
			Vector3.new(14, radius * 2, radius * 2),
			CFrame.new(ORIGIN - Vector3.new(0, layer[2], 0)) * CFrame.Angles(0, 0, math.pi / 2),
			rgb(LB.colors.dark),
			Enum.Material.Rock
		)
		cone.Shape = Enum.PartType.Cylinder
		cone.CanCollide = false
		cone.CanQuery = false
	end
end

-- Un point ou se poser dans le salon.
function LobbyService.spot(): Vector3
	local a = random:NextNumber(0, math.pi * 2)
	local d = random:NextNumber(10, LB.radius - 12)
	return ORIGIN + Vector3.new(math.cos(a) * d, 4, math.sin(a) * d)
end

local function publish()
	for id, player in byId do
		local leader = state.groupOf[id]
		local g = leader and state.groups[leader]
		if g then
			local names: { string } = {}
			for _, m in g.members do
				local p = byId[m]
				table.insert(names, if p then p.DisplayName else "?")
			end
			player:SetAttribute(LB.groupAttribute, table.concat(names, ", "))
			player:SetAttribute(LB.modeAttribute, g.mode)
			player:SetAttribute(LB.readyAttribute, g.ready)
		end
	end
	workspace:SetAttribute(
		LB.countdownAttribute,
		if countdown
			then countdown.mode .. "|" .. tostring(
				workspace:GetServerTimeNow() + (countdown.ends - os.clock())
			)
			else nil
	)
end

local function addInvitePrompt(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or root:FindFirstChild("RoyaleInviter") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RoyaleInviter"
	prompt.ActionText = "Inviter dans mon groupe"
	prompt.ObjectText = player.DisplayName
	prompt.HoldDuration = LB.inviteHoldSeconds
	prompt.MaxActivationDistance = LB.inviteDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode[Config.controls.contexts.lobby.invite.keyboard]
	prompt.GamepadKeyCode = Enum.KeyCode[Config.controls.contexts.lobby.invite.gamepad]
	prompt.Parent = root
	prompt.Triggered:Connect(function(from: Player)
		LobbyService.invite(from, player)
	end)
end

-- Pose un joueur dans le salon (personnage neuf).
function LobbyService.place(player: Player)
	if away[player] then
		return
	end
	Avatar.load(player)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(LobbyService.spot()))
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.movement.walkSpeed
			humanoid.Died:Connect(function()
				task.wait(2)
				if player.Parent and not away[player] then
					LobbyService.place(player)
				end
			end)
		end
		addInvitePrompt(player)
	end
end

-- `from` invite `to` dans son groupe.
function LobbyService.invite(from: Player, to: Player)
	if from == to or away[from] or away[to] then
		return
	end
	invites[to] = { from = from, at = os.clock() }
	to:SetAttribute(
		LB.inviteAttribute,
		from.DisplayName .. "|" .. tostring(workspace:GetServerTimeNow())
	)
end

local function accept(player: Player)
	local invite = invites[player]
	invites[player] = nil
	player:SetAttribute(LB.inviteAttribute, nil)
	if invite == nil or os.clock() - invite.at > LB.inviteSeconds or invite.from.Parent == nil then
		return
	end
	if Lobby.join(state, idOf(invite.from), idOf(player), LB.maxGroup) then
		print(
			string.format(
				"[Royale] %s rejoint le groupe de %s",
				player.DisplayName,
				invite.from.DisplayName
			)
		)
	end
	publish()
end

local function action(player: Player, name: any)
	if away[player] or typeof(name) ~= "string" then
		return
	end
	local id = idOf(player)
	if name == "accept" then
		accept(player)
		return
	elseif name == "leave" then
		Lobby.leave(state, id, true)
	elseif name == "mode" then
		Lobby.cycleMode(state, id, LB.modes, SIZES)
	elseif name == "ready" then
		local g = state.groups[state.groupOf[id] or ""]
		Lobby.setReady(state, id, not (g and g.ready), SIZES)
	end
	publish()
end

local function launch(mode: string)
	local groups: { { Player } } = {}
	local players: { Player } = {}
	for _, g in Lobby.readyGroups(state, mode) do
		local list: { Player } = {}
		for _, m in g.members do
			local p = byId[m]
			if p and p.Parent then
				table.insert(list, p)
				table.insert(players, p)
			end
		end
		if #list > 0 then
			table.insert(groups, list)
		end
		g.ready = false
	end
	publish()
	if #players == 0 or onLaunch == nil then
		return
	end
	print(string.format("[Royale] Départ du salon : %d joueur(s), mode %s", #players, mode))
	launching = true
	local ok, err = pcall(onLaunch :: any, players, mode, groups)
	launching = false
	if not ok then
		warn("[Royale] Le départ a échoué : " .. tostring(err))
	end
end

local function step()
	if launching then
		return
	end
	if countdown == nil then
		-- Le premier groupe pret lance le compte a rebours de son mode.
		for _, mode in LB.modes do
			if #Lobby.readyGroups(state, mode) > 0 then
				countdown = { mode = mode, ends = os.clock() + LB.countdownSeconds }
				publish()
				break
			end
		end
	elseif #Lobby.readyGroups(state, countdown.mode) == 0 then
		countdown = nil
		publish()
	elseif os.clock() >= countdown.ends then
		local mode = countdown.mode
		countdown = nil
		launch(mode)
	end
end

-- Ces joueurs partent jouer sur ce serveur (Studio) : hors du salon.
function LobbyService.setAway(players: { Player }, isAway: boolean)
	for _, p in players do
		away[p] = if isAway then true else nil
	end
end

function LobbyService.isAway(player: Player): boolean
	return away[player] == true
end

function LobbyService.start(
	remote: RemoteEvent,
	launcher: (players: { Player }, mode: string, groups: { { Player } }) -> ()
)
	onLaunch = launcher
	build()
	print(string.format("[Royale] Salon : %d cachettes en vitrine", tutorial()))
	-- Le decor n'est que visuel : il se construit apres le reste du
	-- demarrage (differe ; task.spawn l'aurait execute tout de suite).
	task.defer(function()
		local started = os.clock()
		decor()
		print(string.format("[Royale] Salon : décor construit en %.1f s", os.clock() - started))
	end)
	workspace:SetAttribute(Config.match.phaseAttribute, "Salon")
	remote.OnServerEvent:Connect(RemoteGuard.wrap(Config.remotes.lobby, action))
	local function joined(player: Player)
		local id = idOf(player)
		byId[id] = player
		Lobby.add(state, id, Config.squads.mode)
		publish()
		LobbyService.place(player)
	end
	for _, player in Players:GetPlayers() do
		joined(player)
	end
	Players.PlayerAdded:Connect(joined)
	Players.PlayerRemoving:Connect(function(player: Player)
		local id = idOf(player)
		Lobby.leave(state, id, false)
		byId[id] = nil
		away[player] = nil
		invites[player] = nil
		publish()
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local ok, err = pcall(step)
			if not ok then
				warn("[Royale] Salon : " .. tostring(err))
			end
		end
	end)
end

return LobbyService
