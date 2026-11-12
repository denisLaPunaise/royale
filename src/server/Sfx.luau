--!strict
--[[
	Sfx — les sons poses dans le monde, que chacun entend d'ou il est : un
	coup, une fouille, une aspiration, un Repris (repris de Survivor).

	Un son qui ne charge pas echoue en silence chez Roblox : on le nomme une
	fois dans la console. Il se nettoie quand il a fini (`Ended` : sa duree
	vaut 0 tant qu'il n'est pas charge).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Sfx = {}

local S = Config.sounds
local warned: { [string]: boolean } = {}

local function make(name: string, parent: Instance): Sound?
	local entry = S.library[name]
	if entry == nil then
		if not warned[name] then
			warned[name] = true
			warn("[Royale] Son inconnu : " .. name)
		end
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = "Son_" .. name
	sound.SoundId = "rbxassetid://" .. entry.id
	sound.Volume = entry.volume
	sound.Looped = entry.looped == true
	sound.RollOffMinDistance = S.rollOffMin
	sound.RollOffMaxDistance = S.rollOffMax
	sound.Parent = parent
	return sound
end

-- Joue `name` a cet endroit (une part, ou une position).
function Sfx.at(name: string, where: BasePart | Vector3)
	local holder: Instance
	local temporary: Part? = nil
	if typeof(where) == "Vector3" then
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.one
		p.Position = where
		p.Parent = workspace
		holder, temporary = p, p
	else
		holder = where
	end
	local sound = make(name, holder)
	if sound == nil then
		if temporary then
			temporary:Destroy()
		end
		return
	end
	sound.Ended:Connect(function()
		sound:Destroy()
		if temporary then
			temporary:Destroy()
		end
	end)
	sound:Play()
end

-- Un son en boucle accroche a une part (les pas d'un Repris) ; rend le Sound.
function Sfx.loop(name: string, part: BasePart, near: number, far: number): Sound?
	local sound = make(name, part)
	if sound then
		sound.RollOffMinDistance = near
		sound.RollOffMaxDistance = far
	end
	return sound
end

return Sfx
