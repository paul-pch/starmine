# Série 09 : mine de cristal

Fichiers : `serie-09-crystal-mine.json`, charte `art/style/base_prompt.md`. Qwen-Image-2.1, seeds 4242
et 7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 2 images. Prompts complets : `run.json`,
dans le dossier de sortie.

## Fiche

Réponses de l'utilisateur aux questions proposées : portail dans une veine, cristaux bleu pâle, peu
de poussière et éclairé.

```yaml
id: building.crystal_mine.t1
sujet: bâtiment construit autour d'une entrée de galerie, entourée de cristaux géants
élément clé: les amas de cristal bleu pâle autour du portail, et le convoyeur
cadrage: charte
interdit: aspect abandonné ; cristal pris pour de la glace ou de la mousse
critères:
  - se distingue de la mine de métal à 512 px
  - cristaux lisibles, à facettes
  - bâtiment ancré dans la falaise
  - projecteurs visiblement allumés
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

Par rapport à la mine de métal retenue : le matériau et son `detail`, et l'état, avec moins de
poussière et « bright floodlights switched on » au lieu de « illuminated light strips ».

Hypothèse : la formule portail et convoyeur tient pour une autre ressource, et l'éclairage revient
avec ces mots. Les deux changements d'état ne sont pas séparés : on ne sait pas lequel ramène les
lumières.

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Distincte de la mine de métal à 512 px | oui | oui |
| Cristaux à facettes | oui | non : amas arrondis, entre glace et mousse |
| Bâtiment ancré dans la falaise | oui : portail intégré | moyen : posé dans la cavité |
| Projecteurs allumés | oui | oui, moins nombreux |
| Mêmes critères sur les 2 seeds | non | non |

### Observations

- Hypothèse confirmée pour la formule, et les lumières reviennent sur les 2 seeds.
- 4242 est nettement la meilleure et forme une paire avec la mine de métal 4242.
- Le massif de roche de 4242 semble s'avancer depuis la falaise, ce qui reste crédible.

## Retour de l'utilisateur

`crystal_mine-4242` est sélectionnée, en recherche et évaluation (licence Qwen).
