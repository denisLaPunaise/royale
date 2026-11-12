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

return Config
