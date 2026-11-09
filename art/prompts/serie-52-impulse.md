# Série 52, impulse : faut-il grossir ?

L'utilisateur juge `impulse_drive-7777` de la série 42 presque parfaite et hésite à la grossir un peu. Série unique pour cette technologie.

Seed 7777, Qwen-Image-2.1.

## Source

`source-grow.png` : `tool/comfy_grow.py --box 170 340 900 695 --anchor 542 695 --scale 1.2`. Le moteur passe de 61 % à environ 73 % de la
largeur de l'image, le socle reste en place.

## Revue

Comparaison avec l'original à environ 700, 256 et 128 px, sans vue en taille réelle.

| Code | Résultat |
| --- | --- |
| original 7777 | métal lisse ; à 128 px, moteur lisible mais plus petit, beaucoup de vide au-dessus |
| `grow-d45-impulse_drive-7777` | anneaux et lueur proches de l'original, un peu plus usés ; gain net à 128 px |
| `grow-d60-impulse_drive-7777` | anneaux redessinés, métal plus rugueux, moins proche de l'original ; même gain à 128 px |

Avis : grossir vaut la peine pour la vignette. `grow-d45` garde le mieux une image déjà presque parfaite. Le hall s'est un peu éclairci sur les 2.

## Décision

L'utilisateur retient `grow-d45-impulse_drive-7777`. Master : `art/masters/research.impulse_drive/v1.png`.
