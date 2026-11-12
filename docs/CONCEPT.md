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

**Validé (12 novembre) : tout le jeu à la première personne**, comme Survivor : c'est plus fort pour les cachettes (Josh).

**Proposé.** Pas d'armes à feu : le vrai tueur, c'est l'Œil. Les joueurs se nuisent surtout en le faisant travailler pour eux.

## Une partie

| Point | Statut | Ce qu'on a dit |
| --- | --- | --- |
| Durée | Validé | 15 à 25 min par partie, en 5 phases |
| Victoire | Validé | Le dernier joueur ou la dernière escouade pas capturé gagne |
| Modes | Validé | Solo, duo et escouade de 4, dès le lancement (12 novembre) |
| Taille d'escouade | Validé | Duo (12 équipes) et escouade de 4 (6 équipes) à 24 joueurs |
| Nombre de joueurs | Validé | 24 joueurs au plus pour commencer ; on montera plus tard si les serveurs se remplissent |
| Découpage | Validé | 5 phases, les « Regards », au lieu des jours de Survivor ; chaque Regard annonce un nouveau cercle |

**Validé (9 novembre) : le serveur n'attend pas d'être plein.** Le jeu s'adapte au nombre de joueurs présents : taille de la zone jouable, nombre de cachettes, quantité de butin, force de l'Œil.

**Validé (12 novembre) : tout suit le nombre de joueurs.** Le nombre de cachettes et d'objets se calcule à chaque partie à partir du nombre de joueurs, et le premier cercle aussi (voir La carte).

**Validé (12 novembre) : une attente courte, et des bots.** Josh : une longue recherche fait quitter le jeu (l'ancienne idée « on lance même à 5 » est remplacée par ce qui suit).

- On attend des joueurs **30 s au plus** (moins si le serveur se remplit à 24), puis **des bots complètent la partie jusqu'à un total tiré entre 17 et 24 joueurs**, pour qu'elle paraisse toujours bien remplie. **Un seul vrai joueur suffit** (validé le 12 novembre) : même seul, on joue tout de suite. Josh : au lancement du jeu, il y aura peu de joueurs ; les bots permettent de jouer tout de suite.
- **Les bots sont invisibles** : on doit croire que ce sont de vrais joueurs. Ils savent jouer à peu près (fouiller, courir se cacher quand l'Œil s'ouvre, fuir un faisceau, se battre un peu).
- **Leurs noms sont inventés**, jamais ceux de vrais comptes Roblox.
- **Validé (12 novembre) : une partie avec des bots rapporte comme une autre** (XP, crédits, classement). Josh : sinon, les premiers joueurs ne pourraient jamais progresser ; et plus le jeu aura de joueurs, moins il y aura de bots. Conséquence : un bot ne doit pas être plus facile à battre qu'un joueur moyen, sinon les parties avec bots deviendraient la façon la plus rapide de gagner.
- **La liste des joueurs de Roblox ne montre que les vrais joueurs** : pour que les bots passent inaperçus, le jeu affiche sa propre liste de joueurs, avec tout le monde.
- **À mesurer** : 20 bots ou plus en même temps doivent tourner sans ralentir le serveur.
- Ils servent aussi à tester une partie à 24 seul dans Studio.

**Validé (12 novembre) : une équipe incomplète** (par exemple 2 amis en escouade de 4) est complétée par de vrais joueurs seuls qui cherchent une équipe ; s'il n'y en a pas assez avant la fin de l'attente, par des bots coéquipiers, invisibles eux aussi. Une case « Ne pas compléter » permet de jouer à moins.

## L'Œil et sa montée en puissance

**Un mot d'abord.** Un **Regard** est une **phase** de la partie : un palier de force de l'Œil, pas un seul coup d'œil. Pendant chaque Regard, l'Œil **s'ouvre et se ferme plusieurs fois** (ses rafales) ; d'un Regard à l'autre, il devient plus fort.

**Validé.** L'Œil devient plus fort au fil de la partie : il arrache plus de choses, il reste de moins en moins de cachettes.

**Validé (12 novembre) : les Regards et les cercles vont ensemble.** Chaque nouveau Regard annonce le prochain cercle : une seule horloge à suivre. « Regard 3 », c'est un Œil plus fort **et** un nouveau cercle.

**Retenu, à préciser (9 novembre) : l'Œil chasse en permanence**, pour que le début ne soit pas mou. Ordre de ses cibles :

1. **Un joueur visible** (dehors, sans toit) : un faisceau fonce sur lui. Le faisceau se déplace, il ne se téléporte pas : on voit la lumière venir.
2. **Il se cache ou sort de sa vue** : l'Œil garde sa piste un moment, puis passe au joueur visible le plus proche.
3. **Tout le monde est caché** : il prend la zone où il y a le plus de joueurs et fait le ménage, toits et cachettes autour d'eux, puis leurs cachettes. Éjecté, on a 2 s de répit pour courir.

Bien caché, on n'est jamais aspiré directement, mais une cachette n'est jamais sûre longtemps.

**Retenu : il regarde par rafales**, ouvert puis fermé quelques secondes (son temps de recharge). Sans ces respirations, on ne pourrait plus fouiller. Au dernier Regard, il ne se ferme plus.

**Validé (12 novembre) comme valeurs de départ : la montée Regard par Regard.** Josh l'a laissée à l'assistant ; tout ira dans le fichier de réglages et se règle après les premières parties. Repères : marche 14, course 22 (en studs par seconde).

|  | Regard 1 | Regard 2 | Regard 3 | Regard 4 | Regard 5 |
| --- | --- | --- | --- | --- | --- |
| Ce qu'on annonce | « Il s'éveille » | « Il voit plus loin » | « Il entend la course » | « Il entend les coups » | « Il ne ferme plus les yeux » |
| Durée | 5 min | 4 min 30 | 4 min | 3 min 30 | Jusqu'à la fin (environ 3 min) |
| Faisceaux (au moins 1) | 1 pour 8 joueurs en vie | 1 pour 7 | 1 pour 6 | 1 pour 5 | 1 pour 4 |
| Ouvert par rafale | 30 s | 35 s | 40 s | 45 s | Ne se ferme plus |
| Fermé entre deux rafales | 20 s | 15 s | 12 s | 8 s | — |
| Vitesse de poursuite | 12 (moins que la marche) | 15 | 18 | 20 | 22 (la course) |
| Mémoire de la piste | 1 s | 1,5 s | 2 s | 3 s | 3,5 s |
| Erreur de visée | 60 studs (« dans ton coin ») | 40 | 25 | 15 | 5 (pile sur toi) |
| Arrachages par rafale autour des cachés | 3 | 4 | 6 | 8 | 12 |
| Rayon du faisceau | 14 studs (un trottoir) | 16 | 18 | 20 | 22 (une rue) |
| Plein regard avant l'aspiration | 2 s | 2 s | 1,8 s | 1,8 s | 1,6 s |
| L'ouïe | Non | Non | La course | Course et coups | Tout bruit |
| Annonce du prochain cercle | 90 s | 80 s | 65 s | 55 s | 45 s |
| Jauge hors zone pleine en | 20 s | 15 s | 11 s | 8 s | 5 s |

**Choisi par l'assistant (12 novembre) : 5 Regards**, chacun avec **un changement qu'on annonce à l'écran** (la ligne « Ce qu'on annonce ») : tout monte un peu à chaque Regard, mais une chose se remarque à coup sûr. Voir `DECISIONS.md`.

