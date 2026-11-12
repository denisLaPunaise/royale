--!strict
--[[
	La boutique avec les vrais reglages : la boutique du jour, les tirages
	(les regles de Roblox : tout affiche, chances egales, total 100 %, chaque
	tirage donne quelque chose, prix a la valeur moyenne), le passe.
]]

local Config = require("../../src/shared/Config")
local Shop = require("../../src/shared/Shop")

local harness = require("../harness")

return function(t: harness.Harness)
	local CO = Config.cosmetics
	local SH = Config.shop
	local PA = Config.pass
	local items = CO.items

	t.section("Le catalogue")
	local count = 0
	local slotsOk, pricesOk = true, true
	for _, def in items do
		count += 1
		if not table.find(CO.slots, def.slot) then
			slotsOk = false
		end
		if CO.prices[def.rarity] == nil then
			pricesOk = false
		end
	end
	t.check("au moins 15 cosmetiques", count >= 15)
	t.check("chacun a un emplacement connu", slotsOk)
	t.check("chacun a un prix (par sa rarete)", pricesOk)
	for _, id in SH.permanent do
		t.check("permanent existe : " .. id, items[id] ~= nil)
	end

	t.section("La boutique du jour")
	local d1 = Shop.daily(items, SH.permanent, 20000, SH.daily)
	local d1b = Shop.daily(items, SH.permanent, 20000, SH.daily)
	local d2 = Shop.daily(items, SH.permanent, 20001, SH.daily)
	t.equal("le bon nombre d'objets", #d1, SH.daily)
	t.check(
		"le meme jour, la meme boutique partout",
		table.concat(d1, ",") == table.concat(d1b, ",")
	)
	t.check("le lendemain, elle change", table.concat(d1, ",") ~= table.concat(d2, ","))
	local clash = false
	for _, id in d1 do
		if table.find(SH.permanent, id) then
			clash = true
		end
	end
	t.check("jamais un permanent dans la boutique du jour", not clash)

	t.section("Les tirages (regles de Roblox)")
	local chances = Shop.chances(SH.drawPool)
	local total, first, equal = 0, nil, true
	for _, c in chances do
		total += c
		first = first or c
		if math.abs(c - (first :: number)) > 1e-9 then
			equal = false
		end
	end
	t.check("le total des chances fait 100 %", math.abs(total - 1) < 1e-9)
	t.check("toutes les chances sont egales (Josh)", equal)
	local all = true
	for _, id in SH.drawPool do
		if items[id] == nil then
			all = false
		end
	end
	t.check("chaque resultat possible existe", all)
	local seen: { [string]: boolean } = {}
	for k = 0, 99 do
		seen[Shop.draw(SH.drawPool, k / 100)] = true
	end
	local reached = 0
	for _ in seen do
		reached += 1
	end
	t.equal(
		"chaque tirage donne un objet de la selection, tous atteignables",
		reached,
		#SH.drawPool
	)
	t.check("meme a u = 1", Shop.draw(SH.drawPool, 1) ~= nil)
	local price = Shop.drawPrice(items, CO.prices, SH.drawPool)
	local sum = 0
	for _, id in SH.drawPool do
		sum += Shop.price(items, CO.prices, id)
	end
	t.check(
		"le prix d'un tirage est la valeur moyenne de la selection",
		price == math.ceil(sum / #SH.drawPool)
	)
	t.check("un doublon rend quelque chose", SH.duplicateRefund > 0 and SH.duplicateRefund < 1)

	t.section("Le passe")
	t.equal("au depart, palier 0", Shop.tier(0, PA.tierXp, PA.tiers), 0)
	t.equal("jamais au-dela du dernier palier", Shop.tier(10 ^ 9, PA.tierXp, PA.tiers), PA.tiers)
	local free = Shop.passRewards(PA.free, 0, PA.tiers)
	t.check("la piste gratuite donne quelque chose", #free > 0)
	local okItems = true
	for _, track in { PA.free, PA.premium } do
		for _, reward in track do
			if reward.item and items[reward.item] == nil then
				okItems = false
			end
		end
	end
	t.check("chaque recompense du passe existe", okItems)
	t.check(
		"passer deux paliers d'un coup donne les deux",
		#Shop.passRewards({ [1] = {}, [2] = {} }, 0, 2) == 2
	)
	local perMatch = Config.progression.xp.played + Config.progression.xp.perRegard * 3
	t.check(
		"le passe se finit en une saison (moins de 200 parties moyennes)",
		PA.tiers * PA.tierXp / perMatch < 200
	)
	t.check("le bonus du premium reste petit", PA.premiumXpBonus <= 0.25)
end
