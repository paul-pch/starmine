# Série 15 : réservoir de deutérium

Fichiers : fichier de série supprimé, prompts dans `run.json`, charte `art/style/base_prompt.md`. Qwen-Image-2.1, seeds
4242 et 7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 2 images. Prompts complets :
`run.json`, dans le dossier de sortie.

## Fiche

Réponses de l'utilisateur aux questions proposées : falaise en mer, silos à liquide lumineux.

```yaml
id: building.deuterium_tank.t1
sujet: dépôt de deutérium, une rangée de silos blindés à paroi vitrée, en bord de mer
élément clé: le liquide bleu-vert lumineux derrière le verre
cadrage: charte
interdit: liquide pris pour un autre matériau ; confusion avec le hangar de cristal
critères:
  - silos dominants, monumentaux
  - liquide lisible à 512 px
  - mer et falaise visibles
  - famille visible avec les deux autres dépôts
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

Dérogation à la charte : `site`, identique au synthétiseur retenu.

Hypothèse : le même silo vitré, avec un liquide et la mer, complète le trio de stockage et se relie au
synthétiseur.

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Silos dominants, monumentaux | moyen : la falaise prend le dessus | oui |
| Liquide lisible à 512 px | oui : lueur, sans niveau visible | oui : niveau visible |
| Mer et falaise visibles | oui | oui |
| Famille des dépôts | oui : proche du hangar de cristal | moyen : cuves plus basses |
| Mêmes critères sur les 2 seeds | non | non |

### Observations

- Hypothèse confirmée : le trio de stockage se lit, et le site relie le réservoir au synthétiseur.
- 7777 montre mieux qu'il s'agit d'un liquide et paraît plus massive.
- 4242 est plus proche des deux autres dépôts, mais plus petite dans l'image.

## Retour de l'utilisateur

« 42 est bien mais les silos sont trop petits » : la composition de 4242 convient, avec des silos plus
grands. Suite : série 16, avec des silos qui montent presque au sommet de la falaise.
