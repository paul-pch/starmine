# Prompt de base des unités

Charte commune aux constructibles du chantier spatial : défenses (`defense.<clé YAML>`) et vaisseaux
(`ship.<clé YAML>`). Choisie par l'utilisateur en Q/R (série 58). Une série la sélectionne avec
`"base": "art/style/unit_prompt.md"`. Chaque image donne `subject` et `detail` ; les vaisseaux
remplacent `view` et `site` par les valeurs du bloc « Vaisseaux » ci-dessous.

```text
{view} {subject} {detail} {scale} {site} {state} Art direction: realistic sci-fi concept art, warm low sunlight, long soft shadows, muted neutral grey palette, atmospheric haze.
```

```view
Wide three-quarter aerial view from a distance and from above, with the whole unit visible inside the frame.
```

```scale
The defense is monumental, several storeys tall: tiny vehicles and tiny human figures at its base give the scale.
```

```site
It stands alone on bare dark neutral grey rock on a lifeless alien planet of bare rock, under a hazy sky, with a flat rocky plain stretching behind it to distant mountains. Deep depth of field: the whole image is in sharp focus, with no blurred foreground.
```

```state
Far-future high-tech military hardware, with seamless composite panels, polished metal, illuminated light strips and plain unmarked surfaces.
```

## Vaisseaux

- `view` : Close three-quarter view from slightly above, with the whole ship visible inside the frame and filling most of it.
- `scale` : vide pour l'instant.
- `site` : It flies alone in the black of space in high orbit, above a lifeless grey rocky planet: the planet's curved horizon, with a thin bright rim of atmosphere, crosses the lower third of the frame from left to right, and its grey cratered surface, with one large round crater below the ship, fills the bottom of the frame, slightly out of focus. The sky above is pure black, with a soft warm golden haze of sunlight glowing along the right edge of the frame.

## Choix

- **17 unités dans une seule série** (série 58), dans l'ordre du YAML de jeu, une à la fois, 3 images
  par essai (seeds 4242, 7777, 1234). Décision de l'utilisateur.
- **Défenses en extérieur sur la roche grise** : une seule image, sans climat.
- **Vaisseaux en vol dans l'espace**, planète rocheuse grise en arrière-plan.
- **Défense imposante** : après le lanceur de missiles, l'utilisateur a demandé que chaque défense paraisse
  grande face aux cailloux du sol. Ajout du bloc `scale` et d'une caméra plus basse, à partir du laser léger.
  Essai e1 du laser refusé : le premier plan flou rapetisse la défense (effet maquette). e2 : caméra à
  distance au téléobjectif, image nette partout, peu de sol devant. Refusé : encore un plan serré.
  e3 : vue aérienne à distance comme les bâtiments, échelle par minuscules véhicules et humains au pied
  (« nobody in sight » retiré de `state`).
- **Fond des vaisseaux décrit dans `site`** : même espace noir, halo doré à droite, horizon courbe et grand
  cratère, retenus avec le grand transporteur. Jamais d'assemblage d'images : l'utilisateur a refusé les
  retouches de zone et les collages (coutures visibles).
- **Plan rapproché, sans humain** : l'unité remplit le cadre, pour la lisibilité en vignette.
