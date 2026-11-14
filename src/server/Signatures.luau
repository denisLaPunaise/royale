--!strict
--[[
	Signatures — l'element qui n'appartient qu'a chaque legendaire
	(Config.cosmetics.signatures ; choisi avec Josh le 14 novembre 2026 :
	« les plus rares bien plus beaux, travailles, animes »).

	De vraies pieces animees : un anneau qui tourne, un oeil qui regarde, un
	cocon qui bat, des traces au sol. Aucune ne touche, ne bloque ni n'arrete
	un rayon : ce sont des effets.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Signatures = {}

local SG = Config.cosmetics.signatures
local BLACK = Color3.fromRGB(8, 4, 6)

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Une piece d'effet : lumineuse, sans collision, sans rayon, sans ombre.
local function piece(shape: Enum.PartType, size: Vector3, color: Color3, neon: boolean): Part
	local p = Instance.new("Part")
	p.Name = "RoyaleSignature"
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- Un moyeu invisible soude a `anchor` par une soudure qu'on fait tourner :
-- tout ce qu'on lui soude tourne avec, une seule valeur a changer par image.
local function hub(anchor: BasePart): (Part, Weld)
	local h = piece(Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.2), BLACK, false)
	h.Transparency = 1
	h.CFrame = anchor.CFrame
	local weld = Instance.new("Weld")
	weld.Part0 = anchor
	weld.Part1 = h
	weld.Parent = h
	h.Parent = anchor
	return h, weld
end

local function attach(to: BasePart, p: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = p
	w.Parent = p
	p.Parent = to
end

-- Un anneau de segments lumineux autour d'un moyeu (dans son plan XZ).
local function ring(h: BasePart, radius: number, thick: number, color: Color3)
	local n = 16
	local length = 2 * math.pi * radius / n * 1.08
	for i = 1, n do
		local a = i / n * math.pi * 2
		local seg = piece(Enum.PartType.Block, Vector3.new(thick, thick, length), color, true)
		seg.CFrame = h.CFrame * CFrame.Angles(0, a, 0) * CFrame.new(radius, 0, 0)
		attach(h, seg)
	end
end

-- Un oeil (globe, iris, pupille) dont l'avant (-Z) regarde devant.
local function eyeParts(
	at: CFrame,
	size: number,
	iris: number,
	pupil: number,
	white: Color3,
	irisColor: Color3
): { Part }
	-- Le blanc mat : en neon, il bavait en une boule aveuglante qui cachait
	-- l'iris (vu en vitrine) ; seul l'iris luit.
	local globe = piece(Enum.PartType.Ball, Vector3.new(size, size, size), white, false)
	globe.CFrame = at
	local disc = piece(Enum.PartType.Cylinder, Vector3.new(0.2, iris, iris), irisColor, true)
	disc.CFrame = at * CFrame.new(0, 0, -size / 2 + 0.05) * CFrame.Angles(0, math.pi / 2, 0)
	local dot = piece(Enum.PartType.Cylinder, Vector3.new(0.22, pupil, pupil), BLACK, false)
	dot.CFrame = at * CFrame.new(0, 0, -size / 2 - 0.02) * CFrame.Angles(0, math.pi / 2, 0)
	return { globe, disc, dot }
end

-- Une boucle par image, jusqu'a ce que `alive` dise non. Rend de quoi
-- l'arreter.
local function loop(alive: () -> boolean, step: (t: number, dt: number) -> ()): () -> ()
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		if not alive() then
			connection:Disconnect()
			return
		end
		step(os.clock() - started, dt)
	end)
	return function()
		connection:Disconnect()
	end
end

local traces: Folder? = nil
local function traceFolder(): Folder
	if traces == nil or traces.Parent == nil then
		local f = Instance.new("Folder")
		f.Name = "RoyaleTraces"
		f.Parent = workspace
		traces = f
	end
	return traces :: Folder
end

-- S'efface en `seconds` puis disparait.
local function fadeOut(p: BasePart, seconds: number, goal: { [string]: any }?)
	local props: { [string]: any } = { Transparency = 1 }
	for k, v in goal or {} do
		props[k] = v
	end
	TweenService:Create(p, TweenInfo.new(seconds, Enum.EasingStyle.Quad), props):Play()
	task.delay(seconds, function()
		p:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- Les cometes (le coeur est soude a la racine, qui file).
--------------------------------------------------------------------------------

function Signatures.comet(kind: string, core: BasePart, def: any): () -> ()
	local things: { Instance } = {}
	local spinners: { { weld: Weld, axis: Vector3, speed: number, tilt: CFrame } } = {}
	local function spinner(
		radius: number,
		thick: number,
		color: Color3,
		speed: number,
		axis: Vector3,
		tilt: CFrame
	)
		local h, weld = hub(core)
		ring(h, radius, thick, color)
		table.insert(things, h)
		table.insert(spinners, { weld = weld, axis = axis, speed = speed, tilt = tilt })
	end
	if kind == "goldRing" then
		local S = SG.goldRing
		spinner(
			S.ring / 2,
			S.thick,
			rgb(def.a),
			S.spin,
			Vector3.yAxis,
			CFrame.Angles(math.rad(70), 0, 0)
		)
		local h, weld = hub(core)
		for i = 1, S.motes do
			local a = i / S.motes * math.pi * 2
			local mote = piece(Enum.PartType.Ball, Vector3.one * S.moteSize, rgb(def.b), true)
			mote.CFrame = h.CFrame * CFrame.new(math.cos(a) * S.orbit, 0, math.sin(a) * S.orbit)
			attach(h, mote)
		end
		table.insert(things, h)
		table.insert(spinners, {
			weld = weld,
			axis = Vector3.yAxis,
			speed = S.orbitSpeed,
			tilt = CFrame.Angles(0, 0, math.rad(25)),
		})
	elseif kind == "emberEye" or kind == "firstGaze" then
		local S = SG[kind]
		local h = hub(core)
		for _, p in eyeParts(h.CFrame, S.eye, S.iris, S.pupil, rgb(S.white), rgb(def.b)) do
			attach(h, p)
		end
		table.insert(things, h)
		if kind == "firstGaze" then
			spinner(S.ring / 2, S.thick, rgb(def.b), S.spin, Vector3.xAxis, CFrame.new())
			spinner(
				S.ring / 2 * 1.15,
				S.thick,
				rgb(def.a),
				-S.spin * 0.8,
				Vector3.zAxis,
				CFrame.Angles(0, 0, math.rad(90))
			)
		end
	end
	local alive = true
	local stop = loop(function()
		return alive and core.Parent ~= nil
	end, function(t: number)
		for _, s in spinners do
			s.weld.C0 = s.tilt * CFrame.fromAxisAngle(s.axis, t * s.speed)
		end
	end)
	return function()
		alive = false
		stop()
		for _, thing in things do
			thing:Destroy()
		end
	end
end

--------------------------------------------------------------------------------
-- Les cocons (la coque est ancree ; l'effet vit tant qu'elle existe).
--------------------------------------------------------------------------------

function Signatures.cocoon(kind: string, shell: BasePart, def: any)
	local light = shell:FindFirstChildOfClass("PointLight")
	local baseLight = if light then light.Brightness else 0
	if kind == "eyelid" then
		local S = SG.eyelid
		local slits: { { part: Part, at: CFrame } } = {}
		local r = shell.Size.X / 2
		for _, side in { -1, 1 } do
			local slit =
				piece(Enum.PartType.Block, Vector3.new(S.width, S.closed, 0.25), rgb(def.b), true)
			local at = shell.CFrame * CFrame.new(0, 0, side * (r - 0.05))
			slit.CFrame = at
			slit.Anchored = true
			slit.Parent = shell
			table.insert(slits, { part = slit, at = at })
		end
		loop(function()
			return shell.Parent ~= nil
		end, function(t: number)
			-- S'ouvre doucement, reste un instant, se referme.
			local x = (t % S.period) / S.period
			local o = if x < S.openPart then math.sin(x / S.openPart * math.pi) else 0
			for _, s in slits do
				s.part.Size = Vector3.new(S.width, S.closed + (S.open - S.closed) * o, 0.25)
				s.part.CFrame = s.at
			end
			if light then
				light.Brightness = baseLight * (0.4 + o)
			end
		end)
	elseif kind == "heartbeat" then
		local S = SG.heartbeat
		local mesh = shell:FindFirstChildOfClass("SpecialMesh")
		local baseScale = if mesh then mesh.Scale else Vector3.one
		loop(function()
			return shell.Parent ~= nil
		end, function(t: number)
			-- Un double battement : boum-boum, puis un silence.
			local x = t % S.period
			local beat = math.exp(-((x - 0.06) / 0.05) ^ 2)
				+ 0.7 * math.exp(-((x - 0.3) / 0.05) ^ 2)
			if mesh then
				mesh.Scale = baseScale * (1 + S.swell * beat)
			end
			if light then
				light.Brightness = baseLight * (1 + S.glow * beat)
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- Les trainees : appelees a chaque verification (ShopService), `on` dit si
-- l'on bouge hors d'une cachette.
--------------------------------------------------------------------------------

function Signatures.trail(kind: string, def: any): (on: boolean, root: BasePart) -> ()
	local S = SG[kind]
	local last = 0
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	return function(on: boolean, root: BasePart)
		if not on or os.clock() - last < S.every then
			return
		end
		last = os.clock()
		local character = root.Parent
		params.FilterDescendantsInstances = { character :: Instance, traceFolder() }
		if kind == "gazeEyes" then
			local at = CFrame.lookAt(
				root.Position
					- root.CFrame.LookVector * 2
					+ Vector3.new(math.random() - 0.5, 0.5, 0),
				root.Position
			)
			for _, p in eyeParts(at, S.eye, S.eye * 0.55, S.eye * 0.25, rgb(S.white), rgb(def.a)) do
				p.Anchored = true
				p.Parent = traceFolder()
				fadeOut(p, S.fade, { Position = p.Position + Vector3.new(0, S.rise, 0) })
			end
			return
		end
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -S.reach, 0), params)
		if hit == nil then
			return
		end
		local ground = CFrame.new(hit.Position + Vector3.new(0, 0.04, 0))
			* CFrame.Angles(0, math.random() * math.pi * 2, 0)
		if kind == "riftSteps" then
			-- Deux craquelures en braise qui se croisent, puis s'eteignent.
			for k = 0, 1 do
				local length = S.length[1] + math.random() * (S.length[2] - S.length[1])
				local crack =
					piece(Enum.PartType.Block, Vector3.new(S.width, 0.06, length), rgb(def.a), true)
				crack.CFrame = ground * CFrame.Angles(0, k * (0.6 + math.random() * 0.6), 0)
				crack.Anchored = true
				crack.Parent = traceFolder()
				fadeOut(crack, S.fade, { Color = rgb(def.b) })
			end
		elseif kind == "voidSteps" then
			local disc =
				piece(Enum.PartType.Cylinder, Vector3.new(0.08, S.size, S.size), BLACK, false)
			disc.CFrame = ground * CFrame.Angles(0, 0, math.pi / 2)
			disc.Anchored = true
			disc.Parent = traceFolder()
			local rim = piece(
				Enum.PartType.Cylinder,
				Vector3.new(0.06, S.size * 1.2, S.size * 1.2),
				rgb(def.a),
				true
			)
			rim.CFrame = ground * CFrame.new(0, -0.01, 0) * CFrame.Angles(0, 0, math.pi / 2)
			rim.Transparency = 0.4
			rim.Anchored = true
			rim.Parent = traceFolder()
			fadeOut(disc, S.fade, { Size = Vector3.new(0.08, 0.2, 0.2) })
			fadeOut(rim, S.fade, { Size = Vector3.new(0.06, 0.2, 0.2) })
		end
	end
end

--------------------------------------------------------------------------------
-- Les aspirations (la racine monte vers l'Oeil). Rend de quoi les enlever.
--------------------------------------------------------------------------------

function Signatures.capture(kind: string, root: BasePart, def: any): () -> ()
	local things: { Part } = {}
	local function add(p: Part): Part
		p.Anchored = true
		p.Parent = traceFolder()
		table.insert(things, p)
		return p
	end
	local stop: () -> ()
	if kind == "blackHole" then
		local S = SG.blackHole
		local hole = add(piece(Enum.PartType.Ball, Vector3.one * 0.1, BLACK, false))
		local segs: { Part } = {}
		local n = 18
		for _ = 1, n do
			table.insert(
				segs,
				add(
					piece(
						Enum.PartType.Block,
						Vector3.new(S.thick, S.thick, 2 * math.pi * S.ring / 2 / n * 1.1),
						rgb(def.a),
						true
					)
				)
			)
		end
		stop = loop(function()
			return root.Parent ~= nil
		end, function(t: number)
			local k = math.min(1, t / S.grow)
			local center = root.Position + Vector3.new(0, S.above, 0)
			hole.Size = Vector3.one * math.max(0.1, S.size * k)
			hole.CFrame = CFrame.new(center)
			local tilt = CFrame.new(center) * CFrame.Angles(math.rad(20), 0, math.rad(10))
			for i, seg in segs do
				local a = i / n * math.pi * 2 + t * S.spin
				seg.CFrame = tilt * CFrame.Angles(0, a, 0) * CFrame.new(S.ring / 2 * k, 0, 0)
			end
		end)
	elseif kind == "supernova" then
		local S = SG.supernova
		local flash = add(piece(Enum.PartType.Ball, Vector3.one, rgb(def.a), true))
		local discs: { Part } = {}
		for _ = 1, S.rings do
			table.insert(
				discs,
				add(piece(Enum.PartType.Cylinder, Vector3.new(0.2, 1, 1), rgb(def.b), true))
			)
		end
		stop = loop(function()
			return root.Parent ~= nil
		end, function(t: number)
			local k = math.min(1, t / S.seconds)
			flash.Size = Vector3.one * (1 + (S.size - 1) * k)
			flash.Transparency = k
			flash.CFrame = CFrame.new(root.Position)
			for i, disc in discs do
				local d = 1 + S.size * 1.4 * math.min(1, k * (1 + i * 0.3))
				disc.Size = Vector3.new(0.2, d, d)
				disc.Transparency = 0.3 + 0.7 * k
				disc.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, math.pi / 2 + i * 0.5)
			end
		end)
	else -- innerEye
		local S = SG.innerEye
		local parts = eyeParts(CFrame.new(), S.eye, S.iris, S.pupil, rgb(S.white), rgb(def.a))
		local offsets: { CFrame } = {}
		for _, p in parts do
			table.insert(offsets, p.CFrame)
			add(p)
		end
		local sizes: { Vector3 } = {}
		for i, p in parts do
			sizes[i] = p.Size
		end
		stop = loop(function()
			return root.Parent ~= nil
		end, function(t: number)
			local k = math.min(1, t / S.open)
			local center = root.Position + Vector3.new(0, S.above, 0)
			local look = CFrame.lookAt(center, root.Position)
			for i, p in parts do
				p.Size = sizes[i] * math.max(0.05, k)
				p.CFrame = look * CFrame.new(offsets[i].Position * k) * offsets[i].Rotation
			end
		end)
	end
	return function()
		stop()
		for _, p in things do
			p:Destroy()
		end
	end
end

--------------------------------------------------------------------------------
-- Les battes (le fut est soude a la main ; l'effet vit tant qu'il existe).
--------------------------------------------------------------------------------

function Signatures.bat(kind: string, barrel: BasePart, def: any)
	local length, width = barrel.Size.X, barrel.Size.Y
	if kind == "riftBat" then
		-- Des fentes de braise en biais sur le fut, et il brule.
		local S = SG.riftBat
		for i = 1, S.cracks do
			local crack = piece(
				Enum.PartType.Block,
				Vector3.new(length * 0.35, S.crackWidth, 0.05),
				rgb(def.b),
				true
			)
			crack.CFrame = barrel.CFrame
				* CFrame.new((i / (S.cracks + 1) - 0.5) * length, 0, 0)
				* CFrame.Angles(i * 1.9, 0, 0)
				* CFrame.new(0, 0, width / 2)
				* CFrame.Angles(0, 0, math.rad(25))
			attach(barrel, crack)
		end
		local fire = Instance.new("Fire")
		fire.Color = rgb(def.b)
		fire.SecondaryColor = rgb(def.a)
		fire.Size = 2
		fire.Heat = 4
		fire.Parent = barrel
	elseif kind == "eyeBat" then
		-- Un oeil au bout, qui regarde autour de lui.
		local S = SG.eyeBat
		local h, weld = hub(barrel)
		-- L'avant de l'oeil (-Z) tourne vers le bout de la batte (+X du fut).
		local tip = barrel.CFrame
			* CFrame.new(length / 2 + S.eye * 0.3, 0, 0)
			* CFrame.Angles(0, -math.pi / 2, 0)
		h.CFrame = tip
		weld.C0 = barrel.CFrame:ToObjectSpace(tip)
		for _, p in eyeParts(tip, S.eye, S.iris, S.pupil, rgb(S.white), rgb(def.b)) do
			attach(h, p)
		end
		local base = weld.C0
		local goal, current = CFrame.new(), CFrame.new()
		local nextGlance = 0
		loop(function()
			return barrel.Parent ~= nil
		end, function(t: number, dt: number)
			if t >= nextGlance then
				nextGlance = t + S.glance[1] + math.random() * (S.glance[2] - S.glance[1])
				goal = CFrame.Angles((math.random() - 0.5) * 1.2, (math.random() - 0.5) * 1.6, 0)
			end
			current = current:Lerp(goal, math.min(1, dt * 6))
			weld.C0 = base * current
		end)
	end
end

return Signatures
