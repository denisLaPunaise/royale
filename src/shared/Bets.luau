--!strict
--[[
	Bets — les paris des elimines (CONCEPT.md, Capture) : qui peut parier sur
	qui, et qui a gagne son pari.

	Logique pure : aucun require, aucune API Roblox.
]]

local Bets = {}

export type Check = {
	regard: number,
	untilRegard: number,
	-- Le parieur : elimine pour de bon (ni en vie, ni au Ventre), pas encore
	-- de pari.
	eliminated: boolean,
	already: boolean,
	-- La cible : en vie, et pas un ami Roblox du parieur (deux amis ne
	-- doivent pas pouvoir s'arranger, CONCEPT.md).
	targetAlive: boolean,
	friends: boolean,
}

-- Rend vrai, ou faux et la raison a dire au joueur.
function Bets.allowed(c: Check): (boolean, string?)
	if not c.eliminated then
		return false, "Tu joues encore."
	elseif c.already then
		return false, "Tu as déjà parié."
	elseif c.regard >= c.untilRegard then
		return false, "Les paris sont fermés."
	elseif not c.targetAlive then
		return false, "Il n'est plus en jeu."
	elseif c.friends then
		return false, "Pas de pari sur un ami Roblox."
	end
	return true, nil
end

-- Les parieurs qui ont gagne : ceux dont la cible est parmi les gagnants.
function Bets.winners(bets: { [string]: string }, winners: { string }): { string }
	local won: { [string]: boolean } = {}
	for _, id in winners do
		won[id] = true
	end
	local out: { string } = {}
	for bettor, target in bets do
		if won[target] then
			table.insert(out, bettor)
		end
	end
	table.sort(out)
	return out
end

return Bets
