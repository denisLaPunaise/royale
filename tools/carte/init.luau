--!strict
--[[
	Recette de la carte de Royale — le point d'entree.

	La carte n'est ni dans Git ni dans Rojo : ce dossier est sa sauvegarde
	(tools/README.md). Elle detruit d'abord ce qui repond au contrat de
	nommage (Workspace.Carte, ServerStorage.RoyaleCachettes, la Baseplate et
	le SpawnLocation de depart, les effets de Lighting prefixes « Royale »),
	reconstruit tout, pose la lumiere, puis SE MESURE et rend un rapport.

	Comment la lancer depuis le pont MCP (`loadstring` y est ferme) : copier
	ce dossier dans `src/server/RecetteJetable/` (ignore par Git), laisser
	Rojo synchroniser, `require` un CLONE depuis `execute_luau` et l'appeler
	dans un `task.spawn` (elle depasse le delai d'un appel au pont) ; le
	rapport arrive dans l'attribut `RapportRecette` de Workspace.

	`build({ socle = false })` garde le terrain (20 s de moins) : pratique
	pour retoucher une zone. `build({ zones = { "Banlieue" } })` ne construit
	que les zones nommees (les autres restent absentes).
]]

local ServerStorage = game:GetService("ServerStorage")

local Outils = require(script:WaitForChild("Outils"))
local Plan = require(script:WaitForChild("Plan"))
local Socle = require(script:WaitForChild("Socle"))(Outils, Plan)
local Ciel = require(script:WaitForChild("Ciel"))(Outils)
local Kit = require(script:WaitForChild("Kit"))
local Ville = require(script:WaitForChild("Ville"))(Outils, Kit.CONTRACT)
local Batiment = require(script:WaitForChild("Batiment"))(Outils, Ville, Kit.CONTRACT)
local Prefabs = require(script:WaitForChild("Prefabs"))(Outils, Kit.CONTRACT)

local CONTRACT = Kit.CONTRACT

-- Les zones, dans l'ordre ou elles se construisent : celles qui posent les
-- grandes routes passent avant celles qui remplissent les vides.
local ZONES = {
	"Liaisons",
	"Banlieue",
	"Suspendu",
	"Cratere",
	"FeteForaine",
	"Lycee",
	"Port",
	"Marais",
	"Gare",
	"Hypermarche",
	"Campagne",
	"Vegetation",
}

type Options = { socle: boolean?, zones: { string }? }

local function build(options: Options?): string
	local o: Options = options or {}
	local started = os.clock()
	for _, thing in
		{
			workspace:FindFirstChild(CONTRACT.folder),
			ServerStorage:FindFirstChild(CONTRACT.prefabs),
		}
	do
		if thing then
			thing:Destroy()
		end
	end
	-- La Baseplate et le SpawnLocation d'une place neuve : ils n'ont rien a
	-- faire sur la carte.
	for _, name in { "Baseplate", "SpawnLocation" } do
		local thing = workspace:FindFirstChild(name)
		if thing then
			thing:Destroy()
		end
	end

	Ciel.buildLighting()
	Ciel.applyMaterials()
	if o.socle ~= false then
		Socle.build(workspace.Terrain)
	end

	local kit = Kit.create(Outils, Ville, Plan)
	kit.B = Batiment
	Ciel.buildSky(kit.root, Vector3.zero)
	-- Le ciel ne fait pas d'ombre : la Fissure, a 600 studs, posait une
	-- grande tache noire au sud du Cratere (vu a l'ecran le 12 novembre 2026).
	for _, part in kit.root:GetDescendants() do
		if part:IsA("BasePart") then
			part.CastShadow = false
		end
	end

	-- Les limites de la carte : des murs invisibles au bord des 1600 studs.
	-- Le decor au-dela (montagnes, mer) ferme l'horizon mais ne se visite
	-- pas ; de toute facon, hors du cercle, l'Oeil aspire (CONCEPT.md).
	do
		local limits = Outils.folder(kit.root, "Limites")
		local half, high = Plan.HALF, 600
		for _, side in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local along = if side[1] == 0
				then Vector3.new(half * 2 + 20, high, 4)
				else Vector3.new(4, high, half * 2 + 20)
			Outils.P(
				limits,
				"Limite",
				along,
				CFrame.new(side[1] * (half + 2), high / 2 - 40, side[2] * (half + 2)),
				Enum.Material.SmoothPlastic,
				Outils.C.black,
				{
					transparency = 1,
					shadow = false,
					-- Le regard de l'Oeil passe au travers : seul le corps est arrete.
					query = false,
				}
			)
		end
	end

	-- Les modeles des cachettes, que le jeu pose sur les emplacements.
	local prefabs = Outils.folder(ServerStorage, CONTRACT.prefabs)
	Ville.buildPrefabs(prefabs)
	Prefabs.build(prefabs)

	local problems = Socle.measure()
	local summaries: { string } = {}
	local wanted: { [string]: boolean }? = nil
	if o.zones then
		wanted = {}
		for _, name in o.zones do
			(wanted :: any)[name] = true
		end
	end
	for _, name in ZONES do
		if wanted == nil or wanted[name] then
			-- Une zone qui casse ne doit pas emporter les autres : on note
			-- pourquoi, et on continue.
			local ok, result = pcall(function()
				return require(script.zones:WaitForChild(name))(kit)
			end)
			if ok then
				result.measure(problems)
				table.insert(summaries, result.summary)
			else
				table.insert(problems, name .. " a casse : " .. tostring(result))
			end
			task.wait()
		end
	end

	-- RIEN NE FLOTTE : sous chaque modele pose d'une zone (batiment, arbre,
	-- voiture, objet), un rayon doit toucher le sol ou une autre piece a
	-- moins de 3 studs. Le Quartier suspendu flotte expres ; les debris du
	-- ciel et du Cratere aussi (ce sont des parts, pas des modeles).
	do
		local floating: { string } = {}
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local checked = 0
		local function check(m: Model)
			local box, size = m:GetBoundingBox()
			local bottom = box.Position - Vector3.new(0, size.Y / 2, 0)
			params.FilterDescendantsInstances = { m }
			-- On cherche ce qu'il y a sous le modele en partant de haut (un rayon
			-- parti de son pied, s'il est enfonce dans le terrain, ne voit rien) ;
			-- il flotte si le sol est a plus de 2,5 studs sous son pied.
			-- Au centre et vers les quatre coins : un modele porte par ses pieds
			-- (une grue dont la fleche deborde sur l'eau) ne flotte pas.
			local gap = math.huge
			for _, o in
				{ { 0, 0 }, { 0.35, 0.35 }, { -0.35, 0.35 }, { 0.35, -0.35 }, { -0.35, -0.35 } }
			do
				local p = (box * CFrame.new(o[1] * size.X, -size.Y / 2, o[2] * size.Z)).Position
				local hit = workspace:Raycast(
					Vector3.new(p.X, bottom.Y + size.Y + 20, p.Z),
					Vector3.new(0, -(size.Y + 400), 0),
					params
				)
				if hit then
					gap = math.min(gap, bottom.Y - hit.Position.Y)
				end
			end
			checked += 1
			if gap > 2.5 then
				table.insert(
					floating,
					string.format("%s (%d, %d, %d)", m.Name, bottom.X, bottom.Y, bottom.Z)
				)
			end
		end
		local zonesFolder = kit.root:FindFirstChild(CONTRACT.zones)
		if zonesFolder then
			for _, zone in zonesFolder:GetChildren() do
				if zone.Name ~= "QuartierSuspendu" then
					for _, m in zone:GetChildren() do
						if m:IsA("Model") and m.Name ~= "Route" then
							check(m)
						end
					end
				end
			end
		end
		if #floating > 0 then
			table.insert(
				problems,
				string.format(
					"%d modele(s) sur %d flottent : %s",
					#floating,
					checked,
					table.concat(floating, ", ", 1, math.min(#floating, 8))
				)
			)
		end
		table.insert(
			summaries,
			string.format(
				"Rien ne flotte : %d modeles verifies au rayon, %d en l'air",
				checked,
				#floating
			)
		)
	end

	local anchorCount = #kit.anchors:GetChildren()
	local containerCount = #kit.containers:GetChildren()
	local trees, cars = Ville.generated()
	local lines = {
		string.format(
			"Carte construite en %.0f s : %d parts.",
			os.clock() - started,
			Outils.partCount()
		),
		string.format(
			"%d emplacements de cachettes, %d contenants a fouiller, %d arbres et %d voitures generes.",
			anchorCount,
			containerCount,
			trees,
			cars
		),
	}
	for _, summary in summaries do
		table.insert(lines, summary)
	end
	for _, problem in problems do
		table.insert(lines, "PROBLEME : " .. problem)
	end
	table.insert(lines, string.format("%d problème(s).", #problems))
	local report = table.concat(lines, "\n")
	workspace:SetAttribute(CONTRACT.report, report)
	return report
end

return build
