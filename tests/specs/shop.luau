--!strict
--[[
	La boutique avec les vrais reglages : la boutique du jour, les tirages
	(les regles de Roblox : tout affiche, total 100 %, chaque tirage donne
	quelque chose, prix a la valeur moyenne), le passe.
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
	t.check("chacun a un emplacement connu", slotsOk)
	t.check("chacun a un prix (par sa rarete)", pricesOk)
	for _, id in SH.permanent do
		t.check("permanent existe : " .. id, items[id] ~= nil and not items[id].pass)
	end
	-- Le tirage : 15 objets par emplacement, 6 communs, 5 rares, 3 epiques,
	-- 1 legendaire (choisi avec Josh le 14 novembre 2026).
	local pool = Shop.drawPool(items)
	local wanted = { common = 6, rare = 5, epic = 3, legendary = 1 }
	for _, slot in CO.slots do
		local bySlot: { [string]: number } = {}
		for _, id in pool do
			if items[id].slot == slot then
				bySlot[items[id].rarity] = (bySlot[items[id].rarity] or 0) + 1
			end
		end
		for rarity, n in wanted do
			t.equal(string.format("%s : %d %s", slot, n, rarity), bySlot[rarity] or 0, n)
		end
	end
	-- Chaque apparence a de quoi se montrer.
	local shown = true
	for id, def in items do
		local ok = if def.slot == "emote"
			then typeof(def.anim) == "number"
			elseif def.slot == "title" then typeof(def.title) == "string"
			elseif def.slot == "bat" then CO.batStyles[def.style] ~= nil
				and def.a ~= nil
				and def.b ~= nil
			else CO.styles[def.slot][def.style] ~= nil and def.a ~= nil and def.b ~= nil
		if not ok then
			shown = false
			print("   sans effet : " .. id)
		end
	end
	t.check("chaque apparence a son style, ses couleurs, son animation ou son texte", shown)
	local textures = true
	for slot, styles in CO.styles do
		for _, style in styles do
			for _, layer in (if slot == "cocoon" then style.particles else style) do
				if CO.textures[layer.tex] == nil then
					textures = false
				end
			end
		end
	end
	for _, style in CO.batStyles do
		for _, layer in style.particles or {} do
			if CO.textures[layer.tex] == nil then
				textures = false
			end
		end
	end
	for _, list in CO.tierLayers do
		for _, layer in list do
			if CO.textures[layer.tex] == nil then
				textures = false
			end
		end
	end
	t.check("chaque couche de particules a une texture connue", textures)
	-- Chaque legendaire visible (comete, trainee, cocon, aspiration) a son
	-- effet signature, et chaque signature existe (choisi avec Josh).
	local signed = true
	for id, def in items do
		local visible = def.slot ~= "emote" and def.slot ~= "title"
		if visible and def.rarity == "legendary" and def.signature == nil then
			signed = false
			print("   legendaire sans signature : " .. id)
		end
		if def.signature and CO.signatures[def.signature] == nil then
			signed = false
			print("   signature inconnue : " .. id)
		end
	end
	t.check("chaque legendaire visible a son effet signature", signed)

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
	local clash, passSold = false, false
	for day = 20000, 20060 do
		for _, id in Shop.daily(items, SH.permanent, day, SH.daily) do
			if table.find(SH.permanent, id) then
				clash = true
			end
			if items[id].pass then
				passSold = true
			end
		end
	end
	t.check("jamais un permanent dans la boutique du jour", not clash)
	t.check("jamais un objet du passe en boutique (deux mois de boutiques)", not passSold)

	t.section("Les tirages (regles de Roblox)")
	local chances = Shop.chances(items, pool, SH.drawWeights)
	local total = 0
	local byRarity: { [string]: number } = {}
	for id, c in chances do
		total += c
		byRarity[items[id].rarity] = (byRarity[items[id].rarity] or 0) + c
		if items[id].pass then
			t.check("un objet du passe ne tombe jamais d'un tirage : " .. id, false)
		end
	end
	t.check("le total des chances fait 100 %", math.abs(total - 1) < 1e-9)
	for rarity, w in SH.drawWeights do
		t.check(
			string.format("%s : %d %% du total", rarity, w),
			math.abs((byRarity[rarity] or 0) - w / 100) < 1e-9
		)
	end
	-- Chaque objet est atteignable : on balaie u assez finement.
	local seen: { [string]: boolean } = {}
	for k = 0, 99999 do
		seen[Shop.draw(items, pool, SH.drawWeights, k / 100000)] = true
	end
	local reached = 0
	for _ in seen do
		reached += 1
	end
	t.equal("chaque tirage donne un objet du tirage, tous atteignables", reached, #pool)
	t.check("meme a u = 1", Shop.draw(items, pool, SH.drawWeights, 1) ~= nil)
	local price = Shop.drawPrice(items, CO.prices, pool, SH.drawWeights)
	local expected = 0
	for _, id in pool do
		expected += chances[id] * Shop.price(items, CO.prices, id)
	end
	t.check("le prix d'un tirage est sa valeur moyenne", price == math.ceil(expected))
	t.check("un doublon rend quelque chose", SH.duplicateRefund > 0 and SH.duplicateRefund < 1)

	t.section("Le passe")
	-- La premium : un objet a chaque palier, tous propres au passe ; la
	-- gratuite : un objet tous les 3 a 5 paliers (choisi avec Josh).
	local premiumAll, unique = true, true
	local used: { [string]: boolean } = {}
	for tier = 1, PA.tiers do
		local reward = PA.premium[tier]
		if reward == nil or reward.item == nil then
			premiumAll = false
		end
	end
	local gap, last = 0, 0
	for tier = 1, PA.tiers do
		local reward = PA.free[tier]
		if reward and reward.item then
			gap = math.max(gap, tier - last)
			last = tier
		end
	end
	for _, track in { PA.free, PA.premium } do
		for _, reward in track do
			if reward.item then
				if used[reward.item] or not (items[reward.item] and items[reward.item].pass) then
					unique = false
				end
				used[reward.item] = true
			end
		end
	end
	t.check("la premium donne un objet a chaque palier", premiumAll)
	t.check("la gratuite donne un objet au moins tous les 5 paliers", gap <= 5)
	t.check("chaque objet du passe est propre au passe, et donne une seule fois", unique)
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
	-- Un joueur regulier : 3 parties par jour, ses defis quotidiens et
	-- hebdomadaires faits. Il doit finir le passe en 3 a 8 semaines.
	local CH = Config.challenges
	local perDay = 3 * perMatch
		+ CH.daily * CH.passXp
		+ CH.weekly * CH.passXp * CH.weeklyRewardFactor / 7
	local days = PA.tiers * PA.tierXp / perDay
	t.check("le passe ne se finit pas en moins de 3 semaines", days >= 21)
	t.check("le passe se finit dans une saison de 8 semaines", days <= 56)
	t.check("le bonus du premium reste petit", PA.premiumXpBonus <= 0.25)
	-- Les paquets de credits : chacun en vente, et un plus gros paquet donne
	-- au moins autant de credits par Robux que le precedent.
	local packs = Config.shop.creditPacks
	local fair = true
	for i, pack in packs do
		t.check(string.format("le paquet %d a son produit Roblox", i), pack.productId ~= 0)
		if i > 1 and pack.credits / pack.robux < packs[i - 1].credits / packs[i - 1].robux then
			fair = false
		end
	end
	t.check("un plus gros paquet n'est jamais moins avantageux", fair)
	t.check("le passe premium a son produit Roblox", PA.premiumProductId ~= 0)
end
