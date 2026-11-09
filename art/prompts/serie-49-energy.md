# Série 49, energy : l'élément prend plus de place

Demande de l'utilisateur : garder `energy_technology-7777` de la série 42, que l'élément prenne plus de place. Série unique
pour cette technologie : les essais s'ajoutent à `serie-49-energy.json`.

Seed 7777, Qwen-Image-2.1.

## Source

`source-grow.png` : `tool/comfy_grow.py --box 345 205 720 765 --anchor 532 765 --scale 1.35`. Le cœur et sa colonne grandissent,
le socle reste en place. La colonne passe de 32 % à environ 43 % de la largeur, et de 52 % à 71 % de la hauteur.

## Revue

Vues en taille réelle et en vignette à 256 px.

| Code | Résultat |
| --- | --- |
| `grow-d45-energy_technology-7777` | sphère et arcs fidèles à l'original ; lisible à 256 px |
| `grow-d60-energy_technology-7777` | sphère plus lumineuse, arcs plus marqués, carter un peu redessiné ; lisible à 256 px |

Sur les 2 : le haut de la colonne frôle le bord de l'image sans être coupé, aucune coupure de montage visible.

## Décision

L'utilisateur retient `grow-d60-energy_technology-7777`. Master : `art/masters/research.energy_technology/v1.png`.