**Validé (12 novembre) : la fin se fait par l'Œil, pas par la zone.** Au Regard 5, le dernier cercle reste fixe : l'Œil ne se ferme plus, arrache les cachettes une à une et les cachettes solides s'effondrent, jusqu'à ce qu'il ne reste qu'un joueur ou une équipe. Pas de cercle qui se referme jusqu'à rien (Josh). Si les derniers sont aspirés en même temps, celui qui l'est en dernier gagne.

**À surveiller avec les bots** : un recoin sans rien au-dessus (un fossé, derrière un muret) ne s'arrache pas, et au Regard 5 le faisceau va aussi vite que la course ; deux bons joueurs pourraient faire durer la finale. On mesurera la durée réelle des finales ; si elles traînent, on en reparle.

**Validé (12 novembre) : un power-up au hasard à chaque Regard**, en plus de sa montée naturelle. Il est tiré dans un tableau de power-ups et annoncé à l'écran. Josh : ni trop léger, ni trop fort, des power-ups « classiques ». Chaque partie a donc son Œil.

**Proposé : les règles du tirage.**

- jamais deux fois le même power-up dans une partie ;
- jamais un power-up qui ne change rien (au Regard 5, « Il entend tout » ne sert à rien : on ne le tire pas) ;
- chacun dure jusqu'à la fin de la partie : au Regard 5, l'Œil en a cinq.

**Validé (12 novembre) comme liste de départ : le tableau des power-ups** (14). **À équilibrer avant de coder** (Josh) : aucun ne doit être trop faible ni trop fort ; un power-up trop faible peut être fusionné avec un autre. L'Œil doit vraiment devenir fort.

| Power-up | Ce qu'il fait |
| --- | --- |
| Il entend tout | L'ouïe du Regard 5 dès maintenant |
| La rage | Une rafale sur deux, un faisceau de plus |
| Le faux départ | De temps en temps, il se ferme puis se rouvre aussitôt |
| Le regard long | Une rafale par Regard dure deux fois plus longtemps |
| La faim | Il arrache moitié plus |
| L'œil lent mais sûr | Poursuite un peu plus lente, mais il garde la piste 2 s de plus |
| Le flair | Il arrache d'abord les cachettes occupées depuis longtemps |
| Le regard rasant | Son faisceau arrive plus en biais : les recoins couvrent moins |
| La rancune | Les cachettes marquées le restent jusqu'à la fin de la partie |
| L'éclair | Chaque rafale s'ouvre par un éclair : les joueurs à découvert brillent 2 s pour tout le monde |
| La paupière lourde | Ses pauses entre deux rafales raccourcissent d'un tiers |
| Le retour | Quand il perd ta piste, il revient voir ta dernière position 5 s plus tard |
| Le souffle | Chaque rafale commence par un coup de vent qui pousse les joueurs à découvert |
| Les empreintes | Qui court laisse des traces rouges au sol pendant 10 s, que l'Œil suit |

