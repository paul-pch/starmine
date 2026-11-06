# 07 · Raids pirates

## Objet

Donner une menace au solo : des flottes pirates attaquent régulièrement la planète.

## Règles

Objectif : les raids progressent avec le joueur, mais un joueur qui se défend bien ne doit
pas les craindre ; il peut prendre de l'avance.

- **Planification** : un raid est toujours en attente (créé à la première ouverture, après un
  reset ou un import). La chaîne garde **le même id** d'un raid à l'autre.
- **Intervalle** entre deux arrivées : tiré dans `pirates.interval_hours` (à ×1), soit 2 à 3
  raids par semaine.
- **Relevé et retard** : à la planification (arrivée du raid précédent, ou création), le
  raid enregistre un **relevé** du joueur : points d'économie et de recherche, niveaux de
  technos. La flotte est calculée sur ce relevé, pas sur le joueur au moment de l'attaque :
  les pirates ont un intervalle de retard, un joueur qui progresse vite les dépasse.
  Sauvegarde antérieure sans relevé : relevé pris à la détection.
- **Détection** `pirates.warning_minutes` avant l'arrivée : la composition et les technos
  sont fixées à ce moment. Pas de protection débutant.
- **Points** = ressources dépensées ÷ 1000 (niveaux de bâtiments et de technos, unités
  possédées ; ordres en cours exclus). **Points d'économie et de recherche** = les mêmes
  **sans les unités** : c'est la base des raids, investir en défense ne renforce pas les
  pirates.
- **Composition** : budget = `max(min_budget, points × 1000 × force)` (points du relevé),
  force tirée dans `pirates.strength`. Une part `cargo_share` va aux transporteurs (le plus
  gros débloqué), le reste aux vaisseaux de combat débloqués (`warships`, seuils en points),
  répartis avec des poids aléatoires. Plancher : 3 chasseurs légers.
- **Technos pirates** : Armes, Bouclier et Protection = niveaux du relevé moins
  `pirates.tech_offset` (plancher 0). Les raids gagnent en qualité, un cran sous le joueur.
- **Arrivée** : combat (spec 06) contre les unités de la planète ; chaque camp a ses technos.
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
  composition, soute, technos pirates, forces en présence, « Simuler 100 batailles ».
- **Rapports** : icône dans la barre du haut, pastille du nombre de non lus ; liste des raids
  (verdict, date, pillage) ; tap → rapport complet.
- Raid résolu app ouverte : message avec accès au rapport ; le dernier remplace le précédent.
- Debug : « Raid pirate maintenant » (détection immédiate, relevé conservé), points et base
  des raids.

## Tests

`raid_test.dart` : points et base des raids, technos pirates, détection sur le relevé,
défenses sans effet sur le raid suivant, plancher, montée en force, pillage, arrivée avec
ou sans défense, raid suivant, vitesse, rattrapage de 3 semaines, simulation multiple.

## Points ouverts

- Plancher (`min_budget`) et plage de force à revoir après la refonte, en jouant à ×1.
