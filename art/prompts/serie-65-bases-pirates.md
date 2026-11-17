# Série 65 — bases pirates (pirate_base.<0-3>)

Catégorie `pirate_base` de la spec 11 : une image par base, dans l'ordre de `pirate_bases.list` (avant-poste,
repaire, forteresse, citadelle), 4:3, export 640 × 480, cartes des bases (onglet Flotte). Station en anneau,
d'après `scene.attack_won` (série 62). Charte `art/style/story_prompt.md`. Modèle Qwen-Image-2.1 (int8), 25 pas,
cfg 1, euler/simple, 1152 × 864. Prompts repris de la série 64 (séparée pour le format).

Demande de l'utilisateur (2026-11-17) : 3 propositions par base, seeds 4242, 7777 et 1234.

## Revue b1 (512 px)

| Base | 4242 | 7777 | 1234 |
| --- | --- | --- | --- |
| 0 avant-poste | anneau à rayons, modules rouille, un bras d'amarrage ; petit | anneau propre, deux chasseurs | anneau large et lourd, peu « modeste » |
| 1 repaire | anneau hérissé, rochers, chasseurs ; plus fourni que 0 | rochers, chasseurs ; proche de 0-7777 | grand anneau, rochers ; proche de 0-1234 |
| 2 forteresse | deux anneaux étagés, tourelles, la plus imposante | un anneau, projecteurs | un anneau, projecteurs nets |
| 3 citadelle | presque noire, flèche centrale, anneaux multiples ; très sombre | silhouette éclatée, flèche | trois anneaux, flèche, lumières rouges ; la plus lisible |

Constats : la station remplit toujours le cadre, donc la taille ne marque pas la progression ; elle passe par la
densité, les anneaux et la teinte. L'écart entre avant-poste et repaire reste faible. La citadelle presque noire
risque de mal passer en vignette (256 px). Hypothèse pour b2 si besoin : repère d'échelle (vaisseaux amarrés de
taille fixe) ou cadrage plus large pour l'avant-poste.

Décision : à l'utilisateur.

## Sélection (utilisateur, 2026-11-17)

- `pirate_base.0` : **b1-0-1234**
- `pirate_base.1` : **b1-1-1234**
- `pirate_base.2` : **b1-2-4242**
- `pirate_base.3` : **b1-3-4242**

Inscrites au registre en `validated` v1, WebP 640 × 480. Pas encore branchées (cartes des bases, onglet Flotte).
