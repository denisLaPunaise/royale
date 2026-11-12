# L'Œil — Battle royale : la fiche

Nom de code : **Royale** (titre à choisir). Commencée le 9 novembre 2026,
reprise le 12 novembre 2026.

Tout ce qu'on a dit sur le battle royale de l'Œil, rangé par sujet, pour ne rien oublier. Chaque point porte un statut :

- **Validé** : on est d'accord tous les deux.
- **Proposé** : idée de Claude, pas encore tranchée.
- **À voir** : à réfléchir ensemble avant de coder ce qui en dépend.

Quand on tranche un point, on change son statut ici, et on note la date.

## Le principe

**Validé.** Un battle royale où l'ennemi principal est l'Œil géant du ciel. Il balaie la ville, aspire tout joueur qu'il voit, et devient plus fort de phase en phase. Le dernier joueur, ou la dernière escouade, pas encore capturé gagne.

**Validé.** C'est un jeu à part de Survivor (le jeu de survie en mode histoire), qui garde la même base :

- bien caché, on est en sécurité : l'Œil ne triche jamais, être vu est une vraie ligne de vue ;
- les Balayages, la traque, la jauge d'exposition avant l'aspiration ;
- les cachettes marquées puis arrachées, les toits qui partent, la ville qui s'abîme ;
- le fumigène qui coupe la ligne de vue ;
- le Ventre de l'Œil, où l'on arrive quand on est aspiré.

**Proposé.** Pas d'armes à feu : le vrai tueur, c'est l'Œil. Les joueurs se nuisent surtout en le faisant travailler pour eux.

## Une partie

| Point | Statut | Ce qu'on a dit |
| --- | --- | --- |
| Durée | Validé | 15 à 25 min par partie, en 5 phases |
| Victoire | Validé | Le dernier joueur ou la dernière escouade pas capturé gagne |
| Modes | Validé | Solo et escouade |
| Taille d'escouade | Proposé | Duo et escouade de 4 |
| Nombre de joueurs | Validé | 24 joueurs au plus pour commencer ; on montera plus tard si les serveurs se remplissent |
| Découpage | Proposé | 5 phases, les « Regards », au lieu des jours de Survivor |

**Validé (9 novembre) : le serveur n'attend pas d'être plein.** Il attend des joueurs pendant un certain temps, puis lance la partie même à 5. Le jeu s'adapte alors au nombre de joueurs présents : taille de la zone jouable, nombre de cachettes, quantité de butin, force de l'Œil.

**À voir.** Le temps d'attente avant de lancer (1 à 2 min ?), et le minimum absolu de joueurs.

## L'Œil et sa montée en puissance

**Validé.** L'Œil devient plus fort au fil de la partie : il arrache plus de choses, il reste de moins en moins de cachettes. **À préciser ensemble** : ce qui monte exactement, et de combien, Regard par Regard.

**Retenu, à préciser (9 novembre) : l'Œil chasse en permanence**, pour que le début ne soit pas mou. Ordre de ses cibles :

1. **Un joueur visible** (dehors, sans toit) : un faisceau fonce sur lui. Le faisceau se déplace, il ne se téléporte pas : on voit la lumière venir.
2. **Il se cache ou sort de sa vue** : l'Œil garde sa piste un moment, puis passe au joueur visible le plus proche.
3. **Tout le monde est caché** : il prend la zone où il y a le plus de joueurs et fait le ménage, toits et cachettes autour d'eux, puis leurs cachettes. Éjecté, on a 2 s de répit pour courir.

Bien caché, on n'est jamais aspiré directement, mais une cachette n'est jamais sûre longtemps.

**Retenu, à préciser : il regarde par rafales**, environ 30 à 40 s ouvert, puis quelques secondes fermé (son temps de recharge). Sans ces respirations, on ne pourrait plus fouiller.

**Retenu, à préciser : ce qui peut s'améliorer** (repris des idées de Survivor) :

| Amélioration | Début de partie | Fin de partie |
| --- | --- | --- |
| Nombre de faisceaux | 1 pour 8 joueurs | 1 pour 4 joueurs |
| Vitesse de poursuite | Moins vite que la marche | Plus vite que la course |
| Temps fermé entre deux rafales | \~20 s | \~5 s |
| Mémoire de la piste | 1 s | 4 s |
| Précision de la visée | « Dans le coin » | Pile sur toi |
| Arrachages autour des cachés | Quelques cachettes | Des rues entières |
| Taille du faisceau | Un trottoir | Une rue |
| L'ouïe (il vient vers le bruit) | Non | Course, coups, fouille |
| Temps avant d'être aspiré | 2 s | 1,5 s |

