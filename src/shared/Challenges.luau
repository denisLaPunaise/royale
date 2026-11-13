--!strict
--[[
	Challenges — les defis quotidiens et hebdomadaires (CONCEPT.md : ils font
	avancer le passe).

	Logique pure : aucun require, aucune API Roblox. Le catalogue et le
	numero du jour (ou de la semaine) arrivent en argument.
]]

local Challenges = {}

-- Les defis de cette periode : `count` ids du catalogue, choisis d'apres le
-- numero de la periode (les memes pour tout le monde).
function Challenges.pick(
	list: { [string]: any },
	period: number,
	count: number,
	salt: number
): { string }
	local pool: { string } = {}
	for id in list do
		table.insert(pool, id)
	end
	table.sort(pool)
	local state = ((period + salt) * 2654435761) % 2147483648
	for i = #pool, 2, -1 do
		state = (state * 1103515245 + 12345) % 2147483648
		local j = state % i + 1
		pool[i], pool[j] = pool[j], pool[i]
	end
	local out: { string } = {}
	for i = 1, math.min(count, #pool) do
		out[i] = pool[i]
	end
	return out
end

-- Le suivi d'une periode : remis a zero quand la periode change.
-- `track` : { period, progress = { [id] = n }, done = { [id] = true } }.
function Challenges.reset(track: any, period: number): any
	if typeof(track) ~= "table" or track.period ~= period then
		return { period = period, progress = {}, done = {} }
	end
	track.progress = track.progress or {}
	track.done = track.done or {}
	return track
end

-- Ajoute `amount` a la statistique `stat` pour les defis actifs ; rend les
-- ids des defis qui viennent d'etre finis (a recompenser une seule fois).
function Challenges.record(
	track: any,
	active: { string },
	list: { [string]: any },
	stat: string,
	amount: number,
	goalFactor: number
): { string }
	local finished: { string } = {}
	for _, id in active do
		local def = list[id]
		if def and def.stat == stat and not track.done[id] then
			local goal = def.goal * goalFactor
			local value = math.min((track.progress[id] or 0) + amount, goal)
			track.progress[id] = value
			if value >= goal then
				track.done[id] = true
				table.insert(finished, id)
			end
		end
	end
	return finished
end

return Challenges
