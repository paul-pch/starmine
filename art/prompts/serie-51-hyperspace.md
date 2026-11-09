# Série 51, hyperspace : garder le sens une fois minifié

Demande de l'utilisateur : la 7777 de la série 42 lui plaît, mais la texture peut se perdre une fois minifiée et l'image se comprendre
moins bien. Il demande des avis et plusieurs tests. Série unique pour cette technologie.

Seed 7777, Qwen-Image-2.1. Toutes les variantes partent de `serie-42-recherches/hyperspace_drive-7777_00001_.png`, `denoise` 0,90 :
l'anneau reste, seul le contenu change.

## Revue

Comparaison à 512, 256 et 128 px, avec l'original. Aucune image vue en taille réelle.

| Code | À 512 px | À 128 px |
| --- | --- | --- |
| original 7777 | lentille ou hublot reflétant le hall | hublot, le sens se perd : crainte confirmée |
| `streaks` | rayons convergents, effet de saut | traits fins qui s'effacent, peut évoquer une roue à rayons |
| `vortex` | spirale d'énergie nette | spirale encore évidente, la plus lisible |
| `singularity` | sphère noire et lumière courbée, forte | petit point noir, peut évoquer un œil |
| `portal` | espace et nébuleuse, idée très claire | intérieur sombre, trait de nébuleuse seul |

Avis : `vortex` est le seul à garder forme et contraste à 128 px, et il s'éloigne du `plasma`. Limite : à petite taille, il peut évoquer
une turbine. La lumière reste plutôt gris-blanc que bleu-blanc sur les 4. Le hall s'est un peu éclairci sur les 4.

## Décision

L'utilisateur retient `vortex-hyperspace_drive-7777`, sans renforcer le bleu. Master : `art/masters/research.hyperspace_drive/v1.png`.
