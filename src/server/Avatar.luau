--!strict
--[[
	Avatar — le corps de chacun, joueurs et bots : un corps standard, sans
	accessoire ni paquet de corps, une peau et des vetements de couleurs
	unies.

	Pourquoi : avec l'avatar Roblox complet, un accessoire depassait d'une
	cachette et un corps reduit se cachait mieux (jeu de cache-cache : ce
	serait injuste). Et un joueur ne se distingue plus d'un bot. Les couleurs
	d'un joueur sont tirees de son numero de compte : toujours les memes,
	ses amis le reconnaissent.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Avatar = {}

local B = Config.bots

function Avatar.describe(random: Random): HumanoidDescription
	local description = Instance.new("HumanoidDescription")
	local tone = B.skins[random:NextInteger(1, #B.skins)]
	local skin = Color3.fromRGB(tone[1], tone[2], tone[3])
	description.HeadColor = skin
	description.LeftArmColor = skin
	description.RightArmColor = skin
	description.TorsoColor = Color3.fromHSV(
		random:NextNumber(),
		random:NextNumber(0.3, 0.8),
		random:NextNumber(0.3, 0.9)
	)
	local bottom = Color3.fromHSV(
		random:NextNumber(),
		random:NextNumber(0.1, 0.5),
		random:NextNumber(0.15, 0.6)
	)
	description.LeftLegColor = bottom
	description.RightLegColor = bottom
	-- Le corps standard de Roblox : sans ces deux reglages a zero, le corps
	-- prend des proportions plus elancees.
	description.BodyTypeScale = 0
	description.ProportionScale = 0
	return description
end

-- Un personnage neuf pour ce joueur, avec son avatar du jeu.
function Avatar.load(player: Player)
	player:LoadCharacterWithHumanoidDescription(Avatar.describe(Random.new(player.UserId)))
end

-- Un modele de bot (pas de joueur derriere).
function Avatar.model(random: Random): Model
	return Players:CreateHumanoidModelFromDescription(
		Avatar.describe(random),
		Enum.HumanoidRigType.R15
	)
end

return Avatar
