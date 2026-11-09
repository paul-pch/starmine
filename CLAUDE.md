# Starmine – consignes

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
- Images : seules les entrées `validated` du registre sont packagées ; masters en Git LFS
  (`art/masters/`), jamais dans l'APK.
