# Série 96 — usine de robots t3 (tempéré)

Génération déléguée (critère absolu : rien ne change du t2). Source
`serie-95-robotics-t2/r1b-robotics_factory-4242_00001_.png`, seed 4242. Textes complets dans le JSON.

| Code | Bloc | `denoise` | t2 gardé | Bloc lisible à 128 px |
| --- | --- | --- | --- | --- |
| g1a à g1c | portique d'assemblage d'un robot géant, bas droit | 0,88 à 0,92 | non : le robot géant entre dans la porte de la tour | non séparé |
| g1d | idem | 0,94 | non : annexe de droite remplacée, cadrage resserré | oui |
| g2a, g2b | portique, bas gauche | 0,90 / 0,92 | non : robot dans la porte de la tour | non |
| g2c | idem | 0,94 | non : hall reculé et réduit | oui |
| g3a | hangar creusé dans la falaise, à droite de la tour, robot géant éclairé | 0,90 | oui : tour, hall, annexe, véhicules | oui : niche éclairée |
| g3b | idem | 0,92 | oui | oui |
| g3c | idem | 0,94 | non : annexe remplacée | oui |

Constat : le flanc de falaise à droite de la tour est la seule place libre ; le sol attire le robot dans la tour.

Décision : g3a retenue.
