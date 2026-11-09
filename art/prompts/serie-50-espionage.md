# Série 50, espionage : plus grand, rayons verts conservés

Demande de l'utilisateur : garder `espionage_technology-7777` de la série 42, un peu plus grand dans l'image, en gardant bien
les rayons verts. Série unique pour cette technologie.

Seed 7777, Qwen-Image-2.1.

## Source

`source-grow.png` : `tool/comfy_grow.py --box 130 390 880 760 --anchor 700 760 --scale 1.35`. La sonde, son support et le faisceau
grandissent ensemble. La sonde passe de 30 % à environ 41 % de la largeur de l'image.

## Revue

Vue en taille réelle et en vignette à 256 px.

| Code | Résultat |
| --- | --- |
| `grow-d60-espionage_technology-7777` | même sonde, plus grande ; faisceau conservé et plus marqué, jusqu'au bord gauche ; lisible à 256 px |

À vérifier : une petite plaque claire sur le dessus de la sonde porte des marques qui pourraient évoquer du texte. Le socle a été
un peu redessiné. Aucune coupure de montage visible.

## Décision

L'utilisateur retient `grow-d60-espionage_technology-7777`. Master : `art/masters/research.espionage_technology/v1.png`.
