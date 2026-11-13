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
			-- La liste des joueurs du jeu (R3 etait garde en reserve ; Tab
			-- comme partout sur Roblox).
			playerList = { gamepad = "ButtonR3", keyboard = "Tab" },
		},
		-- Au salon : X maintenu sur quelqu'un l'invite (ou accepte son
		-- invitation, par l'invite), Y change de mode, R2 se dit pret, B
		-- quitte son groupe, croix haut invite des amis Roblox.
		lobby = {
			jump = { gamepad = "ButtonA", keyboard = "Space" },
			invite = { gamepad = "ButtonX", keyboard = "E" },
			mode = { gamepad = "ButtonY", keyboard = "F" },
			ready = { gamepad = "ButtonR2", keyboard = "Return" },
			leaveGroup = { gamepad = "ButtonB", keyboard = "Backspace" },
			robloxInvite = { gamepad = "DPadUp", keyboard = "I" },
			playerList = { gamepad = "ButtonR3", keyboard = "Tab" },
			-- La boutique (avec les tirages, le passe et ses cosmetiques).
			shop = { gamepad = "DPadLeft", keyboard = "O" },
		},
		-- Dans le panneau de la boutique : on choisit a la croix, on change
		-- d'onglet avec L1 / R1, A achete ou equipe, B ferme.
		shopPanel = {
			up = { gamepad = "DPadUp", keyboard = "Up" },
			down = { gamepad = "DPadDown", keyboard = "Down" },
			previousTab = { gamepad = "ButtonL1", keyboard = "Q" },
			nextTab = { gamepad = "ButtonR1", keyboard = "R" },
			confirm = { gamepad = "ButtonA", keyboard = "Return" },
			close = { gamepad = "ButtonB", keyboard = "Backspace" },
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
			playerList = { gamepad = "ButtonR3", keyboard = "Tab" },
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
	-- Les zones de la carte, un dossier chacune (pour les dessiner sur la
	-- carte de l'ecran).
	zones = "Zones",
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
	-- Le depart : on vise depuis la pupille, puis l'Oeil crache tout le monde.
	aimSeconds = 8,
	-- La vitesse de la comete (studs/s) : de la pupille (~600 de haut) au
	-- sol en 3 a 5 s, assez vite pour que ce soit une attaque, assez lent pour
	-- voir les autres filer.
	cometSpeed = 180,
	-- La premiere ouverture de l'Oeil, apres le premier impact (CONCEPT.md).
	firstOpenDelay = 20,
	-- L'ecran de victoire, avant le retour au salon.
	endSeconds = 12,
	-- Avant la visee (et sur un serveur de partie, en attendant les
	-- arrivants), on se pose pres du centre, dans ce rayon (studs).
	waitRadius = 80,
	-- Les personnages se posent un peu au-dessus du sol vise (studs) : la
	-- hauteur d'un bassin.
	landingHeight = 3,
	-- La comete : feu orange, sombre au bout ; l'impact souffle sans blesser.
	cometFireSize = 8,
	cometFireHeat = 20,
	-- Sans cosmetique : orange vif, sombre au bout.
	cometColor = { 255, 120, 40 },
	cometColor2 = { 120, 20, 10 },
	impactRadius = 6,
	-- Les attributs de Workspace que lit l'interface.
	phaseAttribute = "Phase",
	regardAttribute = "Regard",
	regardTitleAttribute = "RegardTitre",
	eyeOpenAttribute = "OeilOuvert",
	phaseEndsAttribute = "PhaseFin",
	aliveAttribute = "EnVie",
	-- La liste des joueurs du jeu, sur Workspace (JSON : nom, equipe, en vie).
	listAttribute = "ListeJoueurs",
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
-- LES POUVOIRS DE L'OEIL — un tire au sort a chaque Regard (CONCEPT.md)
--------------------------------------------------------------------------------

-- Valide le 12 novembre 2026 : un pouvoir au hasard a chaque Regard, jamais
-- deux fois le meme, jamais un qui ne change rien, garde jusqu'a la fin.
-- Equilibre par l'assistant (DECISIONS.md) : chacun doit se sentir dans une
-- ouverture, aucun ne doit rendre une cachette bien choisie inutile.
Config.eyePowers = {
	-- Attributs de Workspace : le dernier pouvoir gagne (« nom|heure ») et la
	-- liste de ceux qu'il a (noms separes par « · »).
	announceAttribute = "PouvoirOeil",
	listAttribute = "PouvoirsOeil",
	-- L'annonce reste a l'ecran ce temps (s) : le temps de la lire deux fois.
	announceSeconds = 7,
	list = {
		hearAll = {
			name = "Il entend tout",
			text = "Il entend tout bruit, même la marche, dès maintenant.",
		},
		rage = {
			name = "La rage",
			text = "Une rafale sur deux, un faisceau de plus.",
			-- Une rafale sur `every`, `beams` faisceaux en plus : un de plus
			-- double la chasse dans une petite partie, sans la noyer.
			every = 2,
			beams = 1,
		},
		feint = {
			name = "Le faux départ",
			text = "Parfois, il se ferme et se rouvre aussitôt.",
			-- Une pause sur trois environ ne dure que `seconds` : assez pour
			-- sortir la tete, pas pour fouiller (une fouille dure 1,5 s, mais
			-- il faut aussi sortir et rentrer).
			chance = 0.35,
			seconds = 2,
		},
		longBurst = {
			name = "Le regard long",
			text = "Une rafale par Regard dure deux fois plus longtemps.",
			factor = 2,
			-- La rafale allongee est l'une des `among` premieres : elle tombe
			-- toujours dans le Regard, meme le plus court (3 min 30).
			among = 3,
		},
		hunger = {
			name = "La faim",
			text = "Il arrache moitié plus de cachettes.",
			ripFactor = 1.5,
		},
		slowSure = {
			name = "L'œil lent mais sûr",
			text = "Il poursuit un peu moins vite, mais garde ta piste 2 s de plus.",
			-- 15 % plus lent : au Regard 5 (22), la course le distance enfin
			-- un peu ; la piste gardee compense largement.
			chaseFactor = 0.85,
			memoryBonus = 2,
		},
		flair = {
			name = "Le flair",
			text = "Il arrache d'abord les cachettes occupées depuis longtemps.",
		},
		slant = {
			name = "Le regard rasant",
			text = "Sa lumière arrive en biais : sous un auvent, on est vu.",
			-- Un second regard part a cette hauteur (degres au-dessus de
			-- l'horizon) : il passe sous les avancees, pas a travers les murs.
			elevation = 30,
		},
		grudge = {
			name = "La rancune",
			text = "Les cachettes marquées le restent jusqu'à la fin.",
		},
		flash = {
			name = "L'éclair",
			text = "Chaque rafale s'ouvre par un éclair : qui est à découvert brille.",
			-- Ceux qui sont a decouvert brillent ce temps pour tout le monde.
			seconds = 2,
			color = { 255, 70, 50 },
		},
		heavyLid = {
			name = "La paupière lourde",
			text = "Ses pauses entre deux rafales raccourcissent d'un tiers.",
			closedFactor = 2 / 3,
		},
		comeback = {
			name = "Le retour",
			text = "Quand il perd ta piste, il revient voir 5 s plus tard.",
			delay = 5,
			-- Il fouille la derniere position ce temps, puis repart.
			linger = 4,
		},
		wind = {
			name = "Le souffle",
			text = "Chaque rafale commence par un coup de vent qui pousse.",
			-- Moins qu'une poussee (34) : il deplace, il ne fait pas tomber.
			speed = 26,
			lift = 6,
		},
		prints = {
			name = "Les empreintes",
			text = "Qui court laisse des traces rouges que l'Œil suit.",
			-- Une trace tous les `every` s, qui reste `seconds` s.
			every = 0.4,
			seconds = 10,
			-- Un faisceau sans cible prend une piste a moins de cette distance
			-- et la remonte vers la trace la plus recente (studs).
			followRange = 70,
			-- Une trace se pose si le sol est a moins de cette distance sous le
			-- bassin (studs) : debout, il est a ~3 ; en l'air, pas de trace.
			probe = 5,
			size = { 1.4, 0.15, 2 },
			color = { 170, 20, 20 },
		},
	},
	folder = "Empreintes",
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
	-- La glissade (B en courant) : un elan qui decroit, la tete basse. Assez
	-- pour passer sous un camion, pas assez pour battre la course sur une rue.
	slideSpeed = 34,
	slideSeconds = 0.8,
	slideHipDrop = 1.6,
	slideCooldown = 1.2,
	-- Courir, pour le jeu : au-dessus de cette vitesse au sol (studs/s), Y
	-- plaque au lieu de pousser et B glisse au lieu de s'accroupir. Entre la
	-- marche (14) et la course (22).
	runningAbove = 18,
	-- S'agripper (A en l'air) : un rebord jusqu'a cette hauteur au-dessus des
	-- pieds (un mur de jardin, un conteneur, un toit plat de garage), devant
	-- soi a moins de `mantleReach`. Se hisser prend `mantleSeconds`.
	mantleHeight = 9,
	mantleReach = 3,
	mantleSeconds = 0.45,
	-- S'allonger (B maintenu a l'arret) et ramper : tres lent, la tete au
	-- ras du sol (sous un camion, derriere un trottoir). Le bassin descend
	-- presque jusqu'au sol (la hauteur de hanche d'un corps standard est ~2).
	proneHoldSeconds = 0.4,
	proneSpeed = 4,
	-- L'animation couche deja le corps sous le bassin : le bassin descend un
	-- peu, pas jusqu'au sol (sinon le corps s'enfonce).
	proneHipDrop = 0.5,
}

