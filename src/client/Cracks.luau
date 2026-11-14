--!strict
--[[
	Cracks — la lueur qui court dans les fissures du ciel, du trou vers le
	dehors (la recette les marque : attributs Branche et Rang). Partage par
	le ciel de la carte (SkyView) et celui du salon (LobbyScene).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Cracks = {}

local P = Config.view.crackPulse

type Ember = { part: BasePart, rank: number, offset: number }

-- Rend une fonction a appeler a chaque image, avec l'heure.
function Cracks.track(sky: Instance): (now: number) -> ()
	local embers: { Ember } = {}
	for _, d in sky:GetDescendants() do
		local branch, rank = d:GetAttribute("Branche"), d:GetAttribute("Rang")
		if d:IsA("BasePart") and typeof(branch) == "number" and typeof(rank) == "number" then
			-- Chaque branche a son propre rythme : toutes ensemble, elles
			-- battaient comme un seul neon.
			table.insert(embers, { part = d, rank = rank, offset = branch * P.branchOffset })
		end
	end
	return function(now: number)
		for _, e in embers do
			local wave = math.sin(now * P.speed - e.rank * P.rankStep + e.offset)
			-- 0 : la braise pleine ; vers 1 : elle s'eteint presque.
			e.part.LocalTransparencyModifier = P.depth * (1 - (wave + 1) / 2)
		end
	end
end

return Cracks
