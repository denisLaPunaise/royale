# Assets générés

Ce qui est généré n'existe que dans la place : ce fichier est la sauvegarde.

## Modèles (ServerStorage.RoyaleModeles)

Repris de Survivor (même maillages, même textures ; voir
`..\Survivor\docs\ASSETS.md` pour leur description et pourquoi ils ont été
gardés). Recréés le 12 novembre 2026 dans la place Royale par
`AssetService:CreateMeshPartAsync(MeshId)`, puis `TextureID`, dans un Model
dont la part s'appelle `Corps`.

| Nom | MeshId | TextureID |
| --- | --- | --- |
| `Arbre` | `rbxassetid://91456604386363` | `rbxassetid://117383140726701` |
| `Voiture1` | `rbxassetid://118456716580222` | `rbxassetid://76327974453445` |
| `Voiture2` | `rbxassetid://79544487506810` | `rbxassetid://130542278747095` |

La recette (`tools/carte/Ville.luau`) les utilise s'ils existent et retombe
sur des arbres et des voitures en parts sinon.

## Modèles du magasin (Creator Store), avec l'accord de Josh (12 novembre 2026)

Insérés dans la place, **tous leurs scripts retirés**, gardés seulement pour
leurs formes et leurs textures, rangés dans `ServerStorage.RoyaleModeles`.

| Nom | Asset d'origine | Créateur | Maillages (MeshId, TextureID) | Remarque |
| --- | --- | --- | --- | --- |
| `Pin` | 3256343670 « Realistic Trees » | Chr1sDevv | `1668448780`, texture `1668393064` | Un pin du lot ; hauteur d'origine 101, réduit à 30-50 |
| `BuissonReel` | 14161520172 « Realistic Bush » | strikelife947 | mesh `743205322`, texture `743204665` | |
| `Feuillu1` | 12880583182 « BeechwoodTree_Var01 » | Tree_Branchie | `5547037961`, `5547037928`, `5547037970` | Hêtre |
| `Feuillu2` | 8020714443 « Oak tree » | 66curiousmagpie | `8020689602`, `8020689600` | Chêne |
| `Feuillu3` | 8827000021 « baum+ » | US Special Operation Command | `8535142943`, `5547038724` | |
| `Epave1` | 9213423301 « Abandoned Car 1 » | lamborghinifan11111 | `8651082373`, `8651085636` | Ramenée à 15 studs de long |
| `Epave2` | 9284331632 « Abandoned Car 5 » | lamborghinifan11111 | `6238209109` | |
| `Epave3` | 9493949933 « Abandoned Car 6 » | lamborghinifan11111 | `7456151272` et suivants (19 pièces) | Tournée pour avoir sa longueur sur Z |
| `Epave4` | 9500559626 « Abandoned Car 11 » (pick-up) | lamborghinifan11111 | `6427595891` | |

Écartés : 96924659951632 (un « pack » qui ne contenait que 23 scripts), 128707014921507
(chêne dont le tronc ne se chargeait pas : un cylindre blanc).

## Objets de rue (magasin)

| Nom | Asset d'origine | Créateur | Remarque |
| --- | --- | --- | --- |
| `Poubelle` | 13452048898 « Realistic Trash Can » | EarlyDev | 4 studs de haut |
| `BorneIncendie` | 13452054366 « Realistic Fire Hydrant » | EarlyDev | 2,6 studs |
| `Cone` | 83471113389608 « Traffic Cone Realistic » | ShreddCPhoenixT | 2,4 studs ; 3 scripts retirés |

## Matières générées (MaterialService.AssistantMaterials)

Générées le 12 novembre 2026 par `generate_material` ; la recette les pose en
remplacement des matières de base (`Ciel.applyMaterials`). Les couleurs des
pièces ont été éclaircies : ces matières les assombrissent.

| Variante | Remplace | Tuile | Textures (couleur, normale, rugosité, métal) |
| --- | --- | --- | --- |
| `RoyaleAsphalte` | Asphalt | 12 | `74628919579852`, `96837989076876`, `72595550370375`, `137585564095394` |
| `RoyaleBeton` | Concrete | 10 | `88125317519617`, `71823089748472`, `92281416995612`, `105461254231182` |
| `RoyaleBrique` | Brick | 6 | `137685932796701`, `105878722563277`, `97680185206221`, `111490999423135` |
| `RoyaleBois` | (plus appliquée : trop sombre dans les intérieurs) | 6 | `133803053723548`, `90758941212490`, `106152062153702`, `131080569088858` |

## Arbres morts (magasin)

| Nom | Asset d'origine | Créateur | Maillage | Remarque |
| --- | --- | --- | --- | --- |
| `Mort1` | 74163741192438 « Dead Forest Tree » | Kipfr9839 | `740991432`, texture `740989141` | 2 scripts retirés (annoncé « no scripts ») |
| `Mort2` | 13535614846 « realistic dead tree » | pighunt3r15 | `13410604750` | |
