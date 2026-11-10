# Prompt de base du hero planète

Charte des images `planet_hero.<cold|temperate|hot>` (21:9, export 1260 × 540, spec 11). Une série la
sélectionne avec `"base": "art/style/hero_prompt.md"` et `"size": [1792, 768]`. Choisie par
l'utilisateur en Q/R (série 59) : panorama au sol, colonie lointaine et éclairée, géante gazeuse et
lune dans le ciel.

Contrainte d'affichage : le bandeau opaque du nom (`PlanetHero`) couvre environ le tiers bas de
l'image. Le sujet (colonie, horizon, ciel) se place dans les deux tiers du haut ; le tiers bas reste
un sol rocheux sans élément important.

```text
{view} {subject} {detail} {site} {sky} {light} No text.
```

```light
Art direction: realistic sci-fi concept art, warm low sunlight, long soft shadows, muted neutral grey palette, atmospheric haze.
```

```view
Ultra-wide cinematic panoramic landscape seen from a high rocky ridge, looking far across a vast valley, with the horizon in the upper half of the frame and plain bare rocky ground filling the lower third of the frame.
```

```subject
Far away across the valley, at the foot of a towering cliff, stands a small cluster of far-future high-tech installations with domes and towers, tiny in the frame, their windows and floodlights glowing brightly.
```

```detail
The colony is only a small detail of the landscape, not its subject.
```

```site
The valley is made of bare dark neutral grey rock, with towering grey cliffs and distant mountains, on a lifeless alien planet of bare rock.
```

```sky
High in the hazy sky above the horizon hangs a huge pale banded gas giant planet, partly lit by the sun, with a small grey moon beside it.
```

## Climats

Mise au point sur la roche grise (tempéré), puis déclinaison froid et chaud en repartant de l'image
retenue, sa seed et `denoise` 0,90, comme les bâtiments (`art/style/base_prompt.md`).
