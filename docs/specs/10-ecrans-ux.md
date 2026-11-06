# 10 · Écrans et UX

## Objet

Inventaire des écrans et de l'information que chacun **doit** afficher. Référence pour la
refonte visuelle : la disposition et le style peuvent changer, pas l'information.

## Structure

```
Barre du haut : nom de la planète, « Température Tmin à Tmax », icône Rapports (+ non lus)
[Bandeau d'alerte raid, si une flotte est en route]
Barre de ressources
Contenu de l'onglet
Navigation : Bâtiments · Recherche · Défense · File · Debug
```

## Éléments communs

| Élément | Information |
| --- | --- |
| Barre de ressources | Par ressource : icône, nom, stock (animé chaque seconde, rouge si plein), capacité, production /h. Énergie : solde en gras, produite · consommée, « Mines à X % » si manque, infobulle |
| Pastilles d'onglet | Verte = file libre ; rouge = file bloquée par l'agrandissement du labo ou du chantier ; rien = occupée ou bâtiment absent |
| Puces de filtre | « Tout » (avec titres de section) + une puce par catégorie du YAML |
| Carte d'élément | Nom, infobulle, niveau ou nombre, effet du niveau suivant, « Requiert … (niveau actuel) » si verrouillé (carte grisée), « Débloque … », coût avec icônes (ressource manquante en rouge), durée, raison du blocage (« Manque … · dans 14 min », file occupée…), bouton |
| Infobulle | Icône (i) → feuille du bas ; jamais d'appui long seul |

## Écrans

- **Bâtiments** : cartes + réglage de production (0–100 %) sur les bâtiments concernés.
- **Recherche** : cartes + étiquette « Palier N » (tap = explication).
- **Défense** : cartes d'unités (× possédé, attaque / bouclier / coque) + feuille de quantité.
- **File** : Construction, Recherche, Chantier. En cours : nom → niveau ou « 3 / 20 »,
  barre de progression, reste, heure de fin, Annuler (pas pour le chantier). Vide : message ;
  bloquée : cadenas rouge « Laboratoire / Chantier en agrandissement : impossible pendant
  encore … » ; bâtiment absent : invitation à le construire.
- **Debug** : vitesse ×1/×10/×100, export / import (presse-papiers), simulateur de combat
  (flottes types → 100 batailles), raid immédiat + points, nouvelle partie, alarmes exactes,
  dernière mise à jour.
- **Rapports** (depuis la barre du haut) : liste des raids → rapport complet.
- **Feuilles** : rapport de combat, simulation (spec 06), détail de la flotte pirate (spec 07),
  quantité au chantier.
- **Messages** : refus d'une commande, raid résolu app ouverte (avec accès au rapport).

## Styles

| Jeton | Valeur |
| --- | --- |
| Métal | Cube, gris acier `#A7B1BC` |
| Cristal | Diamant, bleu `#64B5F6` |
| Deutérium | Goutte, turquoise `#4DD0C8` |
| Énergie | Éclair, jaune `#F5C451` (aussi couleur de base du thème sombre) |
| Recherche | Fiole |
| Libre / bloqué | Vert `#66BB6A` / couleur d'erreur du thème |

Code : `lib/ui/resource_style.dart`, thème dans `lib/main.dart`.

## Règles pour la refonte visuelle

- **L'image ne porte jamais d'information** : chiffres, coûts, timers restent en texte.
- Les visuels viennent du registre YAML (décisions : projet claude.ai,
  `claude/visuels-decisions.md`) ; intégration « équilibrée » par défaut (hero planète +
  vignettes), « immersive » en option.
- Garder les tests de widgets verts : ils vérifient des textes, pas une disposition.

## Code

`lib/ui/home_shell.dart`, `lib/ui/screens/*`, `lib/ui/widgets/*`.

## Tests

`test/ui/home_shell_test.dart` (navigation, filtres, messages de file),
`test/ui/game_controller_test.dart`.
