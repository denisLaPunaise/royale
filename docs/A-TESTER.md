# À tester en jouant

Ce qu'un test en solo ne peut pas dire : si c'est amusant, lisible, juste.
Chaque point dit quoi regarder, dans quel ordre, et ce qui a été vérifié avant.

## Montage du projet (12 novembre 2026)

1. Ouvrir la place **Royale**, lancer `rojo serve` **depuis le dossier
   Royale**, connecter le plugin Rojo (le message doit dire « Royale »), puis
   **Play**. La console doit afficher `[Royale] Serveur démarré` puis
   `[Royale] Client démarré`.

## La carte complète (12 novembre 2026)

*Vérifié seul dans Studio* : la recette construit le sol et les 9 zones sans
erreur, et sa mesure dit 0 problème (mer, rivière, Cratère creux, sols plats,
horizon fermé, 3 ponts, 53 maisons, 5 îlots, grande roue assez haute, quai,
roseaux au bord de l'eau, wagons-cachettes). Environ 256 emplacements de
cachettes, 215 contenants à fouiller, 24 cachettes solides et plus, 690
arbres. *Vu en image par l'assistant* : chaque zone de haut. *Jamais vu* :
la carte en marchant dedans à la première personne, et la lumière Future.

1. **Lumière** : passer `Lighting.Technology` sur **Future**, puis regarder.
2. **Se promener** de zone en zone à pied : est-ce qu'on se repère (grande
   roue, phare, cargo, Lycée, Cratère) ? Est-ce que les routes de campagne
   mènent bien quelque part ?
3. **Chaque zone** : laquelle donne envie d'y tomber au départ ? Laquelle
   paraît vide ou pas finie ?
4. **Le Quartier suspendu** : monter par la dalle retombée, passer d'îlot en
   îlot sur les passerelles. Trop facile, trop dur ?
5. **Le Marais** : trop d'eau, pas assez ? Les pontons se suivent-ils ?
6. **La taille** : 1600 × 1600, trop grand, trop petit pour une vingtaine ?

## Le cœur du jeu et les bots (12 novembre 2026)

*Vérifié seul dans Studio* : une partie s'enchaîne d'elle-même (attente 30 s,
visée depuis la pupille, chute, Regards, fin, nouvelle partie) ; des bots
complètent jusqu'à 17 à 24 ; ils se cachent quand l'Œil s'ouvre ; l'Œil ouvre
et ferme, ses faisceaux chassent, il arrache les cachettes marquées et aspire
ceux qu'il voit ; un joueur immobile à découvert est aspiré ; caché, la
jauge ne monte pas ; éjecté d'une cachette, on a 2 s de répit.
*Vu en image* : l'écran (Regard, Œil, restants, attente), la carte vue de la
pupille pendant la visée, les paupières fermées. *Jamais vu à l'écran* :
les faisceaux de lumière, le mur rouge du cercle, l'Œil qui tourne, la
comète, l'arrachage en vol, le mode spectateur (le pont ne peut pas déplacer
la caméra en jeu). *Jamais testé* : la manette (L3, B, X, L1/R1).

Dans cet ordre :

1. **La visée** : au stick gauche, le réticule rouge se déplace-t-il bien ?
   Trop lent, trop rapide ? On tombe bien là où on visait ?
2. **La chute** : est-ce beau ? Assez « attaque » ? (feu, ligne droite,
   impact)
3. **Les 20 premières secondes** puis la première ouverture : le ciel rougit
   un peu avant, l'Œil s'ouvre ; voit-on venir les faisceaux ? Est-ce qu'on
   comprend qu'il faut se cacher ?
4. **Se cacher** : maintenir X devant une cachette, puis X pour sortir. Vue
   de l'intérieur ? L'Œil revient-il bien l'arracher à l'ouverture suivante,
   avec le tremblement qui prévient ?
5. **S'accroupir derrière un muret** (B) pendant qu'un faisceau passe : la
   jauge reste-t-elle à zéro ? C'est ce qui rend les recoins utiles.
6. **La méfiance** : rester longtemps au même endroit ; « Il te sent… »
   arrive-t-il assez tôt pour réagir ?
