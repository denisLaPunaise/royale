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

-- Les objets du tirage : tout le catalogue sauf les objets du passe
-- (introuvables ailleurs), tries pour un ordre stable.
function Shop.drawPool(items: { [string]: any }): { string }
	local pool: { string } = {}
	for id, def in items do
		if not def.pass then
			table.insert(pool, id)
		end
	end
	table.sort(pool)
	return pool
end

-- La boutique du jour : `count` objets du tirage (hors permanents), choisis
-- d'apres le numero du jour. Le meme jour donne la meme boutique a tout le
-- monde, sur tous les serveurs.
function Shop.daily(
	items: { [string]: any },
	permanent: { string },
	day: number,
	count: number
): { string }
	local pool: { string } = {}
	for _, id in Shop.drawPool(items) do
		if not table.find(permanent, id) then
			table.insert(pool, id)
		end
	end
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

-- Les chances affichees avant l'achat : chaque rarete garde sa part du total
-- (`weights`), partagee a egalite entre ses objets ; total 100 %.
function Shop.chances(
	items: { [string]: any },
	pool: { string },
	weights: { [string]: number }
): { [string]: number }
	local count: { [string]: number } = {}
	for _, id in pool do
		local r = items[id].rarity
		count[r] = (count[r] or 0) + 1
	end
	local total = 0
	for r in count do
		total += weights[r] or 0
	end
	local out: { [string]: number } = {}
	for _, id in pool do
		local r = items[id].rarity
		out[id] = if total > 0 then (weights[r] or 0) / total / count[r] else 0
	end
	return out
end

-- Le prix d'un tirage en credits : la valeur moyenne de ce qu'il donne
-- (CONCEPT.md : sinon un tirage reviendrait moins cher que les objets chers).
function Shop.drawPrice(
	items: { [string]: any },
	prices: { [string]: number },
	pool: { string },
	weights: { [string]: number }
): number
	local chances = Shop.chances(items, pool, weights)
	local total = 0
	for _, id in pool do
		total += chances[id] * Shop.price(items, prices, id)
	end
	return math.ceil(total)
end

-- Un tirage : un objet du tirage, `u` entre 0 et 1, selon ses chances. Il
-- donne toujours quelque chose.
function Shop.draw(
	items: { [string]: any },
	pool: { string },
	weights: { [string]: number },
	u: number
): string
	local chances = Shop.chances(items, pool, weights)
	local acc = 0
	for _, id in pool do
		acc += chances[id]
		if u < acc then
			return id
		end
	end
	return pool[#pool]
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
