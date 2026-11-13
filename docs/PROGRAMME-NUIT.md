# Programme de la nuit du 12 au 13 novembre 2026

Fixé avec Josh avant la nuit. L'assistant travaille seul, puis fait un
rapport le matin (en bas de ce fichier et en message).

## Ce que Josh a décidé

- **Le périmètre** : d'abord tout le jeu, puis, s'il reste du temps, le
  salon d'attente et la progression (XP, crédits, sauvegarde). Pas de
  boutique, pas de tirages, pas de prix.
- **Les commits** : un commit et un push après chaque bloc fini, avec les
  tests au vert.
- **Les sons** : oui, les principaux. Ceux de Survivor d'abord. Choisis sur
  le nom et la durée (l'assistant ne peut pas écouter) ; Josh juge demain.
- **Le goulag impair** : le joueur seul affronte un bot armé d'une batte.

## Ajouté par Josh avant de dormir

- **Tout faire**, boutique et passe de saison compris, avec des choix de
  l'assistant et des prix provisoires bien marqués ; on revoit tout dans le
  rapport.
- **Le salon** : invitations et « rejoindre » classiques de Roblox. Choix
  de l'assistant (Josh lui a laissé) : dans le jeu publié, le salon envoie
  le groupe sur un serveur de partie réservé (`ReserveServer`) ; dans
  Studio, où ça ne marche pas, la partie se lance au même endroit. Le
  groupe se forme dans le salon, à la manette.

## L'ordre

1. Les Repris : Errant, Rampant, Hurleur, Coureur ; ils sont recrachés à
   chaque fermeture ; plafond et garde-fous ; la méfiance qui envoie des
   Repris.
2. Le goulag : duels sur plateformes, mort subite, cages, une seule sortie,
   fermé aux deux derniers cercles.
3. Les escouades : solo, duo ou 4 ; coéquipiers visibles ; relever ; donner
   un objet ; cocon en 3 coups ; victoire d'équipe.
4. Les gestes manquants : s'allonger et ramper, tirer par les pieds, la
   porte dans la figure, les signaux, la carte, l'émote.
5. Les éliminés : regarder un coéquipier, parier (gratuit, sans gain tant
   que les crédits n'existent pas), quitter.
6. La liste des joueurs du jeu, qui cache les bots.
7. Les animations des postures.
8. Les sons.
9. Le salon d'attente et les groupes, puis la progression (XP, niveaux,
   crédits, fragments, sauvegarde).
10. La boutique tournante, les tirages (règles Roblox), le passe de
    saison, avec des prix provisoires.

11. Jusqu'à 9 h, s'il reste du temps : tester le jeu de fond en comble
    (parties entières, se balader, chercher les bugs), corriger, noter.

Chaque bloc : code, tests, essai seul dans Studio, `A-TESTER.md`,
`DECISIONS.md`, commit et push.

## Rapport du matin

### En une phrase

Tout le programme est fait, commité et poussé, plus des bonus. Six parties
complètes jouées par les bots (solo, duo, quatre escouades) n'ont montré
aucune erreur du jeu. Le jeu à la manette, à plusieurs et une fois publié
reste à vérifier par toi.

### Ce qui a été fait cette nuit (dans l'ordre)

1. **Les Repris** : Errant (il crie, un faisceau vient), Rampant (il
   t'arrache de ta cachette), Hurleur (l'Œil entend, les autres
   accourent), Coureur (il grogne puis plaque). Ils tombent à chaque
   fermeture de l'Œil, avec un plafond, et ne tuent jamais.
2. **Le goulag, « le Ventre de l'Œil »** : une salle sombre, des cages, des
   duels sur des plateformes dans le vide, à la batte. La plateforme
   s'effrite, puis vient la mort subite. Une seule chance par partie,
   fermé aux deux derniers cercles. Nombre impair : un « Repris du
   Ventre » à la batte.
3. **Les escouades** : solo, duo, escouade de 4. Coéquipiers en bleu à
   travers les murs, liste de l'équipe en bas à gauche, relever un ami
   K.O., lui donner un objet. Revenu du Ventre, on est dans un cocon qu'un
   coéquipier ouvre en 3 coups avant que l'Œil ne le trouve. La victoire
   va à l'équipe entière.
4. **Les gestes** : s'allonger et ramper (B maintenu), tirer par les pieds
   (X maintenu), signaux « Danger / Ici » à la croix, la carte (croix
   gauche, avec les zones), une émote (croix droite).
5. **Les éliminés** : regarder d'abord ses coéquipiers, parier sur un
   joueur (jamais sur un ami Roblox), quitter.
6. **La liste des joueurs** (R3) : les bots y passent pour des joueurs.
7. **Les animations** : accroupi, ramper, K.O. et porté, générées puis
   regardées une à une. Les corps K.O. ne passent plus sous le sol.
8. **Les sons** de Survivor : l'Œil, l'ambiance, le cœur au Ventre, les
   coups, la fouille, les Repris.
9. **Le salon** : une place en ruine flottante. On y forme son groupe (X
   maintenu sur quelqu'un), on choisit le mode (Y), on se dit prêt (R2).
   Les invitations Roblox marchent. Dans le jeu publié, le départ envoie
   les joueurs sur un serveur de partie ; dans Studio, la partie se joue
   sur place.
10. **La progression** : XP, niveaux, crédits, fragments, sauvegarde. Si
    la lecture d'un profil échoue, rien n'est jamais écrit.
11. **La boutique** (croix gauche au salon) : la boutique du jour et les
    permanents, les tirages (toutes les chances affichées avant, égales),
    le passe de saison gratuit et premium. Les cosmétiques changent la
    comète, la traînée, le cocon, l'émote et le titre. **Tous les prix sont
    provisoires.**

**Bonus** (manques de la fiche) :
- les défis quotidiens et hebdomadaires (onglet Défis) ;
- le classement des victoires (panneau du salon) ;
- se cacher à plusieurs dans les grandes cachettes (buisson à 2, abri à
  3…) ;
- les cachettes à mécanique : le buisson ne couvre qu'à moitié, la voiture
  a deux portières, le conteneur se ferme de l'intérieur mais fait un
  vacarme ;
- le petit tutoriel (les cachettes en vitrine et un panneau « Comment
  jouer ») ;
- l'effet d'aspiration (lueur colorée, aussi en cosmétique) et la pose de
  victoire ;
- les zones sur la carte.

### Les bugs trouvés en testant, et corrigés

- La caméra du spectateur traversait les murs (écran noir).
- Un Rampant arrachait le même bot 4 fois de suite.
- Les bots n'ouvraient jamais le cocon d'un coéquipier, donc un joueur avec
  des bots dans son équipe n'aurait jamais été délivré.
- La victoire n'annonçait que le survivant, pas toute l'équipe.
- Au K.O., le corps passait sous le sol.
- Plusieurs textes débordaient d'une petite fenêtre : le haut de l'écran,
  la boutique, l'annonce des pouvoirs, la carte.
- Y ne changeait pas le mode au salon (le bouton « pousser » l'avalait).
- « Restants : 0 » s'affichait au salon.
- La vérification automatique de GitHub est restée rouge sur 7 poussées de
  la nuit : de simples avertissements d'analyse que je ne voyais pas. Tout
  est corrigé et elle est verte.

### Ce que je n'ai PAS pu vérifier

- **La manette** : les boutons ont été envoyés comme des touches ; il faut
  ta vraie manette.
- **À plusieurs** : inviter, accepter, jouer ensemble. Je suis seul dans
  Studio.
- **L'envoi vers les serveurs de partie** (impossible dans Studio) : c'est
  le premier test à faire après avoir publié.
- **La sauvegarde** : Studio la refuse sans l'accès aux API. Le jeu se
  protège (profil illisible = rien d'écrit), mais la vraie sauvegarde n'a
  jamais tourné.
- **Les achats en Robux** : les produits n'existent pas encore.
- **Les sons** : je ne peux pas écouter.
- **La fluidité réelle** : dans Studio, le serveur tourne à environ 41
  images par seconde, avec le client sur la même machine.

### Ce que je te demande (toi seul peux le faire)

1. **Activer l'accès aux API dans Studio** : Paramètres du jeu → Sécurité →
   « Activer l'accès de Studio aux services d'API ». C'est un réglage de
   sécurité, je n'y ai pas touché. Ensuite, je pourrai tester la
   sauvegarde et le classement.
2. **Regarder les textures de la carte** : depuis que Studio a été rouvert
   cette nuit, 16 avertissements « pas la permission » apparaissent, autant
   que les textures des matières générées (asphalte, béton, brique, bois).
   Vérifie que tu es connecté au bon compte.
3. **Créer les produits Robux** (3 paquets de crédits et le passe premium
   de la saison 1) et me donner leurs numéros. Fixe aussi les vrais prix.
4. **Publier, puis jouer à deux ou plus**, manette en main, en suivant
   `docs/A-TESTER.md`.

### Par où commencer en jouant (le plus utile d'abord)

1. Le salon : les panneaux, Y, R2, puis la croix gauche (la boutique).
2. Une partie en escouade avec tes amis : les repères bleus, relever,
   donner, les signaux.
3. Se faire aspirer : le Ventre, un duel, puis revenir dans un cocon.
4. Les Repris : les voir tomber, un Coureur qui grogne avant de plaquer.
5. B maintenu (ramper), la carte (croix gauche), la liste (R3).
6. Tes impressions : trop dur, trop facile, trop long ? Les parties de bots
   durent 15 à 18 minutes et finissent souvent au Regard 4.

Les choix pris sans toi sont tous dans `docs/DECISIONS.md` (sections « nuit
du 12 » et « 13 novembre »). Les points à regarder, bloc par bloc, sont
dans `docs/A-TESTER.md`.
