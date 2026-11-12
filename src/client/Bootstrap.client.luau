--!strict
--[[
	Bootstrap — point d'entree client, et le seul.

	Le client affiche et envoie des intentions ; il ne decide de rien. Chaque
	module d'interface et d'entree demarre d'ici, dans cet ordre.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local AimView = require(script.Parent.AimView)
local Controls = require(script.Parent.Controls)
local ItemView = require(script.Parent.ItemView)
local Hud = require(script.Parent.Hud)
local SkyView = require(script.Parent.SkyView)
local Spectate = require(script.Parent.Spectate)
local ZoneView = require(script.Parent.ZoneView)

print(
	string.format(
		"[Royale] Client démarré pour %s — réglages version %d",
		Players.LocalPlayer.Name,
		Config.version
	)
)

Hud.start()
ZoneView.start()
task.spawn(SkyView.start)
task.spawn(AimView.start)
task.spawn(Controls.start)
Spectate.start()
task.spawn(ItemView.start)
