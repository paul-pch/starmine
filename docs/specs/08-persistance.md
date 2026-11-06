# 08 · Persistance et sauvegarde

## Objet

Ne jamais perdre une partie : base locale versionnée et sauvegarde exportable.

## Base SQLite (Drift)

| Table | Contenu | Depuis |
| --- | --- | --- |
| `planets` | Nom, Tmax, stocks, `last_update_ms` | v1 |
| `buildings` | Niveau et réglage de production (`percent`) par bâtiment | v1 (`percent` v2) |
| `research` | Niveau par techno | v2 |
| `units` | Nombre par unité et par planète | v3 |
| `events` | File unique : type, échéance, `payload` JSON, statut | v1 |
| `reports` | Rapports de raid (JSON), vu / non vu | v4 |
| `officers` | Niveau par officier débloqué (spec 12) | v5 |
| `counters` | Compteurs de progression (raids repoussés) ; à la migration v5, initialisé avec les raids repoussés des rapports | v5 |
| `meta` | Vitesse de jeu, graine ; préférences d'affichage hors sauvegarde JSON (`ambiance`, `filter_realizable.<onglet>`) | v1 |

- `schemaVersion` = **5**. Chaque montée de version a son étape dans `onUpgrade` et le test
  `migration_test.dart` part d'une **base v1 réelle** jusqu'à la dernière version.
- Chaque écriture est **une transaction** : état, statut des événements appliqués ou annulés,
  rapports produits.
- Un événement de chaîne (lot, raid) reste `pending` sous le même id ; seuls les événements
  terminés passent `done`.
- Le code Drift (`*.g.dart`) est généré par build_runner, jamais commité.

## Sauvegarde JSON (export / import)

- Format `starmine-save`, `version` = **5**. Contient planète (stocks, niveaux, réglages,
  unités), technos, officiers, compteurs, événements en attente (raids : relevé et technos
  pirates), vitesse, graine. Les rapports n'en font pas partie.
- Une sauvegarde **plus ancienne** s'importe (valeurs par défaut pour les champs absents) ;
  une sauvegarde **plus récente** que l'app est refusée.
- Export et import passent par le presse-papiers (écran Debug).

## Code

`lib/data/database.dart`, `lib/data/game_repository.dart`, `lib/data/save_codec.dart`.

## Tests

`migration_test.dart`, `game_repository_test.dart`, `save_codec_test.dart`,
`game_controller_test.dart` (export → reset → import).
