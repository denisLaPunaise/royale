--!strict
--[[
	ZoneService — le cercle de chaque Regard (CONCEPT.md, La carte).

	Au debut d'un Regard, le prochain cercle s'annonce : sa taille vient des
	joueurs encore en vie (Circles.diameter), sa place est tiree dans le cercle
	actuel. Apres `announceSeconds`, le cercle actuel se resserre jusqu'a lui en
	`shrinkSeconds`. Dehors, l'Oeil voit tout : la jauge monte sans faisceau
	(EyeService lit `ZoneService.outside`).

	Publie pour l'interface : attributs de Workspace `Cercle` et
	`CercleSuivant`, des Vector3 (x, rayon, z).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Circles = require(Royale:WaitForChild("Circles"))
local Config = require(Royale:WaitForChild("Config"))

local ZoneService = {}

local Z = Config.zone

type Circle = Circles.Circle

local current: Circle = { x = 0, z = 0, radius = Z.startRadius }
local from: Circle = current
local target: Circle? = nil
local shrinkStart = math.huge
local random = Random.new()

local function encode(circle: Circle): Vector3
	return Vector3.new(circle.x, circle.radius, circle.z)
end

local function publish()
	workspace:SetAttribute(Z.attribute, encode(current))
	workspace:SetAttribute(Z.nextAttribute, if target then encode(target) else nil)
end

function ZoneService.reset()
	current = { x = 0, z = 0, radius = Z.startRadius }
	from = current
	target = nil
	shrinkStart = math.huge
	publish()
end

-- Un nouveau Regard commence a `now` (os.clock) : annonce son cercle.
function ZoneService.announce(regardIndex: number, alive: number, now: number)
	local reference = Z.reference[regardIndex]
	if reference == nil then
		return
	end
	-- Le cercle precedent pas encore fini de se resserrer : on part de la ou
	-- il en est.
	if target then
		current = target
	end
	local diameter = Circles.diameter(reference, alive, current.radius * 2, Z.minDiameter)
	from = current
	target = Circles.place(
		current,
		diameter / 2,
		Z.insideMargin,
		random:NextNumber(),
		random:NextNumber()
	)
	shrinkStart = now + Config.regards[regardIndex].announceSeconds
	publish()
	print(
		string.format(
			"[Royale] Cercle %d annoncé : %d studs de large, %d en vie",
			regardIndex,
			math.floor(diameter),
			alive
		)
	)
end

function ZoneService.step(now: number)
	local nextCircle = target
	if nextCircle == nil or now < shrinkStart then
		return
	end
	local k = math.clamp((now - shrinkStart) / Z.shrinkSeconds, 0, 1)
	current = {
		x = from.x + (nextCircle.x - from.x) * k,
		z = from.z + (nextCircle.z - from.z) * k,
		radius = from.radius + (nextCircle.radius - from.radius) * k,
	}
	if k >= 1 then
		current = nextCircle
		target = nil
		shrinkStart = math.huge
	end
	publish()
end

function ZoneService.outside(position: Vector3): boolean
	return not Circles.contains(current, position.X, position.Z)
end

-- Ramene un point dans le cercle (les faisceaux n'en sortent pas).
function ZoneService.clamp(x: number, z: number): (number, number)
	local dx, dz = x - current.x, z - current.z
	local d = math.sqrt(dx * dx + dz * dz)
	if d <= current.radius or d == 0 then
		return x, z
	end
	return current.x + dx / d * current.radius, current.z + dz / d * current.radius
end

function ZoneService.current(): Circle
	return current
end

return ZoneService
