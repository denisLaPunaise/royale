--!strict
--[[
	Roster — qui joue cette partie, qui est encore en vie, et l'aspiration.

	Un participant est un joueur (Player) ou un bot (son Model, dans
	Workspace.Participants). Les deux portent les memes attributs et passent
	par les memes regles : l'Oeil ne fait aucune difference (CONCEPT.md, les
	bots sont invisibles).

	Un participant aspire n'est plus « en vie » a l'instant meme : l'Oeil
	arrete de le regarder et le cercle de le compter, meme si l'animation dure
	encore. L'aspiration est la seule facon de sortir de la partie.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Sfx = require(script.Parent.Sfx)

local Roster = {}

-- Un joueur ou un bot.
export type Actor = Instance

local aliveSet: { [Actor]: boolean } = {}
local participants: { Actor } = {}
local beforeTake: { (Actor) -> () } = {}
local afterTake: { (Actor) -> () } = {}
-- Peut annuler une aspiration (le Cocon de secours) : rend vrai s'il sauve.
local saver: ((Actor) -> boolean)? = nil
-- Garde le corps d'un aspire apres l'aspiration (le goulag) : rend vrai s'il
-- le prend en charge, et le corps n'est pas detruit.
local keeper: ((Actor, Model) -> boolean)? = nil

local HttpService = game:GetService("HttpService")

-- L'equipe de chacun, gardee : un bot aspire disparait avec son attribut.
local teamOf: { [Actor]: number } = {}

-- Le nombre en vie, et la liste des joueurs du jeu (CONCEPT.md : la liste de
-- Roblox trahirait les bots) : nom, equipe, en vie ou non.
local function publish()
	local n = 0
	for _ in aliveSet do
		n += 1
	end
	workspace:SetAttribute(Config.match.aliveAttribute, n)
	local list = {}
	for _, actor in participants do
		local team = actor.Parent and actor:GetAttribute(Config.squads.attribute)
		if typeof(team) == "number" then
			teamOf[actor] = team
		end
		-- Le titre porte (un cosmetique), s'il y en a un.
		local titleId = actor.Parent
			and actor:GetAttribute(Config.cosmetics.attributePrefix .. "title")
		local title = if typeof(titleId) == "string" and Config.cosmetics.items[titleId]
			then Config.cosmetics.items[titleId].title
			else nil
		table.insert(list, {
			n = Roster.nameOf(actor),
			t = teamOf[actor] or 0,
			a = aliveSet[actor] == true,
			ti = title,
		})
	end
	workspace:SetAttribute(
		Config.match.listAttribute,
		if #list > 0 then HttpService:JSONEncode(list) else nil
	)
end

-- A appeler quand les equipes changent (elles arrivent apres le depart).
function Roster.refresh()
	publish()
end

function Roster.characterOf(actor: Actor): Model?
	if actor:IsA("Player") then
		return actor.Character
	elseif actor:IsA("Model") and actor.Parent then
		return actor
	end
	return nil
end

function Roster.rootOf(actor: Actor): BasePart?
	local character = Roster.characterOf(actor)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- Un identifiant stable pendant la partie (le ciblage s'en sert).
function Roster.idOf(actor: Actor): string
	if actor:IsA("Player") then
		return tostring(actor.UserId)
	end
	return "bot:" .. actor.Name
end

function Roster.nameOf(actor: Actor): string
	if actor:IsA("Player") then
		return actor.DisplayName
	end
	local humanoid = actor:FindFirstChildOfClass("Humanoid")
	return if humanoid then humanoid.DisplayName else actor.Name
end

function Roster.start(actors: { Actor })
	table.clear(aliveSet)
	participants = table.clone(actors)
	for _, actor in actors do
		aliveSet[actor] = true
		actor:SetAttribute(Config.match.aliveAttribute, true)
	end
	publish()
end

function Roster.clear()
	for _, actor in participants do
		if actor.Parent then
			actor:SetAttribute(Config.match.aliveAttribute, nil)
		end
	end
	table.clear(participants)
	table.clear(aliveSet)
	table.clear(teamOf)
	publish()
end

function Roster.startCount(): number
	return #participants
end

function Roster.isAlive(actor: Actor): boolean
	return aliveSet[actor] == true
end

function Roster.alive(): { Actor }
	local out: { Actor } = {}
	for actor in aliveSet do
		table.insert(out, actor)
	end
	return out
end

function Roster.count(): number
	local n = 0
	for _ in aliveSet do
		n += 1
	end
	return n
end

-- Appele juste avant (sortir de sa cachette) et juste apres (compter la fin).
function Roster.onBeforeTake(callback: (Actor) -> ())
	table.insert(beforeTake, callback)
end

function Roster.onTaken(callback: (Actor) -> ())
	table.insert(afterTake, callback)
end

function Roster.setSaver(callback: (Actor) -> boolean)
	saver = callback
end

function Roster.setKeeper(callback: (Actor, Model) -> boolean)
	keeper = callback
end

-- Sauve du goulag : de nouveau en vie dans la partie.
function Roster.revive(actor: Actor)
	if aliveSet[actor] or table.find(participants, actor) == nil then
		return
	end
	aliveSet[actor] = true
	actor:SetAttribute(Config.match.aliveAttribute, true)
	publish()
end

-- L'Oeil prend ce participant : il monte vers le ciel, puis disparait.
function Roster.take(actor: Actor)
	if not aliveSet[actor] then
		return
	end
	if saver and saver(actor) then
		return
	end
	aliveSet[actor] = nil
	actor:SetAttribute(Config.match.aliveAttribute, false)
	publish()
	for _, callback in beforeTake do
		callback(actor)
	end
	print(string.format("[Royale] %s est aspiré par l'Œil", Roster.nameOf(actor)))
	local character = Roster.characterOf(actor)
	local root = Roster.rootOf(actor)
	if character and root then
		local eye = Config.eye
		Sfx.at("aspiration", root.Position)
		root.Anchored = true
		local goal = root.CFrame
			* CFrame.new(0, eye.suctionHeight, 0)
			* CFrame.Angles(0, math.pi * 3, 0)
		TweenService:Create(
			root,
			TweenInfo.new(eye.suctionSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = goal }
		):Play()
		task.delay(eye.suctionSeconds, function()
			if keeper and character.Parent and keeper(actor, character) then
				return
			end
			if actor:IsA("Player") then
				if actor.Character == character then
					character:Destroy()
				end
			else
				character:Destroy()
			end
		end)
	end
	for _, callback in afterTake do
		callback(actor)
	end
end

Players.PlayerRemoving:Connect(function(player: Player)
	if aliveSet[player] then
		aliveSet[player] = nil
		publish()
		for _, callback in afterTake do
			callback(player)
		end
	end
end)

return Roster
