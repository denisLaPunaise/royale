--!strict
--[[
	Squads — les equipes (CONCEPT.md, Les escouades) : qui joue avec qui, et
	quand une equipe a gagne.

	Logique pure : aucun require, aucune API Roblox.
]]

local Squads = {}

-- Les equipes : les vrais joueurs d'abord, ensemble dans l'ordre (des amis
-- qui arrivent ensemble), puis les bots completent (CONCEPT.md : equipe
-- completee par des inconnus puis des bots). Rend id -> numero d'equipe.
function Squads.assign(size: number, humans: { string }, bots: { string }): { [string]: number }
	local out: { [string]: number } = {}
	local i = 0
	for _, id in humans do
		out[id] = i // size + 1
		i += 1
	end
	for _, id in bots do
		out[id] = i // size + 1
		i += 1
	end
	return out
end

-- Les equipes encore en jeu, d'apres l'equipe de chaque vivant.
function Squads.teamsAlive(teams: { number }): number
	local seen: { [number]: boolean } = {}
	local n = 0
	for _, t in teams do
		if not seen[t] then
			seen[t] = true
			n += 1
		end
	end
	return n
end

-- La partie est-elle finie ? `enough` : le nombre d'equipes en dessous
-- duquel on s'arrete (1 d'habitude ; 0 pour une partie d'une seule equipe,
-- qui joue jusqu'au bout).
function Squads.over(teams: { number }, startTeams: number): boolean
	local enough = if startTeams > 1 then 1 else 0
	return Squads.teamsAlive(teams) <= enough
end

return Squads
