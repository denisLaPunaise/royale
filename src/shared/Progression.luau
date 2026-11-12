--!strict
--[[
	Progression — ce qu'une partie rapporte, et le niveau d'apres l'XP
	(CONCEPT.md, Progression et boutique).

	Logique pure : aucun require, aucune API Roblox.
]]

local Progression = {}

export type Result = {
	-- Le plus haut Regard atteint en jeu (1 a 5).
	regard: number,
	won: boolean,
	-- La place de son equipe (1 = gagnante), ou nil si inconnue.
	place: number?,
	betWon: boolean,
}

export type Reward = { xp: number, credits: number, fragments: number }

function Progression.reward(r: Result, p: any, betCredits: number): Reward
	local regard = math.clamp(r.regard, 0, 5)
	local xp = p.xp.played + p.xp.perRegard * regard + (if r.won then p.xp.win else 0)
	local credits = p.credits.played
		+ p.credits.perRegard * regard
		+ (if r.won then p.credits.win else 0)
		+ (if r.betWon then betCredits else 0)
	local fragments = 0
	if r.place == 1 then
		fragments = p.fragments.first
	elseif r.place and r.place <= p.fragments.topUntil then
		fragments = p.fragments.top
	end
	return { xp = xp, credits = credits, fragments = fragments }
end

-- Le niveau pour cette XP totale : le niveau, l'XP deja faite dans ce
-- niveau, et ce qu'il faut pour le finir.
function Progression.level(totalXp: number, base: number, step: number): (number, number, number)
	local level = 1
	local left = math.max(totalXp, 0)
	local need = base
	while left >= need do
		left -= need
		level += 1
		need = base + step * (level - 1)
	end
	return level, left, need
end

-- Un profil neuf, ou un profil lu complete des champs qu'il n'a pas encore
-- (un ancien format reste lisible).
function Progression.fill(data: any, version: number): any
	local out = if typeof(data) == "table" then data else {}
	out.version = version
	out.xp = if typeof(out.xp) == "number" then out.xp else 0
	out.credits = if typeof(out.credits) == "number" then out.credits else 0
	out.fragments = if typeof(out.fragments) == "number" then out.fragments else 0
	out.matches = if typeof(out.matches) == "number" then out.matches else 0
	out.wins = if typeof(out.wins) == "number" then out.wins else 0
	out.owned = if typeof(out.owned) == "table" then out.owned else {}
	out.equipped = if typeof(out.equipped) == "table" then out.equipped else {}
	out.pass = if typeof(out.pass) == "table" then out.pass else {}
	out.receipts = if typeof(out.receipts) == "table" then out.receipts else {}
	return out
end

return Progression
