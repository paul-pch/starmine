# Séries 26 et 27 : mine de cristal, froid et chaud

Première application de la règle de l'utilisateur : même seed que l'image t1 retenue, et départ depuis
l'image validée, pour limiter la dérive du paysage. Fichiers : `serie-26-crystal-mine.json`,
`serie-27-crystal-mine.json`, charte `art/style/base_prompt.md`, inchangée. Qwen-Image-2.1, seed 4242,
source `serie-09-crystal-mine/crystal_mine-4242`, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`.
10 images. Fiche : `serie-19-temperature.md`.

## Essai 1

Seul `denoise` varie : 0,60 ; 0,75 ; 0,85 (série 26) ; 0,90 ; 0,95 (série 27). Les `site` sont ceux de la
mine de métal retenue : neige de la série 20, rouge sourd de la série 21.

Hypothèse : à partir de l'image validée, un seuil de `denoise` installe le climat sans déplacer le
paysage.

### Notes proposées par Claude

10 images vues en taille réelle. L'utilisateur n'a pas encore noté.

| Critère | 0,60 | 0,75 | 0,85 | 0,90 | 0,95 |
| --- | --- | --- | --- | --- | --- |
| Paysage et portail en place | oui | oui | oui | oui | oui |
| Froid lisible | non | non : sol pâle | moyen : givre | oui : neige | oui : neige |
| Chaud lisible | non | moyen : sol brun | moyen : sol rouge-brun | oui | oui |
| Cristaux nets, froid | oui | oui | oui | moyen : aspect givré | moyen : aspect givré |
| Cristaux nets, chaud | oui | oui | oui | oui | oui |

### Observations

- Hypothèse confirmée : le seuil se situe entre 0,85 et 0,90. Portail, convoyeur, falaise et rochers
  restent en place jusqu'à 0,95.
- Froid : dès 0,90, les cristaux se couvrent de givre et se confondent en partie avec la neige.
- Chaud 0,90 : le petit massif de cristaux à la base gauche disparaît. À 0,95, il est remplacé par des
  cristaux dans la roche, et la fumée est plus forte.
- La lave reste discrète sur la falaise, avec un foyer de feu au loin dans les deux cas.
- Le camion et quelques détails changent légèrement, comme le bâtiment du bas en froid.

## Retour de l'utilisateur

`d90-crystal_mine_cold-4242` et `d90-crystal_mine_hot-4242` sont retenues, plutôt que les 0,95 proposées par
Claude. Réglage pour la suite : `denoise` 0,90.
