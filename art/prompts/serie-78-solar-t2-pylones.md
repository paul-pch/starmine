# Série 78 — centrale solaire t2 (tempéré), poste haute tension

Reprise du t2 après refus de la série 76 (cuves = stockage, pas énergie). Bloc choisi par l'utilisateur : poste haute
tension et pylônes géants. Source `serie-11-solar/solar_plant-4242_00001_.png`, seed 4242 ; `view`, `detail`, `site`
du t1. Textes complets dans le JSON.

- v1 : poste à droite, ligne de pylônes géants à câbles lumineux ;
- v2 : poste en bas à droite, arcs électriques bleu-blanc, ligne de pylônes.

| Code | `denoise` | t1 gardé | Bloc en plus à 128 px |
| --- | --- | --- | --- |
| v1a | 0,95 | partiel : plateau et falaise gardés, tour lisse, champ de miroirs plus large | oui : pylône et poste à droite |
| v1b | 0,96 | partiel : comme v1a | oui |
| v1c | 0,97 | non : tour à base évasée | oui : pylône le plus grand |
| v2a | 0,95 | partiel : comme v1a | oui : pylônes, poste et arcs bleus |
| v2b | 0,97 | non : vue plus haute, tour à base évasée | oui |

Décision : v2a retenue par l'utilisateur (2026-11-17).
