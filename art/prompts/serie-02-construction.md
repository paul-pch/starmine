# Série 02 : famille Construction

Série d'exploration demandée par l'utilisateur, avec deux buts : affiner le skill `starmine-prompt`
et commencer à sélectionner des images.

Fichiers : fichier de série supprimé, prompts dans `run.json`, base `art/style/base_prompt.md`. Qwen-Image-2.1, seeds 4242
et 7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 18 images, environ 30 s par image.

## Décisions de l'utilisateur

- La famille Construction couvre `shipyard`, `robotics_factory` et `nanite_factory`.
- État : industriel actif, entretenu et utilisé.
- Environnement : à choisir sur image, parmi plusieurs jeux.

## Essai 1

Changements par rapport à la série 01 :

- base scindée : le point de vue, l'environnement et l'état passent dans le fichier de série ;
- « gritty » et « weathered » retirés ; « large » retiré du sujet ;
- « barren alien planet » retiré de la base avec la cuvette rocheuse ;
- point de vue éloigné : « Wide view from a distance and slightly above ».

Hypothèse : un état actif, sans les mots d'usure, supprime l'effet post-apocalyptique ; un seul
élément nommé distingue les 3 bâtiments.

Variante C choisie par Claude en remplacement de l'intérieur de hangar proposé à l'utilisateur, qui
contredit « vu de loin ».

| Jeu | Environnement |
| --- | --- |
| A | plateau de basalte gris |
| B | dalle industrielle balisée sur plaine rocheuse |
| C | adossé à une falaise |

Prompts complets : `run.json`, dans le dossier de sortie.

### Notes proposées par Claude

6 images vues en taille réelle : A-shipyard-7777, C-shipyard-7777, B-robotics_factory-7777,
C-robotics_factory-4242, A-nanite_factory-4242, C-nanite_factory-7777. Les 12 autres sont notées
sur la planche seulement. L'utilisateur n'a pas encore noté.

| Critère | Résultat |
| --- | --- |
| Effet post-apocalyptique supprimé | oui, sur les images vues : bâtiments propres et éclairés |
| 3 bâtiments reconnus à 512 px | oui, mais par le contenu : vaisseau, robots, cylindre |
| Sujet dominant | oui, sur toutes les images |
| Vu de loin, bâtiment entier | A oui ; B et C non : plusieurs coupés au bord ou trop proches |
| Structure cohérente | hangars et cylindres oui ; robots fusionnés sur B-robotics_factory-7777 |
| Science-fiction lisible | non pour le hangar et l'usine de robots : entrepôts actuels |
| Autre planète | non : arbres à l'horizon sur C-shipyard-7777 |

### Observations

- Le retrait de « alien planet » a un effet secondaire non prévu : le décor ressemble à la Terre.
- `shipyard` et `robotics_factory` partagent le même bâtiment : un entrepôt à grande porte. Seul le
  contenu les sépare, et les robots restent petits sur A et B.
- `nanite_factory` est le plus affirmé, mais le nuage prend une forme de double hélice sur toutes
  les images, qui peut évoquer l'ADN.
- Le vaisseau garde un aspect de navette usée, malgré « clean hull plates ».
- La variante A garde la distance la plus proche de la direction « vu de loin ».

## Retour de l'utilisateur

Voir `serie-03-construction.md`.