**Idée à garder :** une capacité en plus tirée au hasard à chaque Regard, pour que l'Œil soit un peu différent d'une partie à l'autre (« cette partie, il entend tout »).

**Validé (9 novembre) : une partie de 15 à 25 min.** **Proposé, version 2 du tableau** (corrigée après relecture : la phase 1 était trop molle, les phases 4 et 5 trop dures). Repères : marche 14, course 22 (en studs par seconde).

|  | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
| --- | --- | --- | --- | --- | --- |
| Durée | 5 min | 4 min 30 | 4 min | 3 min 30 | 3 min au plus |
| Faisceaux (au moins 1) | 1 pour 8 joueurs en vie | 1 pour 7 | 1 pour 6 | 1 pour 5 | 1 pour 4 |
| Ouvert par rafale | 30 s | 35 s | 40 s | 45 s | Ne se ferme plus |
| Fermé entre deux rafales | 20 s | 15 s | 12 s | 8 s | — |
| Vitesse de poursuite | 12 | 15 | 18 | 20 | 22 |
| Mémoire de la piste | 1 s | 1,5 s | 2 s | 3 s | 3,5 s |
| Erreur de visée | 60 studs | 40 | 25 | 15 | 5 |
| Arrachages par rafale autour des cachés | 3 | 4 | 6 | 8 | 12 |
| Rayon du faisceau | 14 studs | 16 | 18 | 20 | 22 |
| Plein regard avant l'aspiration | 2 s | 2 s | 1,8 s | 1,8 s | 1,6 s |
| L'ouïe | Non | Non | La course | Course et coups | Tout bruit |
| Jauge hors zone pleine en | 20 s | 15 s | 11 s | 8 s | 5 s |

**Proposé : la fin est garantie.** En phase 5, le dernier cercle se referme jusqu'à rien : la partie ne dépasse jamais 25 min. Si les derniers sont aspirés en même temps, celui qui l'est en dernier gagne.

**Proposé : un trait au hasard par phase**, à partir de la phase 2, annoncé à l'écran, pour que deux parties ne se jouent pas pareil :

- **Il entend tout** : l'ouïe de la phase 5 dès maintenant ;
- **La rage** : deux fois plus de faisceaux pendant une rafale ;
- **Le faux départ** : il se ferme puis se rouvre aussitôt ;
- **Le regard long** : une rafale qui dure deux fois plus longtemps ;
- **La faim** : il arrache deux fois plus ;
- **L'œil lent mais sûr** : poursuite plus lente, mais il ne perd plus jamais une piste.

Avec moins de 24 joueurs, le nombre de faisceaux suit déjà les joueurs en vie ; les autres chiffres restent les mêmes. Tout se règle en jouant.

## La carte

**Validé.** La carte change à chaque partie, pour qu'on ne se lasse pas.

**Validé (9 novembre) : une carte assez petite pour que les joueurs se croisent tout le temps.** La zone jouable s'adapte au nombre de joueurs : plus on est nombreux, plus elle est grande. Il doit toujours y avoir de l'interaction.

**Proposé : une seule grande carte, découpée en 5 à 7 zones de styles différents.** Par exemple : la Banlieue (beaucoup de recoins), la Zone commerciale (un hypermarché, de grands parkings à découvert), le Parc (presque aucun couvert, mais des tunnels), la Zone industrielle (hangars, conteneurs), le Centre-ville (tours, toits, souterrains). Chaque zone a ses cachettes et son butin propres, ce qui donne des choix de départ différents.

**Ce qui change d'une partie à l'autre (proposé) :**

- l'emplacement de chaque zone sur la carte, tiré au hasard parmi quelques dispositions ;
- les cachettes fragiles posées parmi des centaines d'emplacements possibles (comme Survivor) ;
- les maisons déjà en ruine, les rues bloquées, les caves ouvertes ;
- le butin rare et les lieux d'événement.

