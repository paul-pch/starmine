---
name: starmine-ci
description: Vérifier Starmine via GitHub Actions quand aucun SDK Flutter n'est disponible localement (pousser, attendre la CI, lire les erreurs, appliquer le format et le pubspec.lock calculés par la CI). À utiliser après chaque push ou quand la CI échoue.
---

# Boucle CI sans SDK Flutter

L'environnement de Claude n'a ni Flutter ni Dart, et les installations de paquets peuvent être
bloquées : **la CI est la seule compilation**. Le dépôt est public, l'API GitHub se lit sans
jeton.

## Boucle

```bash
git push -q origin main
tool/ci.sh wait            # attend le run du HEAD, affiche jobs, erreurs, tests
```

Lire dans cet ordre :

1. **`flutter analyze`** : erreurs de type, imports inutiles. Corriger d'abord ; une erreur
   d'analyse fait aussi échouer la compilation des tests.
2. **`flutter test`** : `Expected / Actual / Which` donnent la cause. Une erreur de compilation
   apparaît une fois par fichier de test : n'en corriger qu'une.
3. **Format** : la CI imprime le diff attendu → `tool/ci.sh apply-format`. Appliquer le diff
   **avant** d'éditer les mêmes fichiers, sinon il ne s'applique plus.
4. **`pubspec.lock` obsolète** (après un ajout de dépendance) : la CI imprime le lock
   résolu → `tool/ci.sh apply-lock`.

Puis commit « Format » ou correctif, push, `tool/ci.sh wait` à nouveau.

## Bonnes pratiques

- Écrire le code au format `dart format` (largeur 100) pour limiter les allers-retours :
  retours à la ligne après la parenthèse ouvrante quand l'appel dépasse, virgule finale.
- Types explicites pour les listes et maps hétérogènes (`<Unlockable>[...]`) : l'inférence
  stricte est activée.
- Pour attendre longtemps, lancer `tool/ci.sh wait` en tâche de fond plutôt que de bloquer.
- Un push pendant un run annule le run précédent (concurrence) : attendre la fin d'un build
  APK avant de pousser.

## Ce que la session ne peut pas faire

- **Pousser un tag** (refusé par le proxy) : donner la commande à l'utilisateur.
  Le job APK ne tourne que sur un tag `v*` ou un lancement manuel.
- Manipuler les secrets de signature : c'est l'utilisateur qui les gère.
