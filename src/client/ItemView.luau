--!strict
--[[
	ItemView — le sac a l'ecran et ce que les objets montrent.

	- En bas : les 4 places (CONCEPT.md : pas de panneau de sac), la place
	  choisie encadree, sa couleur de rarete. L1 / R1 pour choisir.
	- L2 : un objet a lancer se vise tant qu'on tient (le trait de l'arc), et
	  part au lacher ; les autres servent a l'appui.
	- Les effets : lancers des autres, ebloui, joueurs reveles (Jumelles, Oeil
	  de verre), grappin, Regard vole, clochettes, relique, messages.

	Rien ne se decide ici : le serveur publie, l'ecran montre.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Bag = require(Royale:WaitForChild("Bag"))
local Config = require(Royale:WaitForChild("Config"))
local Throw = require(Royale:WaitForChild("Throw"))

local ItemView = {}

local BG = Config.bag
local T = Config.throw
local I = Config.items
local FX = Config.effects
local V = Config.view
local onFoot = Config.controls.contexts.onFoot
local hiddenCtx = Config.controls.contexts.hidden

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function keys(binding: { gamepad: string, keyboard: string }): { any }
	local out: { any } = {}
	for _, name in { binding.gamepad, binding.keyboard } do
		local ok, code = pcall(function()
			return (Enum.KeyCode :: any)[name]
		end)
		table.insert(out, if ok and code then code else (Enum.UserInputType :: any)[name])
	end
	return out
end

local function merged(list: { { gamepad: string, keyboard: string } }): { any }
	local seen: { [any]: boolean } = {}
	local out: { any } = {}
	for _, binding in list do
		for _, k in keys(binding) do
			if not seen[k] then
				seen[k] = true
				table.insert(out, k)
			end
		end
	end
	return out
end

local function active(instance: Instance, attribute: string): number?
	local untilT = instance:GetAttribute(attribute)
	if typeof(untilT) == "number" then
		local left = untilT - workspace:GetServerTimeNow()
		if left > 0 then
			return left
		end
	end
	return nil
end

-- « texte|heure » : le texte, s'il date de moins de `seconds`.
local function recent(value: any, seconds: number): string?
	if typeof(value) ~= "string" then
		return nil
	end
	local text, at = string.match(value, "^(.*)|([%d%.]+)$")
	if text and at and workspace:GetServerTimeNow() - (tonumber(at) :: number) < seconds then
		return text
	end
	return nil
end

local function textLabel(
	parent: Instance,
	size: UDim2,
	position: UDim2,
	textSize: number
): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = position
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Font = (Enum.Font :: any)[V.font]
	l.TextSize = textSize
	l.TextColor3 = Color3.fromRGB(240, 232, 220)
	l.TextStrokeTransparency = 0.4
	l.TextWrapped = true
	-- Le texte retrecit plutot que deborder (un petit ecran, un long nom).
	l.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = textSize
	limit.Parent = l
	l.Text = ""
	l.Parent = parent
	return l
end

function ItemView.start()
	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera
	local remotes = Royale:WaitForChild(Config.remotes.folder)
	local itemRemote = remotes:WaitForChild(Config.remotes.item) :: RemoteEvent
	local projectileRemote = remotes:WaitForChild(Config.remotes.projectile) :: RemoteEvent
	local steerRemote = remotes:WaitForChild(Config.remotes.steer) :: RemoteEvent

	local gui = Instance.new("ScreenGui")
	gui.Name = "RoyaleSac"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Les 4 places, en bas au centre. La largeur se deduit du nombre de places.
	local slotW, slotH, gap = V.slotWidth, V.slotHeight, V.slotGap
	local bar = Instance.new("Frame")
	bar.Name = "Places"
	bar.BackgroundTransparency = 1
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Size = UDim2.fromOffset(BG.slots * slotW + (BG.slots - 1) * gap, slotH)
	bar.Position = UDim2.new(0.5, 0, 1, -V.slotBottom)
	bar.Parent = gui
	-- Sur un ecran etroit, la barre retrecit pour tenir (vu en jeu : elle
	-- debordait sur une petite fenetre). L'echelle se deduit de la largeur.
	local fit = Instance.new("UIScale")
	fit.Parent = bar
	local function refit()
		local width = gui.AbsoluteSize.X
		if width > 0 then
			fit.Scale = math.min(1, width * V.slotFitFraction / bar.Size.X.Offset)
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	refit()
	local slots: { { frame: Frame, name: TextLabel, stroke: UIStroke } } = {}
	for i = 1, BG.slots do
		local f = Instance.new("Frame")
		f.Size = UDim2.fromOffset(slotW, slotH)
		f.Position = UDim2.fromOffset((i - 1) * (slotW + gap), 0)
		f.BackgroundColor3 = Color3.fromRGB(20, 14, 14)
		f.BackgroundTransparency = 0.35
		f.BorderSizePixel = 0
		f.Parent = bar
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = f
		local name = textLabel(f, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0), 16)
		table.insert(slots, { frame = f, name = name, stroke = stroke })
	end
	local selectedName = textLabel(
		gui,
		UDim2.new(V.slotFitFraction, 0, 0, 24),
		UDim2.new(0.5, 0, 1, -(V.slotBottom + slotH + 30)),
		20
	)
	local status =
		textLabel(gui, UDim2.new(V.slotFitFraction, 0, 0, 24), UDim2.new(0.5, 0, 1, -190), 20)
	status.TextColor3 = Color3.fromRGB(255, 220, 140)
	local message =
		textLabel(gui, UDim2.new(V.slotFitFraction, 0, 0, 30), UDim2.fromScale(0.5, 0.68), 24)
	local announce =
		textLabel(gui, UDim2.new(V.slotFitFraction, 0, 0, 34), UDim2.fromScale(0.5, 0.2), 26)
	announce.TextColor3 = rgb(Config.rarities.legendary.color)
	local flash = Instance.new("Frame")
	flash.Name = "Ebloui"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 10
	flash.Parent = gui

	local function playing(): boolean
		return workspace:GetAttribute(Config.match.phaseAttribute) == "Partie"
			and player:GetAttribute(Config.match.aliveAttribute) == true
	end

	local function currentBag(): Bag.Bag
		local text = player:GetAttribute(BG.attribute)
		return Bag.decode(if typeof(text) == "string" then text else "", BG.slots)
	end

	local function selectedSlot(): number
		local s = player:GetAttribute(BG.selectedAttribute)
		return if typeof(s) == "number" then s else 1
	end

	-- Le trait de l'arc, pendant qu'on vise.
	local aiming = false
	local dots: { Part } = {}
	for _ = 1, T.previewPoints do
		local d = Instance.new("Part")
		d.Shape = Enum.PartType.Ball
		d.Size = Vector3.one * V.aimDotSize
		d.Material = Enum.Material.Neon
		d.Color = rgb(V.beamColor)
		d.Anchored = true
		d.CanCollide = false
		d.CanQuery = false
		d.CanTouch = false
		d.Transparency = 1
		d.Parent = camera
		table.insert(dots, d)
	end
	local function hideDots()
		for _, d in dots do
			d.Transparency = 1
		end
	end

	ContextActionService:BindAction(
		"RoyaleObjetChoix",
		function(_, state, input: InputObject)
			if state ~= Enum.UserInputState.Begin or not playing() then
				return Enum.ContextActionResult.Pass
			end
			local step = if input.KeyCode == Enum.KeyCode[onFoot.previousItem.gamepad]
					or input.KeyCode == Enum.KeyCode[onFoot.previousItem.keyboard]
				then -1
				else 1
			itemRemote:FireServer("cycle", step)
			return Enum.ContextActionResult.Sink
		end,
		false,
		table.unpack(merged({
			onFoot.previousItem,
			onFoot.nextItem,
			hiddenCtx.previousItem,
			hiddenCtx.nextItem,
		}))
	)

	ContextActionService:BindAction("RoyaleObjetUtiliser", function(_, state)
		if not playing() then
			aiming = false
			hideDots()
			return Enum.ContextActionResult.Pass
		end
		local id = currentBag()[selectedSlot()]
		local def = I[id]
		if state == Enum.UserInputState.Begin then
			if def and def.kind == "throw" then
				aiming = true
			elseif def then
				itemRemote:FireServer("use", camera.CFrame.LookVector)
			end
		elseif state == Enum.UserInputState.End and aiming then
			aiming = false
			hideDots()
			itemRemote:FireServer("use", camera.CFrame.LookVector)
		end
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(keys(onFoot.useItem)))

	-- Les lancers, vus par tous.
	projectileRemote.OnClientEvent:Connect(
		function(id: string, origin: Vector3, velocity: Vector3, flight: number)
			local def = I[id]
			if def == nil then
				return
			end
			local p = Instance.new("Part")
			p.Size = Vector3.one * V.projectileSize
			p.Material = Enum.Material.Neon
			p.Color = rgb(Config.rarities[def.rarity].color)
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Parent = workspace
			local started = os.clock()
			local o = { x = origin.X, y = origin.Y, z = origin.Z }
			local v = { x = velocity.X, y = velocity.Y, z = velocity.Z }
			local connection: RBXScriptConnection? = nil
			connection = RunService.RenderStepped:Connect(function()
				local t = os.clock() - started
				if t >= flight then
					if connection then
						connection:Disconnect()
					end
					p:Destroy()
					return
				end
				local at = Throw.at(o, v, T.gravity, t)
				p.CFrame = CFrame.new(at.x, at.y, at.z)
			end)
		end
	)

	-- Ceux qu'on voit grace aux Jumelles ou a l'Oeil de verre.
	local revealed: { [Model]: Highlight } = {}
	local function characters(): { Model }
		local out: { Model } = {}
		for _, other in Players:GetPlayers() do
			if other ~= player and other.Character then
				table.insert(out, other.Character)
			end
		end
		local bots = workspace:FindFirstChild(Config.bots.folder)
		if bots then
			for _, b in bots:GetChildren() do
				if b:IsA("Model") then
					table.insert(out, b)
				end
			end
		end
		return out
	end
	local function ownerOf(character: Model): Instance
		return Players:GetPlayerFromCharacter(character) or character
	end

	-- Le grappin : monter jusqu'au point donne par le serveur.
	local lastGrapple = 0
	local lastSteer = 0
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		local bag = currentBag()
		local sel = selectedSlot()
		local inMatch = playing()
		bar.Visible = inMatch
		selectedName.Visible = inMatch
		for i, slot in slots do
			local def = I[bag[i]]
			slot.name.Text = if def then def.name else ""
			slot.stroke.Color = if def
				then rgb(Config.rarities[def.rarity].color)
				else Color3.fromRGB(70, 60, 60)
			slot.stroke.Thickness = if i == sel then V.slotSelectedStroke else 1
			slot.frame.BackgroundTransparency = if i == sel then 0.1 else 0.45
		end
		local selDef = I[bag[sel]]
		selectedName.Text = if selDef
			then selDef.name .. (if selDef.kind == "throw"
				then " — L2 maintenu : viser, lâcher : lancer"
				elseif selDef.kind == "passive" then " — agit tout seul"
				else " — L2 : utiliser")
			else ""

		-- Les effets en cours.
		local lines: { string } = {}
		local function add(attribute: string, label: string)
			local left = active(player, attribute)
			if left then
				table.insert(lines, string.format("%s %d s", label, math.ceil(left)))
			end
		end
		add(FX.cloakAttribute, "Cape d'ombre")
		add(FX.adrenalineAttribute, "Adrénaline")
		add(FX.steerAttribute, "Tu diriges un faisceau — regarde où l'envoyer")
		local sheet = player:GetAttribute(FX.sheetAttribute)
		if sheet ~= nil then
			table.insert(lines, if sheet then "Bâche : invisible" else "Bâche : ne bouge pas !")
		elseif active(player, FX.veiledAttribute) then
			add(FX.veiledAttribute, "Invisible pour l'Œil")
		end
		local bat = player:GetAttribute(FX.batAttribute)
		if typeof(bat) == "number" then
			table.insert(lines, string.format("Batte : %d coups", bat))
		end
		status.Text = table.concat(lines, "   ")

		-- Messages et annonces.
		local bell = workspace:GetAttribute(FX.bellAttribute)
		local bellAt = workspace:GetAttribute(FX.bellTimeAttribute)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local text = recent(player:GetAttribute(BG.messageAttribute), V.messageSeconds) or ""
		if
			text == ""
			and typeof(bell) == "Vector3"
			and typeof(bellAt) == "number"
			and now - bellAt < I.bell.seconds
			and root
			and (root.Position - bell).Magnitude <= I.bell.hearRadius
		then
			text = string.format(
				"Une clochette sonne, à %d m",
				math.floor((root.Position - bell).Magnitude)
			)
		end
		message.Text = text
		local relic = workspace:GetAttribute(Config.relics.attribute)
		announce.Text = recent(workspace:GetAttribute(BG.announceAttribute), V.announceSeconds)
			or (
				if typeof(relic) == "Vector3"
						and root
						and inMatch
					then string.format(
						"Relique à %d m",
						math.floor((root.Position - relic).Magnitude)
					)
					else ""
			)

		-- Ebloui : l'ecran blanchit, puis revient.
		local dazzled = active(player, FX.dazzledAttribute)
		flash.BackgroundTransparency = if dazzled
			then 1 - math.clamp(dazzled / I.torch.seconds, 0, 1) * V.dazzleOpacity
			else 1

		-- Le trait de l'arc.
		if aiming and character then
			local head = character:FindFirstChild("Head") :: BasePart?
			if head then
				local look = camera.CFrame.LookVector
				local origin = head.Position + look * T.handForward
				local o = { x = origin.X, y = origin.Y, z = origin.Z }
				local v = Throw.velocity({ x = look.X, y = look.Y, z = look.Z }, T.speed, T.lift)
				params.FilterDescendantsInstances = { character, camera }
				local previous = origin
				local stopped = false
				for i, d in dots do
					local t = i * T.maxSeconds / T.previewPoints
					local p = Throw.at(o, v, T.gravity, t)
					local here = Vector3.new(p.x, p.y, p.z)
					if not stopped and workspace:Raycast(previous, here - previous, params) then
						stopped = true
					end
					d.Transparency = if stopped then 1 else V.aimDotTransparency
					d.CFrame = CFrame.new(here)
					previous = here
				end
			end
		end

		-- Reveles.
		local reveal = active(player, FX.revealAttribute)
		local range = player:GetAttribute(FX.revealRangeAttribute)
		local throughWalls = player:GetAttribute(FX.revealHiddenAttribute) == true
		local keep: { [Model]: boolean } = {}
		if reveal and root and typeof(range) == "number" then
			for _, other in characters() do
				local otherRoot = other:FindFirstChild("HumanoidRootPart") :: BasePart?
				local hidden = ownerOf(other):GetAttribute(Config.hiding.hiddenAttribute) ~= nil
				if
					otherRoot
					and (otherRoot.Position - root.Position).Magnitude <= range
					and (throughWalls or not hidden)
				then
					keep[other] = true
					if revealed[other] == nil then
						local h = Instance.new("Highlight")
						h.FillColor = Color3.fromRGB(255, 80, 60)
						h.OutlineColor = Color3.fromRGB(255, 200, 180)
						h.FillTransparency = 0.5
						h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						h.Adornee = other
						h.Parent = gui
						revealed[other] = h
					end
				end
			end
		end
		for other, h in revealed do
			if not keep[other] then
				h:Destroy()
				revealed[other] = nil
			end
		end

		-- Le grappin.
		local grappleAt = player:GetAttribute(FX.grappleTimeAttribute)
		local target = player:GetAttribute(FX.grappleAttribute)
		if
			typeof(grappleAt) == "number"
			and grappleAt > lastGrapple
			and typeof(target) == "Vector3"
			and root
			and character
		then
			lastGrapple = grappleAt
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local standAt = target
				+ Vector3.new(0, (if humanoid then humanoid.HipHeight else 2) + root.Size.Y / 2, 0)
			local from = root.Position
			local look = camera.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, -1)
			root.Anchored = true
			local started = os.clock()
			local connection: RBXScriptConnection? = nil
			connection = RunService.Heartbeat:Connect(function()
				local t = math.min((os.clock() - started) / I.grapple.seconds, 1)
				local at = from:Lerp(standAt, t)
				root.CFrame = CFrame.lookAt(at, at + flat)
				if t >= 1 then
					if connection then
						connection:Disconnect()
					end
					root.Anchored = false
					root.AssemblyLinearVelocity = Vector3.zero
				end
			end)
		end

		-- Le Regard vole : le faisceau va la ou l'on regarde.
		if
			active(player, FX.steerAttribute)
			and os.clock() - lastSteer >= V.steerSendSeconds
			and character
		then
			lastSteer = os.clock()
			params.FilterDescendantsInstances = { character, camera }
			local hit = workspace:Raycast(
				camera.CFrame.Position,
				camera.CFrame.LookVector * V.steerRange,
				params
			)
			local at = if hit
				then hit.Position
				else camera.CFrame.Position + camera.CFrame.LookVector * V.steerRange
			steerRemote:FireServer(at.X, at.Z)
		end
	end)
end

return ItemView
