# Sélection des illustrations d'événements

Suivi des images `story.<clé>` choisies par l'utilisateur, une à la fois, dans l'ordre du catalogue
(`story_events.catalog`). Format 16:9 (export 1280 × 720), charte `art/style/story_prompt.md`, série 60
(`art/prompts/serie-60-story.md`). Licence : voir spec 11.

| Événement | Ton | État | Image | Remarque |
| --- | --- | --- | --- | --- |
| `rich_vein` | favorable | validée | `e2-rich_vein-4242` | |
| `deuterium_geyser` | favorable | validée | `e5-deuterium_geyser-4242` | |
| `gravity_anomaly` | favorable | validée | `e7-gravity_anomaly-7777` | remplace `archaeology` (pas de ruines) |
| `drifting_wreck` | favorable, espace | validée | `e10-drifting_wreck-7777` | transporteur spatial délabré et plein, sans navette |
| `solar_storm` | néfaste | validée | `e2-solar_storm-7777` | |
| `gallery_collapse` | néfaste | validée | `e11-gallery_collapse-4242` | |
| `sabotage` | néfaste | validée | `e12-sabotage-4242` | |
| `storage_leak` | néfaste | **à faire** | | prochaine |
| `orbital_battle` | favorable, espace | à faire | | |
| `merchant_convoy` | choix, espace | à faire | | |
| `escort_request` | choix, espace | à faire | | |
| `unstable_wreck` | choix, espace | validée | `e2-unstable_wreck-4242` | |
| `pirate_deserters` | choix | à faire | | |
| `advance_contract` | choix | à faire | | |
| `prospectors` | choix | à faire | | |
| `distress_signal` | choix | à faire | | |

## Pour reprendre

- Ajouter l'entrée suivante (variante `e13`) à `art/prompts/serie-60-story.json`, puis
  `~/ComfyUI/.venv/bin/python tool/comfy_series.py art/prompts/serie-60-story.json` (les codes déjà générés
  sont sautés).
- Scène au sol : vue par défaut de la charte, avec le colon de dos au centre. Scène dans l'espace : vue et
  règles de la section « Scènes dans l'espace » de la charte. Ton : bloc `mood` selon le tableau de la
  charte (néfaste, pari).
- Après validation : master `art/masters/story.<clé>/v1.png`, entrée `validated` au registre (format
  `16:9 1280x720`), puis `python3 tool/export_visuals.py`.
