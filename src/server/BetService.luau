--!strict
--[[
	BetService — ce que fait un elimine pour de bon (CONCEPT.md, Capture) :
	regarder (l'ecran, Spectate), parier sur celui qu'il regarde, ou quitter.

	Un pari est gratuit et rapporte un peu de credits s'il est juste (les
	credits arrivent avec la progression : `onWin`). Jamais sur un ami
	Roblox. Quitter le renvoie au salon (le salon s'en charge : `onQuit`).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local Bets = require(Royale:WaitForChild("Bets"))

local GoulagService = require(script.Parent.GoulagService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Roster = require(script.Parent.Roster)

local BetService = {}

local BT = Config.bets
-- Parieur (idOf) -> cible (idOf).
local bets: { [string]: string } = {}
local byId: { [string]: Player } = {}
local winListeners: { (Player) -> () } = {}
local quitListeners: { (Player) -> () } = {}

local function notify(player: Player, text: string)
	player:SetAttribute(
		Config.bag.messageAttribute,
		text .. "|" .. tostring(workspace:GetServerTimeNow())
	)
end

-- Le participant derriere ce qu'envoie le client (un Player, ou le modele
-- d'un bot).
local function actorOf(thing: any): Roster.Actor?
	if typeof(thing) ~= "Instance" then
		return nil
	end
	if thing:IsA("Player") then
		return thing
	end
	local bots = workspace:FindFirstChild(Config.bots.folder)
	if thing:IsA("Model") and bots and thing.Parent == bots then
		return thing
	end
	return nil
end

local function friends(player: Player, target: Roster.Actor): boolean
	if not target:IsA("Player") then
		return false
	end
	local ok, result = pcall(function()
		return player:IsFriendsWith((target :: Player).UserId)
	end)
	if not ok then
		-- Dans le doute, on refuse : un pari entre amis est ce qu'on veut
		-- empecher.
		warn("[Royale] Amis Roblox illisibles : " .. tostring(result))
		return true
	end
	return result
end

local function place(player: Player, thing: any)
	local target = actorOf(thing)
	local regard = workspace:GetAttribute(Config.match.regardAttribute)
	local id = Roster.idOf(player)
	local ok, why = Bets.allowed({
		regard = if typeof(regard) == "number" then regard else math.huge,
		untilRegard = BT.untilRegard,
		eliminated = not Roster.isAlive(player) and not GoulagService.isInside(player),
		already = bets[id] ~= nil,
		targetAlive = target ~= nil and Roster.isAlive(target),
		friends = target ~= nil and friends(player, target),
	})
	if not ok or target == nil then
		notify(player, why or "Impossible.")
		return
	end
	bets[id] = Roster.idOf(target)
	byId[id] = player
	player:SetAttribute(BT.attribute, Roster.nameOf(target))
	notify(player, "Tu paries sur " .. Roster.nameOf(target))
end

-- La fin de la partie : les paris justes rapportent.
function BetService.settle(winners: { Roster.Actor })
	local ids: { string } = {}
	for _, actor in winners do
		table.insert(ids, Roster.idOf(actor))
	end
	for _, bettor in Bets.winners(bets, ids) do
		local player = byId[bettor]
		if player and player.Parent then
			notify(player, "Pari gagné !")
			for _, listener in winListeners do
				listener(player)
			end
		end
	end
end

function BetService.onWin(listener: (Player) -> ())
	table.insert(winListeners, listener)
end

function BetService.onQuit(listener: (Player) -> ())
	table.insert(quitListeners, listener)
end

function BetService.reset()
	for _, player in byId do
		if player.Parent then
			player:SetAttribute(BT.attribute, nil)
		end
	end
	for _, player in Players:GetPlayers() do
		player:SetAttribute(BT.leftAttribute, nil)
	end
	table.clear(bets)
	table.clear(byId)
end

function BetService.start(betRemote: RemoteEvent, quitRemote: RemoteEvent)
	betRemote.OnServerEvent:Connect(
		RemoteGuard.wrap(Config.remotes.bet, function(player: Player, thing: any)
			place(player, thing)
		end)
	)
	quitRemote.OnServerEvent:Connect(RemoteGuard.wrap(Config.remotes.quit, function(player: Player)
		if Roster.isAlive(player) or GoulagService.isInside(player) then
			return
		end
		player:SetAttribute(BT.leftAttribute, true)
		for _, listener in quitListeners do
			listener(player)
		end
	end))
end

return BetService
