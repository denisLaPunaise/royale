--!strict
--[[
	World — ce que la recette a construit, verifie au demarrage, et la ligne
	de vue de l'Oeil.

	L'Oeil ne triche jamais : etre vu, c'est une ligne reelle entre le bout de
	sa pupille et la tete (ou le bassin) du joueur. Une part qui porte
	l'attribut `Couvert` laisse passer une partie du regard (buisson, roseaux) ;
	une part presque transparente (vitre) ne cache rien ; tout le reste cache.
	Repris de Survivor, ou la regle a ete reglee.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local EyePowers = require(Royale:WaitForChild("EyePowers"))

local World = {}

local W = Config.world

World.root = nil :: Folder?
World.sky = nil :: Instance?
World.anchors = nil :: Folder?
World.solidSpots = nil :: Folder?
World.prefabs = nil :: Folder?
-- Le bout de la pupille, d'ou partent tous les regards.
World.eyeOrigin = Vector3.zero

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = false

-- Ce que les rayons ignorent toujours : le ciel (la voute entoure l'Oeil) et
-- tout ce que le jeu pose pour l'affichage. Rempli par `World.ignore`.
local alwaysIgnored: { Instance } = {}

-- Verifie le contrat de nommage ; rend la liste de ce qui manque.
function World.check(): { string }
	local missing: { string } = {}
	local root = workspace:FindFirstChild(W.folder)
	if root == nil then
		return { "Workspace." .. W.folder .. " (la recette de la carte n'a pas tourne)" }
	end
	World.root = root :: Folder
	for _, name in { W.sky, W.anchors, W.solidSpots } do
		if root:FindFirstChild(name) == nil then
			table.insert(missing, W.folder .. "." .. name)
		end
	end
	World.sky = root:FindFirstChild(W.sky)
	World.anchors = root:FindFirstChild(W.anchors) :: Folder?
	World.solidSpots = root:FindFirstChild(W.solidSpots) :: Folder?
	World.prefabs = ServerStorage:FindFirstChild(W.prefabs) :: Folder?
	if World.prefabs == nil then
		table.insert(missing, "ServerStorage." .. W.prefabs)
	end
	local sky = World.sky
	local eye = sky and sky:FindFirstChild(W.eye)
	local globe = eye and (eye :: Model).PrimaryPart
	if globe == nil then
		table.insert(missing, "le globe de l'Oeil")
	else
		-- Le bout de la pupille : le point le plus bas des parts `Pupille`,
		-- mesure sur le modele (cote serveur, il regarde droit vers le sol).
		local tip = globe.Position - Vector3.new(0, globe.Size.Y / 2, 0)
		for _, part in (eye :: Model):GetDescendants() do
			if part:IsA("BasePart") and part.Name == "Pupille" then
				local bottom = part.Position.Y - part.Size.Z / 2
				if bottom < tip.Y then
					tip = Vector3.new(globe.Position.X, bottom, globe.Position.Z)
				end
			end
		end
		World.eyeOrigin = tip
		table.insert(alwaysIgnored, sky :: Instance)
	end
	return missing
end

function World.ignore(instance: Instance)
	table.insert(alwaysIgnored, instance)
end

-- La part du regard qui atteint `target` depuis la pupille : 1 a decouvert,
-- 0 cache, entre les deux derriere un buisson.
function World.visibility(target: Vector3, ignore: { Instance }, from: Vector3?): number
	local eye = Config.eye
	local seen = 1
	local origin = from or World.eyeOrigin
	local filter = table.clone(alwaysIgnored)
	for _, instance in ignore do
		table.insert(filter, instance)
	end
	for _ = 1, eye.maxRayHops do
		rayParams.FilterDescendantsInstances = filter
		local hit = workspace:Raycast(origin, target - origin, rayParams)
		if hit == nil then
			return seen
		end
		local part = hit.Instance
		local cover = part:GetAttribute(W.coverAttribute)
		if typeof(cover) == "number" then
			seen *= math.clamp(1 - cover, 0, 1)
		elseif part.Transparency < eye.seeThroughTransparency then
			return 0
		end
		-- Vitre ou buisson : on continue derriere.
		table.insert(filter, part)
		origin = hit.Position
		if seen <= 0 then
			return 0
		end
	end
	-- Trop de couches : le doute profite au joueur.
	return 0
end

-- Le regard rasant (pouvoir) : le meme point vu d'un second endroit, plus bas
-- sur l'horizon ; il voit ce que l'un des deux voit.
local function slanted(target: Vector3, ignore: { Instance }, elevation: number?): number
	local seen = World.visibility(target, ignore)
	if elevation == nil or seen >= 1 then
		return seen
	end
	local o = World.eyeOrigin
	local from = EyePowers.slantOrigin(
		{ x = target.X, y = target.Y, z = target.Z },
		{ x = o.X, y = o.Y, z = o.Z },
		elevation
	)
	return math.max(seen, World.visibility(target, ignore, Vector3.new(from.x, from.y, from.z)))
end

-- Ce que l'Oeil voit d'un personnage : le mieux de sa tete et de son bassin.
-- Les personnages ne se cachent pas les uns les autres. `slant` : l'elevation
-- du regard rasant, s'il l'a.
function World.seenFactor(character: Model, slant: number?): number
	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not (head and head:IsA("BasePart") and root and root:IsA("BasePart")) then
		return 0
	end
	local ignore: { Instance } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	return math.max(slanted(head.Position, ignore, slant), slanted(root.Position, ignore, slant))
end

-- Le sol sous un point (le plus haut solide), ou nil au-dessus du vide.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.RespectCanCollide = true

function World.ground(x: number, z: number, ignore: { Instance }?): Vector3?
	local filter = table.clone(alwaysIgnored)
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(filter, player.Character)
		end
	end
	if ignore then
		for _, instance in ignore do
			table.insert(filter, instance)
		end
	end
	groundParams.FilterDescendantsInstances = filter
	local hit = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -800, 0), groundParams)
	return hit and hit.Position
end

return World
