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

-- Les champs facultatifs viennent des pouvoirs de l'Oeil (EyePowers.apply).
export type Regard = {
	playersPerBeam: number,
	openSeconds: number,
	closedSeconds: number,
	-- La rage : une rafale sur `rageEvery`, `rageBeams` faisceaux de plus.
	rageEvery: number?,
	rageBeams: number?,
	-- Le regard long : la rafale numero `longBurst` dure `longFactor` fois plus.
	longBurst: number?,
	longFactor: number?,
	-- Le faux depart : les pauses marquees ne durent que `feintSeconds`.
	feints: { [number]: boolean }?,
	feintSeconds: number?,
}

-- Le nombre de faisceaux : 1 pour `playersPerBeam` joueurs en vie, au moins 1,
-- plus ceux de la rage pendant la rafale `burst`.
function Regards.beamCount(regard: Regard, alive: number, burst: number): number
	local count = math.max(1, math.ceil(alive / regard.playersPerBeam))
	local every, extra = regard.rageEvery, regard.rageBeams
	if every and extra and burst > 0 and burst % every == 0 then
		count += extra
	end
	return count
end

-- A l'instant `t` (secondes depuis le debut du Regard) : l'Oeil est-il
-- ouvert, combien de temps reste-t-il avant qu'il change, et le numero de la
-- rafale en cours (qui commence a 1).
function Regards.burst(regard: Regard, t: number): (boolean, number, number)
	t = math.max(t, 0)
	if regard.closedSeconds <= 0 then
		-- Toujours ouvert, mais une « rafale » par `openSeconds` : l'Oeil
		-- continue d'arracher des cachettes au meme rythme.
		return true, math.huge, math.floor(t / regard.openSeconds) + 1
	end
	-- Rafale par rafale : les pouvoirs en allongent une ou raccourcissent des
	-- pauses. Un Regard en compte une dizaine au plus.
	local start, index = 0, 1
	while true do
		local open = regard.openSeconds
		if regard.longBurst == index and regard.longFactor then
			open *= regard.longFactor
		end
		local closed = regard.closedSeconds
		local feints = regard.feints
		if feints and feints[index] and regard.feintSeconds then
			closed = regard.feintSeconds
		end
		if t < start + open then
			return true, start + open - t, index
		elseif t < start + open + closed then
			return false, start + open + closed - t, index
		end
		start += open + closed
		index += 1
	end
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
