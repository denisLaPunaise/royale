--!strict
--[[
	Config — tous les chiffres reglables du jeu, a un seul endroit.

	Regle absolue du projet : aucun de ces nombres n'est ecrit en dur ailleurs
	dans le code, et aucun repli cache (`or 1`) ne le remplace en silence. Ils
	seront modifies des dizaines de fois pendant les tests, et il faut pouvoir
	en changer un sans ouvrir un seul module de logique.

	Chaque valeur porte la raison de sa valeur. « A REGLER » marque un point de
	depart a valider en jouant.

	Ce module ne requiert rien et ne touche a aucune API Roblox : il se charge
	aussi bien dans Studio que dans les tests Lune.

	UNE TABLE N'ENTRE ICI QUE LE JOUR OU UN SERVICE L'EXECUTE. La panne la plus
	chere d'Arena etait une table de Config testee mais lue par personne : le
	jeu annoncait une regle qui ne s'appliquait pas. Les Regards, l'Oeil, les
	cercles et les objets de docs/CONCEPT.md arriveront avec leur service, pas
	avant. Seule exception : `controls`, fixe AVANT le code (voir plus bas).
]]

local Config = {}

-- Numero de version du reglage, affiche au demarrage. A incrementer quand on
-- change un chiffre qui modifie l'equilibrage, pour savoir de quoi on parle
-- quand on compare deux sessions de test.
Config.version = 1

--------------------------------------------------------------------------------
-- RESEAU
--------------------------------------------------------------------------------

Config.network = {
	-- Le garde-fou contre l'inondation, repris d'Arena et de Survivor ou il a
	-- ete regle : une rafale de 8 laisse passer un double clic et les deux
	-- messages d'un meme geste ; 4 par seconde tenus, c'est plus qu'aucun
	-- humain a la manette.
	remoteThrottle = {
		burst = 8,
		perSecond = 4,
	},
}

--------------------------------------------------------------------------------
-- LES COMMANDES — la manette decide
--------------------------------------------------------------------------------

