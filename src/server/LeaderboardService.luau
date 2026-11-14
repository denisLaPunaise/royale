--!strict
--[[
	LeaderboardService — le classement (CONCEPT.md : « des titres et un
	classement »). Les victoires de chacun dans un OrderedDataStore ; un
	panneau du salon montre les meilleurs.

	Comme pour les profils : une victoire n'est comptee que pour un profil
	lisible, et un classement illisible s'affiche comme tel, jamais vide.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Royale = ReplicatedStorage:WaitForChild("Royale")
local Config = require(Royale:WaitForChild("Config"))

local ProfileService = require(script.Parent.ProfileService)

local LeaderboardService = {}

local LD = Config.leaderboard
local store: OrderedDataStore? = nil
local names: { [number]: string } = {}

local function getStore(): OrderedDataStore?
	if store == nil then
		local ok, result = pcall(function()
			return DataStoreService:GetOrderedDataStore(LD.store)
		end)
		store = if ok then result else nil
	end
	return store
end

local function nameOf(userId: number): string
	local cached = names[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local out = if ok then name else "?"
	names[userId] = out
	return out
end

-- Une victoire de plus pour ce joueur.
local function addWin(player: Player)
	local ods = getStore()
	if ods == nil or not ProfileService.readable(player) then
		return
	end
	local ok, err = pcall(function()
		(ods :: OrderedDataStore):IncrementAsync(tostring(player.UserId), 1)
	end)
	if not ok then
		warn("[Royale] Classement : " .. tostring(err))
	end
end

-- Le panneau du salon : un grand cadre de pierre, et les meilleurs dessus.
local function board(): TextLabel?
	local salon = workspace:FindFirstChild(Config.lobby.folder)
	if salon == nil then
		return nil
	end
	local o = Config.lobby.origin
	local a = math.rad(LD.angle)
	local reach = Config.lobby.radius - LD.boardInset
	local at = Vector3.new(o[1], o[2], o[3])
		+ Vector3.new(math.cos(a) * reach, LD.boardHeight / 2 + 1, math.sin(a) * reach)
	local part = Instance.new("Part")
	part.Name = "Classement"
	part.Anchored = true
	part.Size = Vector3.new(LD.boardWidth, LD.boardHeight, 1)
	part.CFrame = CFrame.lookAt(at, Vector3.new(o[1], at.Y, o[3]))
	part.Color = Color3.fromRGB(40, 34, 32)
	part.Material = Enum.Material.Slate
	part.Parent = salon
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = LD.pixelsPerStud
	gui.LightInfluence = 0
	gui.Parent = part
	-- Le titre en machine a ecrire, la liste en police nette (Config.view) :
	-- tout en un seul texte mis a l'echelle, un nom seul remplissait le
	-- panneau en lettres geantes (vu en image).
	local lantern = Config.lobby.colors.lantern
	-- Le meme cadre que les panneaux « Comment jouer » (LobbyScene).
	local frame = Instance.new("Frame")
	frame.Name = "Cadre"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(0.95, 0.94)
	frame.BackgroundTransparency = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.04, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(lantern[1], lantern[2], lantern[3])
	stroke.Thickness = 4
	stroke.Transparency = 0.35
	stroke.Parent = frame
	frame.Parent = gui
	local title = Instance.new("TextLabel")
	title.Name = "Titre"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0.06, 0.05)
	title.Size = UDim2.fromScale(0.88, 0.16)
	title.Font = (Enum.Font :: any)[Config.view.font]
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(lantern[1], lantern[2], lantern[3])
	title.Text = "CLASSEMENT — VICTOIRES"
	title.Parent = gui
	local text = Instance.new("TextLabel")
	text.Name = "Liste"
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromScale(0.08, 0.24)
	text.Size = UDim2.fromScale(0.84, 0.74)
	text.Font = (Enum.Font :: any)[Config.view.bodyFont]
	text.LineHeight = 1.1
	-- Les `size` lignes tiennent dans la liste : la taille se deduit de sa
	-- hauteur, jamais recopiee.
	local rows = LD.boardHeight * LD.pixelsPerStud * text.Size.Y.Scale
	text.TextSize = math.floor(rows / (LD.size * text.LineHeight))
	text.TextColor3 = Color3.fromRGB(240, 232, 220)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.Text = "…"
	text.Parent = gui
	return text
end

local function refresh(text: TextLabel)
	local ods = getStore()
	local lines = {}
	local ok, err = pcall(function()
		local page = (ods :: OrderedDataStore):GetSortedAsync(false, LD.size):GetCurrentPage()
		for i, entry in page do
			table.insert(
				lines,
				string.format("%d. %s — %d", i, nameOf(tonumber(entry.key) or 0), entry.value)
			)
		end
	end)
	if not ok or ods == nil then
		table.insert(lines, "(indisponible pour l'instant)")
		warn("[Royale] Classement illisible : " .. tostring(err))
	elseif #lines == 0 then
		table.insert(lines, "Personne encore : à toi de gagner.")
	end
	text.Text = table.concat(lines, "\n")
end

function LeaderboardService.start()
	ProfileService.onGranted(function(player: Player, _xp: number, result: any)
		if result and result.won then
			addWin(player)
		end
	end)
	task.spawn(function()
		-- Le panneau n'existe que dans un salon.
		task.wait(1)
		local text = board()
		if text == nil then
			return
		end
		while true do
			refresh(text)
			task.wait(LD.refreshSeconds)
		end
	end)
end

return LeaderboardService