**Proposé : le départ.** Tout le monde est recraché par l'Œil au début, et choisit où tomber, en tombant de la Fissure. C'est le saut en parachute des battle royale, mais dans notre univers.

**Validé (9 novembre) : une zone ronde.** Elle rassemble bien les joueurs. Elle ne se resserre pas petit à petit : le prochain cercle est annoncé, et **à la fin de l'annonce, tout ce qui est dehors devient rouge d'un coup**.

**Proposé, les détails :**

- le prochain cercle est toujours entièrement dans le cercle actuel, et se voit dès l'annonce (au sol, sur la carte) ;
- l'annonce laisse le temps de rentrer : 60 à 90 s, à régler ;
- le centre est tiré au hasard à chaque partie ;
- le premier cercle dépend du nombre de joueurs : à 5 joueurs, il est bien plus petit qu'à 24.

**Validé : hors de la zone, l'Œil est impitoyable.** **Proposé, pour que ce ne soit pas brouillon : pas de faisceaux dehors.** Les faisceaux ne chassent que dans la zone. Dehors, tout est sous un regard rouge diffus, le même pour tout le monde :

- la jauge monte en continu, même caché : il faut rentrer. **Validé : elle aspire de plus en plus vite au fil de la partie** (proposé : pleine en \~20 s au premier cercle, \~5 s au dernier) ;
- les cachettes et les toits du dehors sont arrachés au hasard, de plus en plus vite : le décor s'envole en arrière-plan ;
- se cacher dehors ne sert à rien : sa cachette part, on est éjecté.

Ainsi, chaque chose a un seul sens à l'écran : **un faisceau = la chasse dans la zone ; le rouge = la mort dehors**.

## Cachettes et butin

**Validé (9 novembre) : les cachettes sont le cœur du jeu.** Beaucoup de styles différents, chacun avec sa mécanique, et **aucune trop forte** : chaque cachette a une faiblesse.

**Validé : trois familles.**

| Famille | Places | Solidité | Exemples |
| --- | --- | --- | --- |
| Fragiles | 1 | L'Œil les arrache facilement | Buisson, poubelle, tôle, carton, sous un tas de gravats |
| Moyennes | 2 | Elles tiennent un arrachage de plus | Voiture, abri de jardin, armoire, frigo couché, cabine de camion |
| Solides | 3 à 4 | Rares et fixes, elles s'effondrent en fin de partie | Cave, tunnel, égout, conteneur, bus renversé |

**Validé : chaque partie a ses propres cachettes.** La carte reste la même, mais les cachettes et leurs emplacements changent vraiment d'une partie à l'autre, et leur nombre suit le nombre de joueurs.

**Validé : on ne les affiche pas.** Pas de lueur ni de symbole : on apprend à les reconnaître (un petit tutoriel les présente au début). On interagit en arrivant à côté. Premier arrivé, premier servi.

**Validé : on ne voit pas si quelqu'un est dedans.** C'est une surprise : on ouvre la voiture et on tombe sur quelqu'un.

**Validé : libre de ses mouvements selon la cachette, et des cachettes sans interaction.** **Proposé, trois sortes :**

- **Les volumes**, où l'on bouge librement : buisson, sous une bâche, tas de gravats, grand conteneur, cave. Comme dans Fortnite, de l'intérieur la cachette devient translucide pour soi. On peut y être à plusieurs, et tomber sur quelqu'un.
- **Les abris fermés**, où l'on entre avec X : voiture, armoire, frigo, poubelle. On voit dehors depuis l'intérieur. Ouvrir un abri occupé met face à celui qui y est.

- **Les recoins**, sans aucun bouton : on s'y jette, on s'accroupit ou on s'allonge, et c'est la vraie ligne de vue qui décide si l'Œil te voit. Exemples : glisser sous une voiture ou un camion, s'allonger dans un fossé, sous une table de jardin, derrière un muret bas, sous un escalier, sous un porche, sous un pont. Leur faiblesse : vu de biais, l'Œil peut te voir ; l'objet au-dessus peut être arraché ; on se relève lentement. S'y abriter pendant un Balayage marque le recoin, comme une cachette.

**Proposé : les postures, à la manette.** B en courant : glissade (elle passe sous les objets bas et finit allongé s'il n'y a pas la place de se relever). B à l'arrêt : s'accroupir. Maintenir B : s'allonger, et ramper.

