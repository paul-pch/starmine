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
  possédées ; ordres en cours exclus). Changement décidé pour la V2c : voir plus bas.
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
- Raid résolu app ouverte : message avec accès au rapport ; le dernier remplace le précédent.
- Debug : « Raid pirate maintenant » (détection immédiate) et affichage des points.

## Tests

`raid_test.dart` : points, plancher, montée en force, pillage, détection, arrivée avec ou
sans défense, raid suivant, vitesse, rattrapage de 3 jours, simulation multiple.

## Évolution V2c (à implémenter)

Objectif **décidé** : les raids progressent avec le joueur, mais un joueur qui se défend bien
ne doit pas les craindre ; il doit pouvoir prendre de l'avance.

Décidé :
- **Force sur l'économie et les technos** : le budget pirate se calcule sur les points de
  bâtiments et de technos, **sans les unités** (défenses, puis vaisseaux en V3). Investir en
  défense n'augmente plus les raids suivants. Les points affichés (Debug) restent les points
  totaux ; la base du raid est affichée à côté.
- **Retard** : la base est celle d'il y a `pirates.lag_hours` (à ×1). Technique proposée :
  un historique des points (un relevé à chaque arrivée de raid suffit, avec la date), la
  base étant le relevé le plus récent antérieur à `now − lag`. Un joueur qui progresse vite
  dépasse les pirates.
- **Fréquence** : 2 à 3 raids par semaine à ×1 (`pirates.interval_hours`, ~48 à 96 h).
- **Technos pirates** : Armes, Bouclier et Protection des pirates = niveaux du joueur à la
  date de retard, moins `pirates.tech_offset` (≥ 1, plancher 0). Les raids gagnent en
  qualité, pas seulement en nombre, et restent un cran en dessous du joueur qui recherche.
  Affichées dans la feuille de la flotte pirate et le rapport.

## Points ouverts

- Plancher (`min_budget`) et plage de force à revoir après la refonte, en jouant à ×1.
