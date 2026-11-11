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
| `storage_leak` | néfaste | validée | `e13-storage_leak-7777` | colon assis, accepté |
| `merchant_convoy` | choix, espace | validée | `e15-merchant_convoy-4242` | coque d'allure marine acceptée |
| `escort_request` | choix, espace | validée | `e17-escort_request-4242` | vue de profil, sens du vol imposé |
| `unstable_wreck` | choix, espace | validée | `e2-unstable_wreck-4242` | |
| `pirate_deserters` | choix | validée | `e19-pirate_deserters-7777` | pilotes de face, visières opaques, pas de témoin |
| `advance_contract` | choix | validée | `e22-advance_contract-7777` | colon et émissaire de la guilde, lingot de fer |
| `prospectors` | choix | validée | `e26d-prospectors-7777` | groupe de dos vers l'astéroïde, tête nue (depuis e25-7777, denoise 0,92) |
| `distress_signal` | choix, espace | validée | `e28-distress_signal-7777` | un seul transporteur fonctionnel, avarie et balise |

## État

Série terminée : 15 événements sur 15 (`orbital_battle` retiré du jeu). Un nouvel événement du catalogue s'ajoute à
`art/prompts/serie-60-story.json` avec la variante suivante (`e29`), puis
`~/ComfyUI/.venv/bin/python tool/comfy_series.py art/prompts/serie-60-story.json` ; après validation, master
`art/masters/story.<clé>/v1.png`, entrée `validated` au registre (format `16:9 1280x720`) et
`python3 tool/export_visuals.py`.
