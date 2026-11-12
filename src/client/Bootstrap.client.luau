--!strict
--[[
	Bootstrap — point d'entree client, et le seul.

	Le client affiche et envoie des intentions ; il ne decide de rien. Chaque
	module d'interface et d'entree se demarrera depuis ici.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

print(
	string.format(
		"[Royale] Client démarré pour %s — réglages version %d",
		Players.LocalPlayer.Name,
		Config.version
	)
)
