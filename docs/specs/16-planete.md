# 16 · Planète : identité, traits, renommage

> Décidé et implémenté le 2026-11-27.

## Objet

Donner un caractère à la planète : un nom choisi, une courte description selon son climat,
et deux **traits** permanents (un atout, un défaut) qui orientent la partie.

## Règles

- **Tranche de température** d'après Tmax : froide (Tmax < 0), tempérée (0 à 39), chaude
  (≥ 40). Mêmes tranches que les images (spec 11).
- **Description** : un court texte par tranche (`planet.descriptions`).
- **Traits** : un par effet (`planet.traits`) ; chaque trait a un nom d'atout et un nom de
  défaut. Une planète reçoit **un atout et un défaut d'effets différents**, tirés à sa
  création avec la graine de la partie :
  - atout tiré selon `boon_weight[tranche]`, défaut parmi les autres effets selon
    `flaw_weight[tranche]` (poids 1 par défaut) : une planète chaude tire plus souvent un
    atout d'énergie et un défaut de deutérium, une froide l'inverse ;
  - effet = ± `planet.trait_value` (atout +, défaut −) sur : production de métal, de
    cristal ou de deutérium (ajouté au bonus des mines de la ressource), énergie produite
    (× 1 ± valeur), durée de construction ou de recherche (réduction ± valeur), part de
    défenses reconstruites (± valeur).
  - Permanents, cumulés avec les officiers et les événements.
- **Sauvegarde antérieure** (sans traits) : traits tirés une fois au premier chargement,
  avec une graine dérivée de celle de la partie, puis enregistrés.
- **Renommage** : 1 à 24 caractères, espaces de bord retirés.
- **Signaler un problème** : icône du hero qui ouvre la création d'une issue sur le dépôt
  GitHub (navigateur), version de l'app pré-remplie dans le texte.

## Données

Section `planet` du YAML : `descriptions` (`cold`, `temperate`, `hot`), `trait_value`,
`traits.<effet>` (`boon`, `flaw`, `boon_weight`, `flaw_weight`). Effets : `metal`,
`crystal`, `deuterium`, `energy`, `build`, `research`, `rebuild`.

## UI

- Hero : le nom et les températures ouvrent la **feuille de la planète** au tap ; icône
  « Signaler un problème » à côté de Debug, Officiers et Rapports.
- Feuille de la planète : nom (bouton crayon → dialogue de renommage), températures, tranche,
  description, atout (nom, effet en vert) et défaut (nom, effet en rouge), effet de la
  température sur le synthétiseur de deutérium ; infobulle sur les traits.

## Code

`lib/domain/game_data.dart` (`TemperatureBand`, `PlanetConfig`, `TraitEffect`),
`lib/domain/planet.dart` (`drawTraits`, `Planet.boon` / `flaw`), `GameState.modifiers`,
`GameController.rename`, `lib/ui/widgets/planet_sheet.dart`, `lib/ui/widgets/planet_hero.dart`.

## Persistance

Colonnes `planets.boon` et `planets.flaw` (schéma v11), clés `boon` / `flaw` de la planète
dans la sauvegarde JSON (v12 ; absentes avant : tirage au chargement).

## Tests

Tirage déterministe, atout et défaut distincts, pondération par tranche, effets dans les
modificateurs (production, énergie, durées, reconstruction), tirage d'une ancienne
sauvegarde, renommage persisté, migration v10 → v11, feuille de la planète.