**Validé (12 novembre) : dans une petite partie**, le nombre de faisceaux suit les joueurs en vie ; la vitesse, la précision et le reste de l'Œil ne changent pas. Tout se règle en jouant.
## Contre le camping : la méfiance de l'Œil et les Repris

**Validé (12 novembre) : deux menaces qui se complètent.** Rester à découvert, c'est l'Œil ; rester caché trop longtemps au même endroit, ce sont les Repris. Josh : sans ça, un joueur bien placé au début n'aurait qu'à camper.

**La méfiance de l'Œil.**

- Une jauge cachée monte chez chaque joueur qui reste caché (cachette ou recoin) dans un rayon d'environ 15 studs ; bouger de plus de 25 studs la fait redescendre.
- Pleine, le joueur est **flairé** : à la prochaine ouverture, l'Œil commence par lui et arrache sa cachette, ou ce qui couvre son recoin ; s'il n'y a rien à arracher, il y envoie des Repris.
- **Elle se remplit en 90 s au Regard 1**, puis 75, 60, 45, et **30 s au Regard 5**.
- **Le joueur est prévenu** vers 70 % : un murmure (« Il te sent… ») et un battement rouge discret au bord de l'écran.

**Les Repris, les yeux de l'Œil au sol.** Ceux qu'il a aspirés, qu'il recrache (repris de Survivor : corps, crânes, animations).

| Repris | Arrive | Ce qu'il fait | La parade |
| --- | --- | --- | --- |
| Errant | Regard 1 | Erre lentement ; s'il te voit, il crie et le faisceau vient vers toi | Rester hors de sa vue, le frapper (3 coups) |
| Rampant | Regard 1 | Sent les joueurs cachés à 14 studs et les arrache de leur cachette | Changer de cachette, le tuer avant |
| Hurleur | Regard 3 | Quand il te voit, il hurle : l'Œil vient vers le bruit, les Repris proches accourent | Le faire taire vite, ou fuir loin |
| Coureur | Regard 3 | Rapide et fragile, il te plaque : K.O. 2 s | L'esquiver d'une glissade ; 2 coups suffisent |

- **Ils ne tuent jamais** : ils signalent, délogent ou mettent K.O. 2 à 3 s. C'est toujours l'Œil qui aspire, par une vraie ligne de vue (le principe « l'Œil ne triche pas » tient).
- **À chaque fermeture de l'Œil, il en recrache**, de plus en plus au fil des Regards (environ 1 pour 8 joueurs en vie au Regard 1, jusqu'à 1 pour 3 au Regard 5), en priorité près des joueurs flairés et des cachettes solides occupées. Ils tombent dans une traînée visible de tous.
- **Un plafond** : au plus 1 Repris en vie pour 2 joueurs en vie. Au début de chaque Regard, l'Œil en ré-aspire la moitié (on les voit remonter).
- **Se battre fait du bruit** (l'Œil entend les coups à partir du Regard 4). Un Repris tué lâche un objet commun.
- **Les parades** : le fumigène les aveugle aussi ; accroupi, on se fait moins remarquer ; une cachette fermée cache des Errants et des Hurleurs, pas du Rampant.

**À équilibrer en jouant, avec ces garde-fous dès le départ** (Josh : « il faut que ça reste jouable », pas trop forts ET trop nombreux à la fois) :

- **des Repris faibles** : l'Errant et le Rampant vont moins vite que la marche, le Coureur tombe en 2 coups ;
- **jamais plus de 2 Repris sur le même joueur** à la fois ;
- **ils préviennent** : un grognement avant d'attaquer, et un délai entre deux cris du même Repris ;
- **le plafond** (1 pour 2 joueurs en vie) et le ré-aspirage de la moitié à chaque Regard ;
- tous les chiffres dans le fichier de réglages, et des parties de bots pour mesurer combien de joueurs ils mettent réellement K.O.

## La carte

**Validé (12 novembre) : une grande carte fixe, à thèmes.** Josh : une vraie carte de battle royale, avec des zones bien à thème, belles, **jamais un copier-coller** d'un autre jeu (des inspirations, oui). La disposition des zones ne change pas d'une partie à l'autre : on apprend la carte.

**Validé : ce qui change à chaque partie**, tout ce qui se change facilement :

- les cachettes, posées parmi des centaines d'emplacements possibles (comme Survivor) ;
- les coffres et le butin, les lieux d'événement ;
- les maisons déjà en ruine, les rues bloquées, les caves ouvertes, les épaves, les arbres tombés.

**Validé (9 novembre) : une carte assez serrée pour que les joueurs se croisent tout le temps.** Avec les bots, une partie compte presque toujours 17 à 24 joueurs : la carte est pensée pour environ 20.

**Validé (12 novembre) : 9 zones** (Josh a laissé les thèmes à l'assistant, puis gardé les 9) :

| Zone | L'ambiance | Sa cachette propre |
| --- | --- | --- |
| Le Cratère (au centre) | Sous la Fissure : ruines de toutes les zones, débris qui montent lentement vers l'Œil | Aucun abri d'en haut, mais le meilleur butin |
| La Banlieue | Maisons, jardins, haies, recoins (reprise de Survivor) | La voiture, l'armoire |
| Le Quartier suspendu | Des morceaux de rues que l'Œil a soulevés et laissés flotter au-dessus de la Banlieue, reliés par des poutres | On s'agrippe, on saute, on tombe |
| La Fête foraine | Grande roue penchée, montagnes russes tordues, stands | Le train fantôme, un tunnel solide |
| Le Port échoué | Un cargo couché sur le quai, des conteneurs, des grues, la mer | Le conteneur, bruyant à ouvrir |
| La Gare de triage | Wagons renversés, passerelles au-dessus des voies | Le wagon, deux portes |
| Le Marais | Forêt noyée dans la brume, cabanes sur pilotis | Les roseaux, on y bouge librement |
| Le Lycée | Couloirs, gymnase, toit plat, cour | Les casiers, à une place |
| L'Hypermarché éventré | Le toit à moitié aspiré : rayons à ciel ouvert, grands parkings | La chambre froide, solide |

**Choisi par l'assistant (12 novembre) : la taille et le plan.** Environ **1600 × 1600 studs** (un peu plus d'une minute de course d'un bord à l'autre ; chaque zone fait 350 à 600 studs selon son thème). Les zones ne sont pas rangées en damier : elles s'imbriquent (la Gare traverse tout le sud, le Quartier suspendu flotte au-dessus de la Banlieue), et la carte a des bords naturels (la mer à l'ouest). Plan de départ :

