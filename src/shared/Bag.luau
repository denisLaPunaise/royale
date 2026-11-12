--!strict
--[[
	Bag — le sac de 4 places (CONCEPT.md), sans Roblox. Une place vide vaut
	"". Le sac voyage dans un attribut : des ids separes par des virgules.
]]

local Bag = {}

export type Bag = { string }

function Bag.new(slots: number): Bag
	local b: Bag = {}
	for i = 1, slots do
		b[i] = ""
	end
	return b
end

function Bag.encode(b: Bag): string
	return table.concat(b, ",")
end

function Bag.decode(text: string, slots: number): Bag
	local b = Bag.new(slots)
	local i = 1
	for id in string.gmatch(text .. ",", "([^,]*),") do
		if i > slots then
			break
		end
		b[i] = id
		i += 1
	end
	return b
end

-- Ajoute `id`. Sac plein : il prend la place choisie, et l'ancien tombe.
-- Rend le nouveau sac, la place remplie et ce qui tombe ("" si rien).
function Bag.add(b: Bag, id: string, selected: number): (Bag, number, string)
	local out = table.clone(b)
	for i, slot in out do
		if slot == "" then
			out[i] = id
			return out, i, ""
		end
	end
	local dropped = out[selected]
	out[selected] = id
	return out, selected, dropped
end

-- Retire l'objet de la place `i` ; rend le sac et ce qui y etait.
function Bag.take(b: Bag, i: number): (Bag, string)
	local out = table.clone(b)
	local id = out[i] or ""
	out[i] = ""
	return out, id
end

-- La place suivante (ou precedente, `step` = -1), en boucle.
function Bag.cycle(selected: number, step: number, slots: number): number
	return (selected - 1 + step) % slots + 1
end

function Bag.has(b: Bag, id: string): number?
	for i, slot in b do
		if slot == id then
			return i
		end
	end
	return nil
end

-- Les objets non vides (pour compter, voler).
function Bag.items(b: Bag): { string }
	local out: { string } = {}
	for _, slot in b do
		if slot ~= "" then
			table.insert(out, slot)
		end
	end
	return out
end

return Bag
