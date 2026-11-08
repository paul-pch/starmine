# building.metal_mine.t1

## Fiche

```yaml
id: building.metal_mine.t1
sujet: installation mécanique d'extraction, en contrebas
élément clé: filons métalliques visibles dans la roche
cadrage: vue plongeante, installation centrée et dominante
interdit: engin de chantier type pelleteuse, carrière vide, texte
critères:
  - l'installation est le sujet dominant
  - sa structure reste cohérente au zoom (appuis, assemblages, symétrie)
  - les filons se distinguent nettement de la roche
  - les filons se lisent comme du minerai, ni eau ni lave
  - on reconnaît une mine de métal en vignette de 512 px
  - les 2 seeds respectent les mêmes critères
```

Décision de l'utilisateur : une fosse seule fait carrière ; on veut une installation mécanique
en contrebas, avec des filons visibles.

## Essais

### Essai 1 : comparaison de modèles

Seeds 4242 et 7777, 1024 × 1024. Notes proposées par Claude, en attente de l'avis de
l'utilisateur.

Réglages :

- SDXL base 1.0 : 40 passes, cfg 6, `dpmpp_2m` / `karras`.
- Z-Image Turbo (bf16) : 8 passes, cfg 1, `res_multistep` / `simple`, shift 3. Pas de prompt
  négatif effectif.
- FLUX.2 klein base 4B : 20 passes, cfg 5, `euler`.

Prompt :

> High-angle view looking down into a rocky basin on a barren alien planet. At the center stands
> a compact metal mining installation: a steel lattice headframe tower with a large hoist wheel
> on top, a rectangular machinery building with riveted panels, and a straight conveyor rising to
> an ore hopper. The dark rock walls around it are cut by bright veins of raw metallic ore, silver
> and copper, clearly visible. Realistic sci-fi concept art, photorealistic materials, soft
> overcast light, sharp focus.

Négatif (SDXL et klein) : excavator, bulldozer, construction vehicle, text, watermark, logo,
signature, cartoon, anime, blurry, low quality, deformed structure

| Critère | SDXL 4242 | SDXL 7777 | Z-Image 4242 | Z-Image 7777 | klein 4242 | klein 7777 |
| --- | --- | --- | --- | --- | --- | --- |
| Installation dominante | réussi | réussi | réussi | réussi | réussi | raté |
| Structure cohérente au zoom | raté | raté | raté | raté | raté | raté |
| Filons distincts de la roche | raté | raté | réussi | réussi | réussi | réussi |
| Mine de métal reconnue à 512 px | raté | raté | réussi | réussi | raté | raté |

Mêmes critères respectés sur les 2 seeds : SDXL oui, Z-Image oui, klein non.

Observations :

- SDXL ignore le prompt : structure circulaire, sans tour à treillis, roue, convoyeur ni filons.
- Z-Image rend tous les éléments demandés sur les 2 seeds, mais la roue est posée à plat comme un
  plateau, et il ajoute un second convoyeur. Les filons ressemblent à du ruban de métal plié.
- klein place la roue debout, ce qui est juste, mais la tour fusionne avec le bâtiment, les filons
  ressemblent à de la lave, et la trémie manque.

Proposition : retenir Z-Image Turbo. Essai suivant, un seul changement : décrire la roue debout,
car ce critère de géométrie échoue sur les 2 seeds.

Retour de l'utilisateur : SDXL a une pâte SF plus marquée ; Z-Image et klein sont schématiques,
klein même cubique. Faut-il un prompt plus général pour ces deux modèles ? La proposition de
corriger la roue n'a donc pas été suivie.

### Essai 2 : description générale de l'installation

Mêmes modèles, réglages, seeds et négatif. Hypothèse : la liste d'objets industriels ordinaires
produit le rendu schématique. Seul changement, la description de l'installation :

> a large futuristic metal mining complex, advanced sci-fi industrial machinery with layered
> structures and intricate mechanical detail

Notes proposées par Claude. SDXL noté sur la planche à 512 px seulement, donc sans note de zoom.

| Critère | SDXL 4242 | SDXL 7777 | Z-Image 4242 | Z-Image 7777 | klein 4242 | klein 7777 |
| --- | --- | --- | --- | --- | --- | --- |
| Installation dominante | réussi | réussi | réussi | réussi | réussi | réussi |
| Structure cohérente au zoom | non noté | non noté | réussi | réussi | raté | réussi |
| Filons distincts de la roche | raté | raté | réussi | réussi | réussi | réussi |
| Mine de métal reconnue à 512 px | raté | raté | raté | raté | raté | raté |

