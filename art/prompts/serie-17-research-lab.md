# Série 17 : laboratoire de recherche

Fichiers : `serie-17-research-lab.json`, charte `art/style/base_prompt.md`. Qwen-Image-2.1, seeds 4242
et 7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 2 images. Prompts complets : `run.json`,
dans le dossier de sortie.

## Fiche

Réponses de l'utilisateur aux questions proposées : sommet de falaise, grand dôme vitré.

```yaml
id: building.research_lab.t1
sujet: complexe de recherche au sommet d'une falaise, autour d'un immense dôme de verre
élément clé: le dôme, avec des instruments visibles, et l'anneau d'antennes
cadrage: vue haute, de loin, complexe entier
interdit: aspect usé ou abandonné
critères:
  - dôme dominant, reconnu à 512 px
  - falaise visible sous le plateau
  - high-tech lisible
  - instruments visibles dans le dôme
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

Dérogations à la charte : `view` et `site`, comme la centrale solaire, avec en plus « dark neutral
grey rock » pour le plateau, resté brun en série 11.

Hypothèse : le dôme vitré reprend la réussite de la série 01 dans la charte actuelle.

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Dôme dominant, reconnu à 512 px | oui | oui |
| Falaise visible | oui | oui |
| High-tech lisible | oui | oui |
| Instruments visibles | moyen : structures peu nettes | moyen : lueur chaude, peu nette |
| Anneau d'antennes | moyen : éparses | oui |
| Plateau gris | moyen : sombre, légèrement brun | moyen : légèrement brun |
| Mêmes critères sur les 2 seeds | oui, sauf antennes | oui, sauf antennes |

### Observations

- Hypothèse confirmée : très forte silhouette sur les 2 seeds.
- 7777 occupe mieux l'image, et ses antennes entourent bien le dôme.
- 4242 est plus aérienne, avec un dôme élégant mais plus de falaise que de bâtiment.

## Retour de l'utilisateur

`research_lab-7777` est sélectionnée, en recherche et évaluation (licence Qwen).
