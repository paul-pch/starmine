# Prompt de base du fond d'écran

Charte des images `background.<cold|temperate|hot>` (9:19.5, export 1080 × 2340, spec 11), fond plein
écran de l'ambiance Immersive. Une série la sélectionne avec `"base": "art/style/background_prompt.md"`
et `"size": [768, 1664]`. Même planète que le hero (`hero_prompt.md`) : roche grise, colonie lointaine,
géante gazeuse et lune.

Contrainte d'affichage : seule une bande d'environ 170 dp sous la barre de ressources reste visible ;
le reste est couvert par des panneaux opaques à 78 et 90 %. Le sujet (ciel, géante gazeuse, horizon)
tient dans le tiers haut ; les deux tiers du bas restent une roche sombre dans l'ombre, sans élément
important (« sombre en bas »).

```text
{view} {sky} {subject} {site} {ground} {light} No text.
```

```light
Art direction: realistic sci-fi concept art, warm low sunlight, long soft shadows, muted neutral grey palette, atmospheric haze.
```

```view
Tall vertical phone wallpaper of an alien landscape, seen from a high rocky ridge, with the horizon in the upper third of the frame.
```

```sky
High in the hazy sky near the top of the frame hangs a huge pale banded gas giant planet, partly lit by the sun, with a small grey moon beside it.
```

```subject
Far away on the horizon, at the foot of a towering cliff, stands a small cluster of far-future high-tech installations with domes and towers, tiny in the frame, their windows and floodlights glowing brightly.
```

```site
The land is made of bare dark neutral grey rock, with towering grey cliffs and distant mountains, on a lifeless alien planet of bare rock.
```

```ground
The lower two thirds of the frame are plain bare dark rock sinking into deep shadow, darker and darker toward the bottom edge, with no object.
```

## Climats

Mise au point sur la roche grise (tempéré), puis déclinaison froid et chaud en repartant de l'image
retenue, sa seed et `denoise` 0,90, comme le hero.
