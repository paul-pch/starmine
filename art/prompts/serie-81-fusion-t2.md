# Série 81 — réacteur à fusion t2 (tempéré)

t2 = t1 tempéré + deux tours de refroidissement à droite (choix de l'utilisateur). Source
`serie-12-fusion/fusion_reactor-4242_00001_.png`, seed 4242 ; `view`, `site`, `state` de la charte. Textes complets
dans le JSON.

- x1 : « On the right side of the frame, at the foot of the cliff … two giant cooling towers releasing thick white
  plumes of steam » ;
- x2 : « In the bottom right corner of the frame, in front of the cliff … two giant hyperboloid cooling towers, each as
  tall as the ring ».

| Code | `denoise` | t1 gardé | Bloc séparé à 128 px |
| --- | --- | --- | --- |
| x1a | 0,95 | partiel : anneau plus petit, décalé à gauche | partiel : une tour collée à l'anneau, l'autre derrière |
| x1b | 0,96 | partiel : comme x1a | partiel : comme x1a |
| x1c | 0,97 | partiel : anneau à deux étages | oui : deux tours derrière l'anneau |
| x2a | 0,95 | partiel : anneau plus petit, falaise et sol gardés | oui : deux tours nettes à droite |
| x2b | 0,97 | partiel : anneau à étages | oui : deux tours au premier plan |

Constat : l'anneau rétrécit sur tous les essais pour faire place aux tours.

Décision : x2a retenue par l'utilisateur (2026-11-19).
