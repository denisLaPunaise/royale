--!strict
--[[
	Les paris des elimines avec les vrais reglages : qui peut parier, jamais
	sur un ami Roblox, et qui gagne son pari.
]]

local Config = require("../../src/shared/Config")
local Bets = require("../../src/shared/Bets")

local harness = require("../harness")

return function(t: harness.Harness)
	local BT = Config.bets
	local base = {
		regard = 2,
		untilRegard = BT.untilRegard,
		eliminated = true,
		already = false,
		targetAlive = true,
		friends = false,
	}
	local function with(change: { [string]: any }): any
		local c = table.clone(base)
		for k, v in change do
			c[k] = v
		end
		return c
	end

	t.section("Qui peut parier")
	t.check("un elimine, au Regard 2, sur un inconnu en vie", (Bets.allowed(base)))
	t.check("pas en jouant encore", not Bets.allowed(with({ eliminated = false })))
	t.check("une seule fois", not Bets.allowed(with({ already = true })))
	t.check("jamais sur un ami Roblox (CONCEPT.md)", not Bets.allowed(with({ friends = true })))
	t.check("pas sur quelqu'un d'aspire", not Bets.allowed(with({ targetAlive = false })))
	t.check("fermes aux derniers cercles", not Bets.allowed(with({ regard = BT.untilRegard })))
	local _, why = Bets.allowed(with({ friends = true }))
	t.check("un refus dit pourquoi", type(why) == "string")

	t.section("Qui gagne")
	local won = Bets.winners({ a = "x", b = "y", c = "x" }, { "x", "z" })
	t.check("ceux qui ont parie sur un gagnant", #won == 2 and won[1] == "a" and won[2] == "c")
	t.check(
		"un pari rapporte un peu, jamais beaucoup",
		BT.rewardCredits > 0 and BT.rewardCredits <= 25
	)
end
