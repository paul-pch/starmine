# 06 · Combat

## Objet

Résoudre une bataille entre une flotte attaquante et les unités d'une planète, selon les
règles OGame classiques, et en rendre les chiffres lisibles.

## Règles

- Jusqu'à **6 rounds**, tant que les deux camps ont des unités.
- Tirs **simultanés** : chaque unité tire sur une unité ennemie au hasard ; une unité détruite
  pendant le round tire quand même.
- **Tir rapide** n contre la cible : chance `(n − 1) / n` de tirer à nouveau.
- **Règle du 1 %** : un tir inférieur à 1 % du bouclier de la cible est absorbé sans effet.
- Le **bouclier** absorbe avant la coque et se **régénère** à chaque round.
- Sous **70 % de coque**, une unité explose avec la probabilité `1 − coque / coque initiale`.
- Issue : attaquant victorieux si le défenseur n'a plus d'unité, défenseur victorieux dans le
  cas inverse, match nul sinon.
- Après la bataille, **70 %** des défenses détruites sont **reconstruites** (tirage par unité),
  plus le bonus de l'Ingénieur (spec 12).
- Technos (Armes, Bouclier, Protection) : +10 % par niveau.
- Déterministe pour une graine donnée.

## Chiffres exposés

- **Forces en présence** (`SideStrength`) : unités, attaque totale par round (hors tir
  rapide), boucliers, coque — technos comprises.
- **Volée** par camp et par round (`Volley`) : tirs, puissance tirée, part encaissée par les
  boucliers adverses, part infligée aux coques, part perdue.
- **Simulation multiple** (`simulateRaid`, 100 batailles) : % raid repoussé / nul / planète
  pillée, rounds moyens, pertes moyennes par camp (en unités et en ressources), pillage moyen,
  avec accès à une « bataille type ».

## Code

`lib/domain/combat.dart` (`simulateCombat`, `SideStrength`, `Volley`),
`lib/domain/raid.dart` (`simulateRaid`, `SimulationSummary`).

## UI

Rapport de combat (feuille) : verdict, butin, forces en présence, unités avant → après
(reconstruites), détail des rounds repliable. Feuille de simulation : bilan + bataille type.
Accès : alerte de raid, rapports, Debug → Simulateur.

## Tests

`combat_test.dart` : écrasement, règle du 1 %, tir rapide (~10 tirs d'un croiseur sur des
lanceurs), reconstruction ~70 %, technos, volées cohérentes, forces.

## Points ouverts

- Champ de débris : `debris.share` du métal et du cristal des **vaisseaux** détruits des deux
  camps (défenses exclues), ajouté au champ de la planète et au rapport (spec 15).
