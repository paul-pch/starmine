---
name: starmine-prompt
description: Écrire et mettre au point le prompt d'une image de Starmine avec une méthode mesurable — fiche, critères écrits avant de générer, 2 seeds fixes, un seul changement par essai, journal. Génération locale avec ComfyUI et Qwen-Image-2.1. À utiliser pour définir ce qu'une image doit montrer, corriger un sujet ou un cadrage raté, tester une série de prompts ou comparer des modèles. La validation finale et l'export relèvent de starmine-visuals.
---

# Prompts d'images Starmine (v1)

Objectif : un prompt **précis**, c'est-à-dire qui donne le résultat voulu sur plusieurs seeds,
pas une image réussie par chance. Formats et registre : `docs/specs/11-visuels.md`.
Seul l'utilisateur valide une image.

**Licence** : Qwen-Image-2.1 est limité à la recherche et à l'évaluation. Rien produit avec ce
modèle n'entre dans `assets/` ni dans `art/masters/` sans décision explicite de l'utilisateur.

## 1. Fiche

Une image à mettre au point a une fiche, validée par l'utilisateur avant de générer :

```yaml
id: building.metal_mine.t1   # id du catalogue de la spec 11
sujet: ce qui domine l'image, en termes concrets
élément clé: le détail qui identifie l'élément en jeu
cadrage: point de vue, position et part du sujet dans l'image
interdit: ce qui ferait rejeter l'image
critères:                    # 3 à 6, chacun vérifiable par réussi ou raté
  - ...
  - les 2 seeds respectent les mêmes critères
```

Si un mot peut désigner deux images différentes, poser la question : « mine » peut donner une
carrière vide ou une installation, et seul l'utilisateur sait laquelle il veut.

Pour une **série d'exploration** demandée par l'utilisateur, le fichier de série tient lieu de
fiche ; les critères communs sont ceux de la section 4.

## 2. Prompt

Le prompt est composé de `art/style/base_prompt.md` (point de vue, roche, charte), commun à toutes
les images, et de deux champs propres à chaque image :

- `subject` : le type d'installation et **un seul élément fonctionnel nommé** ;
- `detail` : une phrase sur l'élément qui identifie l'image en jeu.

Une modification de la base s'applique à tout le set : la tester sur plusieurs images.

**À faire avant la prochaine série** : la base actuelle impose une cuvette rocheuse, une charte
usée et un point de vue plongeant à toutes les images, ce qui contredit la direction ci-dessous.
La scinder : le commun (cadrage du set, lumière, réalisme) dans la base, et l'environnement, l'état
et la distance dans chaque famille. Adapter `tool/comfy_series.py` et le fichier de série en
conséquence, puis noter le résultat au journal.

### Direction artistique par famille

Décidée par l'utilisateur sur la série 01 ; aucune image ne l'a encore testée. Un bâtiment absent
d'une famille n'a pas encore de direction : la lui demander avant de générer.

| Famille | Bâtiments | Environnement | État | Ce qu'on doit voir |
| --- | --- | --- | --- | --- |
| Mines | `metal_mine`, `crystal_mine` | planète rocheuse | poussiéreux, moins marqué pour le cristal | installation en contrebas, filons ou cristaux |
| Deutérium | `deuterium_synthesizer` | en mer | à préciser | installation posée sur l'eau |
| Énergie solaire et recherche | `solar_plant`, `research_lab` | à préciser | high-tech, ni usé ni abandonné | technologie avancée lisible |
| Construction | `shipyard` | à préciser | à préciser | grand hangar vu de loin, avec machines ou vaisseaux |

Points à confirmer avec l'utilisateur :

- la famille Construction couvre-t-elle aussi `robotics_factory` et `nanite_factory` ?
- la mer du deutérium s'affiche sur toutes les planètes, y compris froides et chaudes : est-ce
  accepté, ou faut-il une mer peu marquée (spec 11 : une image par bâtiment) ?

## 3. Génération

Serveur ComfyUI lancé, puis :

```bash
~/ComfyUI/.venv/bin/python tool/comfy_series.py art/prompts/<serie>.json
```

