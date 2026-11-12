--!strict
--[[
	Melee — les regles du corps a corps (CONCEPT.md, Interactions entre
	joueurs), sans Roblox : qui un coup touche, combien de coups mettent K.O.,
	et quand on se releve. Les reglages arrivent en argument (Config.combat).
]]

local Melee = {}

export type Candidate = { id: string, x: number, y: number, z: number }

export type State = {
	-- Coups recus depuis le dernier K.O. (ou depuis que la serie s'est perdue).
	hits: number,
	-- Heure du dernier coup recu.
	lastHit: number,
	-- Au sol (K.O. ou renverse) jusqu'a cette heure.
	downUntil: number,
	-- Vrai si c'est un K.O. (on peut le porter, le voler) et pas une chute.
	knockedOut: boolean,
}

function Melee.new(): State
	return { hits = 0, lastHit = -math.huge, downUntil = -math.huge, knockedOut = false }
end

-- Le plus proche dans le cone devant soi : `look` est la direction du regard
-- a plat (x, z), `cone` le cosinus de l'angle maximal. Personne : nil.
function Melee.pickTarget(
	from: { x: number, y: number, z: number },
	look: { x: number, z: number },
	candidates: { Candidate },
	range: number,
	cone: number
): string?
	local len = math.sqrt(look.x * look.x + look.z * look.z)
	if len == 0 then
		return nil
	end
	local lx, lz = look.x / len, look.z / len
	local best: string? = nil
	local bestD = math.huge
	for _, c in candidates do
		local dx, dy, dz = c.x - from.x, c.y - from.y, c.z - from.z
		local d = math.sqrt(dx * dx + dy * dy + dz * dz)
		if d <= range and d < bestD then
			local flat = math.sqrt(dx * dx + dz * dz)
			-- Colle a soi : le cone ne veut plus rien dire, on touche.
			local facing = if flat < 1e-6 then 1 else (dx * lx + dz * lz) / flat
			if facing >= cone then
				best, bestD = c.id, d
			end
		end
	end
	return best
end

function Melee.isDown(state: State, now: number): boolean
	return now < state.downUntil
end

-- Un coup recu. Une serie qui traine plus de `comboResetSeconds` repart de
-- zero : trois coups etales sur une minute ne mettent personne K.O.
-- Rend le nouvel etat et vrai si ce coup met K.O.
function Melee.hit(
	state: State,
	now: number,
	rules: { hitsToKO: number, comboResetSeconds: number, koSeconds: number }
): (State, boolean)
	local hits = if now - state.lastHit > rules.comboResetSeconds then 0 else state.hits
	hits += 1
	if hits >= rules.hitsToKO then
		return {
			hits = 0,
			lastHit = now,
			downUntil = math.max(state.downUntil, now + rules.koSeconds),
			knockedOut = true,
		},
			true
	end
	return {
		hits = hits,
		lastHit = now,
		downUntil = state.downUntil,
		knockedOut = state.knockedOut and now < state.downUntil,
	},
		false
end

-- Renverse (plaquage, tacle, porte dans la figure) : au sol sans etre K.O.
-- Une chute ne raccourcit jamais un K.O. deja en cours.
function Melee.fall(state: State, now: number, seconds: number): State
	local untilT = now + seconds
	if state.knockedOut and state.downUntil >= untilT then
		return state
	end
	return {
		hits = state.hits,
		lastHit = state.lastHit,
		downUntil = math.max(state.downUntil, untilT),
		knockedOut = state.knockedOut and now < state.downUntil,
	}
end

-- Porte, un K.O. dure tant qu'on le porte, jusqu'a `maxSeconds` depuis
-- qu'on l'a souleve : il finit par se debattre et tomber. `refresh` : de
-- combien on prolonge a chaque pas (plus que l'intervalle entre deux pas).
function Melee.holdDown(
	state: State,
	now: number,
	liftedAt: number,
	maxSeconds: number,
	refresh: number
): State
	return {
		hits = state.hits,
		lastHit = state.lastHit,
		downUntil = math.max(state.downUntil, math.min(now + refresh, liftedAt + maxSeconds)),
		knockedOut = true,
	}
end

return Melee
