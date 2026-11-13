--!strict
--[[
	ChallengeService — les defis quotidiens et hebdomadaires (CONCEPT.md : ils
	font avancer le passe). Les services disent ce qui arrive (une fouille,
	un K.O., un Repris detruit, un cocon ouvert, un retour du Ventre) ; la
	fin de partie dit le reste (jouer, le Regard atteint, gagner). Un defi
	fini rapporte de l'XP de passe et des credits, une seule fois.

	Seuls les vrais joueurs ont des defis (les bots n'ont pas de profil).
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Challenges = require(Royale:WaitForChild("Challenges"))
local Config = require(Royale:WaitForChild("Config"))

local ProfileService = require(script.Parent.ProfileService)
local ShopService = require(script.Parent.ShopService)

local ChallengeService = {}

local CH = Config.challenges
local DAY = 86400
-- Les semaines commencent le meme jour pour tout le monde.
local WEEK = 7 * DAY
-- Pour que les defis de la semaine ne soient pas ceux du jour.
local WEEK_SALT = 7

local function periods(): (number, number)
	local t = os.time()
	return t // DAY, t // WEEK
end

local function tracks(d: any): (any, { string }, any, { string })
	local day, week = periods()
	d.challenges = if typeof(d.challenges) == "table" then d.challenges else {}
	d.challenges.daily = Challenges.reset(d.challenges.daily, day)
	d.challenges.weekly = Challenges.reset(d.challenges.weekly, week)
	return d.challenges.daily,
		Challenges.pick(CH.list, day, CH.daily, 0),
		d.challenges.weekly,
		Challenges.pick(CH.list, week, CH.weekly, WEEK_SALT)
end

local function publish(player: Player)
	local d = ProfileService.get(player)
	if d == nil then
		return
	end
	local daily, activeDaily, weekly, activeWeekly = tracks(d)
	local function lines(track: any, active: { string }, factor: number)
		local out = {}
		for _, id in active do
			local def = CH.list[id]
			local goal = def.goal * factor
			table.insert(out, {
				text = string.format(def.text, goal),
				progress = track.progress[id] or 0,
				goal = goal,
				done = track.done[id] == true,
			})
		end
		return out
	end
	player:SetAttribute(
		CH.attribute,
		HttpService:JSONEncode({
			daily = lines(daily, activeDaily, 1),
			weekly = lines(weekly, activeWeekly, CH.weeklyFactor),
		})
	)
end

local function notify(player: Player, text: string)
	player:SetAttribute(
		Config.bag.messageAttribute,
		text .. "|" .. tostring(workspace:GetServerTimeNow())
	)
end

-- Il s'est passe `stat` (`amount` fois) pour ce participant.
function ChallengeService.record(actor: Instance, stat: string, amount: number?)
	if not actor:IsA("Player") then
		return
	end
	local player = actor :: Player
	local d = ProfileService.get(player)
	if d == nil then
		return
	end
	local daily, activeDaily, weekly, activeWeekly = tracks(d)
	local n = amount or 1
	local passXp, credits = 0, 0
	for _, id in Challenges.record(daily, activeDaily, CH.list, stat, n, 1) do
		passXp += CH.passXp
		credits += CH.credits
		notify(
			player,
			"Défi du jour réussi : " .. string.format(CH.list[id].text, CH.list[id].goal)
		)
	end
	for _, id in Challenges.record(weekly, activeWeekly, CH.list, stat, n, CH.weeklyFactor) do
		passXp += CH.passXp * CH.weeklyRewardFactor
		credits += CH.credits * CH.weeklyRewardFactor
		notify(
			player,
			"Défi de la semaine réussi : "
				.. string.format(CH.list[id].text, CH.list[id].goal * CH.weeklyFactor)
		)
	end
	if credits > 0 then
		d.credits += credits
	end
	ProfileService.changed(player)
	if passXp > 0 then
		ShopService.addPassXp(player, passXp)
	end
	publish(player)
end

function ChallengeService.start()
	ProfileService.onLoaded(publish)
	ProfileService.onGranted(function(player: Player, _xp: number, result: any)
		ChallengeService.record(player, "match")
		if result and result.regard >= 3 then
			ChallengeService.record(player, "regard3")
		end
		if result and result.won then
			ChallengeService.record(player, "win")
		end
	end)
end

return ChallengeService
