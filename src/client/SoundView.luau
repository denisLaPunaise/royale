--!strict
--[[
	SoundView — ce qu'on entend de son propre point de vue (repris de
	Survivor).

	- L'ambiance : le vent dehors, un coeur lent dans le Ventre (le goulag).
	- L'Oeil : un coup sourd et un grondement quand le ciel rougit, ses
	  paupieres qui s'ouvrent et se ferment, son regard qui bourdonne de plus
	  en plus fort quand un faisceau approche, un murmure quand il te voit.

	Les sons poses dans le monde (coups, fouilles, aspirations, Repris) sont
	joues par le serveur (Sfx). Tous sont precharges : un son qui ne charge
	pas est nomme dans la console plutot que de manquer en silence.
]]

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local SoundView = {}

local S = Config.sounds
local sounds: { [string]: Sound } = {}

local function play(name: string)
	local sound = sounds[name]
	if sound then
		sound.TimePosition = 0
		sound:Play()
	end
end

local function fadeTo(name: string, volume: number)
	local sound = sounds[name]
	if sound == nil then
		return
	end
	if volume > 0 and not sound.IsPlaying then
		sound.Volume = 0
		sound:Play()
	end
	local tween = TweenService:Create(sound, TweenInfo.new(S.fadeSeconds), { Volume = volume })
	tween:Play()
	if volume == 0 then
		tween.Completed:Once(function()
			if sound.Volume == 0 then
				sound:Stop()
			end
		end)
	end
end

-- La distance au faisceau allume le plus proche (studs, a plat).
local function nearestBeam(here: Vector3): number
	local folder = workspace:FindFirstChild(Config.eye.beamsFolder)
	local best = math.huge
	if folder then
		for _, v in folder:GetAttributes() do
			if typeof(v) == "Vector3" then
				best = math.min(best, Vector3.new(v.X - here.X, 0, v.Z - here.Z).Magnitude)
			end
		end
	end
	return best
end

function SoundView.start()
	local player = Players.LocalPlayer
	local all: { Instance } = {}
	for name, entry in S.library do
		local sound = Instance.new("Sound")
		sound.Name = "Royale_" .. name
		sound.SoundId = "rbxassetid://" .. entry.id
		sound.Volume = entry.volume
		sound.Looped = entry.looped == true
		sound.Parent = SoundService
		sounds[name] = sound
		table.insert(all, sound)
	end
	task.spawn(function()
		ContentProvider:PreloadAsync(all)
		for name, sound in sounds do
			if not sound.IsLoaded then
				warn("[Royale] Son qui ne se charge pas : " .. name .. " (" .. sound.SoundId .. ")")
			end
		end
	end)

	-- L'AMBIANCE : le vent, ou le coeur au Ventre.
	local function ambience()
		local belly = player:GetAttribute(Config.goulag.stateAttribute) ~= nil
		fadeTo("vent", if belly then 0 else S.library.vent.volume)
		fadeTo("coeur", if belly then S.library.coeur.volume else 0)
	end
	ambience()
	player:GetAttributeChangedSignal(Config.goulag.stateAttribute):Connect(ambience)

	-- L'OEIL : le ciel qui rougit, les paupieres.
	workspace:GetAttributeChangedSignal(Config.eye.warningAttribute):Connect(function()
		if workspace:GetAttribute(Config.eye.warningAttribute) == true then
			play("signal")
			fadeTo("menace", S.library.menace.volume)
		end
	end)
	workspace:GetAttributeChangedSignal(Config.match.eyeOpenAttribute):Connect(function()
		local open = workspace:GetAttribute(Config.match.eyeOpenAttribute) == true
		local lids = sounds.ouverture
		fadeTo("menace", 0)
		if lids then
			lids.PlaybackSpeed = if open then 1 else S.closingSpeed
		end
		play("ouverture")
		if open then
			local regard = sounds.regard
			if regard and not regard.IsPlaying then
				regard.Volume = 0
				regard:Play()
			end
		else
			fadeTo("regard", 0)
		end
	end)

	-- Son regard bourdonne d'autant plus fort qu'un faisceau est pres.
	RunService.RenderStepped:Connect(function()
		local regard = sounds.regard
		if regard == nil or not regard.IsPlaying then
			return
		end
		local here = workspace.CurrentCamera.CFrame.Position
		local near = math.clamp(1 - nearestBeam(here) / S.gazeHeardStuds, 0, 1)
		regard.Volume = S.library.regard.volume * near * near
	end)

	-- Il te voit : un murmure, une fois par regard (pas a chaque image).
	local seen = false
	player:GetAttributeChangedSignal(Config.eye.exposureAttribute):Connect(function()
		local level = player:GetAttribute(Config.eye.exposureAttribute)
		local now = typeof(level) == "number" and level > S.murmurAbove
		if now and not seen then
			play("murmure")
		end
		seen = now
	end)
end

return SoundView
