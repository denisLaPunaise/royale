--!strict
--[[
	SignalService — les signaux rapides a la croix (CONCEPT.md) : « Danger ! »
	et « Ici ! », la ou l'on regarde. Le serveur verifie (une sorte connue, a
	portee, pas trop souvent) et les renvoie a soi et a ses coequipiers
	seulement : les morts ne denoncent pas, les ennemis ne voient rien.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local RemoteGuard = require(script.Parent.RemoteGuard)
local Roster = require(script.Parent.Roster)
local SquadService = require(script.Parent.SquadService)

local SignalService = {}

local SG = Config.signals
local last: { [Player]: number } = {}

local function send(remote: RemoteEvent, player: Player, kind: any, at: any)
	if typeof(kind) ~= "string" or SG.kinds[kind] == nil or typeof(at) ~= "Vector3" then
		return
	end
	-- Seulement en jeu (en vie dans la partie) : un elimine ne signale rien.
	local root = Roster.rootOf(player)
	if root == nil or not Roster.isAlive(player) then
		return
	end
	if (at - root.Position).Magnitude > SG.range then
		return
	end
	local now = os.clock()
	if now - (last[player] or -math.huge) < SG.cooldown then
		return
	end
	last[player] = now
	for _, other in Players:GetPlayers() do
		if other == player or SquadService.allies(player, other) then
			remote:FireClient(other, kind, at, player.DisplayName)
		end
	end
end

function SignalService.start(remote: RemoteEvent)
	remote.OnServerEvent:Connect(
		RemoteGuard.wrap(Config.remotes.signal, function(player: Player, kind: any, at: any)
			send(remote, player, kind, at)
		end)
	)
	Players.PlayerRemoving:Connect(function(player: Player)
		last[player] = nil
	end)
end

return SignalService
