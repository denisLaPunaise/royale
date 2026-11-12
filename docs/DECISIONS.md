# Décisions prises sans Josh

Ce que l'assistant a tranché seul, avec la raison. Josh peut revenir sur
n'importe laquelle.

## 12 novembre 2026 — le dossier

- **Nom de code : Royale** (Josh : « le nom que tu veux »). Court, sans accent,
  il dit que c'est le battle royale. Le vrai titre se choisira ensemble avant
  la sortie.
- **Dépôt public**, comme `arena` et `survivor`.
- **Le goulag en duels un contre un** : la fiche gardait aussi l'ancienne idée
  d'une plateforme commune « sans duel ». Le choix des duels, plus récent
  (9 novembre), la remplace.

## 12 novembre 2026 — l'Œil et la zone

Josh a validé que les Regards et les cercles vont ensemble, et a laissé
l'assistant régler la montée de l'Œil (« je te laisse voir »).

- **5 Regards, pas plus.** Une partie dure environ 20 minutes : 5 Regards
  font environ 4 minutes chacun, assez pour fouiller, se cacher et sentir
  qu'il devient plus fort. Avec plus de Regards, il faudrait aussi plus de
  cercles : les annonces (de 90 à 45 s) se suivraient presque sans pause.
- **Un changement annoncé à chaque Regard.** Tout monte un peu à chaque
  Regard, mais une hausse de 15 à 18 studs/s ne se sent pas. Donc chaque
  Regard porte un titre qui dit ce qui change vraiment : « Il s'éveille »,
  « Il voit plus loin », « Il entend la course », « Il entend les coups »,
  « Il ne ferme plus les yeux ». Josh a ensuite validé un power-up tiré au
  hasard à chaque Regard, en plus.
- **Le tableau de la fiche (« version 2 ») devient les valeurs de départ.**
  L'ancien tableau « ce qui peut s'améliorer », plus vague, est retiré : la
  version 2 contient toutes ses lignes, chiffrées.
- **Les durées d'annonce** : 90, 80, 65, 55 et 45 s, du premier au dernier
  cercle (Josh a validé « de 90 s à 45 s »).

## 12 novembre 2026 — la carte

Josh a gardé les 9 zones proposées et laissé l'assistant régler la taille et
le plan (« je te laisse voir et adapter »).

- **1600 × 1600 studs plutôt que 1400.** À 1400, chaque zone n'aurait fait
  qu'environ 450 studs de côté en moyenne, moins de la moitié de la Banlieue
  de Survivor (800), alors que le Port, la Gare ou le Marais ont besoin de
  longueur. À 1600, on traverse en un peu plus d'une minute : pour environ 20
  joueurs, c'est à peu près cinq fois plus serré par joueur qu'un battle
  royale classique, ce qui tient la promesse « on se croise tout le temps ».
- **Un plan imbriqué, pas un damier** : le Cratère au centre sous l'Œil, la
  mer à l'ouest comme bord naturel, la Gare en bande tout le long du sud, le
  Quartier suspendu au-dessus de la Banlieue.
- **La place des thèmes** a été choisie pour que des zones voisines se
  contrastent (le Marais à côté du Port, la Fête foraine à côté du Lycée).

## 12 novembre 2026 — le tour de l'Œil refait

Josh : le globe, l'iris et les veines sont parfaits, mais le tour de l'Œil
(un « carré noir » au-dessus, des paupières plates) ne va pas avec le reste.
Pris par l'assistant :

- **Le fond de la déchirure** n'est plus une plaque noire plate (c'était le
  carré) : une voûte courbe, rouge très sombre, éclairée de l'intérieur, assez
  petite pour rester cachée derrière la déchirure.
- **De vraies paupières** : deux coques de peau qui épousent le globe, avec un
  bourrelet humide, une braise le long de la jointure et des cils. Elles
  s'ouvrent et se ferment en tournant autour de l'axe est-ouest du globe
  (attributs `Cote`, `Ouvert`, `Ferme`, en degrés). **À faire** : la vue du
  ciel côté client (reprise de Survivor) devra les animer par cette rotation,
  et non plus en allongeant des bandes.
- **Une orbite de chair** : des bourrelets serrés descendent du bord de la
  déchirure jusqu'au globe ; plus de vide noir autour de l'Œil.
- **La déchirure** a un bord irrégulier (bruit et quelques longues fentes) au
  lieu d'une étoile à pointes régulières.

