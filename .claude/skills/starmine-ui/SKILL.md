---
name: starmine-ui
description: Conventions d'interface de Starmine (mobile Android, Flutter) et disposition cible de la refonte visuelle — écrans, cartes, feuilles, infobulles, pastilles, puces, couleurs, typo, ambiances. À utiliser pour tout changement d'écran, de widget, de texte affiché ou d'intégration d'images.
---

# UI Starmine

- **Quoi afficher** : `docs/specs/10-ecrans-ux.md` (information obligatoire, disposition
  cible, jetons de style). Ce skill dit **comment** le faire.
- **Images** : `docs/specs/11-visuels.md` et le skill `starmine-visuals`.
- **Maquettes validées (font foi pour la disposition)** : canevas claude.ai
  https://claude.ai/artifact/MS19SVcTb4gKJUzof7czUS — B « Équilibrée » (défaut),
  C « Immersive », A « Sobre ». Une maquette qui contredit la spec 10 sur l'information :
  la spec gagne, signaler l'écart à l'utilisateur.

## Principes

- **Mobile d'abord** : largeur de téléphone (390 dp de référence), cibles tactiles
  **≥ 48 dp**, pas de survol.
- **L'information reste en texte** : chiffres, coûts, timers, niveaux ne sont jamais portés
  par une image ni par la couleur seule (la couleur double un texte ou une icône).
- **Une information peut descendre dans une feuille du bas, jamais disparaître** : la carte
  garde l'essentiel pour décider (niveau, effet, coût, durée, blocage, action), le reste est
  à un tap (détail).
- **Toute mécanique non évidente a une infobulle au tap** : `InfoButton` (icône i → feuille
  du bas) ou `InfoButton.show(...)`. Jamais un `Tooltip` à l'appui long seul. Le texte vient
  du YAML (`description`) quand il décrit un élément de jeu.
- **Textes en français**, phrases courtes, chiffres via `fmtAmount` / `fmtDuration` /
  `CostLine` (espace fine insécable pour les milliers), en JetBrains Mono.
- **Sombre uniquement**, jetons de la spec 10 ; pas de dégradé décoratif, pas d'emoji, pas
  de texte posé sur une image nue (toujours un bandeau opaque ≥ 78 %).

## Disposition (ambiance Équilibrée)

```
ResourceBar compacte (4 colonnes, collée en haut)
PlanetHero 21:9 (image + bandeau : nom, Tmin à Tmax, Rapports + badge)
RaidBanner (si raid détecté)
Onglet : InProgressCard (si file occupée / bloquée) · puces · cartes
NavigationBar 5 onglets + pastilles de file
```

- **Immersive** : fond plein écran derrière tout ; ResourceBar et contenu sur des panneaux
  opaques (78 % / 90 %) ; cartes en grille 2 colonnes, image 4:3 en tête, coût sur le bouton.
- **Sobre** : comme Équilibrée sans aucune image (repli partout), hero réduit au bandeau.
- L'ambiance se lit dans `meta.ambiance` via le `GameController` ; un seul endroit choisit
  la variante (pas de `if` d'ambiance dispersés dans les écrans).

## Briques (réutiliser avant de créer)

| Besoin | Brique |
| --- | --- |
| Icône et couleur d'une ressource, énergie, recherche | `ResourceStyle` (`lib/ui/resource_style.dart`) |
| Coût avec icônes, manque en rouge | `CostLine` |
| Liste filtrable par catégorie | `CategorizedList` (catégories du YAML) |
| Bâtiment, techno, défense | `ItemCard` (+ feuille de détail) |
| Explication | `InfoButton` |
| Barre de ressources | `ResourceBar` (+ feuille de détail par ressource) |
| Alerte raid | `RaidBanner` |
| Forces, rounds, simulation | `ForcesTable`, `RoundsTable`, `SimulationSheet` |
| Rapport de combat | `CombatReport.show` |
| État d'une file | `slotStatus` (domaine) → pastille / InProgressCard / message |
| Image du registre | `visuals.dart` (à créer, spec 11) — jamais `Image.asset` en direct |

À créer pour la refonte : `PlanetHero`, `InProgressCard`, la feuille de détail d'élément,
`visuals.dart`. Polices embarquées dans `assets/fonts/` (déclarées dans `pubspec.yaml`),
jamais `google_fonts` (réseau au runtime).

## Règles d'état

- Données affichées : `controller.interpolated(now)` pour les stocks qui bougent ; ne jamais
  écrire l'état depuis un widget (passer par une méthode du `GameController`).
- Pastilles d'onglet : verte = libre, rouge = bloquée (agrandissement), rien sinon.
- Carte verrouillée : grisée + « Requiert … (niveau actuel) ».

## Images dans l'UI

- Toujours via `visuals.dart` : id → asset, palier du bâtiment, tranche de température,
  repli (surface + icône vectorielle) si l'asset manque ou si l'ambiance est Sobre.
- Taille fixe réservée avant chargement (pas de saut de mise en page), `gaplessPlayback`,
  fondu ≤ 150 ms, `excludeFromSemantics: true`, `cacheWidth` à la taille affichée.
- `precacheImage` du hero et du fond au démarrage.

## Vérification

- Tests de widgets dans `test/ui/` : vérifier des **textes**, pas une disposition, pour
  survivre à la refonte. Un test par nouveau message, écran ou feuille.
- Pas de rendu visuel possible dans la CI : décrire à l'utilisateur ce qu'il doit regarder
  sur son téléphone (et dans quelle ambiance).
- Changement de disposition : mettre à jour la spec 10 dans le même commit, et la maquette
  si l'écart est volontaire.
