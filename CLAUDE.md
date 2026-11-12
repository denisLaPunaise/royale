# Royale — notes pour l'assistant

Nom de code du dépôt : **Royale**. Titre du jeu : **à choisir avec Josh**.
Battle royale Roblox (solo et escouades, 24 joueurs au plus) où l'ennemi
principal est l'Œil géant du ciel : il balaie la ville, aspire qui il voit, et
devient plus fort de Regard en Regard. Le dernier joueur ou la dernière
escouade pas capturé gagne.

**Le concept complet est dans [docs/CONCEPT.md](docs/CONCEPT.md)**, chaque
point marqué *validé*, *proposé* ou *à voir*. Un point *validé* ne change
qu'avec Josh. Une décision prise sans lui se note dans
[docs/DECISIONS.md](docs/DECISIONS.md).

Les notes communes à tous les jeux de Josh sont dans
`C:\Users\boill\.claude\CLAUDE.md` (copie dans
`..\Survivor\docs\NOTES-COMMUNES.md`).

## D'où vient le jeu

C'est un jeu à part de **Survivor** (`..\Survivor`, dépôt
`denisLaPunaise/survivor`), qui garde la même base. Le code utile s'y
**recopie** (pas de dépendance entre dépôts) : le trajet des Balayages
(`Sweep`), la jauge (`Exposure`), les courbes de montée (`Growth`), les
cachettes marquées (`Hiding`), le fumigène (`Smoke`), l'Œil et sa ligne de vue
(`EyeService`, `SkyView`), `Throttle` et `RemoteGuard`. Même squelette : Rojo,
Rokit, StyLua, Selene, Lune, GitHub Actions, tous les chiffres dans
`Config.luau`.

## Les principes à ne jamais casser

1. **Bien caché, on est en sécurité dans la zone.** L'Œil ne triche jamais :
   être vu, c'est une vraie ligne de vue, mesurée au rayon. Seule exception,
   voulue : hors de la zone, la jauge monte même caché.
2. **La manette décide.** Une action qui ne rentre pas dans `Config.controls`
   se sacrifie. Un test refuse toute collision.
3. **Aucun achat ne donne de puissance.** Boutique cosmétique seulement.
4. **Aucun objet n'annule l'Œil**, et rien ne s'additionne pour rendre un
   joueur intouchable.
5. **Une récompense se demande** : qui peut provoquer cette issue exprès, et
   avec combien de comptes ? (Paris, XP, crédits.)

## Où on en est

- **9 novembre 2026** : fiche commencée avec Josh dans un autre chat.
- **12 novembre 2026** : dossier et dépôt créés, fiche rangée dans
  `docs/CONCEPT.md`, contradictions du goulag et des paris tranchées. **On
  finit la fiche avant d'écrire du code** (choix de Josh).
