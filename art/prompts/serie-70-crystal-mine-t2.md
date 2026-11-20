# Série 70 — mine de cristal, palier t2 (tempéré)

`building.crystal_mine.t2.temperate`, depuis le t1 validé (`serie-09-crystal-mine/crystal_mine-4242`), seed 4242.
Méthode de la mine de métal (séries 67 à 69, `tier-adds-visible-block`).

## Fiche (Q/R avec l'utilisateur, 2026-11-17)

- t2 : raffinerie de cristal à droite, bâtiment séparé à parois vitrées, cristaux taillés bleus lumineux ;
- t3 : bloc encastré dans la falaise à gauche, avec sa galerie, au premier plan et plus gros que le bâtiment
  principal.

## r1

« On the right side of the frame, next to the tunnel, stands a second large and clearly separate block: a dedicated
crystal refinery building with tall glass walls, through which rows of cut and polished pale blue crystals glow
brightly. »

| Code | `denoise` | t1 gardé | Bloc en plus à 128 px | Remarques |
| --- | --- | --- | --- | --- |
| r1a-crystal_mine-4242 | 0,95 | oui : portail, cristaux, convoyeur | oui : façade vitrée bleue à droite | |
| r1b-crystal_mine-4242 | 0,97 | **non** : bâtiment principal redessiné, galerie déplacée | oui | dérive du paysage |

Décision : à l'utilisateur.

## Sélection (utilisateur, 2026-11-17)

`building.crystal_mine.t2.temperate` : **r1a-crystal_mine-4242** (`denoise` 0,95), `validated` v1.
