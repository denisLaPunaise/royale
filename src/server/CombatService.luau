--!strict
--[[
	CombatService — le corps a corps (CONCEPT.md, Interactions entre joueurs) :
	frapper (R2), pousser ou plaquer (Y), porter et jeter un K.O. (Y maintenu,
	puis Y ou B), le tacle glisse (B en courant), toquer a un abri (R2 dessus),
	deloger quelqu'un (Y sur un abri) et la porte dans la figure (R2 cache).

	Le client n'envoie qu'un geste ; le serveur choisit la cible devant le
	joueur, verifie la portee, les temps de recharge et l'etat (au sol, porte,
	cache). Les bots passent par le meme `gesture`.

	Les elans passent par un LinearVelocity dont la limite de force est coupee :
	l'Humanoid mange les coups de vitesse horizontaux (Arena). Au sol, le corps
	reste droit et immobile : c'est l'animation K.O. qui le couche
	(PostureView). En PlatformStand, il basculait ET l'animation le couchait :
	la tete passait sous le sol (vu en sonde). Seul celui qu'on porte est en
	PlatformStand (il est soude a son porteur).
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))
local Melee = require(Royale:WaitForChild("Melee"))

local EyeService = require(script.Parent.EyeService)
local HidingService = require(script.Parent.HidingService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Roster = require(script.Parent.Roster)
local Sfx = require(script.Parent.Sfx)

local CombatService = {}

local C = Config.combat
local Mv = Config.movement

type Carry =
	{ target: Roster.Actor, weld: WeldConstraint, liftedAt: number, massless: { BasePart } }

local states: { [Roster.Actor]: Melee.State } = {}
local cooldowns: { [Roster.Actor]: { [string]: number } } = {}
local carries: { [Roster.Actor]: Carry } = {}
local carriedBy: { [Roster.Actor]: Roster.Actor } = {}
-- Qui l'a frappe en dernier, et quand (les bots rendent les coups).
local attackers: { [Roster.Actor]: { by: Roster.Actor, at: number } } = {}
-- Glissade en cours : jusqu'a quand, et qui elle a deja fauche.
local slides: { [Roster.Actor]: { untilT: number, hit: { [Roster.Actor]: boolean } } } = {}

local function stateOf(actor: Roster.Actor): Melee.State
	local s = states[actor]
	if s == nil then
		s = Melee.new()
		states[actor] = s
	end
	return s
end

local function ready(actor: Roster.Actor, name: string, seconds: number): boolean
	local now = os.clock()
	local c = cooldowns[actor]
	if c == nil then
		c = {}
		cooldowns[actor] = c
	end
	if now < (c[name] or -math.huge) then
		return false
	end
	c[name] = now + seconds
	return true
end

local function humanoidOf(actor: Roster.Actor): Humanoid?
	local character = Roster.characterOf(actor)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function isDown(actor: Roster.Actor): boolean
	local s = states[actor]
	return s ~= nil and Melee.isDown(s, os.clock())
end

local function flatSpeed(root: BasePart): number
	local v = root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude
end

-- L'arene du goulag (GoulagService) : ceux qui s'y battent sans etre en vie
-- dans la partie, et ses regles (K.O. plus court, un coup a terre ejecte).
local arena: (() -> { Roster.Actor })? = nil
local arenaRules: any = nil

local function inArena(actor: Roster.Actor): boolean
	return arena ~= nil and table.find(arena(), actor) ~= nil
end

-- En jeu : en vie dans la partie, ou au goulag.
local function active(actor: Roster.Actor): boolean
	return Roster.isAlive(actor) or inArena(actor)
end

-- Tous ceux qu'un geste peut toucher.
local function pool(): { Roster.Actor }
	local out = Roster.alive()
	if arena then
		for _, actor in arena() do
			table.insert(out, actor)
		end
	end
	return out
end

-- Peut agir : en jeu, debout, pas porte, pas cache.
local function free(actor: Roster.Actor): boolean
	return active(actor)
		and not isDown(actor)
		and carriedBy[actor] == nil
		and not HidingService.isHidden(actor)
end

-- Publie l'etat au sol sur le participant et pose le corps.
local function publish(actor: Roster.Actor)
	local s = stateOf(actor)
	local now = os.clock()
	local down = Melee.isDown(s, now)
	actor:SetAttribute(
		C.downAttribute,
		if down then workspace:GetServerTimeNow() + (s.downUntil - now) else nil
	)
	actor:SetAttribute(C.koAttribute, if down and s.knockedOut then true else nil)
	local humanoid = humanoidOf(actor)
	if humanoid then
		humanoid.PlatformStand = carriedBy[actor] ~= nil
		-- Un bot au sol ne marche plus (un joueur, son client s'en charge).
		if not actor:IsA("Player") then
			humanoid.WalkSpeed = if down then 0 else Mv.walkSpeed
		end
	end
end

local function impulse(root: BasePart, velocity: Vector3)
	local attachment = Instance.new("Attachment")
	attachment.Name = "RoyaleElan"
	attachment.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = attachment
	lv.ForceLimitsEnabled = false
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = velocity
	lv.Parent = attachment
	Debris:AddItem(attachment, C.impulseSeconds)
end

local function flatLook(root: BasePart): { x: number, z: number }
	local look = root.CFrame.LookVector
	return { x = look.X, z = look.Z }
end

-- Les cibles possibles : en vie, pas cachees, pas portees, pas soi.
local function candidates(
	self: Roster.Actor,
	filter: ((Roster.Actor) -> boolean)?
): ({ Melee.Candidate }, { [string]: Roster.Actor })
	local list: { Melee.Candidate } = {}
	local byId: { [string]: Roster.Actor } = {}
	for _, actor in pool() do
		if
			actor == self
			or HidingService.isHidden(actor)
			-- Dans un cocon : on frappe le cocon, pas lui.
			or actor:GetAttribute(Config.squads.cocoonAttribute) == true
			or carriedBy[actor] ~= nil
			or (filter and not filter(actor))
		then
			continue
		end
		local root = Roster.rootOf(actor)
		if root then
			local id = Roster.idOf(actor)
			byId[id] = actor
			table.insert(
				list,
				{ id = id, x = root.Position.X, y = root.Position.Y, z = root.Position.Z }
			)
		end
	end
	return list, byId
end

local function targetInFront(
	actor: Roster.Actor,
	root: BasePart,
	range: number,
	filter: ((Roster.Actor) -> boolean)?
): Roster.Actor?
	local list, byId = candidates(actor, filter)
	local p = root.Position
	local id =
		Melee.pickTarget({ x = p.X, y = p.Y, z = p.Z }, flatLook(root), list, range, C.hitCone)
	return if id then byId[id] else nil
end

-- Le fait tomber `seconds` et le pousse de `push` (studs/s), s'il en a un.
-- Sous adrenaline, on se releve plus vite.
local function knockDown(actor: Roster.Actor, seconds: number, push: Vector3?)
	local adrenaline = actor:GetAttribute(Config.effects.adrenalineAttribute)
	if typeof(adrenaline) == "number" and workspace:GetServerTimeNow() < adrenaline then
		seconds *= Config.items.adrenaline.fallFactor
	end
	states[actor] = Melee.fall(stateOf(actor), os.clock(), seconds)
	-- Tombe : il n'est plus allonge (il se relevera debout).
	actor:SetAttribute(C.proneAttribute, nil)
	publish(actor)
	local root = Roster.rootOf(actor)
	if root and push then
		impulse(root, push)
	end
end

local function release(carrier: Roster.Actor, velocity: Vector3?)
	local carry = carries[carrier]
	if carry == nil then
		return
	end
	carries[carrier] = nil
	carriedBy[carry.target] = nil
	carry.weld:Destroy()
	for _, part in carry.massless do
		part.Massless = false
	end
	carrier:SetAttribute(C.carryingAttribute, nil)
	carry.target:SetAttribute(C.carriedAttribute, nil)
	local root = Roster.rootOf(carry.target)
	local carrierRoot = Roster.rootOf(carrier)
	if root then
		if carrierRoot then
			-- Pose devant soi, pas dans sa propre tete.
			root.CFrame = carrierRoot.CFrame * CFrame.new(0, 1, -3)
		end
		if root:CanSetNetworkOwnership() then
			root:SetNetworkOwner(if carry.target:IsA("Player") then carry.target else nil)
		end
	end
	knockDown(carry.target, C.thrownFall, velocity)
end

local function lift(carrier: Roster.Actor, target: Roster.Actor)
	local carrierRoot = Roster.rootOf(carrier)
	local root = Roster.rootOf(target)
	local character = Roster.characterOf(target)
	if carrierRoot == nil or root == nil or character == nil then
		return
	end
	local massless: { BasePart } = {}
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") and not d.Massless then
			d.Massless = true
			table.insert(massless, d)
		end
	end
	root.Anchored = false
	if root:CanSetNetworkOwnership() then
		root:SetNetworkOwner(if carrier:IsA("Player") then carrier else nil)
	end
	-- Allonge au-dessus de la tete, en travers des epaules.
	root.CFrame = carrierRoot.CFrame
		* CFrame.new(0, C.carryHeight, 0)
		* CFrame.Angles(0, math.pi / 2, math.pi / 2)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "RoyalePorte"
	weld.Part0 = carrierRoot
	weld.Part1 = root
	weld.Parent = carrierRoot
	carries[carrier] = { target = target, weld = weld, liftedAt = os.clock(), massless = massless }
	carriedBy[target] = carrier
	carrier:SetAttribute(C.carryingAttribute, Roster.nameOf(target))
	target:SetAttribute(C.carriedAttribute, true)
	publish(target)
end

-- Ce qu'on peut frapper sans que ce soit un participant (les Repris, les
-- cocons) : chaque source donne sa liste et ce qu'un coup leur fait.
export type Creature = {
	id: string,
	root: BasePart,
	onHit: (id: string, by: Roster.Actor, push: Vector3) -> (),
}
local creatureSources: { () -> { Creature } } = {}

function CombatService.addCreatures(list: () -> { Creature })
	table.insert(creatureSources, list)
end

-- Une creature devant soi, a portee de coup.
local function creatureInFront(root: BasePart): Creature?
	local list: { Melee.Candidate } = {}
	local byId: { [string]: Creature } = {}
	for _, source in creatureSources do
		for _, c in source() do
			byId[c.id] = c
			local p = c.root.Position
			table.insert(list, { id = c.id, x = p.X, y = p.Y, z = p.Z })
		end
	end
	local p = root.Position
	local id =
		Melee.pickTarget({ x = p.X, y = p.Y, z = p.Z }, flatLook(root), list, C.hitRange, C.hitCone)
	return if id then byId[id] else nil
end

local function hit(actor: Roster.Actor, root: BasePart)
	if not ready(actor, "hit", C.hitCooldown) then
		return
	end
	local target = targetInFront(actor, root, C.hitRange)
	-- Un Repris plus proche qu'un participant prend le coup.
	local creature = creatureInFront(root)
	if creature then
		local targetRoot = target and Roster.rootOf(target)
		local cd = (creature.root.Position - root.Position).Magnitude
		if targetRoot == nil or cd < (targetRoot.Position - root.Position).Magnitude then
			local away = creature.root.Position - root.Position
			away = Vector3.new(away.X, 0, away.Z)
			local push = if away.Magnitude > 0 then away.Unit else Vector3.zero
			creature.onHit(creature.id, actor, push)
			-- Se battre fait du bruit (CONCEPT.md).
			EyeService.noise(creature.root.Position, C.hitNoiseSeconds, false)
			Sfx.at("coup", creature.root)
			return
		end
	end
	if target and arenaRules and inArena(actor) and isDown(target) then
		-- Au goulag, un coup sur quelqu'un a terre l'envoie voler (CONCEPT.md).
		local targetRoot = Roster.rootOf(target)
		if targetRoot then
			local away = targetRoot.Position - root.Position
			away = Vector3.new(away.X, 0, away.Z)
			local dir = if away.Magnitude > 0 then away.Unit else root.CFrame.LookVector
			attackers[target] = { by = actor, at = os.clock() }
			impulse(
				targetRoot,
				dir * arenaRules.launchSpeed + Vector3.new(0, arenaRules.launchLift, 0)
			)
		end
		return
	end
	if target then
		local now = os.clock()
		-- La batte : K.O. en moins de coups, tant qu'il lui en reste.
		local bat = actor:GetAttribute(Config.effects.batAttribute)
		local rules = C
		if arenaRules and inArena(actor) then
			rules = arenaRules
		end
		if typeof(bat) == "number" and bat > 0 then
			rules = {
				hitsToKO = Config.items.bat.hitsToKO,
				comboResetSeconds = C.comboResetSeconds,
				koSeconds = C.koSeconds,
			}
			actor:SetAttribute(Config.effects.batAttribute, if bat > 1 then bat - 1 else nil)
		end
		local s, ko = Melee.hit(stateOf(target), now, rules)
		states[target] = s
		attackers[target] = { by = actor, at = now }
		publish(target)
		local targetRoot = Roster.rootOf(target)
		if targetRoot then
			local away = targetRoot.Position - root.Position
			away = Vector3.new(away.X, 0, away.Z)
			if away.Magnitude > 0 then
				impulse(targetRoot, away.Unit * C.hitPush)
			end
			EyeService.noise(targetRoot.Position, C.hitNoiseSeconds, false)
			Sfx.at("coup", targetRoot)
		end
		if ko then
			print(
				string.format(
					"[Royale] %s met %s K.O.",
					Roster.nameOf(actor),
					Roster.nameOf(target)
				)
			)
		end
		return
	end
	-- Personne devant : on toque a l'abri le plus proche.
	local spot, at = HidingService.spotNear(root.Position, C.knockRange)
	if spot and at and ready(actor, "knock", C.knockCooldown) then
		EyeService.noise(at, C.knockNoiseSeconds, true)
	end
end

local function shove(actor: Roster.Actor, root: BasePart)
	local look = root.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z).Unit
	if flatSpeed(root) > Mv.runningAbove then
		if not ready(actor, "tackle", C.tackleCooldown) then
			return
		end
		local target = targetInFront(actor, root, C.tackleRange, function(a)
			return not isDown(a)
		end)
		if target then
			knockDown(target, C.tackleTargetFall, forward * C.tackleLunge)
		end
		-- Plaquer, c'est tomber aussi, meme dans le vide.
		knockDown(actor, C.tackleSelfFall, forward * C.tackleLunge)
		return
	end
	if not ready(actor, "shove", C.shoveCooldown) then
		return
	end
	local target = targetInFront(actor, root, C.shoveRange)
	if target then
		local targetRoot = Roster.rootOf(target)
		if targetRoot then
			impulse(targetRoot, forward * C.shoveSpeed + Vector3.new(0, C.shoveLift, 0))
		end
		return
	end
	-- Sur un abri : on deloge celui qui y est.
	local spot = HidingService.spotNear(root.Position, Config.hiding.promptDistance)
	if spot then
		local out = HidingService.evict(spot)
		local outRoot = out and Roster.rootOf(out)
		if outRoot then
			impulse(outRoot, forward * C.shoveSpeed + Vector3.new(0, C.shoveLift, 0))
		end
	end
