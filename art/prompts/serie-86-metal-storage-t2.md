# Série 86 — hangar de métal t2 (tempéré)

t2 = t1 tempéré + aire de lingots à ciel ouvert avec portique de levage (choix de l'utilisateur). Source
`serie-13-metal-storage/metal_storage-4242_00001_.png`, seed 4242. Textes complets dans le JSON.

- m1 : aire à droite des silos ; m2 : coin bas droit, devant les silos ; m3 : premier plan, tiers bas du cadre,
  portique « as tall as the silos ».

| Code | `denoise` | t1 gardé | Bloc en plus à 128 px |
| --- | --- | --- | --- |
| m1a, m1b, m1c | 0,92 / 0,94 / 0,96 | oui | non : quelques piles et un petit portique devant le dernier silo |
| m2a, m2b | 0,93 / 0,95 | oui | non : comme m1 |
| m3a | 0,95 | oui | partiel : rangées de lingots sur tout le premier plan, portique petit à gauche |
| m3b | 0,96 | oui | partiel : comme m3a |
| m3c | 0,97 | non : silos plus bas, à dôme | oui : grande aire et portique au premier plan |

Constat : les silos occupent toute la largeur du t1, la droite n'a pas de place ; seul le premier plan accueille le bloc.
Le portique ne grandit pas sans dérive des silos.

Décision : m3a retenue par l'utilisateur (2026-11-19).
