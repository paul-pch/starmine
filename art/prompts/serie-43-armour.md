# Série 43, armour : agrandir le blindage

Demande de l'utilisateur : garder `armour_technology-7777` de la série 42 et agrandir un peu le blindage, pour
qu'il se voie bien une fois minifié. Règle valable pour les images suivantes.

Seed 7777, Qwen-Image-2.1. Le blindage occupait 54 % de la largeur de l'image.

## Sources

Préparées par script depuis l'image de la série 42, dans `~/ComfyUI/output/starmine_test/serie-43-armour/` :

- `source-zoom.png` : recadrage `(110, 220, 910, 1020)` agrandi à 1024 px. Toute l'image grandit, le socle est coupé
  sur les côtés. Blindage à environ 69 % de la largeur.
- `source-grow.png` : zone `(215, 340, 805, 700)` agrandie × 1,25, ancrée en `(510, 700)` au bas de la plaque et
  fondue sur 24 px. Seul le blindage grandit, le socle reste entier. Blindage à environ 67 % de la largeur.

## Prompt

Sujet réécrit pour décrire ce que montre l'image : la presse demandée en série 42 n'y figure pas et ne doit pas
apparaître. Ce changement s'ajoute à l'agrandissement.

## Revue

Les 4 images vues sur une planche réduite à environ 900 px par image, et en vignette à 256 px.

| Code | Ressemblance à la 7777 | Lisible à 256 px | Remarque |
| --- | --- | --- | --- |
| `zoom-d30` | panneaux très proches | oui | socle coupé, hall presque hors cadre |
| `grow-d30` | la plus proche, panneaux conservés | oui | sol et plaque un peu plus grenus |
| `grow-d45` | proche, quelques détails changent | oui | image plus propre, hall plus détaillé |
| `grow-d60` | panneaux redessinés | oui | ce n'est plus tout à fait la même plaque |

Aucune coupure de montage visible à cette taille.

## Décision

L'utilisateur retient `grow-d60-armour_technology-7777`, alors que la revue conseillait `grow-d30` pour sa fidélité :
il préfère que l'élément central, et non le socle, prenne plus de place. Master : `art/masters/research.armour_technology/v1.png`.