-- Valide avec Josh le 12 novembre 2026 comme point de depart (docs/CONCEPT.md,
-- « Les boutons de la manette ») : si une action ne rentre pas dans ces
-- boutons, on la sacrifie. Le clavier n'est qu'un miroir.
--
-- Exception a la regle « une table n'entre que quand un service l'execute » :
-- les boutons se fixent avant le code pour que chaque mecanique trouve sa
-- place sans en deloger une autre. Un test verifie que dans un meme contexte
-- aucun bouton ni aucune touche ne porte deux actions.
--
-- Un appui court et un appui maintenu sur le meme bouton sont UNE action ici
-- (le test refuserait deux lignes) : c'est le service qui distingue, et le
-- commentaire de chaque ligne dit ce que fait le maintien.
Config.controls = {
	-- Les boutons qu'un jeu peut prendre. ButtonStart ouvre le menu de Roblox
	-- et ButtonSelect bascule la navigation dans les panneaux : les deux sont
	-- a Roblox, pas a nous. Les sticks bougent et regardent ; les ENFONCER
	-- (L3, R3) reste a nous.
	gamepadButtons = {
		"ButtonA",
		"ButtonB",
		"ButtonX",
		"ButtonY",
		"ButtonL1",
		"ButtonR1",
		"ButtonL2",
		"ButtonR2",
		"ButtonL3",
		"ButtonR3",
		"DPadUp",
		"DPadDown",
		"DPadLeft",
		"DPadRight",
	},

	contexts = {
		-- A pied, et dans un volume ou un recoin (on y bouge librement).
		onFoot = {
			-- En l'air pres d'un rebord : s'agripper et se hisser.
			jump = { gamepad = "ButtonA", keyboard = "Space" },
			-- En courant : glisser (et tacler qui est devant) ; a l'arret :
			-- s'accroupir ; maintenu : s'allonger et ramper.
			posture = { gamepad = "ButtonB", keyboard = "C" },
			-- Fouiller, ouvrir, entrer dans un abri. Maintenu : relever un ami
			-- a terre, voler un ennemi K.O., donner son objet a un ami debout,
			-- tirer par les pieds quelqu'un d'allonge.
			interact = { gamepad = "ButtonX", keyboard = "E" },
			-- Frapper ; sur un abri : toquer ; sur un cocon : l'ouvrir.
			hit = { gamepad = "ButtonR2", keyboard = "MouseButton1" },
			-- A l'arret : pousser ; en courant : plaquer ; maintenu sur un
			-- K.O. : le porter.
			shove = { gamepad = "ButtonY", keyboard = "F" },
			-- Utiliser l'objet choisi ; maintenu : viser, lacher pour lancer.
			useItem = { gamepad = "ButtonL2", keyboard = "MouseButton2" },
			previousItem = { gamepad = "ButtonL1", keyboard = "Q" },
			nextItem = { gamepad = "ButtonR1", keyboard = "R" },
			-- Bascule a la manette (L3 se tient mal en bougeant le stick, vu
			-- dans Survivor), maintenu au clavier.
			sprint = { gamepad = "ButtonL3", keyboard = "LeftShift" },
			map = { gamepad = "DPadLeft", keyboard = "M" },
			signalDanger = { gamepad = "DPadUp", keyboard = "Z" },
			signalHere = { gamepad = "DPadDown", keyboard = "X" },
			emote = { gamepad = "DPadRight", keyboard = "G" },
		},
		-- En portant un joueur K.O. au-dessus de sa tete.
		carrying = {
			throw = { gamepad = "ButtonY", keyboard = "F" },
			putDown = { gamepad = "ButtonB", keyboard = "C" },
		},
		-- Dans un abri ferme (voiture, armoire, frigo, poubelle).
		hidden = {
			leave = { gamepad = "ButtonX", keyboard = "E" },
			-- La porte dans la figure de celui qui ouvre.
			burstOut = { gamepad = "ButtonR2", keyboard = "MouseButton1" },
			previousItem = { gamepad = "ButtonL1", keyboard = "Q" },
			nextItem = { gamepad = "ButtonR1", keyboard = "R" },
			signalDanger = { gamepad = "DPadUp", keyboard = "Z" },
			signalHere = { gamepad = "DPadDown", keyboard = "X" },
		},
		-- Au goulag, en duel sur sa plateforme.
		gulag = {
			hit = { gamepad = "ButtonR2", keyboard = "MouseButton1" },
			jump = { gamepad = "ButtonA", keyboard = "Space" },
			crouch = { gamepad = "ButtonB", keyboard = "C" },
		},
		-- Elimine pour de bon : regarder, parier, quitter.
		spectating = {
			previousPlayer = { gamepad = "ButtonL1", keyboard = "Q" },
			nextPlayer = { gamepad = "ButtonR1", keyboard = "R" },
			bet = { gamepad = "ButtonX", keyboard = "E" },
			leave = { gamepad = "ButtonB", keyboard = "Backspace" },
		},
	},
}

--------------------------------------------------------------------------------
-- LA CARTE — le contrat de nommage avec la recette (tools/carte/Kit.luau)
--------------------------------------------------------------------------------

-- Seule interface entre le code et ce que la recette construit. Le serveur
-- verifie ces noms au demarrage et dit ce qui manque.
Config.world = {
	folder = "Carte",
	sky = "Ciel",
	eye = "Oeil",
	lids = "Paupieres",
	anchors = "Emplacements",
	solidSpots = "CachettesSolides",
	containers = "Fouilles",
	prefabs = "RoyaleCachettes",
	inside = "Interieur",
	exit = "Sortie",
	-- Attribut d'une part qui ne couvre qu'a moitie (buisson, grillage) : la
	-- part du regard qu'elle laisse passer, entre 0 et 1.
	coverAttribute = "Couvert",
	-- Ou l'on pose les cachettes de la partie (un dossier neuf a chaque partie).
	placedFolder = "CachettesDeLaPartie",
	-- La moitie du cote de la carte jouable (tools/carte/Plan.luau).
	half = 800,
}

