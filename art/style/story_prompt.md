# Prompt de base des événements

Charte des illustrations `story.<clé YAML>` (16:9, export 1280 × 720, spec 11), affichées en tête de
la popover d'événement (`EventPopover`), sans recouvrement. Une série la sélectionne avec
`"base": "art/style/story_prompt.md"` et `"size": [1664, 928]`.

Choix de l'utilisateur en Q/R (série 60) :

- **sans climat** : roche grise neutre, comme les recherches et les unités ;
- **ambiance selon le ton** de l'événement (bloc `mood`, trois valeurs ci-dessous) ;
- **vaisseaux et lieux** : l'objet de l'événement domine (les visages relèvent de la catégorie
  `character`) ;
- **témoin de dos** : dans les scènes au sol, un colon en combinaison, vu de dos au premier plan au
  centre, regarde l'événement. Les scènes dans l'espace n'en ont pas. Décision de l'utilisateur après
  la série 60 : la vue ci-dessous le produit sur les 2 seeds (essai e2), alors qu'il était
  involontaire. Ne pas la reformuler sans retester ;
- **tête nue sur la planète du joueur** (décision de l'utilisateur, `prospectors` e26) : dans les scènes au sol,
  personnages sans casque ; les tenues restent (colon en combinaison de travail blanche et grise, tenues propres à
  chaque groupe). Les images validées avant cette règle gardent leurs casques ;
- mise au point sur 3 scènes types (`rich_vein`, `solar_storm`, `unstable_wreck`), puis les 13 autres
  une par une.

Format : 16:9 et non 21:9, pour un téléphone vertical (la popover fait environ 350 dp de large, et
l'image environ 197 dp de haut). Décision de l'utilisateur après l'essai e1 en 21:9. Le sujet est
**centré** et rien d'important ne touche les bords (demande de l'utilisateur).

```text
{view} {subject} {detail} {site} {mood} No text.
```

```view
Cinematic view with a centred composition: the subject sits in the middle of the frame, large and filling most of the frame height, with nothing important near the left or right edges.
```

```site
On a lifeless alien planet of bare dark neutral grey rock, with towering grey cliffs and distant mountains.
```

```mood
Art direction: realistic sci-fi concept art, hopeful and optimistic mood, bright golden-hour sunlight with rich warm tones on the rock, crisp clear air with good contrast, a deep clear blue-teal sky.
```

## Ton (`mood`)

| Ton | Événements | Texte |
| --- | --- | --- |
| Favorable | défaut du bloc `mood` | lumière du hero planète |
| Néfaste | tempête, effondrement, sabotage, fuite… | Art direction: realistic sci-fi concept art, dramatic and ominous mood, dark stormy sky, harsh contrasting light with deep shadows, muted cold palette. |
| Pari, choix | épave instable, déserteurs… | Art direction: realistic sci-fi concept art, tense and suspenseful mood, cold bluish light with strong contrast, deep shadows. |

## Scènes dans l'espace

`site` est remplacé, par exemple par « In space, in orbit … with stars ». `view` est remplacé par la vue
ci-dessous, qui n'a fait apparaître aucun personnage : la vue par défaut ajoute le témoin, même dans
une soute et même avec « no person » (série 60, e8 et e9).

- `view` : Cinematic view with a centred composition: the main element of the scene is placed in the middle of the frame, large and filling most of the frame height, with nothing important near the left or right edges, and no person in the foreground.
- Vaisseau : « built for space and not shaped like a boat ». Le mot « freighter » donne un navire de
  mer (e9).
- Avant qu'on ait choisi d'y aller, aucun vaisseau du joueur sur place (retour de l'utilisateur, e8).
