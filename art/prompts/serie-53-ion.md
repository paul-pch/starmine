# Série 53, ion : tube plus court, faisceau et couleur visibles, machine centrée

Retour de l'utilisateur sur la série 42 : le tuyau lui plaît mais il est trop long ; il veut mieux voir le faisceau et la couleur dans le
tuyau, et une machine bien centrée. Il n'a pas cité de seed : 7777 retenue par hypothèse, c'était la préférée de la revue. Série unique
pour cette technologie.

Qwen-Image-2.1, seed 7777, sauf retouche locale ci-dessous.

## Source

`source-short.png`, par script : tranche `x` de 330 à 560 retirée du tube, machine agrandie × 1,2 et recentrée, faisceau dessiné jusqu'au
bord droit, fond refait à partir du mur et du sol de l'original. Les raccords sont visibles : ils comptent sur la passe du modèle.

## Essais

| Code | Départ | Réglage | Résultat |
| --- | --- | --- | --- |
| `short-d75` | `source-short.png` | `denoise` 0,75 | socle cassé en deux : raté |
| `short-d90` | `source-short.png` | `denoise` 0,90 | machine courte et propre, faisceau net, mais tube couleur cuivre |
| `blue-d80` | `short-d90` | `denoise` 0,80, « no copper » | cuivre conservé : raté. Le modèle ne suit pas la négation |
| `tube-7777` | `blue-d80` | retouche locale du tube, seed 7777 | cuivre remplacé, trait bleu plus fin |
| `tube-4242` | `blue-d80` | retouche locale du tube, seed 4242 | tube rempli de bleu, le plus visible à 128 px |

Retouche : `tool/comfy_inpaint.py --box 300 425 530 510 --denoise 0.95`.

## Revue

Vues à environ 1024 px, en vignettes à 256 et 128 px. La machine est centrée à quelques % près. Le fond a dérivé au fil des passes : hall plus
clair avec un mur éclairé, sol brun chaud et reflet bleu marqué, moins neutre que les autres recherches. Le raccord à droite de la retouche se voit
un peu sur `tube-4242`, près de la bride centrale.

## Décision

L'utilisateur retient `raw-tube-4242_00001_.png`, sortie brute de la retouche, sans recomposition avec l'image de départ, et garde le fond tel
quel. Master : `art/masters/research.ion_technology/v1.png`.
