--!strict
--[[
	Les Repris avec les vrais reglages : combien l'Oeil en recrache, le
	plafond qui tient sur une partie entiere, jamais plus de 2 sur un joueur,
	et les garde-fous de Josh (lents, fragiles, ils previennent).
]]

local Config = require("../../src/shared/Config")
local Horde = require("../../src/shared/Horde")

local harness = require("../harness")

return function(t: harness.Harness)
	local R = Config.repris
	local K = R.kinds

	t.section("Combien il en recrache")
	t.equal("24 en vie au Regard 1 : 3", Horde.spawnCount(24, 0, R.perPlayers[1], R.capRatio), 3)
	t.equal("6 en vie au Regard 5 : 2", Horde.spawnCount(6, 0, R.perPlayers[5], R.capRatio), 2)
	t.equal("personne en vie : aucun", Horde.spawnCount(0, 0, 3, R.capRatio), 0)
	t.equal("plafond atteint : aucun", Horde.spawnCount(10, 5, 3, R.capRatio), 0)
	t.equal("de 1 pour 8 a 1 pour 3 (CONCEPT.md)", R.perPlayers[1] * 10 + R.perPlayers[5], 83)

	t.section("Le plafond sur une partie")
	-- Une partie simulee : a chaque fermeture il en recrache, a chaque
	-- Regard il en re-aspire la moitie, et des joueurs sont aspires.
	-- Des aspirations peuvent faire passer le rapport au-dessus du plafond ;
	-- ce qui compte, c'est qu'une chute ne le depasse jamais.
	local alive, living, broken = 24, 0, 0
	for regard = 1, 5 do
		living -= Horde.reaspire(living, R.reaspireFraction)
		for _ = 1, 6 do
			local spawned = Horde.spawnCount(alive, living, R.perPlayers[regard], R.capRatio)
			living += spawned
			if spawned > 0 and living > Horde.cap(alive, R.capRatio) then
				broken += 1
			end
			alive = math.max(2, alive - 1)
		end
	end
	t.equal("une chute ne depasse jamais 1 Repris pour 2 joueurs", broken, 0)
	t.equal("la moitie re-aspiree", Horde.reaspire(7, R.reaspireFraction), 3)

	t.section("Qui ils visent")
	local seen = {
		{ id = "a", distance = 10, visible = true },
		{ id = "b", distance = 20, visible = true },
		{ id = "c", distance = 5, visible = false },
	}
	t.equal("le plus proche qu'il voit", Horde.pickTarget(seen, 60, {}, 2, nil), "a")
	t.equal("pas celui que 2 suivent deja", Horde.pickTarget(seen, 60, { a = 2 }, 2, nil), "b")
	t.equal("il garde sa cible", Horde.pickTarget(seen, 60, { b = 2 }, 2, "b"), "b")
	t.equal("personne a portee", Horde.pickTarget(seen, 8, {}, 2, nil), nil)
	t.equal("au plus 2 par joueur (CONCEPT.md)", R.maxPerTarget, 2)
	local crouched = Horde.sightRange(60, 4, R.slowSpeed, R.slowSightFactor)
	t.check("accroupi, il se remarque moins", crouched < 60)
	t.check("en courant, non", Horde.sightRange(60, 22, R.slowSpeed, R.slowSightFactor) == 60)
	t.equal("les caches pesent plus a la chute", Horde.pickWeighted({ 1, 3 }, 0.5), 2)

	t.section("Les sortes et leurs arrivees")
	local r1 = Horde.kindsAt(K, 1)
	local r3 = Horde.kindsAt(K, 3)
	t.check("Regard 1 : Errant et Rampant", #r1 == 2 and table.find(r1, "wanderer") ~= nil)
	t.check("Regard 3 : les quatre", #r3 == 4)
	t.check(
		"un tirage tombe toujours sur une sorte arrivee",
		Horde.pickKind(K, 1, 0.99) ~= "runner"
	)

	t.section("Les garde-fous (Josh : il faut que ca reste jouable)")
	local walk = Config.movement.walkSpeed
	t.check("l'Errant va moins vite que la marche", K.wanderer.speed < walk)
	t.check("le Rampant aussi", K.crawler.speed < walk)
	t.check("on echappe au Coureur en courant", K.runner.speed < Config.movement.runSpeed)
	t.equal("le Coureur tombe en 2 coups", K.runner.hits, 2)
	t.check("il grogne avant de plaquer, le temps d'une glissade", K.runner.tackle.windup >= 0.5)
	t.check(
		"son plaquage met K.O. 2 a 3 s (CONCEPT.md)",
		K.runner.tackle.fall >= 2 and K.runner.tackle.fall <= 3
	)
	t.check(
		"un delai entre deux cris",
		K.wanderer.cry.cooldown >= 5 and K.howler.howl.cooldown >= 5
	)
	t.check("le Rampant sent a 14 studs (CONCEPT.md)", K.crawler.smell == 14)
end
