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
