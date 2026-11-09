# Série 03 : famille Construction, charte et fiches

Suite de la série 02. Fichiers : `serie-03-construction.json`, sans le prompt des robots remplacé en série 04, charte `art/style/base_prompt.md`.
Qwen-Image-2.1, seeds 4242 et 7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 6 images.
Prompts complets : `run.json`, dans le dossier de sortie.

## Retour de l'utilisateur sur la série 02

- Les bâtiments adossés à la roche plaisent : ils relient le bâtiment au type de planète.
- Le cylindre de nanites est très réussi. `C-nanite_factory-4242` est la référence, à rendre plus
  grand et plus high-tech.
- Le reste fait « entrepôt », et les proportions paraissent petites.
- Les robots conviennent : pas besoin de les parfaire, ils seront tout petits sur téléphone. L'effort
  porte sur l'usine, qui doit en être une.
- Le chantier spatial fabrique des vaisseaux et doit les laisser sortir : il obéit à d'autres règles.

## Décisions de l'utilisateur

- Une charte générique, puis une fiche définie ensemble pour chaque bâtiment. Remplace la famille.
- Chantier spatial : cale à ciel ouvert (piste S1). La piste S2, portail dans la falaise, n'est pas
  testée.
- Tout en roche grise d'abord. Ensuite, 3 déclinaisons de chaque image : froid, tempéré, chaud.
- Paliers : t1 est déjà monumental, t2 et t3 grandissent par ajouts d'éléments, pas par la taille
  seule.

## Essai 1

Hypothèses : les repères d'échelle et la caméra basse agrandissent le bâtiment ; composite, métal
poli et bandes lumineuses suppriment l'entrepôt ; « lifeless alien planet of bare rock » supprime le
décor terrestre.

### Notes proposées par Claude

6 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté. Chaque case donne
4242 / 7777.

| Critère | Chantier spatial | Usine de robots | Usine de nanites |
| --- | --- | --- | --- |
| Sujet dominant | oui / oui | non / non : la falaise domine | oui / oui |
| Monumental | oui / oui | non / non | oui / oui |
| Adossé à la roche | sans objet | non / non : posée devant | oui / oui |
| Plus d'entrepôt | oui / oui | oui / oui | oui / oui |
| Fonction reconnue à 512 px | oui / oui | oui / oui | oui / oui |
| Aucun décor terrestre | oui / oui | non / non : voitures actuelles | oui / oui |

### Observations

- Grand progrès sur les trois hypothèses, sauf l'échelle de l'usine de robots.
- Chantier spatial : deux compositions fortes. Fosse droite sur 4242, cratère sur 7777.
- Usine de robots : « long » et « along its facade » donnent un bâtiment bas et étalé. Hypothèse :
  ces mots réduisent la hauteur et détachent le bâtiment de la falaise.
- Voitures de série sur l'usine de robots 4242 : « vehicles » reste trop vague.
- Usine de nanites 4242 : le cylindre devient une capsule et le nuage perd sa spirale.
- Usine de nanites 7777 : la spirale reste et le cylindre s'élève, mais la roche devient un bloc
  isolé plutôt qu'une falaise.

## Retour de l'utilisateur

Sélection provisoire ; rien n'entre dans `assets/` ni
`art/masters/` :

- `shipyard-4242` : la fosse droite, « beaucoup mieux » que le cratère ;
- `nanite_factory-4242` : préférée à 7777, malgré la perte de la spirale notée par Claude ;
- `robotics_factory-4242` : gardée, mais l'usine paraît petite dans l'image, plus que sur 7777.

Suite décidée : ne retravailler que l'usine de robots (série 04). Pas de changement sur les
véhicules de la charte, ni d'image-to-image pour les nanites.
