--!strict
--[[
	Throw — la trajectoire d'un lancer, sans Roblox : la meme formule pour le
	trait de visee du client et le point de chute du serveur. Les vecteurs
	sont des { x, y, z }.
]]

local Throw = {}

export type V3 = { x: number, y: number, z: number }

-- La vitesse de depart : la direction du regard, relevee de `lift` radians.
function Throw.velocity(look: V3, speed: number, lift: number): V3
	local flat = math.sqrt(look.x * look.x + look.z * look.z)
	if flat < 1e-6 then
		-- Droit en haut ou en bas : on garde la verticale.
		return { x = 0, y = (if look.y >= 0 then 1 else -1) * speed, z = 0 }
	end
	local pitch = math.atan2(look.y, flat) + lift
	pitch = math.clamp(pitch, -math.pi / 2, math.pi / 2)
	local c = math.cos(pitch)
	return {
		x = look.x / flat * c * speed,
		y = math.sin(pitch) * speed,
		z = look.z / flat * c * speed,
	}
end

-- La position a l'instant `t`.
function Throw.at(origin: V3, velocity: V3, gravity: number, t: number): V3
	return {
		x = origin.x + velocity.x * t,
		y = origin.y + velocity.y * t - gravity * t * t / 2,
		z = origin.z + velocity.z * t,
	}
end

return Throw
