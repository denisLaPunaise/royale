--!strict
--[[
	La progression avec les vrais reglages : ce qu'une partie rapporte, les
	fragments de la fiche, les niveaux, et un profil lu qui garde tout.
]]

local Config = require("../../src/shared/Config")
local Progression = require("../../src/shared/Progression")

local harness = require("../harness")

return function(t: harness.Harness)
	local P = Config.progression
	local bet = Config.bets.rewardCredits
	local function r(regard: number, won: boolean, place: number?, betWon: boolean)
		return Progression.reward(
			{ regard = regard, won = won, place = place, betWon = betWon },
			P,
			bet
		)
	end

	t.section("Ce qu'une partie rapporte")
	local lost = r(1, false, 9, false)
	local won = r(5, true, 1, false)
	t.check(
		"perdre au Regard 1 rapporte un peu",
		lost.xp > 0 and lost.credits > 0 and lost.fragments == 0
	)
	t.check("gagner rapporte bien plus", won.xp > lost.xp * 3 and won.credits > lost.credits * 3)
	t.equal("top 1 : 2 fragments (CONCEPT.md)", won.fragments, 2)
	t.equal("top 3 : 1 fragment", r(4, false, 3, false).fragments, 1)
	t.equal("top 6 : rien", r(4, false, 6, false).fragments, 0)
	t.equal("10 victoires pour un tirage (CONCEPT.md)", P.fragments.perDraw / P.fragments.first, 10)
	t.check("un pari juste rapporte un peu", r(1, false, 9, true).credits - lost.credits == bet)
	t.check("parier ne rapporte jamais plus qu'une victoire", bet < P.credits.win)

	t.section("Les niveaux")
	local l1, into1, need1 = Progression.level(0, P.levelBase, P.levelStep)
	t.check("au depart : niveau 1", l1 == 1 and into1 == 0 and need1 == P.levelBase)
	t.equal("assez d'XP : niveau 2", (Progression.level(P.levelBase, P.levelBase, P.levelStep)), 2)
	local l3, _, need3 = Progression.level(P.levelBase * 2 + P.levelStep, P.levelBase, P.levelStep)
	t.check("chaque niveau coute un peu plus", l3 == 3 and need3 == P.levelBase + 2 * P.levelStep)
	local games = math.ceil((P.levelBase + P.levelBase + P.levelStep) / lost.xp)
	t.check("le niveau 3 en une dizaine de parties perdues", games <= 12)

	t.section("Le profil")
	local fresh = Progression.fill(nil, P.version)
	t.check(
		"un profil neuf part de zero",
		fresh.xp == 0 and fresh.credits == 0 and fresh.version == P.version
	)
	local old = Progression.fill({ xp = 500, credits = 70, owned = { a = true } }, P.version)
	t.check(
		"un ancien profil garde ce qu'il a",
		old.xp == 500 and old.credits == 70 and old.owned.a == true
	)
	t.check("et gagne les champs nouveaux", typeof(old.pass) == "table" and old.fragments == 0)
end
