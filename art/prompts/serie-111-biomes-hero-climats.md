# Série 111 — hero côte, mesas, jungle : froid et chaud

Depuis les hero tempérés validés (série 109 : coast-4242, mesas-7777, jungle-4242), seed de chacun, `denoise` 0,90,
seul `site` change (textes dans le JSON, repris des rangées « Mer » et « Falaise » de `base_prompt.md` pour la côte et
les mesas ; jungle givrée en froid, rouge et noire dans une brume volcanique en chaud).

| Code | Climat lisible | Composition gardée |
| --- | --- | --- |
| coast cold | faible : mer pâle et écumeuse, falaise sans neige | oui |
| coast hot | oui : vapeur sur la mer, fumées | oui |
| mesas cold | oui : plaine et buttes enneigées | oui |
| mesas hot | oui : terre rouge, fumées | oui |
| jungle cold | oui : plantes givrées, blanches | oui |
| jungle hot | oui : feuilles rouges, brume | oui |

Décision : toutes retenues par l'utilisateur (2026-11-20) sauf jungle cold : « on voit vraiment pas la neige ».

## Reprise du jungle froid

`site` renforcé : « The whole valley is blanketed in deep white snow and snowdrifts … buried under thick white snow
and hung with long icicles ». Même source et seed.

| Code | `denoise` | Neige lisible | Composition gardée |
| --- | --- | --- | --- |
| s90 | 0,90 | oui : plantes et sol enneigés | oui |
| s93 | 0,93 | oui, plus blanc | oui |
| s95 | 0,95 | oui, le plus blanc | oui, plantes un peu redessinées |

Décision : aucune. Utilisateur : pas de neige sur la roche du premier plan (25 % de l'image). Le `view` disait « plain bare rocky ground » ; reprise en série 113.
