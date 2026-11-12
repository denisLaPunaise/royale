--!strict
--[[
	Le corps a corps avec les vrais reglages : combien de coups mettent K.O.,
	qui un coup touche, et qu'aucune chute ne raccourcit un K.O.
]]

local Config = require("../../src/shared/Config")
local Melee = require("../../src/shared/Melee")

local harness = require("../harness")

return function(t: harness.Harness)
	local C = Config.combat

	t.section("Les coups")
	local s = Melee.new()
	local ko = false
	for k = 1, C.hitsToKO do
		s, ko = Melee.hit(s, k * C.hitCooldown, C)
		t.check(string.format("coup %d : K.O. seulement au dernier", k), ko == (k == C.hitsToKO))
	end
	local koAt = C.hitsToKO * C.hitCooldown
	t.check("K.O. : au sol", Melee.isDown(s, koAt + 0.1) and s.knockedOut)
	t.check("et releve apres koSeconds", not Melee.isDown(s, koAt + C.koSeconds + 0.01))
	t.check("le K.O. dure 2 a 3 s (CONCEPT.md)", C.koSeconds >= 2 and C.koSeconds <= 3)
	local slow = Melee.new()
	for k = 1, C.hitsToKO do
		slow, ko = Melee.hit(slow, k * (C.comboResetSeconds + 1), C)
	end
	t.check("des coups trop espaces ne mettent jamais K.O.", not ko)
	t.check(
		"trois coups prennent le temps de fuir (au moins 1 s)",
		(C.hitsToKO - 1) * C.hitCooldown >= 1
	)

	t.section("Les chutes")
	local fallen = Melee.fall(s, koAt + 0.1, 0.5)
	t.check(
		"une chute courte ne raccourcit pas un K.O.",
		fallen.downUntil >= koAt + C.koSeconds - 1e-9 and fallen.knockedOut
	)
	local tackled = Melee.fall(Melee.new(), 0, C.tackleTargetFall)
	t.check("plaque : au sol, sans etre K.O.", Melee.isDown(tackled, 1) and not tackled.knockedOut)
	t.check(
		"le plaque tombe plus longtemps que celui qui plaque",
		C.tackleTargetFall > C.tackleSelfFall
	)

	t.section("Porter")
	local carried = s
	local lifted = koAt + 0.5
	local now = lifted
	while Melee.isDown(carried, now + C.stepSeconds) and now < lifted + 60 do
		carried = Melee.holdDown(carried, now, lifted, C.carryMaxSeconds, C.carryRefresh)
		now += C.stepSeconds
	end
	t.check(
		"porte, le K.O. dure jusqu'a la limite, pas plus",
		math.abs(now - (lifted + C.carryMaxSeconds)) <= C.carryRefresh + C.stepSeconds
	)
	t.check("le service prolonge plus vite qu'il ne tourne", C.carryRefresh > C.stepSeconds)
	t.check("on porte moins vite qu'on ne marche", C.carrySpeed < Config.movement.walkSpeed)

	t.section("Qui un coup touche")
	local from = { x = 0, y = 0, z = 0 }
	local look = { x = 0, z = -1 }
	local list = {
		{ id = "devant", x = 0, y = 0, z = -4 },
		{ id = "loin", x = 0, y = 0, z = -20 },
		{ id = "derriere", x = 0, y = 0, z = 2 },
	}
	t.equal(
		"le plus proche devant",
		Melee.pickTarget(from, look, list, C.hitRange, C.hitCone),
		"devant"
	)
	t.equal(
		"personne derriere",
		Melee.pickTarget(from, look, { list[3] }, C.hitRange, C.hitCone),
		nil
	)
	t.equal(
		"personne hors de portee",
		Melee.pickTarget(from, look, { list[2] }, C.hitRange, C.hitCone),
		nil
	)
	t.equal(
		"un peu de cote, on touche quand meme (manette)",
		Melee.pickTarget(
			from,
			look,
			{ { id = "cote", x = 2.5, y = 0, z = -3 } },
			C.hitRange,
			C.hitCone
		),
		"cote"
	)

	t.section("Le corps")
	local Mv = Config.movement
	t.check(
		"courir pour le jeu : entre la marche et la course",
		Mv.runningAbove > Mv.walkSpeed and Mv.runningAbove < Mv.runSpeed
	)
	t.check("la glissade part plus vite que la course", Mv.slideSpeed > Mv.runSpeed)
	t.check(
		"porter interdit de courir (pas de plaquage en portant)",
		C.carrySpeed < Mv.runningAbove
	)
end