## 12 novembre 2026 — le cœur du jeu, choix pris sans Josh

Josh a laissé l'assistant construire le cœur du jeu en autonomie (« fais
d'abord le cœur »). Ce que la fiche ne fixait pas, pris par l'assistant :

- **Le cercle** : il s'annonce au début de chaque Regard (taille calculée
  d'après les participants en vie, bots compris), reste annoncé
  `announceSeconds`, puis se resserre en **60 s** (`Config.zone.shrinkSeconds`).
  Avant le premier, toute la carte est jouable et aucun mur ne s'affiche.
- **Être vu** : il faut être dans la lumière d'un faisceau **et** relié au
  bout de la pupille par une ligne réelle (tête ou bassin). Les faisceaux ne
  sortent jamais du cercle ; dehors, c'est la jauge rouge diffuse.
- **Les faisceaux** : à chaque ouverture, chacun tombe à 80 studs d'un
  participant tiré au sort (on voit la lumière venir). Sans cible, il va vers
  le bruit le plus proche (la course à partir du Regard 3, tout mouvement au
  Regard 5), sinon vers le participant le plus proche, **jamais plus vite
  qu'en poursuite**. L'erreur de visée se retire toutes les 2 s.
- **Les cachettes** : pour l'instant, toutes s'utilisent de la même façon
  (maintenir X pour entrer, X pour sortir), roseaux et buissons compris. Un
  recoin à ciel ouvert (fossé, derrière un muret) ne demande rien : la ligne
  de vue suffit, et s'accroupir (B) baisse vraiment la tête.
- **L'arrachage** : à chaque ouverture, l'Œil prend jusqu'à `ripsPerBurst`
  cachettes marquées avant cette ouverture, les occupées d'abord, celles des
  campeurs flairés avant tout ; chaque arrachage tombe à un moment au hasard
  de l'ouverture, après 1,5 s de tremblement. Les cachettes solides ne
  s'arrachent pas encore (leur effondrement au Regard 5 viendra).