7. **Le cercle** : le mur rouge et le trait blanc du prochain se voient-ils
   de loin ? Hors du cercle, le message dit-il clairement où aller ?
8. **Les bots** : ont-ils l'air de vrais joueurs ? Trop forts, trop bêtes ?
   (Ils ne se battent pas encore et ne fouillent rien : les coups et les
   objets ne sont pas faits.)
9. **Une fois aspiré** : regarder les autres avec L1 / R1.
10. **La durée** : combien dure une partie ? Le Regard 5 traîne-t-il ?

**Partie de mesure, 22 participants dont 21 bots** (vérifié seul, 12 novembre
2026) : environ 15 minutes ; en vie au début de chaque Regard 22 → 19 → 13
→ 5, la fiche en estimait 20 → 14 → 10 → 6 ; gagnée par un bot à la fin du
Regard 4 ; aucune erreur. À 24 participants, le serveur tient 53 images par
seconde (client et serveur dans le même Studio). À juger en jouant : une
partie de 15 minutes, c'est bien ?

## Le corps à corps (12 novembre 2026)

**Vérifié seul dans Studio** (sondes sur des bots, trois essais chacun) :
trois coups mettent K.O. (pas deux), le K.O. couche le corps et se relève
après 2,5 s ; porter tient le K.O. 3,5 studs au-dessus du porteur ; jeter
l'envoie à 11–20 studs et il reste au sol 1,5 s ; pousser déplace de
18–23 studs (le bot finissait peut-être sa marche) ; pousser sur une
cachette occupée en fait sortir l'occupant ; R2 caché fait sortir et
renverse celui qui se tient devant. Partie de 5 minutes ensuite : aucun bot
mort par la physique, plus de message « path request is too long ».

**Vu une fois, pas reproduit** : au tout premier essai de « porter », les
deux bots sont morts (corps tombés hors de la carte). Quatre essais suivants
sans souci. À surveiller en jouant : si quelqu'un disparaît en étant porté,
le dire.

**Jamais vu à l'écran ni à la manette** : la glissade, le tacle glissé, le
plaquage (il faut courir vraiment, le pont ne fait pas courir), s'agripper
aux rebords, l'écran « K.O. » et « Tu portes … ».

**À regarder en jouant, dans l'ordre :**

1. R2 sur un ami trois fois : il tombe K.O. ? Le temps entre deux coups
   (0,6 s) laisse-t-il fuir ?
2. Y maintenu sur lui : tu le soulèves ? Tu marches lentement ; Y le jette,
   B le pose. Jeter quelqu'un dans un faisceau, c'est drôle ou injuste ?
3. Y à l'arrêt sur quelqu'un : la poussée, trop forte ou trop faible ?
4. En courant (L3), Y : le plaquage, vous tombez tous les deux.
5. En courant, B : la glissade, et si quelqu'un est devant, il tombe.
6. Cache-toi, un ami appuie sur Y devant ta cachette : tu sors.
7. Caché, R2 quand un ami est juste devant : il tombe et tu files.
8. R2 sur une cachette vide : au Regard 1, le faisceau vient-il voir ?
9. Saute contre un muret, un conteneur, un toit de garage et appuie encore
   sur A en l'air : tu te hisses ?
10. Avec des bots : ils rendent les coups ? Se battent-ils assez souvent
    (presque jamais seuls, ils se croisent peu) ?
11. Accroupi et glissade : les jambes s'enfoncent dans le sol (pas encore
    d'animation). Gênant ?

## Les objets (12 novembre 2026)

**Vérifié seul dans Studio** (sondes sur des bots) :
- 30 meubles fouillés : 12 objets, 18 vides (commun 6, peu commun 4,
  épique 2), aucun meuble fouillé deux fois.
