# Série 73 — synthétiseur de deutérium, palier t2 (tempéré)

`building.deuterium_synthesizer.t2.temperate`, depuis le t1 validé (`serie-10-deuterium/deuterium_synthesizer-4242`),
seed 4242, `site` « Mer » tempéré du t1.

## Fiche (Q/R avec l'utilisateur, 2026-11-17)

- t2 : une deuxième sphère sous pression, bloc séparé, reliée à la première ;
- t3 : station de pompage en mer au premier plan, tours d'aspiration et conduites vers les sphères.

## s1 — 2ᵉ sphère à gauche

| Code | `denoise` | t1 gardé | Bloc en plus à 128 px | Remarques |
| --- | --- | --- | --- | --- |
| s1a, s1b | 0,95 / 0,96 | partiel : une seule sphère, grappe simplifiée | **non** | à gauche il n'y a que la mer : rien n'y est posé |
| s1c | 0,97 | non | **non** | plateforme en pleine mer |

## s2 — 2ᵉ sphère à droite, sur la plateforme, ou deux sphères côte à côte

| Code | Formulation | `denoise` | t1 gardé | Bloc en plus à 128 px |
| --- | --- | --- | --- | --- |
| s2a | à droite | 0,92 | partiel | **non** |
| s2b | à droite | 0,95 | partiel : sphère, falaise et plateforme reconnaissables, grappe simplifiée | oui : 2ᵉ sphère nette à droite |
| s2c | côte à côte | 0,95 | non : deux sphères plus petites | oui |

Constat : ce bâtiment dérive dès 0,92 (la grappe de petites sphères du t1 disparaît). Le bloc doit être placé sur la
plateforme, côté falaise.

Décision : s2b retenue par l'utilisateur (2026-11-17).
