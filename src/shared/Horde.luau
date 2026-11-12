--!strict
--[[
	Horde — combien de Repris l'Oeil recrache, combien il en garde, et qui
	ils visent (CONCEPT.md, Contre le camping).

	Logique pure : aucun require, aucune API Roblox. Les reglages
	(Config.repris) et les tirages arrivent en argument.
]]

local Horde = {}

-- Le plafond : au plus `capRatio` Repris par joueur en vie.
function Horde.cap(alive: number, capRatio: number): number
	return math.floor(alive * capRatio)
end

-- Combien en recracher a cette fermeture : 1 pour `perPlayers` joueurs en
-- vie (au moins 1 tant qu'il reste quelqu'un), sans depasser le plafond.
function Horde.spawnCount(
	alive: number,
	living: number,
	perPlayers: number,
	capRatio: number
): number
	if alive <= 0 then
		return 0
	end
	local wanted = math.max(1, math.ceil(alive / perPlayers))
	return math.clamp(Horde.cap(alive, capRatio) - living, 0, wanted)
end

-- Combien il en re-aspire au debut d'un Regard.
function Horde.reaspire(living: number, fraction: number): number
	return math.floor(living * fraction)
end

-- Les sortes deja arrivees a ce Regard, triees (un tirage reproductible).
function Horde.kindsAt(kinds: { [string]: any }, regard: number): { string }
	local out: { string } = {}
	for id, kind in kinds do
		if kind.arrives <= regard then
			table.insert(out, id)
		end
	end
	table.sort(out)
	return out
end

function Horde.pickKind(kinds: { [string]: any }, regard: number, u: number): string?
	local list = Horde.kindsAt(kinds, regard)
	if #list == 0 then
		return nil
	end
	return list[math.clamp(math.floor(u * #list) + 1, 1, #list)]
end

-- Qui viser a la chute : un tirage pondere (`weights[i]`, les caches pesent
-- plus). Rend l'indice tire, ou nil sans personne.
function Horde.pickWeighted(weights: { number }, u: number): number?
	local total = 0
	for _, w in weights do
		total += w
	end
	if total <= 0 then
		return nil
	end
	local acc = 0
	for i, w in weights do
		acc += w / total
		if u < acc then
			return i
		end
	end
	return #weights
end

export type Seen = { id: string, distance: number, visible: boolean }

-- La cible : le plus proche qu'il voit a portee, sauf ceux que `maxPerTarget`
-- Repris suivent deja (`taken[id]`, sans compter celui-ci). Garder sa cible
-- actuelle passe avant (il ne lache pas pour un plus proche).
function Horde.pickTarget(
	seen: { Seen },
	range: number,
	taken: { [string]: number },
	maxPerTarget: number,
	current: string?
): string?
	local best, bestD = nil, math.huge
	for _, s in seen do
		if not s.visible or s.distance > range then
			continue
		end
		if s.id == current then
			return s.id
		end
		if (taken[s.id] or 0) >= maxPerTarget then
			continue
		end
		if s.distance < bestD then
			best, bestD = s.id, s.distance
		end
	end
	return best
end

-- La portee de sa vue sur un joueur qui va a cette vitesse : un joueur lent
-- (accroupi, immobile) se remarque moins.
function Horde.sightRange(
	sight: number,
	speed: number,
	slowSpeed: number,
	slowFactor: number
): number
	if speed <= slowSpeed then
		return sight * slowFactor
	end
	return sight
end

return Horde