end

local function burstOut(actor: Roster.Actor)
	if not HidingService.isHidden(actor) then
		return
	end
	HidingService.leave(actor)
	local root = Roster.rootOf(actor)
	if root == nil then
		return
	end
	for _, other in Roster.alive() do
		local otherRoot = Roster.rootOf(other)
		if other ~= actor and otherRoot and not HidingService.isHidden(other) then
			local away = otherRoot.Position - root.Position
			if away.Magnitude <= C.burstRange then
				local flat = Vector3.new(away.X, 0, away.Z)
				knockDown(
					other,
					C.burstFall,
					if flat.Magnitude > 0 then flat.Unit * C.shoveSpeed else nil
				)
			end
		end
	end
end

-- Un geste d'un participant (joueur par le remote, bot directement).
function CombatService.gesture(actor: Roster.Actor, name: string)
	if name == "burst" then
		if Roster.isAlive(actor) and not isDown(actor) then
			burstOut(actor)
		end
		return
	end
	if not free(actor) then
		return
	end
	local root = Roster.rootOf(actor)
	if root == nil then
		return
	end
	local carry = carries[actor]
	if carry then
		local look = root.CFrame.LookVector
		local forward = Vector3.new(look.X, 0, look.Z).Unit
		if name == "throw" then
			release(actor, forward * C.throwSpeed + Vector3.new(0, C.throwLift, 0))
		elseif name == "drop" then
			release(actor, nil)
		end
		return
	end
	if name == "hit" then
		hit(actor, root)
	elseif name == "shove" then
		shove(actor, root)
	elseif name == "carry" then
		local target = targetInFront(actor, root, C.carryRange, function(a)
			local s = states[a]
			return s ~= nil and s.knockedOut and Melee.isDown(s, os.clock())
		end)
		if target then
			lift(actor, target)
		end
	elseif name == "slide" then
		if flatSpeed(root) > Mv.runningAbove and ready(actor, "slide", Mv.slideCooldown) then
			slides[actor] = { untilT = os.clock() + Mv.slideSeconds, hit = {} }
		end
	elseif name == "crouch" then
		actor:SetAttribute(C.crouchAttribute, true)
	elseif name == "uncrouch" then
		actor:SetAttribute(C.crouchAttribute, nil)
	elseif name == "prone" then
		actor:SetAttribute(C.crouchAttribute, nil)
		actor:SetAttribute(C.proneAttribute, true)
	elseif name == "stand" then
		actor:SetAttribute(C.proneAttribute, nil)
	end
