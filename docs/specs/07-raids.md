# 07 · Raids pirates

## Objet

Donner une menace au solo : des flottes pirates attaquent régulièrement la planète.

## Règles

- **Planification** : un raid est toujours en attente (créé à la première ouverture, après un
  reset ou un import). La chaîne garde **le même id** d'un raid à l'autre.
- **Intervalle** entre deux arrivées : tiré dans `pirates.interval_hours` (à ×1).
- **Détection** `pirates.warning_minutes` avant l'arrivée : la composition est fixée à ce
  moment, selon les **points** du joueur. Pas de protection débutant.
- **Points** = ressources dépensées ÷ 1000 (niveaux de bâtiments et de technos, unités
  possédées ; ordres en cours exclus).
- **Composition** : budget = `max(min_budget, points × 1000 × force)`, force tirée dans
  `pirates.strength`. Une part `cargo_share` va aux transporteurs (le plus gros débloqué),
  le reste aux vaisseaux de combat débloqués (`warships`, seuils en points), répartis avec
  des poids aléatoires. Plancher : 3 chasseurs légers.
- **Arrivée** : combat (spec 06) contre les unités de la planète et les technos du joueur.
  Pirates sans technos.
- **Pillage** (si les pirates gagnent) : jusqu'à `loot_share` de chaque stock, réduit
  proportionnellement à la soute des survivants. Aucune part protégée.
- Les défenses perdues sont retirées (après reconstruction des 70 %).
- Un **rapport** est enregistré pour chaque raid.

## Données

Section `pirates` du YAML.

## Code

`lib/domain/raid.dart` (`points`, `pirateFleet`, `loot`, `detectRaid`, `resolveRaid`,
`ensureRaidScheduled`, `raidNow`), `lib/ui/widgets/raid_banner.dart`,
`lib/ui/screens/reports_screen.dart`.

## UI

- **Bandeau d'alerte** (raid détecté) : « Flotte pirate en approche · arrivée dans … ». Au tap :
  composition, soute, forces en présence, « Simuler 100 batailles ».
- **Rapports** : icône dans la barre du haut, pastille du nombre de non lus ; liste des raids
  (verdict, date, pillage) ; tap → rapport complet.
- Raid résolu app ouverte : message avec accès au rapport.
- Debug : « Raid pirate maintenant » (détection immédiate) et affichage des points.

## Tests

`raid_test.dart` : points, plancher, montée en force, pillage, détection, arrivée avec ou
sans défense, raid suivant, vitesse, rattrapage de 3 jours, simulation multiple.

## Points ouverts

- Équilibrage (intervalle, force, plancher) à valider en jouant.
- Technos pirates (aujourd'hui nulles).