**Proposé : les cachettes à mécanique** (chacune avec sa faiblesse) :

| Cachette | Sa force | Sa faiblesse |
| --- | --- | --- |
| Voiture | Deux portières, on peut fuir par l'autre côté | Ouverte d'un côté, on te voit |
| Buisson | On y bouge, on peut être plusieurs | Il couvre à moitié : un faisceau qui reste dessus finit par voir |
| Plaque d'égout | Ressort plus loin : traverser une rue sans être vu | Étroit : on y croise les autres, et on ne voit pas ce qui attend à la sortie |
| Armoire, frigo | Protègent même quand le toit est arraché | Dans une maison, là où l'Œil arrache le plus |
| Conteneur | Se ferme de l'intérieur | Fait un vacarme à l'ouverture |
| Château d'eau, toit plat | On voit tout | Piégé si un faisceau arrive |
| Cave | Solide, plusieurs places | Une seule sortie : un cadenas ou un piège à loup et on est coincé |

**À voir : le nombre.** Proposé : au début, un peu plus de places que de joueurs ; en finale, moins de places que de joueurs, pour qu'il faille se battre pour une place. Une simulation vérifiera qu'aucune cachette n'est trop forte.

**Proposé : risque contre gain.**

- Le meilleur butin est là où c'est dangereux : sous un toit qui va partir, à découvert, dans une zone qui va être condamnée.
- **Les Reliques** : après certains Balayages, l'Œil lâche un objet rare au milieu d'une place, annoncé à tous. Tout le monde le veut, et il faut traverser à découvert.
- Fouiller fait du bruit et prend du temps : on hésite quand le ciel rougit.
- Un sac limité : on choisit ce qu'on garde.

Les objets et leurs raretés : voir la section Les objets.

## Interactions entre joueurs

**Validé.** Il faut beaucoup d'interactions entre joueurs, par le butin comme au corps à corps (se taper pour mettre K.O. quelques secondes). **À voir** : lesquelles on garde. Banque d'idées (proposées) :

**Au corps à corps**

- **Le coup** : met K.O. 2 à 3 secondes, avec un temps de recharge. Un joueur K.O. à découvert pendant un Balayage est en grand danger.
- **La poussée** : faire sortir quelqu'un de sa cachette, ou le pousser dans le faisceau.
- **Voler** : fouiller le sac d'un joueur K.O. et lui prendre un objet.
- **Plaquer** en courant : on tombe tous les deux, mais l'autre plus longtemps.

**Avec des objets** : voir la section Les objets, juste en dessous.

**À voir avant de choisir : la manette.** Frapper, pousser, voler, plaquer, glisser, s'accroupir, s'allonger, lancer, utiliser un objet, le sac, les signaux : il faut un tableau des boutons, contexte par contexte. Une action qui n'y rentre pas se sacrifie.

**Entre coéquipiers**

- relever un ami K.O., partager un objet, se cacher à plusieurs dans une grande cachette ;
- détacher un coéquipier recraché dans un cocon (voir Capturé) ;
- des signaux rapides à la croix directionnelle.

## Les objets

**Validé (9 novembre) : beaucoup d'objets, en cinq raretés, jusqu'à épique et légendaire.** **Les règles et le catalogue ci-dessous sont retenus tels quels (9 novembre) ; on les revalidera au moment de coder**.

**Proposé : les règles.**

- Presque tout se consomme : un objet sert une fois ou pendant un temps limité. Rien ne s'additionne pour rendre un joueur intouchable.
- Aucun objet n'annule l'Œil : il aide à lui échapper un moment, jamais pour de bon.
- Sac limité : 4 places pour les objets, on choisit ce qu'on garde.
- Chances à chaque fouille, à régler : commun 55 %, peu commun 25 %, rare 13 %, épique 6 %, légendaire 1 %.
- Les épiques sont plutôt aux endroits dangereux (sous un toit qui va partir, près du bord de la zone).
- **Les légendaires ne se fouillent presque jamais** : ils tombent surtout des **Reliques**, que l'Œil lâche au milieu d'une place, annoncées à tous. Un ou deux par partie au plus.
- Celui qui porte un légendaire brille un peu : tout le monde veut le lui prendre.
- Couleurs habituelles : gris, vert, bleu, violet, or.

**Proposé : le catalogue.**

