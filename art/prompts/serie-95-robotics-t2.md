# Série 95 — usine de robots t2 (tempéré)

Génération déléguée (critère absolu : rien ne change du t1). Bloc choisi : second hall d'assemblage bas, porte ouverte
éclairée, robots qui en sortent (à gauche, sur la plaine). Source `serie-04-robotics/robotics_factory-4242_00001_.png`,
seed 4242. Textes complets dans le JSON.

| Code | Bloc | `denoise` | t1 gardé | Bloc lisible à 128 px |
| --- | --- | --- | --- | --- |
| r1a | hall à gauche | 0,88 | oui | non : quelques caisses |
| r1b | idem | 0,90 | oui : tour et ses 4 étages vitrés | oui : hall éclairé à gauche |
| r1c | idem | 0,92 | oui | oui |
| r2a à r2c | hangar d'essai à toit courbe | 0,88 à 0,92 | oui | oui |

Les robots du t1 deviennent moins nombreux et plus grands sur tous les essais.

Décision : r1b retenue (plus bas `denoise` qui ajoute le bloc).
