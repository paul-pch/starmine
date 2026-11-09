# Série 18 : chantier spatial, vaisseau dans la fosse

Suite de la série 03, décidée par l'utilisateur. Fichiers : `serie-18-shipyard.json`, charte
`art/style/base_prompt.md`, inchangée. Qwen-Image-2.1, seeds 4242 et 7777, 1024 × 1024, 25 passes,
cfg 1, `euler` / `simple`. 4 images. Prompts complets : `run.json`, dans le dossier de sortie.

## Fiche

Demande de l'utilisateur : garder la fosse de `shipyard-4242` (série 03), « hyper bien », y mettre un
vaisseau et non une fusée, sans image trop poussiéreuse.

```yaml
id: building.shipyard.t1
sujet: cale à ciel ouvert, taillée dans la roche, avec un vaisseau à l'intérieur
élément clé: le vaisseau, qui ne ressemble pas à une fusée
cadrage: vue haute, de loin, chantier entier
interdit: fusée dressée, image trop poussiéreuse
critères:
  - fosse droite proche de la série 03
  - vaisseau reconnu à 512 px, pas une fusée
  - vaisseau cohérent au zoom
  - moins de poussière que la série 03
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

- Variante A : seul le `detail` change. « rises vertically » devient une coque large, plate et
  anguleuse, à ailes en flèche, en vol stationnaire à plat, dans l'axe de la cale.
- Variante B : A, plus un `state` propre (« spotlessly clean », « clear air », sol de cale propre).

Hypothèses : le vol vertical causait la fusée ; le `state` réduit la poussière sans changer la
composition.

### Notes proposées par Claude

4 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | A-4242 | A-7777 | B-4242 | B-7777 |
| --- | --- | --- | --- | --- |
| Fosse droite proche de la série 03 | moyen : parois de roche brute | oui | moyen : parois de roche brute | oui |
| Vaisseau reconnu à 512 px, pas une fusée | oui | oui | oui | oui |
| Vaisseau cohérent au zoom | moyen : bloc plat, sans moteur visible | moyen : grande ouverture à l'avant | moyen : bloc plat, sans moteur visible | moyen : grande ouverture à l'avant |
| Moins de poussière que la série 03 | moyen | moyen : roche au premier plan | oui | moyen : sol net, roche au premier plan |
| Mêmes critères sur les 2 seeds | non : fosse et vaisseau différents | non | non | non |

### Observations

- Première hypothèse confirmée : plus aucune fusée sur les 2 seeds.
- Deuxième hypothèse confirmée : la composition reste très proche entre A et B. L'effet porte surtout
  sur le sol et l'air, peu sur la roche nue.
- « bright engine glow » est presque perdu : une seule lueur sur 7777, aucune nette sur 4242.
- 4242 : le vaisseau ressemble à une dalle, et un second petit vaisseau apparaît sur le rebord en A.
- 7777 : vaisseau plus élégant, parois proches de la série 03, mais grues lointaines en B.

## Retour de l'utilisateur

`B-shipyard-4242` est sélectionnée, malgré la recommandation de Claude pour `B-shipyard-7777`. Elle
remplace `shipyard-4242` de la série 03 dans la sélection.
