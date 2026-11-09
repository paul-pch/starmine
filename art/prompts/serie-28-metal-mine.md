# Séries 28 à 30 : mine de métal, labo et deutérium refaits depuis le t1

Décision de l'utilisateur : refaire avec la règle « seed t1 et départ depuis l'image validée » la mine et le
labo, froid et chaud, et le deutérium chaud. `denoise` 0,90, retenu par l'utilisateur sur la mine de cristal.
Fichiers : `serie-28-metal-mine.json`, `serie-29-research-lab.json`, `serie-30-deuterium.json`, charte
`art/style/base_prompt.md`, inchangée. Qwen-Image-2.1, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`.
5 images. Fiche : `serie-19-temperature.md`.

| Série | Source | Seed | `site` repris de |
| --- | --- | --- | --- |
| 28 | `serie-08-metal-mine/metal_mine-4242` | 4242 | froid : série 20 ; chaud : série 21 |
| 29 | `serie-17-research-lab/research_lab-7777` | 7777 | froid : série 20 ; chaud : série 22 |
| 30 | `serie-10-deuterium/deuterium_synthesizer-4242` | 4242 | chaud : série 23 |

Hypothèse : la composition du t1 reste en place, ce que n'obtenaient pas les séries 19 à 23.

## Notes proposées par Claude

5 images vues en taille réelle, comparées aux sources pour le deutérium et par la planche de sélection pour la
mine et le labo. L'utilisateur n'a pas encore noté.

| Image | Composition du t1 | Climat lisible | Défaut |
| --- | --- | --- | --- |
| `d90-metal_mine_cold-4242` | moyen | oui | le convoyeur devient une large rampe, voitures actuelles |
| `d90-metal_mine_hot-4242` | oui | oui | voitures actuelles |
| `d90-research_lab_cold-7777` | oui | moyen | givre plutôt que neige, ciel plus sombre |
| `d90-research_lab_hot-7777` | oui | oui | colonne de fumée proche d'une trombe |
| `d90-deuterium_synthesizer_hot-4242` | oui | oui | la mer au loin vire au beige, comme du sable |

## Observations

- Hypothèse confirmée sur 4 images sur 5 ; le convoyeur de la mine froide change de forme.
- Deutérium : la grande sphère dominante et la plateforme reviennent.
- Le labo froid reçoit moins de neige que la mine de cristal au même réglage.

## Retour de l'utilisateur

Les 5 images sont retenues. Le deutérium froid de la série 19 reste retenu, bien qu'il précède la règle.