| Rareté | Objet | Ce qu'il fait |
| --- | --- | --- |
| Commun | Fumigène | Un nuage qui coupe la ligne de vue 15 s ; l'Œil perd ta piste |
| Commun | Pétard | Fait du bruit là où il tombe : attire l'Œil et les joueurs |
| Commun | Fusée éclairante | Lancée sur un joueur ou au sol, elle attire un faisceau |
| Commun | Craie | Marque la cachette d'un autre : l'Œil vient l'arracher |
| Commun | Bouteille | Lancée, elle étourdit 1 s à distance |
| Peu commun | Batte | K.O. en deux coups au lieu de trois |
| Peu commun | Piège à loup | Posé devant une cachette, il bloque 3 s celui qui en sort |
| Peu commun | Jumelles | Voir de loin les joueurs à découvert, signalés 5 s |
| Peu commun | Planches | Barricader une porte ou une cave 20 s |
| Peu commun | Carton piégé | Une fausse cachette : qui y entre est éjecté et marqué |
| Rare | Cape d'ombre | Ta jauge monte moitié moins vite pendant 20 s |
| Rare | Cadenas | Ferme une cave de l'intérieur : personne d'autre n'entre |
| Rare | Miroir | Renvoie le faisceau qui te poursuit vers le joueur le plus proche |
| Rare | Radio | Montre où vont les faisceaux pendant 30 s |
| Rare | Grappin | Monter sur un toit ou passer un mur |
| Épique | Bâche de plomb | Immobile dessous, le faisceau ne te voit pas pendant 10 s |
| Épique | Mannequin | L'Œil le prend pour un joueur et le poursuit 10 s |
| Épique | Œil de verre | 15 s : tu vois à travers les murs les joueurs proches |
| Épique | Fusée rouge | Attire tous les faisceaux sur un point pendant 5 s |
| Légendaire | Le Regard volé | Pendant 10 s, tu diriges toi-même un faisceau |
| Légendaire | La Larme de l'Œil | Il cligne : tous les faisceaux s'éteignent 5 s, partout |
| Légendaire | Le Cocon de secours | Aspiré, tu es recraché aussitôt sur place, sans passer par le goulag (une fois) |
| Légendaire | Le Fragment de Fissure | 15 s invisible pour l'Œil, mais tu brilles pour les joueurs |

## Capturé

**Validé : le goulag.** Aspiré, on arrive dans le Ventre de l'Œil. On ne peut s'en sortir **qu'une seule fois** par partie.

**Validé (9 novembre) : des plateformes suspendues dans le vide.** Il faut mettre l'autre K.O. et **le jeter par-dessus bord** pour être sauvé ; celui qui tombe est éliminé. (L'idée d'une seule plateforme pour tous, sans duel, est remplacée par les duels un contre un ci-dessous.)

- **on revient le sac vide** ;
- **en solo**, on revient à un endroit au hasard ;
- **en escouade**, on revient près d'un coéquipier, dans un cocon qu'il ouvre en tapant dessus 3 fois (à régler).

**Validé (9 novembre) : comment ça se joue.**

