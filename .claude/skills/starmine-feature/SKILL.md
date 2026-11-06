---
name: starmine-feature
description: Ajouter ou modifier une fonctionnalité de jeu Starmine de bout en bout (spec, données YAML, domaine Dart pur, persistance, UI, CI). À utiliser pour toute évolution de gameplay, nouvel événement, nouveau bâtiment / techno / unité, ou changement de règle.
---

# Fonctionnalité Starmine, de la spec au push

Ordre de travail. Chaque étape a sa vérification ; ne pas passer à la suivante sans elle.

## 1. Spec d'abord

- Lire `docs/specs/README.md` puis la ou les specs concernées.
- Écrire ou modifier la spec **avant le code** : règles, clés YAML, UI, tests attendus.
  Les chiffres vont dans le YAML, pas dans la spec.
- Une décision de gameplay non tranchée par l'utilisateur → la lui poser (règle OGame
  proposée par défaut, avec une recommandation).

## 2. Données (`assets/game_data.yaml`)

- Nouveau bâtiment / techno / défense : `name`, `description` (sert d'infobulle),
  `category` (doit exister dans `categories`), `cost`, `factor`, `requires`.
- Valeur OGame reprise de mémoire : commentaire « à vérifier ». Vérifier sur le wiki OGame
  quand c'est possible et citer la source dans le message de commit.
- Nouvelle section : la parser dans `GameData.fromMap` (lecture typée, `FormatException`
  explicite) et l'ajouter au test de config de `rules_test.dart`.

## 3. Domaine (`lib/domain/`, Dart pur)

- Aucun import Flutter, Drift, sqlite3, path_provider (contrôlé en CI).
- Le temps n'avance que via `advance()` ; tout aléatoire passe par une graine stockée dans
  l'événement.
- **Nouveau type d'événement** : `GameEvent` est scellé ; compléter tous les `switch`
  exhaustifs, sinon la compilation échoue :
  - `lib/domain/engine.dart` : `_apply` (renvoie `state`, `next` éventuel, `report`) ;
  - `lib/data/save_codec.dart` : `eventType`, `eventPayload`, `decodeEvent` ;
  - `lib/data/game_repository.dart` : `_createdAt` ;
  - `lib/ui/notifications.dart` : `schedule` (et `notifyAt` si l'instant diffère de `dueAt`) ;
  - `test/domain/engine_test.dart` : la simulation de référence `secondBySecond`.
- Événement en chaîne : renvoyer `next` **avec le même id** (le repository le garde
  `pending`).
- Échéances à la milliseconde (sinon l'aller-retour de sauvegarde diffère).
- Tests dans `test/domain/` : règle nominale, refus, déterminisme ; si la règle touche
  `advance`, comparer à une simulation pas à pas.

## 4. Persistance (`lib/data/`)

- Nouvelle donnée d'état → table ou colonne Drift :
  - incrémenter `schemaVersion` ; ajouter l'étape `if (from < N)` dans `onUpgrade` ;
  - étendre `test/data/migration_test.dart` (il part d'une base v1 réelle) ;
  - `replaceAll` doit vider la nouvelle table.
- Sauvegarde JSON : incrémenter `saveVersion` si le format change ; **une sauvegarde plus
  ancienne doit rester importable** (valeurs par défaut), test dans `save_codec_test.dart`.
- Mettre à jour `docs/specs/08-persistance.md`.

## 5. UI (`lib/ui/`)

- Suivre le skill `starmine-ui`.
- Orchestration dans `GameController` : une seule horloge par action (`final t = now();`),
  `advance` puis commande puis `_commit(..., applied:, reports:)` ; notifications seulement
  si l'app est masquée.
- Test de widget si un écran ou un message change (`test/ui/`).

## 6. Vérifier et livrer

- Suivre le skill `starmine-ci` (push sur `main`, lecture de la CI, format, lock).
- Commits petits et thématiques, en français, avec les lignes d'attribution demandées.
- Mettre à jour la spec et, si le périmètre de version change, `00-vision-roadmap.md`.
- Si une spec change, régénérer l'instantané `claude/specs-fonctionnelles.md` du projet
  claude.ai (concaténation de `docs/specs/[0-9]*.md`) : il sert à la refonte visuelle.
- Proposer le tag à l'utilisateur (`git tag vX.Y.Z && git push origin vX.Y.Z`) : la session
  ne peut pas pousser de tag.
