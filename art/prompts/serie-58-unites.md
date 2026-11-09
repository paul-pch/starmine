# Série 58, unités du chantier spatial

Constructibles du chantier spatial : 8 défenses (`defense.<clé>`) et 8 vaisseaux (`ship.<clé>`), dans l'ordre du
YAML de jeu, une unité à la fois, 3 images par essai (seeds 1234, 4242, 7777). Charte : `art/style/unit_prompt.md`,
choisie par l'utilisateur en Q/R : défenses sur la roche grise en extérieur, vaisseaux en orbite au-dessus de la
planète grise, une seule image par unité, sans climat. Modèle : Qwen-Image-2.1, 25 pas, cfg 1.

## Retenues

| Unité | Code retenu | Essais |
| --- | --- | --- |
| `defense.rocket_launcher` | `e1-rocket_launcher-1234` | 1 |
| `defense.light_laser` | `e3-light_laser-1234` | 3 |
| `defense.heavy_laser` | `e1-heavy_laser-1234` | 1 (+ agrandissement refusé) |
| `defense.gauss_cannon` | `tilt-d97-gauss_cannon-1234` | 2 |
| `defense.ion_cannon` | `e1-ion_cannon-7777` | 1 |
| `defense.plasma_turret` | `e1-plasma_turret-4242` | 1 |
| `defense.small_shield_dome` | `e3-small_shield_dome-1234` | 3 |
| `defense.large_shield_dome` | `e2-large_shield_dome-7777` | 2 |
| `ship.small_cargo` | `e2-d95-small_cargo-7777` | 2 |
| `ship.large_cargo` | `e2-large_cargo-4242` | 2 (+ retouche refusée) |
| `ship.light_fighter` | `e1-light_fighter-1234` | 1 |
| `ship.heavy_fighter` | `e1-heavy_fighter-1234` | 1 |
| `ship.cruiser` | `e1-cruiser-1234` | 1 |
| `ship.battleship` | `e1-battleship-7777` | 1 |
| `ship.recycler` | `e2-recycler-1234` | 2 |
| `ship.espionage_probe` | `e4-espionage_probe-7777` | 4 |

Masters : `art/masters/<id>/v1.png`, WebP dans `assets/visuels/`.

## Retours de l'utilisateur et leçons

- **Défense imposante** (lanceur de missiles) : à hauteur d'œil, la défense paraît petite face aux cailloux.
- **Premier plan flou** (laser léger, e1) : effet maquette, la défense rapetisse. Image nette partout (e2) : refusé,
  encore un plan serré. **Vue aérienne à distance avec minuscules véhicules et humains au pied** (e3) : retenue,
  passée dans la charte.
- **Contraste entre unités voisines** (laser lourd) : l'utilisateur voulait plus gros que le laser léger.
  L'agrandissement par collage (`comfy_grow.py`) puis passe d'harmonisation laisse des coutures ; refusé.
- **Canon de biais** (Gauss) : un canon vertical se lit comme une tour. Repartir de l'image avec « tilted at a
  45-degree angle … seen from the side » : le canon ne bascule qu'à partir de `denoise` 0,93. Le biais a été
  repris pour les défenses suivantes.
- **Petit bouclier** : ce n'est pas un dôme local mais un bouclier planétaire de surface porté par des tours
  d'énergie à perte de vue, bouclier au-dessus de l'horizon ; vue haute vers l'horizon (e3).
- **Grand bouclier** : la planète entière vue de l'espace, derrière une sphère de force violette. Une planète
  grise « vide » est refusée : océans sombres et reliefs à peine marqués (e2).
- **Sens du vol** (petit transporteur, recycleur) : le réacteur doit être à l'arrière, dans l'axe de la coque ;
  « exhaust streams straight backward along the hull's axis » corrige les propulseurs perpendiculaires.
  Un transporteur doit montrer des conteneurs.
- **Fond commun des vaisseaux** : l'assemblage (retouche de zone du vaisseau sur le fond d'une autre image) est
  refusé, coutures visibles. Le fond se décrit dans `site` (espace noir, halo doré à droite, horizon courbe
  au tiers bas, grand cratère) et se retrouve d'une seed à l'autre.
- **Sonde d'espionnage** : une coque profilée donne un vaisseau (e1, e3). Forme de satellite (corps, parabole,
  panneaux solaires, perches) retenue (e2), corps hexagonal un peu allongé plutôt que sphérique (e4).

## Incident

Un lancement interrompu par l'utilisateur a tout de même produit `e2-small_shield_dome` (4 pylônes) ; le
lancement suivant a réutilisé ce code avec un autre prompt. `run.json` contient donc deux entrées pour
`e2-small_shield_dome-7777` et `-1234`. La version « vue vers l'horizon » a été renommée `e3`.
