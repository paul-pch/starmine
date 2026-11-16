# Série 63 — vaisseaux pirates (pirate)

Catégorie `pirate` de la spec 11 : `pirate.<clé YAML>`, les 6 vaisseaux des flottes pirates, version pirate (coque
disparate, marquages), 1:1, 512 px. Pas encore de charte propre : base `art/style/unit_prompt.md`, bloc
« Vaisseaux » (vue rapprochée, même fond d'espace que les vaisseaux du joueur). Modèle Qwen-Image-2.1 (int8),
25 pas, cfg 1, euler/simple.

Demande de l'utilisateur (2026-11-13) : 3 propositions par vaisseau.

## Fiche commune

```yaml
id: pirate.<clé>
sujet: le même type de vaisseau que l'unité du joueur, en version pirate
élément clé: silhouette du vaisseau du joueur reconnaissable ; coque rapiécée, rouille, plaques dépareillées
cadrage: celui des vaisseaux de la série 58 (vue de trois quarts, vaisseau qui remplit le cadre)
interdit: texte, lettres, symboles, tête de mort ou logo ; navire de mer
critères:
  - on reconnaît le type de vaisseau (même silhouette que ship.<clé>)
  - on le distingue au premier coup d'œil du vaisseau du joueur (coque disparate, tuyères orange-rouge)
  - aucun texte ni symbole
  - lisible en vignette (256 px)
```

## p1

Même `subject` que la série 58 ; `state` pirate (plaques de récupération dépareillées, rouille, soudures,
blindage et canons ajoutés, quelques bandes rouge sombre peintes, ni texte ni symbole) ; tuyères « dim smoky
orange-red » au lieu de « bright blue-white », pour séparer les camps (constat série 62).

- p1a : départ de l'image retenue de `ship.<clé>` (série 58), sa seed, `denoise` 0,85.
- p1b : idem, `denoise` 0,92.
- p1c : sans image de départ, seed 4242.

## Revue p1

Comparaison côte à côte avec le vaisseau du joueur retenu (série 58), à 512 px.

| Vaisseau | p1a (0,85) | p1b (0,92) | p1c (seed 4242) |
| --- | --- | --- | --- |
| light_fighter | quasi identique au joueur : tuyère rouge, deux bandes rouges | idem | plus usé, bandes rouges, silhouette proche ; pirate lisible mais discret |
| heavy_fighter | quasi identique, tuyères rouges, une marque rouge | idem | coque plus claire et sale, rouge ; silhouette proche |
| cruiser | quasi identique, tuyère rouge | idem, bandes rouges | coque blanche rapiécée, bande rouge, gros panache rouge ; tour réduite |
| battleship | quasi identique | idem | coque blanche marbrée de rouge, superstructure de navire : silhouette de bateau |
| small_cargo | conteneurs jaunis, bandes rouges | idem | conteneurs fondus dans la coque, cargo moins lisible |
| large_cargo | bandes rouges, tuyères rouges | idem | coque marbrée, chevrons rouges ; silhouette tenue |

Constats : à 0,85 et 0,92, l'image de départ l'emporte, seules la couleur des tuyères et quelques bandes changent ;
en vignette on ne distingue pas le pirate du joueur (critère 2 raté). Sans image de départ, l'usure se voit, mais la
coque reste claire, proche de celle du joueur. Le `state` pirate est trop faible : aucune plaque dépareillée nette.
Hypothèse pour p2 : imposer une **coque sombre** (« dark gunmetal and rust-brown patchwork ») opposée au gris clair du
joueur, et passer le départ à 0,96 pour garder la silhouette sans garder la coque.

## Abandon (utilisateur, 2026-11-13)

Les vignettes par vaisseau pirate ne sont pas utiles. Il faut à la place une image d'annonce du raid pirate à venir
(`scene.raid_incoming`, série 64) et une image par base pirate (`pirate_base.<0-3>`, série 64). Série 63 close
sans image retenue ; constat utile : une coque claire ne distingue pas le pirate du joueur.
