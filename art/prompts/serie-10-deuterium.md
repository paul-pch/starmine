# Série 10 : synthétiseur de deutérium

Fichiers : `serie-10-deuterium.json`, charte `art/style/base_prompt.md`. Qwen-Image-2.1, seeds 4242 et
7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 2 images. Prompts complets : `run.json`, dans
le dossier de sortie.

## Fiche

Réponses de l'utilisateur aux questions proposées : falaise plongeant en mer, sphères de pression,
mer sombre et grise.

```yaml
id: building.deuterium_synthesizer.t1
sujet: usine de synthèse sur une plateforme, au pied d'une falaise qui plonge dans la mer
élément clé: la grappe de sphères de pression géantes
cadrage: charte
interdit: mer prise pour un autre liquide ; aspect abandonné
critères:
  - sphères dominantes, reconnues à 512 px
  - la mer et la falaise sont toutes deux visibles
  - l'eau se lit comme de l'eau, sans couleur terrestre marquée
  - tuyaux reliés à la mer
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

Dérogation à la charte : `site`, avec la falaise qui plonge dans la mer.

Hypothèse : le site garde le lien avec la roche tout en montrant la mer.

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Sphères dominantes, reconnues à 512 px | oui : une sphère géante | oui : une grappe, plus petite |
| Mer et falaise visibles | oui | oui |
| Eau lisible, neutre | oui | oui |
| Tuyaux reliés à la mer | non | non |
| Monumental | oui | moyen |
| Lumières allumées | peu | peu |
| Mêmes critères sur les 2 seeds | oui, sauf monumental | oui, sauf monumental |

### Observations

- Hypothèse confirmée : le site tient la roche et la mer sur les 2 seeds.
- 4242 est la plus monumentale, mais la grosse tuyauterie brillante tire vers le rétrofuturisme.
- 7777 respecte mieux « cluster » et paraît plus sobre, mais moins imposante.
- Aucun tuyau n'entre dans l'eau : le raccord échoue encore, comme pour la foreuse.

## Retour de l'utilisateur

`deuterium_synthesizer-4242` est sélectionnée.
