--!strict
--[[
	Le goulag avec les vrais reglages : les paires (jamais deux coequipiers,
	l'impair contre le bot), l'effritement qui finit toujours par faire
	tomber quelqu'un, qui est sauve, et la fermeture aux deux derniers cercles.
]]

local Config = require("../../src/shared/Config")
local Duels = require("../../src/shared/Duels")

local harness = require("../harness")

return function(t: harness.Harness)
	local G = Config.goulag

	t.section("Les paires")
	local pairs, alone = Duels.pair({ "a", "b", "c", "d" }, {})
	t.check("4 au Ventre : 2 duels, personne contre le bot", #pairs == 2 and alone == nil)
	pairs, alone = Duels.pair({ "a", "b", "c" }, {})
	t.check("3 : un duel, et le dernier contre le bot", #pairs == 1 and alone == "c")
	pairs, alone = Duels.pair({ "a", "b", "c", "d" }, { a = "1", b = "1", c = "2", d = "2" })
	local mixed = true
	for _, p in pairs do
		if p[1]:sub(1, 1) ~= p[2]:sub(1, 1) then
			local ta = ({ a = "1", b = "1", c = "2", d = "2" })[p[1]]
			local tb = ({ a = "1", b = "1", c = "2", d = "2" })[p[2]]
			if ta == tb then
				mixed = false
			end
		end
	end
	t.check("jamais deux coequipiers dans le meme duel", mixed and #pairs == 2)
	pairs, alone = Duels.pair({ "a", "b" }, { a = "1", b = "1" })
	local waiting = Duels.waiting({ "a", "b" }, pairs, alone)
	t.check(
		"deux coequipiers seuls : l'un prend le bot, l'autre attend",
		#pairs == 0 and alone ~= nil and #waiting == 1
	)
	t.equal(
		"personne n'est oublie",
		#Duels.waiting({ "a", "b", "c" }, Duels.pair({ "a", "b", "c" }, {})),
		0
	)

	t.section("La plateforme")
	local r0 = Duels.radius(0, G)
	local rEnd, suddenAtEnd = Duels.radius(G.duelSeconds - 0.01, G)
	local rLast, sudden = Duels.radius(G.duelSeconds + G.suddenSeconds, G)
	t.equal("au depart, pleine taille", r0, G.platformRadius)
	t.check("elle s'effrite pendant le duel", rEnd < r0 and not suddenAtEnd)
	t.check("en mort subite, il n'en reste rien", rLast == 0 and sudden)
	t.check(
		"assez large pour deux au depart (ecart et coups)",
		G.platformRadius > G.startOffset + Config.combat.hitRange / 2
	)
	t.check(
		"une manche tient dans 45 s (decompte, duel, mort subite)",
		G.introSeconds + G.duelSeconds + G.suddenSeconds <= G.roundSeconds
	)

	t.section("Qui est sauve")
	t.equal("jete par son adversaire : l'autre est sauve", Duels.outcome(true, false), "saved")
	t.equal("tombe tout seul : personne n'est sauve", Duels.outcome(false, false), "waits")
	t.equal("en mort subite, un duel a toujours un gagnant", Duels.outcome(false, true), "saved")

	t.section("La fermeture")
	t.check("ouvert au Regard 3", Duels.open(3, G.closesAtRegard, false))
	t.check("ferme aux deux derniers cercles", not Duels.open(4, G.closesAtRegard, false))
	t.equal("les deux derniers des 5 Regards", #Config.regards - G.closesAtRegard + 1, 2)
	t.check("une seule fois par partie", not Duels.open(1, G.closesAtRegard, true))
	t.check(
		"le K.O. du Ventre dure 2 s (CONCEPT.md)",
		G.rules.koSeconds == 2 and G.rules.hitsToKO == 3
	)
end