- **ouest** : la mer, le Port échoué ;
- **nord** : le Lycée, la Fête foraine ;
- **centre** : le Cratère, juste sous l'Œil ;
- **est** : la Banlieue, et le Quartier suspendu au-dessus ;
- **sud-est** : l'Hypermarché éventré ; **sud-ouest** : le Marais ;
- **sud** : la Gare de triage, en bande d'ouest en est.

Comme dans Survivor, l'Œil est au-dessus du centre : plus on s'en éloigne, plus son regard arrive en biais et plus les murs couvrent. Le bord est plus sûr face à l'Œil, mais les cercles ramènent vers le milieu. À vérifier en jouant.

**Validé (12 novembre) : la carte complète dès la sortie, et construite d'abord.** Josh veut sortir un jeu fini, et que l'assistant puisse tester le jeu entier avec les bots. Les 9 zones se construisent avant les mécaniques. Le risque, dit à Josh : on saura plus tard si se cacher contre les autres est amusant.

**Validé (12 novembre) : le départ, recraché par l'Œil.** Josh veut que ce soit **beau**, comme une attaque : l'Œil recrache les joueurs, ils filent en ligne droite et viennent s'écraser au sol, puis la partie commence. On choisit à peu près où tomber.

**Proposé, comment ça se passe :**

1. **On vise** (environ 8 s) : depuis la pupille, on voit la carte d'en haut et le premier cercle ; on choisit son point de chute au stick. Les escouades visent ensemble.
2. **Le crachat** : l'Œil s'ouvre en grand et crache tout le monde d'un coup. Chaque joueur part comme une comète brûlante, en ligne droite vers son point, avec une traînée de feu sombre ; on voit les autres filer dans le ciel.
3. **L'impact** : on s'écrase dans un nuage de poussière, l'écran tremble, une petite trace brûlée reste au sol quelques secondes. On se relève aussitôt.
4. **Pas de faisceau pendant la chute** : la première rafale arrive environ 20 s après le premier impact.

Faisable dans Roblox (traînées, particules, caméra, secousses) ; **la beauté se jugera à l'écran**, par Josh.

**Validé (9 novembre) : une zone ronde.** Elle rassemble bien les joueurs. Elle ne se resserre pas petit à petit : le prochain cercle est annoncé, et **à la fin de l'annonce, tout ce qui est dehors devient rouge d'un coup**.

**Validé (12 novembre) :**

- un nouveau cercle est annoncé **au début de chaque Regard** ;
- l'annonce dure **90 s au premier cercle, puis de moins en moins, jusqu'à 45 s au dernier** (90, 80, 65, 55, 45).

**Proposé, les détails :**

- le prochain cercle est toujours entièrement dans le cercle actuel, et se voit dès l'annonce (au sol, sur la carte) ;
- le centre est tiré au hasard à chaque partie ;
- **validé (12 novembre)** : le premier cercle dépend du nombre de joueurs, et il est **vraiment petit** dans une petite partie, pour qu'on se croise dès le début.
- **Validé (12 novembre) : la taille de chaque cercle se calcule au moment de l'annoncer**, d'après le nombre de joueurs encore en vie (bots compris), pour garder le bon espace par joueur. Jamais plus grand que le cercle d'avant. Repère pour environ 20 joueurs au départ (estimé, à vérifier avec les bots) :

| | Joueurs en vie (estimé) | Largeur du cercle |
| --- | --- | --- |
| Regard 1 | 20 | 1300 studs (presque toute la carte) |
| Regard 2 | 14 | 900 |
| Regard 3 | 10 | 600 |
| Regard 4 | 6 | 380 |
| Regard 5 | 3 ou 4 | 220 (environ 10 s de course) |

**Validé : hors de la zone, l'Œil est impitoyable.** **Validé (12 novembre) : pas de faisceaux dehors.** Les faisceaux ne chassent que dans la zone. Dehors, tout est sous un regard rouge diffus, le même pour tout le monde :