- **La méfiance** monte quand on reste caché (dans une cachette, ou hors de
  vue de l'Œil) à moins de 15 studs du même point. Pleine : la cachette est
  arrachée sur-le-champ (Œil ouvert), ou un faisceau libre vient sur toi — il
  ne te voit que si tu es vraiment à découvert. Puis elle repart de zéro.
- **Seul**, sans bots, la partie dure jusqu'à ce que l'Œil te prenne. Un
  personnage qui meurt (chute dans le vide) compte comme aspiré.
- **En attendant le salon**, on attend au centre de la carte (le Cratère) et
  les parties s'enchaînent toutes seules.
- **Les paupières** : fermées, l'iris et la pupille (qui dépassent du globe)
  s'effacent chez chaque client, sinon ils passaient au travers.
- **Les bots** : 17 à 24 participants au total. Ils voient ce qu'un joueur
  voit (faisceaux, cercle, Œil, cachettes libres, leur propre méfiance) et
  rien de plus. Temps de réaction humain (0,35 à 1,1 s), et une ouverture sur
  cinq ils jouent mal (restent dehors). Avatars simples aux couleurs tirées au
  sort, noms inventés. **Pas encore fait** : la liste des joueurs du jeu (la
  liste de Roblox ne montre que les vrais joueurs, donc trahit les bots).
- **Les cachettes solides au Regard 5** s'effondrent : l'Œil peut les prendre
  comme les autres (on en est chassé avec 2 s de répit, on n'y rentre plus).
  Elles ne s'envolent pas, elles font partie de la carte. **Trou connu** :
  avant le Regard 5, un campeur flairé dans une cachette solide ne risque
  rien ; ce sont les Repris (pas encore faits) qui doivent s'en charger.
- **La liste des joueurs de Roblox est cachée** pendant la partie, pour ne
  pas trahir les bots ; la liste du jeu viendra avec le salon.
- **Les bots anticipent le cercle** : dès que le prochain est annoncé, ils
  quittent une cachette qui sera dehors (Œil fermé) et visent une cachette
  dedans. Sans ça, quatre d'un coup se faisaient prendre au premier
  resserrement (vu en partie de mesure).

## 12 novembre 2026 — le corps à corps, choix pris sans Josh

- **Porter prolonge le K.O.** jusqu'à 6 s depuis qu'on soulève : avec un
  K.O. de 2,5 s, on n'aurait jamais eu le temps de porter quelqu'un. Après
  6 s, il se débat et tombe.
- **Le plaquage raté fait tomber quand même** celui qui plaque : sinon on
  plaquerait dans le vide sans risque pour aller plus vite.
- **Toquer à un abri attire l'Œil à tout Regard**, même avant qu'il entende
  la course : c'est un geste voulu pour dénoncer, comme le pétard. Les coups
  qui portent, eux, ne s'entendent qu'à partir du Regard 4 (« Il entend les
  coups »).
- **Pousser sur un abri déloge l'occupant sans répit** : c'est un joueur qui
  l'a trouvé, pas l'Œil (le répit de 2 s reste pour les arrachages).
- **Y : sans K.O. à portée, la poussée part tout de suite** ; près d'un K.O.,
  on attend 0,4 s pour savoir si c'est un maintien (porter). Sinon chaque
  poussée aurait 0,4 s de retard.
- **Les bots rendent les coups** pendant 4 s et cherchent parfois querelle
  quand l'Œil est fermé ; ils ne portent ni ne jettent personne (pour
  l'instant).
- **S'allonger, ramper et tirer par les pieds attendent** les animations de
  posture : sans elles, un corps « allongé » serait un corps enfoncé dans le
  sol.

## 12 novembre 2026 — les objets, choix pris sans Josh

- **L'équilibrage avant le code** (demandé par Josh) : chaque objet porte sa
  durée de protection contre l'Œil (`shield`, la durée réelle de son
  effet). Un test vérifie que le meilleur sac de 4 protège au plus un quart
  du plus court Regard (45 s sur 210) et qu'aucun objet ne couvre toute
  une ouverture. Ce qui contre chacun : la fumée ne cache que dedans, la
  cape ralentit sans arrêter, la bâche saute dès qu'on bouge, le miroir ne
  sert que si un faisceau te suit, le mannequin et les fusées attirent un
  faisceau sans l'éteindre.
- **Un meuble sur deux environ a quelque chose** (7 par participant, 60 au
  moins, sur 276) ; les autres se fouillent pour rien. Fouiller fait du
  bruit (entendu à partir du Regard 4).
- **L'adrénaline ne dépasse pas la course** (22) : la fiche interdit d'aller
  plus vite que l'Œil au dernier Regard. Elle donne donc la course dans
  toutes les postures (accroupi, en portant quelqu'un), sans bruit pour
  l'Œil, et on se relève deux fois plus vite. À revoir si elle semble
  inutile.
- **La batte se consomme** : 6 coups qui portent, puis elle est finie
  (« presque tout se consomme »).
- **Planches et Cadenas se posent de l'intérieur** de sa cachette : ils
  empêchent qu'on te déloge (poussée, boule puante), pas l'Œil d'arracher.
  Le cadenas seulement dans une cachette solide. Les cachettes n'ont qu'une
  place pour l'instant, donc « personne d'autre n'entre » revient au même.
- **Le carton piégé s'envole** quand quelqu'un s'y fait prendre (l'Œil
  l'arrache, à la vue de tous) : il ne piège qu'une fois.
- **La clochette se voit à l'écran** (« Une clochette sonne, à 40 m ») : le
  jeu n'a encore aucun son.
- **Le Cocon de secours ne marche plus à partir du Regard 4** : la fiche dit
  qu'il ne marche plus quand le goulag ferme, aux deux derniers cercles.
- **Deux Reliques par partie**, au début des Regards 3 et 4, sur un
  emplacement de cachette à moins de la moitié du rayon du cercle.
- **Un objet lancé ne touche jamais son lanceur** (bouteille, filet).
- **Ce qui est par terre disparaît après 2 minutes.**
- **Les bots** fouillent quand l'Œil est fermé (à moins de 120 studs),
  courent à une relique à moins de 300 studs, et sortent leur meilleur
  objet de protection quand un faisceau les suit. Ils ne posent ni craie ni
  piège.


## 12 novembre 2026 — les pouvoirs de l'Œil, choix pris sans Josh

La fiche demandait d'équilibrer les 14 power-ups avant de coder. Josh ayant
laissé l'autonomie, l'assistant a fixé ces valeurs (toutes dans
`Config.eyePowers`, à régler en jouant) :

- **Le tirage** : au début de chaque Regard, Regard 1 compris (l'Œil en a
  donc cinq au Regard 5). Jamais deux fois le même ; au Regard 5, ni « Il
  entend tout » ni ce qui joue sur les pauses (il ne se ferme plus).
- **La rage** : un faisceau de plus aux rafales paires.
- **Le faux départ** : environ une pause sur trois ne dure que 2 s, **jamais
  deux de suite**, pour qu'il reste toujours une vraie pause pour fouiller.
- **Le regard long** : l'une des 3 premières rafales de chaque Regard dure
  deux fois plus.
- **La faim** : arrachages × 1,5, arrondi au-dessus.
- **L'œil lent mais sûr** : poursuite × 0,85, piste + 2 s. Au Regard 5, la
  course le distance enfin un peu.
- **Le flair** : parmi les cachettes occupées à arracher, la plus ancienne
  occupation d'abord (les campeurs flairés restent en tête).
- **Le regard rasant** : un second regard part à 30° au-dessus de l'horizon,
  du côté de l'Œil ; on est vu si l'un des deux voit. Il passe sous les
  auvents, jamais à travers un mur. Mesuré : sur 19 bots, environ 1 sur 6
  de ceux qui étaient couverts devient visible.
- **La rancune** : les cachettes marquées ne s'oublient plus (au lieu de 3
  ouvertures).
- **L'éclair** : à chaque ouverture, ceux qui sont à découvert dans le
  cercle brillent en rouge 2 s, visibles à travers les murs pour tout le
  monde.
- **La paupière lourde** : pauses × 2/3.
- **Le retour** : 5 s après avoir perdu une piste, le faisceau libre le plus
  proche va voir la dernière position pendant 4 s.
- **Le souffle** : un seul vent par ouverture, même sens pour tous, à 26
  studs/s (une poussée fait 34) : il déplace d'environ 5 studs sans
  renverser.
- **Les empreintes** : qui court laisse une trace rouge tous les 0,4 s, qui
  reste 10 s. Un faisceau sans cible qui passe à moins de 70 studs d'une
  piste la remonte jusqu'à la trace la plus récente, avant les bruits.
- **À l'écran** : la liste des pouvoirs sous les restants, et l'annonce en
  grand 7 s au début de chaque Regard.

## 12 novembre 2026 (nuit) — les Repris, choix pris sans Josh

- **Vitesses** : Errant 8, Rampant 7, Hurleur 9 (moins que la marche, 14) ;
  Coureur 19 (moins que la course, 22).
- **Coups pour les détruire** : 3, et 2 pour le Coureur. Un Repris détruit
  lâche un objet commun par terre.
- **Combien** : à chaque fermeture, 1 pour 8 joueurs en vie au Regard 1,
  puis 7, 6, 4, et 3 au Regard 5 (à chaque rafale, puisqu'il ne se ferme
  plus). Plafond : 1 Repris pour 2 joueurs en vie. La moitié est
  re-aspirée au début de chaque Regard.
- **Où ils tombent** : à 30–60 studs d'un joueur tiré au sort ; un joueur
  caché pèse 3 fois plus dans ce tirage. La chute laisse une traînée rouge.
- **Ce qu'ils voient** : comme l'Œil, une vraie ligne de vue depuis leur
  tête, jusqu'à 60 studs (70 pour le Coureur). Ils ne voient pas à travers
  la fumée, ni quelqu'un de caché dans une cachette. Un joueur lent
  (accroupi ou immobile, sous 8 studs/s) n'est vu qu'à 60 % de cette
  distance.
- **Errant** : quand il voit quelqu'un, il crie, au plus une fois toutes les
  10 s. Le faisceau le plus proche va pendant 4 s à l'endroit où était le
  joueur.
- **Hurleur** : il hurle, au plus une fois toutes les 12 s. L'Œil entend le
  bruit 5 s, à tout Regard, et les Repris à moins de 80 studs accourent.
- **Rampant** : il sent un joueur caché dans une cachette à 14 studs, va à
  l'entrée la plus proche, et l'arrache après 1,5 s collé contre elle. Les
  planches et le cadenas le bloquent.
- **Coureur** : il grogne 0,8 s, puis plaque s'il est encore à portée. Au
  sol 2 s, au plus une fois toutes les 4 s.
- **Flairé sans rien à arracher** : l'Œil envoie 2 Repris près de lui, dans
  la limite du plafond.
- **Les bots** frappent un Repris qui arrive à portée de coup.
- **Leur corps** : celui de Survivor (le crâne généré, la cendre, les
  animations Zombie). Le crâne est chargé au démarrage du serveur depuis son
  asset.
