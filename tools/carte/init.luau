--!strict
--[[
	Recette de la carte de Royale — le point d'entree.

	La carte n'est ni dans Git ni dans Rojo : ce dossier est sa sauvegarde
	(tools/README.md). Elle detruit d'abord ce qui repond au contrat de
	nommage (Workspace.Carte, la Baseplate et le SpawnLocation de depart, les
	effets de Lighting prefixes « Royale »), reconstruit tout, pose la
	lumiere, puis SE MESURE et rend un rapport.

	Comment la lancer depuis le pont MCP (`loadstring` y est ferme) : copier
	ce dossier dans `src/server/RecetteJetable/`, laisser Rojo synchroniser,
	`require` un CLONE depuis `execute_luau` et l'appeler dans un
	`task.spawn` (elle depasse le delai d'un appel au pont) ; le rapport
	arrive dans l'attribut `RapportRecette` de Workspace. Puis supprimer la
	copie du depot : elle ne se commite jamais.

	Les zones s'ajoutent une par une, chacune dans son module, appelees
	ci-dessous apres le socle.
]]

local Outils = require(script:WaitForChild("Outils"))
local Plan = require(script:WaitForChild("Plan"))
local Socle = require(script:WaitForChild("Socle"))(Outils, Plan)
local Ciel = require(script:WaitForChild("Ciel"))(Outils)

-- Le contrat de nommage avec le jeu.
local CONTRACT = {
	folder = "Carte",
	report = "RapportRecette",
}

local function build(): string
	local started = os.clock()
	local old = workspace:FindFirstChild(CONTRACT.folder)
	if old then
		old:Destroy()
	end
	-- La Baseplate et le SpawnLocation d'une place neuve : ils n'ont rien a
	-- faire sur la carte.
	for _, name in { "Baseplate", "SpawnLocation" } do
		local thing = workspace:FindFirstChild(name)
		if thing then
			thing:Destroy()
		end
	end

	local root = Outils.folder(workspace, CONTRACT.folder)

	Ciel.buildLighting()
	Socle.build(workspace.Terrain)
	Ciel.buildSky(root, Vector3.zero)
	-- Le ciel ne fait pas d'ombre : la Fissure, a 600 studs, posait une
	-- grande tache noire au sud du Cratere (vu a l'ecran le 12 novembre 2026).
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") then
			part.CastShadow = false
		end
	end

	local problems = Socle.measure()

	local lines = {
		string.format(
			"Carte construite en %.0f s : %d parts.",
			os.clock() - started,
			Outils.partCount()
		),
	}
	for _, problem in problems do
		table.insert(lines, "PROBLEME : " .. problem)
	end
	table.insert(lines, string.format("%d problème(s).", #problems))
	local report = table.concat(lines, "\n")
	workspace:SetAttribute(CONTRACT.report, report)
	return report
end

return build
