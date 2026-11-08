# 10 · Écrans et UX

## Objet

Inventaire des écrans, de l'information que chacun **doit** afficher et de leur disposition
cible (refonte visuelle). Règle d'or : la disposition et le style peuvent changer, pas
l'information ; une information peut passer dans une feuille du bas, jamais disparaître.

Maquettes de référence (validées) : canevas claude.ai « Ogamelike – intégration visuels
(mobile) », https://claude.ai/artifact/MS19SVcTb4gKJUzof7czUS — B « Équilibrée » (défaut),
C « Immersive » (option), A « Sobre » (repli sans image). Les images et leur registre :
spec 11.

État : B et A sont implémentées, sans images pour l'instant (repli partout, spec 11) ; les
polices restent à embarquer. C reste la **cible** : ce qui la concerne ci-dessous n'est pas
implémenté.

Écarts voulus avec les maquettes, la spec primant sur l'information : stocks en entier animé
(pas « 128.4k ») ; (i) sur chaque carte ; navigation avec icônes ; cibles 48 dp (44 sur la
maquette) ; couleurs des ressources et de la production selon les jetons ci-dessous.

## Structure

```
Barre de ressources (collée en haut, compacte)
Hero planète 21:9 (défile avec le contenu, 200 dp au plus) : image + bandeau opaque (nom,
  « Tmin à Tmax °C », icônes Debug, Officiers + disponibles et Rapports + non lus)
[Bandeau d'alerte raid, si une flotte est en route]
Contenu de l'onglet : [carte « En cours » de la file de l'onglet] · puces · cartes
Navigation : Bâtiments · Recherche · Chantier · File · Flotte (pastilles d'état de file) ;
  Debug depuis le hero
```

En C, le hero est remplacé par le fond plein écran (spec 11) ; barre de ressources et contenu
sont posés sur des panneaux opaques à 78–90 %.

## Éléments communs

| Élément | Information | Disposition |
| --- | --- | --- |
| Barre de ressources | Par ressource : icône, stock (animé chaque seconde, rouge si plein), production /h ; jauge fine de remplissage. Énergie : solde ; « Mines à X % » en rouge à la place du /h si manque | 4 colonnes. Tap sur une ressource → feuille : nom, stock / capacité, production détaillée (base, mines et consommations, total) ; énergie : produite · consommée, explication du facteur |
| Hero planète | Nom, « Tmin à Tmax °C », Officiers (badge du nombre d'officiers à débloquer ou promouvoir), Rapports (badge du nombre de non lus) | Image par tranche de température (spec 11), texte sur un bandeau opaque à 82 %, jamais sur l'image nue |
| Carte « En cours » | File de l'onglet : nom → niveau ou « 3 / 20 », barre de progression, reste (fin du lot pour le chantier) | En tête de l'onglet si la file est occupée ; tap → onglet File. Rouge avec cadenas si la file est bloquée (agrandissement du labo / chantier) |
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
d'unité (attaque / bouclier / coque) pour la défense. La feuille de quantité s'ouvre depuis
le bouton de la carte.

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
  immédiat + points, événement immédiat (spec 14), nouvelle partie, alarmes
  exactes, dernière mise à jour.
- **Rapports** (depuis le hero) : onglets « Raids » (liste → rapport complet) et
  « Événements » (journal des événements ponctuels, spec 14).
- **Bandeau des événements** (sous le bandeau de raid) : décision attendue et effets en
  cours (spec 14).
- **Officiers** (depuis le hero, spec 12) : carte par officier (nom, niveau / plafond, bonus
  actuel et du niveau suivant, prérequis en rouge s'ils manquent, « Débloquer » ou
  « Promouvoir »).
- **Feuilles** : détail d'élément, détail d'une ressource, rapport de combat, simulation
  (spec 06), détail de la flotte pirate (spec 07), quantité au chantier.
- **Messages** : refus d'une commande, raid résolu app ouverte (avec accès au rapport).

## Puces de filtre

Puces en **icônes** (une par catégorie du YAML, « Tout », « Réalisables »), pour tenir sur la
largeur d'un téléphone sans défiler (`CategoryStyle`). Le nom du filtre actif est écrit sous
les puces (« Réalisables · Production ») et les titres de section restent en texte ; chaque
puce a son libellé accessible.

## Filtre « Réalisables »

Une bascule « Réalisables », en tête de la rangée des puces de catégorie (combinable avec
elles), qui
**masque** tout ce qui ne peut pas être lancé maintenant, sur Bâtiments, Recherche et
Défense (`lib/domain/availability.dart`, `CategorizedList`).

- Réalisable = prérequis remplis **et** ressources disponibles (défense : au moins une
  unité, limite par planète comprise). La file n'est **pas** prise en compte (sinon
  l'onglet se vide pendant une construction) ; les éléments verrouillés sont masqués.
- Évalué à l'activation et à l'ouverture de l'onglet, **pas chaque seconde** ; un bandeau
  « N nouveaux éléments réalisables · Actualiser » signale les éléments devenus réalisables.
- Liste vide : « Rien de réalisable » et « <élément> dans <durée> » (le plus tôt accessible
  au rythme de production actuel ; rien si tout est verrouillé ou hors d'atteinte).
- Choix mémorisé par onglet (préférence d'affichage, table `meta`, clés
  `filter_realizable.<onglet>`, hors sauvegarde JSON).

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

Code : `lib/ui/resource_style.dart`, thème et jetons dans `lib/ui/theme.dart`.

## Règles pour la refonte visuelle

- **L'image ne porte jamais d'information** : chiffres, coûts, timers, niveaux restent en
  texte ; la couleur double toujours un texte ou une icône.
- Images décoratives : exclues de la sémantique (lecteur d'écran).
- Le chargement d'une image ne bloque jamais l'affichage des chiffres ; image absente →
  repli (spec 11).
- Garder les tests de widgets verts : ils vérifient des textes, pas une disposition.

## Code

`lib/ui/home_shell.dart`, `lib/ui/theme.dart`, `lib/ui/screens/*`, `lib/ui/widgets/*`.

## Tests

`test/ui/home_shell_test.dart` (navigation, filtres, messages de file, feuilles, carte
« En cours », ambiance),
`test/ui/game_controller_test.dart`.

## Points ouverts

- Ordre exact des onglets et place de Debug une fois la refonte en main.