- Les 28 objets donnés puis utilisés un par un : chacun agit ou refuse avec
  un message clair (« Il faut être caché dedans », « Aucun faisceau ne te
  suit », « Rien où s'accrocher »…).
- Le fumigène coupe vraiment la vue de l'Œil : un bot à découvert vu à
  1,00, dans la fumée à 0,00.
- La batte met K.O. en 2 coups et décompte ses coups ; la lampe éblouit.
- Clochette (elle sonne quand quelqu'un entre), planches (la poussée ne
  déloge plus), piège (on tombe en sortant), carton piégé (on en est
  éjecté), Cocon de secours (aspiré, on reste en vie, une fois), Relique
  (posée, prise, annoncée), aspiré = son sac tombe par terre.
- Le filet lancé à ses pieds ne renverse plus son lanceur (corrigé).
- Une partie de 4 minutes avec les bots : ils ont fouillé 31 meubles, aucune
  erreur, ni serveur ni joueur.
- **Vérifié par le calcul** (test) : un lancer droit devant tombe à 43 studs ;
  le meilleur sac de 4 protège 45 s, moins d'un quart du plus court Regard ;
  aucun objet ne couvre toute une ouverture de l'Œil.

**Vu à l'écran** : le sac en bas (couleur de rareté, place choisie en
vert, effet en cours au-dessus). Corrigé ensuite pour les petites fenêtres
(la barre débordait) ; ce dernier réglage n'a pas été revu à l'écran.

**Jamais vu à l'écran ni à la manette** : le trait de visée et le vol des
objets, la fumée, les fusées, la flaque, le grappin, le Regard volé, les
joueurs révélés par les jumelles, l'écran blanc de la lampe, la Relique qui
brille. Le vol d'un K.O. (l'invite ne se déclenche pas depuis le pont).

**À regarder en jouant, dans l'ordre :**

1. Maintiens X sur un meuble (cuisine, armoire, caisse) : 1,5 s, c'est
   trop long quand l'Œil va s'ouvrir ? Trouve-t-on assez souvent quelque
   chose (environ un meuble sur deux) ?
2. L1 / R1 pour choisir, L2 pour utiliser. Le nom et l'aide au-dessus du
   sac se lisent bien ?
3. Fumigène : L2 maintenu, le trait de l'arc se voit ? Lâche : il tombe où
   tu visais ? Cache-toi dans la fumée pendant qu'un faisceau passe.
4. Pétard et fusée éclairante loin de toi : le faisceau y va ?
5. Sac plein, ramasse un objet : celui que tu tenais tombe par terre et se
   ramasse (X).
6. Mets un ami K.O. (3 coups), maintiens X sur lui : tu lui voles un objet.
7. Craie sur la cachette d'un ami, puis attends l'ouverture suivante.
8. Une Relique tombe au Regard 3 : l'annonce se voit ? On y court tous ?
9. Les objets trop forts, trop faibles, inutiles ? (Josh : rien ne doit
   être trop fort.)

## Les pouvoirs de l'Œil (12 novembre 2026)

**Vérifié par le calcul** (`tests/specs/eyepowers.luau`) : sur 200 parties
tirées, jamais deux fois le même pouvoir et toujours un pouvoir utile ;
chacun des 14 change vraiment le Regard où il tombe ; la plus courte pause
possible laisse le temps d'une fouille ; même avec les cinq pires pouvoirs,
un Regard 4 garde des pauses.

**Vérifié seul dans Studio** (19 bots, les 14 pouvoirs forcés d'un coup) :
- le tirage et l'annonce au Regard 1, aucune erreur en 90 s ;
- la rage : 4 faisceaux au lieu de 3 aux rafales paires ;
- les empreintes : jusqu'à 79 traces au sol en même temps ;
- l'éclair : les bots à découvert brillent à chaque ouverture ;
- le souffle : 5 à 6 studs de poussée, personne ne tombe ;
- le regard rasant : il voit 3 bots sur 19 que le regard d'en haut ne voyait
  pas, et ne voit jamais moins.

**Vu à l'écran** : l'annonce « L'ŒIL GAGNE UN POUVOIR » et la liste (elle
débordait, corrigée et revue).

**Jamais vu en jeu** : le retour, le flair, la rancune, le faux départ et le
regard long (seulement vérifiés par le calcul), l'éclair et les empreintes
vus de près, le souffle sur un vrai joueur.

