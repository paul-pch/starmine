# Série 31 : centrale solaire, froid et chaud

Fichiers : `serie-31-solar.json`, charte `art/style/base_prompt.md`, inchangée. Qwen-Image-2.1, seed 4242,
source `serie-11-solar/solar_plant-4242`, `denoise` 0,90, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`.
2 images. Fiche : `serie-19-temperature.md`. Les `site` sont ceux du labo, retenus sur le même type de plateau.

## Notes proposées par Claude

2 images vues en taille réelle et comparées à la source. L'utilisateur n'a pas encore noté.

| Critère | Froid | Chaud |
| --- | --- | --- |
| Tour et falaise en place | oui | oui |
| Climat lisible | oui, surtout sur la falaise | oui |
| Champ de miroirs proche du t1 | moyen : plus dense, sort du cadre | oui, plus dense et plus régulier |
| Aucune matière ambiguë | oui | moyen : colonne de fumée grande et proche |

## Observations

- Froid : la neige couvre le plateau devant le champ, mais le fond reste en partie brun.
- Chaud : la lave est discrète, en bas à droite et à gauche sur la falaise.

## Retour de l'utilisateur

- `d90-solar_plant_hot-4242` est retenue.
- Froid refusé : trop de panneaux, trop chargé pour un smartphone.

## Essai 2, froid

Demande de l'utilisateur : corriger dans cette série. `serie-31-solar.json` contient désormais le nouveau
`detail` du froid : peu d'anneaux, très espacés, neige entre eux, champ à l'intérieur du cadre. Une seule image
est visée, mais le script régénère toute la série : le chaud sort identique, même md5, en `_00002_`.

Hypothèse : décrire un champ clairsemé retire des miroirs à 0,90.

Résultat : raté. Le champ reste aussi dense, et il forme un bloc continu qui sort du cadre. Le premier froid reste
dans le dossier, en `_00001_`.

## Essai 3, froid

Série 32, `serie-32-solar-cold.json` : même prompt, `denoise` 0,80 et 0,85.

Hypothèse : moins de transformation garde les miroirs espacés du t1.

| `denoise` | Miroirs | Neige |
| --- | --- | --- |
| 0,80 | oui : espacés, champ dans le cadre | non : sol brun, un peu de glace sur la falaise |
| 0,85 | non : anneaux denses, mais champ dans le cadre | moyen : givre |

Le prompt seul ne donne pas à la fois les miroirs du t1 et la neige. Prochain levier proposé : neiger le paysage en
protégeant le champ de miroirs par un masque. Accepté par l'utilisateur.

## Essai 4, froid, masque

Trois étapes depuis `serie-11-solar/solar_plant-4242`, seed 4242, avec le prompt du froid de la série 31 :

1. Série 33, `tool/comfy_inpaint.py`, `denoise` 0,90, zones protégées : `--keep-box 0 0 1024 438`,
   `--keep-box 440 438 585 600`, `--keep-ellipse 500 596 505 122`. Miroirs intacts et devant enneigé, mais sol
   brun autour du champ et sous celui-ci.
2. Série 33, `tool/snow_ground.py`, seuil haut 452 : recolore le sol brun en neige. Seul, le rendu est artificiel,
   avec des miroirs brouillés et des taches orange.
3. Série 34, `tool/comfy_inpaint.py`, `denoise` 0,60, ciel protégé : `--keep-box 0 0 1024 438`. Harmonise le tout.

Résultat proposé : `serie-34-solar-cold-harmonise/solar_plant_cold-4242.png`.

- Neige sur tout le sol, champ entier dans le cadre, plus aéré que les essais à 0,90.
- Ciel et haut de la tour identiques au t1.
- Défauts : miroirs plus gris et moins brillants que le t1 ; rangs avant un peu confus au zoom ; petites
  structures et falaise modifiées par la dernière passe.

Retour de l'utilisateur : `serie-33-solar-cold-masque/raw-solar_plant_cold-4242` est retenue, c'est-à-dire la
sortie directe de l'étape 1, sans recoloration ni harmonisation, malgré le sol brun autour du champ.
