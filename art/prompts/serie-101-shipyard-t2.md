# Série 101 — chantier spatial t2 (tempéré)

Génération déléguée (critère absolu : rien ne change du t1). Source `serie-18-shipyard/B-shipyard-4242_00001_.png`
(variante B, `state` « spotlessly clean »), seed 4242, `view` et `site` du t1. Textes complets dans le JSON.

| Code | Bloc | `denoise` | t1 gardé | Bloc lisible à 128 px |
| --- | --- | --- | --- | --- |
| y1a à y1c | hangar d'assemblage, rive haut gauche | 0,88 à 0,92 | non : grue de gauche remplacée par le hangar | oui |
| y2a | hangar, rive droite | 0,88 | partiel : grues restylées | un 2ᵉ vaisseau posé sur la rive |
| y2b, y2c | idem | 0,90 / 0,92 | partiel : une grue de droite remplacée | oui : hangar ouvert avec vaisseau |
| y3a | idem | 0,84 | partiel : grues restylées | vaisseau posé, petit |
| y3b | idem | 0,86 | partiel : grues restylées (même dérive qu'à 0,84) | oui : 2ᵉ vaisseau blanc posé sur la rive droite |

Constat : à partir de cette source, le cadrage se resserre et les grues changent de style quel que soit le `denoise`
(0,84 à 0,92). y3b garde le plus d'éléments : cale, vaisseau principal, rives, véhicules.

Décision : y3b retenue.
