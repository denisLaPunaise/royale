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
