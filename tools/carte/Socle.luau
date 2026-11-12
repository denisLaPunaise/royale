--!strict
--[[
	Socle — le sol de toute la carte, en terrain : la campagne entre les zones,
	la mer a l'ouest, le Cratere au centre, les collines qui ferment l'horizon
	au nord, a l'est et au sud, le Marais plus bas et humide. Chaque zone
	construit ensuite sur un sol deja aplani pour elle (Plan.zones).

	Ecrit en voxels par morceaux (`WriteVoxels`), avec une occupation douce :
	les pentes sont lisses, pas en escalier.

	Puis il se mesure au rayon : la mer est de l'eau, le Cratere est creux, le
	sol des villes est plat, les collines ferment bien l'horizon.
]]

local RESOLUTION = 4
-- Ce que les voxels couvrent en hauteur : du fond de la mer au sommet des
-- collines du bord.
local MIN_Y = -24
-- Assez haut pour les sommets du massif (a 220, ils etaient coupes a plat,
-- vu a l'ecran le 12 novembre 2026).
local MAX_Y = 340
-- Le cote d'un morceau, en colonnes de voxels : assez petit pour rendre la
-- main entre deux morceaux (la recette tourne en tache de fond).
local CHUNK = 50

-- La palette du terrain : une campagne passee, presque grise, sous un ciel
-- couvert. Le rouge reste a l'Oeil ; le Cratere est noir de brulure.
local MATERIAL_COLORS = {
	[Enum.Material.Grass] = Color3.fromRGB(88, 96, 68),
	[Enum.Material.LeafyGrass] = Color3.fromRGB(86, 94, 64),
	[Enum.Material.Ground] = Color3.fromRGB(104, 96, 78),
	[Enum.Material.Mud] = Color3.fromRGB(86, 80, 64),
	[Enum.Material.Sand] = Color3.fromRGB(150, 140, 118),
	[Enum.Material.Rock] = Color3.fromRGB(96, 94, 90),
	[Enum.Material.Basalt] = Color3.fromRGB(40, 36, 36),
	[Enum.Material.Slate] = Color3.fromRGB(70, 66, 64),
	-- Pas l'eau : sa couleur se regle par `Terrain.WaterColor` (SetMaterialColor
	-- la refuse, vu dans Studio le 12 novembre 2026).
}

local function smoothstep(t: number): number
	local c = math.clamp(t, 0, 1)
	return c * c * (3 - 2 * c)
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

