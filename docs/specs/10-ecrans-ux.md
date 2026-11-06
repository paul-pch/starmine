# 10 · Écrans et UX

## Objet

Inventaire des écrans, de l'information que chacun **doit** afficher et de leur disposition
cible (refonte visuelle). Règle d'or : la disposition et le style peuvent changer, pas
l'information ; une information peut passer dans une feuille du bas, jamais disparaître.

Maquettes de référence (validées) : canevas claude.ai « Ogamelike – intégration visuels
(mobile) », https://claude.ai/artifact/MS19SVcTb4gKJUzof7czUS — B « Équilibrée » (défaut),
C « Immersive » (option), A « Sobre » (repli sans image). Les images et leur registre :
spec 11.

État : la disposition ci-dessous est la **cible** ; l'implémentation actuelle suit encore
l'ancienne disposition (AppBar + barre de ressources + liste), avec la même information.

## Structure

```
Barre de ressources (collée en haut, compacte)
Hero planète 21:9 : image + bandeau opaque (nom, « Tmin à Tmax °C », icône Rapports + non lus)
[Bandeau d'alerte raid, si une flotte est en route]
Contenu de l'onglet : [carte « En cours » de la file de l'onglet] · puces · cartes
Navigation : Bâtiments · Recherche · Défense · File · Debug (pastilles d'état de file)
```

En C, le hero est remplacé par le fond plein écran (spec 11) ; barre de ressources et contenu
sont posés sur des panneaux opaques à 78–90 %.

## Éléments communs

| Élément | Information | Disposition |
| --- | --- | --- |
| Barre de ressources | Par ressource : icône, stock (animé chaque seconde, rouge si plein), production /h ; jauge fine de remplissage. Énergie : solde ; « Mines à X % » en rouge à la place du /h si manque | 4 colonnes. Tap sur une ressource → feuille : nom, stock / capacité, production détaillée ; énergie : produite · consommée, explication du facteur |
| Hero planète | Nom, « Tmin à Tmax °C », Rapports (badge du nombre de non lus) | Image par tranche de température (spec 11), texte sur un bandeau opaque à 82 %, jamais sur l'image nue |
| Carte « En cours » | File de l'onglet : nom → niveau ou « 3 / 20 », barre de progression, reste | En tête de l'onglet si la file est occupée ; tap → onglet File. Rouge avec cadenas si la file est bloquée (agrandissement du labo / chantier) |
| Pastilles d'onglet | Verte = file libre ; rouge = file bloquée par l'agrandissement du labo ou du chantier ; rien = occupée ou bâtiment absent | Point sur l'icône de navigation (inchangé) |
| Puces de filtre | « Tout » (avec titres de section) + une puce par catégorie du YAML | Rangée défilante horizontale sous la carte « En cours » |
| Carte d'élément | Voir ci-dessous | B : ligne avec vignette 64 px ; C : grille 2 colonnes, image 4:3 en tête ; A : vignette remplacée par l'icône vectorielle |
| Infobulle | Icône (i) → feuille du bas ; jamais d'appui long seul | Inchangé |

### Carte d'élément

Toujours visible sur la carte (B) :

- vignette (décorative) ; nom + (i) ; « Niv. N · effet du niveau suivant » ou « × N possédés » ;
- coût avec icônes (ressource manquante en rouge) · durée ;
- raison du blocage s'il y en a une (« Manque … · dans 14 min », file occupée…) ;
- bouton d'action 48 dp (flèche « Améliorer », « Rechercher », « Commander »), désactivé si
  bloqué ; libellé accessible = action + nom ;
- carte verrouillée : grisée, « Requiert … (niveau actuel) » à la place du coût ;
- réglage de production < 100 % : puce « Production X % » à côté du niveau.

Dans la feuille de détail (tap sur la carte) : description (YAML), « Débloque … »,
« Requiert … » complet, réglage de production 0–100 % (bâtiments concernés), caractéristiques
d'unité (attaque / bouclier / coque) et feuille de quantité pour la défense.

En C, la carte n'affiche que nom, niveau, durée et le coût **sur** le bouton ; tout le reste
est dans la feuille de détail (un tap).

## Écrans

