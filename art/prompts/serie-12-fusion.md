# Série 12 : réacteur à fusion

Fichiers : `serie-12-fusion.json`, charte `art/style/base_prompt.md`, sans dérogation. Qwen-Image-2.1,
seeds 4242 et 7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 2 images. Prompts complets :
`run.json`, dans le dossier de sortie.

## Fiche

Réponses de l'utilisateur aux questions proposées : pied de falaise, tore lumineux, plasma bleu-blanc.

```yaml
id: building.fusion_reactor.t1
sujet: centrale à fusion construite autour d'un immense tore de confinement
élément clé: l'anneau, avec le plasma visible par de larges fenêtres
cadrage: charte
interdit: confusion avec le cylindre de nanites ou la sphère de deutérium
critères:
  - anneau dominant, reconnu à 512 px
  - plasma bleu-blanc visible
  - installation ancrée à la falaise
  - se distingue des autres bâtiments du set
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

Hypothèse : la forme d'anneau donne une silhouette unique dans le set. Le prompt demande un anneau
debout (« upright »).

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Anneau dominant, reconnu à 512 px | oui | oui |
| Plasma bleu-blanc visible | oui | oui |
| Ancrée à la falaise | moyen : devant la paroi | non : détachée, en plaine |
| Distincte du reste du set | oui | oui |
| Anneau debout, comme demandé | non : à plat | non : à plat |
| Mêmes critères sur les 2 seeds | non | non |

### Observations

- Hypothèse confirmée sur la silhouette, mais « upright » est ignoré sur les 2 seeds.
- 4242 : la plus cohérente avec le set, avec sa proximité de la falaise et son anneau intact. L'anneau à
  plat peut évoquer un stade.
- 7777 : architecture plus modulaire et high-tech, mais loin de la paroi, ce qui s'écarte de la charte.

## Retour de l'utilisateur

`fusion_reactor-4242` est sélectionnée. L'anneau à plat
est accepté.