**À regarder en jouant, dans l'ordre :**

1. Au début de chaque Regard : l'annonce se lit en entier avant de
   disparaître (7 s) ?
2. L'éclair : à l'ouverture, les amis à découvert brillent en rouge. Ça se
   voit, c'est utile ou c'est trop ?
3. Le souffle : en pleine rue à l'ouverture, tu es poussé. Gênant, drôle,
   trop faible ?
4. Les empreintes : cours, retourne-toi : les traces rouges se voient ? Un
   faisceau te suit à la trace ?
5. Le faux départ : la pause de 2 s surprend, ou on ne la remarque pas ?
6. Le retour : cache-toi d'un faisceau qui te poursuit, attends 5 s : il
   revient voir ?
7. Le regard rasant : sous un auvent ou un abri de bus, on est vu ?
8. Au Regard 5, avec cinq pouvoirs : l'Œil est assez fort ? trop ? Un
   pouvoir paraît inutile ? (Josh : aucun trop faible, aucun trop fort.)

## Les Repris (nuit du 12 novembre 2026)

**Vérifié par le calcul** (`tests/specs/repris.luau`) : combien l'Œil en
recrache à chaque Regard ; une chute ne dépasse jamais 1 Repris pour 2
joueurs ; jamais plus de 2 Repris sur le même joueur ; les garde-fous
(lents, fragiles, ils grognent avant de plaquer).

**Vérifié seul dans Studio** (bots) :
- l'Œil en recrache à la fermeture, avec le crâne ; ils marchent, et la
  moitié remonte au Regard suivant ;
- le Coureur a plaqué un bot (au sol 6 s après sa chute) ;
- l'Errant a crié en voyant un bot ;
- le Rampant a délogé 2 bots cachés sur 3 (une voiture, une crypte). Il
  n'a pas atteint celui qui était sous les gradins ;
- les bots frappent et détruisent les Repris.

**Jamais vu à l'écran** : le corps des Repris dans cette carte, leur chute
et sa traînée, les animations. Le hurlement du Hurleur n'a pas été
déclenché en sonde.

**À regarder en jouant, dans l'ordre :**

1. À la fermeture de l'Œil : tu vois les Repris tomber, avec la traînée ?
   Ils font peur, ou ils font rire ?
2. Un Errant te voit : il crie et un faisceau arrive. Tu comprends que
   c'est lui ?
3. Cache-toi longtemps dans une voiture : un Rampant vient t'en sortir ?
4. Un Coureur grogne avant de plaquer : tu as le temps de glisser (B en
   courant) pour l'esquiver ?
5. Frappe un Repris (R2) : 3 coups, 2 pour le Coureur. Il lâche un objet ?
6. Est-ce que ça reste jouable ? Trop de Repris, ou pas assez ? (Josh : pas
   trop forts et trop nombreux à la fois.)

## Le goulag (nuit du 12 novembre 2026)

**Vérifié par le calcul** (`tests/specs/goulag.luau`) : les paires (jamais
deux coéquipiers, le nombre impair contre le bot), la plateforme qui finit
toujours par disparaître, qui est sauvé, la fermeture aux deux derniers
cercles, une seule fois par partie.

**Vérifié seul dans Studio** : trois bots aspirés au Regard 1 arrivent en
cage. Une manche se lance au bout de 12 s, avec un duel entre deux bots et
un duel contre le Repris du Ventre. Un bot a jeté l'autre dans le vide et
il est revenu dans la partie ; le perdant est éliminé. Le bot seul a battu
le Repris du Ventre et il est revenu lui aussi.

**Vu à l'écran** (en mode édition) : la salle, les plateformes, les cages.

