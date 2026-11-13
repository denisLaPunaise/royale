--!strict
--[[
	Les defis avec les vrais reglages : les memes pour tout le monde, qui
	changent chaque periode, un defi fini une seule fois, la semaine en plus
	long.
]]

local Challenges = require("../../src/shared/Challenges")
local Config = require("../../src/shared/Config")

local harness = require("../harness")

return function(t: harness.Harness)
	local CH = Config.challenges

	t.section("Le choix des defis")
	local a = Challenges.pick(CH.list, 20000, CH.daily, 0)
	local b = Challenges.pick(CH.list, 20000, CH.daily, 0)
	local c = Challenges.pick(CH.list, 20001, CH.daily, 0)
	t.equal("le bon nombre", #a, CH.daily)
	t.check("les memes pour tout le monde", table.concat(a, ",") == table.concat(b, ","))
	t.check("ils changent le lendemain", table.concat(a, ",") ~= table.concat(c, ","))
	local stats = {
		match = true,
		regard3 = true,
		win = true,
		search = true,
		knockout = true,
		repris = true,
		belly = true,
		cocoon = true,
	}
	local known = true
	for _, def in CH.list do
		if not stats[def.stat] then
			known = false
		end
	end
	t.check("chaque defi compte une chose que le jeu signale", known)

	t.section("L'avancement")
	local list = { s = { stat = "search", goal = 3 } }
	local track = Challenges.reset(nil, 1)
	t.equal("pas encore fini", #Challenges.record(track, { "s" }, list, "search", 2, 1), 0)
	t.equal("fini a 3", #Challenges.record(track, { "s" }, list, "search", 1, 1), 1)
	t.equal("jamais deux fois", #Challenges.record(track, { "s" }, list, "search", 5, 1), 0)
	t.equal(
		"une autre chose ne compte pas",
		#Challenges.record(Challenges.reset(nil, 1), { "s" }, list, "match", 9, 1),
		0
	)
	local weekly = Challenges.reset(nil, 1)
	Challenges.record(weekly, { "s" }, list, "search", 3, CH.weeklyFactor)
	t.check("la semaine demande plus", weekly.done.s ~= true)
	t.check("une nouvelle periode repart de zero", next(Challenges.reset(track, 2).done) == nil)
end
