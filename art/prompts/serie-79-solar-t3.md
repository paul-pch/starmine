# Série 79 — centrale solaire t3 (tempéré)

t3 = t2 validé (série 78, v2a) + salle des turbines au premier plan (choix de l'utilisateur). Source
`serie-78-solar-t2-pylones/v2a-solar_plant-4242_00001_.png`, seed 4242 ; `view`, `detail`, `site` du t1.

- w1 : salle des turbines en bas du cadre, plus grande que le poste ;
- w2 : même salle, coin bas gauche, au bord de la falaise.

| Code | `denoise` | t2 gardé | Bloc séparé à 128 px |
| --- | --- | --- | --- |
| w1a | 0,95 | oui | non : la salle fusionne avec le poste |
| w1b | 0,96 | oui | non : comme w1a |
| w1c | 0,97 | non : vue plus haute, tour à base évasée, miroirs immenses | oui : salle à gauche |
| w2a | 0,95 | oui : tour, pylônes, poste et arcs gardés | oui : salle à gauche, éclairée de bleu |
| w2b | 0,97 | non : comme w1c | oui |

Décision : w2a retenue par l'utilisateur (2026-11-19).