**Jamais vu en jeu** : un vrai joueur au Ventre (le décompte, la caméra,
les textes à l'écran), la mort subite, la dernière manche à la fermeture.

**À regarder en jouant, dans l'ordre :**

1. Fais-toi aspirer au Regard 1 ou 2 : tu arrives dans une cage. Tu
   comprends où tu es et ce qu'il faut faire ?
2. Le duel : 3 coups (R2) le mettent K.O., le coup suivant l'envoie voler.
   C'est lisible ? Trop rapide ?
3. Attends sans frapper : la plateforme rétrécit, puis la mort subite fait
   tout tomber.
4. Revenu dans la partie : tu retombes dans le cercle, sac vide.
5. Fais-toi aspirer une deuxième fois : c'est fini pour de bon.
6. Au Regard 4, être aspiré est définitif.
7. Le Ventre fait-il assez peur ? Est-il trop sombre ?

## Les escouades (nuit du 12 novembre 2026)

**Vérifié par le calcul** (`tests/specs/squads.luau`) : les équipes (les amis
ensemble, les bots complètent), la fin de partie par équipe, des équipes
pleines, 3 coups pour ouvrir un cocon bien avant que l'Œil arrive.

**Vérifié seul dans Studio** :
- 20 participants, 5 équipes de 4 ;
- des coups entre coéquipiers mettent K.O., et « relever » remet debout ;
- un cocon apparaît près d'un coéquipier, qui l'ouvre en 3 coups ;
- un cocon laissé seul est pris par le faisceau (au bout de 65 s, à
  l'ouverture de l'Œil).

**Vu à l'écran** : la liste « TON ÉQUIPE » en bas à gauche, et le texte du
haut qui tient maintenant en entier.

**Jamais vu** : les repères bleus à travers les murs (le pont ne montre
pas les étiquettes au-dessus des têtes), « Relever » et « Donner » à
l'écran, le cocon vu de près, l'écran de victoire d'équipe.

**À regarder en jouant (avec tes amis), dans l'ordre :**

1. Au début : tes amis sont dans ton équipe ? Tu les vois en bleu à
   travers les murs, avec leur nom ?
2. Un ami est K.O. : X maintenu sur lui affiche « Relever » et le remet
   debout.
3. X maintenu sur un ami debout : « Donner » lui passe l'objet que tu
   tiens.
4. Un ami sauvé du Ventre revient dans un cocon près de toi : 3 coups (R2)
   l'ouvrent. Attends trop longtemps : le faisceau vient le prendre.
5. Les objets lancés (bouteille, filet…) ne touchent jamais un ami.
6. La fin : quand il ne reste que ton équipe, vous avez gagné, tous.

## Les gestes (nuit du 12 novembre 2026)

**Vérifié seul dans Studio** :
- un bot allongé fait apparaître l'invite « Tirer » ; un autre bot l'a
  tiré : sorti de 3 studs, au sol, plus allongé ;
- un signal « ICI » envoyé par le joueur s'affiche chez lui ;
- la carte s'ouvre, avec les deux cercles, moi et mes coéquipiers. Le grand
  cercle débordait du cadre et le texte du haut passait dessus : corrigé,
  mais pas revu.

**Jamais essayé à la manette** : B maintenu pour s'allonger, ramper, se
relever ; la croix (signaux, carte, émote) ; « Tirer » sur un ami.

**À regarder en jouant, dans l'ordre :**

1. B maintenu : tu t'allonges ? Tu rampes sous un camion ? (Le corps
   s'enfonce dans le sol en attendant l'animation.)
2. Un ami allongé : X maintenu « Tirer » le sort de son recoin.
3. Croix haut ou bas en regardant un endroit : tes amis voient le signal ?
4. Croix gauche : la carte se lit ? Il manque le dessin des zones ?
5. Croix droite : ton personnage salue.

## Les éliminés (nuit du 12 novembre 2026)

**Vérifié par le calcul** (`tests/specs/bets.luau`) : qui peut parier, jamais
sur un ami Roblox, les paris fermés aux derniers cercles, qui gagne.

**Vérifié seul dans Studio** : mon joueur éliminé pour de bon regarde d'abord
un coéquipier. Le pari est enregistré et affiché (« pari sur
Kiwi_Fantome »). Quitter arrête le spectateur et l'écran le dit.

**Vu à l'écran** : la ligne du spectateur, et le contour bleu d'un
coéquipier à travers un arbre.

**À regarder en jouant :**

