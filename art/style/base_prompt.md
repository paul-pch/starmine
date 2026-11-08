# Prompt de base

Partagé par toutes les images de bâtiment. `tool/comfy_series.py` lit le premier bloc `text`
ci-dessous et y remplace `{subject}` et `{detail}` par les valeurs de chaque image.

```text
High-angle view looking down into a rocky basin on a barren alien planet. At the center, filling most of the frame, stands {subject}. {detail} The ground and rock walls are dark neutral grey basalt. Art direction: gritty realistic sci-fi concept art, weathered dark gunmetal machinery, warm low sunlight, long soft shadows, muted neutral grey palette, atmospheric haze.
```

## Choix

- **Roche neutre** : un bâtiment n'a qu'une image, affichée quelle que soit la température de la
  planète (spec 11). Une roche rouge ne fonctionnerait que sur une planète de type désert.
- **Modèle en test** : Qwen-Image-2.1, sous licence Qwen Research, limitée à la recherche et à
  l'évaluation. Aucune image de ce modèle n'est publiée sans décision explicite de l'utilisateur.
