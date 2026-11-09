# Série 14 : hangar de cristal

Fichiers : `serie-14-crystal-storage.json`, charte `art/style/base_prompt.md`, sans dérogation.
Qwen-Image-2.1, seeds 4242 et 7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 2 images.
Prompts complets : `run.json`, dans le dossier de sortie.

## Fiche

Réponses de l'utilisateur aux questions proposées : silos à hublots, blocs triés à facettes.

```yaml
id: building.crystal_storage.t1
sujet: dépôt de cristal, une rangée de silos blindés à paroi vitrée contre la falaise
élément clé: le cristal bleu pâle visible derrière le verre
cadrage: charte
interdit: confusion avec la mine de cristal ou l'usine de nanites
critères:
  - silos dominants, monumentaux
  - cristal reconnu à 512 px
  - famille visible avec le hangar de métal
  - distinct de la mine de cristal et de l'usine de nanites
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

Hypothèse : la paroi vitrée garde la famille des silos tout en distinguant le cristal.

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Silos dominants, monumentaux | oui | moyen : bas, coupés à droite |
| Cristal reconnu à 512 px | oui | oui |
| Famille du hangar de métal | oui | moyen : modules plutôt que silos |
| Distinct de la mine et des nanites | oui | oui |
| Blocs triés à facettes | moyen : petits éclats en vrac | non : grands éclats en vrac |
| Mêmes critères sur les 2 seeds | non | non |

### Observations

- Hypothèse confirmée sur 4242, qui forme une paire nette avec le hangar de métal retenu.
- Sur les 2 seeds, le cristal apparaît en vrac et non en blocs triés.

## Retour de l'utilisateur

`crystal_storage-4242` est sélectionnée.