--------------------------------------------------------------------------------
-- LA PARTIE — son deroule (CONCEPT.md, Une partie)
--------------------------------------------------------------------------------

Config.match = {
	-- L'attente des joueurs : courte, puis les bots completent (valide le 12
	-- novembre 2026 : « une longue recherche fait quitter le jeu »).
	waitSeconds = 30,
	-- Un seul vrai joueur suffit : seul, on joue tout de suite.
	minRealPlayers = 1,
	-- Le depart : on vise depuis la pupille, puis l'Oeil crache tout le monde.
	aimSeconds = 8,
	-- La vitesse de la comete (studs/s) : de la pupille (~600 de haut) au
	-- sol en 3 a 5 s, assez vite pour que ce soit une attaque, assez lent pour
	-- voir les autres filer.
	cometSpeed = 180,
	-- La premiere ouverture de l'Oeil, apres le premier impact (CONCEPT.md).
	firstOpenDelay = 20,
	-- L'ecran de victoire, avant qu'une nouvelle partie ne recommence.
	endSeconds = 12,
	-- Tant qu'il n'y a pas de salon d'attente : on enchaine les parties sur le
	-- meme serveur, pour tester en boucle (Josh, 12 novembre 2026).
	restartAfterEnd = true,
	-- On attend pres du centre, dans ce rayon (studs), en attendant le salon.
	waitRadius = 80,
	-- Les personnages se posent un peu au-dessus du sol vise (studs) : la
	-- hauteur d'un bassin.
	landingHeight = 3,
	-- La comete : feu orange, sombre au bout ; l'impact souffle sans blesser.
	cometFireSize = 8,
	cometFireHeat = 20,
	impactRadius = 6,
	-- Les attributs de Workspace que lit l'interface.
	phaseAttribute = "Phase",
	regardAttribute = "Regard",
	regardTitleAttribute = "RegardTitre",
	eyeOpenAttribute = "OeilOuvert",
	phaseEndsAttribute = "PhaseFin",
	aliveAttribute = "EnVie",
	winnerAttribute = "Gagnant",
}

--------------------------------------------------------------------------------
-- L'OEIL — ses 5 Regards (CONCEPT.md, valeurs de depart validees le 12 nov.)
--------------------------------------------------------------------------------

