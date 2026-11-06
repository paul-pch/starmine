# 03 · Bâtiments

## Objet

Faire progresser la planète niveau par niveau.

## Règles

- Coût du niveau N : `floor(coût de base × facteur^(N−1))`, débité **au lancement**.
- Durée : `(M + C) / (2500 × (1 + robots) × 2^nanites × vitesse)` heures, arrondie à la
  seconde inférieure, au moins 1 s.
- **File de construction** : 1 slot. Annulation avec remboursement intégral (le stock peut
  alors dépasser la capacité).
- **Prérequis** : niveaux minimums de bâtiments ou de technos (`requires`). Ordre des raisons
  de refus : file occupée → labo/chantier occupé → prérequis → ressources.
- **Règle du labo** : pas d'agrandissement du labo pendant une recherche, ni de recherche
  pendant son agrandissement.
- **Règle du chantier** : pas d'agrandissement du chantier pendant un lot, ni de lot pendant
  son agrandissement.

## Catégories (puces de filtre)

| Catégorie | Bâtiments |
| --- | --- |
| Production | Mine de métal, Mine de cristal, Synthétiseur de deutérium |
| Énergie | Centrale solaire, Centrale à fusion |
| Stockage | Hangars de métal et de cristal, Réservoir de deutérium |
| Infrastructure | Usine de robots, Usine de nanites, Chantier spatial, Laboratoire |

Effets : robots et nanites accélèrent les constructions, le labo les recherches, le
chantier la production d'unités (spec 05).

## Données

`buildings.<clé>` : `name`, `description` (infobulle), `category`, `cost`, `factor`,
`requires`, effets (spec 02). `categories.buildings` : libellés et ordre des puces.

## Code

`lib/domain/game_data.dart` (`BuildingKind`, `BuildingSpec`), `lib/domain/engine.dart`
(`checkOrder`, `startOrder`, `cancelOrder`, `slotStatus`).

## UI

Onglet Bâtiments : carte par bâtiment (spec 10). État de la file sur l'onglet : pastille
verte si libre.

## Tests

`engine_test.dart` : lancement, file, annulation, nanites, prérequis, état des files.
