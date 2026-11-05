# Starmine – consignes

- Specs et roadmap : doc « OGame-like solo — Specs V0 & Roadmap » (claude.ai). La V0 est la seule spécifiée en détail.
- `lib/domain/` est du Dart pur : aucun import Flutter, Drift, sqlite3 ou path_provider (la CI échoue sinon). Tout le gameplay y vit et y est testé.
- Les paramètres de jeu (coûts, facteurs) vont dans `assets/game_data.yaml`, les formules dans le code.
- Le temps n'avance que via `advance(state, now)` ; jamais de timer qui écrit l'état.
- Push direct sur `main`, commits petits et thématiques, messages en français.
- L'environnement de Claude n'a pas de SDK Flutter : la CI GitHub Actions est la seule vérification. Lire ses logs après chaque push.
- `pubspec.lock` doit être commité (app) ; le générer avec `flutter pub get`.
- Le code Drift (`*.g.dart`) est généré par build_runner en CI et localement, jamais commité.
- Si la CI signale un `pubspec.lock` obsolète, elle imprime le lock attendu dans ses logs : le reprendre tel quel.
- UX mobile : toute mécanique non évidente a une infobulle au tap (`InfoButton`, icône i → feuille du bas). Pas de Tooltip à l'appui long seul.