end

-- Tirer par les pieds : `target` est allonge, `puller` le sort a
-- decouvert, vers lui, et il est au sol un instant (CONCEPT.md).
function CombatService.pull(puller: Roster.Actor, target: Roster.Actor)
	local a, b = Roster.rootOf(puller), Roster.rootOf(target)
	if
		not free(puller)
		or not active(target)
		or target:GetAttribute(C.proneAttribute) ~= true
		or a == nil
		or b == nil
		or (a.Position - b.Position).Magnitude > C.pull.distance + 2
	then
		return
	end
	target:SetAttribute(C.proneAttribute, nil)
	local toward = Vector3.new(a.Position.X - b.Position.X, 0, a.Position.Z - b.Position.Z)
	local step = if toward.Magnitude > 0
		then toward.Unit * math.min(C.pull.back, toward.Magnitude)
		else Vector3.zero
	local character = Roster.characterOf(target)
	if character then
		character:PivotTo(character:GetPivot() + step)
	end
	knockDown(target, C.pull.fall, nil)
	print(
		string.format(
			"[Royale] %s tire %s par les pieds",
			Roster.nameOf(puller),
			Roster.nameOf(target)
		)
	)
end

-- Renverse depuis un objet (bouteille, filet, huile, piege) : comme un
-- plaquage, sans K.O.
function CombatService.trip(actor: Roster.Actor, seconds: number, push: Vector3?)
	if active(actor) and carriedBy[actor] == nil then
		knockDown(actor, seconds, push)
	end
