# Séries 44 et 45, combustion : un moteur plus high-tech

Retour de l'utilisateur sur `combustion_drive` de la série 42 : le cadrage de l'original est bon, mais le moteur
ressemble à une vieille fusée. L'utilisateur n'a pas précisé la seed : 7777 retenue par hypothèse, son moteur étant
le plus grand dans le cadre. Pas d'agrandissement par montage.

## Série 44

Depuis `serie-42-recherches/combustion_drive-7777_00001_.png`, seed 7777. Hypothèse : sans les mots « chemical rocket »
et « bell nozzle », et avec un carter fermé, le moteur perd son allure de fusée.

| Code | Résultat |
| --- | --- |
| `d60` | même moteur, tuyaux à nu, seule une bande lumineuse apparaît : raté |
| `d75` | quasi identique à `d60` : raté |
| `d90` | carter facetté, mais tuyère évasée et tuyaux à nu au centre : partiel |

La tuyère et les tuyaux restent de l'image de départ jusqu'à 0,90.

## Série 45

Depuis `d90` de la série 44, seed 7777. Hypothèse : la forme évasée vient du mot « nozzle ». On décrit une capsule
d'un seul tenant et une sortie en anneau affleurante.

| Code | Résultat |
| --- | --- |
| `r85` | forme de la tuyère conservée malgré le prompt : raté |
| `r95` | capsule fermée, sortie en anneau, aucun tuyau, bande lumineuse : réussi ; lisible à 256 px |

Sur `r95`, la forme rappelle une torpille et le socle est simplifié. Le hall et le cadrage restent proches, avec un point
de vue un peu différent. Petite marque sombre en haut du carter, à vérifier : elle pourrait évoquer du texte.

## Règle observée

Pour changer la forme d'un élément depuis une image, il faut `denoise` 0,95 : à 0,85 et 0,90, la silhouette de départ reste.

## Décision

L'utilisateur a d'abord retenu `d90-combustion_drive-7777` de la série 44, puis a changé d'avis pour
`r95-combustion_drive-7777` de la série 45, avant tout export. Master : `art/masters/research.combustion_drive/v1.png`.

## Nouvelle génération

Après la minification, l'utilisateur rejette `r95` et demande une nouvelle génération d'origine. 4 idées ajoutées à `serie-45-combustion.json`, seeds
4242 et 7777 : `new-bell` (tuyère courte en céramique blanche), `new-cluster` (3 tuyères), `new-chamber` (chambre visible), `new-spike` (aérospike).
La série a tourné deux fois : chaque code a un fichier `_00001_` et un `_00002_`, en double dans `run.json`.

L'utilisateur retient `new-bell-combustion_drive-4242_00001_.png`. Master `art/masters/research.combustion_drive/v1.png` remplacé, sans v2 : `r95` n'avait
pas été commitée. WebP réexporté.
