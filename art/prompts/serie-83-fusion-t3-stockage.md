# Série 83 — réacteur à fusion t3 (tempéré), stockage d'énergie

Reprise après refus de la série 82. Bloc demandé par l'utilisateur : bâtiment de stockage d'énergie relié à la
centrale par de gros câbles. Source `serie-81-fusion-t2/x2a-fusion_reactor-4242_00001_.png`, seed 4242. `denoise`
abaissé (0,92 à 0,95) : à 0,95 la série 82 déplaçait déjà l'anneau. Textes complets dans le JSON.

- z1 : hall blindé à cellules de condensateurs bleues, en bas à gauche, câbles posés au sol jusqu'à l'anneau ;
- z2 : rangées de batteries cylindriques bleues, coin bas gauche, câbles vers l'anneau.

| Code | `denoise` | t2 gardé | Bloc séparé, relié, à 128 px |
| --- | --- | --- | --- |
| z1a | 0,92 | oui : anneau, tours, falaise en place | oui : hall bleu à gauche, faisceau de câbles jusqu'à l'anneau |
| z1b | 0,94 | oui | oui : comme z1a |
| z1c | 0,95 | oui | oui : comme z1a |
| z2a | 0,93 | oui | partiel : câbles vers le bas du cadre, pas vers l'anneau |
| z2b | 0,95 | oui | partiel : comme z2a |

Constat : en abaissant le `denoise` sous 0,95, le t2 reste en place. Le lien par câbles se lit sur z1.

Décision : z2a retenue par l'utilisateur (2026-11-19).
