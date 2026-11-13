-- Banc d'equilibrage jetable (jamais commite) : note chaque partie de bots.
return function()
	local SSS = game.ServerScriptService.Royale
	local Roster = require(SSS.Roster)
	local Hiding = require(SSS.HidingService)
	local Zone = require(SSS.ZoneService)
	local Combat = require(SSS.CombatService)
	local World = require(SSS.World)
	-- Depuis quand chacun n'a pas bouge (plus de 2 studs).
	local lastPos, lastMove = {}, {}
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, a in Roster.alive() do
				local r = Roster.rootOf(a)
				if r then
					local p = r.Position
					if lastPos[a] == nil or (lastPos[a] - p).Magnitude > 2 then
						lastPos[a] = p
						lastMove[a] = os.clock()
					end
				end
			end
		end
	end)
	local Http = game:GetService("HttpService")
	local Config = require(game.ReplicatedStorage.Royale.Config)
	local baseMistake = Config.bots.mistakeChance
	-- Une entree du plan : "mode" ou "mode:chance d'erreur des bots".
	local function apply(entry)
		local parts = string.split(entry, ":")
		workspace:SetAttribute("BancMode", parts[1])
		Config.bots.mistakeChance = tonumber(parts[2]) or baseMistake
	end
	local all = {}
	local cur = nil
	local t0 = 0
	local regard = 0
	local origTake = Roster.take
	Roster.take = function(actor)
		local wasAlive = Roster.isAlive(actor)
		local tb = debug.traceback()
		local hidden = Hiding.isHidden(actor)
		local root = Roster.rootOf(actor)
		local outside = root ~= nil and Zone.outside(root.Position)
		local down = Combat.isDown(actor)
		local speed = if root
			then math.floor(
				Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
			)
			else -1
		local still = if lastMove[actor] then math.floor(os.clock() - lastMove[actor]) else -1
		local vis = if root
			then math.floor(
				World.visibility(root.Position + Vector3.new(0, 1.5, 0), { workspace.Participants })
					* 100
			)
			else -1
		local hunted = actor:GetAttribute("Traque") == true
		local open = workspace:GetAttribute("OeilOuvert") == true
		origTake(actor)
		if cur and wasAlive then
			local cause
			if tb:find("SquadService") then
				cause = "cocon"
			elseif tb:find("EyeService") then
				cause = if outside then "zone" else "oeil"
			elseif tb:find("GoulagService") then
				cause = "ventre"
			elseif tb:find("MatchService") then
				cause = "mort"
			else
				cause = "autre"
			end
			local nowAlive = Roster.isAlive(actor)
			table.insert(cur.takes, {
				t = math.floor(os.clock() - t0),
				r = regard,
				c = if nowAlive then "sauve" else cause,
				h = hidden,
				d = down,
				v = speed,
				still = still,
				vis = vis,
				hunt = hunted,
				open = open,
				bot = not actor:IsA("Player"),
			})
		end
	end
	local origRevive = Roster.revive
	Roster.revive = function(actor)
		local was = Roster.isAlive(actor)
		origRevive(actor)
		if cur and not was and Roster.isAlive(actor) then
			table.insert(cur.revives, { t = math.floor(os.clock() - t0), r = regard })
		end
	end
	local plan = string.split(workspace:GetAttribute("BancPlan"), ",")
	local idx = 1
	workspace:SetAttribute("BancIndex", idx)
	apply(plan[idx])
	workspace:SetAttribute("BancActif", true)
	while true do
		task.wait(1)
		local phase = workspace:GetAttribute("Phase")
		if phase == "Partie" and cur == nil then
			cur = {
				mode = workspace:GetAttribute("BancMode"),
				mistake = Config.bots.mistakeChance,
				start = Roster.startCount(),
				takes = {},
				revives = {},
				alive = {},
				at = {},
			}
			t0 = os.clock()
			regard = 0
		end
		if cur then
			local r = workspace:GetAttribute("Regard") or 0
			if r ~= regard then
				regard = r
				cur.alive[r] = Roster.count()
				cur.at[r] = math.floor(os.clock() - t0)
				local f = workspace.Carte:FindFirstChild("CachettesDeLaPartie")
				local n = 0
				if f then
					for _, m in f:GetChildren() do
						if not m.Name:find("Egout") then
							n += 1
						end
					end
				end
				cur.spots = cur.spots or {}
				cur.spots[r] = n
			end
			if phase ~= "Partie" then
				cur.duration = math.floor(os.clock() - t0)
				cur.winner = workspace:GetAttribute("Gagnant")
				cur.lastRegard = regard
				table.insert(all, cur)
				workspace:SetAttribute("BancBilan", Http:JSONEncode(all))
				print(
					string.format(
						"[Banc] Partie %d (%s, erreurs %s) finie en %d s, Regard %d",
						#all,
						cur.mode,
						tostring(cur.mistake),
						cur.duration,
						regard
					)
				)
				cur = nil
				idx += 1
				workspace:SetAttribute("BancIndex", idx)
				if plan[idx] then
					apply(plan[idx])
				else
					workspace:SetAttribute("BancActif", false)
				end
			end
		end
	end
end