-- Repères : la marche fait 14 studs/s, la course 22.
Config.regards = {
	{
		title = "Il s'éveille",
		seconds = 300,
		playersPerBeam = 8,
		openSeconds = 30,
		closedSeconds = 20,
		chaseSpeed = 12,
		memorySeconds = 1,
		aimError = 60,
		ripsPerBurst = 3,
		beamRadius = 14,
		fillSeconds = 2,
		hears = "rien",
		announceSeconds = 90,
		outsideFillSeconds = 20,
		suspicionSeconds = 90,
		solidFalls = false,
	},
	{
		title = "Il voit plus loin",
		seconds = 270,
		playersPerBeam = 7,
		openSeconds = 35,
		closedSeconds = 15,
		chaseSpeed = 15,
		memorySeconds = 1.5,
		aimError = 40,
		ripsPerBurst = 4,
		beamRadius = 16,
		fillSeconds = 2,
		hears = "rien",
		announceSeconds = 80,
		outsideFillSeconds = 15,
		suspicionSeconds = 75,
		solidFalls = false,
	},
	{
		title = "Il entend la course",
		seconds = 240,
		playersPerBeam = 6,
		openSeconds = 40,
		closedSeconds = 12,
		chaseSpeed = 18,
		memorySeconds = 2,
		aimError = 25,
		ripsPerBurst = 6,
		beamRadius = 18,
		fillSeconds = 1.8,
		hears = "course",
		announceSeconds = 65,
		outsideFillSeconds = 11,
		suspicionSeconds = 60,
		solidFalls = false,
	},
	{
		title = "Il entend les coups",
		seconds = 210,
		playersPerBeam = 5,
		openSeconds = 45,
		closedSeconds = 8,
		chaseSpeed = 20,
		memorySeconds = 3,
		aimError = 15,
		ripsPerBurst = 8,
		beamRadius = 20,
		fillSeconds = 1.8,
		hears = "coups",
		announceSeconds = 55,
		outsideFillSeconds = 8,
		suspicionSeconds = 45,
		solidFalls = false,
	},
	{
		title = "Il ne ferme plus les yeux",
		-- Pas de fin forcee : la partie se termine par l'Oeil (valide le 12
		-- novembre 2026). La duree ne sert qu'a l'affichage.
		seconds = 180,
		playersPerBeam = 4,
		-- Ouvert en permanence : `closedSeconds` a 0 ne ferme jamais.
		openSeconds = 60,
		closedSeconds = 0,
		chaseSpeed = 22,
		memorySeconds = 3.5,
		aimError = 5,
		ripsPerBurst = 12,
		beamRadius = 22,
		fillSeconds = 1.6,
		hears = "tout",
		announceSeconds = 45,
		outsideFillSeconds = 5,
		suspicionSeconds = 30,
		-- La fin se fait par l'Oeil (CONCEPT.md) : les cachettes solides
		-- s'effondrent aussi, sinon un tunnel ferait durer la finale sans fin.
		solidFalls = true,
	},
}

Config.eye = {
	-- La jauge redescend a l'abri en 5 s (Survivor : traverser une rue en
	-- courant passe, rester plante non).
	drainSeconds = 5,
	-- Ejecte d'une cachette arrachee : 2 s de repit pour courir (CONCEPT.md).
	graceSeconds = 2,
	-- La ligne de vue traverse au plus ces couches (vitres, buissons).
	maxRayHops = 6,
	-- Au-dessus de cette transparence, une part ne cache rien (une vitre).
	seeThroughTransparency = 0.5,
	-- Sans cible, un faisceau erre a cette vitesse (studs/s) autour des
	-- joueurs : on voit la lumiere venir, elle ne se teleporte pas.
	roamSpeed = 16,
	-- Le ciel rougit quelques secondes avant chaque ouverture.
	warningSeconds = 4,
	-- La hauteur ou l'on monte, aspire, avant de disparaitre (studs).
	suctionHeight = 160,
	suctionSeconds = 2.4,
	-- Les attributs du joueur lus par l'interface.
	exposureAttribute = "Exposition",
	graceAttribute = "Repit",
	-- Le pas de calcul de l'Oeil (s) : dix fois par seconde suffit a une
	-- jauge qui se remplit en 1,6 s au plus vite, et laisse du temps aux rayons.
	tickSeconds = 0.1,
	-- L'erreur de visee se retire au sort toutes les 2 s : le faisceau
	-- hesite, il ne tremble pas.
	aimRerollSeconds = 2,
	-- Un joueur va « en courant » au-dessus de cette vitesse (studs/s) :
	-- entre la marche (14) et la course (22).
	runningSpeed = 18,
	-- A chaque ouverture, un faisceau tombe a cette distance d'un joueur au
	-- hasard : pres, pour que la chasse commence, jamais dessus (studs).
	openOffset = 80,
	-- Les faisceaux, publies pour l'interface : un dossier de Workspace dont
	-- chaque attribut `F1`, `F2`... vaut (x, rayon, z).
	beamsFolder = "Faisceaux",
	-- Les attributs de Workspace : la prochaine ouverture ou fermeture (heure
	-- du serveur), et le ciel qui rougit avant.
	changeAttribute = "OeilChange",
	warningAttribute = "OeilBientot",
	-- L'attribut d'un joueur poursuivi par un faisceau (pour son ecran).
	huntedAttribute = "Traque",
}

