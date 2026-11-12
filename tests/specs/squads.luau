--!strict
--[[
	Les escouades avec les vrais reglages : les equipes (les vrais joueurs
	ensemble, les bots completent), la fin de partie par equipe, et le cocon.
]]

local Config = require("../../src/shared/Config")
local Squads = require("../../src/shared/Squads")

local harness = require("../harness")

return function(t: harness.Harness)
	local SQ = Config.squads

	t.section("Les equipes")
	local map = Squads.assign(4, { "josh", "ami1", "ami2" }, { "b1", "b2", "b3", "b4", "b5" })
	t.check("trois amis ensemble", map.josh == 1 and map.ami1 == 1 and map.ami2 == 1)
	t.check("un bot complete leur equipe", map.b1 == 1)
	t.check("les autres bots forment l'equipe suivante", map.b2 == 2 and map.b5 == 2)
	local solo = Squads.assign(1, { "a" }, { "b", "c" })
	t.check("en solo, chacun son equipe", solo.a == 1 and solo.b == 2 and solo.c == 3)
	t.equal(
		"les tailles de la fiche",
		SQ.sizes.solo * 100 + SQ.sizes.duo * 10 + SQ.sizes.squad,
		124
	)
	t.check("le mode joue existe", SQ.sizes[SQ.mode] ~= nil)
	for mode, size in SQ.sizes do
		t.check(
			"le maximum de participants fait des equipes pleines en " .. mode,
			Config.bots.totalMax % size == 0
		)
	end

	t.section("La fin de partie")
	t.check("deux equipes en vie : on continue", not Squads.over({ 1, 1, 2 }, 6))
	t.check("une seule equipe en vie : elle gagne", Squads.over({ 3, 3 }, 6))
	t.check("une partie d'une seule equipe va jusqu'au bout", not Squads.over({ 1 }, 1))
	t.check("personne : fini", Squads.over({}, 6))

	t.section("Le cocon")
	t.equal("3 coups pour l'ouvrir (CONCEPT.md)", SQ.cocoon.hits, 3)
	t.check("l'Oeil le trouve apres environ 8 s (propose)", SQ.cocoon.eyeDelay == 8)
	t.check(
		"on a le temps de l'ouvrir avant (3 coups bien avant 8 s)",
		SQ.cocoon.hits * Config.combat.hitCooldown < SQ.cocoon.eyeDelay
	)
end
