--!strict
--[[
	Regards — le rythme de l'Oeil dans un Regard : combien de faisceaux, et
	quand il est ouvert ou ferme.

	Logique pure : aucun require, aucune API Roblox. Les reglages arrivent en
	argument (Config.regards[n]).

	Un Regard enchaine des rafales : ouvert `openSeconds`, puis ferme
	`closedSeconds`, et ainsi de suite. `closedSeconds` a 0 : il ne se ferme
	plus (le Regard 5).
]]

local Regards = {}

export type Regard = {
	playersPerBeam: number,
	openSeconds: number,
	closedSeconds: number,
}

-- Le nombre de faisceaux : 1 pour `playersPerBeam` joueurs en vie, au moins 1.
function Regards.beamCount(regard: Regard, alive: number): number
	return math.max(1, math.ceil(alive / regard.playersPerBeam))
end

-- A l'instant `t` (secondes depuis le debut du Regard) : l'Oeil est-il
-- ouvert, combien de temps reste-t-il avant qu'il change, et le numero de la
-- rafale en cours (qui commence a 1).
function Regards.burst(regard: Regard, t: number): (boolean, number, number)
	if regard.closedSeconds <= 0 then
		-- Toujours ouvert, mais une « rafale » par `openSeconds` : l'Oeil
		-- continue d'arracher des cachettes au meme rythme.
		return true, math.huge, math.floor(math.max(t, 0) / regard.openSeconds) + 1
	end
	local cycle = regard.openSeconds + regard.closedSeconds
	local index = math.floor(math.max(t, 0) / cycle)
	local within = math.max(t, 0) - index * cycle
	if within < regard.openSeconds then
		return true, regard.openSeconds - within, index + 1
	end
	return false, cycle - within, index + 1
end

-- Le Regard en cours a `t` secondes depuis la premiere ouverture, et l'instant
-- ou il a commence. Apres le dernier, on reste sur le dernier.
function Regards.at(durations: { number }, t: number): (number, number)
	local start = 0
	for i, seconds in durations do
		if i == #durations or t < start + seconds then
			return i, start
		end
		start += seconds
	end
	return #durations, start
end

return Regards
