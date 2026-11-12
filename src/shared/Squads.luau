--!strict
--[[
	Squads — les equipes (CONCEPT.md, Les escouades) : qui joue avec qui, et
	quand une equipe a gagne.

	Logique pure : aucun require, aucune API Roblox.
]]

local Squads = {}

-- Les equipes avec des groupes du salon : un groupe n'est jamais coupe (s'il
-- ne tient pas dans la place qui reste, il ouvre une nouvelle equipe), puis
-- les bots comblent les trous et forment les equipes suivantes.
function Squads.assignGroups(
	size: number,
	groups: { { string } },
	bots: { string }
): { [string]: number }
	local out: { [string]: number } = {}
	local teams: { number } = {} -- places prises par equipe
	for _, group in groups do
		local placed = false
		for t, used in teams do
			if used + #group <= size then
				for _, id in group do
					out[id] = t
				end
				teams[t] = used + #group
				placed = true
				break
			end
		end
		if not placed then
			table.insert(teams, 0)
			local t = #teams
			-- Un groupe plus grand que l'equipe (mode trop petit) : coupe en
			-- equipes successives.
			for i, id in group do
				local team = t + (i - 1) // size
				while #teams < team do
					table.insert(teams, 0)
				end
				out[id] = team
				teams[team] += 1
			end
		end
	end
	local nextBot = 1
	for t, used in teams do
		while used < size and nextBot <= #bots do
			out[bots[nextBot]] = t
			used += 1
			nextBot += 1
		end
		teams[t] = used
	end
	local t = #teams
	local filled = size
	while nextBot <= #bots do
		if filled >= size then
			t += 1
			filled = 0
		end
		out[bots[nextBot]] = t
		filled += 1
		nextBot += 1
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