1. Éliminé pour de bon : tu regardes d'abord un ami ? L1 / R1 change.
2. X : le pari s'affiche. Sur un ami Roblox, il est refusé avec la raison.
3. Gagne-t-on bien les crédits du pari à la fin (après la progression) ?
4. B : on quitte ; plus tard, retour au salon.

## La liste des joueurs (nuit du 12 novembre 2026)

**Vérifié seul dans Studio et vu à l'écran** : R3 (envoyé comme une touche)
ouvre la liste avec 24 participants ; mon équipe est en tête, en bleu.

**À regarder en jouant** : R3 ouvre et ferme la liste, on ne devine pas qui
est un bot, les aspirés passent en gris.

## Les animations des postures (nuit du 12 novembre 2026)

**Vérifié seul dans Studio** (mesuré sur mon écran, la tête au-dessus du
sol) :
- moi allongé avec C maintenu : animation ramper, tête à 0,9 ;
- un bot allongé : 1,2 ; un bot accroupi : 3,9 (debout, environ 4,5) ;
- un bot K.O. : tête à 0,9 (avant la correction : 1,4 sous le sol).

**Vu à l'écran** : chaque animation sur un mannequin, en mode édition.

**Jamais vu en jeu** : les animations sur un vrai personnage qui bouge,
porté au-dessus d'un porteur, et ce qu'en voient les autres joueurs.

**À regarder en jouant :**

1. Accroupis-toi (B) et marche : tes amis te voient accroupi ?
2. Allonge-toi (B maintenu) et rampe : le corps est couché, pas enfoncé ?
3. Un K.O. est allongé au sol, pas debout ni sous terre ?
4. Porte un K.O. (Y maintenu) : il est couché au-dessus de ta tête, sans la
   traverser ?

## Les sons (nuit du 12 novembre 2026)

**Vérifié seul dans Studio** : les 15 sons se chargent ; le vent joue. En
70 s de partie, le serveur a joué des coups, des fouilles, une aspiration,
des chutes, des grognements et les pas des Repris.

**Jamais écouté** : je ne peux pas entendre. C'est à toi de juger.

**À noter** : depuis que Studio a été rouvert, 16 avertissements « Requester
does not have permission for Asset » apparaissent au démarrage. 16, c'est
le nombre de textures des matières générées de la carte (asphalte, béton,
brique, bois). Regarde si les routes et les murs ont toujours leurs
textures ; sinon, il faut peut-être être connecté au bon compte dans Studio.

**À écouter en jouant :**

1. Le ciel rougit : un grand coup sourd, puis l'Œil s'ouvre (paupières).
2. Un faisceau approche : le bourdonnement enfle-t-il ?
3. Il te voit : le murmure.
4. Les coups, la fouille, un Repris qui grogne avant de plaquer.
5. Au Ventre : le cœur à la place du vent.
6. Un son trop fort, trop faible ou ridicule ? Dis-moi lequel.

## Le salon (nuit du 12 novembre 2026)

**Vérifié par le calcul** (`tests/specs/lobby.luau`, `squads.luau`) : les
groupes (inviter, plein à 4, le chef qui part), le mode qui suit la taille
du groupe, seul le chef se dit prêt, un groupe jamais coupé en équipes.

**Vérifié seul dans Studio** :
- j'arrive au salon ;
- Y change le mode, R2 me dit prêt et lance le compte à rebours ;
- à la fin, la partie part avec moi et 23 bots, mon équipe complétée ;
- mon équipe gagne : 12 s d'écran de fin, puis retour au salon, et le
  monde est vidé (bots, Repris).

**Vu à l'écran** : la place et le panneau du salon.

**Jamais vérifié, impossible dans Studio** : l'envoi vers un serveur de
partie réservé et le retour au salon. Seulement dans le jeu publié. C'est
le premier test à faire après publication, à deux au moins.

**Jamais vérifié** : inviter un autre joueur et accepter (il faut être deux).

**À regarder en jouant, dans l'ordre :**

