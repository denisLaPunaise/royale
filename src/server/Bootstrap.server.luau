--!strict
--[[
	Bootstrap — point d'entree serveur, et le seul.

	Aucune logique ici : il verifie la carte, annonce ce qui tourne, puis
	demarre la partie. Toute nouvelle mecanique se branche sur cette liste, et
	nulle part ailleurs.

	La banniere n'annonce QUE ce qu'un service execute. Une ligne qui decrit
	une regle que personne n'applique est exactement la panne qu'Arena a vue
	quatre fois.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local MatchService = require(script.Parent.MatchService)
local World = require(script.Parent.World)

print("================================================")
print(string.format("[Royale] Serveur démarré — réglages version %d", Config.version))

local missing = World.check()
if #missing > 0 then
	-- Sans carte, une partie ne veut rien dire : on le dit et on s'arrete.
	warn(
		"[Royale] La carte est incomplète, aucune partie ne démarre. Manque : "
			.. table.concat(missing, ", ")
	)
	print("================================================")
	return
end

print(
	string.format(
		"[Royale] %d Regards, l'Œil voit depuis la pupille (%d de haut), le cercle se resserre",
		#Config.regards,
		math.floor(World.eyeOrigin.Y)
	)
)
print(
	"[Royale] Cachettes posées à chaque partie, marquées et arrachées ; méfiance contre le camping"
)
print("================================================")

MatchService.start()
