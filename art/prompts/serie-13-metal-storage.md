# Série 13 : hangar de métal

Fichiers : `serie-13-metal-storage.json`, charte `art/style/base_prompt.md`, sans dérogation.
Qwen-Image-2.1, seeds 4242 et 7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 2 images.
Prompts complets : `run.json`, dans le dossier de sortie.

## Fiche

Réponses de l'utilisateur aux questions proposées : silos géants, lingots empilés. L'utilisateur a
préféré les silos aux alvéoles recommandées par Claude.

```yaml
id: building.metal_storage.t1
sujet: dépôt de métal, une rangée de silos blindés géants contre la falaise
élément clé: les piles de lingots visibles à la base des silos
cadrage: charte
interdit: effet d'entrepôt ; confusion avec le cylindre de nanites
critères:
  - silos dominants, monumentaux
  - lingots reconnus à 512 px
  - silos ancrés à la falaise
  - se distingue de l'usine de nanites
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

Hypothèse : montrer le produit stocké suffit à reconnaître un dépôt de métal sans effet d'entrepôt.

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Silos dominants, monumentaux | oui | moyen : plus petits, rangée coupée à droite |
| Lingots reconnus à 512 px | oui, avec un effet d'escalier | moyen : proches de caisses |
| Ancrés à la falaise | oui | oui |
| Distinct de l'usine de nanites | oui | oui |
| Mêmes critères sur les 2 seeds | non | non |

### Observations

- Hypothèse confirmée : ce sont bien des silos de stock, sans effet d'entrepôt.
- 4242 est nettement la meilleure, avec 4 silos très imposants.

## Retour de l'utilisateur

`metal_storage-4242` est sélectionnée, en recherche et évaluation (licence Qwen).
