--!strict
--[[
	CosmeticFx — ce que montre chaque apparence.

	Une apparence n'est plus une couleur : un style (Config.cosmetics.styles),
	deux couleurs (a, b) et sa rarete, qui ajoute des couches d'effets
	(tierLayers : plus rare = plus d'effets, ca se voit). Choisi avec Josh le
	14 novembre 2026 : « faut que ca donne envie ».

	Rien ici ne change le jeu : ce sont des effets, sans collision ni rayon.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Signatures = require(script.Parent.Signatures)

local CosmeticFx = {}

local CO = Config.cosmetics
local WHITE = { 255, 255, 255 }
local BLACK = { 45, 40, 38 }

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Une couleur de couche : « a », « b », « w », « k », ou deja une couleur.
local function pick(token: any, def: any): { number }
	if token == "a" then
		return def.a
	elseif token == "b" then
		return def.b
	elseif token == "w" then
		return WHITE
	elseif token == "k" then
		return BLACK
	end
	return token
end

local function tierOf(def: any): number
	return CO.tierOf[def.rarity]
end

-- Les couches d'un style, plus celles que sa rarete ajoute.
local function layers(slot: string, def: any, base: { any }): { any }
	local out = {}
	local tier = tierOf(def)
	for _, list in { base, CO.tierLayers[slot] or {} } do
		for _, layer in list do
			if (layer.tier or 1) <= tier then
				table.insert(out, layer)
			end
		end
	end
	return out
end

-- Un emetteur de particules decrit par Config, aux couleurs de `def`.
local function emit(
	parent: Instance,
	p: any,
	def: any,
	boost: { rate: number, size: number }?
): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	local rate = if boost then boost.rate else 1
	local grow = if boost then boost.size else 1
	e.Texture = CO.textures[p.tex]
	local c1 = rgb(pick(p.c1, def))
	e.Color = if p.c2 then ColorSequence.new(c1, rgb(pick(p.c2, def))) else ColorSequence.new(c1)
	e.Size = NumberSequence.new(p.size[1] * grow, p.size[2] * grow)
	e.Transparency = NumberSequence.new(p.alpha[1], p.alpha[2])
	e.Rate = p.rate * rate
	e.Lifetime = NumberRange.new(p.life[1], p.life[2])
	e.Speed = NumberRange.new(p.speed[1], p.speed[2])
	local spread = p.spread or 0
	e.SpreadAngle = Vector2.new(spread, spread)
	e.LightEmission = p.light or 0
	local rot = p.rot or 0
	e.RotSpeed = NumberRange.new(-rot, rot)
	e.Rotation = NumberRange.new(0, 360)
	e.Acceleration = Vector3.new(0, p.accel or 0, 0)
	e.LockedToPart = p.lock == true
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = parent
	return e
end

-- Une boule lumineuse soudee a `anchor` (le coeur d'une comete, un halo).
local function glowBall(anchor: BasePart, color: Color3, size: number, transparency: number): Part
	local ball = Instance.new("Part")
	ball.Name = "RoyaleLueur"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(size, size, size)
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Transparency = transparency
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.Massless = true
	ball.CastShadow = false
	ball.CFrame = anchor.CFrame
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = ball
	weld.Parent = ball
	ball.Parent = anchor
	return ball
end

-- Un ruban de a vers b entre deux points de `part`. Rend le ruban et ses
-- deux attaches (pour les enlever).
local function ribbon(
	part: BasePart,
	width: number,
	def: any,
	life: number,
	light: number
): { Instance }
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, width / 2, 0)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -width / 2, 0)
	a1.Parent = part
	local trail = Instance.new("Trail")
	trail.Name = "RoyaleTrainee"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(rgb(def.a), rgb(def.b))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = life
	trail.LightEmission = light
	trail.FaceCamera = true
	trail.Parent = part
	return { trail, a0, a1 }
end

local function cleaner(things: { Instance }): () -> ()
	return function()
		for _, thing in things do
			thing:Destroy()
		end
	end
end

-- La comete d'arrivee : un coeur, sa lueur, ses particules, sa queue.
-- Rend de quoi l'eteindre a l'atterrissage.
function CosmeticFx.comet(root: BasePart, def: any): () -> ()
	local C = CO.comet
	local tier = tierOf(def)
	local things: { Instance } = {}
	local core = glowBall(root, rgb(def.a), C.coreSize[tier], 0)
	table.insert(things, core)
	if tier >= 3 then
		table.insert(things, glowBall(root, rgb(def.a), C.coreSize[tier] * 2.2, 0.8))
	end
	local light = Instance.new("PointLight")
	light.Color = rgb(def.a)
	light.Range = C.lightRange
	light.Brightness = C.lightBrightness
	light.Parent = core
	local at = Instance.new("Attachment")
	at.Parent = root
	table.insert(things, at)
	local boost = { rate = C.rateBoost, size = C.sizeBoost }
	for _, p in layers("comet", def, CO.styles.comet[def.style]) do
		-- Les couches collees au coeur ne s'etalent pas : pas d'acceleration.
		emit(at, p, def, if p.lock then nil else boost)
	end
	for _, thing in ribbon(core, C.ribbonWidth[tier], def, C.ribbonLife[tier], 1) do
		table.insert(things, thing)
	end
	local clean = cleaner(things)
	if def.signature then
		local stopSignature = Signatures.comet(def.signature, core, def)
		return function()
			stopSignature()
			clean()
		end
	end
	return clean
end

-- La trainee portee : un ruban et des particules aux pieds. Rend les
-- emetteurs (le jeu les coupe a l'arret et cache) et tout ce qui est pose.
function CosmeticFx.trail(
	root: BasePart,
	def: any
): (
	{ ParticleEmitter },
	{ Instance },
	((on: boolean, root: BasePart) -> ())?
)
	local tier = tierOf(def)
	local things = ribbon(root, CO.trail.height, def, CO.trailLife[tier], CO.trailLight[def.style])
	local feet = Instance.new("Attachment")
	feet.Name = "RoyaleTraineePieds"
	feet.Position = Vector3.new(0, -CO.trail.feet, 0)
	feet.Parent = root
	table.insert(things, feet)
	local emitters: { ParticleEmitter } = {}
	for _, p in layers("trail", def, CO.styles.trail[def.style]) do
		table.insert(emitters, emit(feet, p, def))
	end
	-- Une legendaire laisse aussi ses traces (Signatures).
	local step = if def.signature then Signatures.trail(def.signature, def) else nil
	return emitters, things, step
end

-- Le cocon : sa matiere, sa lueur, ses ornements, ses particules.
function CosmeticFx.cocoon(shell: BasePart, def: any)
	local style = CO.styles.cocoon[def.style]
	shell.Material = (Enum.Material :: any)[style.material]
	shell.Color = rgb(def.a)
	shell.Reflectance = style.reflectance or 0
	shell.Transparency = style.transparency or 0
	local light = shell:FindFirstChildOfClass("PointLight")
	if light then
		light.Color = rgb(def.b)
		-- La lumiere est au centre du cocon : une coque claire en sortait
		-- blanche, brulee (vu en vitrine). Plus la coque est claire, plus la
		-- lumiere baisse.
		local a = def.a
		local luminance = (0.3 * a[1] + 0.59 * a[2] + 0.11 * a[3]) / 255
		light.Brightness *= math.clamp(1 - luminance, CO.cocoonLightFloor, 1)
	end
	if style.ribs then
		-- Des cotes : des anneaux plats autour de la coque, de bas en haut.
		local height = shell.Size.Y * style.ribs.reach
		local mesh = shell:FindFirstChildOfClass("SpecialMesh")
		local tall = shell.Size.Y * (if mesh then mesh.Scale.Y else 1)
		for i = 1, style.ribs.count do
			local y = (-height / 2 + (i - 0.5) / style.ribs.count * height) * tall / shell.Size.Y
			local k = math.sqrt(math.max(0, 1 - (2 * y / tall) ^ 2))
			local d = shell.Size.X * k + style.ribs.thick
			local ring = Instance.new("Part")
			ring.Name = "RoyaleCote"
			ring.Shape = Enum.PartType.Cylinder
			ring.Size = Vector3.new(style.ribs.thick, d, d)
			ring.Material = Enum.Material.SmoothPlastic
			ring.Color = rgb(def.b)
			ring.CanCollide = false
			ring.CanQuery = false
			ring.CanTouch = false
			ring.Anchored = true
			ring.CastShadow = false
			ring.CFrame = shell.CFrame * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2)
			ring.Parent = shell
		end
	end
	local at = Instance.new("Attachment")
	at.Parent = shell
	for _, p in layers("cocoon", def, style.particles) do
		emit(at, p, def)
	end
	if def.signature then
		Signatures.cocoon(def.signature, shell, def)
	end
end

-- L'aspiration : des particules qui montent avec celui qu'on aspire.
-- Rend de quoi les enlever.
function CosmeticFx.capture(root: BasePart, def: any): () -> ()
	local at = Instance.new("Attachment")
	at.Parent = root
	for _, p in layers("capture", def, CO.styles.capture[def.style]) do
		emit(at, p, def)
	end
	local clean = cleaner({ at })
	if def.signature then
		local stopSignature = Signatures.capture(def.signature, root, def)
		return function()
			stopSignature()
			clean()
		end
	end
	return clean
end

-- La batte en main (au Ventre, ou l'objet Batte) : un manche, un pommeau,
-- un col et un fut, a la matiere de son skin (ou la batte de base). Rend le
-- modele (le jeu l'enleve quand on ne la tient plus).
function CosmeticFx.bat(hand: BasePart, def: any?): Model
	local B = CO.batShape
	local look = def or CO.batDefault
	local style = CO.batStyles[look.style]
	local model = Instance.new("Model")
	model.Name = "RoyaleBatte"
	local grip = hand:FindFirstChild("RightGripAttachment")
	local base = hand.CFrame
		* CFrame.new(if grip and grip:IsA("Attachment") then grip.Position else Vector3.zero)
		* CFrame.Angles(math.rad(B.holdTilt), 0, 0)
	local upright = CFrame.Angles(0, 0, math.pi / 2)
	local function cylinder(
		name: string,
		length: number,
		width: number,
		from: number,
		color: Color3,
		material: Enum.Material
	): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(length, width, width)
		p.CFrame = base * CFrame.new(0, from + length / 2, 0) * upright
		p.Color = color
		p.Material = material
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.Parent = model
		return p
	end
	local mat = (Enum.Material :: any)[style.material]
	local a, b = rgb(look.a), rgb(look.b)
	local handle =
		cylinder("Manche", B.handle.length, B.handle.width, -B.grip, b, Enum.Material.Fabric)
	local knob = Instance.new("Part")
	knob.Name = "Pommeau"
	knob.Shape = Enum.PartType.Ball
	knob.Size = Vector3.one * B.knob
	knob.CFrame = base * CFrame.new(0, -B.grip, 0)
	knob.Color = b
	knob.Material = Enum.Material.SmoothPlastic
	knob.CanCollide = false
	knob.CanQuery = false
	knob.CanTouch = false
	knob.Massless = true
	knob.Parent = model
	local neckFrom = B.handle.length - B.grip
	local neck = cylinder("Col", B.neck.length, B.neck.width, neckFrom, a, mat)
	local barrelFrom = neckFrom + B.neck.length
	local barrel = cylinder("Fut", B.barrel.length, B.barrel.width, barrelFrom, a, mat)
	for _, p in { neck, barrel } do
		p.Reflectance = style.reflectance or 0
		p.Transparency = style.transparency or 0
	end
	-- Les ornements.
	if style.bands then
		for i = 1, style.bands.count do
			local y = barrelFrom + (i / (style.bands.count + 1)) * B.barrel.length
			local band = cylinder(
				"Bande",
				0.12,
				B.barrel.width + 0.04,
				y,
				b,
				if style.bands.neon then Enum.Material.Neon else Enum.Material.Fabric
			)
			band.CanQuery = false
		end
	end
	if style.nails then
		for i = 1, style.nails do
			local nail = Instance.new("Part")
			nail.Name = "Clou"
			nail.Size = Vector3.new(0.06, 0.06, 0.45)
			nail.CFrame = base
				* CFrame.new(0, barrelFrom + (i - 0.5) / style.nails * B.barrel.length, 0)
				* CFrame.Angles(0, i * 2.4, 0)
				* CFrame.new(0, 0, B.barrel.width / 2)
			nail.Color = b
			nail.Material = Enum.Material.Metal
			nail.CanCollide = false
			nail.CanQuery = false
			nail.CanTouch = false
			nail.Massless = true
			nail.Parent = model
		end
	end
	if style.barbed then
		local n = style.barbed * 10
		for i = 1, n do
			local wire = Instance.new("Part")
			wire.Name = "Barbele"
			wire.Size = Vector3.new(0.05, 0.05, 0.22)
			wire.CFrame = base
				* CFrame.new(0, barrelFrom + i / n * B.barrel.length, 0)
				* CFrame.Angles(0, i / 10 * math.pi * 2, 0)
				* CFrame.new(B.barrel.width / 2 + 0.02, 0, 0)
			wire.Color = b
			wire.Material = Enum.Material.Metal
			wire.CanCollide = false
			wire.CanQuery = false
			wire.CanTouch = false
			wire.Massless = true
			wire.Parent = model
		end
	end
	-- Tout tient au manche, et le manche a la main.
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and p ~= handle then
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = p
			w.Parent = p
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = handle
	weld.Parent = handle
	model.PrimaryPart = handle
	if def then
		local at = Instance.new("Attachment")
		at.Parent = barrel
		for _, p in layers("bat", def, style.particles or {}) do
			emit(at, p, def)
		end
		if def.signature then
			Signatures.bat(def.signature, barrel, def)
		end
	end
	return model
end

return CosmeticFx
