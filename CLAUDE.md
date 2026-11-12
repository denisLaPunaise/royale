# Royale — notes pour l'assistant

Nom de code du dépôt : **Royale**. Titre du jeu : **à choisir avec Josh**.
Battle royale Roblox (solo et escouades, 24 joueurs au plus) où l'ennemi
principal est l'Œil géant du ciel : il balaie la ville, aspire qui il voit, et
devient plus fort de Regard en Regard. Le dernier joueur ou la dernière
escouade pas capturé gagne.

**Le concept complet est dans [docs/CONCEPT.md](docs/CONCEPT.md)**, chaque
point marqué *validé*, *proposé* ou *à voir*. Un point *validé* ne change
qu'avec Josh. Une décision prise sans lui se note dans
[docs/DECISIONS.md](docs/DECISIONS.md).

Les notes communes à tous les jeux de Josh sont dans
`C:\Users\boill\.claude\CLAUDE.md` (copie dans
`..\Survivor\docs\NOTES-COMMUNES.md`).

## D'où vient le jeu

C'est un jeu à part de **Survivor** (`..\Survivor`, dépôt
`denisLaPunaise/survivor`), qui garde la même base. Le code utile s'y
**recopie** (pas de dépendance entre dépôts) : le trajet des Balayages
(`Sweep`), la jauge (`Exposure`), les courbes de montée (`Growth`), les
cachettes marquées (`Hiding`), le fumigène (`Smoke`), l'Œil et sa ligne de vue
(`EyeService`, `SkyView`), `Throttle` et `RemoteGuard`. Même squelette : Rojo,
Rokit, StyLua, Selene, Lune, GitHub Actions, tous les chiffres dans
`Config.luau`.

## Les principes à ne jamais casser

1. **Bien caché, on est en sécurité dans la zone.** L'Œil ne triche jamais :
   être vu, c'est une vraie ligne de vue, mesurée au rayon. Seule exception,
   voulue : hors de la zone, la jauge monte même caché.
2. **La manette décide.** Une action qui ne rentre pas dans `Config.controls`
   se sacrifie. Un test refuse toute collision.
3. **Aucun achat ne donne de puissance.** Boutique cosmétique seulement.
4. **Aucun objet n'annule l'Œil**, et rien ne s'additionne pour rendre un
   joueur intouchable.
5. **Une récompense se demande** : qui peut provoquer cette issue exprès, et
   avec combien de comptes ? (Paris, XP, crédits.)

## Où on en est

- **9 novembre 2026** : fiche commencée avec Josh dans un autre chat.
- **12 novembre 2026** : dossier et dépôt créés, fiche rangée dans
  `docs/CONCEPT.md`, puis fiche presque finie avec Josh dans la journée :
  l'Œil (5 Regards liés aux cercles, power-ups), la zone, le départ recraché,
  les bots invisibles, les cachettes, les boutons de la manette, les
  interactions, 27 objets, la carte (9 zones, 1600 × 1600), les escouades,
  la boutique. Restent l'équilibrage des objets et des power-ups, et les prix
  en chiffres ; le nom et le marketing se feront au lancement.
- **Ordre de construction choisi par Josh** : la carte complète d'abord, puis
  les mécaniques (voir `docs/CONCEPT.md`, Mise en place).
- **12 novembre 2026, le projet monté et le socle de la carte** : squelette
  (Rokit, Rojo, CI, `Config` avec les boutons, points d'entrée,
  `RemoteGuard`), première personne. La recette `tools/carte/` pose le sol :
  une vallée côtière (le pays monte vers le nord et l'est), la rivière de
  l'est à la mer, cinq chaînes de montagnes (`Plan.RIDGES`), la côte en caps
  et anses, le Cratère, le Marais en mares, l'Œil et la lumière repris de
  Survivor. Mesure : 0 problème.
- **12 novembre 2026, la carte complète** (en autonomie, à la demande de
  Josh) : `tools/carte/zones/` construit les liaisons (routes de campagne,
  3 ponts et leurs cachettes dessous), la Banlieue (lotissement à rues
  courbes, 53 maisons de Survivor), le Quartier suspendu (5 îlots, passerelles,
  dalle retombée), le Cratère (épaves, fissures, butin), la Fête foraine
  (grande roue penchée, montagnes russes cassées, manège, train fantôme), le
  Lycée, le Port (quai qui suit la côte, cargo couché, conteneurs, grues,
  phare), le Marais (cabanes sur pilotis, pontons), la Gare (6 voies, wagons),
  l'Hypermarché éventré, puis la végétation. Mesure : 0 problème.
  Outils communs : `Kit` (sol, place, routes, emplacements, caisses),
  `Ville` (pièces de Survivor), `Batiment`, `Prefabs` (casier, roseaux,
  carton, armoire).

## La place et la recette

- La place Studio est publiée (placeId `74018653591531`) ; Rojo y synchronise
  le projet « Royale ». `Lighting.Technology` (Future) se règle à la main.
- **Lancer la recette** : copier `tools/carte/` dans
  `src/server/RecetteJetable/` (ignoré par Git), attendre que Rojo ait
  synchronisé (comparer la taille des `Source`), `require` un CLONE depuis
  `execute_luau` dans un `task.spawn`, lire `workspace:GetAttribute("RapportRecette")`.
  Le socle prend environ 20 s.
- **Ne jamais supprimer puis recopier `src/server/RecetteJetable/`** pendant
  que Rojo tourne : `rojo serve` plante (fichier introuvable) et le plugin se
  déconnecte. Recopier par-dessus (`cp -r`), sans `rm -rf`.
- `CorrodedMetal` impose sa couleur rouille : les grandes surfaces sont en
  `Metal` (sinon tout le port virait au rose).
- L'eau du terrain se range par cases de 4 et ne partage pas une case avec
  la terre : elle affleure à -4 et ne remplit que les creux sous -8.
- `Model:ScaleTo` est **absolu** (par rapport au modèle d'origine) :
  multiplier `GetScale()`. Et poser un modèle du magasin par le bas de sa
  boîte, pas par son pivot (les arbres flottaient, géants).
- Pas de remblai sous les routes : aux carrefours il enterrait la route
  voisine et s'accumulait à chaque reconstruction.
- Modèles du magasin : accord de Josh le 12 novembre 2026 ; scripts retirés,
  tout est noté dans `docs/ASSETS.md`. Ils n'existent que dans la place :
  Josh doit **publier** après chaque ajout.
- Pièges vus : `SetMaterialColor` refuse l'eau (`Terrain.WaterColor`) ;
  `WriteVoxels` pose la surface une demi-case plus haut que l'occupation lue à
  plat (le socle retire 0,5) ; la mer et les mares ne se remplissent que là
  où le socle le dit (sinon le Cratère devenait un lac).
