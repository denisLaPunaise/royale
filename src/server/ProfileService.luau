--!strict
--[[
	ProfileService — le profil de chaque joueur (XP, niveau, credits,
	fragments, cosmetiques, passe), sauvegarde dans un DataStore.

	La regle d'or (CLAUDE.md, principe 5) : une sauvegarde illisible n'est pas
	une sauvegarde vide. Si la lecture echoue, le joueur joue avec un profil
	vide en memoire, marque illisible, et RIEN n'est jamais ecrit pour lui.

	Le salon et le serveur de partie se passent le joueur (teleportation) :
	chaque serveur tient le profil (champ `session`) et le lache en
	sauvegardant au depart ; l'autre attend qu'il soit lache avant de le lire.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local Progression = require(Royale:WaitForChild("Progression"))

local ProfileService = {}

local P = Config.progression
local A = P.attributes

type Entry = { data: any, readable: boolean, dirty: boolean }

local profiles: { [Player]: Entry } = {}
local loadedListeners: { (Player) -> () } = {}
local store: DataStore? = nil

local function getStore(): DataStore?
	if store == nil then
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(P.store)
		end)
		if ok then
			store = result
		else
			warn("[Royale] DataStore indisponible : " .. tostring(result))
		end
	end
	return store
end

local function keyOf(player: Player): string
	return "joueur_" .. player.UserId
end

local function now(): number
	return os.time()
end

-- Publie ce que l'ecran montre.
local function publish(player: Player)
	local entry = profiles[player]
	if entry == nil then
		return
	end
	local d = entry.data
	local level, into, need = Progression.level(d.xp, P.levelBase, P.levelStep)
	player:SetAttribute(A.level, level)
	player:SetAttribute(A.xp, into)
	player:SetAttribute(A.xpNeeded, need)
	player:SetAttribute(A.credits, d.credits)
	player:SetAttribute(A.fragments, d.fragments)
	player:SetAttribute(A.unreadable, if entry.readable then nil else true)
end

-- Lire : attendre qu'aucun autre serveur ne le tienne, puis le prendre.
-- Rend le profil, ou nil si la lecture a echoue.
local function read(player: Player): any?
	local ds = getStore()
	if ds == nil then
		return nil
	end
	local key = keyOf(player)
	local waitedUntil = os.clock() + P.sessionWaitSeconds
	-- Attendre qu'un autre serveur lache le profil ne compte pas comme un
	-- echec ; seules les erreurs du DataStore comptent.
	local failures = 0
	while failures < P.readAttempts do
		local held = false
		local result: any = nil
		local ok, err = pcall(function()
			(ds :: DataStore):UpdateAsync(key, function(old: any)
				local data = Progression.fill(old, P.version)
				local session = data.session
				if
					typeof(session) == "table"
					and session.job ~= game.JobId
					and now() - (session.at or 0) < P.sessionStaleSeconds
					and os.clock() < waitedUntil
				then
					-- Un autre serveur le tient encore : on n'ecrit rien.
					held = true
					return nil
				end
				data.session = { job = game.JobId, at = now() }
				result = data
				return data
			end)
		end)
		if ok and not held and result then
			return result
		elseif not ok then
			failures += 1
			warn(
				string.format(
					"[Royale] Lecture du profil de %s (essai %d) : %s",
					player.Name,
					failures,
					tostring(err)
				)
			)
		end
		task.wait(P.retrySeconds)
	end
	return nil
end

-- Sauvegarder (et lacher le profil si `release`). Jamais pour un profil
-- illisible.
local function save(player: Player, release: boolean)
	local entry = profiles[player]
	local ds = getStore()
	if entry == nil or not entry.readable or ds == nil then
		return
	end
	local data = table.clone(entry.data)
	data.session = if release then nil else { job = game.JobId, at = now() }
	local ok, err = pcall(function()
		(ds :: DataStore):UpdateAsync(keyOf(player), function(old: any)
			local current = if typeof(old) == "table" then old.session else nil
			if
				typeof(current) == "table"
				and current.job ~= game.JobId
				and now() - (current.at or 0) < P.sessionStaleSeconds
			then
				-- Un autre serveur l'a pris entre-temps : ne pas l'ecraser.
				return nil
			end
			return data
		end)
	end)
	if ok then
		entry.dirty = false
	else
		warn("[Royale] Sauvegarde du profil de " .. player.Name .. " : " .. tostring(err))
	end
end

local function load(player: Player)
	local data = read(player)
	local readable = data ~= nil
	if not readable then
		warn("[Royale] Profil illisible pour " .. player.Name .. " : rien ne sera sauvegardé")
	end
	profiles[player] =
		{ data = data or Progression.fill(nil, P.version), readable = readable, dirty = false }
	publish(player)
	for _, listener in loadedListeners do
		task.spawn(listener, player)
	end
end

function ProfileService.onLoaded(listener: (Player) -> ())
	table.insert(loadedListeners, listener)
end

-- Le profil en memoire (la boutique, le passe le lisent et le changent).
function ProfileService.get(player: Player): any?
	local entry = profiles[player]
	return entry and entry.data
end

function ProfileService.changed(player: Player)
	local entry = profiles[player]
	if entry then
		entry.dirty = true
		publish(player)
	end
end

-- Depenser des credits : vrai si assez.
function ProfileService.spend(player: Player, credits: number): boolean
	local d = ProfileService.get(player)
	if d == nil or d.credits < credits then
		return false
	end
	d.credits -= credits
	ProfileService.changed(player)
	return true
end

-- Ce qu'une partie rapporte, ajoute et annonce.
function ProfileService.grant(player: Player, result: Progression.Result)
	local d = ProfileService.get(player)
	if d == nil then
		return
	end
	local reward = Progression.reward(result, P, Config.bets.rewardCredits)
	d.xp += reward.xp
	d.credits += reward.credits
	d.fragments += reward.fragments
	d.matches += 1
	if result.won then
		d.wins += 1
	end
	ProfileService.changed(player)
	player:SetAttribute(
		A.lastReward,
		string.format(
			"+%d XP · +%d crédits%s",
			reward.xp,
			reward.credits,
			if reward.fragments > 0
				then string.format(" · +%d fragment(s)", reward.fragments)
				else ""
		)
			.. "|"
			.. tostring(workspace:GetServerTimeNow())
	)
	save(player, false)
end

function ProfileService.start()
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerAdded:Connect(load)
	Players.PlayerRemoving:Connect(function(player: Player)
		save(player, true)
		profiles[player] = nil
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			save(player, true)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(P.autosaveSeconds)
			for player, entry in profiles do
				if entry.dirty then
					save(player, false)
				end
			end
		end
	end)
end

return ProfileService
