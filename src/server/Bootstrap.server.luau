--!strict
--[[
	Bootstrap — point d'entree serveur, et le seul.

	Aucune logique ici : il annonce l'etat des reglages, puis demarre les
	services dans l'ordre. Toute nouvelle mecanique se branche sur cette liste,
	et nulle part ailleurs.

	La banniere n'annonce QUE ce qu'un service execute. Une ligne de banniere
	qui decrit une regle que personne n'applique est exactement la panne
	qu'Arena a vue quatre fois. Pour l'instant aucun service ne tourne : la
	carte se construit d'abord (choix de Josh, 12 novembre 2026).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

print("================================================")
print(string.format("[Royale] Serveur démarré — réglages version %d", Config.version))
print("[Royale] Aucune mécanique branchée : la carte se construit d'abord.")
print("================================================")
