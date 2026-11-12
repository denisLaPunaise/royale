--!strict
--[[
	PostureView — les postures qu'on voit (docs/ASSETS.md) : accroupi,
	allonge qui rampe, K.O. au sol, porte a l'horizontale.

	Chaque ecran les joue sur tous les personnages (joueurs et bots), d'apres
	leurs attributs : c'est un affichage, le serveur n'en a pas besoin. Les
	animations de posture passent devant la marche ; accroupi et ramper se
	figent quand le personnage ne bouge pas.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local PostureView = {}

local P = Config.postures
local C = Config.combat

type Tracks = { [string]: AnimationTrack }

local loaded: { [Humanoid]: Tracks } = {}
local playing: { [Humanoid]: string } = {}
local warned = false

local function tracksOf(humanoid: Humanoid): Tracks?
	local cached = loaded[humanoid]
	if cached then
		return cached
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator == nil then
		return nil
	end
	local out: Tracks = {}
	for _, name in { "prone", "crouch", "knockedOut", "carried" } do
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. (P :: any)[name]
		local ok, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if ok then
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = true
			out[name] = track
		elseif not warned then
			warned = true
			warn("[Royale] Animation de posture : " .. tostring(track))
		end
	end
	loaded[humanoid] = out
	humanoid.AncestryChanged:Connect(function()
		if humanoid.Parent == nil then
			loaded[humanoid] = nil
			playing[humanoid] = nil
		end
	end)
	return out
end

-- La posture d'un participant, d'apres ses attributs (ou rien : debout).
local function postureOf(actor: Instance): string?
	local down = actor:GetAttribute(C.downAttribute)
	if actor:GetAttribute(C.carriedAttribute) == true then
		return "carried"
	elseif typeof(down) == "number" and workspace:GetServerTimeNow() < down then
		return "knockedOut"
	elseif actor:GetAttribute(C.proneAttribute) == true then
		return "prone"
	elseif actor:GetAttribute(C.crouchAttribute) == true then
		return "crouch"
	end
	return nil
end

local function update(actor: Instance, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or root == nil or not root:IsA("BasePart") then
		return
	end
	local tracks = tracksOf(humanoid)
	if tracks == nil then
		return
	end
	local want = postureOf(actor)
	local current = playing[humanoid]
	if want ~= current then
		if current and tracks[current] then
			tracks[current]:Stop(P.fadeSeconds)
		end
		if want and tracks[want] then
			tracks[want]:Play(P.fadeSeconds)
		end
		playing[humanoid] = want
	end
	-- Accroupi et ramper : la boucle avance quand on bouge, se fige sinon.
	if want == "crouch" or want == "prone" then
		local track = tracks[want]
		local v = root.AssemblyLinearVelocity
		if track then
			track:AdjustSpeed(if Vector3.new(v.X, 0, v.Z).Magnitude > P.stillSpeed then 1 else 0)
		end
	end
end

function PostureView.start()
	while true do
		task.wait(P.refreshSeconds)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character then
				update(player, character)
			end
		end
		local bots = workspace:FindFirstChild(Config.bots.folder)
		if bots then
			for _, model in bots:GetChildren() do
				if model:IsA("Model") then
					update(model, model)
				end
			end
		end
	end
end

return PostureView