--------------------------------------------------------------------------------
-- LA ZONE — un cercle par Regard (CONCEPT.md, La carte)
--------------------------------------------------------------------------------

Config.zone = {
	-- La largeur de reference de chaque cercle pour ~20 joueurs au depart, et
	-- le nombre de joueurs en vie qu'on y attend. Au moment de l'annoncer, le
	-- cercle se calcule d'apres les joueurs vraiment en vie (valide le 12
	-- novembre 2026), sans jamais depasser le precedent.
	reference = {
		{ diameter = 1300, alive = 20 },
		{ diameter = 900, alive = 14 },
		{ diameter = 600, alive = 10 },
		{ diameter = 380, alive = 6 },
		{ diameter = 220, alive = 4 },
	},
	-- Jamais plus petit que ceci : il faut toujours de quoi se cacher.
	minDiameter = 140,
	-- Le prochain cercle reste entierement dans l'actuel, avec cette marge.
	insideMargin = 10,
	-- Les attributs de Workspace : le cercle actuel et le prochain.
	attribute = "Cercle",
	nextAttribute = "CercleSuivant",
	-- Le cercle se resserre pendant ce temps (s), une fois annonce depuis
	-- `announceSeconds` : une minute laisse traverser la carte en marchant.
	shrinkSeconds = 60,
	-- Avant le premier cercle : toute la carte, coins compris.
	startRadius = 1140,
}

--------------------------------------------------------------------------------
-- LES CACHETTES — combien, et l'Oeil qui les arrache (CONCEPT.md, Cachettes)
--------------------------------------------------------------------------------

