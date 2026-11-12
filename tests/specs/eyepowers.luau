--!strict
--[[
	Les pouvoirs de l'Oeil avec les vrais reglages : le tirage (jamais deux
	fois, jamais inutile), que chacun change vraiment le Regard ou il tombe, et
	les bornes d'equilibrage (on peut toujours fouiller pendant une pause, le
	vent pousse sans renverser).
]]

local Config = require("../../src/shared/Config")
local EyePowers = require("../../src/shared/EyePowers")
local Regards = require("../../src/shared/Regards")

local harness = require("../harness")

-- Un generateur reproductible (les tests choisissent leurs hasards).
local function lcg(seed: number): () -> number
	local state = seed
	return function()
		state = (state * 1103515245 + 12345) % 2147483648
		return state / 2147483648
	end
end

-- Deux Regards different-ils ? (les tables, comme les faux departs, par
-- leur contenu)
local function differs(a: any, b: any): boolean
	for k, v in a do
		local w = b[k]
		if type(v) == "table" and type(w) == "table" then
			if differs(v, w) or differs(w, v) then
				return true
			end
		elseif v ~= w then
			return true
		end
	end
	for k in b do
		if a[k] == nil then
			return true
		end
	end
	return false
end

return function(t: harness.Harness)
	local P = Config.eyePowers
	local L = P.list
	local R = Config.regards
	local ids = EyePowers.ids(L)

	t.section("Le catalogue")
	t.equal("14 pouvoirs (CONCEPT.md)", #ids, 14)
	for _, id in ids do
		t.check(
			id .. " : un nom et une phrase",
			type(L[id].name) == "string" and type(L[id].text) == "string"
		)
	end

	t.section("Le tirage")
	local repeats, missing = 0, 0
	for seed = 1, 200 do
		local u = lcg(seed)
		local owned: { string } = {}
		for i = 1, #R do
			local id = EyePowers.draw(L, owned, R[i], u())
			if id == nil then
				missing += 1
			elseif table.find(owned, id) then
				repeats += 1
			else
				if not EyePowers.useful(id, R[i]) then
					missing += 1
				end
				table.insert(owned, id)
			end
		end
	end
	t.equal("200 parties : jamais deux fois le meme", repeats, 0)
	t.equal("un pouvoir utile a chaque Regard", missing, 0)
	t.check(
		"au Regard 5, « Il entend tout » ne se tire pas",
		not EyePowers.useful("hearAll", R[5])
	)
	t.check(
		"au Regard 5, ce qui joue sur les pauses non plus",
		not EyePowers.useful("heavyLid", R[5])
	)

	t.section("Chaque pouvoir change le Regard ou il tombe")
	for _, id in ids do
		local changed = true
		for i = 1, #R do
			if EyePowers.useful(id, R[i]) then
				local base = EyePowers.apply(R[i], {}, L, lcg(7))
				local with = EyePowers.apply(R[i], { id }, L, lcg(7))
				if not differs(base, with) then
					changed = false
				end
			end
		end
		t.check(id .. " change quelque chose", changed)
	end

	t.section("Les rythmes")
	local r1 = R[1]
	local lid = EyePowers.apply(r1, { "heavyLid" }, L, lcg(1))
	local _, leftLid = Regards.burst(lid, r1.openSeconds + 0.01)
	t.check(
		"paupiere lourde : la pause dure 2/3",
		math.abs(leftLid - r1.closedSeconds * 2 / 3) < 0.02
	)
	local long = EyePowers.apply(r1, { "longBurst" }, L, lcg(1))
	local n = long.longBurst
	t.check("regard long : une des premieres rafales", n >= 1 and n <= L.longBurst.among)
	local startN = (n - 1) * (r1.openSeconds + r1.closedSeconds)
	local openLong = Regards.burst(long, startN + r1.openSeconds * 1.5)
	local openAfter, _, index = Regards.burst(long, startN + r1.openSeconds * 2 + 0.5)
	t.check("regard long : encore ouvert a 1,5 fois la rafale", openLong)
	t.check("et ferme juste apres le double", not openAfter and index == n)
	local feint = EyePowers.apply(r1, { "feint" }, L, function()
		return 0
	end)
	local _, leftFeint = Regards.burst(feint, r1.openSeconds + 0.01)
	t.check(
		"faux depart : la pause marquee ne dure que quelques secondes",
		math.abs(leftFeint - L.feint.seconds) < 0.02
	)
	local rage = EyePowers.apply(R[3], { "rage" }, L, lcg(1))
	t.equal(
		"rage : une rafale sur deux, un de plus",
		Regards.beamCount(rage, 12, 2) - Regards.beamCount(rage, 12, 1),
		L.rage.beams
	)
	local hunger = EyePowers.apply(R[1], { "hunger" }, L, lcg(1))
	t.equal(
		"faim : moitie plus d'arrachages",
		hunger.ripsPerBurst,
		math.ceil(R[1].ripsPerBurst * 1.5)
	)
	local slow = EyePowers.apply(R[5], { "slowSure" }, L, lcg(1))
	t.check(
		"lent mais sur : au Regard 5, la course le distance",
		slow.chaseSpeed < Config.movement.runSpeed
	)
	t.check("et il garde la piste 2 s de plus", slow.memorySeconds == R[5].memorySeconds + 2)

	t.section("L'equilibrage")
	local shortest = math.huge
	for i = 1, #R do
		if R[i].closedSeconds > 0 then
			local all = EyePowers.apply(R[i], { "heavyLid", "feint" }, L, function()
				return 0
			end)
			shortest = math.min(shortest, all.closedSeconds, all.feintSeconds)
		end
	end
	t.check(
		"la plus courte pause laisse le temps d'une fouille",
		shortest >= Config.loot.searchSeconds
	)
	t.check("le souffle pousse moins qu'une poussee", L.wind.speed < Config.combat.shoveSpeed)
	local five = EyePowers.apply(
		R[4],
		{ "longBurst", "heavyLid", "feint", "rage", "hunger" },
		L,
		function()
			return 0
		end
	)
	local openTime, total = 0, 0
	local step = 0.5
	for tt = 0, R[4].seconds, step do
		total += step
		if Regards.burst(five, tt) then
			openTime += step
		end
	end
	t.check(
		"meme avec les pires pouvoirs, un Regard 4 garde des pauses (moins de 97 % ouvert)",
		openTime / total < 0.97
	)

	t.section("Le regard rasant")
	local eye = { x = 0, y = 400, z = 0 }
	local target = { x = 300, y = 0, z = 0 }
	local o = EyePowers.slantOrigin(target, eye, L.slant.elevation)
	local d = math.sqrt((o.x - target.x) ^ 2 + (o.y - target.y) ^ 2 + (o.z - target.z) ^ 2)
	t.check("meme distance que la pupille", math.abs(d - 500) < 0.01)
	local elev = math.deg(math.atan2(o.y - target.y, math.abs(o.x - target.x)))
	t.check("a la bonne hauteur sur l'horizon", math.abs(elev - L.slant.elevation) < 0.01)
	t.check("du cote de l'Oeil", o.x < target.x)
	local under = EyePowers.slantOrigin({ x = 0, y = 0, z = 0 }, eye, L.slant.elevation)
	t.check("sous l'Oeil : il arrive de l'est", under.x > 0)
	t.check("et plus bas que la pupille (il passe sous les avancees)", o.y < eye.y)
end
