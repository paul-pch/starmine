# Série 19 : essais de température, froid et chaud

Fichiers : `serie-19-temperature.json`, charte `art/style/base_prompt.md`, inchangée. Qwen-Image-2.1,
seeds 4242 et 7777, 1024 × 1024, 25 passes, cfg 1, `euler` / `simple`. 12 images. Prompts complets :
`run.json`, dans le dossier de sortie.

Trois bâtiments représentent les trois sites : `metal_mine` (falaise), `research_lab` (plateau) et
`deuterium_synthesizer` (mer). Le suffixe `_cold` ou `_hot` de l'`id` sert seulement au code de la
galerie ; il ne préjuge pas de l'id du catalogue. Le `site` étant propre à une image, il ne peut pas
passer par une variante : `comfy_series.py` donne priorité à l'image.

## Fiche

Décisions de l'utilisateur : mer gelée en froid, mer sombre et fumante en chaud, sans lave ; prompt
seul avant tout image-to-image.

```yaml
id: building.<clé>.t1, déclinaisons froid et chaud
sujet: le même bâtiment que la sélection t1, seul le climat change
élément clé: le climat se lit au premier regard
cadrage: inchangé, celui de chaque bâtiment
interdit: lave, matière ambiguë
critères:
  - climat reconnu à 512 px
  - bâtiment proche de la sélection t1 sur la même seed
  - bâtiment reconnu à 512 px
  - aucune matière ambiguë
  - les 2 seeds respectent les mêmes critères
```

## Essai 1

Seul `site` change. Froid : falaise striée de glace, neige, mer gelée. Chaud : basalte brûlé, fissures,
vapeur, mer sombre et fumante.

Hypothèses : `site` suffit à donner le climat ; la même seed garde la composition, sans
image-to-image.

### Notes proposées par Claude

12 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté. Chaque case donne
4242 / 7777.

| Critère | Mine froid | Mine chaud | Labo froid | Labo chaud | Deutérium froid | Deutérium chaud |
| --- | --- | --- | --- | --- | --- | --- |
| Climat reconnu à 512 px | oui / oui | moyen / moyen : aride | oui / oui | moyen / moyen : aride | oui / oui | moyen / moyen : vapeur |
| Bâtiment reconnu à 512 px | oui / oui | oui / oui | oui / oui | oui / oui | oui / oui | oui / oui |
| Aucune matière ambiguë | oui / oui | oui / oui | moyen / moyen : glace ou nuages | oui / oui | oui / oui | oui / oui |

Sur les 3 seeds retenues en t1 (mine 4242, labo 7777, deutérium 4242), la composition est proche de la
sélection, mais les détails du bâtiment changent. Comparaison faite avec la planche de sélection, à
petite taille.

### Observations

- Froid : très lisible. La lumière chaude de la charte ne le gêne pas.
- Chaud : le sol passe au brun et se lit comme un désert aride plus que comme une planète brûlante.
  Il perd aussi le gris neutre.
- Labo froid : « snow-covered » n'a presque pas pris, le plateau reste sombre avec un léger givre.
- Deutérium chaud : la vapeur sort surtout du rivage, pas de la surface de la mer.
- Mine chaud 4242 : l'entrée de galerie est moins nette que sur le froid 4242.
- Les tuyaux du deutérium s'arrêtent sur la plateforme, sans entrer dans la mer ou la glace.

## Retour de l'utilisateur

- Le froid rend le mieux, et la mer de glace est très réussie. Il manque un peu de neige sur les
  éléments terrestres, pour la lisibilité sur téléphone.
- Le chaud manque de fumées, d'un peu de lave et d'une terre plus terracotta.

Suite décidée : série 20. Le deutérium froid n'est pas regénéré.