Config.hiding = {
	-- Au debut, un peu plus de places que de joueurs ; en finale, moins (les
	-- arrachages s'en chargent). Places posees par joueur au depart.
	spotsPerPlayer = 4,
	-- Jamais moins (une partie a 2 vrais joueurs garde une carte vivante).
	minSpots = 60,
	-- Une cachette se marque des qu'on y entre ; l'Oeil vient la chercher a sa
	-- prochaine ouverture, jamais pendant celle ou l'on s'y cache.
	-- Il garde ses marques ce nombre d'ouvertures, puis oublie.
	markBursts = 3,
	-- Combien de temps l'invite met a s'ouvrir (maintenir X).
	enterHoldSeconds = 0.3,
	promptDistance = 7,
	-- L'attribut d'un joueur cache : le nom de sa cachette.
	hiddenAttribute = "Cache",
	-- Une cachette arrachee : ses morceaux s'envolent ce temps (s) avant de
	-- disparaitre, a la vue de tous.
	ripSeconds = 3,
	-- Le tremblement qui previent, avant l'arrachage (s) : de quoi sortir.
	ripWarningSeconds = 1.5,
	-- Le tremblement (studs et radians) et la force de l'envol (studs/s) :
	-- assez pour que toute la rue voie partir la cachette vers l'Oeil.
	shakeOffset = 0.3,
	shakeTurn = 0.03,
	liftMin = 60,
	liftMax = 110,
	scatter = 12,
	spin = 4,
}

--------------------------------------------------------------------------------
-- LE CORPS — marcher, courir, s'accroupir (CONCEPT.md, Les boutons)
--------------------------------------------------------------------------------

Config.movement = {
	-- Les reperes de Survivor : la marche et la course.
	walkSpeed = 14,
	runSpeed = 22,
	-- Accroupi, on va lentement et la tete descend : derriere un muret, on
	-- sort de la ligne de vue de l'Oeil pour de vrai.
	crouchSpeed = 7,
	crouchHipDrop = 1.2,
}

--------------------------------------------------------------------------------
-- LA MEFIANCE — contre le camping (CONCEPT.md, valide le 12 novembre 2026)
--------------------------------------------------------------------------------

Config.suspicion = {
	-- Caché dans ce rayon autour du meme point : la jauge monte.
	radius = 15,
	-- Bouger plus loin que ceci la fait redescendre.
	resetDistance = 25,
	-- Elle redescend en ce temps (s) quand on bouge.
	drainSeconds = 20,
	-- L'avertissement « Il te sent… ».
	warnAt = 0.7,
	attribute = "Mefiance",
}

--------------------------------------------------------------------------------
-- LES BOTS — invisibles, pour que la partie paraisse toujours pleine
--------------------------------------------------------------------------------

-- CONCEPT.md (valide le 12 novembre 2026) : apres l'attente, des bots
-- completent jusqu'a un total tire entre 17 et 24. On doit croire que ce sont
-- des joueurs, et ils ne doivent pas etre plus faciles a battre qu'un joueur
-- moyen (une partie avec bots rapporte comme une autre).
Config.bots = {
	totalMin = 17,
	totalMax = 24,
	folder = "Participants",
	-- Ils reflechissent deux fois par seconde : assez pour fuir un faisceau
	-- (qui avance a 22 studs/s au plus), assez peu pour en faire tourner 23.
	thinkSeconds = 0.5,
	-- Un faisceau plus pres que ceci (studs) : il faut se mettre a l'abri.
	dangerDistance = 70,
	-- On cherche une cachette libre dans ce rayon (studs).
	hideSearchRadius = 90,
	-- Le temps de reaction d'un humain (s), tire a chaque danger.
	reactionMin = 0.35,
	reactionMax = 1.1,
	-- A chaque ouverture, une chance de mal jouer (rester a decouvert,
	-- choisir une mauvaise cachette) : un joueur moyen se trompe aussi.
	mistakeChance = 0.2,
	-- Bloque (moins de ce deplacement en 2 s) : on recalcule le chemin.
	stuckDistance = 2,
	stuckSeconds = 2,
	-- Bloque autant de fois de suite : il renonce, et evite cette cachette
	-- un moment (s).
	stuckTries = 3,
	avoidSeconds = 30,
	-- Ils quittent leur cachette avant d'etre flaires, quand la mefiance
	-- depasse ce niveau (un peu apres l'avertissement que voit un joueur).
	leaveSuspicion = 0.8,
	-- Entre deux deplacements, ils restent un moment (s) dans une cachette.
	hideMinSeconds = 8,
	hideMaxSeconds = 30,
	-- Sans cachette libre, un coin a l'abri du regard : cherche sur 3 cercles
	-- jusqu'a 40 studs, 12 points chacun (36 rayons au plus, seulement quand
	-- il en a besoin), sans monter ni descendre de plus de 8 studs.
	coverRadius = 40,
	coverRings = 3,
	coverSamples = 12,
	coverClimb = 8,
	-- La hauteur de la tete au-dessus du sol (studs), pour la ligne de vue.
	headHeight = 4.5,
	-- Arrive (studs) : a son but, et a chaque etape de son chemin.
	arriveDistance = 4,
	waypointReach = 3,
	-- Rentrer dans le cercle : viser a cette fraction du rayon depuis le
	-- centre (pas le bord, ou il ressortirait au prochain resserrement).
	insideFraction = 0.6,
	-- Le chemin : la largeur et la hauteur d'un personnage.
	agentRadius = 2,
	agentHeight = 5,
	-- Les teintes de peau, en { r, v, b }.
	skins = {
		{ 234, 184, 146 },
		{ 204, 142, 105 },
		{ 160, 105, 74 },
		{ 105, 64, 40 },
		{ 250, 214, 180 },
	},
	-- Les noms, inventes (jamais de vrais comptes Roblox).
	names = {
		"PixelBrigand",
		"LunaCroquette",
		"TomTomBzz",
		"NoaLeRapide",
		"Kiwi_Fantome",
		"ZazouMax",
		"CapitaineFrite",
		"MiloCascade",
		"LeaTornade",
		"BlobDuNord",
		"GaloPin42",
		"SnowNugget",
		"Ritonix",
		"PetitPoisVert",
		"MangoFlash",
		"Choco_Ninja",
		"VanillaRex",
		"Tobyzarbi",
		"JojoLaBrume",
		"ElianCrochet",
		"NinaPapillon",
		"Krokmou_77",
		"SachaPiment",
		"FripouilleXD",
		"OscarVolt",
		"BiscotteGG",
		"RubisPotiron",
		"MaelleComete",
		"TitanGlouglou",
		"LouLouRocket",
	},
}

--------------------------------------------------------------------------------
-- CE QUE VOIT LE JOUEUR — l'ecran, le ciel, les faisceaux, le cercle
--------------------------------------------------------------------------------

Config.view = {
	-- L'Oeil suit du regard, mais pas plus loin que cet angle depuis la
	-- verticale (degres) : au-dela, la paupiere decouvrirait le dos du globe.
	eyeTurnMax = 38,
	-- La vitesse a laquelle il tourne (fraction du chemin par seconde).
	eyeTurnRate = 2.5,
	-- Les paupieres s'ouvrent ou se ferment en ce temps (s).
	lidSeconds = 1.2,
	-- L'iris et la pupille depassent du globe : paupieres fermees, ils
	-- passeraient au travers (vu en image). Ils s'effacent sous cette
	-- ouverture (0 ferme, 1 ouvert).
	irisShowAt = 0.3,
	irisParts = { "Iris", "IrisChaud", "AnneauIris", "Lisere", "Fibre", "Pupille", "Reflet" },
	-- Les couleurs sont en { rouge, vert, bleu } (0 a 255) : Config se charge
	-- aussi dans les tests, ou Color3 n'existe pas.
	-- Le faisceau : une colonne de lumiere rouge orangee, et sa tache au sol.
	beamColor = { 255, 70, 40 },
	beamTransparency = 0.82,
	spotTransparency = 0.45,
	-- La lumiere que la tache jette au sol.
	spotBrightness = 6,
	spotRange = 40,
	spotAngle = 60,
	-- Il glisse vers sa position publiee (fraction par seconde) : le serveur
	-- n'en envoie que dix par seconde.
	beamSmoothing = 10,
	-- Le mur du cercle : des panneaux rouges translucides, assez hauts pour se
	-- voir de loin par-dessus les toits.
	wallSegments = 96,
	wallHeight = 160,
	wallColor = { 200, 30, 24 },
	wallTransparency = 0.7,
	-- Le prochain cercle : un trait blanc au sol.
	nextColor = { 240, 240, 240 },
	nextHeight = 3,
	nextTransparency = 0.35,
	-- Le ciel rougit quand l'Oeil s'ouvre.
	openTint = { 255, 205, 195 },
	warningTint = { 255, 225, 215 },
	-- La visee de la chute : vitesse du reticule (studs/s) et envois au serveur.
	aimSpeed = 260,
	aimSendSeconds = 0.5,
	-- Vue de la pupille, les nuages et la brume noient la carte (vu en jeu) :
	-- le temps de viser, on les ecarte chez soi.
	aimAtmosphereDensity = 0.15,
	-- Le stick ne bouge rien sous ce seuil (une manette au repos derive).
	stickDeadZone = 0.15,
	-- En spectateur, la camera se tient derriere et au-dessus (studs).
	spectateDistance = 14,
	spectateHeight = 6,
	-- La police des textes de l'Oeil (Survivor : la machine a ecrire).
	font = "SpecialElite",
}

--------------------------------------------------------------------------------
-- LE RESEAU DE LA PARTIE — les intentions du client
--------------------------------------------------------------------------------

Config.remotes = {
	folder = "Remotes",
	-- Le point vise pour l'ejection (x, z).
	aim = "Viser",
	-- Sortir de sa cachette.
	leave = "Sortir",
}

return Config
