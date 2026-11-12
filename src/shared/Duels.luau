--!strict
--[[
	Duels — les manches du goulag (CONCEPT.md, Capture) : qui affronte qui,
	l'effritement de la plateforme, et qui est sauve quand quelqu'un tombe.

	Logique pure : aucun require, aucune API Roblox. Les reglages
	(Config.goulag) et les tirages arrivent en argument.
]]

local Duels = {}

-- Les paires d'une manche. `team[id]` : jamais deux coequipiers ensemble
-- (CONCEPT.md). `order` : les ids deja melanges. Rend les paires et celui qui
-- reste seul (il affronte le bot), ou nil.
function Duels.pair(order: { string }, team: { [string]: string }): ({ { string } }, string?)
	local left = table.clone(order)
	local pairs: { { string } } = {}
	while #left >= 2 do
		local a = table.remove(left, 1) :: string
		local partner = nil
		for i, b in left do
			if team[a] == nil or team[a] ~= team[b] then
				partner = i
				break
			end
		end
		if partner == nil then
			-- Que des coequipiers : il attend (ou prend le bot s'il est seul).
			table.insert(left, a)
			break
		end
		table.insert(pairs, { a, table.remove(left, partner) :: string })
	end
	-- Le premier qui reste prend le bot ; s'il reste plusieurs coequipiers,
	-- les autres attendront la manche suivante (Duels.waiting).
	return pairs, left[1]
end

-- Ceux qui n'ont pas trouve de place dans `pairs` ni contre le bot.
function Duels.waiting(order: { string }, pairs: { { string } }, alone: string?): { string }
	local placed: { [string]: boolean } = {}
	for _, p in pairs do
		placed[p[1]] = true
		placed[p[2]] = true
	end
	if alone then
		placed[alone] = true
	end
	local out: { string } = {}
	for _, id in order do
		if not placed[id] then
			table.insert(out, id)
		end
	end
	return out
end

-- Le rayon de la plateforme `t` secondes apres le debut du duel : elle
-- s'effrite doucement, puis vite en mort subite, jusqu'a rien.
function Duels.radius(t: number, g: any): (number, boolean)
	if t <= 0 then
		return g.platformRadius, false
	elseif t < g.duelSeconds then
		local k = t / g.duelSeconds
		return g.platformRadius + (g.crumbleTo - g.platformRadius) * k, false
	end
	local k = math.clamp((t - g.duelSeconds) / g.suddenSeconds, 0, 1)
	return g.crumbleTo * (1 - k), true
end

-- Quelqu'un tombe. `hitBy` : l'adversaire l'a frappe dans le delai.
-- Rend ce qu'il advient de l'adversaire : "saved" (il revient dans la
-- partie) ou "waits" (tomber tout seul ne sauve personne : il attendra la
-- manche suivante). En mort subite, un duel a toujours un gagnant.
function Duels.outcome(hitBy: boolean, sudden: boolean): string
	if hitBy or sudden then
		return "saved"
	end
	return "waits"
end

-- Le goulag est-il ouvert a ce Regard, pour qui ne l'a pas encore utilise ?
function Duels.open(regard: number, closesAt: number, used: boolean): boolean
	return not used and regard < closesAt
end

return Duels