- **Des manches toutes les \~45 s, en duels un contre un** (choix du 9 novembre, pour qu'on sache toujours qui gagne et qui perd). Tous ceux qui ont été capturés depuis la dernière manche sont répartis par paires, chaque duel sur sa petite plateforme, tous en même temps : personne n'attend plus d'une manche. Celui qui jette l'autre est sauvé.
- **Validé (12 novembre) : la mort subite.** Si personne n'est tombé à la fin du temps, les bords s'effritent de plus en plus vite jusqu'à ce que quelqu'un tombe : un duel a toujours un gagnant.
- **Ceux qui attendent la manche suivante sont dans des cages autour de la plateforme**, et regardent.
- **Nombre impair** : celui qui reste seul affronte un Repris contrôlé par le jeu.
- **L'arme : une batte, la même pour tous.** Trois coups mettent K.O. 2 s ; un coup sur quelqu'un de K.O. l'envoie voler.
- **C'est le dernier à avoir frappé qui est sauvé.** Tomber tout seul ne sauve personne.
- **Sauvé, on quitte la plateforme aussitôt** : la manche continue pour les autres.
- **Les bords s'effritent** pendant le duel.
- **Jamais deux coéquipiers dans le même duel**.
- **Le goulag ferme pour la fin de partie** : en finale, être aspiré est définitif. **Validé (12 novembre) : il ferme aux deux derniers cercles**, quel que soit le nombre de joueurs (la règle « moins de 6 en vie » est abandonnée : une partie lancée à 5 n'aurait jamais eu de goulag).

**Validé : le cocon révèle où l'on est.** En escouade, on revient dans un cocon près d'un coéquipier, qui l'ouvre en 3 coups. Le cocon signale sa place à l'Œil : s'il n'a pas déjà une cible, il vient. **Validé : si le faisceau atteint le cocon avant qu'il soit ouvert, le joueur dedans est aspiré pour de bon** (sa deuxième capture). Proposé : environ 8 s avant que l'Œil arrive.

**Validé : on ne laisse pas les morts dénoncer.** Si tous les éliminés peuvent signaler des joueurs à l'Œil, ce sera le bazar.

**Validé (9 novembre) : ce que fait un éliminé**, une fois sa chance au goulag passée. Il choisit :

1. **Regarder un coéquipier**, depuis ses yeux.
2. **Parier** sur le joueur qui gagnera : s'il a raison, il gagne des crédits pour la boutique.
3. **Quitter** et revenir au salon d'attente.

**Validé (12 novembre) : les paris.**

- Un pari juste **rapporte un peu** : sympa, mais jamais le meilleur moyen de gagner des crédits.
- **On ne peut pas parier sur un ami Roblox** : deux amis ne peuvent pas s'arranger pour que l'un se fasse aspirer exprès et parie sur l'autre.

**À voir.** Le chiffre exact du gain, et si l'on peut parier jusqu'à la fin ou seulement avant un certain Regard.

## Progression et boutique

**Validé.** Aucun achat ne donne de puissance, comme Survivor. On gagne en jouant :

- de l'XP de compte et des niveaux ;
- des cosmétiques : tenues, effet de capture, cocon, émotes ;
- des titres et un classement.

**À voir.** Des défis quotidiens ou une saison ? Faut-il une version gratuite du cosmétique pour chaque objet payant ?

## Mise en place

**Validé.** Un dépôt séparé, qui reprend une copie des morceaux utiles de Survivor : le trajet des Balayages, la jauge, les courbes de montée, les cachettes marquées, le fumigène, l'Œil et sa ligne de vue. Même façon de travailler : Rojo, tests, CI, tous les chiffres dans un seul fichier de réglages.

**Proposé, l'ordre de construction :**

1. **La version minimale** : une carte (une Banlieue plus serrée), 8 à 16 joueurs en solo, les 5 Regards, la capture, des cachettes à une place, l'écran de victoire. Une seule question : est-ce tendu et amusant de se cacher contre les autres ?
2. Le coup qui met K.O., la poussée, les premiers objets (fusée, leurre, fumigène).
3. Les escouades, le goulag, le cocon.
4. La carte en zones qui change à chaque partie, et ce qui ramène tout le monde au centre.
5. Le salon d'attente, la recherche de partie, la progression cosmétique.

## Questions ouvertes

- [x] Le nombre de joueurs : 24 au plus, la partie se lance même incomplète.
- [x] Ce que fait un éliminé définitif : regarder, parier, ou quitter.
- [ ] Le temps d'attente avant de lancer, et le minimum de joueurs.
- [ ] Comment le jeu s'adapte au nombre de joueurs (zone, cachettes, butin, Œil).
- [ ] L'Œil : sa chasse en permanence, ses rafales, et le tableau des améliorations Regard par Regard.
- [ ] La zone : durée de l'annonce, taille des cercles, vitesse de la jauge dehors.
- [ ] Le départ : on choisit où tomber, ou on est placé au hasard ?
- [ ] Les zones de la carte et leur style.
- [ ] Les interactions à garder dans la banque d'idées, et le tableau des boutons de la manette.
- [ ] La liste des cachettes et des objets, avec leurs raretés.
- [x] Le goulag : il ferme aux deux derniers cercles ; un duel nul se finit en mort subite ; un cocon atteint par le faisceau avant d'être ouvert, c'est la capture définitive.
- [x] Les paris : un petit gain, et pas de pari sur un ami Roblox (le chiffre reste à régler).
- [ ] Le nom du jeu.
