# Série 71 — mine de cristal, palier t3 (tempéré)

`building.crystal_mine.t3.temperate`, depuis le t2 validé (`serie-70-crystal-mine-t2/r1a`), seed 4242. Fiche :
série 70 (bloc encastré dans la falaise à gauche, avec sa galerie, au premier plan et plus gros que le bâtiment
principal).

## k1 — formulation du t3 de la mine de métal (g3c)

| Code | `denoise` | t2 gardé | Bloc en plus à 128 px | Remarques |
| --- | --- | --- | --- | --- |
| k1a-crystal_mine-4242 | 0,95 | oui | **non** : façade lointaine à gauche | |
| k1c-crystal_mine-4242 | 0,96 | oui | **non** : idem | |
| k1b-crystal_mine-4242 | 0,97 | **non** : portail et bâtiment principal remplacés | oui : énorme bloc à gauche | dérive |

Constat : à gauche, le t2 montre une plaine qui s'éloigne ; le modèle y pose le bloc au loin. Le seuil entre 0,96
et 0,97 est brutal. Hypothèse : ancrer le bloc dans le coin bas gauche du cadre.

## k2 — bloc ancré dans le coin bas gauche

« Close to the viewer on the left, its base filling the bottom-left corner of the frame and as tall as the main
building, a third massive and clearly separate block: a huge multi-level mining building carved into a rocky
outcrop of the mountain, with a second wide tunnel mouth at its base, surrounded by huge clusters of pale blue
crystal. »

| Code | `denoise` | t2 gardé | Bloc en plus à 128 px | Remarques |
| --- | --- | --- | --- | --- |
| k2a-crystal_mine-4242 | 0,96 | oui | moyen : bloc bas au premier plan, galerie et cristaux | bas et trapu, peu « dans la montagne » ; le convoyeur y aboutit |
| k2b-crystal_mine-4242 | 0,97 | partiel : raffinerie gardée, bâtiment principal redessiné | oui, net : bloc haut sur un éperon, galerie à sa base | trois blocs bien séparés |

Décision : à l'utilisateur.

## Sélection (utilisateur, 2026-11-17)

`building.crystal_mine.t3.temperate` : **k2b-crystal_mine-4242** (`denoise` 0,97), `validated` v1.
