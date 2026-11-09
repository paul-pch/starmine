# Série 42, recherches : premier jet

12 technologies, seeds 4242 et 7777, Qwen-Image-2.1, 24 images. Prompts complets : `run.json` de la série.
Charte : `art/style/research_prompt.md`, nouvelle, sélectionnée par le champ `base` du fichier de série.

## Cadrage, décidé par l'utilisateur en Q/R

- Mise en scène : banc d'essai dans un hall de labo.
- Échelle : plan rapproché, sans humain.
- Couleur : gris neutre et une seule lueur par technologie.
- Sujets : prototypes, sans vaisseau (réacteurs au banc, armes sur support).

## Critères

- Le prototype domine l'image.
- La structure reste cohérente : appuis, pièces qui flottent ou fusionnent.
- On reconnaît ce que la technologie fait, à 512 px, sans son nom.
- La lueur demandée est la seule couleur vive.
- Aucun texte, logo ni interface.
- Lisible vers 256 px.

## Revue

Planche à 512 px et vignettes à 256 px pour les 24 images. Taille réelle pour 4 seulement : `laser-4242`,
`ion-7777`, `weapons-7777`, `shielding-7777`. Le critère de texte reste donc à confirmer au zoom sur les 20 autres.

| Technologie | 4242 | 7777 | Remarque |
| --- | --- | --- | --- |
| `energy_technology` | réussi | réussi | sphère et arcs nets ; socle plus imposant sur 7777 |
| `laser_technology` | raté | réussi | 4242 : cible qui flotte sans support |
| `ion_technology` | réussi | réussi | 7777 plus net ; petites marques sur le socle à vérifier |
| `plasma_technology` | réussi | réussi | filament franc sur les 2 |
| `computer_technology` | réussi | réussi | 4242 plus coloré ; dense à 256 px |
| `espionage_technology` | partiel | partiel | lit plus comme un projecteur ou une caméra qu'une sonde |
| `combustion_drive` | partiel | réussi | 4242 : flamme pâle, rosée au départ |
| `impulse_drive` | réussi | réussi | peu d'onde visible, surtout des volutes ; teinte proche du violet du bouclier |
| `shielding_technology` | raté | raté | le tir atteint la machine dans le dôme au lieu de s'arrêter à sa surface |
| `hyperspace_drive` | partiel | partiel | lit comme une grande lentille ; silhouette proche de `plasma_technology` |
| `weapons_technology` | raté | raté | plaque collée à la bouche du canon, qui se voit mal ; lueur peu présente |
| `armour_technology` | raté | raté | pas de presse sur les 2 seeds ; lit comme un bouclier ou une porte |

Constat commun : le hall reste le même d'une technologie à l'autre sur une même seed, ce qui donne un set
homogène. Le prototype n'occupe souvent qu'environ la moitié du cadre, moins que le plan rapproché demandé.

## Décision

En attente du choix de l'utilisateur.
