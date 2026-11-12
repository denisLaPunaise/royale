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
local GestureView = require(script.Parent.GestureView)
local ItemView = require(script.Parent.ItemView)
local LobbyView = require(script.Parent.LobbyView)
local Hud = require(script.Parent.Hud)
local PlayerListView = require(script.Parent.PlayerListView)
local PostureView = require(script.Parent.PostureView)
local ShopView = require(script.Parent.ShopView)
local SkyView = require(script.Parent.SkyView)
local SoundView = require(script.Parent.SoundView)
local Spectate = require(script.Parent.Spectate)
local TeamView = require(script.Parent.TeamView)
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
task.spawn(TeamView.start)
task.spawn(GestureView.start)
task.spawn(PlayerListView.start)
task.spawn(PostureView.start)
task.spawn(SoundView.start)
task.spawn(LobbyView.start)
task.spawn(ShopView.start)
