# 12 · Officiers

> Version V2c. Le nom du fichier reste `12-succes-officiers.md` pour ne pas casser les liens.

## Objet

Récompenser la progression : des **officiers**, personnages gagnés en jouant, donnent des
**bonus permanents** qui compensent le ralentissement naturel du jeu (la courbe des durées
de construction et de recherche).

## Règles

- **Gagnés, jamais achetés ni loués** : pas de monnaie, pas de durée (spec 00).
- **Prérequis par niveau** : niveaux de bâtiments et de technos (arbre d'avancement) et/ou
  **compteurs** de progression, selon l'officier (`officers.<id>.levels[].requires`).
- **Déblocage explicite** : quand les prérequis du niveau suivant sont remplis, l'officier
  est *disponible* ; le joueur appuie sur **« Débloquer »** (niveau 1) ou **« Promouvoir »**.
  Rien ne se débloque sans lui. Commande **gratuite**, horodatée : le bonus s'applique à
  partir de cet instant (le passé est soldé à l'ancien niveau).
- **Niveaux plafonnés** : bonus = `per_level × niveau`, plafond = nombre de niveaux.
- **Tous les officiers débloqués sont actifs.** Un nombre limité de places actives reste une
  **option d'équilibrage** (noté dans `GameState.modifiers` et dans le YAML).
- **Compteurs** tenus par `advance()` (exacts app fermée) : `raids_repelled` (raid dont le
  défenseur sort vainqueur).
- **Bonus** = `Modifiers` appliqués par les formules existantes, jamais un timer :

| Officier | Prérequis | Bonus |
| --- | --- | --- |
| Géologue | Niveaux des mines | Production des mines (ajouté au bonus des technos) |
| Technocrate | Labo et technos | Durée de recherche réduite |
| Architecte | Usine de robots, puis de nanites | Durée de construction des bâtiments réduite |
| Ingénieur | Chantier, Protection, raids repoussés | Part des défenses reconstruites (70 % de base) |

- Pas de notification quand un officier devient disponible : la pastille du hero suffit.
- Commandant (file d'attente, spec 13) et Amiral (flotte, V3) : plus tard.
- Les officiers influenceront certains événements (spec 14, V2d).

## Données

Section `officers` du YAML : par officier `name`, `description` (infobulle), `bonus`
(`type` : `mine_production`, `research_time`, `build_time`, `defense_rebuild` ;
`per_level`), `levels` (liste de `requires`, clés = bâtiments, technos ou compteurs).
Section `counters` : libellé de chaque compteur. Seuils à équilibrer en jouant.

## UI

- Icône **Officiers** dans le bandeau du hero, pastille = nombre d'officiers disponibles.
- Écran **Officiers** : carte par officier (portrait en repli icône, nom, « Niveau n / max »,
  bonus actuel, bonus du niveau suivant, prérequis « Élément requis (actuel) » en rouge s'ils
  manquent), bouton « Débloquer » / « Promouvoir » actif seulement si disponible, sans
  message (la carte se met à jour) ; marge du bas pour la barre de navigation Android ; `InfoButton` par officier (description) et sur l'écran (règles).
- Portraits : catégorie `character` du registre d'images (spec 11), à produire.

## Persistance

Tables `officers` et `counters` (schéma v5), sauvegarde JSON v5 (spec 08).

## Code

`lib/domain/officers.dart` (disponibilité, prérequis manquants, `promoteOfficer`),
`GameState.officers` / `counters` / `modifiers` (`engine.dart`), `Modifiers` (`rules.dart`),
`lib/ui/screens/officers_screen.dart`.

## Tests

`officers_test.dart` : config, verrouillé, disponible mais jamais débloqué seul, Géologue
(production à partir du déblocage), Technocrate et Architecte (durées), Ingénieur
(compteur en prérequis, reconstruction), plafond, compteur de raids repoussés. Persistance :
`migration_test.dart`, `save_codec_test.dart`. Écran : `home_shell_test.dart`.

## Points ouverts

- Seuils et bonus à équilibrer en jouant (skill `starmine-balance`).
- Place définitive de l'entrée Officiers une fois la refonte en main (skill `starmine-ui`).
