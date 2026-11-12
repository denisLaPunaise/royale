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

