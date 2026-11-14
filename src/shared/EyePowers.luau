--!strict
--[[
	EyePowers — les pouvoirs que l'Oeil gagne, un par Regard (CONCEPT.md).

	Logique pure : aucun require, aucune API Roblox. Le catalogue
	(Config.eyePowers.list) et les tirages (`u`, entre 0 et 1) arrivent en
	argument.

	Un pouvoir ne fait rien par lui-meme : `apply` rend une copie du Regard
	(Config.regards[n]) avec les champs que les services lisent (faisceaux en
	plus, pauses raccourcies, regard rasant...). Ainsi tout ce qui change
	l'Oeil se lit en un seul endroit.
]]

local EyePowers = {}

-- Les ids du catalogue, tries : un tirage reproductible.
function EyePowers.ids(list: { [string]: any }): { string }
	local out: { string } = {}
	for id in list do
		table.insert(out, id)
	end
	table.sort(out)
	return out
end

-- Un pouvoir change-t-il quelque chose a ce Regard ? (CONCEPT.md : jamais un
-- pouvoir qui ne change rien.) Ce qui joue sur les pauses ne sert a rien
-- quand l'Oeil ne se ferme plus ; l'ouie totale, quand il entend deja tout.
function EyePowers.useful(id: string, regard: any): boolean
	if id == "hearAll" then
		return regard.hears ~= "tout"
	elseif id == "feint" or id == "longBurst" or id == "heavyLid" then
		return regard.closedSeconds > 0
	end
	return true
end

-- Ce qu'on peut tirer : ni deja gagne, ni inutile a ce Regard.
function EyePowers.eligible(list: { [string]: any }, owned: { string }, regard: any): { string }
	local have: { [string]: boolean } = {}
	for _, id in owned do
		have[id] = true
	end
	local out: { string } = {}
	for _, id in EyePowers.ids(list) do
		if not have[id] and EyePowers.useful(id, regard) then
			table.insert(out, id)
		end
	end
	return out
end

function EyePowers.draw(list: { [string]: any }, owned: { string }, regard: any, u: number): string?
	local pool = EyePowers.eligible(list, owned, regard)
	if #pool == 0 then
		return nil
	end
	return pool[math.clamp(math.floor(u * #pool) + 1, 1, #pool)]
end

-- Le Regard tel que l'Oeil le joue avec ses pouvoirs. `u` rend un nombre au
-- hasard entre 0 et 1 (les faux departs, la rafale allongee) ; il est appele
-- une fois par Regard, pas a chaque pas.
function EyePowers.apply(
	regard: any,
	owned: { string },
	list: { [string]: any },
	u: () -> number
): any
	local out = table.clone(regard)
	local have: { [string]: boolean } = {}
	for _, id in owned do
		have[id] = true
	end
	if have.hearAll then
		out.hears = "tout"
	end
	if have.rage then
		out.rageEvery = list.rage.every
		out.rageBeams = list.rage.beams
	end
	if have.heavyLid and out.closedSeconds > 0 then
		out.closedSeconds *= list.heavyLid.closedFactor
	end
	if have.feint and out.closedSeconds > 0 then
		-- Assez de pauses pour le Regard le plus long, rafales les plus courtes.
		local pauses = math.ceil(out.seconds / (out.openSeconds + list.feint.seconds)) + 1
		local feints: { [number]: boolean } = {}
		for i = 1, pauses do
			-- Jamais deux de suite : « de temps en temps », et il reste
			-- toujours une vraie pause sur deux pour fouiller.
			local roll = u()
			if not feints[i - 1] and roll < list.feint.chance then
				feints[i] = true
			end
		end
		out.feints = feints
		out.feintSeconds = math.min(list.feint.seconds, out.closedSeconds)
	end
	if have.longBurst and out.closedSeconds > 0 then
		local among = list.longBurst.among
		out.longBurst = math.clamp(math.floor(u() * among) + 1, 1, among)
		out.longFactor = list.longBurst.factor
	end
	if have.hunger then
		out.ripsPerBurst = math.ceil(out.ripsPerBurst * list.hunger.ripFactor)
	end
	if have.slowSure then
		out.chaseSpeed *= list.slowSure.chaseFactor
		out.memorySeconds += list.slowSure.memoryBonus
	end
	out.flair = have.flair == true
	out.markFactor = if have.grudge then list.grudge.markFactor else 1
	out.prints = have.prints == true
	if have.slant then
		out.slantElevation = list.slant.elevation
	end
	if have.flash then
		out.flashSeconds = list.flash.seconds
	end
	if have.comeback then
		out.comebackDelay = list.comeback.delay
		out.comebackLinger = list.comeback.linger
	end
	if have.wind then
		out.windSpeed = list.wind.speed
		out.windLift = list.wind.lift
	end
	return out
end

-- Le point d'ou part le regard rasant : a la meme distance que la pupille,
-- `elevation` degres au-dessus de l'horizon, du cote de l'Oeil. Vecteurs en
-- { x, y, z }. Sous l'Oeil a la verticale, il arrive de l'est (+x).
function EyePowers.slantOrigin(
	target: { x: number, y: number, z: number },
	eye: { x: number, y: number, z: number },
	elevation: number
): { x: number, y: number, z: number }
	local dx, dy, dz = eye.x - target.x, eye.y - target.y, eye.z - target.z
	local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
	local flat = math.sqrt(dx * dx + dz * dz)
	local hx, hz = 1, 0
	if flat > 1e-6 then
		hx, hz = dx / flat, dz / flat
	end
	local a = math.rad(elevation)
	return {
		x = target.x + hx * math.cos(a) * distance,
		y = target.y + math.sin(a) * distance,
		z = target.z + hz * math.cos(a) * distance,
	}
end

return EyePowers
