--!strict
--[[
	Le coeur du jeu : les Regards, les cercles, la jauge, la mefiance et la
	poursuite des faisceaux, avec les vrais reglages de Config. On verifie ce
	que le jeu FAIT (combien de faisceaux a 24 joueurs, quand l'Oeil se ferme,
	ou tombe le cercle), pas qu'un chiffre est coherent avec un autre.
]]

local Circles = require("../../src/shared/Circles")
local Config = require("../../src/shared/Config")
local Exposure = require("../../src/shared/Exposure")
local Regards = require("../../src/shared/Regards")
local Suspicion = require("../../src/shared/Suspicion")
local Targeting = require("../../src/shared/Targeting")

local harness = require("../harness")

return function(t: harness.Harness)
	local R = Config.regards

	t.section("Les Regards")
	t.equal("5 Regards", #R, 5)
	t.equal("24 joueurs au Regard 1 : 3 faisceaux", Regards.beamCount(R[1], 24), 3)
	t.equal("5 joueurs au Regard 1 : 1 faisceau", Regards.beamCount(R[1], 5), 1)
	t.equal("8 joueurs au Regard 5 : 2 faisceaux", Regards.beamCount(R[5], 8), 2)
	t.equal("1 joueur : toujours au moins 1 faisceau", Regards.beamCount(R[5], 1), 1)
	local open0 = Regards.burst(R[1], 0)
	local open1, left1, n1 = Regards.burst(R[1], R[1].openSeconds + 1)
	local open2, _, n2 = Regards.burst(R[1], R[1].openSeconds + R[1].closedSeconds + 1)
	t.check("au debut d'un Regard, l'Oeil est ouvert", open0)
	t.check("apres son ouverture, il se ferme", not open1)
	t.check("le temps restant ferme est juste", math.abs(left1 - (R[1].closedSeconds - 1)) < 1e-6)
	t.check("puis il se rouvre, rafale 2", open2 and n2 == 2 and n1 == 1)
	t.check("au Regard 5, il ne se ferme jamais", (Regards.burst(R[5], 10000)))
	local durations = {}
	for _, r in R do
		table.insert(durations, r.seconds)
	end
	t.equal("a 0 s : Regard 1", (Regards.at(durations, 0)), 1)
	t.equal("juste apres le premier : Regard 2", (Regards.at(durations, R[1].seconds + 1)), 2)
	t.equal("bien apres la fin : on reste au Regard 5", (Regards.at(durations, 99999)), 5)
	-- Ce qui monte ne redescend pas (CONCEPT.md : le jeu ne devient jamais facile).
	for i = 2, #R do
		t.check(
			string.format("Regard %d : poursuite au moins aussi rapide", i),
			R[i].chaseSpeed >= R[i - 1].chaseSpeed
		)
		t.check(
			string.format("Regard %d : visee au moins aussi precise", i),
			R[i].aimError <= R[i - 1].aimError
		)
		t.check(
			string.format("Regard %d : aspire au moins aussi vite", i),
			R[i].fillSeconds <= R[i - 1].fillSeconds
		)
		t.check(
			string.format("Regard %d : mefiance au moins aussi rapide", i),
			R[i].suspicionSeconds <= R[i - 1].suspicionSeconds
		)
	end
	t.check("au Regard 1, la poursuite est plus lente que la marche (14)", R[1].chaseSpeed < 14)
	t.check("au Regard 5, elle egale la course (22)", R[5].chaseSpeed >= 22)
	-- La fin se fait par l'Oeil : au dernier Regard, plus aucun abri n'est sur.
	t.check("au dernier Regard, les cachettes solides s'effondrent", R[#R].solidFalls)
	t.check(
		"avant, jamais",
		not (R[1].solidFalls or R[2].solidFalls or R[3].solidFalls or R[4].solidFalls)
	)

	t.section("Les cercles")
	local Z = Config.zone
	local previous = 1600
	local alive = { 20, 14, 10, 6, 4 }
	for i, ref in Z.reference do
		local d = Circles.diameter(ref, alive[i], previous, Z.minDiameter)
		t.check(string.format("cercle %d : jamais plus grand que le precedent", i), d <= previous)
		previous = d
	end
	t.check(
		"a 20 joueurs, le premier cercle fait sa reference",
		math.abs(Circles.diameter(Z.reference[1], 20, 1600, Z.minDiameter) - 1300) < 1e-6
	)
	t.check(
		"a 5 joueurs, le premier cercle est bien plus petit",
		Circles.diameter(Z.reference[1], 5, 1600, Z.minDiameter) < 700
	)
	t.check(
		"jamais sous le minimum",
		Circles.diameter(Z.reference[5], 1, 1600, Z.minDiameter) >= Z.minDiameter
	)
	local current = { x = 0, z = 0, radius = 650 }
	local worst = 0
	for u = 0, 1, 0.25 do
		for v = 0, 1, 0.2 do
			local nextCircle = Circles.place(current, 450, Z.insideMargin, u, v)
			local d = math.sqrt(nextCircle.x ^ 2 + nextCircle.z ^ 2) + nextCircle.radius
			worst = math.max(worst, d)
		end
	end
	t.check("le prochain cercle reste entierement dans l'actuel", worst <= current.radius + 1e-6)
	t.check("un point au centre est dedans", Circles.contains(current, 0, 0))
	t.check("un point loin est dehors", not Circles.contains(current, 900, 0))

	t.section("La jauge")
	local level = 0
	for _ = 1, 20 do
		level = Exposure.step(
			level,
			1,
			0.1,
			{ fillSeconds = R[1].fillSeconds, drainSeconds = Config.eye.drainSeconds }
		)
	end
	t.check("2 s de plein regard au Regard 1 : aspire", Exposure.isTaken(level))
	local crossed = 0
	for _ = 1, 10 do
		crossed = Exposure.step(
			crossed,
			1,
			0.1,
			{ fillSeconds = R[1].fillSeconds, drainSeconds = Config.eye.drainSeconds }
		)
	end
	t.check("traverser 1 s ne suffit pas", not Exposure.isTaken(crossed))

	t.section("La mefiance")
	local S = Config.suspicion
	local state = Suspicion.new(0, 0)
	-- Un pas de plus : la somme de 900 pas de 0,1 s tombe juste sous 1.
	for _ = 1, R[1].suspicionSeconds * 10 + 1 do
		state = Suspicion.step(state, 1, 1, true, 0.1, R[1].suspicionSeconds, S)
	end
	t.check("cache sans bouger 90 s au Regard 1 : flaire", Suspicion.isFlagged(state))
	local moving = Suspicion.new(0, 0)
	for k = 1, 900 do
		moving = Suspicion.step(moving, k * 0.4, 0, true, 0.1, R[1].suspicionSeconds, S)
	end
	t.check("en changeant de place, on n'est jamais flaire", not Suspicion.isFlagged(moving))
	local exposed = Suspicion.new(0, 0)
	for _ = 1, 2000 do
		exposed = Suspicion.step(exposed, 0, 0, false, 0.1, R[1].suspicionSeconds, S)
	end
	t.check(
		"a decouvert, la mefiance ne monte pas (c'est l'Oeil qui s'en charge)",
		exposed.level == 0
	)

	t.section("La poursuite des faisceaux")
	local beams =
		{ { x = 0, z = 0, target = nil, memory = 0 }, { x = 100, z = 0, target = nil, memory = 0 } }
	local seen = { { id = "a", x = 10, z = 0 }, { id = "b", x = 90, z = 0 } }
	local out = Targeting.assign(beams, seen, 1, 0.1)
	t.equal("chaque faisceau prend le plus proche (1)", out[1].target, "a")
	t.equal("chaque faisceau prend le plus proche (2)", out[2].target, "b")
	local lost = Targeting.assign(out, { { id = "b", x = 90, z = 0 } }, 1, 0.5)
	t.equal("perdu de vue, il garde la piste un moment", lost[1].target, "a")
	local gone = Targeting.assign(lost, { { id = "b", x = 90, z = 0 } }, 1, 0.6)
	t.equal("sa memoire epuisee, il lache", gone[1].target, nil)
	local single = Targeting.assign(beams, { { id = "a", x = 10, z = 0 } }, 1, 0.1)
	t.check(
		"deux faisceaux ne poursuivent jamais le meme joueur",
		single[1].target ~= single[2].target
	)
	local sx = Targeting.chaseStep(0, 0, 100, 0, R[1].chaseSpeed, 1)
	t.check(
		"un faisceau avance a sa vitesse, sans se teleporter",
		math.abs(sx - R[1].chaseSpeed) < 1e-6
	)
end
