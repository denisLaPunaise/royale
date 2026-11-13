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
- **12 novembre 2026, le cœur du jeu et les bots** (en autonomie) : la
  partie (`MatchService` : attente, visée, chute en comète, Regards, fin,
  relance), `Roster` (participants joueurs ou bots, aspiration), `World`
  (contrat de la carte, ligne de vue depuis la pupille), `ZoneService`,
  `HidingService` (cachettes posées à chaque partie, marques, arrachage),
  `EyeService` (faisceaux, ciblage, jauge, méfiance), `BotService` (chemins,
  se cacher, fuir). Client : `SkyView` (Œil qui suit, paupières, faisceaux),
  `ZoneView`, `Hud`, `AimView`, `Controls`, `Spectate`. Logique pure :
  `Regards`, `Circles`, `Exposure`, `Suspicion`, `Targeting`. Partie de
  mesure à 22 : 15 min, sans erreur (`docs/A-TESTER.md`).
- **12 novembre 2026, le corps à corps** (en autonomie) : `CombatService`
  (frapper, K.O., pousser, plaquer, tacle glissé, porter et jeter, toquer à
  un abri, déloger, la porte dans la figure), logique pure `Melee`, gestes
  du client dans `Controls` (glissade, s'agripper aux rebords), l'Œil entend
  les bruits (`EyeService.noise`), les bots rendent les coups et calculent
  leurs chemins par étapes de 400 studs.
- **12 novembre 2026, les objets** (en autonomie) : `ItemService` (fouille
  des 276 meubles de `Carte.Fouilles`, sac de 4, les 28 objets, voler un
  K.O., sac lâché à l'aspiration, Reliques aux Regards 3 et 4, Cocon de
  secours), logique pure `Loot`, `Bag`, `Throw` ; `ItemView` (sac à
  l'écran, L1/R1, L2 viser et lancer, effets) ; crochets dans `EyeService`
  (leurres, voile, miroir, clignement, Regard volé, cape), `HidingService`
  (clochette, piège, barricade, carton piégé, craie) ; les bots fouillent,
  courent aux reliques et se défendent avec leurs objets.
- **12 novembre 2026, les pouvoirs de l'Œil** (en autonomie) : un tiré à
  chaque Regard parmi 14 (`EyePowerService`, logique pure `EyePowers`,
  `Config.eyePowers`) ; les chiffres passent par le Regard modifié
  (`EyePowerService.regardFor`), l'éclair, le souffle et les empreintes
  vivent dans le service ; `Regards.burst` accepte rafale allongée et faux
  départs ; le regard rasant dans `World.seenFactor`.
- **12 novembre 2026 (nuit), les Repris** : `ReprisService` (quatre sortes,
  corps et crâne de Survivor, chute à la fermeture, re-aspirés à chaque
  Regard), logique pure `Horde`, `Config.repris` ; crochets
  `CombatService.setCreatures`, `EyeService.onFlagged`,
  `ItemService.dropCommon` ; les bots frappent les Repris.
- **12 novembre 2026 (nuit), le goulag** : `GoulagService` (le Ventre construit
  au démarrage, cages, duels, mort subite, bot à la batte au corps de
  Repris), logique pure `Duels`, `Config.goulag` ; `Roster.setKeeper` et
  `Roster.revive` ; `CombatService.setArena` (règles du Ventre, un coup à
  terre envoie voler).
- **12 novembre 2026 (nuit), les escouades** : `SquadService` (équipes,
  cocon, victoire d'équipe), logique pure `Squads`, `Config.squads`,
  `TeamView` (repères et liste) ; relever et donner par les invites
  d'`ItemService` (`tryInteract` pour les sondes) ;
  `CombatService.addCreatures` (Repris et cocons).
- **12 novembre 2026 (nuit), les gestes** : s'allonger et ramper
  (`Controls`, attribut `Allonge`), tirer par les pieds
  (`CombatService.pull`, invite d'`ItemService`), signaux (`SignalService`,
  `GestureView`), carte et émote (`GestureView`).
- **12 novembre 2026 (nuit), les éliminés** : `Spectate` (coéquipiers
  d'abord, X parier, B quitter), `BetService`, logique pure `Bets`,
  `Config.bets`.
- **12 novembre 2026 (nuit), la liste des joueurs** : `PlayerListView` (R3 /
  Tab), publiée par `Roster` (`ListeJoueurs`).
- **12 novembre 2026 (nuit), les postures** : quatre animations générées
  (`docs/ASSETS.md`), jouées par `PostureView` sur tous les personnages ;
  plus de `PlatformStand` au sol.
- **12 novembre 2026 (nuit), les sons** : `Sfx` (serveur), `SoundView`
  (client), `Config.sounds` (repris de Survivor).
- **12 novembre 2026 (nuit), le salon** : `LobbyService` (la place, les
  groupes, le compte à rebours), logique pure `Lobby`,
  `Squads.assignGroups`, `LobbyView` ; `MatchService` joue sur place dans
  Studio, envoie sur un serveur réservé ailleurs (`serveMatch` sur le
  serveur de partie).
- **12 novembre 2026 (nuit), la progression** : `ProfileService` (DataStore,
  jamais d'écriture si la lecture échoue, verrou de session entre serveurs),
  logique pure `Progression`, récompenses de fin de partie
  (`SquadService.track` / `placeOf`).
- **12 novembre 2026 (nuit), la boutique** : `ShopService` (boutique du
  jour, tirages aux règles de Roblox, crédits et passe en Robux, passe de
  saison), logique pure `Shop`, `Config.cosmetics` / `shop` / `pass` (prix
  provisoires), `ShopView` ; cosmétiques appliqués (comète, traînée,
  cocon, émote, titre).
- **13 novembre 2026 (nuit), défis et classement** : `ChallengeService`
  (logique pure `Challenges`, onglet Défis de la boutique),
  `LeaderboardService` (victoires, panneau du salon) ; la carte dessine les
  zones ; les bots ouvrent les cocons de leurs coéquipiers.
- **13 novembre 2026, l'équilibrage** : Josh a activé l'accès aux API dans
  Studio (la sauvegarde marche) et publié. Une trentaine de parties de bots
  mesurées (`tools/banc/`) : montée de l'Œil régulière, Regard 4 et finale
  adoucis, cachettes ajoutées dans chaque nouveau cercle
  (`HidingService.fillCircle`, `Config.hiding.circleFill`), Repris des
  flairés hors plafond ; deux bugs (cocon + égout, chute hors du monde,
  `Config.match.voidBelow`). Détail dans `docs/DECISIONS.md`.
- **Prochaine tâche (décidé avec Josh le 13 novembre 2026)** : créer les
  produits Robux avec Josh (3 paquets de crédits et le passe premium,
  `Config.shop.creditPacks` et `Config.pass.premiumProductId` valent 0).
  Il les crée sur create.roblox.com (Monétisation → Produits de
  développeur), donne les numéros et les vrais prix ; on ajuste les
  crédits. Ensuite : une file d'attente entre salons.

## La place et la recette

- **La CI refuse aussi les avertissements de Selene** (vu la nuit du 12
  novembre : sept poussées rouges pour un `UDim2.new` simplifiable). Avant de
  commiter, lire la ligne des avertissements (`selene src ... | tail -3`), pas
  seulement la dernière.
- **Le salon et le Ventre se construisent au démarrage du serveur**
  (`LobbyService`, `GoulagService`) : ils ne sont pas dans la place. Pour
  les photographier en mode édition, on peut `require` un clone de leur
  module (avec une copie fraîche de `Config`, le pont garde l'ancienne en
  cache), puis **effacer** le dossier et l'attribut `Phase` posés sur
  Workspace. Attention : `LobbyService.start` lance des boucles qui
  restent tant que Studio est ouvert.
- **Les sauvegardes** (profils, classement) ne marchent dans Studio
  qu'avec « l'accès de Studio aux services d'API » (réglage de sécurité de
  Josh). Sans lui, le profil est marqué illisible et rien n'est écrit.

- **Le banc d'équilibrage** (`tools/banc/Banc.luau`) : le copier dans
  `src/server/RecetteJetable/` (ignoré par Git), poser l'attribut
  `BancPlan` de Workspace (« solo,squad,duo:0.35 » : le mode et, après les
  deux-points, la chance d'erreur des bots), injecter un `Script` qui fait
  `require(...RecetteJetable.Banc)()`, et un `LocalScript` client (dans un
  `ScreenGui` à `ResetOnSpawn` faux, sinon il meurt au premier
  personnage) qui envoie `mode` et `ready` au remote `Salon`. Le bilan
  s'accumule en JSON dans l'attribut `BancBilan`. Une partie dure environ
  17 minutes : **pas plus de 3 parties par lancement** (Studio a planté
  après plusieurs heures de jeu).
- **Mettre les bots en pause pour une mesure** : poser l'attribut `Phase` de
  Workspace sur autre chose que `Partie` (ils ne pensent qu'en `Partie`), puis
  le remettre. Sinon un bot frappé retourne se cacher entre deux coups.
- **Piloter une partie depuis le pont** : les invites ne se déclenchent pas
  par le pont ; les sondes passent par `HidingService.tryEnter`. Injecter un
  `Script` serveur pendant le jeu (son `require` partage le cache du jeu),
  qui écrit son rapport dans un attribut de Workspace. Le pont ne déplace pas
  la caméra en jeu : faisceaux et mur du cercle ne se voient qu'en jouant.

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
