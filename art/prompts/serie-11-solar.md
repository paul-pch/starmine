# Série 11 : centrale solaire

Fichiers : `serie-11-solar.json`, charte `art/style/base_prompt.md`. Qwen-Image-2.1, seeds 4242 et
7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 2 images. Prompts complets : `run.json`, dans
le dossier de sortie.

## Fiche

Réponses de l'utilisateur aux questions proposées : sommet de falaise, tour et miroirs.

```yaml
id: building.solar_plant.t1
sujet: tour solaire colossale au sommet d'une falaise, entourée de miroirs
élément clé: la tour au sommet lumineux et les anneaux de miroirs
cadrage: vue haute, de loin, centrale entière
interdit: aspect usé ou abandonné ; panneaux à plat
critères:
  - tour et miroirs dominants, reconnus à 512 px
  - falaise visible sous le plateau
  - miroirs inclinés, tournés vers la tour
  - high-tech lisible
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

Dérogations à la charte : `view` et `site`, avec une vue haute sur le plateau au sommet.

Hypothèse : l'élément tour et miroirs donne une silhouette plus forte que les panneaux de la série 01,
et la falaise garde le lien avec la roche.

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Tour et miroirs dominants, reconnus à 512 px | oui | oui |
| Falaise visible sous le plateau | oui | oui |
| Miroirs inclinés vers la tour | moyen : rangées avant irrégulières | oui |
| High-tech lisible | oui | oui |
| Terrain gris neutre | non : plateau brun | non : plateau brun |
| Mêmes critères sur les 2 seeds | oui, sauf les miroirs | oui, sauf les miroirs |

### Observations

- Hypothèse confirmée : forte silhouette sur les 2 seeds.
- 4242 : tour plus haute, mais elle évoque un phare.
- 7777 : l'anneau de miroirs est très net, presque graphique.
- Le plateau tire vers le brun, sans la roche grise des autres images. À regarder si cela gêne pour le
  set.

## Retour de l'utilisateur

`solar_plant-7777` est sélectionnée, en recherche et évaluation (licence Qwen). Plateau brun laissé
tel quel.
