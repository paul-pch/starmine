# Prompt de base

Charte commune aux images de bâtiment. `tool/comfy_series.py` lit le bloc `text` ci-dessous et y
insère `{subject}` et `{detail}`, propres à chaque image, ainsi que `{view}`, `{site}` et `{state}`,
dont les valeurs par défaut sont dans les blocs du même nom. Une image peut y déroger dans son
fichier de série, comme le chantier spatial pour la vue et le site.

```text
{view} {subject} {detail} The installation is monumental: tiny vehicles and tiny human figures at its base give the scale. {site} {state} Art direction: realistic sci-fi concept art, warm low sunlight, long soft shadows, muted neutral grey palette, atmospheric haze.
```

```view
Wide low three-quarter aerial view from a distance, with the whole installation visible inside the frame.
```

```site
It is built into the foot of a towering dark neutral grey rock cliff on a lifeless alien planet of bare rock.
```

```state
Far-future high-tech industry in active use, with seamless composite panels, polished metal and illuminated light strips.
```

## Choix

- **Charte et fiche** : la charte fixe ce qui est commun, chaque bâtiment a sa fiche dans le fichier
  de série. Décision de l'utilisateur, série 02.
- **Adossé à la roche** : préféré par l'utilisateur sur la série 02, et il relie le bâtiment au type
  de planète.
- **Roche grise pour l'instant** : l'utilisateur prévoit 3 déclinaisons de chaque image (froid,
  tempéré, chaud), après la mise au point sur la roche. Cela changera le catalogue de la spec 11.
- **Modèle en test** : Qwen-Image-2.1.

Les séries 01 et 02 ont utilisé des bases précédentes, conservées dans l'historique Git et dans le
`run.json` de chaque série.
