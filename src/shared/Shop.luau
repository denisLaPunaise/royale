--!strict
--[[
	Shop — la boutique, les tirages et le passe, sans Roblox (CONCEPT.md,
	Progression et boutique).

	Logique pure : aucun require, aucune API Roblox. Le catalogue et les
	tirages au hasard arrivent en argument.
]]

local Shop = {}

-- Le prix d'un objet (d'apres sa rarete).
function Shop.price(items: { [string]: any }, prices: { [string]: number }, id: string): number
	local def = items[id]
	return if def then prices[def.rarity] else math.huge
end

-- La boutique du jour : `count` objets du catalogue (hors permanents),
-- choisis d'apres le numero du jour. Le meme jour donne la meme boutique a
-- tout le monde, sur tous les serveurs.
function Shop.daily(
	items: { [string]: any },
	permanent: { string },
	day: number,
	count: number
): { string }
	local pool: { string } = {}
	for id in items do
		if not table.find(permanent, id) then
			table.insert(pool, id)
		end
	end
	table.sort(pool)
	-- Un melange reproductible (un generateur lineaire seme par le jour).
	local state = (day * 2654435761) % 2147483648
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

-- Le prix d'un tirage en credits : la valeur moyenne de la selection
-- (CONCEPT.md : sinon un tirage reviendrait moins cher que les objets chers).
function Shop.drawPrice(
	items: { [string]: any },
	prices: { [string]: number },
	pool: { string }
): number
	local total = 0
	for _, id in pool do
		total += Shop.price(items, prices, id)
	end
	return math.ceil(total / #pool)
end

-- Les chances affichees avant l'achat : toutes egales (Josh), total 100 %.
function Shop.chances(pool: { string }): { [string]: number }
	local out: { [string]: number } = {}
	for _, id in pool do
		out[id] = 1 / #pool
	end
	return out
end

-- Un tirage : un objet de la selection, `u` entre 0 et 1. Il donne toujours
-- quelque chose.
function Shop.draw(pool: { string }, u: number): string
	return pool[math.clamp(math.floor(u * #pool) + 1, 1, #pool)]
end

-- Le palier du passe pour cette XP de passe.
function Shop.tier(passXp: number, tierXp: number, tiers: number): number
	return math.clamp(math.floor(passXp / tierXp), 0, tiers)
end

-- Les recompenses gagnees en passant du palier `from` (exclu) a `to`
-- (inclus), pour une piste.
function Shop.passRewards(track: { [number]: any }, from: number, to: number): { any }
	local out = {}
	for tier = from + 1, to do
		if track[tier] then
			table.insert(out, track[tier])
		end
	end
	return out
end

return Shop
