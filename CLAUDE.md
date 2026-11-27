# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Starmine – consignes

## Commandes

```bash
flutter pub get
dart run build_runner build -d                 # code Drift (*.g.dart), après tout changement de lib/data/database.dart
flutter analyze
flutter test                                   # toute la suite
flutter test test/domain/engine_test.dart      # un fichier
flutter test test/domain/raid_test.dart --plain-name '<nom du test>'   # un test
dart format lib test                           # la CI refuse un code non formaté
flutter test test/balance/balance_report_test.dart   # mesure d'équilibrage, lignes « BALANCE| »
```

CI (`.github/workflows/ci.yml`) : contrôle Dart pur de `lib/domain/`, analyze, tests, format,
`pubspec.lock` à jour. APK seulement sur tag `v*` ou lancement manuel.

## Architecture

Trois couches, dépendances à sens unique : `domain` ← `data` ← `ui`.

- **`lib/domain/`** : état et règles. `engine.dart` porte `GameState` et `advance()`, qui
  rejoue dans l'ordre les événements échus (constructions, raids, missions, effets) jusqu'à
  `now` ; les ordres du joueur rendent un `OrderOutcome` scellé (`OrderStarted`,
  `OrderQueued`, `OrderRejected` + raison `OrderBlock`). `game_data.dart` type le YAML,
  `rules.dart` les formules, puis un fichier par mécanique (`raid`, `fleet`, `combat`,
  `story`, `officers`, `availability`).
- **`lib/data/`** : `database.dart` (Drift, `schemaVersion`, migrations testées depuis une
  base v1 réelle), `game_repository.dart` (charge/sauve `GameState`), `save_codec.dart`
  (export/import JSON versionné, spec 08).
- **`lib/ui/`** : `GameController` (ChangeNotifier) sérialise chaque action :
  avancer → commander → sauvegarder → reprogrammer les notifications. `home_shell.dart`
  porte la navigation par onglets ; `visuals.dart` résout un id d'image du registre vers un
  asset, avec repli. `main.dart` câble le tout.
- **Tests** miroirs de `lib/` (`test/domain`, `test/data`, `test/ui`) ;
  `test/domain/helpers.dart` fournit `shippedGameData` (le vrai YAML) ;
  `test/balance/bot.dart` est un joueur automatique pour les simulations.
- **`tool/`** : `ci.sh` (boucle CI), scripts ComfyUI (`comfy_*.py`) et `export_visuals.py`
  pour la production des images (skill `starmine-visuals`).

## Où est quoi

- **Specs fonctionnelles** (comportement implémenté) : `docs/specs/` — à lire avant de toucher
  une fonctionnalité, à mettre à jour dans le même commit.
- Historique des specs par version et roadmap : doc claude.ai « OGame-like solo — Specs V0 &
  Roadmap ». Visuels : `docs/specs/10-ecrans-ux.md` (disposition cible) et
  `docs/specs/11-visuels.md` (images, registre `art/registry.yaml`) ; décisions et historique
  dans le projet claude.ai, `claude/visuels-decisions.md`.
- **Skills locaux** (`.claude/skills/`) :
  - `starmine-feature` : toute évolution de gameplay, de la spec au push ;
  - `starmine-ci` : boucle CI sans SDK (`tool/ci.sh`) ;
  - `starmine-ui` : conventions d'interface et disposition de la refonte visuelle ;
  - `starmine-visuals` : production des images (ComfyUI local), registre, validation ;
  - `starmine-prompt` : mise au point d'un prompt d'image, méthode mesurable ;
  - `starmine-balance` : équilibrage par le YAML et des simulations.

## Règles

- `lib/domain/` est du Dart pur : aucun import Flutter, Drift, sqlite3 ou path_provider (la CI
  échoue sinon). Tout le gameplay y vit et y est testé.
- Les paramètres de jeu vont dans `assets/game_data.yaml`, les formules dans le code.
- Le temps n'avance que via `advance(state, now)` ; jamais de timer qui écrit l'état. Tout
  aléatoire passe par une graine stockée.
- Push direct sur `main`, commits petits et thématiques, messages en français.
- L'environnement de Claude n'a pas de SDK Flutter : la CI GitHub Actions est la seule
  vérification (`tool/ci.sh wait` après chaque push). La session ne peut pas pousser de tag.
- `pubspec.lock` est commité ; le code Drift (`*.g.dart`) n'est jamais commité.
- UX mobile : toute mécanique non évidente a une infobulle au tap (`InfoButton`). Pas de
  Tooltip à l'appui long seul. Cibles tactiles ≥ 48 dp. L'image ne porte jamais d'information.
- Images : seules les entrées `validated` du registre sont packagées ; masters en local
  (`art/masters/`, ignoré par Git), jamais versionnés ni dans l'APK.