- la jauge monte en continu, même caché : il faut rentrer. Elle aspire de plus en plus vite : pleine en 20 s au premier cercle, 5 s au dernier ;
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

**Validé : libre de ses mouvements selon la cachette, et des cachettes sans interaction.** **Validé (12 novembre) : trois sortes.** Les volumes et les recoins sont les refuges rapides : poursuivi par l'Œil, on y arrive vite, on s'y jette en glissade, on s'y accroupit ou on s'y allonge, sans bouton à presser.

- **Les volumes**, où l'on bouge librement : buisson, sous une bâche, tas de gravats, grand conteneur, cave. Comme dans Fortnite, de l'intérieur la cachette devient translucide pour soi. On peut y être à plusieurs, et tomber sur quelqu'un.
- **Les abris fermés**, où l'on entre avec X : voiture, armoire, frigo, poubelle. On voit dehors depuis l'intérieur. Ouvrir un abri occupé met face à celui qui y est.

- **Les recoins**, sans aucun bouton : on s'y jette, on s'accroupit ou on s'allonge, et c'est la vraie ligne de vue qui décide si l'Œil te voit. Exemples : glisser sous une voiture ou un camion, s'allonger dans un fossé, sous une table de jardin, derrière un muret bas, sous un escalier, sous un porche, sous un pont. Leur faiblesse : vu de biais, l'Œil peut te voir ; l'objet au-dessus peut être arraché ; on se relève lentement. S'y abriter pendant un Balayage marque le recoin, comme une cachette.

**Validé (12 novembre) : les postures, à la manette.** B en courant : glissade (elle passe sous les objets bas et finit allongé s'il n'y a pas la place de se relever). B à l'arrêt : s'accroupir. Maintenir B : s'allonger, et ramper.

**Validé (12 novembre) comme liste de départ : les cachettes à mécanique** (chacune avec sa faiblesse ; on en ajoutera en jouant) :

| Cachette | Sa force | Sa faiblesse |
| --- | --- | --- |
| Voiture | Deux portières, on peut fuir par l'autre côté | Ouverte d'un côté, on te voit |
| Buisson | On y bouge, on peut être plusieurs | Il couvre à moitié : un faisceau qui reste dessus finit par voir |
| Plaque d'égout | Ressort plus loin : traverser une rue sans être vu | Étroit : on y croise les autres, et on ne voit pas ce qui attend à la sortie |
| Armoire, frigo | Protègent même quand le toit est arraché | Dans une maison, là où l'Œil arrache le plus |
| Conteneur | Se ferme de l'intérieur | Fait un vacarme à l'ouverture |
| Château d'eau, toit plat | On voit tout | Piégé si un faisceau arrive |
| Cave | Solide, plusieurs places | Une seule sortie : un cadenas ou un piège à loup et on est coincé |

**Validé (12 novembre) : le nombre.** Au début, un peu plus de places que de joueurs ; en finale, moins de places que de joueurs, pour qu'il faille se battre pour une place (on peut déloger quelqu'un de sa cachette). Josh : **le jeu doit rester dur**, à régler en jouant. Une simulation vérifiera qu'aucune cachette n'est trop forte.

**Validé (12 novembre) : depuis un abri fermé, on voit par l'ouverture.** Le pare-brise de la voiture, la fente de l'armoire, le couvercle entrouvert de la poubelle : on peut tourner la tête, mais la vue est cadrée et un peu sombre. Chaque abri a donc sa force : la voiture voit loin, l'armoire presque rien.

**Proposé : risque contre gain.**

- Le meilleur butin est là où c'est dangereux : sous un toit qui va partir, à découvert, dans une zone qui va être condamnée.
- **Les Reliques** : après certains Balayages, l'Œil lâche un objet rare au milieu d'une place, annoncé à tous. Tout le monde le veut, et il faut traverser à découvert.
- Fouiller fait du bruit et prend du temps : on hésite quand le ciel rougit.
- Un sac limité : on choisit ce qu'on garde.

Les objets et leurs raretés : voir la section Les objets.

## Interactions entre joueurs

**Validé.** Il faut beaucoup d'interactions entre joueurs, par le butin comme au corps à corps.

**Validé (12 novembre) : les interactions gardées.** Toutes tiennent sur les boutons du tableau ci-dessous.

**Au corps à corps**

