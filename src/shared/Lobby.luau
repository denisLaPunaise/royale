--!strict
--[[
	Lobby — les groupes du salon : qui est avec qui, le mode choisi par le
	chef, qui est pret, et qui part quand le compte a rebours finit.

	Logique pure : aucun require, aucune API Roblox. Les joueurs sont des ids
	(texte). Chaque joueur est toujours dans un groupe (seul, il est son
	propre chef).
]]

local Lobby = {}

export type Group = { leader: string, members: { string }, mode: string, ready: boolean }
export type State = { groups: { [string]: Group }, groupOf: { [string]: string } }

function Lobby.new(): State
	return { groups = {}, groupOf = {} }
end

-- Un joueur arrive : seul dans son groupe, au mode par defaut.
function Lobby.add(s: State, id: string, mode: string)
	if s.groupOf[id] then
		return
	end
	s.groups[id] = { leader = id, members = { id }, mode = mode, ready = false }
	s.groupOf[id] = id
end

-- Il quitte son groupe (ou le serveur) : seul de nouveau, ou retire. Si
-- c'etait le chef, le suivant le devient.
function Lobby.leave(s: State, id: string, stay: boolean)
	local leader = s.groupOf[id]
	local g = leader and s.groups[leader]
	if g == nil then
		return
	end
	local i = table.find(g.members, id)
	if i then
		table.remove(g.members, i)
	end
	s.groupOf[id] = nil
	s.groups[leader] = nil
	if #g.members > 0 then
		local nextLeader = g.members[1]
		g.leader = nextLeader
		g.ready = false
		s.groups[nextLeader] = g
		for _, m in g.members do
			s.groupOf[m] = nextLeader
		end
	end
	if stay then
		Lobby.add(s, id, g.mode)
	end
end

-- `id` rejoint le groupe de `host` (il a accepte son invitation). Refuse si
-- le groupe est plein ou si c'est deja le meme.
function Lobby.join(s: State, host: string, id: string, maxGroup: number): boolean
	local leader = s.groupOf[host]
	local g = leader and s.groups[leader]
	if g == nil or s.groupOf[id] == leader or #g.members >= maxGroup then
		return false
	end
	Lobby.leave(s, id, false)
	-- Le depart a pu changer le chef du groupe hote (si `id` en etait).
	leader = s.groupOf[host]
	g = s.groups[leader]
	table.insert(g.members, id)
	s.groupOf[id] = leader
	g.ready = false
	return true
end

-- Le mode suivant (le chef seulement) : un groupe trop grand pour un mode
-- passe au suivant.
function Lobby.cycleMode(s: State, id: string, modes: { string }, sizes: { [string]: number })
	local g = s.groups[id]
	if g == nil then
		return
	end
	local i = table.find(modes, g.mode) or 0
	for _ = 1, #modes do
		i = i % #modes + 1
		if sizes[modes[i]] >= #g.members then
			g.mode = modes[i]
			g.ready = false
			return
		end
	end
end

function Lobby.setReady(s: State, id: string, ready: boolean, sizes: { [string]: number })
	local g = s.groups[s.groupOf[id] or ""]
	if g == nil or g.leader ~= id then
		return
	end
	-- Un groupe plus grand que son mode ne peut pas partir.
	g.ready = ready and sizes[g.mode] >= #g.members
end

-- Les groupes prets de ce mode, dans l'ordre de leurs chefs.
function Lobby.readyGroups(s: State, mode: string): { Group }
	local out: { Group } = {}
	for _, g in s.groups do
		if g.ready and g.mode == mode then
			table.insert(out, g)
		end
	end
	table.sort(out, function(a, b)
		return a.leader < b.leader
	end)
	return out
end

return Lobby
