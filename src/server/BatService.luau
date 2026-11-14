--!strict
--[[
	BatService — la batte se voit en main (choisi avec Josh le 14 novembre
	2026) : au Ventre (la batte pour tous) et avec l'objet Batte ramasse en
	partie. Un joueur tient le skin de batte qu'il porte, sinon la batte de
	base ; un bot, la batte de base.

	Purement visible : le combat lit toujours ses regles (CombatService).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local CosmeticFx = require(script.Parent.CosmeticFx)
local GoulagService = require(script.Parent.GoulagService)
local Roster = require(script.Parent.Roster)
local ShopService = require(script.Parent.ShopService)

local BatService = {}

local held: { [Model]: Model } = {}

local function wants(actor: Roster.Actor): boolean
	local bat = actor:GetAttribute(Config.effects.batAttribute)
	return (typeof(bat) == "number" and bat > 0) or GoulagService.isInside(actor)
end

local function sync()
	local seen: { [Model]: boolean } = {}
	for _, actor in Roster.participants() do
		local character = Roster.characterOf(actor)
		if character == nil then
			continue
		end
		seen[character] = true
		local current = held[character]
		local want = wants(actor)
		if want and (current == nil or current.Parent == nil) then
			local hand = character:FindFirstChild("RightHand")
			if hand and hand:IsA("BasePart") then
				local skin = if actor:IsA("Player") then ShopService.equipped(actor, "bat") else nil
				local bat = CosmeticFx.bat(hand, skin)
				bat.Parent = character
				held[character] = bat
			end
		elseif not want and current then
			current:Destroy()
			held[character] = nil
		end
	end
	-- Les personnages partis (nouvelle partie, salon) : on oublie leur batte.
	for character, bat in held do
		if not seen[character] then
			bat:Destroy()
			held[character] = nil
		end
	end
end

function BatService.start()
	task.spawn(function()
		while true do
			local ok, err = pcall(sync)
			if not ok then
				warn("[Royale] Batte en main : " .. tostring(err))
			end
			task.wait(Config.cosmetics.batCheckSeconds)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		local character = player.Character
		if character and held[character] then
			held[character]:Destroy()
			held[character] = nil
		end
	end)
end

return BatService
