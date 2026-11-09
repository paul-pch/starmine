# Série 54, laser : un faisceau visible en miniature

Retour de l'utilisateur : `laser_technology-4242` de la série 42 lui plaît beaucoup, avec son émetteur, mais le laser est trop fin pour se voir en
miniature. Série unique pour cette technologie.

Qwen-Image-2.1. Retouche locale `tool/comfy_inpaint.py --box 470 355 880 475` : hors de la zone, l'image reste identique à l'originale, émetteur compris.

## Essais

| Code | Départ | Réglage | Résultat |
| --- | --- | --- | --- |
| `paint-4242` | faisceau dessiné sur l'original | `denoise` 0,70, seed 4242 | faisceau épais à cœur blanc, le plus visible à 128 px ; un peu tube néon |
| `paint-7777` | faisceau dessiné sur l'original | `denoise` 0,70, seed 7777 | un peu moins épais, plus propre, halo plus doux ; bien visible à 128 px |
| `pure-4242` | original sans dessin | `denoise` 0,95, seed 4242 | faisceau resté fin, pièce ajoutée sur la cible : raté |

Dessin du faisceau : halo rouge de 40 px et cœur clair de 12 px, de `x` 472 à 864 en `y` 414. Sans ce dessin, le modèle ne l'épaissit pas.

## Revue

Vues à environ 700, 256 et 128 px, sans vue en taille réelle. Défauts conservés de l'original : la cible flotte sans support, et l'émetteur porte de petites
marques qui pourraient évoquer du texte. Le faisceau n'éclaire ni l'émetteur ni le sol, car la retouche ne touche que sa zone.

## Itération sur `pure-4242`

Retour de l'utilisateur : le faisceau de `pure-4242` lui plaît, mais la pièce ajoutée sur la cible est étrange. `pure-4242` corrige en effet le faisceau
tout seul : la note « raté » ci-dessus venait de sa finesse par rapport à `paint`, et l'utilisateur préfère cette épaisseur.

Source `source-target.png`, par script : cible d'origine rétablie à droite de `x` 805, tronçon du faisceau de `pure-4242` recopié de 62 px vers la droite
jusqu'à la cible. Retouche `--box 790 365 905 465`, seed 4242.

| Code | Réglage | Résultat |
| --- | --- | --- |
| `target-d35-4242`, `target-d55-4242` | recopie par « plus clair », `denoise` 0,35 et 0,55 | rectangle clair autour du faisceau : raté |
| `clean-d55-4242` | recopie du rouge seul, `denoise` 0,55 | cœur blanc effacé, le modèle y met un nouveau cylindre : raté |
| `final-d35-4242` | recopie par luminosité, `denoise` 0,35 | faisceau continu jusqu'à la cible, impact rouge, plus de pièce ajoutée |

Sur `final-d35-4242`, vue au zoom sur la cible : petite trace sombre sur le mur au-dessus du faisceau et petit éclat clair au bord de la plaque, peu visibles.
La cible flotte toujours sans support.

## Miroir sur pied

Retour de l'utilisateur : la cible ne tient sur rien ; un petit miroir suffit. Retouche de `final-d35-4242`, `--box 800 320 990 780`, prompt « small round
polished mirror, held by a slim metal post that stands firmly on the steel test bench ».

| Code | Résultat |
| --- | --- |
| `mirror-d85-4242`, `mirror-d85-7777` | miroir rond, mais toujours sans pied : raté |
| `mirror-d95-7777` | miroir effacé, faisceau qui s'arrête dans le vide : raté |
| `mirror-d95-4242` | miroir sur tige posée sur le banc, mais rectangle clair de l'ancienne plaque derrière |
| `mirror-wall-4242`, `mirror-wall-7777` | retouche du rectangle à 0,95 : il revient, plus ou moins net : raté |
| `mirror-clean-4242` | rectangle recouvert par le mur voisin, puis passe à 0,45 : propre |

Sur `mirror-clean-4242` : un léger panneau plus clair reste visible derrière le miroir, il se lit comme un panneau du mur. Miroir lisible à 256 px, simple
point à 128 px, faisceau bien visible.

## Nouvelle génération

Retour de l'utilisateur : le miroir est trop bizarre et la reprise trop compliquée. Nouvelle image d'origine, sans départ : émetteur high-tech, laser en
perspective qui sort du cadre à droite, sans cible ni nouvel élément, cadrage centré sur l'émetteur et le laser. Seeds 4242 et 7777.

| Code | Résultat |
| --- | --- |
| `new-laser_technology-4242` | émetteur profilé à bandes lumineuses, faisceau épais qui sort à droite ; pas de marque ; lisible à 128 px |
| `new-laser_technology-7777` | émetteur plus petit sur bras fin ; marques sur le dessus qui évoquent des lettres |
| `new-low-laser_technology-4242` | quasi identique à `new-4242` : le changement de vue n'a presque rien fait |
| `new-low-laser_technology-7777` | émetteur plus compact, socle massif ; marques en forme de lettres sur le dessus |

Perspective faible sur les 4 : le faisceau part presque à l'horizontale, en légère montée, plus qu'il ne s'enfonce dans le hall.

## Décision

L'utilisateur retient `new-laser_technology-4242`, nouvelle génération d'origine. Master : `art/masters/research.laser_technology/v1.png`.