- **Le coup** (R2) : trois coups mettent K.O. 2 à 3 secondes (deux avec une batte), avec un temps de recharge. Un joueur K.O. à découvert pendant que l'Œil regarde est en grand danger.
- **La poussée** (Y à l'arrêt) : faire sortir quelqu'un de sa cachette, ou le pousser dans le faisceau.
- **Le plaquage** (Y en courant) : on tombe tous les deux, mais l'autre plus longtemps.
- **Le tacle glissé** (B en courant, vers quelqu'un) : ta glissade le fauche, il tombe 1,5 s et tu continues de glisser.
- **Voler** (X maintenu sur un joueur K.O.) : lui prendre un objet.
- **Porter et jeter** (Y maintenu sur un joueur K.O.) : tu le soulèves au-dessus de ta tête et tu marches lentement ; Y le jette à quelques mètres (dans un faisceau, d'un toit, hors d'une cachette) ; B le pose doucement (un coéquipier à l'abri). Remplace l'idée de traîner un K.O.
- **Tirer par les pieds** (X maintenu sur quelqu'un allongé dans un recoin) : il est réveillé, tu le sors à découvert en une seconde.
- **Toquer à un abri** (R2 sur une voiture, une armoire…) : le bruit attire l'Œil vers l'abri. Tu dénonces peut-être quelqu'un… ou personne.
- **Les portes dans la figure** : ouvrir brusquement une porte (maison, abri) fait tomber celui qui est juste derrière. Caché dans un abri, R2 au moment où quelqu'un ouvre : la porte l'envoie au sol et tu files.

**Se déplacer**

- **S'agripper aux rebords** (A en l'air, près d'un rebord) : on s'agrippe et on se hisse sur un mur, un toit plat, un conteneur. Un toit est un poste pour voir venir, mais à découvert.

**Avec des objets** : voir la section Les objets, juste en dessous.

**Entre coéquipiers**

- **Validé (12 novembre) : on voit toujours ses coéquipiers** : un petit repère et leur nom au-dessus d'eux, à travers les murs, et leur vie en bas à gauche.
- **Validé (12 novembre) : les coups entre coéquipiers marchent** (frapper, pousser, plaquer, tacler, porter et jeter). Les objets, eux, ne touchent jamais un coéquipier. **À surveiller** : avec des inconnus pour compléter l'équipe, certains vont trahir (pousser un coéquipier dans le faisceau) ; à revoir si ça gâche les parties.
- relever un ami K.O. (X maintenu), lui donner l'objet qu'on tient (X maintenu sur un ami debout), se cacher à plusieurs dans une grande cachette ;
- détacher un coéquipier recraché dans un cocon (3 coups de R2, voir Capturé) ;
- des signaux rapides à la croix directionnelle.

## Les boutons de la manette

**Validé (12 novembre) comme point de départ**, à tenir en main puis régler. Une même touche peut changer de sens selon la situation, jamais deux actions sur la même touche au même moment ; un test le vérifiera, comme dans Survivor. Start et Select appartiennent à Roblox.

**À pied** (et dans un volume ou un recoin)

| Bouton | Action |
| --- | --- |
| A | Sauter ; en l'air près d'un rebord : s'agripper et se hisser |
| B | En courant : glisser (et tacler) ; à l'arrêt : s'accroupir ; maintenu : s'allonger, ramper |
| X | Fouiller, ouvrir, entrer dans un abri |
| X maintenu | Ami à terre : le relever ; ennemi K.O. : le voler ; ami debout : lui donner son objet ; quelqu'un allongé : le tirer par les pieds |
| R2 | Frapper ; sur un abri : toquer ; sur un cocon : l'ouvrir (3 coups) |
| Y | À l'arrêt : pousser ; en courant : plaquer ; maintenu sur un K.O. : le porter |
| L2 | Utiliser l'objet choisi ; maintenu : viser, lâcher pour lancer |
| L1 / R1 | Choisir parmi ses 4 objets (affichés en bas de l'écran) |
| L3 | Courir (on appuie une fois) |
| Croix ← | La carte : la zone et le prochain cercle |
| Croix ↑ / ↓ | Signaux « Danger ! » et « Ici ! » |
| Croix → | Émote |
| R3 | Libre, gardé en réserve |

**En portant quelqu'un** : Y le jette, B le pose.

**Dans un abri fermé** : X sortir ; R2 sortir en frappant celui qui ouvre (la porte dans la figure) ; L1 / R1 choisir un objet ; croix ↑ / ↓ signaux.

**Au goulag** : R2 frapper avec la batte, A sauter, B s'accroupir.

**Éliminé** : L1 / R1 changer de joueur regardé, X parier, B quitter.

## Les objets

**Validé (9 novembre) : beaucoup d'objets, en cinq raretés, jusqu'à épique et légendaire.** Revus ensemble le 12 novembre.

**Validé (12 novembre) : les règles.**

- Presque tout se consomme : un objet sert une fois ou pendant un temps limité. Rien ne s'additionne pour rendre un joueur intouchable, et rien n'est permanent.
- Aucun objet n'annule l'Œil : il aide à lui échapper un moment, jamais pour de bon.
- **Un objet ne touche jamais ses coéquipiers** (miroir, piège, craie, fusée…).
- Sac limité : 4 places pour les objets, on choisit ce qu'on garde. **Pas de panneau de sac** ; les 4 objets sont affichés en bas de l'écran. Ramasser avec un sac plein **échange** le nouvel objet avec celui qu'on tient, qui tombe par terre.
- Chances à chaque fouille, à régler : commun 56 %, peu commun 25 %, rare 13 %, épique 6 %. **Les légendaires ne se fouillent jamais.**
- Les épiques sont plutôt aux endroits dangereux (sous un toit qui va partir, près du bord de la zone).
- **Les légendaires tombent seulement des Reliques**, que l'Œil lâche au milieu d'une place, annoncées à tous. Un ou deux par partie au plus.
- Celui qui porte un légendaire brille un peu : tout le monde veut le lui prendre.
- Couleurs habituelles : gris, vert, bleu, violet, or.

**À voir : l'équilibrage.** Josh : rien ne doit être trop fort. Avant de coder, chaque objet reçoit sa réponse (ce qui le contre) et une simulation vérifie qu'aucune combinaison de 4 objets ne rend un joueur presque intouchable.

**Validé (12 novembre) : le catalogue de départ** (27 objets ; à équilibrer en jouant).

| Rareté | Objet | Ce qu'il fait |
| --- | --- | --- |
| Commun | Fumigène | Un nuage qui coupe la ligne de vue 15 s ; l'Œil perd ta piste |
| Commun | Pétard | Un bruit énorme là où il tombe : attire l'Œil (toujours, même avant qu'il entende la course) et les joueurs |
| Commun | Fusée éclairante | Lancée sur un joueur ou au sol, elle attire un faisceau |
| Commun | Craie | Marque la cachette d'un autre : l'Œil vient l'arracher |
| Commun | Bouteille | Lancée, elle étourdit 1 s à distance |
| Commun | Flaque d'huile | Lancée au sol : qui court dessus glisse et tombe 1,5 s |
| Commun | Lampe torche | Braquée sur un joueur proche, elle l'éblouit : son écran blanchit 2 s |
| Commun | Clochette | Accrochée à une cachette, elle sonne quand quelqu'un y entre : tout le monde l'entend |
| Peu commun | Batte | K.O. en deux coups au lieu de trois |
| Peu commun | Piège à loup | Posé devant une cachette, il bloque 3 s celui qui en sort |
| Peu commun | Jumelles | Voir de loin les joueurs à découvert, signalés 5 s |
| Peu commun | Planches | Barricader une porte ou une cave 20 s |
| Peu commun | Carton piégé | Une fausse cachette : qui y entre est éjecté et marqué |
| Peu commun | Boule puante | Lancée sur une cachette : celui qui est dedans doit sortir en toussant |
| Peu commun | Filet | Lancé, il immobilise un joueur 2 s |
| Rare | Cape d'ombre | Ta jauge monte moitié moins vite pendant 20 s |
| Rare | Cadenas | Ferme une cave de l'intérieur pendant 45 s : personne d'autre n'entre |
| Rare | Miroir | Renvoie le faisceau qui te poursuit vers le joueur ennemi le plus proche |
| Rare | Grappin | Monter sur un toit trop haut pour s'agripper, passer d'un toit à l'autre |
| Rare | Adrénaline | Tu cours plus vite pendant 8 s (jamais plus vite que l'Œil au dernier Regard) |
| Épique | Bâche de plomb | Immobile dessous, le faisceau ne te voit pas pendant 10 s |
| Épique | Mannequin | L'Œil le prend pour un joueur et le poursuit 10 s |
| Épique | Œil de verre | 15 s : tu vois à travers les murs les joueurs proches |
| Épique | Fusée rouge | Attire tous les faisceaux sur un point pendant 5 s |
| Légendaire | Le Regard volé | Pendant 10 s, tu diriges toi-même un faisceau |
| Légendaire | La Larme de l'Œil | Il cligne : tous les faisceaux s'éteignent 5 s, partout |
| Légendaire | Le Cocon de secours | Aspiré, tu es recraché aussitôt sur place, sans goulag (une fois). **Ne marche plus en finale**, quand le goulag est fermé |
| Légendaire | Le Fragment de Fissure | 15 s invisible pour l'Œil, mais tu brilles pour les joueurs |

**Retirés (12 novembre)** : la Radio (« montre où vont les faisceaux ») : l'Œil chasse les joueurs qu'il voit, on ne peut pas prédire ses faisceaux, donc elle n'avait pas de sens ; le Parapluie noir (idée non retenue).

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

**Validé (12 novembre) : une seule monnaie, les crédits.** On les gagne en jouant (parties, défis, paris justes) ou on les achète en Robux. Tout cosmétique de la boutique s'achète en crédits : tout peut se gagner sans payer, payer va juste plus vite.

**Validé (12 novembre) : une boutique tournante et permanente.** Une partie change chaque jour ; un coin permanent garde les classiques. Ce qui tourne revient plus tard.

**Validé (12 novembre) : des saisons et des défis.**

- Des saisons d'environ 8 semaines, chacune avec un thème (et par exemple un nouveau power-up de l'Œil ou une zone retouchée).
- Des défis quotidiens et hebdomadaires qui font avancer le passe.
- **Le passe de saison** : une piste gratuite pour tous, une piste payante en Robux, **à racheter chaque saison** (il ne se rembourse pas, choix de Josh). La piste payante apporte, sans jamais aider en partie :
  - des cosmétiques ;
  - de l'XP de compte en plus (on monte plus vite de niveau) ;
  - des personnalisations exclusives : sa comète d'arrivée, son cocon, son effet quand on est aspiré, sa pose de victoire.
- **Les parties privées à règles**, vendues à part : jouer entre amis avec ses propres règles (Œil plus fort, tous les power-ups…), hors classement et sans récompense.

**Validé (12 novembre) : des tirages de cosmétiques**, de deux façons :

- **Gratuits, avec des fragments** gagnés en finissant bien une partie : un tirage = 20 fragments ; top 1 = 2 fragments, top 2 à 5 = 1 fragment. Le plus rapide est donc **10 victoires pour un tirage**. En équipe, chaque membre de l'équipe gagnante reçoit sa part. Les fragments ne s'achètent jamais.
- **Payés en crédits.** Comme les crédits s'achètent, c'est un tirage payant au sens de Roblox, donc :
  - avant l'achat, on affiche tout ce qui peut tomber, avec sa chance (total 100 %), par un lien qui porte un mot ;
  - **tous les cosmétiques du tirage ont la même chance** (Josh) ;
  - chaque tirage donne quelque chose ; un doublon rend des crédits ;
  - le tirage en crédits est coupé là où Roblox interdit les tirages payants (`ArePaidRandomItemsRestricted`) ; celui des fragments reste.
- **La liste des tirages est une sélection à part**, dont le prix se règle sur la valeur moyenne de ce qu'elle contient : sinon un tirage reviendrait moins cher que d'acheter les cosmétiques les plus chers.

**Règle : un pari d'éliminé est toujours gratuit.** Miser des crédits (achetables) en ferait un jeu d'argent.

**À surveiller** : les fragments récompensent la victoire ; en solo, deux amis qui s'entraident en cachette gagneraient plus vite. À voir si ça arrive.

## Le lancement (plus tard)

**Validé (12 novembre) : tout ce qui pousse le jeu se fait au moment de le lancer**, et s'étudiera alors à fond pour l'optimiser : le nom, la stratégie de lancement, les miniatures et l'icône, la page du jeu, le marketing, les pubs payées ou non. Pas maintenant.

## Mise en place

**Validé.** Un dépôt séparé, qui reprend une copie des morceaux utiles de Survivor : le trajet des Balayages, la jauge, les courbes de montée, les cachettes marquées, le fumigène, l'Œil et sa ligne de vue. Même façon de travailler : Rojo, tests, CI, tous les chiffres dans un seul fichier de réglages.

**Proposé, l'ordre de construction** (revu le 12 novembre : la carte d'abord, choix de Josh) :

1. **La carte complète** : les 9 zones, belles, avec leurs emplacements de cachettes et de butin, en recette comme la ville de Survivor.
2. **Le cœur du jeu** : l'Œil et ses 5 Regards, les cercles, le départ recraché, les trois sortes de cachettes, la capture, l'écran de victoire, en solo.
3. **Les bots**, pour tester des parties à 20 seul.
4. Les interactions (coup, poussée, plaquage, tacle, porter…) et les objets.
5. Les escouades, le goulag, le cocon.
6. Le salon d'attente, la recherche de partie, la progression et la boutique cosmétique.

## Questions ouvertes

- [x] Le nombre de joueurs : 24 au plus, la partie se lance même incomplète.
- [x] Ce que fait un éliminé définitif : regarder, parier, ou quitter.
- [x] L'attente : 30 s au plus, puis des bots invisibles complètent jusqu'à 17 à 24 joueurs, et rapportent comme les autres.
- [x] Comment le jeu s'adapte au nombre de joueurs : cachettes, objets et premier cercle suivent les joueurs ; les faisceaux suivent les joueurs en vie.
- [x] L'Œil : 5 Regards liés aux cercles, et la montée Regard par Regard (valeurs de départ).
- [x] L'Œil : un power-up au hasard à chaque Regard.
- [x] L'Œil : 14 power-ups pour commencer ; la fin se fait par l'Œil, sans cercle qui se referme.
- [x] L'équilibrage des power-ups de l'Œil : valeurs de départ fixées par l'assistant (`DECISIONS.md`), à régler en jouant.
- [x] La zone : annonce de 90 s à 45 s, pas de faisceaux dehors, jauge dehors de 20 s à 5 s.
- [x] La zone : la taille de chaque cercle se calcule d'après les joueurs encore en vie.
- [x] Le départ : recraché par l'Œil, on vise, on file comme une comète et on s'écrase.
- [x] Les escouades : solo, duo et escouade de 4 ; équipe complétée par des inconnus puis des bots ; coéquipiers toujours visibles ; coups entre coéquipiers permis.
- [x] Le minimum de vrais joueurs : un seul suffit.
- [x] La carte : fixe, 9 zones à thème, environ 1600 × 1600, cachettes et butin qui changent à chaque partie.
- [x] Les interactions et le tableau des boutons de la manette (point de départ).
- [x] Les cachettes : trois sortes, le nombre, les postures, les sept cachettes à mécanique pour commencer.
- [x] Ce qu'on voit depuis un abri fermé : par l'ouverture, cadré.
- [x] Les objets : règles et catalogue de 27 objets.
- [ ] L'équilibrage des objets (rien de trop fort), avant de coder.
- [x] Le goulag : il ferme aux deux derniers cercles ; un duel nul se finit en mort subite ; un cocon atteint par le faisceau avant d'être ouvert, c'est la capture définitive.
- [x] Les paris : un petit gain, et pas de pari sur un ami Roblox (le chiffre reste à régler).
- [x] La progression et la boutique : une monnaie (crédits), boutique tournante, saisons et passe, tirages par fragments ou crédits.
- [ ] Les prix (passe, crédits, tirages) et les récompenses par partie, en chiffres.
- [x] Contre le camping : la méfiance de l'Œil et les Repris recrachés.
- [ ] Le nom du jeu, la stratégie de lancement, les miniatures, le marketing : au moment de lancer (voir Le lancement).