- Le fichier de série donne les seeds et la liste `id`, `subject`, `detail`.
- 2 images par prompt, seeds **4242** et **7777**, jamais changées au cours d'une série.
- Compter environ 30 s par image : annoncer le temps avant un grand lot.
- Sorties : `~/ComfyUI/output/starmine_test/<serie>/`, avec `run.json` et `sheet_512.png`.

## 4. Revue

Noter chaque critère pour chaque image, réussi ou raté, en taille réelle puis à 512 px. Critères
communs :

- le sujet demandé domine l'image ;
- la structure reste cohérente au zoom : appuis, assemblages, symétrie, pièces qui flottent ou
  fusionnent ;
- on reconnaît l'élément du jeu à 512 px, sans son nom ;
- aucune matière ambiguë (minerai pris pour de l'eau ou de la lave, par exemple) ;
- les 2 seeds respectent les mêmes critères.

Regarder les images en taille réelle avant de noter. Ne pas noter un critère de goût à la place de
l'utilisateur : le lui demander. Montrer les images et les notes ; il a le dernier mot.

## 5. Essai suivant

- Un seul changement, relié à une hypothèse et à un critère raté. Si un changement en entraîne un
  autre, le dire.
- Vérifier que le changement n'a pas modifié autre chose que prévu.
- Si un critère échoue 3 essais de suite, le prompt n'est plus le bon levier : proposer un autre
  outil (ControlNet, retouche locale, autre modèle) plutôt qu'un quatrième essai.
- Fiche inchangée entre deux essais, sauf décision de l'utilisateur, notée au journal.
- Prompt retenu quand tous les critères passent sur les 2 seeds et que l'utilisateur confirme.
  Passer alors à `starmine-visuals`.

## 6. Journal

`art/prompts/<id>.md` ou `art/prompts/<serie>.md`, texte seulement : la fiche, puis pour chaque essai
le modèle, les réglages, le prompt complet, les notes par critère, l'hypothèse et la décision. Noter
aussi les retours de l'utilisateur, surtout quand ils contredisent une note. Pas d'image de
brouillon.

## Comparer des modèles

Même fiche, même prompt, mêmes seeds pour chacun, réglages recommandés du modèle. Noter toute
différence imposée, comme l'absence de prompt négatif. On compare sur les critères, puis on itère
le prompt sur un seul modèle.

## Règles apprises

Chaque règle ajoutée ici vient d'un défaut réellement observé. Journal :
`art/prompts/building.metal_mine.t1.md`.

- **Liste d'objets, rendu schématique** (essai 1) : énumérer des objets ordinaires (tour à treillis,
  bâtiment rectangulaire) donne une maquette. Rester général et nommer un seul élément fonctionnel.
- **Trop général, fonction perdue** (essai 2) : sans élément nommé, on obtient un réacteur ou une
  forteresse. C'est encore le cas avec Qwen à l'essai 6.
- **Un seul élément fonctionnel nommé** (série 01) : 6 bâtiments reconnaissables sur les 2 seeds, avec
  un type d'installation et un élément (puits, sphères, dôme, portique). Quand l'élément est extérieur
  au bâtiment, comme les cristaux, le bâtiment lui-même reste un amas de blocs.
- **Pas de base unique pour l'ambiance** (série 01) : une même charte rend tout poussiéreux et
  post-apocalyptique, ce qui ne convient qu'aux mines. L'état et l'environnement dépendent de la
  famille. Hypothèse non testée : « gritty » et « weathered » causent l'effet d'abandon.
- **Adjectif de taille et paliers** (série 01) : « large » sur un t1 ne laisse aucune marge pour t2 et
  t3. Réserver l'échelle au palier.
- **Couleur de roche** (essais 4 et 5) : le terrain doit rester neutre, car l'image s'affiche sur
  toutes les planètes.
- **Point de vue** (essai 3) : le fixer explicitement, sinon le modèle recule la caméra.
- **Négatif** (essai 6) : avec Qwen en cfg 1, le prompt négatif n'a probablement pas d'effet. Décrire
  ce qu'on veut voir.
