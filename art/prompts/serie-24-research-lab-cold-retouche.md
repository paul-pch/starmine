# Séries 24 et 25 : laboratoire de recherche, froid, sans la tente

Retouche de `serie-20-temperature/research_lab_cold-4242`, demandée par l'utilisateur : la tente à gauche
gêne, le reste est parfait. Outil : `tool/comfy_inpaint.py`. Qwen-Image-2.1, 25 passes, cfg 1, `euler` /
`simple`, zone `240 398 302 468`, bords adoucis. Hors de la zone, l'image reste identique à la source.

Prompt de la zone : « Flat plateau ground blanketed in deep white snow with smooth snowdrifts, realistic
sci-fi concept art, warm low sunlight, long soft shadows. »

Hypothèse : régénérer le prompt complet changerait toute l'image ; une retouche locale ne change que la tente.

| Série | Denoise | Seed 4242 | Seed 7777 |
| --- | --- | --- | --- |
| 24 | 0,85 | raté : la tente revient, plus grande | réussi : petite structure grise et brune |
| 25 | 1,0 | raté : la tente revient en masse | réussi : proche de la série 24 |

La neige demandée n'apparaît sur aucune image : la zone reste occupée par une structure. Le résultat
dépend de la seed, pas du denoise.

Proposition de Claude : `serie-24-research-lab-cold-retouche/research_lab_cold-7777.png`.

## Retour de l'utilisateur

`raw-research_lab_cold-7777` est « parfaite ». C'est la sortie directe du modèle, avant recomposition sur la
source : hors de la zone, elle n'est donc pas identique au pixel près à la source. Le même nom existe dans
les séries 24 et 25 ; Claude retient celle de la série 24, sa proposition.
