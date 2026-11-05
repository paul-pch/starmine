# Starmine

Idle solo façon OGame, en temps réel, pour Android 15+. Flutter, 100 % local (SQLite), sans backend.

## Architecture

| Dossier | Rôle | Dépendances autorisées |
| --- | --- | --- |
| `lib/domain/` | Règles, formules, moteur d'événements `advance()` | Dart pur uniquement (vérifié en CI) |
| `lib/data/` | Drift/SQLite, chargement de `assets/game_data.yaml`, export/import JSON | domain |
| `lib/ui/` | Écrans, notifications | domain, data |

## Dev local

```bash
flutter pub get
dart run build_runner build -d   # code Drift (*.g.dart, non commité)
flutter test
flutter run            # signé avec la clé debug
```

## CI et APK

- Chaque push : format, `flutter analyze`, `flutter test`.
- Lancement manuel (Actions → CI → Run workflow) : APK release arm64 signé, en artefact (30 jours).
- Tag `v*` : APK et GitHub Release avec l'APK en pièce jointe, à télécharger depuis le téléphone.

```bash
git tag v0.1.0 && git push origin v0.1.0
```

Le `versionCode` vaut `github.run_number`, le `versionName` vient de `pubspec.yaml`.

### Secrets de signature

| Secret | Contenu |
| --- | --- |
| `ANDROID_KEYSTORE_B64` | `starmine.jks` encodé en base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Mot de passe du keystore |
| `ANDROID_KEY_ALIAS` | Alias de la clé (`starmine`) |
| `ANDROID_KEY_PASSWORD` | Mot de passe de la clé (identique au keystore en PKCS12) |

Le keystore ne doit jamais être perdu : sans lui, impossible de mettre à jour l'app sans la désinstaller (et perdre la sauvegarde).
