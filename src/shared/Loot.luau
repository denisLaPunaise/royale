--!strict
--[[
	Loot — ce qu'une fouille donne, sans Roblox. Les tirages recoivent leurs
	nombres au hasard en argument (`u` entre 0 et 1) : les tests les
	choisissent, le jeu les tire.
]]

local Loot = {}

-- L'ordre des raretes qu'on fouille (les legendaires ne se fouillent jamais).
Loot.searchable = { "common", "uncommon", "rare", "epic" }

-- Les poids d'une fouille dans un meuble : `danger` multiplie la chance
-- epique (le Cratere), le reste garde ses proportions.
function Loot.weights(
	base: { [string]: number },
	danger: boolean,
	epicFactor: number
): { [string]: number }
	local out: { [string]: number } = {}
	for rarity, w in base do
		out[rarity] = if danger and rarity == "epic" then w * epicFactor else w
	end
	return out
end

-- La chance de chaque rarete, en fraction (le total fait 1).
function Loot.chances(weights: { [string]: number }): { [string]: number }
	local total = 0
	for _, rarity in Loot.searchable do
		total += weights[rarity] or 0
	end
	local out: { [string]: number } = {}
	for _, rarity in Loot.searchable do
		out[rarity] = (weights[rarity] or 0) / total
	end
	return out
end

function Loot.rollRarity(weights: { [string]: number }, u: number): string
	local chances = Loot.chances(weights)
	local acc = 0
	for _, rarity in Loot.searchable do
		acc += chances[rarity]
		if u < acc then
			return rarity
		end
	end
	return Loot.searchable[#Loot.searchable]
end

-- Les ids du catalogue de cette rarete, tries (un tirage reproductible).
function Loot.ofRarity(items: { [string]: any }, rarity: string): { string }
	local out: { string } = {}
	for id, def in items do
		if def.rarity == rarity then
			table.insert(out, id)
		end
	end
	table.sort(out)
	return out
end

function Loot.pick(items: { [string]: any }, rarity: string, u: number): string?
	local list = Loot.ofRarity(items, rarity)
	if #list == 0 then
		return nil
	end
	return list[math.clamp(math.floor(u * #list) + 1, 1, #list)]
end

-- Les secondes de protection contre l'Oeil d'un sac : la somme des `shield`.
-- Rien ne s'additionne pour rendre intouchable (CONCEPT.md) : le test
-- d'equilibrage borne le pire sac de 4, et les bots choisissent le meilleur.
function Loot.shield(items: { [string]: any }, bag: { string }): number
	local total = 0
	for _, id in bag do
		local def = items[id]
		if def then
			total += def.shield
		end
	end
	return total
end

return Loot
