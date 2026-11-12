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

function EyeService.reset()
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
		for _ = 1, Regards.beamCount(regard, #alive) do
			table.insert(beams, newBeam(randomAlivePosition()))
		end
		table.clear(rips)
		local flagged: { [Roster.Actor]: boolean } = {}
		for player, state in suspicion do
			if Suspicion.isFlagged(state) then
				flagged[player] = true
			end
		end
		local candidates = HidingService.ripCandidates(flagged, regard.solidFalls)
		for i = 1, math.min(regard.ripsPerBurst, #candidates) do
			table.insert(
				rips,
				{ at = now + random:NextNumber(0, regard.openSeconds), spot = candidates[i] }
			)
		end
	end
	workspace:SetAttribute(Config.match.eyeOpenAttribute, open)

	-- Le nombre de faisceaux suit les joueurs en vie, meme au milieu d'une
	-- ouverture.
	if open then
		local wanted = Regards.beamCount(regard, #alive)
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
		local sight = if hidden then 0 else World.seenFactor(Roster.characterOf(player) :: Model)
		local lit = false
		if open then
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
			if spot then
				HidingService.rip(spot, regard.solidFalls)
			else
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
		for _, beam in beams do
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
	publishBeams(open, radius)

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
			level = Exposure.step(level, factor[player] or 0, dt, {
				fillSeconds = regard.fillSeconds,
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
	exposure[player] = nil
	suspicion[player] = nil
end)

return EyeService
