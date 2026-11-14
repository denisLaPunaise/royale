# Rapport du matin — 14 novembre 2026

Une nuit de parties de bots en boucle pour finir l'équilibrage de Royale.
Tout est vérifié **seul dans Studio, avec des bots**, jamais avec de vrais
joueurs ni à la manette.

## En bref

- **24 parties complètes** cette nuit, plus une trentaine hier : solo, duo,
  escouade, avec des bots maladroits, normaux et prudents.
- **Aucune erreur du jeu.** Deux soucis trouvés et corrigés, un troisième
  rattrapé par un filet de sécurité.
- **L'équilibrage tient.** On arrive en finale bien plus souvent, en solo
  comme en escouade.
- **Rien n'est commité de la nuit** : tu ne m'as pas autorisé à pousser
  pendant la nuit, je te le demande.

## Ce que donnent les parties maintenant

En vie au début de chaque Regard (la fiche visait 20 → 14 → 10 → 6 → 3) :

| Partie | Exemple | Durée |
| --- | --- | --- |
| Solo, bots normaux | 24 → 23 → 21 → 13 → 7 | 18 min, finale d'environ 1 min |
| Solo, bots prudents | 17 → 16 → 13 → 7 → 2 | 17 min |
| Solo, bots maladroits | 21 → 20 → 16 → 9 → 2 | 19 min |
| Escouade | 20 → 17 → 13 → 11 | 16 min, finie au Regard 4 (une seule équipe) |

Personne n'est balayé au début, quel que soit le niveau : le Ventre redonne
une chance jusqu'au Regard 3.

## Ce que j'ai changé cette nuit

1. **Le Regard 4 encore adouci.** Il prenait 80 % des joueurs en solo, et
   deux fois tout le monde en moins de 3 minutes. Maintenant c'est environ
   la moitié, comme prévu.
2. **Le pouvoir « La rancune »** garde ses marques deux fois plus longtemps,
   au lieu de jusqu'à la fin. Avec « Le flair » et « La paupière lourde »,
   il rendait toute cachette inutile au Regard 4.
3. **Les sauvegardes ne se marchent plus dessus.** Deux sauvegardes du même
   profil à quelques secondes d'écart dépassaient la limite de Roblox. Avec
   beaucoup de joueurs, Roblox aurait pu en jeter.

## Ce qui reste un peu ouvert

- **Une chute hors du monde inexpliquée**, une fois en 24 parties : un bot
  passé d'un coup de la route au vide. Le filet l'a rattrapé et la partie a
  continué. L'avertissement dira maintenant ce qu'il faisait, pour trouver
  la cause la prochaine fois.
- **Le Regard 4 garde de la variance** : de temps en temps, une partie solo
  s'y termine encore. Ça dépend des pouvoirs tirés.
- **Les objets** : les bots n'utilisent que les objets qui protègent. Les
  autres ne sont réglés que par le calcul (les tests vérifient qu'aucun
  objet ne protège trop).

## À décider avec toi

1. **La durée d'une saison.** Le passe (30 paliers) se finit en environ
   **9 jours** à 3 parties par jour avec les défis. Pour une saison de
   6 semaines, il faudrait environ 3 fois plus d'XP par palier. Je n'ai rien
   changé.
2. **Les produits Robux** (déjà noté comme la prochaine tâche).
3. **Si une finale traîne avec de vrais joueurs** (quelqu'un derrière un
   mur que rien ne déloge), on choisira une solution ensemble.

## L'économie, en chiffres (calculée sur la courbe mesurée)

- Une partie : environ 106 XP et 28 crédits en solo, 128 XP et 34 crédits
  en escouade.
- Niveau 11 : environ 37 parties. Niveau 21 : environ 120.
- À 3 parties par jour avec les défis : une apparence commune en 1 jour,
  rare en 3, épique en 6, légendaire en 12. Un tirage en 4 jours.

## Quoi regarder en jouant

La fin de `docs/A-TESTER.md` (deux parties : « L'équilibrage » et « La nuit
d'équilibrage »). Le pourquoi de chaque réglage est dans `docs/DECISIONS.md`.