- **Bâtiments** : cartes ; réglage de production dans la feuille de détail.
- **Recherche** : cartes + étiquette « Palier N » (tap = explication).
- **Défense** : cartes d'unités (× possédé, attaque / bouclier / coque) + feuille de quantité.
- **File** : Construction, Recherche, Chantier. En cours : nom → niveau ou « 3 / 20 »,
  barre de progression, reste, heure de fin, Annuler (pas pour le chantier). Vide : message ;
  bloquée : cadenas rouge « Laboratoire / Chantier en agrandissement : impossible pendant
  encore … » ; bâtiment absent : invitation à le construire.
- **Debug** : vitesse ×1/×10/×100, **ambiance** (Équilibrée / Immersive / Sobre), export /
  import (presse-papiers), simulateur de combat (flottes types → 100 batailles), raid
  immédiat + points, nouvelle partie, alarmes exactes, dernière mise à jour.
- **Rapports** (depuis le hero) : liste des raids → rapport complet.
- **Feuilles** : détail d'élément, détail d'une ressource, rapport de combat, simulation
  (spec 06), détail de la flotte pirate (spec 07), quantité au chantier.
- **Messages** : refus d'une commande, raid résolu app ouverte (avec accès au rapport).

## Filtre « Réalisables » (à implémenter)

Décidé : une bascule « Réalisables » qui **masque** tout ce qui ne peut pas être lancé
maintenant, sur Bâtiments, Recherche et Défense.

Proposé (non contesté, à confirmer à l'implémentation) :

- réalisable = prérequis remplis **et** ressources disponibles (défense : au moins une
  unité) ; la file n'est **pas** prise en compte (sinon l'onglet se vide pendant une
  construction) ; les éléments verrouillés sont masqués aussi ;
- combinable avec les puces de catégorie, placée à droite des puces ;
- évalué à l'activation et au changement d'onglet, **pas chaque seconde** (sinon les cartes
  apparaissent et disparaissent en plein défilement) ; un bandeau « N nouveaux éléments
  réalisables · Actualiser » signale les changements ;
- liste vide : « Rien de réalisable · <élément> dans <durée> » (le plus tôt accessible) ;
- choix mémorisé par onglet (préférence d'affichage, comme l'ambiance).

## Ambiance

Préférence d'affichage, pas un état de jeu : table `meta`, clé `ambiance`
(`balanced` par défaut, `immersive`, `plain`), hors sauvegarde JSON. Changer d'ambiance ne
change aucune information affichée.

## Styles

| Jeton | Valeur |
| --- | --- |
| Fond | `#0B0F17` ; barres `#0E1420` ; surfaces (cartes) `#131A26` ; filets `#233046` |
| Texte | `#E6EDF7` ; secondaire `#A3B2C9` ; tertiaire `#8A9BB4` (≥ 4,5:1 sur les surfaces) |
| Action | `#F2A93B`, texte `#1A1206` ; carte « En cours » fond `#1A1408`, bord `#5A4116` |
| Métal | Cube, gris acier `#A7B1BC` |
| Cristal | Diamant, bleu `#64B5F6` |
| Deutérium | Goutte, turquoise `#4DD0C8` |
| Énergie | Éclair, jaune `#F5C451` (couleur de base du thème sombre) |
| Recherche | Fiole |
| Libre / positif | Vert `#66BB6A` (pastilles, production /h) ; bloqué / manque : couleur d'erreur du thème |
| Typo | Titres Space Grotesk 500/700 ; texte Inter 400–600 ; chiffres JetBrains Mono 500. Polices embarquées (OFL), pas de chargement réseau |
| Rayons | Cartes 10–12 ; boutons 8–10 ; vignettes 8–10 |
| Cibles tactiles | ≥ 48 dp |

Les icônes de ressources restent vectorielles (Material) : pas d'image générée à cette taille.

Code : `lib/ui/resource_style.dart`, thème dans `lib/main.dart`.

## Règles pour la refonte visuelle

- **L'image ne porte jamais d'information** : chiffres, coûts, timers, niveaux restent en
  texte ; la couleur double toujours un texte ou une icône.
- Images décoratives : exclues de la sémantique (lecteur d'écran).
- Le chargement d'une image ne bloque jamais l'affichage des chiffres ; image absente →
  repli (spec 11).
- Garder les tests de widgets verts : ils vérifient des textes, pas une disposition.

## Code

`lib/ui/home_shell.dart`, `lib/ui/screens/*`, `lib/ui/widgets/*`.

## Tests

`test/ui/home_shell_test.dart` (navigation, filtres, messages de file),
`test/ui/game_controller_test.dart`.

## Points ouverts

- Ordre exact des onglets et place de Debug une fois la refonte en main.
