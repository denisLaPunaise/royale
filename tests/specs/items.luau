--!strict
--[[
	Les objets avec les vrais reglages : les chances d'une fouille, le sac,
	le lancer, l'equilibrage (aucun sac de 4 ne rend intouchable) et chaque
	objet du catalogue vraiment traite par ItemService.
]]

local fs = require("@lune/fs")

local Bag = require("../../src/shared/Bag")
local Config = require("../../src/shared/Config")
local Loot = require("../../src/shared/Loot")
local Throw = require("../../src/shared/Throw")

local harness = require("../harness")

return function(t: harness.Harness)
	local I = Config.items
	local L = Config.loot

	t.section("Le catalogue")
	local count = 0
	for id, def in I do
		count += 1
		t.check(id .. " : rarete connue", Config.rarities[def.rarity] ~= nil)
		t.check(
			id .. " : sorte connue",
			def.kind == "throw" or def.kind == "use" or def.kind == "spot" or def.kind == "passive"
		)
		t.check(id .. " : a un nom", typeof(def.name) == "string" and def.name ~= "")
	end
	t.equal("28 objets au catalogue (CONCEPT.md)", count, 28)
	t.equal("4 legendaires", #Loot.ofRarity(I, "legendary"), 4)
	for _, rarity in Loot.searchable do
		t.check("des objets " .. rarity, #Loot.ofRarity(I, rarity) > 0)
	end
	-- Une regle que seuls les tests appellent ne s'applique pas : chaque objet
	-- doit avoir son effet dans le service.
	local service = fs.readFile("src/server/ItemService.luau")
	for id, def in I do
		if def.kind ~= "passive" then
			t.check(
				id .. " a son effet dans ItemService",
				string.find(service, '"' .. id .. '"', 1, true) ~= nil
			)
		end
	end

	t.section("La fouille")
	local chances = Loot.chances(L.weights)
	t.check("commun 56 %", math.abs(chances.common - 0.56) < 1e-9)
	t.check("epique 6 %", math.abs(chances.epic - 0.06) < 1e-9)
	local legendary = false
	for k = 0, 999 do
		local rarity = Loot.rollRarity(L.weights, k / 1000)
		if rarity == "legendary" then
			legendary = true
		end
	end
	t.check("une fouille ne donne jamais de legendaire", not legendary)
	t.equal("u = 0 : commun", Loot.rollRarity(L.weights, 0), "common")
	t.equal("u presque 1 : epique", Loot.rollRarity(L.weights, 0.9999), "epic")
	local danger = Loot.chances(Loot.weights(L.weights, true, L.dangerEpicFactor))
	t.check("le Cratere donne plus d'epiques", danger.epic > chances.epic)
	local seen: { [string]: boolean } = {}
	for k = 0, 99 do
		local id = Loot.pick(I, "common", k / 100)
		if id then
			seen[id] = true
		end
	end
	t.equal(
		"chaque commun peut sortir",
		#Loot.ofRarity(I, "common"),
		(function()
			local n = 0
			for _ in seen do
				n += 1
			end
			return n
		end)()
	)

	t.section("Le sac")
	local b = Bag.new(Config.bag.slots)
	for _, id in { "smoke", "bat", "net", "torch" } do
		b = (Bag.add(b, id, 1))
	end
	local full, slot, dropped = Bag.add(b, "mirror", 2)
	t.check("sac plein : le nouveau prend la place choisie", full[2] == "mirror" and slot == 2)
	t.equal("et l'ancien tombe", dropped, "bat")
	t.equal(
		"aller-retour par l'attribut",
		Bag.encode(Bag.decode(Bag.encode(full), 4)),
		Bag.encode(full)
	)
	local emptied, taken = Bag.take(full, 1)
	t.check("prendre vide la place", taken == "smoke" and emptied[1] == "")
	t.equal("R1 apres la 4e revient a la 1re", Bag.cycle(4, 1, 4), 1)
	t.equal("L1 avant la 1re va a la 4e", Bag.cycle(1, -1, 4), 4)
	t.equal("un sac vide se lit vide", #Bag.items(Bag.decode("", 4)), 0)

	t.section("Le lancer")
	local T = Config.throw
	local v = Throw.velocity({ x = 0, y = 0, z = -1 }, T.speed, T.lift)
	-- Lance a hauteur des yeux (4,5 studs) vers l'avant, jusqu'au sol.
	local tt = 0
	local p = Throw.at({ x = 0, y = 4.5, z = 0 }, v, T.gravity, 0)
	while p.y > 0 and tt < T.maxSeconds do
		tt += T.stepSeconds
		p = Throw.at({ x = 0, y = 4.5, z = 0 }, v, T.gravity, tt)
	end
	t.check(
		string.format("droit devant, il tombe a une rue (%.0f studs)", -p.z),
		-p.z > 25 and -p.z < 70
	)
	t.check("il retombe avant la fin de la recherche", tt < T.maxSeconds)
	t.check("l'arc monte d'abord", v.y > 0)

	t.section("L'equilibrage")
	-- Le meilleur sac de 4 qu'on puisse fouiller.
	local shields: { number } = {}
	for _, rarity in Loot.searchable do
		for _, id in Loot.ofRarity(I, rarity) do
			table.insert(shields, Loot.shield(I, { id }))
		end
	end
	table.sort(shields, function(a, b2)
		return a > b2
	end)
	local best = 0
	for k = 1, Config.bag.slots do
		best += shields[k] or 0
	end
	local shortest = math.huge
	local shortestOpen = math.huge
	for _, r in Config.regards do
		shortest = math.min(shortest, r.seconds)
		if r.closedSeconds > 0 then
			shortestOpen = math.min(shortestOpen, r.openSeconds)
		end
	end
	t.check(
		string.format(
			"le meilleur sac de 4 protege %d s, moins d'un quart du plus court Regard",
			best
		),
		best <= shortest / 4
	)
	for id, def in I do
		t.check(id .. " : aucun objet ne couvre toute une ouverture", def.shield < shortestOpen)
	end
	t.check(
		"l'adrenaline ne va jamais plus vite que l'Oeil au dernier Regard",
		Config.movement.runSpeed <= Config.regards[#Config.regards].chaseSpeed
	)
end