Observations :

- Hypothèse confirmée pour Z-Image : pâte SF nette et structures symétriques et cohérentes.
- Contrepartie : plus aucune fonction de mine lisible, on croit voir un réacteur ou une tour.
- Z-Image ajoute des tracés de circuit au sol (4242), et les filons virent à la lave (7777).
- klein reste un empilement de boîtes : le défaut cubique ne vient pas seulement du prompt.
- SDXL garde son style, toujours sans filons.

Proposition : retenir Z-Image et rendre la fonction de mine avec un seul ajout, un puits de forage
central, sans revenir à la liste d'objets.

Retour de l'utilisateur : garder l'ambiance de SDXL, dont le contenu et la précision resteront
limités ; essayer une base SDXL retravaillée par klein ou Z-Image avec une charte graphique
précise. La proposition du puits seul n'a donc pas été suivie telle quelle.

### Essai 3 : base SDXL retravaillée

Sources : images SDXL de l'essai 2, retravaillées avec leur seed. Le prompt change en même temps
que le procédé : ce n'est pas un test à une seule variable, mais un test de faisabilité.

- Z-Image : img2img, denoise 0,45 et 0,65, autres réglages inchangés.
- klein base 4B : édition par `ReferenceLatent` (template ComfyUI), 20 passes, cfg 5.

Contenu commun :

> a large futuristic metal mining complex in a red-brown rocky canyon on a barren alien planet. A
> central drilling shaft descends into the ground, and a conveyor carries ore from the shaft to
> the complex. Thick veins of raw silver and copper ore run through the red rock walls, dull
> natural metal, unlit.

Charte commune :

> Art direction: gritty realistic sci-fi concept art, weathered dark gunmetal machinery, warm low
> sunlight, long soft shadows, muted red-brown palette, atmospheric haze.

Préfixe Z-Image : « High-angle view of ». Préfixe klein : « Edit this image. Keep the same camera
angle, composition, rock shapes, lighting and color palette. Turn the structure into ».
Négatif klein : excavator, bulldozer, text, watermark, logo, cartoon, blurry, lava, glowing cracks.

Observations de Claude, à faire noter par l'utilisateur :

- Z-Image 0,45 : ambiance et composition gardées, plus de détails, mais ni filons ni fonction de
  mine.
- Z-Image 0,65 : tour de forage visible, mais les filons deviennent des chaînes et des tuyaux, et
  des billes et bobines jonchent le sol. Tour coupée en haut sur 7777.
- klein 4242 : filons intégrés aux strates de roche, puits et convoyeur lisibles, ambiance gardée.
  Mais vue moins plongeante, composition de la base non respectée, silhouette de ville, et le
  convoyeur finit dans le vide.
- klein 7777 : composition de la base gardée, mais une coulée grise dans le puits fait cascade.

Proposition : retenir la chaîne SDXL puis édition klein, et corriger un défaut à la fois.

Décision de l'utilisateur : chaîne validée, essai suivant sur la vue plongeante.

### Essai 4 : vue plongeante

Même chaîne, sources, seeds, contenu, charte et négatif que klein à l'essai 3. Hypothèse : klein
recule la caméra parce que rien ne lui impose le point de vue. Changement : le préfixe devient

> Edit this image. Keep the same rock shapes, lighting and color palette. Change the viewpoint to
> a steep aerial view looking down from high above: the complex sits at the bottom of the canyon,
> far below the camera, with no horizon and no sky visible. Turn the structure into

La demande de garder l'angle et la composition est retirée, car elle contredirait le nouveau point
de vue.

Notes proposées par Claude :

| Critère | klein 4242 | klein 7777 |
| --- | --- | --- |
| Installation dominante | réussi | réussi |
| Structure cohérente au zoom | raté | réussi, à confirmer |
| Filons distincts de la roche | réussi | réussi |
| Mine de métal reconnue à 512 px | raté | réussi |

Les 2 seeds ne respectent pas les mêmes critères.

Observations :

- Vue plongeante sans horizon obtenue sur les 2 seeds. La cascade de 7777 a disparu, et le
  convoyeur ne finit plus dans le vide.
- 7777 : installation au fond du canyon, machinerie crédible, filons naturels. À vérifier : le bras
  incliné du mât et le convoyeur, qui sort du cadre et occupe tout le premier plan.
- 4242 : un grand cylindre sort du trou et fait silo, donc pas vraiment en contrebas. Le convoyeur
  est plaqué dessus, sans lien clair avec un puits. Le plateau circulaire de la base semble imposer
  cette forme.

