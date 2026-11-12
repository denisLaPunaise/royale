--!strict
--[[
	Circles — la zone ronde : la taille du prochain cercle et ou il tombe.

	Logique pure. Le hasard arrive en argument (deux nombres entre 0 et 1),
	pour que les tests le rejouent.

	La taille se calcule au moment de l'annoncer, d'apres les joueurs encore
	en vie (CONCEPT.md, valide le 12 novembre 2026) : on garde l'espace par
	joueur de la reference. Jamais plus grand que le cercle d'avant, jamais
	plus petit que le minimum. Le prochain cercle est toujours entierement
	dans l'actuel.
]]

local Circles = {}

export type Circle = { x: number, z: number, radius: number }
export type Reference = { diameter: number, alive: number }

function Circles.diameter(
	reference: Reference,
	alive: number,
	previous: number,
	minimum: number
): number
	-- La surface suit le nombre de joueurs : le diametre suit sa racine.
	local wanted = reference.diameter * math.sqrt(math.max(alive, 1) / reference.alive)
	return math.clamp(wanted, minimum, math.max(previous, minimum))
end

-- Le centre du prochain cercle, de rayon `radius`, tire dans l'actuel.
function Circles.place(
	current: Circle,
	radius: number,
	margin: number,
	u: number,
	v: number
): Circle
	local room = math.max(current.radius - radius - margin, 0)
	-- La racine : uniforme sur le disque, pas concentre au centre.
	local reach = room * math.sqrt(math.clamp(u, 0, 1))
	local angle = math.clamp(v, 0, 1) * math.pi * 2
	return {
		x = current.x + math.cos(angle) * reach,
		z = current.z + math.sin(angle) * reach,
		radius = radius,
	}
end

function Circles.contains(circle: Circle, x: number, z: number): boolean
	local dx, dz = x - circle.x, z - circle.z
	return dx * dx + dz * dz <= circle.radius * circle.radius
end

return Circles
