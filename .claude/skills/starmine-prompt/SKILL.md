---
name: starmine-prompt
description: Écrire et mettre au point le prompt d'une image de Starmine avec une méthode mesurable — fiche, critères écrits avant de générer, 2 seeds fixes, un seul changement par essai, journal. Génération locale avec ComfyUI et Qwen-Image-2.1. À utiliser pour définir ce qu'une image doit montrer, corriger un sujet ou un cadrage raté, tester une série de prompts ou comparer des modèles. La validation finale et l'export relèvent de starmine-visuals.
---

# Prompts d'images Starmine (v1)

Objectif : un prompt **précis**, c'est-à-dire qui donne le résultat voulu sur plusieurs seeds,
pas une image réussie par chance. Formats et registre : `docs/specs/11-visuels.md`.
Seul l'utilisateur valide une image.

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

Les fiches se définissent **un bâtiment à la fois**, par des questions à réponses proposées. Quand
l'utilisateur soumet ses réponses, sans autre validation : écrire le prompt, générer, vérifier les
images en taille réelle, puis lui faire un retour avec les notes et la galerie.

Pour une **série d'exploration** demandée par l'utilisateur, le fichier de série tient lieu de
fiche ; les critères communs sont ceux de la section 4.

## 2. Prompt

Le prompt est composé de la charte `art/style/base_prompt.md`, commune aux images, et d'une fiche par
bâtiment, définie avec l'utilisateur, dans le fichier de série :

- `view`, `site`, `state` : valeurs par défaut dans la charte ; une image ou une variante peut y
  déroger ;
- `subject` : le type d'installation et **un seul élément fonctionnel nommé** ;
- `detail` : une phrase sur l'élément qui identifie l'image en jeu.

Une modification de la base s'applique à tout le set : la tester sur plusieurs images.

### Direction artistique par famille

Décidée par l'utilisateur et testée sur les 12 bâtiments en t1. Images retenues et journaux :
`art/prompts/selection-t1-rocheux.md`.

Toutes les images se mettent au point en roche grise. L'utilisateur prévoit ensuite 3 déclinaisons
de chaque image (froid, tempéré, chaud). Cela changera le catalogue de la spec 11.

Paliers : t1 est déjà monumental ; t2 et t3 grandissent par ajouts d'éléments, pas par la taille
seule.

| Famille | Bâtiments | Environnement | État | Ce qu'on doit voir |
| --- | --- | --- | --- | --- |
| Mines | `metal_mine`, `crystal_mine` | adossé à une falaise | high-tech poussiéreux, moins marqué pour le cristal | bâtiment autour d'une entrée de galerie, convoyeur, filons ou cristaux |
| Deutérium | `deuterium_synthesizer`, `deuterium_tank` | falaise plongeant dans une mer gris sombre | charte | sphère de pression ; silos vitrés à liquide lumineux |
| Énergie | `fusion_reactor` | adossé à une falaise | charte | anneau de confinement, plasma bleu-blanc |
| Énergie solaire et recherche | `solar_plant`, `research_lab` | plateau au sommet d'une falaise, vue haute | charte | tour et miroirs ; dôme vitré et antennes |
| Stockage | `metal_storage`, `crystal_storage` | adossé à une falaise | charte | rangée de silos : lingots ; paroi vitrée sur le cristal |
| Construction | `robotics_factory`, `nanite_factory` | adossé à une falaise | high-tech, en activité | l'usine et ce qu'elle produit, monumentale |
| Construction, dérogation | `shipyard` | cale à ciel ouvert, taillée dans la roche | high-tech, en activité | un vaisseau qui sort de la cale, vu de haut |

Point à confirmer avec l'utilisateur :

- la mer du deutérium s'affiche sur toutes les planètes, y compris froides et chaudes : est-ce
  accepté, ou faut-il une mer peu marquée (spec 11 : une image par bâtiment) ?

## 3. Génération

