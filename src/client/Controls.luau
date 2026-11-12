--!strict
--[[
	Controls — le corps et les gestes. Les boutons viennent de
	Config.controls, jamais d'ici.

	- Courir : L3 bascule (Maj maintenu au clavier).
	- B : en courant, glisser (le serveur fauche qui est devant) ; a l'arret,
	  s'accroupir. En portant quelqu'un : le poser.
	- A en l'air pres d'un rebord : s'agripper et se hisser.
	- R2 : frapper (ou toquer a un abri) ; cache : sortir en force.
	- Y : pousser, ou plaquer en courant ; maintenu sur un K.O. : le porter ;
	  en portant : le jeter.
	- X cache : sortir.

	La vitesse, la hauteur, la glissade et l'escalade se font sur le client :
	c'est lui qui fait bouger son personnage. Le serveur decide des coups et
	publie `AuSol` (renverse) et `Porte` (on porte quelqu'un) : on les tient ici.
	Accroupi, la tete descend vraiment : derriere un muret, l'Oeil (qui vise la
	tete et le bassin) ne te voit plus.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local Controls = {}

local onFoot = Config.controls.contexts.onFoot
local carryingCtx = Config.controls.contexts.carrying
local hiddenCtx = Config.controls.contexts.hidden
local Mv = Config.movement
local C = Config.combat

type Binding = { gamepad: string, keyboard: string }

local function keys(binding: Binding): { Enum.KeyCode | Enum.UserInputType }
	local out: { Enum.KeyCode | Enum.UserInputType } = {}
	for _, name in { binding.gamepad, binding.keyboard } do
		local ok, code = pcall(function()
			return (Enum.KeyCode :: any)[name]
		end)
		if ok and code then
			table.insert(out, code)
		else
			table.insert(out, (Enum.UserInputType :: any)[name])
		end
	end
	return out
end

-- Deux contextes peuvent partager un bouton (Y pousse a pied, jette en
-- portant) : une seule liaison par bouton, et la situation choisit l'action.
local function merged(bindings: { Binding }): { Enum.KeyCode | Enum.UserInputType }
	local seen: { [any]: boolean } = {}
	local out: { Enum.KeyCode | Enum.UserInputType } = {}
	for _, binding in bindings do
		for _, k in keys(binding) do
			if not seen[k] then
				seen[k] = true
				table.insert(out, k)
			end
		end
	end
	return out
end

function Controls.start()
	local player = Players.LocalPlayer
	local remotes = Royale:WaitForChild(Config.remotes.folder)
	local leaveRemote = remotes:WaitForChild(Config.remotes.leave) :: RemoteEvent
	local gestureRemote = remotes:WaitForChild(Config.remotes.gesture) :: RemoteEvent

	local running = false
	local crouched = false
	local sliding = false
	local mantling = false
	local baseHip: number? = nil
	local slideCooldownUntil = 0

	local function parts(): (Humanoid?, BasePart?)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return humanoid, if root and root:IsA("BasePart") then root else nil
	end

	local function isDown(): boolean
		local down = player:GetAttribute(C.downAttribute)
		return typeof(down) == "number" and workspace:GetServerTimeNow() < down
	end

	local function carrying(): boolean
		return player:GetAttribute(C.carryingAttribute) ~= nil
	end

	local function hidden(): boolean
		return player:GetAttribute(Config.hiding.hiddenAttribute) ~= nil
	end

	local function flatSpeed(root: BasePart): number
		local v = root.AssemblyLinearVelocity
		return Vector3.new(v.X, 0, v.Z).Magnitude
	end

	-- La vitesse et la hauteur, d'apres la posture et ce que dit le serveur.
	local function apply()
		local humanoid = parts()
		if humanoid == nil then
			return
		end
		if baseHip == nil then
			baseHip = humanoid.HipHeight
		end
		local down = isDown() or player:GetAttribute(C.carriedAttribute) ~= nil
		local adrenaline = player:GetAttribute(Config.effects.adrenalineAttribute)
		local rushing = typeof(adrenaline) == "number" and workspace:GetServerTimeNow() < adrenaline
		humanoid.PlatformStand = down
		humanoid.WalkSpeed = if down
			then 0
			elseif rushing then Mv.runSpeed
			elseif carrying() then C.carrySpeed
			elseif crouched then Mv.crouchSpeed
			elseif running then Mv.runSpeed
			else Mv.walkSpeed
		local drop = if sliding then Mv.slideHipDrop elseif crouched then Mv.crouchHipDrop else 0
		humanoid.HipHeight = (baseHip :: number) - drop
	end

	player.CharacterAdded:Connect(function()
		running, crouched, sliding, mantling, baseHip = false, false, false, false, nil
		task.defer(apply)
	end)
	for _, attribute in
		{
			C.downAttribute,
			C.carryingAttribute,
			C.carriedAttribute,
			Config.effects.adrenalineAttribute,
		}
	do
		player:GetAttributeChangedSignal(attribute):Connect(apply)
	end
	-- `AuSol` porte une heure de fin : on se releve quand elle passe, meme si
	-- le serveur n'a pas encore efface l'attribut.
	-- De meme pour la fin de l'adrenaline.
	local wasDown, wasRushing = false, false
	RunService.Heartbeat:Connect(function()
		local down = isDown()
		local adrenaline = player:GetAttribute(Config.effects.adrenalineAttribute)
		local rushing = typeof(adrenaline) == "number" and workspace:GetServerTimeNow() < adrenaline
		if down ~= wasDown or rushing ~= wasRushing then
			wasDown, wasRushing = down, rushing
			apply()
		end
	end)

	local function slide(humanoid: Humanoid, root: BasePart)
		sliding, crouched = true, false
		slideCooldownUntil = os.clock() + Mv.slideCooldown
		gestureRemote:FireServer("slide")
		local dir = humanoid.MoveDirection
		if dir.Magnitude < 0.1 then
			dir = root.CFrame.LookVector
		end
		dir = Vector3.new(dir.X, 0, dir.Z).Unit
		local attachment = Instance.new("Attachment")
		attachment.Name = "RoyaleGlisse"
		attachment.Parent = root
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = attachment
		lv.ForceLimitsEnabled = false
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
		lv.LineDirection = dir
		lv.LineVelocity = Mv.slideSpeed
		lv.Parent = attachment
		apply()
		local started = os.clock()
		local connection: RBXScriptConnection? = nil
		connection = RunService.Heartbeat:Connect(function()
			local t = (os.clock() - started) / Mv.slideSeconds
			if t >= 1 or isDown() or not attachment.Parent then
				if connection then
					connection:Disconnect()
				end
				attachment:Destroy()
				sliding = false
				apply()
				return
			end
			-- L'elan retombe vers la course.
			lv.LineVelocity = Mv.slideSpeed + (Mv.runSpeed - Mv.slideSpeed) * t
		end)
	end

	-- S'agripper : un mur devant a hauteur de poitrine, un dessus a portee,
	-- et la place de s'y tenir debout. On se hisse en `mantleSeconds`.
	local function tryMantle(humanoid: Humanoid, root: BasePart): boolean
		local state = humanoid:GetState()
		if state ~= Enum.HumanoidStateType.Freefall and state ~= Enum.HumanoidStateType.Jumping then
			return false
		end
		local look = root.CFrame.LookVector
		local forward = Vector3.new(look.X, 0, look.Z)
		if forward.Magnitude < 0.1 then
			return false
		end
		forward = forward.Unit
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character :: Instance }
		params.RespectCanCollide = true
		local feetOffset = humanoid.HipHeight + root.Size.Y / 2
		local feet = root.Position.Y - feetOffset
		local wall = workspace:Raycast(root.Position, forward * Mv.mantleReach, params)
		if wall == nil then
			return false
		end
		local above = Vector3.new(wall.Position.X, feet + Mv.mantleHeight + 1, wall.Position.Z)
			+ forward
		local top = workspace:Raycast(above, Vector3.new(0, -(Mv.mantleHeight + 1), 0), params)
		if top == nil or top.Position.Y <= feet + 1 or top.Normal.Y < 0.7 then
			return false
		end
		local standAt = top.Position + Vector3.new(0, feetOffset, 0)
		local headroom = workspace:Raycast(
			top.Position + Vector3.new(0, 0.2, 0),
			Vector3.new(0, feetOffset * 2, 0),
			params
		)
		if headroom then
			return false
		end
		mantling = true
		local from = root.CFrame.Position
		root.Anchored = true
		local started = os.clock()
		local connection: RBXScriptConnection? = nil
		connection = RunService.Heartbeat:Connect(function()
			local t = math.min((os.clock() - started) / Mv.mantleSeconds, 1)
			-- D'abord monter, puis passer par-dessus le rebord.
			local up = from:Lerp(Vector3.new(from.X, standAt.Y, from.Z), math.min(t * 2, 1))
			local over = up:Lerp(standAt, math.max(t * 2 - 1, 0))
			root.CFrame = CFrame.lookAt(over, over + forward)
			if t >= 1 then
				if connection then
					connection:Disconnect()
				end
				root.Anchored = false
				root.AssemblyLinearVelocity = Vector3.zero
				mantling = false
			end
		end)
		return true
	end

	ContextActionService:BindAction(
		"RoyaleCourir",
		function(_, state: Enum.UserInputState, input: InputObject)
			if input.KeyCode == Enum.KeyCode[onFoot.sprint.gamepad] then
				-- A la manette : bascule.
				if state == Enum.UserInputState.Begin then
					running = not running
					crouched = false
				end
			else
				running = state == Enum.UserInputState.Begin
				if running then
					crouched = false
				end
			end
			apply()
			return Enum.ContextActionResult.Pass
		end,
		false,
		table.unpack(keys(onFoot.sprint))
	)

	-- B : glisser en courant, s'accroupir a l'arret, poser en portant.
	ContextActionService:BindAction("RoyalePosture", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if carrying() then
			gestureRemote:FireServer("drop")
			return Enum.ContextActionResult.Sink
		end
		local humanoid, root = parts()
		if humanoid == nil or root == nil or isDown() or sliding or mantling then
			return Enum.ContextActionResult.Pass
		end
		if flatSpeed(root) > Mv.runningAbove and os.clock() >= slideCooldownUntil then
			slide(humanoid, root)
		else
			crouched = not crouched
			if crouched then
				running = false
			end
			apply()
		end
		return Enum.ContextActionResult.Pass
	end, false, table.unpack(merged({ onFoot.posture, carryingCtx.putDown })))

	-- A : le saut reste a Roblox ; en l'air pres d'un rebord, on s'agrippe.
	ContextActionService:BindAction("RoyaleRebord", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin or mantling then
			return Enum.ContextActionResult.Pass
		end
		local humanoid, root = parts()
		if humanoid and root and not isDown() and not carrying() and tryMantle(humanoid, root) then
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, table.unpack(keys(onFoot.jump)))

	-- R2 : frapper ; cache, sortir en force (la porte dans la figure).
	ContextActionService:BindAction("RoyaleFrapper", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if hidden() then
			gestureRemote:FireServer("burst")
		elseif not isDown() then
			gestureRemote:FireServer("hit")
		end
		return Enum.ContextActionResult.Pass
	end, false, table.unpack(merged({ onFoot.hit, hiddenCtx.burstOut })))

	-- Y : pousser / plaquer ; maintenu pres d'un K.O., le porter ; en
	-- portant, le jeter. Sans K.O. a portee, la poussee part tout de suite.
	local holdToken = 0
	local holding = false
	local function knockedOutNear(): boolean
		local _, root = parts()
		if root == nil then
			return false
		end
		local function near(model: Instance?): boolean
			local other = model and model:FindFirstChild("HumanoidRootPart")
			return other ~= nil
				and other:IsA("BasePart")
				and (other.Position - root.Position).Magnitude <= C.carryRange
		end
		for _, other in Players:GetPlayers() do
			if
				other ~= player
				and other:GetAttribute(C.koAttribute) == true
				and near(other.Character)
			then
				return true
			end
		end
		local bots = workspace:FindFirstChild(Config.bots.folder)
		if bots then
			for _, bot in bots:GetChildren() do
				if bot:GetAttribute(C.koAttribute) == true and near(bot) then
					return true
				end
			end
		end
		return false
	end
	ContextActionService:BindAction("RoyalePousser", function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			if carrying() then
				gestureRemote:FireServer("throw")
				return Enum.ContextActionResult.Sink
			end
			if isDown() or hidden() then
				return Enum.ContextActionResult.Pass
			end
			if not knockedOutNear() then
				gestureRemote:FireServer("shove")
				return Enum.ContextActionResult.Sink
			end
			holdToken += 1
			holding = true
			local token = holdToken
			task.delay(C.carryHoldSeconds, function()
				if holding and token == holdToken then
					holding = false
					gestureRemote:FireServer("carry")
				end
			end)
		elseif state == Enum.UserInputState.End and holding then
			holding = false
			gestureRemote:FireServer("shove")
		end
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(merged({ onFoot.shove, carryingCtx.throw })))

	-- Sortir : seulement quand on est cache (sinon X sert aux invites).
	ContextActionService:BindAction("RoyaleSortir", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if not hidden() then
			return Enum.ContextActionResult.Pass
		end
		leaveRemote:FireServer()
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(keys(hiddenCtx.leave)))
end

return Controls
