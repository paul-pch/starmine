# Prompt de base des officiers

Charte des portraits `character.<clé YAML de l'officier>` (1:1, export 512 px, spec 11 et 12), sur les cartes
de l'écran Officiers. Une série la sélectionne avec `"base": "art/style/character_prompt.md"` (taille par défaut,
1024 × 1024).

Choix de l'utilisateur en Q/R (série 66, 2026-11-17) :

- **8 portraits**, un par officier du YAML, Amiral compris ;
- **fond = lieu du métier**, flou (faible profondeur de champ) : on reconnaît le rôle sans texte ;
- **casting mixte**, âges et origines variés (4 femmes, 4 hommes), fixé dans la série ;
- **tenue de travail du métier**, blanche et grise comme le colon des événements, avec une couleur d'accent par
  métier ; **tête nue** (règle de la planète du joueur) ;
- ni texte, ni insigne lisible, ni logo, ni écran d'interface ;
- `subject` (la personne), `detail` (un geste ou un objet du métier) et `site` (le lieu) sont propres à chaque officier.

```text
{view} {subject} {outfit} {detail} {site} {mood} No text, no letters, no logo, no badge.
```

```view
Close-up head-and-shoulders portrait, centred: the face and shoulders fill the upper two thirds of the frame, the person turned slightly three-quarter and looking at the viewer, with a bare head and no helmet.
```

```outfit
Wearing a plain white and grey far-future work suit.
```

```site
Behind them, softly blurred with a shallow depth of field, a far-future colony on a lifeless grey rocky planet.
```

```mood
Art direction: realistic sci-fi concept art with photographic realism, soft warm key light on the face, calm confident expression, muted neutral palette with one accent colour.
```