-- Les animations des postures (docs/ASSETS.md), jouees par chaque ecran sur
-- tous les personnages d'apres leurs attributs. Accroupi et ramper se figent
-- quand on ne bouge pas (sous `stillSpeed`).
Config.postures = {
	prone = 76447610279679,
	crouch = 110814117323360,
	knockedOut = 88589009991204,
	carried = 94783137609755,
	stillSpeed = 1,
	fadeSeconds = 0.2,
	refreshSeconds = 0.1,
}

--------------------------------------------------------------------------------
-- LE CORPS A CORPS (CONCEPT.md, Interactions entre joueurs, valide le 12/11)
--------------------------------------------------------------------------------

Config.combat = {
	-- Le coup (R2) : devant soi, a portee de bras.
	hitRange = 6,
	-- Le cone devant soi (cosinus) : 0,5 = 60 degres de chaque cote, on
	-- touche sans viser au millimetre a la manette.
	hitCone = 0.5,
	-- Entre deux coups (s) : trois coups prennent au moins 1,2 s, le temps de
	-- fuir pour celui qui voit venir.
	hitCooldown = 0.6,
	-- Trois coups mettent K.O. (CONCEPT.md) ; la batte en mettra deux.
	hitsToKO = 3,
	-- Une serie s'oublie apres ce temps sans coup (s).
	comboResetSeconds = 4,
	-- Le K.O. : 2 a 3 s (CONCEPT.md), on prend le haut.
	koSeconds = 2.5,
	-- Un coup fait reculer un peu (studs/s), pour qu'on le sente.
	hitPush = 14,

	-- La poussee (Y a l'arret) : elle chasse, sans faire tomber.
	shoveRange = 6,
	-- 48 envoyait a 17-27 studs (mesure le 12/11) : on vise une dizaine,
	-- assez pour sortir d'une ombre ou entrer dans un faisceau.
	shoveSpeed = 34,
	shoveLift = 12,
	shoveCooldown = 1.2,

	-- Le plaquage (Y en courant) : on tombe tous les deux, l'autre plus
	-- longtemps (CONCEPT.md).
	tackleRange = 7,
	tackleSelfFall = 1,
	tackleTargetFall = 2.2,
	tackleCooldown = 3,
	tackleLunge = 30,

	-- Le tacle glisse (B en courant vers quelqu'un) : il tombe 1,5 s et ta
	-- glissade continue (CONCEPT.md).
	slideTackleRange = 5,
	slideTackleFall = 1.5,

	-- Porter (Y maintenu sur un K.O.) : on le souleve au-dessus de sa tete.
	carryHoldSeconds = 0.4,
	carryRange = 6,
	-- Assez haut pour que le corps porte, allonge par son animation (2 studs
	-- sous son bassin), passe au-dessus de la tete du porteur.
	carryHeight = 5.5,
	-- On marche lentement en portant : on ne traverse pas la carte avec un
	-- otage.
	carrySpeed = 9,
	-- Porte, le K.O. dure jusqu'a ce temps depuis qu'on l'a souleve (s) : de
	-- quoi faire quelques pas jusqu'a un faisceau, pas le garder.
	carryMaxSeconds = 6,
	-- Prolongation du K.O. a chaque pas du service (s), plus que son pas.
	carryRefresh = 0.5,
	-- Jeter (Y) : quelques metres devant (CONCEPT.md), et il reste au sol.
	-- 42 envoyait a 40-48 studs (mesure le 12/11) : bien plus que « quelques
	-- metres ».
	throwSpeed = 22,
	throwLift = 18,
	thrownFall = 1.5,

	-- La porte dans la figure (R2 cache, au moment ou on sort) : renverse
	-- qui se tient devant l'abri.
	burstRange = 6,
	burstFall = 1.5,

	-- Toquer a un abri (R2 dessus) : le bruit attire l'Oeil vers l'abri pendant
	-- `knockNoiseSeconds`, quel que soit le Regard (c'est voulu, on denonce).
	knockRange = 7,
	knockNoiseSeconds = 4,
	knockCooldown = 2,
	-- Un coup qui porte fait du bruit (l'Oeil l'entend au Regard 4).
	hitNoiseSeconds = 2,

	-- L'elan d'un coup ou d'un jet dure ce temps (s), puis la physique reprend.
	impulseSeconds = 0.2,
	-- Le pas du service (s) : les chutes, les porteurs.
	stepSeconds = 0.1,

	-- Les attributs publies sur le participant (le client et les bots lisent).
	-- Au sol jusqu'a cette heure du serveur.
	downAttribute = "AuSol",
	-- Accroupi (vrai), pour que les autres le voient accroupi.
	crouchAttribute = "Accroupi",
	-- Allonge (vrai) : on peut le tirer par les pieds.
	proneAttribute = "Allonge",
	-- Tirer par les pieds (X maintenu sur quelqu'un d'allonge, CONCEPT.md) :
	-- en une seconde, il est sorti de `back` studs vers celui qui tire, et
	-- au sol `fall` s, reveille et a decouvert.
	pull = { seconds = 1, distance = 7, back = 4, fall = 1, text = "Tirer" },
	-- Vrai pendant un K.O. (pas pendant une simple chute).
	koAttribute = "KO",
	-- Sur le porteur : le nom de celui qu'il porte ; sur le porte : vrai.
	carryingAttribute = "Porte",
	carriedAttribute = "EstPorte",
}

--------------------------------------------------------------------------------
-- LA FOUILLE ET LES OBJETS (CONCEPT.md, Les objets, valide le 12 novembre)
--------------------------------------------------------------------------------

Config.loot = {
	-- Maintenir X sur un meuble (le meuble de la carte, dans Carte.Fouilles).
	-- 1,5 s : assez pour hesiter quand le ciel rougit (CONCEPT.md).
	searchSeconds = 1.5,
	promptDistance = 7,
	-- Fouiller fait du bruit : l'Oeil l'entend quand il entend les coups.
	searchNoiseSeconds = 2,
	-- Combien de meubles ont quelque chose a chaque partie : par participant
	-- au depart, jamais moins (la carte en a 276). Les autres sont vides et
	-- se fouillent pour rien : on ne sait pas d'avance lesquels.
	perParticipant = 7,
	minFilled = 60,
	-- Chances par fouille (CONCEPT.md, a regler) : commun, peu commun, rare,
	-- epique. Les legendaires ne se fouillent jamais.
	weights = { common = 56, uncommon = 25, rare = 13, epic = 6 },
	-- Les endroits dangereux donnent plus d'epiques (CONCEPT.md) : le Cratere,
	-- sans abri d'en haut. Multiplie la chance epique.
	dangerTables = { cratere = true },
	dangerEpicFactor = 3,
	-- Un objet par terre (sac plein, aspire) : on le ramasse en maintenant X.
	pickupSeconds = 0.4,
	-- Un objet par terre disparait apres ce temps (s) : la carte ne se remplit
	-- pas de restes.
	groundSeconds = 120,
	-- Ou il tombe autour du point (studs) : deux objets ne s'empilent pas.
	groundScatter = 2,
	-- L'attribut d'un meuble deja fouille cette partie.
	searchedAttribute = "Fouille",
	-- Le dossier de ce que la partie pose (fumee, flaques, objets, relique).
	folder = "ObjetsDeLaPartie",
}

Config.bag = {
	-- 4 places (CONCEPT.md) : on choisit ce qu'on garde.
	slots = 4,
	-- Attributs du participant : le contenu (ids separes par des virgules,
	-- vide pour une place libre) et la place choisie (1 a 4).
	attribute = "Sac",
	selectedAttribute = "SacChoix",
	-- L2 ne repart pas avant ce temps (s) : un double appui ne gaspille pas
	-- deux objets.
	useCooldown = 0.5,
	-- Voler (X maintenu sur un K.O., CONCEPT.md) : le temps de maintien.
	stealSeconds = 0.8,
	stealDistance = 7,
	-- Un message court pour le joueur (« Rien ici. »), et une annonce pour
	-- tous (Relique, Larme) : « texte|heure ».
	messageAttribute = "Message",
	announceAttribute = "Annonce",
}

-- Le lancer (L2 maintenu : viser, lacher : lancer).
Config.throw = {
	-- Vitesse au depart (studs/s) et gravite de Roblox : 60 ne portait qu'a
	-- 20 studs (calcul du test). A 100, en visant droit devant, ~40 studs ;
	-- au plus loin (45 degres) ~50 : une rue, pas un quartier.
	speed = 100,
	gravity = 196.2,
	-- Le lancer part un peu au-dessus du regard (radians) : en visant droit
	-- devant, l'objet monte d'abord.
	lift = 0.3,
	-- On cherche le point de chute pendant au plus ce temps (s), par pas.
	maxSeconds = 3,
	stepSeconds = 0.05,
	-- Le trait de visee dessine sur le client : tant de points.
	previewPoints = 30,
	-- Le depart, devant les yeux (studs).
	handForward = 1.5,
}

-- Les raretes et leurs couleurs habituelles (CONCEPT.md) : gris, vert, bleu,
-- violet, or.
Config.rarities = {
	common = { name = "Commun", color = { 190, 190, 190 } },
	uncommon = { name = "Peu commun", color = { 90, 200, 90 } },
	rare = { name = "Rare", color = { 80, 150, 255 } },
	epic = { name = "Épique", color = { 180, 90, 230 } },
	legendary = { name = "Légendaire", color = { 255, 190, 40 } },
}

-- Le catalogue (CONCEPT.md, valide le 12 novembre, a equilibrer en jouant).
-- `kind` : throw (L2 maintenu, on lance), use (L2, effet sur soi ou devant
-- soi), spot (L2 pres d'une cachette ou dedans), passive (rien a faire).
-- `shield` : combien de secondes, au mieux, il protege de l'Oeil ; c'est la
-- duree de son effet (le test d'equilibrage et les bots le lisent).
Config.items = {
	smoke = {
		name = "Fumigène",
		rarity = "common",
		kind = "throw",
		-- Un nuage qui coupe la ligne de vue 15 s (CONCEPT.md) : une boule de
		-- 14 studs, assez pour cacher deux joueurs, pas une rue.
		seconds = 15,
		radius = 14,
		shield = 15,
	},
	firecracker = {
		name = "Pétard",
		rarity = "common",
		kind = "throw",
		-- Un bruit enorme : l'Oeil l'entend a tout Regard (CONCEPT.md).
		seconds = 5,
		shield = 0,
	},
	flare = {
		name = "Fusée éclairante",
		rarity = "common",
		kind = "throw",
		-- Attire un faisceau ; tombee a moins de `stickRadius` d'un joueur,
		-- elle s'accroche a lui.
		seconds = 6,
		stickRadius = 6,
		shield = 0,
	},
	chalk = {
		name = "Craie",
		rarity = "common",
		kind = "spot",
		-- Marque la cachette : l'Oeil vient l'arracher a sa prochaine
		-- ouverture.
		shield = 0,
	},
	bottle = {
		name = "Bouteille",
		rarity = "common",
		kind = "throw",
		-- Etourdit 1 s qui est a moins de `radius` du point de chute.
		radius = 4,
		fall = 1,
		shield = 0,
	},
	oil = {
		name = "Flaque d'huile",
		rarity = "common",
		kind = "throw",
		-- Qui court dessus glisse et tombe 1,5 s ; la flaque reste 20 s.
		radius = 7,
		fall = 1.5,
		seconds = 20,
		shield = 0,
	},
	torch = {
		name = "Lampe torche",
		rarity = "common",
		kind = "use",
		-- Ebloui 2 s, le joueur devant soi a moins de 25 studs.
		range = 25,
		seconds = 2,
		shield = 0,
	},
	bell = {
		name = "Clochette",
		rarity = "common",
		kind = "spot",
		-- Sonne quand quelqu'un y entre : tous ceux a moins de `hearRadius`
		-- l'entendent (et voient d'ou ca vient) pendant `seconds`.
		hearRadius = 150,
		seconds = 4,
		shield = 0,
	},
	bat = {
		name = "Batte",
		rarity = "uncommon",
		kind = "use",
		-- K.O. en deux coups au lieu de trois, pour `charges` coups qui
		-- portent : un objet se consomme (CONCEPT.md).
		hitsToKO = 2,
		charges = 6,
		shield = 0,
	},
	trap = {
		name = "Piège à loup",
		rarity = "uncommon",
		kind = "spot",
		-- Bloque 3 s celui qui sort de la cachette.
		fall = 3,
		shield = 0,
	},
	binoculars = {
		name = "Jumelles",
		rarity = "uncommon",
		kind = "use",
		-- Les joueurs a decouvert jusqu'a 250 studs, signales 5 s.
		range = 250,
		seconds = 5,
		shield = 0,
	},
	planks = {
		name = "Planches",
		rarity = "uncommon",
		kind = "spot",
		-- Barricade sa cachette 20 s, de l'interieur : personne ne la deloge.
		seconds = 20,
		shield = 0,
	},
	fakeBox = {
		name = "Carton piégé",
		rarity = "uncommon",
		kind = "use",
		-- Une fausse cachette posee devant soi : qui y entre est ejecte et
		-- flaire par l'Oeil.
		prefab = "Carton",
		distance = 5,
		shield = 0,
	},
	stinkBomb = {
		name = "Boule puante",
		rarity = "uncommon",
		kind = "throw",
		-- Tombee a moins de `radius` d'une cachette : celui qui y est sort.
		-- Le nuage vert se voit `seconds`.
		radius = 6,
		seconds = 4,
		shield = 0,
	},
	net = {
		name = "Filet",
		rarity = "uncommon",
		kind = "throw",
		-- Immobilise 2 s qui est a moins de `radius` du point de chute.
		radius = 5,
		fall = 2,
		shield = 0,
	},
	cloak = {
		name = "Cape d'ombre",
		rarity = "rare",
		kind = "use",
		-- La jauge monte moitie moins vite pendant 20 s : vaut 10 s de
		-- protection.
		seconds = 20,
		fillFactor = 0.5,
		shield = 10,
	},
	padlock = {
		name = "Cadenas",
		rarity = "rare",
		kind = "spot",
		-- Comme les planches, 45 s, seulement dans une cachette solide.
		seconds = 45,
		solidOnly = true,
		shield = 0,
	},
	mirror = {
		name = "Miroir",
		rarity = "rare",
		kind = "use",
		-- Renvoie le faisceau qui te poursuit vers le joueur le plus proche ;
		-- tu es ignore par ce faisceau `seconds`.
		seconds = 4,
		shield = 4,
	},
	grapple = {
		name = "Grappin",
		rarity = "rare",
		kind = "use",
		-- Un rebord jusqu'a 60 studs devant le regard ; on y monte en 0,8 s.
		range = 60,
		seconds = 0.8,
		shield = 0,
	},
	adrenaline = {
		name = "Adrénaline",
		rarity = "rare",
		kind = "use",
		-- 8 s : on court a la course (22, jamais plus vite que l'Oeil au
		-- dernier Regard) dans toutes les postures, sans bruit, et on se
		-- releve deux fois plus vite.
		seconds = 8,
		fallFactor = 0.5,
		shield = 0,
	},
	leadSheet = {
		name = "Bâche de plomb",
		rarity = "epic",
		kind = "use",
		-- Immobile dessous, le faisceau ne voit pas pendant 10 s ; bouger plus
		-- vite que `stillSpeed` la souleve (on redevient visible).
		seconds = 10,
		stillSpeed = 2,
		shield = 10,
	},
	dummy = {
		name = "Mannequin",
		rarity = "epic",
		kind = "use",
		-- Pose devant soi, l'Oeil le prend pour un joueur et le poursuit 10 s.
		seconds = 10,
		distance = 4,
		shield = 10,
	},
	glassEye = {
		name = "Œil de verre",
		rarity = "epic",
		kind = "use",
		-- 15 s : les joueurs a moins de 80 studs, a travers les murs.
		seconds = 15,
		range = 80,
		shield = 0,
	},
	redFlare = {
		name = "Fusée rouge",
		rarity = "epic",
		kind = "throw",
		-- Tous les faisceaux sur un point pendant 5 s.
		seconds = 5,
		shield = 5,
	},
	stolenGaze = {
		name = "Le Regard volé",
		rarity = "legendary",
		kind = "use",
		-- 10 s : on dirige un faisceau la ou l'on regarde.
		seconds = 10,
		shield = 10,
	},
	tear = {
		name = "La Larme de l'Œil",
		rarity = "legendary",
		kind = "use",
		-- Il cligne : tous les faisceaux s'eteignent 5 s, partout.
		seconds = 5,
		shield = 5,
	},
	cocoon = {
		name = "Le Cocon de secours",
		rarity = "legendary",
		kind = "passive",
		-- Aspire, recrache aussitot sur place (une fois). Ne marche plus a
		-- partir de ce Regard (quand le goulag ferme, CONCEPT.md).
		closedFromRegard = 4,
		shield = 0,
	},
	fragment = {
		name = "Le Fragment de Fissure",
		rarity = "legendary",
		kind = "use",
		-- 15 s invisible pour l'Oeil, mais tu brilles pour les joueurs.
		seconds = 15,
		shield = 15,
	},
}

-- Les Reliques (CONCEPT.md) : l'Oeil lache un legendaire au milieu d'une
-- place, annonce a tous. Un ou deux par partie : au debut de ces Regards.
Config.relics = {
	regards = { 3, 4 },
	-- Elle tombe a moins de cette fraction du rayon du cercle, du centre :
	-- dedans, sur un emplacement de cachette de la carte.
	insideFraction = 0.5,
	-- Elle brille, visible de loin.
	lightRange = 40,
	-- La position de la relique en cours (Vector3), pour l'ecran.
	attribute = "Relique",
}

-- Les effets que les objets posent sur un participant (heure de fin, serveur).
Config.effects = {
	-- Invisible pour l'Oeil (Fragment, Bache immobile).
	veiledAttribute = "Voile",
	-- La jauge monte moins vite (Cape) : le facteur en cours.
	cloakAttribute = "Cape",
	-- Adrenaline.
	adrenalineAttribute = "Adrenaline",
	-- Ebloui (lampe torche) : l'ecran blanchit.
	dazzledAttribute = "Ebloui",
	-- Voir les autres (Jumelles, Oeil de verre) : l'heure de fin, la portee,
	-- et si l'on voit aussi les caches (a travers les murs).
	revealAttribute = "Revele",
	revealRangeAttribute = "ReveleDistance",
	revealHiddenAttribute = "ReveleCaches",
	-- Les coups de batte qui restent.
	batAttribute = "Batte",
	-- On dirige un faisceau (Regard vole).
	steerAttribute = "Pilote",
	-- Une clochette a sonne : sur Workspace, la position (Vector3) et l'heure.
	bellAttribute = "Clochette",
	bellTimeAttribute = "ClochetteHeure",
	-- Le Cocon de secours, garde jusqu'a la capture.
	cocoonAttribute = "Cocon",
	-- Le Grappin : le point ou monter (Vector3) et l'heure du lancer.
	grappleAttribute = "GrappinVers",
	grappleTimeAttribute = "GrappinHeure",
	-- Sous la Bache de plomb : vrai immobile (invisible), faux en bougeant.
	sheetAttribute = "Bache",
	-- La lueur : le Fragment se voit de loin, un legendaire dans le sac
	-- juste un peu (CONCEPT.md : « tout le monde veut le lui prendre »).
	fragmentFill = 0.3,
	legendaryFill = 0.85,
	legendaryOutline = 0.5,
	-- Brille pour les joueurs (Fragment).
	glowColor = { 255, 190, 40 },
	-- Le service des effets tourne a ce pas (s).
	stepSeconds = 0.1,
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
-- LES REPRIS — les yeux de l'Oeil au sol, contre le camping (CONCEPT.md)
--------------------------------------------------------------------------------

-- Valide le 12 novembre 2026. Ils ne tuent jamais : ils signalent, delogent
-- ou mettent K.O. C'est toujours l'Oeil qui aspire, par une vraie ligne de
-- vue. Garde-fous de Josh : « il faut que ca reste jouable ».
Config.repris = {
	-- A chaque fermeture de l'Oeil, il en recrache 1 pour ce nombre de
	-- joueurs en vie, Regard par Regard (CONCEPT.md : 1 pour 8, jusqu'a 1
	-- pour 3). Au Regard 5 il ne se ferme plus : a chaque rafale.
	perPlayers = { 8, 7, 6, 4, 3 },
	-- Le plafond : au plus 1 Repris en vie pour 2 joueurs en vie.
	capRatio = 0.5,
	-- Au debut de chaque Regard, l'Oeil en re-aspire cette part.
	reaspireFraction = 0.5,
	-- Jamais plus de 2 Repris sur le meme joueur.
	maxPerTarget = 2,
	-- Ils tombent a cette distance d'un joueur (studs) : assez loin pour le
	-- voir venir, assez pres pour qu'il compte.
	spawnMin = 30,
	spawnMax = 60,
	-- Un joueur cache pese ce poids dans le choix de qui ils visent a la
	-- chute (les campeurs d'abord, CONCEPT.md).
	hiddenWeight = 3,
	-- La chute : de cette hauteur, en ce temps, dans une trainee visible.
	dropHeight = 90,
	dropSeconds = 1.4,
	-- Re-aspires : ils remontent en ce temps avant de disparaitre.
	riseSeconds = 2.5,
	-- Les flaires sans rien a arracher : l'Oeil envoie autant de Repris
	-- (CONCEPT.md, la mefiance).
	flaggedSend = 2,
	-- Un joueur lent (accroupi, immobile) se remarque moins : leur vue
	-- porte moins loin (CONCEPT.md, les parades).
	slowSpeed = 8,
	slowSightFactor = 0.6,
	-- Ils voient quelqu'un si plus de cette part du regard passe (un
	-- buisson le cache a moitie, la fumee completement).
	seenAbove = 0.4,
	-- Ils gardent la piste de qui ils ont vu ce temps, puis vont voir ou il
	-- etait.
	memorySeconds = 3,
	-- Sans cible, ils rodent vers le joueur le plus proche dans ce rayon,
	-- sinon au hasard.
	roamRange = 150,
	roamStep = 25,
	-- Le pas de reflexion (s).
	thinkSeconds = 0.2,
	-- Les chemins (repris de Survivor).
	path = { radius = 2, height = 5, canJump = true },
	repathSeconds = 1.5,
	directRange = 14,
	stuckSeconds = 1.5,
	sidestepSeconds = 0.8,
	-- Un coup sur un Repris le fait reculer de cette vitesse (studs/s).
	hitPush = 18,
	-- Le crane genere pour Survivor (docs/ASSETS.md de Survivor), cree au
	-- demarrage du serveur.
	headMesh = "rbxassetid://104274234503331",
	-- Les animations du pack Zombie de Roblox (verifiees dans Survivor).
	animations = { walk = 616168032, run = 616163682, idle = 616158929 },
	-- La cendre de leur corps et la lueur de leurs yeux.
	ash = { 54, 52, 50 },
	folder = "Repris",
	-- L'attribut d'un Repris : sa sorte (pour les bots et l'ecran).
	kindAttribute = "Sorte",
	kinds = {
		wanderer = {
			name = "Errant",
			arrives = 1,
			-- Moins vite que la marche (14) : on le distance en marchant.
			speed = 8,
			hits = 3,
			sight = 60,
			-- S'il te voit, il crie : le faisceau le plus proche vient a
			-- l'endroit ou tu etais, `lureSeconds`. Jamais deux cris en
			-- moins de `cooldown` (CONCEPT.md : ils previennent).
			cry = { cooldown = 10, lureSeconds = 4 },
			look = { height = 1, width = 0.9, depth = 0.9, scale = 1, eyes = { 255, 120, 40 } },
		},
		crawler = {
			name = "Rampant",
			arrives = 1,
			speed = 7,
			hits = 3,
			-- Il sent ceux qui sont caches dans une cachette a cette
			-- distance, et les en arrache apres `evictSeconds` contre elle.
			smell = 14,
			evictSeconds = 1.5,
			evictReach = 5,
			-- Apres un arrachage, il ne sent plus rien ce temps (s).
			evictRest = 15,
			look = {
				height = 0.75,
				width = 1.1,
				depth = 1,
				scale = 0.9,
				eyes = { 200, 255, 120 },
			},
		},
		howler = {
			name = "Hurleur",
			arrives = 3,
			speed = 9,
			hits = 3,
			sight = 60,
			-- Il hurle : l'Oeil entend le bruit `noiseSeconds` (a tout
			-- Regard), et les Repris a `callRadius` accourent.
			howl = { cooldown = 12, noiseSeconds = 5, callRadius = 80 },
			look = {
				height = 1.1,
				width = 0.85,
				depth = 0.85,
				scale = 1.05,
				bigEye = { 255, 60, 40 },
			},
		},
		runner = {
			name = "Coureur",
			arrives = 3,
			-- Moins vite que la course (22) : on lui echappe en courant.
			speed = 19,
			-- Fragile : 2 coups (CONCEPT.md).
			hits = 2,
			sight = 70,
			-- Il grogne `windup` s avant de plaquer : le temps d'une glissade
			-- (CONCEPT.md : ils previennent). Le plaquage met au sol `fall` s.
			tackle = { range = 5, windup = 0.8, fall = 2, cooldown = 4, push = 26 },
			look = { height = 1.05, width = 0.75, depth = 0.75, scale = 1, eyes = { 255, 200, 80 } },
		},
	},
}

--------------------------------------------------------------------------------
-- LE GOULAG — le Ventre de l'Oeil (CONCEPT.md, Capture)
--------------------------------------------------------------------------------

-- Valide le 9 et le 12 novembre 2026 : aspire, on arrive dans le Ventre.
-- Des duels un contre un sur des plateformes dans le vide ; celui qui jette
-- l'autre est sauve, une seule fois par partie. Il ferme aux deux derniers
-- cercles. Nombre impair : un bot a la batte (Josh, 12 novembre).
Config.goulag = {
	-- Il ferme au debut de ce Regard (les deux derniers cercles sur 5).
	closesAtRegard = 4,
	-- Une manche toutes les 45 s au plus (CONCEPT.md) : decompte, duel,
	-- mort subite tiennent dedans.
	roundSeconds = 45,
	-- Le premier arrive attend au moins ceci : le temps de voir ou il est.
	firstWaitSeconds = 12,
	introSeconds = 3,
	duelSeconds = 25,
	suddenSeconds = 12,
	-- Le Ventre, loin de la carte et sous l'Oeil : rien de la partie ne s'y
	-- voit, rien du Ventre ne se voit de la partie.
	origin = { 3200, 420, 0 },
	-- Les plateformes de duel, en cercle autour des cages.
	platforms = 12,
	ringRadius = 90,
	-- Une plateforme fait ce rayon au depart, s'effrite jusqu'a
	-- `crumbleTo` pendant le duel, puis jusqu'a rien en mort subite.
	platformRadius = 13,
	crumbleTo = 9,
	platformThickness = 3,
	-- Les combattants partent a cette distance du centre, face a face.
	startOffset = 6,
	-- Sous la plateforme de plus que ceci : tombe.
	fallBelow = 20,
	-- C'est le dernier a avoir frappe, dans ce delai, qui est sauve.
	lastHitSeconds = 8,
	-- Les regles du combat au Ventre : la batte pour tous, 3 coups mettent
	-- K.O. 2 s, un coup a terre envoie voler (CONCEPT.md).
	rules = {
		hitsToKO = 3,
		comboResetSeconds = 4,
		koSeconds = 2,
		launchSpeed = 70,
		launchLift = 30,
	},
	-- Les cages : au centre, sur un pilier, d'ou l'on voit les duels. Assez
	-- espacees pour qu'on voie entre elles (a 22 de rayon, 24 cages se
	-- touchaient, vu en image).
	cages = 24,
	cageRadius = 32,
	cageSize = 6,
	-- La salle qui enferme le Ventre : demi-largeur, profondeur sous les
	-- plateformes, hauteur au-dessus, et le nombre de veines de braise.
	room = { half = 170, below = 140, above = 70, veins = 18 },
	-- Le bot de la manche impaire : il vise, frappe, et pousse vers le bord.
	botThinkSeconds = 0.15,
	botName = "Repris du Ventre",
	-- Sauve : on retombe dans le cercle de cette hauteur.
	returnHeight = 40,
	-- Attributs : sur le participant, ou il en est ("Cage", "Duel") ; sur
	-- Workspace, l'heure de la prochaine manche ; et le message de fin de duel.
	stateAttribute = "Goulag",
	roundAttribute = "GoulagManche",
	suddenAttribute = "GoulagMortSubite",
	resultAttribute = "GoulagIssue",
	-- L'issue d'un duel reste a l'ecran de tous ce temps (s).
	resultSeconds = 5,
	folder = "Ventre",
	colors = {
		stone = { 40, 30, 32 },
		wall = { 48, 14, 16 },
		pit = { 110, 12, 8 },
		vein = { 130, 20, 12 },
		rim = { 200, 30, 20 },
		cage = { 255, 60, 30 },
		ember = { 255, 110, 50 },
	},
}

--------------------------------------------------------------------------------
-- LES ESCOUADES — solo, duo, escouade de 4 (CONCEPT.md, valide le 12 novembre)
--------------------------------------------------------------------------------

Config.squads = {
	-- Le mode joue, en attendant que le salon le fasse choisir : l'escouade,
	-- parce que Josh joue avec ses amis (DECISIONS.md).
	mode = "squad",
	sizes = { solo = 1, duo = 2, squad = 4 },
	-- L'attribut d'un participant : le numero de son equipe ; sur Workspace,
	-- le mode de la partie en cours.
	attribute = "Equipe",
	modeAttribute = "ModePartie",
	-- Relever un ami K.O. (X maintenu, la meme invite que voler).
	reviveText = "Relever",
	-- Donner l'objet qu'on tient a un ami debout (X maintenu sur lui).
	giveSeconds = 0.6,
	giveDistance = 7,
	giveText = "Donner",
	-- Le cocon : sauve du Ventre, on revient pres d'un coequipier, dans un
	-- cocon qu'il ouvre en 3 coups (CONCEPT.md). Il signale sa place a
	-- l'Oeil apres `eyeDelay` s (propose : 8 s) ; si un faisceau le touche
	-- avant qu'il soit ouvert, c'est la capture definitive.
	cocoon = {
		hits = 3,
		eyeDelay = 8,
		lureSeconds = 40,
		offset = 6,
		size = { 4.5, 7, 4.5 },
		color = { 120, 30, 26 },
		glow = { 255, 80, 40 },
		-- Il luit : on le trouve, et l'Oeil aussi.
		lightRange = 14,
		lightBrightness = 3,
	},
	-- Les reperes des coequipiers, a travers les murs : un bleu froid, que
	-- rien d'autre n'utilise (le rouge est a l'Oeil, l'or aux legendaires).
	markerColor = { 90, 200, 255 },
	-- L'ecran : la liste en bas a gauche (au-dessus du sac), le nom au-dessus
	-- de la tete, et la frequence de mise a jour (s).
	view = {
		listWidth = 360,
		listHeight = 110,
		listTextSize = 18,
		tagWidth = 160,
		tagHeight = 26,
		tagAbove = 2.6,
		refreshSeconds = 0.25,
	},
	-- L'attribut d'un participant dans un cocon (vrai).
	cocoonAttribute = "DansCocon",
}

--------------------------------------------------------------------------------
-- LES ELIMINES — regarder, parier, quitter (CONCEPT.md, Capture)
--------------------------------------------------------------------------------

Config.bets = {
	-- On parie sur celui qu'on regarde, une fois, tant que le Ventre est
	-- ouvert (avant les deux derniers cercles) : parier sur les trois
	-- derniers serait trop facile (choix de l'assistant, a voir).
	untilRegard = 4,
	-- Un pari juste rapporte un peu de credits (CONCEPT.md : jamais le
	-- meilleur moyen d'en gagner). Toujours gratuit : miser des credits en
	-- ferait un jeu d'argent.
	rewardCredits = 15,
	-- Attributs : sur le joueur, le nom de celui sur qui il a parie ; sur
	-- le joueur qui a quitte, vrai.
	attribute = "Pari",
	leftAttribute = "AQuitte",
}

--------------------------------------------------------------------------------
-- LES SONS — repris de Survivor (docs/ASSETS.md de Survivor)
--------------------------------------------------------------------------------

-- Choisis sur le nom et la duree : l'assistant ne peut pas ecouter. Josh
-- juge en jouant (DECISIONS.md).
Config.sounds = {
	library = {
		-- Le ciel rougit : un grand coup sourd, puis un grondement.
		signal = { id = 9125484367, volume = 0.7 },
		menace = { id = 9125485274, volume = 0.35 },
		-- Son regard : un bourdonnement grave qui enfle quand un faisceau
		-- approche.
		regard = { id = 9114353261, volume = 0.8, looped = true },
		-- Ses paupieres qui s'ouvrent (et, plus lentement, se ferment).
		ouverture = { id = 9043343895, volume = 0.6 },
		-- Il aspire quelqu'un, il arrache une cachette.
		aspiration = { id = 9118840222, volume = 0.9 },
		-- L'ambiance : le vent dehors, un coeur lent dans le Ventre.
		vent = { id = 9114625552, volume = 0.25, looped = true },
		coeur = { id = 9043365842, volume = 0.5, looped = true },
		-- Il te voit : un murmure.
		murmure = { id = 9114228525, volume = 0.6 },
		-- Une chute lourde (comete, Repris qui tombe).
		chute = { id = 9125484700, volume = 0.6 },
		-- Les Repris : un grognement (Errant, Coureur), le cri du Hurleur,
		-- leurs pas.
		grognement = { id = 9125475729, volume = 0.7 },
		hurlement = { id = 9113985445, volume = 1 },
		pas = { id = 9114166413, volume = 0.45, looped = true },
		-- Un coup qui porte.
		coup = { id = 9119330371, volume = 0.7 },
		-- Fouiller : une boite d'objets qu'on remue.
		fouille = { id = 9114895552, volume = 0.5 },
		-- Le fumigene qui eclate.
		fumee = { id = 9120591722, volume = 0.7 },
	},
	-- Au-dela de cette distance d'un faisceau, on n'entend plus son regard ;
	-- dessous, il enfle jusqu'au volume plein.
	gazeHeardStuds = 300,
	-- Les sons poses dans le monde : pleins a 25 studs, eteints a 500.
	rollOffMin = 25,
	rollOffMax = 500,
	-- Les pas des Repris s'entendent de moins loin.
	stepsMin = 10,
	stepsMax = 90,
	-- Le temps de passer d'une ambiance a l'autre.
	fadeSeconds = 2,
	-- Les paupieres se referment au ralenti.
	closingSpeed = 0.7,
	-- Le murmure : des qu'il te voit un peu.
	murmurAbove = 0.02,
}

--------------------------------------------------------------------------------
-- LE SALON — on attend, on forme son groupe, on lance (DECISIONS.md)
--------------------------------------------------------------------------------

-- Choisi avec Josh (12 novembre 2026, nuit) : les deux. Dans le jeu publie,
-- le salon envoie les joueurs prets sur un serveur de partie reserve, puis
-- les recupere a la fin ; dans Studio (ou la teleportation ne marche pas),
-- la partie se joue sur place.
Config.lobby = {
	-- Le salon, loin de la carte (a l'oppose du Ventre) : une place en ruine.
	origin = { -3200, 300, 0 },
	radius = 70,
	-- Les colonnes brisees qui font la ruine.
	columns = 10,
	-- Un groupe : 4 au plus (l'escouade), invite en maintenant X sur
	-- quelqu'un ; l'invitation attend une reponse ce temps.
	maxGroup = 4,
	inviteSeconds = 15,
	inviteHoldSeconds = 0.6,
	inviteDistance = 10,
	-- Quand un groupe se dit pret, un compte a rebours part pour son mode :
	-- les autres groupes prets du meme mode partent avec lui.
	countdownSeconds = 15,
	-- Le serveur de partie attend les arrivants au plus ce temps, puis joue
	-- avec ceux qui sont la (les bots completent).
	arrivalSeconds = 25,
	-- Les modes, dans l'ordre ou Y les fait defiler.
	modes = { "solo", "duo", "squad" },
	modeNames = { solo = "Solo", duo = "Duo", squad = "Escouade" },
	-- Attributs : sur le joueur, son groupe (le nom du chef), son mode, s'il
	-- est pret, l'invitation recue (« nom|heure ») ; sur Workspace, le
	-- compte a rebours (« mode|heure de depart »).
	groupAttribute = "Groupe",
	modeAttribute = "Mode",
	readyAttribute = "Pret",
	inviteAttribute = "Invitation",
	countdownAttribute = "Depart",
	folder = "Salon",
	colors = {
		stone = { 92, 86, 82 },
		dark = { 52, 48, 46 },
		lantern = { 255, 170, 90 },
		banner = { 140, 30, 24 },
	},
}

--------------------------------------------------------------------------------
-- LA PROGRESSION — XP, niveaux, credits, fragments (CONCEPT.md)
--------------------------------------------------------------------------------

-- Valide : aucun achat ne donne de puissance ; on gagne en jouant. Les
-- chiffres sont des valeurs de depart (A REGLER, prix et recompenses a voir
-- avec Josh).
Config.progression = {
	-- Le DataStore des profils, et la version du format.
	store = "RoyaleProfils1",
	version = 1,
	-- Lire : quelques essais espaces, puis on abandonne SANS jamais ecrire.
	readAttempts = 3,
	retrySeconds = 2,
	-- Un profil tenu par un autre serveur (teleportation en cours) : on
	-- attend qu'il le lache, au plus ce temps, puis on le prend.
	sessionWaitSeconds = 12,
	sessionStaleSeconds = 60,
	-- On sauvegarde aussi regulierement (s), au cas ou le serveur tombe.
	autosaveSeconds = 120,
	-- L'XP d'une partie : de quoi jouer, plus pour chaque Regard atteint,
	-- beaucoup pour la victoire.
	xp = { played = 50, perRegard = 15, win = 150 },
	-- Les niveaux : le premier coute 200 XP, chaque suivant 50 de plus.
	levelBase = 200,
	levelStep = 50,
	-- Les credits d'une partie (CONCEPT.md : une seule monnaie).
	credits = { played = 10, perRegard = 5, win = 40 },
	-- Les fragments (CONCEPT.md) : top 1 = 2, top 2 a 5 = 1 ; 20 font un
	-- tirage gratuit. En equipe, chaque membre recoit sa part.
	fragments = { first = 2, top = 1, topUntil = 5, perDraw = 20 },
	-- Attributs publies sur le joueur, pour l'ecran.
	attributes = {
		level = "Niveau",
		xp = "XP",
		xpNeeded = "XPNiveau",
		credits = "Credits",
		fragments = "Fragments",
		-- Le resume de la derniere partie (« texte|heure »).
		lastReward = "Recompense",
		-- Vrai si le profil n'a pas pu etre lu (rien ne sera sauvegarde).
		unreadable = "ProfilIllisible",
	},
	rewardSeconds = 10,
}

--------------------------------------------------------------------------------
-- LA BOUTIQUE, LES TIRAGES, LE PASSE — cosmetiques seulement (CONCEPT.md)
--------------------------------------------------------------------------------

-- PRIX PROVISOIRES (Josh decidera) : tout est a regler. Aucun achat ne donne
-- de puissance : ce ne sont que des apparences.
--
-- Les emplacements : la comete du depart (ses couleurs de feu), une trainee
-- derriere soi, la couleur de son cocon, l'emote de la croix droite, un
-- titre (dans la liste des joueurs).
Config.cosmetics = {
	slots = { "comet", "trail", "cocoon", "emote", "title" },
	slotNames = {
		comet = "Comète",
		trail = "Traînée",
		cocoon = "Cocon",
		emote = "Émote",
		title = "Titre",
	},
	-- Prix en credits, par rarete (PROVISOIRE).
	prices = { common = 150, rare = 400, epic = 900, legendary = 1800 },
	items = {
		cometEmber = {
			name = "Braise",
			slot = "comet",
			rarity = "common",
			color = { 255, 120, 40 },
			color2 = { 120, 20, 10 },
		},
		cometFrost = {
			name = "Givre",
			slot = "comet",
			rarity = "rare",
			color = { 140, 220, 255 },
			color2 = { 30, 60, 140 },
		},
		cometVoid = {
			name = "Néant",
			slot = "comet",
			rarity = "epic",
			color = { 170, 60, 255 },
			color2 = { 20, 0, 40 },
		},
		cometGold = {
			name = "Or de l'Œil",
			slot = "comet",
			rarity = "legendary",
			color = { 255, 210, 80 },
			color2 = { 160, 60, 0 },
		},
		trailAsh = { name = "Cendre", slot = "trail", rarity = "common", color = { 120, 115, 110 } },
		trailBlood = { name = "Sang", slot = "trail", rarity = "rare", color = { 180, 20, 20 } },
		trailSpirit = {
			name = "Esprit",
			slot = "trail",
			rarity = "epic",
			color = { 120, 255, 200 },
		},
		trailRift = {
			name = "Fissure",
			slot = "trail",
			rarity = "legendary",
			color = { 255, 60, 30 },
		},
		cocoonMoss = {
			name = "Mousse",
			slot = "cocoon",
			rarity = "common",
			color = { 70, 110, 50 },
		},
		cocoonBone = { name = "Os", slot = "cocoon", rarity = "rare", color = { 220, 210, 190 } },
		cocoonGlass = {
			name = "Verre noir",
			slot = "cocoon",
			rarity = "epic",
			color = { 30, 30, 40 },
		},
		emoteCheer = { name = "Victoire", slot = "emote", rarity = "common", emote = "cheer" },
		emoteLaugh = { name = "Rire", slot = "emote", rarity = "common", emote = "laugh" },
		emotePoint = { name = "Pointer", slot = "emote", rarity = "rare", emote = "point" },
		emoteDance = { name = "Danse", slot = "emote", rarity = "epic", emote = "dance" },
		emoteDance2 = {
			name = "Danse folle",
			slot = "emote",
			rarity = "legendary",
			emote = "dance2",
		},
		titleSurvivor = {
			name = "Survivant",
			slot = "title",
			rarity = "common",
			title = "Survivant",
		},
		titleShadow = { name = "Ombre", slot = "title", rarity = "rare", title = "Ombre" },
		titleUnseen = { name = "Invisible", slot = "title", rarity = "epic", title = "L'Invisible" },
		titleEyeless = {
			name = "Sans regard",
			slot = "title",
			rarity = "legendary",
			title = "Celui qu'il ne voit pas",
		},
	},
	-- L'attribut d'un joueur par emplacement equipe : « Cosmetique_comet »...
	attributePrefix = "Cosmetique_",
	-- La trainee : sa hauteur (studs), le temps qu'elle reste, sa lueur.
	trail = { height = 2, lifetime = 0.6, lightEmission = 0.6, transparency = 0.3 },
}

-- Les defis (CONCEPT.md : quotidiens et hebdomadaires, ils font avancer le
-- passe). Les hebdomadaires sont les memes defis, en plus long et mieux
-- payes. Choix de l'assistant, a regler.
Config.challenges = {
	daily = 3,
	weekly = 3,
	-- Les hebdomadaires demandent `weeklyFactor` fois plus, et rapportent
	-- `weeklyRewardFactor` fois plus.
	weeklyFactor = 5,
	weeklyRewardFactor = 3,
	-- Recompense d'un defi quotidien : de l'XP de passe et des credits.
	passXp = 150,
	credits = 15,
	list = {
		play = { text = "Jouer %d partie(s)", stat = "match", goal = 2 },
		regard3 = { text = "Atteindre le Regard 3 (%d fois)", stat = "regard3", goal = 1 },
		win = { text = "Gagner %d partie(s)", stat = "win", goal = 1 },
		search = { text = "Fouiller %d meubles", stat = "search", goal = 8 },
		knockout = { text = "Mettre %d joueurs K.O.", stat = "knockout", goal = 3 },
		repris = { text = "Détruire %d Repris", stat = "repris", goal = 3 },
		belly = { text = "Revenir du Ventre (%d fois)", stat = "belly", goal = 1 },
		cocoon = { text = "Ouvrir le cocon d'un coéquipier (%d fois)", stat = "cocoon", goal = 1 },
	},
	-- Attribut du joueur : ses defis et leur avancement (JSON, pour l'ecran).
	attribute = "Defis",
}

Config.shop = {
	-- La boutique tournante : ce nombre d'objets, changes chaque jour (UTC) ;
	-- le coin permanent garde les classiques.
	daily = 4,
	permanent = { "cometEmber", "trailAsh", "emoteCheer", "titleSurvivor" },
	-- Les tirages : une selection a part (CONCEPT.md), toutes les chances
	-- egales. En credits, le prix est la valeur moyenne de la selection
	-- (calcule, jamais recopie) ; en fragments, 20 (Config.progression).
	drawPool = {
		"cometFrost",
		"cometVoid",
		"trailBlood",
		"trailSpirit",
		"cocoonBone",
		"cocoonGlass",
		"emotePoint",
		"emoteDance",
		"titleShadow",
		"titleUnseen",
	},
	-- Un doublon rend cette part de son prix en credits.
	duplicateRefund = 0.5,
	-- Les paquets de credits en Robux (produits de developpeur). Un id a 0 :
	-- pas encore cree par Josh sur Roblox, le paquet ne s'affiche pas.
	creditPacks = {
		{ credits = 500, productId = 0, robux = 49 },
		{ credits = 1200, productId = 0, robux = 99 },
		{ credits = 3000, productId = 0, robux = 199 },
	},
	-- Attributs : sur Workspace, la boutique du jour (JSON) ; sur le joueur,
	-- ce qu'il a et porte, et son passe (JSON).
	worldAttribute = "BoutiqueJour",
	playerAttribute = "BoutiqueEtat",
	-- La boutique change a minuit (UTC) : on la republie a ce rythme (s).
	refreshSeconds = 60,
	-- L'ecran (pixels) et ses couleurs ; par-dessus tout ; les recompenses
	-- du passe montrees d'avance.
	displayOrder = 6,
	passPreview = 6,
	panelWidth = 560,
	rowHeight = 30,
	textSize = 20,
	background = { 20, 16, 16 },
	selected = { 255, 170, 90 },
}

Config.pass = {
	-- Une saison d'environ 8 semaines (CONCEPT.md). Le passe premium se
	-- rachete chaque saison : un produit de developpeur par saison (id a 0 :
	-- pas encore cree, PROVISOIRE).
	season = 1,
	tiers = 30,
	-- L'XP de passe par palier (l'XP d'une partie compte aussi pour le passe).
	tierXp = 300,
	premiumProductId = 0,
	premiumRobux = 499,
	-- Le premium donne un peu plus d'XP de compte (CONCEPT.md), jamais de
	-- puissance.
	premiumXpBonus = 0.2,
	-- Les recompenses : par palier, gratuites ou premium. Un objet du
	-- catalogue, ou des credits.
	free = {
		[2] = { credits = 50 },
		[5] = { item = "cocoonMoss" },
		[8] = { credits = 100 },
		[12] = { item = "emoteLaugh" },
		[16] = { credits = 150 },
		[20] = { item = "titleShadow" },
		[25] = { credits = 200 },
		[30] = { item = "trailBlood" },
	},
	premium = {
		[1] = { item = "cometFrost" },
		[3] = { credits = 100 },
		[6] = { item = "trailSpirit" },
		[10] = { item = "emoteDance" },
		[14] = { credits = 250 },
		[18] = { item = "cocoonGlass" },
		[22] = { item = "titleUnseen" },
		[26] = { credits = 400 },
		[30] = { item = "cometGold" },
	},
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
	-- L'Oeil ferme, il fouille les meubles a moins de ce rayon (studs) tant
	-- que son sac a de la place, et court a une relique a moins de
	-- `relicRadius`.
	searchRadius = 120,
	relicRadius = 300,
	-- Frappe, il rend les coups pendant ce temps (s).
	grudgeSeconds = 4,
	-- L'Oeil ferme, a chaque reflexion, la chance de frapper qui passe a
	-- portee (A REGLER : assez pour que la rue soit vivante, pas assez pour
	-- que chaque croisement soit une bagarre).
	brawlChance = 0.15,
	-- Le cocon d'un coequipier a moins de cette distance : il va l'ouvrir.
	-- Le cocon apparait a 6 studs de lui : large, pour aller au secours.
	cocoonRange = 120,
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
	-- Un chemin se calcule par etapes de cette longueur (studs) : plus loin,
	-- le service de chemins refuse (« path request is too long », vu en jeu).
	pathMaxDistance = 400,
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
	-- Contre un mur, la camera se tient a cette distance devant (studs).
	spectateWallGap = 1,
	-- La ligne du spectateur, en bas de l'ecran (pixels).
	spectateInfoBottom = 40,
	spectateInfoHeight = 30,
	spectateInfoTextSize = 22,
	-- La police des textes de l'Oeil (Survivor : la machine a ecrire).
	font = "SpecialElite",
	-- Le sac en bas de l'ecran : 4 places de cette taille (pixels), un ecart,
	-- a cette distance du bas ; la place choisie a un cadre plus epais.
	slotWidth = 120,
	slotHeight = 44,
	slotGap = 8,
	slotBottom = 20,
	slotSelectedStroke = 3,
	-- La barre ne prend jamais plus que cette part de la largeur de l'ecran.
	slotFitFraction = 0.95,
	-- Le trait de visee d'un lancer : des points (studs), un peu transparents.
	aimDotSize = 0.4,
	aimDotTransparency = 0.3,
	-- L'objet lance, vu en vol.
	projectileSize = 0.8,
	-- Un message reste ce temps (s), une annonce pour tous un peu plus.
	messageSeconds = 3,
	announceSeconds = 5,
	-- Ebloui : l'ecran devient blanc a ce point au debut (1 = tout blanc).
	dazzleOpacity = 1,
	-- Le Regard vole : on envoie le point vise a ce rythme (le garde-fou du
	-- remote en laisse passer 4 par seconde), jusqu'a cette distance.
	steerSendSeconds = 0.3,
	steerRange = 600,
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
	-- Un geste : (nom) parmi frapper, pousser, porter, jeter, poser, glisser,
	-- sortir en force. Le serveur choisit la cible et verifie tout.
	gesture = "Geste",
	-- Le sac : (action, argument) — choisir une place, utiliser l'objet choisi
	-- (avec la direction visee pour un lancer).
	item = "Objet",
	-- Le serveur montre un lancer a tous (depart, vitesse, objet).
	projectile = "Projectile",
	-- Le Regard vole : le point vise (x, z).
	steer = "Pilote",
	-- Un signal a ses coequipiers : (sorte, position). Le serveur le renvoie
	-- a l'equipe : (sorte, position, nom).
	signal = "Signal",
	-- Le salon : (action, argument) — inviter (joueur), accepter (chef),
	-- quitter son groupe, changer de mode, se dire pret.
	lobby = "Salon",
	-- La boutique : (action, argument) — acheter, equiper, tirer (fragments
	-- ou credits), acheter des credits ou le passe (Robux).
	shop = "Boutique",
	-- Un elimine parie : (celui qu'il regarde, Player ou Model). Ou quitte :
	-- (rien) avec le remote `quit`.
	bet = "Pari",
	quit = "Quitter",
}

--------------------------------------------------------------------------------
-- LES SIGNAUX, LA CARTE, L'EMOTE (CONCEPT.md, Les boutons de la manette)
--------------------------------------------------------------------------------

Config.signals = {
	-- Croix haut et bas : « Danger ! » et « Ici ! », la ou l'on regarde,
	-- vus par ses coequipiers a travers les murs.
	seconds = 6,
	-- Au plus loin (studs) : au-dela, le regard ne touche rien de precis.
	range = 400,
	-- Un signal par personne et par seconde au plus.
	cooldown = 1,
	kinds = {
		danger = { text = "⚠ DANGER", color = { 255, 80, 60 } },
		here = { text = "▼ ICI", color = { 90, 200, 255 } },
	},
	-- L'etiquette a l'ecran (pixels).
	tagWidth = 160,
	tagHeight = 44,
}

Config.map = {
	-- Croix gauche : la carte, le cercle actuel, le prochain, soi et ses
	-- coequipiers. Sa taille a l'ecran, en part de la plus petite dimension.
	screenFraction = 0.7,
	dotSize = 12,
	refreshSeconds = 0.1,
	-- Au-dessus des autres ecrans (qui sont a 0).
	displayOrder = 5,
	-- Les zones dessinees (dossiers de Carte.Zones) et leur nom a l'ecran.
	-- Les liaisons, la campagne et la vegetation n'en sont pas.
	zoneNames = {
		Cratere = "Cratère",
		Banlieue = "Banlieue",
		FeteForaine = "Fête foraine",
		Lycee = "Lycée",
		PortEchoue = "Port échoué",
		Marais = "Marais",
		GareDeTriage = "Gare de triage",
		Hypermarche = "Hypermarché",
		QuartierSuspendu = "Quartier suspendu",
	},
	zoneColor = { 120, 110, 100 },
	zoneTransparency = 0.8,
	zoneText = { 220, 210, 200 },
	zoneTextSize = 16,
	-- Le fond sombre, le cercle actuel en blanc casse, le prochain en rouge
	-- (comme l'Oeil), soi en jaune ; les coequipiers ont leur bleu.
	background = { 20, 16, 16 },
	current = { 240, 232, 220 },
	upcoming = { 255, 90, 70 },
	me = { 255, 220, 90 },
}

Config.playerList = {
	-- Les joueurs du jeu, a droite, sous le haut de l'ecran (le Regard) et
	-- par-dessus les autres ecrans. Les aspires en gris, son equipe en bleu.
	top = 150,
	width = 300,
	rowHeight = 22,
	textSize = 18,
	displayOrder = 4,
	background = { 20, 16, 16 },
	text = { 240, 232, 220 },
	out = { 120, 112, 108 },
}

Config.emote = {
	-- Croix droite : une emote de Roblox (le script d'animation du joueur
	-- la joue).
	name = "wave",
}

return Config