Proposition : un seul changement, décrire un complexe bas et large posé au fond du canyon.

Retour de l'utilisateur sur 7777 : image intéressante, mais les filons ressemblent à des chutes
d'eau, ce qui contredit la note « filons naturels » de Claude. Et la couleur de la roche ne convient
qu'à une planète de type désert ou Mars.

Décisions de l'utilisateur : tester une roche neutre, car un bâtiment n'a qu'une image quelle que
soit la planète ; ajouter à la fiche le critère « les filons se lisent comme du minerai, ni eau ni
lave ».

### Essai 5 : roche neutre

Nouvelles bases SDXL, même chaîne, seeds, point de vue et négatif klein que l'essai 4. Hypothèse :
l'ambiance survit à une roche neutre.

Base SDXL, 2 changements par rapport à l'essai 2 : « dark neutral grey basalt rock walls » dans le
prompt, et « red rock, orange rock, mars, desert, sand » ajoutés au négatif.

Édition klein, seules les couleurs changent : « neutral grey rocky canyon », « dark grey rock
walls », « muted neutral grey palette ».

Notes proposées par Claude :

| Critère | klein 4242 | klein 7777 |
| --- | --- | --- |
| Installation dominante | réussi | réussi |
| Structure cohérente au zoom | réussi, à confirmer | réussi, à confirmer |
| Filons distincts de la roche | réussi | réussi |
| Filons lus comme du minerai | raté | raté |
| Mine de métal reconnue à 512 px | réussi | raté |

Les 2 seeds ne respectent pas les mêmes critères.

Observations :

- Le rouge a disparu, mais la roche tire sur le beige, donc reste un peu aride.
- Le changement n'a pas porté que sur la couleur : la base SDXL ne montre plus aucune roche, seule
  la machine remplit l'image. klein a inventé le canyon.
- Effets secondaires : un horizon revient sur 4242, et l'installation est une haute tour qui sort
  du canyon, donc pas en contrebas.
- Filons toujours longs et verticaux, encore proches de coulées, surtout sur 7777.
- Ambiance plus sobre, proche d'une photo de canyon terrestre, moins SF.
- Détail réussi sur 4242 : du minerai visible dans les bennes en haut de la structure.

En attente : l'avis de l'utilisateur sur l'ambiance.

Retour de l'utilisateur : le rendu de l'essai 5 ne convient pas ; il demande de tester
Qwen-Image-2.1 et accepte sa licence de recherche pour ce test, sans rien publier.

### Essai 6 : Qwen-Image-2.1 seul

Génération directe, sans base SDXL. `qwen_image_2.1_int8_convrot`, encodeur
`qwen3vl_8b_int8_convrot`, 25 passes, cfg 1, `euler` / `simple`, réécriture de prompt désactivée.
Licence : Qwen Research, usage limité à la recherche et à l'évaluation. Avec cfg 1, le négatif n'a
probablement pas d'effet.

Prompt :

> High-angle view looking down into a rocky basin on a barren alien planet. At the center stands a
> large futuristic metal mining complex, advanced sci-fi industrial machinery with layered
> structures and intricate mechanical detail. The dark neutral grey basalt rock walls around it are
> cut by bright veins of raw metallic ore, silver and copper, clearly visible. Art direction: gritty
> realistic sci-fi concept art, weathered dark gunmetal machinery, warm low sunlight, long soft
> shadows, muted neutral grey palette, atmospheric haze.

Notes proposées par Claude :

| Critère | Qwen 4242 | Qwen 7777 |
| --- | --- | --- |
| Installation dominante | réussi | raté |
| Structure cohérente au zoom | raté | raté |
| Filons distincts de la roche | réussi | réussi |
| Filons lus comme du minerai | réussi | réussi |
| Mine de métal reconnue à 512 px | raté | raté |

Les 2 seeds ne respectent pas les mêmes critères.

Observations :

- Meilleure roche et meilleurs filons de la série : roche sombre et crédible, filons pris dans la
  masse, ni lave ni ruban. Quelques filons blancs de 7777 pourraient passer pour de la glace.
- Installation enfin en contrebas, au fond de la cuvette, avec une composition stable d'une seed à
  l'autre.
- Point faible : la machine est un amas de blocs sombres, sans fonction lisible, et trop petite sur
  7777.
- Trame fine visible sur les zones de terrain, à surveiller. Cause non établie.

Proposition : garder Qwen et resserrer le cadrage sur l'installation, un seul changement.