return function(_O: any, Plan: any)
	local HALF = Plan.HALF
	local crater = Plan.CRATER

	-- Un bruit fractal : plusieurs couches de plus en plus fines, comme un
	-- vrai relief (de grandes formes, puis des bosses, puis du grain).
	local function fbm(x: number, z: number, octaves: number, seed: number): number
		local sum, amp, freq, norm = 0, 1, 1, 0
		for i = 1, octaves do
			sum += amp * math.noise(x * freq, z * freq, seed + i * 1.37)
			norm += amp
			amp *= 0.5
			freq *= 2.03
		end
		return sum / norm
	end

	-- Des cretes : le bruit replie sur lui-meme fait des aretes de montagne
	-- plutot que des bosses rondes.
	local function ridged(x: number, z: number, octaves: number, seed: number): number
		local sum, amp, freq, norm = 0, 1, 1, 0
		for i = 1, octaves do
			local n = 1 - math.abs(math.noise(x * freq, z * freq, seed + i * 2.11)) * 2
			sum += amp * n * n
			norm += amp
			amp *= 0.5
			freq *= 2.1
		end
		return sum / norm
	end

	-- La cote ondule et forme des anses : une ligne droite se verrait de loin.
	local function coastX(z: number): number
		-- Des caps et des anses sur toute la longueur : a 80 studs d'ecart, la
		-- cote paraissait encore tiree a la regle (vu a l'ecran).
		return Plan.COAST_X + 170 * fbm(z / 650, 0.5, 4, 7.3) + 40 * math.noise(z / 170, 3.1)
	end

	-- La distance au lit de la riviere (Plan.RIVER), en studs.
	local function riverDistance(x: number, z: number): number
		local best = math.huge
		local points = Plan.RIVER.points
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local abx, abz = b[1] - a[1], b[2] - a[2]
			local t =
				math.clamp(((x - a[1]) * abx + (z - a[2]) * abz) / (abx * abx + abz * abz), 0, 1)
			local px, pz = a[1] + abx * t, a[2] + abz * t
			-- Le lit serpente : on le decale sur le cote de sa ligne. (Ajouter le
			-- decalage a la distance coupait la riviere en morceaux, mesure.)
			local wobble = 45 * math.noise(px / 230, pz / 230, 5.5)
				+ 8 * math.noise(px / 60, pz / 60, 6.6)
			local len = math.sqrt(abx * abx + abz * abz)
			local side = ((x - px) * -abz + (z - pz) * abx) / len
			local along = math.sqrt(math.max((x - px) ^ 2 + (z - pz) ^ 2 - side * side, 0))
			best = math.min(best, math.sqrt((side - wobble) ^ 2 + along * along))
		end
		return best
	end

	-- Le relief libre de la campagne, deforme pour qu'aucune forme ne se
	-- repete : de longues ondulations, et des collines qui ne sont pas des
	-- bosses rondes.
	local function wild(x: number, z: number): number
		local wx = x + 90 * math.noise(x / 520, z / 520, 11.1)
		local wz = z + 90 * math.noise(x / 520, z / 520, 12.7)
		local h = 24 * fbm(wx / 600, wz / 600, 5, 3.3)
		-- Une vallee cotiere, comme sur une vraie cote : le pays monte doucement
		-- vers le nord et vers l'est, la riviere coule au fond, la mer est a
		-- l'ouest. Les zones sont posees a des hauteurs qui suivent cette pente.
		h += 0.034 * math.max(z + 250, 0) + 0.014 * math.max(x, 0)
		-- Les collines nommees du plan (pas de symetrie : chacune a sa forme).
		for _, hill in Plan.HILLS do
			local d = math.sqrt((wx - hill.x) ^ 2 + ((wz - hill.z) / hill.stretch) ^ 2)
			if d < hill.radius * 1.6 then
				local t = math.max(0, 1 - (d / (hill.radius * 1.6)) ^ 2)
				h += hill.height * t * t * (0.75 + 0.5 * ridged(wx / 260, wz / 260, 3, hill.x))
			end
		end
		return h
	end

	-- Les montagnes qui ferment l'horizon : des CHAINES, comme les vraies
	-- (Plan.RIDGES), pas un anneau autour d'un carre (Josh, 12 novembre
	-- 2026 : « trop carre, un gros angle de montagne »). Chaque chaine suit une
	-- ligne de cretes ; sa hauteur varie le long de la ligne, et ses flancs
	-- descendent en eperons irreguliers.
	local function distanceToLine(x: number, z: number, points: { { number } }): (number, number)
		local best, at = math.huge, 0
		local walked, total = 0, 0
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			total += math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
		end
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local abx, abz = b[1] - a[1], b[2] - a[2]
			local len = math.sqrt(abx * abx + abz * abz)
			local t = math.clamp(((x - a[1]) * abx + (z - a[2]) * abz) / (len * len), 0, 1)
			local d = math.sqrt((x - a[1] - abx * t) ^ 2 + (z - a[2] - abz * t) ^ 2)
			if d < best then
				best = d
				at = (walked + len * t) / total
			end
			walked += len
		end
		return best, at
	end

	local function mountains(x: number, z: number): number
		local highest = 0
		-- Les flancs ne sont pas des lignes paralleles : on deforme l'espace.
		local wx = x + 120 * math.noise(x / 400, z / 400, 23.3)
		local wz = z + 120 * math.noise(x / 400, z / 400, 24.9)
		for _, ridge in Plan.RIDGES do
			local d, along = distanceToLine(wx, wz, ridge.points)
			if d < ridge.width then
				local t = 1 - d / ridge.width
				-- Plus basse aux deux bouts de la chaine, avec des cols et des
				-- sommets le long de la ligne.
				local ends = math.sin(math.clamp(along, 0, 1) * math.pi) ^ 0.4
				local peaks = 0.7 + 0.6 * math.noise(along * 6, ridge.height, 27.7)
				local h = ridge.height * t ^ 1.6 * ends * peaks
				h *= 0.6 + 0.4 * ridged(x / 520, z / 520, 4, 41.9)
				highest = math.max(highest, h)
			end
		end
		return highest
	end

	-- Le poids d'une zone en ce point : 1 dedans, 0 au-dela du fondu.
	local function zoneWeight(zone: any, x: number, z: number): number
		local dx = math.max(zone.minX - x, 0, x - zone.maxX)
		local dz = math.max(zone.minZ - z, 0, z - zone.maxZ)
		local outside = math.sqrt(dx * dx + dz * dz)
		-- Le bord du fondu ondule : sinon la limite d'une zone dessinerait un
		-- rectangle arrondi dans le paysage.
		local blend = Plan.BLEND * (1 + 0.4 * math.noise(x / 150, z / 150, 17.7))
		return 1 - smoothstep(outside / blend)
	end

	-- La hauteur du sol et sa matiere, partout.
	-- Rend aussi si l'eau peut monter ici : la mer, la riviere et les mares
	-- du Marais, jamais le fond du Cratere (il serait devenu un lac).
	local function surface(x: number, z: number): (number, Enum.Material, boolean)
		local wet = false
		local base = wild(x, z)
		local h = base
		local material = Enum.Material.Grass
		-- De grandes nappes d'herbe haute et de terre battue, aux bords doux :
		-- des taches petites et contrastees faisaient un camouflage (vu a
		-- l'ecran le 12 novembre 2026).
		local patch = math.noise(x / 140, z / 140, 9.9) + 0.35 * math.noise(x / 35, z / 35, 2.2)
		if patch > 0.48 then
			material = Enum.Material.Ground
		elseif patch < -0.25 then
			material = Enum.Material.LeafyGrass
		end

		-- Les zones aplanissent le sol pour leurs batiments, chacune a sa
		-- hauteur : on monte vers la Fete foraine, on descend vers le Marais.
		local strongest = 0
		for _, zone in Plan.zones do
			local w = zoneWeight(zone, x, z)
			if w > strongest then
				strongest = w
				h = lerp(base, zone.ground + (base - zone.ground) * (1 - zone.flat) * 0.3, w)
				if zone.name == "Marais" and w > 0.5 then
					-- Des mares et des ilots d'herbe haute, de la boue au bord de
					-- l'eau : tout en boue, le Marais faisait une tache noire.
					h += 2.4 * math.noise(x / 55, z / 55, 8.8) * w
					wet = true
					material = if math.abs(h - Plan.SEA_LEVEL) < 0.7
						then Enum.Material.Mud
						else Enum.Material.LeafyGrass
				end
			end
		end

		-- Les pentes fortes montrent la terre, puis la roche.
		local slope = math.abs(wild(x + 4, z) - base) + math.abs(wild(x, z + 4) - base)
		if slope > 2.4 and strongest < 0.5 then
			material = if slope > 4 then Enum.Material.Rock else Enum.Material.Ground
		end

		-- La riviere : elle descend des montagnes de l'est, passe entre la
		-- Banlieue et l'Hypermarche, au sud du Cratere, traverse le Marais et
		-- se jette dans la mer.
		local rd = riverDistance(x, z)
		local bed = Plan.RIVER.width * 0.5
		if rd < bed + 30 then
			local bank = smoothstep((bed + 30 - rd) / 30)
			local floor = Plan.SEA_LEVEL - Plan.RIVER.depth * smoothstep((bed - rd) / bed + 0.5)
			h = lerp(h, math.min(h, if rd < bed then floor else Plan.SEA_LEVEL + 0.8), bank)
			if rd < bed + 6 then
				material = if rd < bed then Enum.Material.Mud else Enum.Material.Ground
				wet = true
			end
		end

		-- Le Cratere : une cuvette noire et brulee, au bord releve.
		local r = math.sqrt((x - crater.x) ^ 2 + (z - crater.z) ^ 2)
		local rim = crater.radius * 1.4
		if r < rim then
			local bowl = if r < crater.radius
				then -crater.depth * (1 - (r / crater.radius) ^ 2)
				else 0
			local lip = 4
				* math.sin(
					math.clamp((r - crater.radius * 0.85) / (rim - crater.radius * 0.85), 0, 1)
						* math.pi
				)
			local w = smoothstep((rim - r) / (rim - crater.radius) + 0.0001)
			h = lerp(
				h,
				bowl + lip + 0.6 * math.noise(x / 18, z / 18),
				math.max(w, if r < crater.radius then 1 else 0)
			)
			if r < crater.radius * 0.92 then
				material = Enum.Material.Basalt
			elseif r < rim * 0.95 then
				material = if math.noise(x / 12, z / 12) > 0
					then Enum.Material.Slate
					else Enum.Material.Ground
			end
		end

		-- Les montagnes du bord (pas a l'ouest : la mer ferme l'horizon).
		local coast = coastX(z)
		if x > coast + 80 then
			local m = mountains(x, z)
			if m > 0 then
				-- Jamais sur une zone : la Gare et la Banlieue touchent le bord.
				-- Ni sur la riviere : elle s'y ouvre une vallee pour sortir des
				-- montagnes (sinon elles la recouvraient au bord est, mesure).
				h += m * (1 - strongest) * smoothstep((rd - bed - 10) / 90)
				if m > 25 then
					material = if m > 70 and math.noise(x / 30, z / 30) > -0.1
						then Enum.Material.Rock
						else Enum.Material.LeafyGrass
				end
			end
		end

		-- La mer a l'ouest. Ou la terre arrive haute, elle tombe en falaise de
		-- roche ; ou elle arrive basse, une petite plage de sable. Pas de
		-- plage partout : elle n'aurait rien raconte (Josh, 12 novembre 2026).
		if x < coast + 40 then
			local land = h
			-- Des caps de roche ici et la : la terre s'y releve avant la mer.
			local headland = math.max(0, math.noise(z / 320, 0.7, 13.3)) * 26
			land += headland * smoothstep(1 - (x - coast) / 40)
			local cliff = smoothstep((land - 3) / 8)
			local into = coast + 40 - x
			local beach = lerp(land, -0.6, smoothstep(into / 40))
			local rocky = if x < coast + 4
				then lerp(land, -10, smoothstep((coast + 4 - x) / 10))
				else land
			h = lerp(beach, rocky, cliff)
			-- Le sable seulement au fond des anses basses ; ailleurs l'herbe
			-- descend jusqu'aux galets.
			local cove = math.noise(z / 260, 4.4, 2.2) > 0.15
			material = if cliff > 0.5
				then Enum.Material.Rock
				elseif cove then Enum.Material.Sand
				else Enum.Material.Ground
			if x < coast then
				h = math.min(h, math.max(-0.6 - (coast - x) * 0.25, -18))
				wet = true
			end
		end

		return h, material, wet
	end

	local function build(terrain: Terrain)
		terrain:Clear()
		for material, color in MATERIAL_COLORS do
			terrain:SetMaterialColor(material, color)
		end
		terrain.WaterColor = Color3.fromRGB(58, 72, 74)
		terrain.WaterTransparency = 0.35
		terrain.WaterReflectance = 0.6
		terrain.WaterWaveSize = 0.08
		terrain.WaterWaveSpeed = 6

		local columns = math.floor(Plan.OUTER * 2 / RESOLUTION)
		local layers = math.floor((MAX_Y - MIN_Y) / RESOLUTION)
		for cx = 0, columns - 1, CHUNK do
			for cz = 0, columns - 1, CHUNK do
				local nx = math.min(CHUNK, columns - cx)
				local nz = math.min(CHUNK, columns - cz)
				local materials = table.create(nx)
				local occupancies = table.create(nx)
				for ix = 1, nx do
					local mx = table.create(layers)
					local ox = table.create(layers)
					for iy = 1, layers do
						mx[iy] = table.create(nz, Enum.Material.Air)
						ox[iy] = table.create(nz, 0)
					end
					local x = -Plan.OUTER + (cx + ix - 0.5) * RESOLUTION
					for iz = 1, nz do
						local z = -Plan.OUTER + (cz + iz - 0.5) * RESOLUTION
						local h, material, wet = surface(x, z)
						for iy = 1, layers do
							local yLow = MIN_Y + (iy - 1) * RESOLUTION
							-- Roblox pose la surface d'une demi-case plus haut que
							-- l'occupation lue a plat (mesure : 2 studs de trop) : on
							-- retire cette demi-case.
							local fill = math.clamp((h - yLow) / RESOLUTION - 0.5, 0, 1)
							if fill > 0 then
								mx[iy][iz] = if h - yLow > RESOLUTION * 3
									then Enum.Material.Ground
									else material
								ox[iy][iz] = fill
							elseif wet and yLow + RESOLUTION * 0.5 < Plan.SEA_LEVEL then
								mx[iy][iz] = Enum.Material.Water
								ox[iy][iz] = 1
							end
						end
					end
					materials[ix] = mx
					occupancies[ix] = ox
				end
				local low =
					Vector3.new(-Plan.OUTER + cx * RESOLUTION, MIN_Y, -Plan.OUTER + cz * RESOLUTION)
				local high = low
					+ Vector3.new(nx * RESOLUTION, layers * RESOLUTION, nz * RESOLUTION)
				terrain:WriteVoxels(Region3.new(low, high), RESOLUTION, materials, occupancies)
				task.wait()
			end
		end
	end

	-- La mesure : on lance des rayons d'en haut et on compare a ce que le plan
	-- annonce. Rend la liste des problemes.
	local function measure(): { string }
		local problems: { string } = {}
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { workspace.Terrain }
		params.IgnoreWater = false
		local function hit(x: number, z: number): RaycastResult?
			return workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -500, 0), params)
		end

		-- La mer est de l'eau, loin de la cote.
		for _, z in { -600, 0, 600 } do
			local r = hit(-950, z)
			if r == nil or r.Material ~= Enum.Material.Water then
				table.insert(problems, string.format("pas d'eau en mer a z = %d", z))
			end
		end

		-- Le Cratere est creux au centre.
		local center = hit(crater.x, crater.z)
		if center == nil or center.Position.Y > -crater.depth * 0.7 then
			table.insert(problems, "le Cratere n'est pas assez creux au centre")
		end

		-- Le sol des zones plates est plat et a sa hauteur.
		for _, zone in Plan.zones do
			if zone.flat >= 1 then
				local worst = 0
				for i = 0, 4 do
					for j = 0, 4 do
						local x = lerp(zone.minX + 20, zone.maxX - 20, i / 4)
						local z = lerp(zone.minZ + 20, zone.maxZ - 20, j / 4)
						local r = hit(x, z)
						local y = if r then r.Position.Y else -999
						worst = math.max(worst, math.abs(y - zone.ground))
					end
				end
				if worst > 1.5 then
					table.insert(
						problems,
						string.format("%s : sol pas plat (ecart %.1f)", zone.name, worst)
					)
				end
			end
		end

		-- L'horizon est ferme au nord, a l'est et au sud : quelque part le long
		-- de chaque bord, le relief depasse 40 studs.
		-- Au sud, de simples collines (la plaine ou sort la voie ferree).
		local needed = { nord = 40, est = 40, sud = 18 }
		for _, side in { "nord", "est", "sud" } do
			local highest = -math.huge
			for i = -6, 6 do
				local x = if side == "est" then 1250 else i * 180
				local z = if side == "nord" then 1250 elseif side == "sud" then -1250 else i * 180
				local r = hit(x, z)
				highest = math.max(highest, if r then r.Position.Y else -999)
			end
			if highest < needed[side] then
				table.insert(
					problems,
					string.format("horizon trop bas au %s (%.0f)", side, highest)
				)
			end
		end

		-- La riviere est de l'eau, de l'est a la mer.
		for _, p in Plan.RIVER.points do
			if math.abs(p[1]) < HALF then
				-- Elle serpente : on cherche l'eau en travers de sa ligne.
				local found = false
				for dz = -70, 70, 5 do
					local r = hit(p[1], p[2] + dz)
					if r and r.Material == Enum.Material.Water then
						found = true
						break
					end
				end
				if not found then
					table.insert(
						problems,
						string.format("pas d'eau dans la riviere en (%d, %d)", p[1], p[2])
					)
				end
			end
		end

		return problems
	end

	return { build = build, measure = measure, surface = surface }
end
