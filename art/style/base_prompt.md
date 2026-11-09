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
- **Roche grise pour le tempéré** : chaque image est mise au point sur la roche, puis déclinée en froid
  et en chaud en repartant de l'image retenue, avec sa seed et `denoise` 0,90. Le catalogue de la spec 11 reste
  à adapter.
- **Modèle en test** : Qwen-Image-2.1.

## Déclinaisons de climat

Valeurs de `site` retenues par l'utilisateur, seul champ modifié. Chantier spatial : voir
`art/prompts/serie-41-shipyard.json`.

| Site | Froid | Chaud |
| --- | --- | --- |
| Falaise | It is built into the foot of a towering dark neutral grey rock cliff heavily covered with thick white snow and ice, with the ground all around blanketed in deep white snow and snowdrifts, on a frozen lifeless alien planet of bare rock, ice and wind-blown snow. | It is built into the foot of a towering scorched dark basalt cliff with a few thin glowing orange lava cracks, with the ground all around made of baked deep muted oxblood-red earth, on a sun-baked lifeless alien planet of bare scorched rock, with thick columns of volcanic smoke rising in the distance. |
| Plateau | It stands on a flat plateau blanketed in deep white snow and snowdrifts at the top of a towering dark neutral grey rock cliff heavily covered with thick white snow and ice, open to the sky, on a frozen lifeless alien planet of bare rock, ice and wind-blown snow. | It stands on a flat plateau of baked deep muted oxblood-red earth at the top of a towering scorched dark basalt cliff with a few thin glowing orange lava cracks, open to the sky, on a sun-baked lifeless alien planet of bare scorched rock, with thick columns of volcanic smoke rising in the distance. |
| Mer | It stands on a broad platform at the foot of a towering dark neutral grey rock cliff streaked with ice that plunges straight into a frozen sea of cracked pale ice with ice floes and pressure ridges, on a frozen lifeless alien planet of bare rock, ice and wind-blown snow. | It stands on a broad platform at the foot of a towering scorched dark basalt cliff with a few thin glowing orange lava cracks that plunges straight into a dark slate-grey sea with heavy swell and thick white steam rising from its surface, on a sun-baked lifeless alien planet of bare scorched rock, with thick columns of volcanic smoke rising far in the distance. |

## Historique

Les séries 01 et 02 ont utilisé des bases précédentes, conservées dans l'historique Git et dans le
`run.json` de chaque série.
