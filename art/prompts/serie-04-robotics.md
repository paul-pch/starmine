# Série 04 : usine de robots

Suite de la série 03, décidée par l'utilisateur. Fichiers : `serie-04-robotics.json`, charte
`art/style/base_prompt.md`, inchangée. Qwen-Image-2.1, seeds 4242 et 7777, 1024 × 1024, 25 passes,
cfg 1, `euler` / `simple`. 2 images. Prompts complets : `run.json`, dans le dossier de sortie.

Critères ratés en série 03 : sujet dominant, monumental, adossé à la roche, aucun décor terrestre.

## Essai 1

Un seul changement : le `subject`, et son `detail` pour rester cohérent. La chaîne longue le long de
la façade devient une structure haute à étages, ancrée dans la falaise.

Hypothèse : empiler les étages donne de la hauteur et accroche l'usine à la falaise. Le critère du
décor terrestre n'est pas visé : les voitures peuvent rester.

### Notes proposées par Claude

2 images vues en taille réelle ; planche à 512 px non regardée. L'utilisateur n'a pas encore noté.
Chaque case donne 4242 / 7777.

| Critère | Résultat |
| --- | --- |
| Sujet dominant | oui / oui |
| Adossé à la roche | oui / oui |
| Fonction d'usine visible | oui / oui : bras visibles à chaque étage |
| Monumental | moyen / moyen : 5 ou 6 étages à l'échelle des robots |
| Aucun décor terrestre | non / non : voitures actuelles |

### Observations

- Hypothèse confirmée sur les 2 seeds : hauteur et ancrage obtenus.
- 4242 : le mieux intégré à la falaise, avec un plateau de sortie vivant.
- 7777 : la file de robots est très lisible, mais ils ressemblent à des androïdes et la tour évoque
  un immeuble.
- Les robots sont gros par rapport aux étages, ce qui limite l'effet monumental.

## Retour de l'utilisateur

`robotics_factory-4242` de cette série remplace celle de la série 03 dans la sélection provisoire. Les voitures restent : elles ne se verront pas sur téléphone.

Sélection de la famille Construction : `serie-03-construction/shipyard-4242`,
`serie-03-construction/nanite_factory-4242`, `serie-04-robotics/robotics_factory-4242`.

Suite décidée : les autres bâtiments, un par un, avec des questions et réponses proposées pour
définir chaque fiche.
