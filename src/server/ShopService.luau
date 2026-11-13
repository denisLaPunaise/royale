--!strict
--[[
	ShopService — la boutique, les tirages et le passe de saison (CONCEPT.md,
	Progression et boutique). Rien que des apparences : aucun achat ne donne
	de puissance. PRIX PROVISOIRES (Config.cosmetics, Config.shop,
	Config.pass), a regler avec Josh.

	- La boutique tournante change chaque jour ; le coin permanent reste.
	- Les tirages : avec des fragments (gratuit) ou des credits. En credits,
	  c'est un tirage payant au sens de Roblox : toutes les chances sont
	  affichees avant (l'ecran), egales, total 100 % ; chaque tirage donne
	  quelque chose, un doublon rend des credits ; il est coupe la ou Roblox
	  interdit les tirages payants (PolicyService).
	- Les credits et le passe premium s'achetent en Robux (produits de
	  developpeur, a creer par Josh) ; un achat n'est compte qu'une fois, et
	  jamais sur un profil illisible (Roblox le representera plus tard).
	- Le passe avance avec l'XP des parties ; ses recompenses tombent seules.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local Shop = require(Royale:WaitForChild("Shop"))

local ProfileService = require(script.Parent.ProfileService)
local RemoteGuard = require(script.Parent.RemoteGuard)

local ShopService = {}

local CO = Config.cosmetics
local SH = Config.shop
local PA = Config.pass
local items = CO.items
local random = Random.new()
-- Ceux pour qui Roblox interdit les tirages payants (lu a l'arrivee).
local restricted: { [Player]: boolean } = {}

local function notify(player: Player, text: string)
	player:SetAttribute(
		Config.bag.messageAttribute,
		text .. "|" .. tostring(workspace:GetServerTimeNow())
	)
end

local function today(): number
	return os.time() // 86400
end

-- Ce que l'ecran montre : la boutique du jour, le prix d'un tirage (sur
-- Workspace) ; ce qu'on a, ce qu'on porte, le passe (sur le joueur).
local function publishWorld()
	workspace:SetAttribute(
		Config.shop.worldAttribute,
		HttpService:JSONEncode({
			daily = Shop.daily(items, SH.permanent, today(), SH.daily),
			drawPrice = Shop.drawPrice(items, CO.prices, SH.drawPool),
			chances = Shop.chances(SH.drawPool),
		})
	)
end

-- La trainee portee, derriere le personnage (le serveur la pose : tout le
-- monde la voit).
local function applyTrail(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	for _, name in { "RoyaleTrainee", "RoyaleTraineeHaut", "RoyaleTraineeBas" } do
		local old = root:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local d = ProfileService.get(player)
	local id = d and d.equipped.trail
	local def = id and items[id]
	if def == nil then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "RoyaleTraineeHaut"
	a0.Position = Vector3.new(0, CO.trail.height / 2, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "RoyaleTraineeBas"
	a1.Position = Vector3.new(0, -CO.trail.height / 2, 0)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "RoyaleTrainee"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = CO.trail.lifetime
	trail.LightEmission = CO.trail.lightEmission
	trail.Color = ColorSequence.new(Color3.fromRGB(def.color[1], def.color[2], def.color[3]))
	trail.Transparency = NumberSequence.new(CO.trail.transparency, 1)
	trail.Parent = root
end

local function publish(player: Player)
	local d = ProfileService.get(player)
	if d == nil then
		return
	end
	for _, slot in CO.slots do
		player:SetAttribute(CO.attributePrefix .. slot, d.equipped[slot])
	end
	local pass = d.pass
	player:SetAttribute(
		Config.shop.playerAttribute,
		HttpService:JSONEncode({
			owned = d.owned,
			equipped = d.equipped,
			tier = Shop.tier(pass.xp or 0, PA.tierXp, PA.tiers),
			passXp = pass.xp or 0,
			premium = pass.premium == PA.season,
			restricted = restricted[player] == true,
		})
	)
end

-- Donne un objet ; un doublon rend une part de son prix. Rend le texte a
-- dire.
local function give(d: any, id: string): string
	local def = items[id]
	if def == nil then
		return ""
	end
	if d.owned[id] then
		local refund = math.floor(Shop.price(items, CO.prices, id) * SH.duplicateRefund)
		d.credits += refund
		return string.format("%s (déjà à toi : +%d crédits)", def.name, refund)
	end
	d.owned[id] = true
	return def.name
end

-- Le passe : la saison change, on repart de zero ; sinon on avance.
local function passOf(d: any): any
	if d.pass.season ~= PA.season then
		d.pass = { season = PA.season, xp = 0, premium = nil }
	end
	return d.pass
end

local function grantPass(player: Player, d: any, from: number, to: number)
	local pass = passOf(d)
	local tracks = { PA.free }
	if pass.premium == PA.season then
		table.insert(tracks, PA.premium)
	end
	for _, track in tracks do
		for _, reward in Shop.passRewards(track, from, to) do
			if reward.credits then
				d.credits += reward.credits
				notify(player, string.format("Passe : +%d crédits", reward.credits))
			elseif reward.item then
				notify(player, "Passe : " .. give(d, reward.item))
			end
		end
	end
end

-- L'XP d'une partie fait avancer le passe (ProfileService.onGranted).
local function onMatchXp(player: Player, xp: number)
	local d = ProfileService.get(player)
	if d == nil then
		return
	end
	local pass = passOf(d)
	local before = Shop.tier(pass.xp or 0, PA.tierXp, PA.tiers)
	pass.xp = (pass.xp or 0) + xp
	local after = Shop.tier(pass.xp, PA.tierXp, PA.tiers)
	if after > before then
		grantPass(player, d, before, after)
	end
	ProfileService.changed(player)
	publish(player)
end

local function buy(player: Player, d: any, id: any)
	local daily = Shop.daily(items, SH.permanent, today(), SH.daily)
	if
		typeof(id) ~= "string"
		or items[id] == nil
		or not (table.find(daily, id) or table.find(SH.permanent, id))
	then
		notify(player, "Pas en boutique aujourd'hui.")
		return
	end
	if d.owned[id] then
		notify(player, "Tu l'as déjà.")
		return
	end
	if not ProfileService.spend(player, Shop.price(items, CO.prices, id)) then
		notify(player, "Pas assez de crédits.")
		return
	end
	d.owned[id] = true
	notify(player, "Acheté : " .. items[id].name)
end

local function equip(player: Player, d: any, id: any)
	if typeof(id) ~= "string" or items[id] == nil or not d.owned[id] then
		return
	end
	local slot = items[id].slot
	-- Le porter deja : on l'enleve.
	d.equipped[slot] = if d.equipped[slot] == id then nil else id
	notify(
		player,
		if d.equipped[slot] then "Équipé : " .. items[id].name else "Enlevé : " .. items[id].name
	)
	if slot == "trail" then
		applyTrail(player)
	end
end

local function draw(player: Player, d: any, withCredits: boolean)
	if withCredits then
		if restricted[player] then
			notify(player, "Les tirages en crédits ne sont pas disponibles pour toi.")
			return
		end
		if not ProfileService.spend(player, Shop.drawPrice(items, CO.prices, SH.drawPool)) then
			notify(player, "Pas assez de crédits.")
			return
		end
	else
		local cost = Config.progression.fragments.perDraw
		if d.fragments < cost then
			notify(player, string.format("Il faut %d fragments.", cost))
			return
		end
		d.fragments -= cost
	end
	notify(player, "Tirage : " .. give(d, Shop.draw(SH.drawPool, random:NextNumber())))
end

local function action(player: Player, name: any, arg: any)
	local d = ProfileService.get(player)
	if d == nil or typeof(name) ~= "string" then
		return
	end
	if name == "buy" then
		buy(player, d, arg)
	elseif name == "equip" then
		equip(player, d, arg)
	elseif name == "drawFragments" then
		draw(player, d, false)
	elseif name == "drawCredits" then
		draw(player, d, true)
	elseif name == "pack" then
		local pack = if typeof(arg) == "number" then SH.creditPacks[arg] else nil
		if pack and pack.productId ~= 0 then
			MarketplaceService:PromptProductPurchase(player, pack.productId)
		else
			notify(player, "Ce paquet n'est pas encore en vente.")
		end
		return
	elseif name == "pass" then
		if PA.premiumProductId ~= 0 and passOf(d).premium ~= PA.season then
			MarketplaceService:PromptProductPurchase(player, PA.premiumProductId)
		else
			notify(player, "Le passe premium n'est pas encore en vente.")
		end
		return
	else
		return
	end
	ProfileService.changed(player)
	publish(player)
end

-- Un achat en Robux : compte une seule fois (le numero d'achat est garde
-- dans le profil), jamais sur un profil illisible.
local function processReceipt(receipt: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local d = player and ProfileService.get(player)
	if player == nil or d == nil or not ProfileService.readable(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if d.receipts[receipt.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local granted = false
	for _, pack in SH.creditPacks do
		if pack.productId ~= 0 and pack.productId == receipt.ProductId then
			d.credits += pack.credits
			notify(player, string.format("+%d crédits, merci !", pack.credits))
			granted = true
		end
	end
	if PA.premiumProductId ~= 0 and receipt.ProductId == PA.premiumProductId then
		local pass = passOf(d)
		pass.premium = PA.season
		-- Les recompenses premium deja atteintes tombent tout de suite.
		local tier = Shop.tier(pass.xp or 0, PA.tierXp, PA.tiers)
		for _, reward in Shop.passRewards(PA.premium, 0, tier) do
			if reward.credits then
				d.credits += reward.credits
			elseif reward.item then
				give(d, reward.item)
			end
		end
		notify(player, "Passe premium débloqué !")
		granted = true
	end
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	d.receipts[receipt.PurchaseId] = true
	ProfileService.changed(player)
	if not ProfileService.saveNow(player) then
		-- Pas sauvegarde : Roblox representera l'achat, et le numero garde
		-- en memoire evite de le compter deux fois sur ce serveur.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	publish(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- De l'XP de passe venue d'ailleurs (les defis).
function ShopService.addPassXp(player: Player, xp: number)
	onMatchXp(player, xp)
end

-- Ce qu'un joueur porte dans cet emplacement (l'objet du catalogue), ou nil.
function ShopService.equipped(player: Player, slot: string): any?
	local id = player:GetAttribute(CO.attributePrefix .. slot)
	return if typeof(id) == "string" then items[id] else nil
end

function ShopService.start(remote: RemoteEvent)
	publishWorld()
	remote.OnServerEvent:Connect(RemoteGuard.wrap(Config.remotes.shop, action))
	ProfileService.onLoaded(function(player: Player)
		local ok, info = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)
		-- Dans le doute (lecture impossible), on coupe le tirage payant.
		restricted[player] = not ok or info.ArePaidRandomItemsRestricted == true
		publish(player)
	end)
	ProfileService.onGranted(onMatchXp)
	MarketplaceService.ProcessReceipt = processReceipt
	-- La trainee revient a chaque nouveau personnage (salon, partie).
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			applyTrail(player)
		end)
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(player: Player)
		restricted[player] = nil
	end)
	-- La boutique change a minuit (UTC) : on la republie de temps en temps.
	task.spawn(function()
		while true do
			task.wait(SH.refreshSeconds)
			publishWorld()
		end
	end)
end

return ShopService