Serveur ComfyUI lancé, puis :

```bash
~/ComfyUI/.venv/bin/python tool/comfy_series.py art/prompts/<serie>.json
```

- Le fichier de série donne les seeds, des `variants` facultatives et la liste `id`, `subject`,
  `detail`, avec `view`, `site` ou `state` en cas de dérogation à la charte.
- Nouvelle image : 2 images par prompt, seeds **4242** et **7777**, jamais changées au cours d'une
  série.
- Modification ou déclinaison d'une image retenue : **uniquement sa seed, en repartant de cette image**
  (`source`, `denoise`), pour limiter la dérive du paysage. Décision de l'utilisateur. Sélection :
  `art/prompts/selection-t1-rocheux.md`. Déclinaisons froid et chaud : `denoise` 0,90, retenu par
  l'utilisateur (séries 26 et 27).
- Un bâtiment à la fois, avec sa galerie.
- Retoucher une petite zone : `tool/comfy_inpaint.py`. Essayer plusieurs seeds : sur la tente du labo,
  le résultat dépendait de la seed, pas du `denoise` (séries 24 et 25).
- Compter environ 30 s par image : annoncer le temps avant un grand lot.
- Sorties : `~/ComfyUI/output/starmine_test/<serie>/`, avec `run.json`, `sheet_512.png` et
  `index.html`.
- Sélection : donner à l'utilisateur le chemin de la galerie locale
  (`\\wsl.localhost\Debian\home\paul\ComfyUI\output\starmine_test\<serie>\index.html`). Il cite les
  codes affichés sous les images. Ne pas publier ces images en Artifact : licence, voir plus haut.

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
- **Échelle par repères** (série 03) : caméra basse et minuscules humains et véhicules à la base font
  monumental, là où la série 02 restait à la taille d'un entrepôt. Ne remplace pas la décision sur
  les paliers (voir la direction artistique).
- **Matières contre entrepôt** (série 03) : « composite panels, polished metal, light strips » retire
  le bardage ; un mot d'état ne suffisait pas (série 02).
- **Fonction visible** (série 03) : une usine se reconnaît à ce qu'on voit fabriquer ; un bâtiment à
  grande porte ne se distingue que par son contenu (série 02).
- **Hauteur par la falaise** (séries 03 et 16) : « rise almost to the top of the cliff » agrandit le
  sujet, sur 4242 surtout. Un adjectif de taille seul n'y suffit pas.
- **Orientation non obtenue** (série 12) : « upright » n'a pas redressé l'anneau de fusion, resté à
  plat sur les 2 seeds.
- **Forme allongée** (série 03) : « long ... along its facade » donne un bâtiment bas, écrasé par la
  falaise. « towering multi-level structure anchored into the cliff » donne hauteur et ancrage sur
  les 2 seeds (série 04).
- **Raccord entre deux objets** (séries 06 à 08) : une foreuse reliée à un bâtiment et entrant dans
  la roche échoue (elle pointe dehors ou longe la paroi). Un bâtiment construit autour d'une ouverture
  avec un convoyeur marche : préférer un élément qui ne dépend pas d'un raccord précis.
- **Lumières** (séries 05 à 09) : avec beaucoup de poussière, les « light strips » ne ressortent pas.
  « very light coat of rock dust, and bright floodlights switched on » les ramène, sans séparer les
  deux effets.
- **Planète à nommer** (série 02) : sans « alien planet », arbres et herbes apparaissent. « lifeless
  alien planet of bare rock » les retire (série 03).
- **Couleur de roche** (essais 4 et 5) : le terrain doit rester neutre, car l'image s'affiche sur
  toutes les planètes.
- **Point de vue** (essai 3) : le fixer explicitement, sinon le modèle recule la caméra.
- **Négatif** (essai 6) : avec Qwen en cfg 1, le prompt négatif n'a probablement pas d'effet. Décrire
  ce qu'on veut voir.
