# Série 74 — synthétiseur de deutérium t3 (tempéré)

Fiche : t3 = t2 validé (série 73, s2b) + une station de pompage en mer, au premier plan (choix de l'utilisateur).
Méthode : [[tier-adds-visible-block]], source `serie-73-deuterium-t2/s2b-deuterium_synthesizer-4242_00001_.png`,
seed 4242, Qwen-Image-2.1.

`detail` et `site` : identiques à la série 73.

## p1 — station en bas du cadre

Subject : A deuterium synthesis plant built around one cluster of giant spherical pressure tanks. On the right side of the frame, on the platform against the cliff, stands a second large and clearly separate block: a second giant spherical pressure tank as large as the first, with its own supports, linked to the first by thick pipes. In the bottom of the frame, in the foreground and larger than the main building, a third massive and clearly separate block: a huge offshore pumping station standing in the sea on thick steel pylons, with giant pump housings and wide intake pipes plunging into the waves, linked to the platform by a heavy pipe bridge.

## p2 — station dans le coin bas gauche

Subject : A deuterium synthesis plant built around one cluster of giant spherical pressure tanks. On the right side of the frame, on the platform against the cliff, stands a second large and clearly separate block: a second giant spherical pressure tank as large as the first, with its own supports, linked to the first by thick pipes. In the bottom left corner of the frame, in the foreground and larger than the main building, a third massive and clearly separate block: a huge offshore pumping station standing in the sea on thick steel pylons, with giant pump housings and wide intake pipes plunging into the waves, linked to the platform by a heavy pipe bridge.

## Revue

| Code | `denoise` | t2 gardé | Bloc en plus à 128 px |
| --- | --- | --- | --- |
| p1a | 0,92 | oui : quai au ras de l'eau, véhicules, 2 sphères | oui : station sur pylônes à gauche, taille proche des sphères |
| p1b | 0,95 | non : le quai devient une corniche haute | oui |
| p1c | 0,97 | non : corniche haute, sphères plus petites | oui, station plus grande |
| p2a | 0,95 | non : corniche haute | oui |
| p2b | 0,97 | non : corniche haute | oui, station la plus grande |

Constat : la mer à gauche accepte un bloc posé sur pylônes (contrairement à une sphère en série 73). À partir de 0,95
le quai du t2 se transforme en falaise.

Décision : p1a retenue par l'utilisateur (2026-11-17).