end

-- Le goulag declare ses combattants et ses regles (hitsToKO,
-- comboResetSeconds, koSeconds, launchSpeed, launchLift).
function CombatService.setArena(list: () -> { Roster.Actor }, rules: any)
	arena, arenaRules = list, rules
end

-- Remet a zero l'etat de combat d'un participant (sorti du goulag).
function CombatService.reset(actor: Roster.Actor)
	states[actor] = nil
	attackers[actor] = nil
	publish(actor)
end

-- Pousse sans renverser (le souffle de l'Oeil).
function CombatService.push(actor: Roster.Actor, velocity: Vector3)
	local root = Roster.rootOf(actor)
	if root and active(actor) and carriedBy[actor] == nil and not root.Anchored then
		impulse(root, velocity)
	end
end

function CombatService.isDown(actor: Roster.Actor): boolean
	return isDown(actor)
end

-- Celui qui l'a frappe il y a moins de `within` secondes, s'il y en a un.
function CombatService.attackerOf(actor: Roster.Actor, within: number): Roster.Actor?
	local a = attackers[actor]
	if a and os.clock() - a.at <= within and active(a.by) then
		return a.by
	end
	return nil
end

function CombatService.isCarried(actor: Roster.Actor): boolean
	return carriedBy[actor] ~= nil
end

-- Entre deux parties : tout le monde debout, personne ne porte personne.
function CombatService.clear()
	for carrier in carries do
		release(carrier, nil)
	end
	for actor in states do
		if actor.Parent then
			actor:SetAttribute(C.downAttribute, nil)
			actor:SetAttribute(C.koAttribute, nil)
		end
	end
	table.clear(states)
	table.clear(attackers)
	table.clear(cooldowns)
	table.clear(slides)
end

local function step()
	local now = os.clock()
	-- Les porteurs : le K.O. dure tant qu'on le porte, jusqu'a sa limite.
	for carrier, carry in carries do
		local target = carry.target
		if
			not Roster.isAlive(carrier)
			or isDown(carrier)
			or not Roster.isAlive(target)
			or Roster.rootOf(target) == nil
		then
			release(carrier, nil)
			continue
		end
		states[target] =
			Melee.holdDown(stateOf(target), now, carry.liftedAt, C.carryMaxSeconds, C.carryRefresh)
		if not Melee.isDown(states[target], now + C.stepSeconds) then
			-- Il se debat et tombe.
			release(carrier, nil)
		end
	end
	-- Les tacles glisses : la glissade fauche qui elle traverse.
	for actor, slide in slides do
		local root = Roster.rootOf(actor)
		if now > slide.untilT or root == nil or not free(actor) then
			slides[actor] = nil
			continue
		end
		local target = targetInFront(actor, root, C.slideTackleRange, function(a)
			return not slide.hit[a] and not isDown(a)
		end)
		if target then
			slide.hit[target] = true
			knockDown(target, C.slideTackleFall, nil)
		end
	end
	-- Ceux qui se relevent.
	for actor, s in states do
		if actor.Parent == nil then
			states[actor] = nil
		elseif actor:GetAttribute(C.downAttribute) ~= nil and not Melee.isDown(s, now) then
			publish(actor)
		end
	end
end

function CombatService.start(gestureRemote: RemoteEvent)
	gestureRemote.OnServerEvent:Connect(
		RemoteGuard.wrap(Config.remotes.gesture, function(player: Player, name: any)
			if typeof(name) == "string" then
				CombatService.gesture(player, name)
			end
		end)
	)
	-- Aspire en portant, ou porte : on lache tout avant de monter.
	Roster.onBeforeTake(function(actor: Roster.Actor)
		release(actor, nil)
		local carrier = carriedBy[actor]
		if carrier then
			release(carrier, nil)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		release(player, nil)
		local carrier = carriedBy[player]
		if carrier then
			release(carrier, nil)
		end
		states[player] = nil
		attackers[player] = nil
		cooldowns[player] = nil
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc >= C.stepSeconds then
			acc = 0
			step()
		end
	end)
end

return CombatService
