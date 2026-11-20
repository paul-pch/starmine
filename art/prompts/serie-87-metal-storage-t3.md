# Série 87 — hangar de métal t3 (tempéré)

t3 = t2 validé (série 86, m3a) + porte de coffre-fort ronde encastrée haut dans la falaise, au-dessus des silos
(choix de l'utilisateur : seule place libre). Source `serie-86-metal-storage-t2/m3a-metal_storage-4242_00001_.png`,
seed 4242. Textes complets dans le JSON.

- v1 : haut du cadre, au-dessus des silos, « wider than two silos », entrouverte sur des lingots ;
- v2 : haut gauche, avec rampe.

| Code | `denoise` | t2 gardé | Bloc séparé à 128 px |
| --- | --- | --- | --- |
| v1a | 0,93 | oui | oui : porte ronde ouverte au-dessus des silos, lingots dedans |
| v1b | 0,95 | oui | oui : comme v1a |
| v1c | 0,97 | non : silos bas, grande aire et portique | oui |
| v2a | 0,95 | oui | partiel : porte petite, en haut à gauche |
| v2b | 0,97 | non : 3 silos à dôme | oui |

Constat : la porte reste plus étroite que deux silos, mais se lit en vignette.

Décision : v1b retenue par l'utilisateur (2026-11-19).
