# Série 76 — centrale solaire t2 (tempéré)

Fiche : t2 = t1 tempéré + stockage thermique (cuves de sels fondus) à droite, choix de l'utilisateur.
Méthode : [[tier-adds-visible-block]], source `serie-11-solar/solar_plant-4242_00001_.png`, seed 4242.
`view`, `detail`, `site` : ceux du t1 (série 11). Subject = subject du t1 + bloc ; textes complets dans le JSON.

- h1 : « On the right side of the frame, on the plateau beside the mirror field … several giant upright cylindrical
  molten-salt tanks » ;
- h2 : « In the bottom right corner of the frame, on the plateau outside the mirror field … three giant upright
  cylindrical molten-salt tanks, each as tall as a building ».

| Code | `denoise` | t1 gardé | Bloc en plus à 128 px |
| --- | --- | --- | --- |
| h1a | 0,95 | partiel : plateau et falaise gardés, tour plus lisse, champ de miroirs réduit | oui : cuves à droite |
| h1b | 0,96 | partiel : comme h1a | oui |
| h1c | 0,97 | partiel : tour à base évasée, miroirs épars | oui |
| h2a | 0,95 | partiel : grand champ de miroirs, tour plus lointaine | oui : cuves en bas à droite |
| h2b | 0,97 | non : vue plus basse, champ de miroirs immense | oui |

Constat : les cuves s'ajoutent dès 0,95 sur les deux formulations ; la tour du t1 perd ses détails industriels.

Décision : aucune. h1a choisie puis refusée par l'utilisateur : les cuves évoquent le stockage, pas l'énergie. On recommence le t2.
