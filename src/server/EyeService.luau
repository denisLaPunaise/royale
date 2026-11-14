--!strict
--[[
	EyeService — l'Oeil qui chasse (CONCEPT.md, L'Oeil et ses Regards).

	Pendant une ouverture, des faisceaux (un pour `playersPerBeam` joueurs en
	vie) parcourent la carte. Un joueur est VU quand il est dans la lumiere d'un
	faisceau ET qu'une ligne reelle le relie au bout de la pupille
	(World.seenFactor) : sa jauge monte ; pleine, il est aspire. Un faisceau
	qui voit quelqu'un le poursuit (Targeting), avec une erreur de visee qui
	fond au fil des Regards ; sans cible, il erre vers ce qu'il entend.

	Hors du cercle, l'Oeil voit tout : la jauge monte sans faisceau, meme
	cache. Il arrache les cachettes marquees, et celles des campeurs flaires
	(la mefiance, Suspicion) passent en premier.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local Exposure = require(Royale:WaitForChild("Exposure"))
local Regards = require(Royale:WaitForChild("Regards"))
local Suspicion = require(Royale:WaitForChild("Suspicion"))
local Targeting = require(Royale:WaitForChild("Targeting"))

local HidingService = require(script.Parent.HidingService)
local Roster = require(script.Parent.Roster)
local Sfx = require(script.Parent.Sfx)
local World = require(script.Parent.World)
local ZoneService = require(script.Parent.ZoneService)

local EyeService = {}

local E = Config.eye
local S = Config.suspicion

type Beam = {
	x: number,
	z: number,
	target: string?,
	memory: number,
	-- L'erreur de visee en cours (entre -1 et 1) et quand la retirer.
	ex: number,
	ez: number,
	reroll: number,
}

local beams: { Beam } = {}
local exposure: { [Roster.Actor]: number } = {}
local suspicion: { [Roster.Actor]: Suspicion.State } = {}
local rips: { { at: number, spot: HidingService.Spot } } = {}
local wasOpen = false
local lastBurst = 0
local serial = 0
local random = Random.new()
-- Les bruits qu'on lui fait (coups, toquer a un abri) : `always`, il les
-- entend a tout Regard ; sinon seulement quand il entend les coups.
local noises: { { at: Vector3, untilT: number, always: boolean } } = {}
-- Les leurres (fusees, mannequin) : un point qui attire un faisceau, ou tous.
local lures: { { at: () -> Vector3?, untilT: number, all: boolean } } = {}
-- Ceux qu'il ne voit plus un moment (le Miroir).
local ignoredUntil: { [Roster.Actor]: number } = {}
-- Tous les faisceaux eteints jusqu'a cette heure (la Larme).
local blindUntil = 0
-- Le Regard vole : qui dirige un faisceau, jusqu'a quand, et ou.
local steer: { actor: Roster.Actor?, untilT: number, x: number, z: number } =
	{ actor = nil, untilT = 0, x = 0, z = 0 }
-- Le retour (pouvoir) : les dernieres positions de ceux qu'il a perdus, ou il
-- revient voir entre `at` et `untilT`.
local comebacks: { { x: number, z: number, at: number, untilT: number } } = {}
-- Les empreintes (pouvoir) : rend la trace a suivre pres d'un faisceau.
local trail: ((x: number, z: number) -> Vector3?)? = nil
-- Appeles au debut de chaque ouverture (l'eclair, le souffle).
local burstCallbacks: { (regard: any) -> () } = {}
-- Appeles pour un flaire qui n'a rien a arracher (les Repris).
local flaggedCallbacks: { (actor: Roster.Actor) -> () } = {}
local FX = Config.effects

-- Un effet (heure de fin du serveur, posee par ItemService) encore actif.
local function effect(actor: Roster.Actor, attribute: string): boolean
	local untilT = actor:GetAttribute(attribute)
	return typeof(untilT) == "number" and workspace:GetServerTimeNow() < untilT
end
local folder: Folder? = nil

local function beamFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = E.beamsFolder
	f.Parent = workspace
	folder = f
	return f
end

local function publishBeams(open: boolean, radius: number)
	local f = beamFolder()
	for name in f:GetAttributes() do
		f:SetAttribute(name, nil)
	end
	if not open then
		return
	end
	for i, beam in beams do
		f:SetAttribute("F" .. i, Vector3.new(beam.x, radius, beam.z))
	end
end

-- Un faisceau neuf tombe pres de quelqu'un, jamais dessus.
local function newBeam(near: Vector3?): Beam
	local cx, cz = 0, 0
	if near then
		cx, cz = near.X, near.Z
	end
	local a = random:NextNumber(0, math.pi * 2)
	return {
		x = cx + math.cos(a) * E.openOffset,
		z = cz + math.sin(a) * E.openOffset,
		target = nil,
		memory = 0,
		ex = random:NextNumber(-1, 1),
		ez = random:NextNumber(-1, 1),
		reroll = 0,
	}
end

local function randomAlivePosition(): Vector3?
	local alive = Roster.alive()
	for _ = 1, #alive do
		local root = Roster.rootOf(alive[random:NextInteger(1, #alive)])
		if root then
			return root.Position
		end
	end
	return nil
end

-- Un bruit a `at` pendant `seconds`. `always` : meme avant qu'il entende.
function EyeService.noise(at: Vector3, seconds: number, always: boolean)
	table.insert(noises, { at = at, untilT = os.clock() + seconds, always = always })
end

-- Un leurre : `at` rend sa position (nil : il a disparu). `all` : tous les
-- faisceaux y vont (Fusee rouge) ; sinon le plus proche.
function EyeService.lure(at: () -> Vector3?, seconds: number, all: boolean)
	table.insert(lures, { at = at, untilT = os.clock() + seconds, all = all })
end

-- Le Miroir : le faisceau qui le poursuit part sur le plus proche des autres,
-- et ne le voit plus `seconds`. Rend vrai si un faisceau le poursuivait.
function EyeService.deflect(actor: Roster.Actor, seconds: number): boolean
	local id = Roster.idOf(actor)
	local root = Roster.rootOf(actor)
	ignoredUntil[actor] = os.clock() + seconds
	local deflected = false
	for _, beam in beams do
		if beam.target == id and root then
			deflected = true
			local best, bestD = nil, math.huge
			for _, other in Roster.alive() do
				local r = Roster.rootOf(other)
				if other ~= actor and r and not HidingService.isHidden(other) then
					local d = (r.Position - root.Position).Magnitude
					if d < bestD then
						best, bestD = other, d
					end
				end
			end
			beam.target = if best then Roster.idOf(best) else nil
		end
	end
	return deflected
end

-- La Larme : il cligne, tous les faisceaux s'eteignent.
function EyeService.blink(seconds: number)
	blindUntil = os.clock() + seconds
end

-- Le Carton piege : il est flaire, l'Oeil vient a lui.
function EyeService.flag(actor: Roster.Actor)
	local root = Roster.rootOf(actor)
	if root then
		local state = Suspicion.new(root.Position.X, root.Position.Z)
		state.level = 1
		suspicion[actor] = state
	end
end

-- Le Regard vole : `actor` dirige un faisceau `seconds`.
function EyeService.steer(actor: Roster.Actor, seconds: number)
	local root = Roster.rootOf(actor)
	steer.actor = actor
	steer.untilT = os.clock() + seconds
	steer.x = if root then root.Position.X else 0
	steer.z = if root then root.Position.Z else 0
end

function EyeService.steerTo(actor: Roster.Actor, x: number, z: number)
	if steer.actor == actor and os.clock() < steer.untilT then
		steer.x, steer.z = x, z
	end
end

-- Les empreintes : `fn` rend la trace la plus recente d'une piste proche.
function EyeService.setTrail(fn: (x: number, z: number) -> Vector3?)
	trail = fn
end

function EyeService.onBurst(callback: (regard: any) -> ())
	table.insert(burstCallbacks, callback)
end

-- CONCEPT.md : flaire sans rien a arracher, il y envoie des Repris.
function EyeService.onFlagged(callback: (actor: Roster.Actor) -> ())
	table.insert(flaggedCallbacks, callback)
end

-- Le vacarme d'une cachette qui s'ouvre (le conteneur) : l'Oeil l'entend a
-- tout Regard, et tout le monde aussi.
local function clang(_actor: Roster.Actor, spot: HidingService.Spot)
	local seconds = HidingService.noiseOf(spot)
	if seconds > 0 then
		EyeService.noise(spot.inside.Position, seconds, true)
		Sfx.at("coup", spot.inside.Position)
	end
end
HidingService.onEnter(clang)
HidingService.onRelease(clang)

function EyeService.reset()
	table.clear(comebacks)
	table.clear(lures)
	table.clear(ignoredUntil)
	blindUntil = 0
	steer.actor = nil
	table.clear(noises)
	table.clear(beams)
	table.clear(exposure)
	table.clear(suspicion)
	table.clear(rips)
	wasOpen = false
	lastBurst = 0
	serial = 0
	workspace:SetAttribute(Config.match.eyeOpenAttribute, false)
	publishBeams(false, 0)
	for _, player in Players:GetPlayers() do
		player:SetAttribute(E.exposureAttribute, nil)
		player:SetAttribute(S.attribute, nil)
		player:SetAttribute(E.huntedAttribute, nil)
		player:SetAttribute(E.graceAttribute, nil)
	end
end

local function inGrace(player: Roster.Actor): boolean
	local until_ = player:GetAttribute(E.graceAttribute)
	return typeof(until_) == "number" and workspace:GetServerTimeNow() < until_
end

-- Ce que l'Oeil entend (CONCEPT.md : la course au Regard 3, les coups au 4,
-- tout au 5) : la position des joueurs qu'il entend, sinon vide.
local function heard(regard: any): { Vector3 }
	local out: { Vector3 } = {}
	local now = os.clock()
	local hearsHits = regard.hears == "coups" or regard.hears == "tout"
	for i = #noises, 1, -1 do
		local n = noises[i]
		if now >= n.untilT then
			table.remove(noises, i)
		elseif n.always or hearsHits then
			table.insert(out, n.at)
		end
	end
	if regard.hears == "rien" then
		return out
	end
	for _, player in Roster.alive() do
		local root = Roster.rootOf(player)
		if
			root
			and not HidingService.isHidden(player)
			and not ZoneService.outside(root.Position)
			and not effect(player, FX.adrenalineAttribute)
		then
			local speed = Vector3.new(
				root.AssemblyLinearVelocity.X,
				0,
				root.AssemblyLinearVelocity.Z
			).Magnitude
			-- « tout » : il entend aussi la marche.
			local threshold = if regard.hears == "tout" then 1 else E.runningSpeed
			if speed >= threshold then
				table.insert(out, root.Position)
			end
		end
	end
	return out
end

-- Un pas de calcul. `regard` : Config.regards[n] ; `open` et `burst` viennent
-- de Regards.burst ; `active` : faux pendant l'attente et la chute (personne
-- n'est vu, la jauge et la mefiance dorment).
function EyeService.step(dt: number, regard: any, open: boolean, burst: number, active: boolean)
	local now = os.clock()
	local alive = Roster.alive()
	if not active then
		return
	end

	-- Une nouvelle ouverture : nouveaux faisceaux, cachettes a arracher.
	local newBurst = open and (not wasOpen or burst ~= lastBurst)
	wasOpen = open
	lastBurst = burst
	if newBurst then
		serial += 1
		HidingService.setBurst(serial)
		table.clear(beams)
		for _ = 1, Regards.beamCount(regard, #alive, burst) do
			table.insert(beams, newBeam(randomAlivePosition()))
		end
		table.clear(rips)
		local flagged: { [Roster.Actor]: boolean } = {}
		for player, state in suspicion do
			if Suspicion.isFlagged(state) then
				flagged[player] = true
			end
		end
		-- La rancune : il garde ses marques plus longtemps.
		local candidates = HidingService.ripCandidates(
			flagged,
			regard.solidFalls,
			Config.hiding.markBursts * regard.markFactor,
			regard.flair
		)
		for i = 1, math.min(regard.ripsPerBurst, #candidates) do
			table.insert(
				rips,
				{ at = now + random:NextNumber(0, regard.openSeconds), spot = candidates[i] }
			)
		end
		for _, callback in burstCallbacks do
			task.spawn(callback, regard)
		end
	end
	workspace:SetAttribute(Config.match.eyeOpenAttribute, open)
	-- Les faisceaux allumes : ouvert, et pas pendant un clignement.
	local lightsOn = open and now >= blindUntil
	for i = #lures, 1, -1 do
		if now >= lures[i].untilT or lures[i].at() == nil then
			table.remove(lures, i)
		end
	end
	if steer.actor and (now >= steer.untilT or not Roster.isAlive(steer.actor)) then
		steer.actor = nil
	end

	-- Le nombre de faisceaux suit les joueurs en vie, meme au milieu d'une
	-- ouverture.
	if open then
		local wanted = Regards.beamCount(regard, #alive, burst)
		while #beams > wanted do
			table.remove(beams)
		end
		while #beams < wanted do
			table.insert(beams, newBeam(randomAlivePosition()))
		end
		for i = #rips, 1, -1 do
			if now >= rips[i].at then
				HidingService.rip(rips[i].spot, regard.solidFalls)
				table.remove(rips, i)
			end
		end
	end

	-- Ce que l'Oeil voit de chacun : la ligne de vue depuis la pupille, et la
	-- lumiere d'un faisceau.
	local radius = regard.beamRadius
	local seen: { Targeting.Seen } = {}
	local factor: { [Roster.Actor]: number } = {}
	local byId: { [string]: Roster.Actor } = {}
	local positions: { [Roster.Actor]: Vector3 } = {}
	for _, player in alive do
		local root = Roster.rootOf(player)
		if root == nil then
			continue
		end
		local id = Roster.idOf(player)
		byId[id] = player
		positions[player] = root.Position
		-- Pas de faisceau dehors (CONCEPT.md, valide le 12 novembre 2026) :
		-- hors du cercle, c'est le regard rouge diffus qui s'en charge.
		local inZone = not ZoneService.outside(root.Position)
		local hidden = HidingService.isHidden(player)
		local veiled = effect(player, FX.veiledAttribute)
			or (ignoredUntil[player] ~= nil and now < (ignoredUntil[player] :: number))
		-- Cache : rien d'un abri ferme, une partie dans un buisson.
		local sight = if veiled
			then 0
			elseif hidden then HidingService.coverOf(player)
			else World.seenFactor(Roster.characterOf(player) :: Model, regard.slantElevation)
		local lit = false
		if lightsOn then
			for _, beam in beams do
				local dx, dz = root.Position.X - beam.x, root.Position.Z - beam.z
				if dx * dx + dz * dz <= radius * radius then
					lit = true
					break
				end
			end
		end
		local f = if lit and inZone then sight else 0
		factor[player] = f
		if f > 0 then
			table.insert(seen, { id = id, x = root.Position.X, z = root.Position.Z })
		end
		-- La mefiance : cache (dans une cachette ou hors de sa vue) sans bouger.
		local state = suspicion[player] or Suspicion.new(root.Position.X, root.Position.Z)
		suspicion[player] = Suspicion.step(
			state,
			root.Position.X,
			root.Position.Z,
			hidden or sight <= 0,
			dt,
			regard.suspicionSeconds,
			S
		)
	end

	if open then
		-- Qui chaque faisceau poursuit.
		local assigned = Targeting.assign(beams, seen, regard.memorySeconds, dt)
		for i, a in assigned do
			-- Le retour : une piste perdue, il reviendra voir.
			local lost = beams[i].target
			if regard.comebackDelay and lost and a.target == nil then
				local who = byId[lost]
				local at = who and positions[who]
				if at then
					table.insert(comebacks, {
						x = at.X,
						z = at.Z,
						at = now + regard.comebackDelay,
						untilT = now + regard.comebackDelay + regard.comebackLinger,
					})
				end
			end
			beams[i].target = a.target
			beams[i].memory = a.memory
		end
		-- Les campeurs flaires : sa cachette s'arrache, ou un faisceau libre
		-- vient sur lui (il n'est vu que s'il est vraiment a decouvert).
		for player, state in suspicion do
			if not Suspicion.isFlagged(state) or not Roster.isAlive(player) then
				continue
			end
			local spot = HidingService.spotOf(player)
			local head = Roster.characterOf(player)
			local cover = if spot == nil and head
				then World.coverAbove(
					(positions[player] or Vector3.zero) + Vector3.new(0, 1, 0),
					{ head }
				)
				else nil
			if spot then
				HidingService.rip(spot, regard.solidFalls)
			elseif cover then
				-- Ce qui couvre son recoin s'envole (CONCEPT.md).
				Sfx.at("aspiration", cover.Position)
				World.ripCover(cover)
				print(
					string.format("[Royale] L'Œil arrache ce qui couvre %s", Roster.nameOf(player))
				)
			else
				for _, callback in flaggedCallbacks do
					task.spawn(callback, player)
				end
				for _, beam in beams do
					if beam.target == nil then
						beam.target = Roster.idOf(player)
						beam.memory = regard.memorySeconds
						break
					end
				end
			end
			suspicion[player] = Suspicion.new(state.x, state.z)
		end
		-- Bouger les faisceaux.
		local sounds = heard(regard)
		-- Les leurres : chacun prend le faisceau le plus proche, une fusee
		-- rouge les prend tous ; le Regard vole tient le premier.
		local forced: { [any]: Vector3 } = {}
		if steer.actor and beams[1] then
			forced[beams[1]] = Vector3.new(steer.x, 0, steer.z)
		end
		-- Le retour : le faisceau libre le plus proche va revoir l'endroit.
		for i = #comebacks, 1, -1 do
			local c = comebacks[i]
			if now >= c.untilT then
				table.remove(comebacks, i)
			elseif now >= c.at then
				local best, bestD = nil, math.huge
				for _, beam in beams do
					local d = (beam.x - c.x) ^ 2 + (beam.z - c.z) ^ 2
					if beam.target == nil and forced[beam] == nil and d < bestD then
						best, bestD = beam, d
					end
				end
				if best then
					forced[best] = Vector3.new(c.x, 0, c.z)
				end
			end
		end
		for _, lure in lures do
			local at = lure.at()
			if at == nil then
				continue
			end
			if lure.all then
				for _, beam in beams do
					forced[beam] = at
				end
			else
				local best, bestD = nil, math.huge
				for _, beam in beams do
					local d = (beam.x - at.X) ^ 2 + (beam.z - at.Z) ^ 2
					if forced[beam] == nil and d < bestD then
						best, bestD = beam, d
					end
				end
				if best then
					forced[best] = at
				end
			end
		end
		for _, beam in beams do
			local lured = forced[beam]
			if lured then
				beam.target = nil
				beam.x, beam.z =
					Targeting.chaseStep(beam.x, beam.z, lured.X, lured.Z, regard.chaseSpeed, dt)
				beam.x, beam.z = ZoneService.clamp(beam.x, beam.z)
				continue
			end
			if now >= beam.reroll then
				beam.ex, beam.ez = random:NextNumber(-1, 1), random:NextNumber(-1, 1)
				beam.reroll = now + E.aimRerollSeconds
			end
			local targetPlayer = if beam.target then byId[beam.target] else nil
			local goal = targetPlayer and positions[targetPlayer]
			local speed = regard.chaseSpeed
			if goal == nil then
				-- Sans cible : vers le bruit le plus proche, sinon vers un joueur.
				-- Jamais plus vite qu'en poursuite : errer ne doit pas battre
				-- chasser.
				speed = math.min(E.roamSpeed, regard.chaseSpeed)
				local best = math.huge
				-- Les empreintes passent avant les bruits : il remonte la piste.
				if regard.prints and trail then
					goal = trail(beam.x, beam.z)
					if goal then
						best = 0
					end
				end
				for _, p in sounds do
					local d = (p.X - beam.x) ^ 2 + (p.Z - beam.z) ^ 2
					if d < best then
						best, goal = d, p
					end
				end
				if goal == nil then
					for _, p in positions do
						if ZoneService.outside(p) then
							continue
						end
						local d = (p.X - beam.x) ^ 2 + (p.Z - beam.z) ^ 2
						if d < best then
							best, goal = d, p
						end
					end
				end
			end
			if goal then
				local ax, az = Targeting.aimPoint(goal.X, goal.Z, regard.aimError, beam.ex, beam.ez)
				beam.x, beam.z = Targeting.chaseStep(beam.x, beam.z, ax, az, speed, dt)
				beam.x, beam.z = ZoneService.clamp(beam.x, beam.z)
			end
		end
	end
	publishBeams(lightsOn, radius)

	-- Les jauges.
	local hunted: { [Roster.Actor]: boolean } = {}
	for _, beam in beams do
		local p = if open and beam.target then byId[beam.target] else nil
		if p then
			hunted[p] = true
		end
	end
	for _, player in alive do
		local position = positions[player]
		if position == nil then
			continue
		end
		local level = exposure[player] or 0
		if inGrace(player) then
			level = Exposure.step(
				level,
				0,
				dt,
				{ fillSeconds = regard.fillSeconds, drainSeconds = E.drainSeconds }
			)
		elseif ZoneService.outside(position) then
			level = Exposure.step(level, 1, dt, {
				fillSeconds = regard.outsideFillSeconds,
				drainSeconds = E.drainSeconds,
			})
		else
			-- La Cape : la jauge monte moins vite.
			local fill = if effect(player, FX.cloakAttribute)
				then regard.fillSeconds / Config.items.cloak.fillFactor
				else regard.fillSeconds
			level = Exposure.step(level, factor[player] or 0, dt, {
				fillSeconds = fill,
				drainSeconds = E.drainSeconds,
			})
		end
		exposure[player] = level
		player:SetAttribute(E.exposureAttribute, level)
		local state = suspicion[player]
		player:SetAttribute(S.attribute, if state then state.level else 0)
		player:SetAttribute(E.huntedAttribute, hunted[player] == true)
		if Exposure.isTaken(level) then
			exposure[player] = nil
			suspicion[player] = nil
			Roster.take(player)
		end
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	ignoredUntil[player] = nil
	exposure[player] = nil
	suspicion[player] = nil
end)

return EyeService