1. Publie, rejoins avec un ami : vous êtes dans le même salon ?
2. X maintenu sur ton ami : il voit l'invitation et accepte avec X.
3. Y : le mode change ; R2 : prêts, le compte à rebours part.
4. Vous partez ensemble sur un serveur de partie, dans la même équipe.
5. À la fin, retour au salon.
6. Le salon est-il assez beau ? (Première version : à habiller.)

## La progression (nuit du 12 novembre 2026)

**Vérifié par le calcul** (`tests/specs/progression.luau`) : ce qu'une partie
rapporte, les fragments de la fiche (10 victoires pour un tirage), les
niveaux, un ancien profil qui garde tout.

**Vérifié seul dans Studio** :
- une victoire au Regard 1 a rapporté +215 XP (niveau 2), +55 crédits et
  +2 fragments, affichés au salon ;
- Studio refuse les sauvegardes (« API access is not enabled »), donc le
  profil est marqué illisible et rien n'est écrit : la règle d'or marche.

**Jamais vérifié** : une vraie sauvegarde et sa relecture, et le passage
du profil entre le salon et le serveur de partie.

**À faire par toi** (c'est un réglage de sécurité, je n'y touche pas) :
dans Studio, Paramètres du jeu → Sécurité → « Activer l'accès de Studio
aux services d'API ». Ensuite, je pourrai tester la sauvegarde.

**À regarder en jouant :**

