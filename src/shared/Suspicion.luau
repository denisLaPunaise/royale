--!strict
--[[
	Suspicion — la mefiance de l'Oeil envers ceux qui ne bougent pas.

	Logique pure. Un joueur cache qui reste dans `radius` autour du meme point
	voit sa jauge monter (pleine en `fillSeconds`) ; s'il s'eloigne de plus de
	`resetDistance`, le point se deplace avec lui et la jauge redescend.
	Pleine, il est flaire (CONCEPT.md, Contre le camping).
]]

local Suspicion = {}

export type State = { x: number, z: number, level: number }
export type Settings = { radius: number, resetDistance: number, drainSeconds: number }

function Suspicion.new(x: number, z: number): State
	return { x = x, z = z, level = 0 }
end

-- Un pas de temps. `hidden` : le joueur est cache (cachette ou recoin, pas vu).
function Suspicion.step(
	state: State,
	x: number,
	z: number,
	hidden: boolean,
	dt: number,
	fillSeconds: number,
	settings: Settings
): State
	local dx, dz = x - state.x, z - state.z
	local moved = math.sqrt(dx * dx + dz * dz)
	if moved > settings.resetDistance then
		-- Il a change de place : nouveau point, et la jauge commence a baisser.
		return {
			x = x,
			z = z,
			level = math.max(state.level - dt / settings.drainSeconds, 0),
		}
	end
	if hidden and moved <= settings.radius then
		return { x = state.x, z = state.z, level = math.min(state.level + dt / fillSeconds, 1) }
	end
	return {
		x = state.x,
		z = state.z,
		level = math.max(state.level - dt / settings.drainSeconds, 0),
	}
end

function Suspicion.isFlagged(state: State): boolean
	return state.level >= 1
end

return Suspicion
