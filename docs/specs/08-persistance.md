# 08 · Persistance et sauvegarde

## Objet

Ne jamais perdre une partie : base locale versionnée et sauvegarde exportable.

## Base SQLite (Drift)

| Table | Contenu | Depuis |
| --- | --- | --- |
| `planets` | Nom, Tmax, stocks, champ de débris (v8), `last_update_ms` | v1 |
| `buildings` | Niveau et réglage de production (`percent`) par bâtiment | v1 (`percent` v2) |
| `research` | Niveau par techno | v2 |
| `units` | Nombre par unité et par planète | v3 |
| `events` | File unique : type, échéance, `payload` JSON, statut | v1 |
| `reports` | Rapports de raid (JSON), vu / non vu | v4 |
| `officers` | Niveau par officier débloqué (spec 12) | v5 |
| `pirate_bases` | Bases pirates (JSON : génération, stock, survivants, débris, espionnage) | v9 |
| `active_effects` | Effets temporaires des événements en cours (JSON, spec 14) | v7 |
| `story_log` | Journal des événements ponctuels (clé, issue, option, pari réussi `won` v10) | v7 |
| `queued_orders` | Ordres en file d'attente : id réservé, position, payload (spec 13) | v6 |
| `counters` | Compteurs de progression (raids repoussés) ; à la migration v5, initialisé avec les raids repoussés des rapports | v5 |
| `meta` | Vitesse de jeu, graine ; préférences d'affichage hors sauvegarde JSON (`ambiance`, `filter_realizable.<onglet>`) | v1 |

- `schemaVersion` = **10**. Chaque montée de version a son étape dans `onUpgrade` et le test
  `migration_test.dart` part d'une **base v1 réelle** jusqu'à la dernière version.
- Chaque écriture est **une transaction** : état, statut des événements appliqués ou annulés,
  rapports produits.
- Un événement de chaîne (lot, raid) reste `pending` sous le même id ; seuls les événements
  terminés passent `done`.
- Le code Drift (`*.g.dart`) est généré par build_runner, jamais commité.

## Sauvegarde JSON (export / import)

- Format `starmine-save`, `version` = **10** (v10 : chaîne des événements avec stock,
  échéances du stock, du choix et du service ; effet `delayed` avec son montant). Contient planète (stocks, niveaux, réglages,
  unités, débris), technos, officiers, compteurs, file d'attente, effets d'événements en cours, bases pirates,
  événements en attente (raids : relevé et technos
  pirates), vitesse, graine. Les rapports et le journal des événements n'en font pas partie.
- Une sauvegarde **plus ancienne** s'importe (valeurs par défaut pour les champs absents) ;
  une sauvegarde **plus récente** que l'app est refusée.
- Export et import passent par le presse-papiers (écran Debug).

## Code

`lib/data/database.dart`, `lib/data/game_repository.dart`, `lib/data/save_codec.dart`.

## Tests

`migration_test.dart`, `game_repository_test.dart`, `save_codec_test.dart`,
`game_controller_test.dart` (export → reset → import).
