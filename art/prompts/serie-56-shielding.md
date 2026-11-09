# Série 56, shielding : un bouclier plus visible

Demande de l'utilisateur : garder `shielding_technology-7777` de la série 42, avec un bouclier plus visible. Série unique, seed 7777.

| Code | Départ | `denoise` | Résultat |
| --- | --- | --- | --- |
| `d75` | original | 0,75 | bord du dôme plus net, intérieur encore transparent |
| `d85` | original | 0,85 | bord plus vif, intérieur transparent |
| `tint-d90` | `d85` | 0,90 | dôme teinté de violet, motif hexagonal léger |
| `tint-d95` | `d85` | 0,95 | dôme le plus visible : teinte, motif hexagonal, anneau lumineux au sol ; le plus lisible à 128 px |

Défaut conservé de l'original sur les 4 : le tir est à l'intérieur du dôme et touche la machine, au lieu de s'arrêter sur la surface. Une lumière
de plafond apparaît en haut à droite sur `tint-d95`.

## Perspective

Retour de l'utilisateur sur `tint-d90` : le bouclier est derrière la machine, pas autour. Source `source-front.png`, par script depuis `tint-d90` : voile
violet à 22 % sur toute la surface du dôme, machine comprise, et arc avant de l'anneau de base peint sur le banc. Prompt : machine vue à travers la face
avant du dôme, anneau de base tout autour.

| Code | `denoise` | Résultat |
| --- | --- | --- |
| `front-d55` | 0,55 | machine vue à travers le voile violet, anneau avant sur le banc ; voile un peu plat |
| `front-d70` | 0,70 | dôme mieux intégré, anneau avant net sur le banc ; le dôme englobe la machine |

Le tir reste à l'intérieur du dôme, comme sur l'original.

## Décision

L'utilisateur retient `front-d55-shielding_technology-7777`, avec le tir à l'intérieur du dôme. Master : `art/masters/research.shielding_technology/v1.png`.