1. Après une partie, au salon : « Dernière partie : +… XP · +… crédits ».
2. Quitte et reviens : ton niveau et tes crédits sont restés (jeu publié,
   ou Studio avec l'accès aux API).
3. Les gains te paraissent-ils justes ? Trop lents, trop rapides ?

## La boutique, les tirages, le passe (nuit du 12 novembre 2026)

**Vérifié par le calcul** (`tests/specs/shop.luau`) : la boutique du jour
(la même partout, elle change le lendemain, jamais un permanent), les
règles des tirages (tout affiché, chances égales, total 100 %, chaque
tirage donne quelque chose, prix à la valeur moyenne), le passe (paliers,
récompenses qui existent, fini en une saison).

**Vérifié seul dans Studio** (avec 3000 crédits et 40 fragments donnés par
une sonde) :
- la boutique s'ouvre avec la croix gauche ;
- acheter « Invisible » (900) avec A ;
- un tirage aux fragments a donné la traînée « Esprit » ; un tirage en
  crédits (650) a donné « Sang » ;
- équiper un titre et une traînée : la traînée est posée sur le
  personnage ;
- l'onglet des tirages affiche les 10 chances (10 % chacune).

**Vu à l'écran** : les onglets Boutique, Tirages et Passe. Le panneau
débordait d'une petite fenêtre : corrigé (il rétrécit et défile).

**Jamais vérifié** : un achat en Robux (les produits ne sont pas créés),
la comète, le cocon et l'émote portés en partie, le titre dans la liste,
et la navigation avec une vraie manette (envoyée comme des touches).

**À faire par toi** : créer sur Roblox les produits de développeur (3
paquets de crédits, le passe premium de la saison 1) et me donner leurs
numéros, puis fixer les vrais prix.

**À regarder en jouant :**

1. Croix gauche au salon : la boutique s'ouvre ; la croix, L1 / R1, A et B
   marchent à la manette ?
2. Achète une comète, porte-la, lance une partie : ton feu change de
   couleur à la chute ?
3. Une traînée te suit ? Ton titre apparaît dans la liste (R3) ?
4. L'onglet Tirages : les chances se lisent bien avant d'acheter ?
5. Les prix te conviennent ? (Tout est provisoire.)

## Les parties de test de la nuit (13 novembre 2026)

**Partie solo complète, laissée se jouer seule** (moi et 19 bots) : 15 min
30 du départ à la victoire, 4 Regards (la partie s'est finie au Regard 4,
avant le dernier), 4 pouvoirs tirés, deux Reliques posées, des dizaines de
Repris recrachés et détruits, une quinzaine de duels au Ventre (moi
éliminé par le Repris du Ventre, puisque je ne bougeais pas), retour au
salon. **Aucune erreur, aucun avertissement du jeu.**

Corrigé grâce à elle :
- la caméra du spectateur traversait les murs : écran noir derrière un
  bâtiment. Elle s'arrête maintenant devant le mur ;
- un Rampant arrachait le même bot quatre fois de suite (il rentrait
  aussitôt). Après un arrachage, il ne sent plus rien pendant 15 s.
- en escouade, les bots n'ouvraient jamais le cocon d'un coéquipier : tous
  les cocons finissaient pris par le faisceau, et un joueur avec des bots
  dans son équipe n'aurait jamais été délivré. Maintenant, un bot court
  ouvrir le cocon d'un coéquipier à moins de 120 studs, et sort même de sa
  cachette pour ça. Vérifié : deux cocons ouverts par des bots, 3 et 5 s
  après leur apparition.

**Partie en escouade complète** : une quinzaine de cocons, presque tous
ouverts par des coéquipiers bots. Mon équipe a fini 2e (+80 XP, +20
crédits, +1 fragment, juste). « Gagnant » n'annonçait que le survivant de
l'équipe : corrigé, toute l'équipe est annoncée.

**Partie en duo complète** : 18 min, la première à atteindre le Regard 5.
Le finale (l'Œil ne se ferme plus) a duré environ 1 minute ; les cachettes
solides se sont effondrées une à une, et la victoire annonçait les deux
noms du duo. Aucune erreur.

**Pas de fuite** : après deux parties, le monde compte exactement le même
nombre d'objets (35 287) au retour au salon.

**Charge du serveur dans Studio** : environ 41 images par seconde (pire
image : 60 ms), Œil ouvert ou fermé. Dans Studio, le serveur et le client
partagent la même machine : à revérifier dans le jeu publié.

**Une erreur vue, causée par ma sonde** (ma fonction de mesure renvoyait
trois valeurs) : la partie s'est arrêtée et tout le monde est revenu au
salon, proprement. Le jeu se protège donc d'une erreur en pleine partie.

**La carte** (croix gauche) dessine maintenant les zones avec leur nom,
mesurées sur la carte construite (rien de recopié).

**Un avertissement ancien** au démarrage (« 203785492 : Asset type does
not match ») vient de la place, pas du code : introuvable dans les
propriétés habituelles, et sans effet visible.

## Les défis (nuit du 13 novembre 2026)

**Vérifié par le calcul** (`tests/specs/challenges.luau`) et **seul dans
Studio** : 3 défis du jour et 3 de la semaine apparaissent. Après 8
fouilles, 3 K.O. et 3 Repris détruits (signalés par le même chemin que le
jeu) puis une victoire : deux défis du jour réussis (+30 crédits, +300 XP
de passe), les défis de la semaine avancent, et le passe atteint le palier
1.

**À regarder en jouant** : l'onglet Défis de la boutique, et le message
« Défi du jour réussi » quand il tombe en pleine partie.

## Le classement (nuit du 13 novembre 2026)

**Vu à l'écran dans Studio** : le panneau au bord du salon. Sans accès aux
API, il affiche « indisponible pour l'instant » : jamais un faux classement
vide.

**À regarder** (jeu publié, ou Studio avec l'accès aux API) : gagne une
partie, attends 2 minutes au salon, ton nom apparaît.

## Se cacher à plusieurs (nuit du 13 novembre 2026)

**Vérifié seul dans Studio** : deux bots entrent dans le même buisson, côte
à côte (à 2 studs) ; le troisième est refusé ; l'arrachage les fait sortir
tous les deux.

**À regarder en jouant (avec tes amis)** : cachez-vous à deux dans un
buisson, à trois sous un abri. Ça se voit trop de dehors ? Les places par
cachette sont-elles justes ?

## Le petit tutoriel (nuit du 13 novembre 2026)

**Vu à l'écran** : les 9 cachettes en vitrine au bord du salon, avec leur
nom et leurs places, le panneau « Comment jouer » en face du classement.
Les étiquettes se chevauchaient de loin : corrigé (taille en studs).

**À regarder** : un ami qui découvre le jeu comprend-il avec la vitrine et
le panneau ? Faut-il un vrai tutoriel guidé ?

