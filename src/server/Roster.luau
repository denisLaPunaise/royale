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

local Roster = {}

-- Un joueur ou un bot.
export type Actor = Instance

local aliveSet: { [Actor]: boolean } = {}
local participants: { Actor } = {}
local beforeTake: { (Actor) -> () } = {}
local afterTake: { (Actor) -> () } = {}

local function publish()
	local n = 0
	for _ in aliveSet do
		n += 1
	end
	workspace:SetAttribute(Config.match.aliveAttribute, n)
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

-- L'Oeil prend ce participant : il monte vers le ciel, puis disparait.
function Roster.take(actor: Actor)
	if not aliveSet[actor] then
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
