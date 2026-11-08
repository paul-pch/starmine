# 02 · Économie

## Objet

Produire, stocker et consommer les ressources ; c'est la boucle de base du jeu.

## Règles

- **Ressources stockées** : métal, cristal, deutérium (`double`, affichées tronquées).
  L'énergie n'est pas stockée : c'est un bilan instantané.
- **Production horaire** (vitesse comprise) :
  `base + mines × facteur d'énergie × (1 + bonus Plasma + Géologue) − consommations`
  (Géologue : spec 12).
- **Coup de pouce de départ** (`start_boost`) : production de base et des mines (pas les
  consommations) × `1 + extra × max(0, 1 − points / fade_points)`, points d'économie et de
  recherche (spec 07). ×3 au départ, disparaît à 500 points (mesuré : début rapide, baisse
  de production limitée ; cible figée dans `test/balance/balance_targets_test.dart`). Les objectifs de départ récompensés viendront
  avec la narration.
  - Mine de niveau N : `coefficient × N × 1.1^N`, multiplié par le réglage de production.
  - Deutérium : × `(1.44 − 0.004 × Tmax)` ; une planète froide produit plus.
  - La **production de base** ne dépend ni de l'énergie ni du réglage.
  - Les **consommations** (deutérium de la fusion) ne dépendent pas de l'énergie.
- **Énergie** : produite par la centrale solaire (`20 × N × 1.1^N`) et la fusion
  (`30 × N × (1.05 + 0.01 × Énergie)^N`) ; consommée par les mines.
  Facteur = `min(1, produite / consommée)`, appliqué à toutes les mines.
- **Réglage de production** : 0 à 100 % par pas de 10, sur les bâtiments qui produisent des
  ressources ou de l'énergie ; il multiplie production **et** consommation du bâtiment. Le
  passé est soldé à l'ancien réglage.
- **Stockage** : capacité d'un hangar de niveau N = `5000 × floor(2.5 × e^(20N/33))`.
  La production s'arrête au plafond ; un stock au-dessus (remboursement d'une annulation) est
  conservé sans production. Une production nette négative fait baisser le stock jusqu'à 0,
  jamais en dessous.
- **Départ** : ressources de `start.resources`, bâtiments au niveau 0, Tmax tirée dans
  `start.temp_max`, Tmin = Tmax − `start.temp_spread` (affichage seulement).

## Données

`formulas.*`, `start.*`, et pour chaque bâtiment : `production`, `consumption`, `energy`,
`stores`.

## Code

`lib/domain/rules.dart` (`hourlyProduction`, `energy`, `capacity`, `produce`),
`lib/domain/resources.dart`, `lib/domain/planet.dart`.

## UI

Barre de ressources (spec 10) : stock interpolé, capacité, production horaire, bilan
d'énergie, « Mines à X % » quand l'énergie manque.

## Tests

`test/domain/rules_test.dart` : coûts, production, énergie négative, fusion, réglage,
stockage, plancher à 0.
