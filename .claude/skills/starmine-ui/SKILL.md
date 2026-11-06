---
name: starmine-ui
description: Conventions d'interface de Starmine (mobile Android, Flutter) et règles de la refonte visuelle — écrans, cartes, infobulles, pastilles, puces, couleurs, intégration des images du registre. À utiliser pour tout changement d'écran, de widget, de texte affiché ou d'intégration de visuels.
---

# UI Starmine

Référence fonctionnelle : `docs/specs/10-ecrans-ux.md` (ce que chaque écran **doit**
afficher). Ce skill dit **comment** le faire.

## Principes

- **Mobile d'abord** : largeur de téléphone, cibles tactiles ≥ 32 px, pas de survol.
- **L'information reste en texte** : chiffres, coûts, timers, niveaux ne sont jamais portés
  par une image ni par la couleur seule (la couleur double un texte ou une icône).
- **Toute mécanique non évidente a une infobulle au tap** : `InfoButton` (icône i → feuille
  du bas) ou `InfoButton.show(...)` sur un élément touchable. Jamais un `Tooltip` à l'appui
  long seul. Le texte vient du YAML (`description`) quand il décrit un élément de jeu.
- **Textes en français**, phrases courtes, chiffres via `fmtAmount` / `fmtDuration` /
  `CostLine` (espace fine insécable pour les milliers).

## Briques existantes (réutiliser avant de créer)

| Besoin | Brique |
| --- | --- |
| Icône et couleur d'une ressource, énergie, recherche | `ResourceStyle` (`lib/ui/resource_style.dart`) |
| Coût avec icônes, manque en rouge | `CostLine` |
| Liste filtrable par catégorie | `CategorizedList` (catégories du YAML) |
| Bâtiment ou techno | `ItemCard` |
| Explication | `InfoButton` |
| Forces, rounds, simulation | `ForcesTable`, `RoundsTable`, `SimulationSheet` |
| Rapport de combat | `CombatReport.show` |
| État d'une file | `slotStatus` (domaine) → pastille / message |

## Règles d'état

- Données affichées : `controller.interpolated(now)` pour les stocks qui bougent ; ne jamais
  écrire l'état depuis un widget (passer par une méthode du `GameController`).
- Pastilles d'onglet : verte = libre, rouge = bloquée (agrandissement), rien sinon.
- Carte verrouillée : grisée + « Requiert … (niveau actuel) ».

## Refonte visuelle

Décisions dans le projet claude.ai, `claude/visuels-decisions.md` (à relire avant de toucher
aux visuels) :

- Images **pré-générées**, packagées en WebP dans l'APK ; aucun appel de génération au runtime.
- **Registre YAML dans le dépôt** = source de vérité (id stable `building.metal_mine.t2`,
  catégorie, palier, format, statut, chemins `master` / `build`). Seules les entrées
  `validated` sont utilisées par l'app ; prévoir un repli (icône ou couleur) si l'image
  manque.
- Intégration **B « équilibrée »** par défaut (hero planète + vignettes), **C « immersive »**
  en option de réglage.
- Formats : icônes ressources 1:1, vignettes bâtiments 1:1 (B) / 4:3 (C), hero planète 21:9,
  fond 9:19.5 sombre en bas.
- Le chargement d'une image ne doit jamais bloquer l'affichage des chiffres.

## Vérification

- Tests de widgets dans `test/ui/` : vérifier des **textes**, pas une disposition, pour
  survivre à la refonte. Ajouter un test pour chaque nouveau message ou écran.
- Pas de rendu visuel possible dans la CI : décrire à l'utilisateur ce qu'il doit regarder
  sur son téléphone.
