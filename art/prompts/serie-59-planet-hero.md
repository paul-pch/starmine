# Série 59 — planet_hero

Charte : `art/style/hero_prompt.md`. Modèle Qwen-Image-2.1 (int8), 25 pas, cfg 1, euler/simple,
1792 × 768 (21:9), seeds 4242 et 7777. Export prévu 1260 × 540.

## Fiche

```yaml
id: planet_hero.temperate   # puis cold et hot par déclinaison (denoise 0,90)
sujet: panorama au sol de la planète rocheuse, vu d'une crête, sur une vallée
élément clé: géante gazeuse et une lune dans le ciel ; colonie lointaine éclairée
cadrage: 21:9, horizon dans la moitié haute ; tiers bas = sol rocheux sans élément (bandeau du nom)
interdit: texte, interface, végétation, colonie qui domine l'image
critères:
  - colonie visible mais petite, au pied d'une falaise, lumières allumées
  - une géante gazeuse et une seule lune, nettes, dans les deux tiers du haut
  - tiers bas sans élément important (masqué par le bandeau)
  - structure cohérente au zoom (colonie, astres), pas de texte
  - lisible au format téléphone (420 × 180, bandeau simulé)
  - les 2 seeds respectent les mêmes critères
```

Choix de l'utilisateur (Q/R, 2026-11-10) : panorama au sol, colonie lointaine avec lumières, géante
gazeuse et lune.

## Essai e1

Prompt (complet dans `run.json`) : charte telle quelle.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Colonie petite, au pied d'une falaise | réussi : dômes et tours sur le fond de vallée, falaises derrière | à moitié : petite, mais posée au bord du plateau, pas au pied d'une falaise |
| Lumières allumées | raté : plein jour, aucune lumière lisible | raté |
| Géante + une lune | réussi | raté : géante, une seconde planète rayée et une lune |
| Tiers bas libre | réussi : sol rocheux de la crête | réussi |
| Structure, pas de texte | réussi | réussi |
| Lisible au format téléphone | réussi : géante et colonie se lisent tout de suite | réussi, géante un peu coupée en haut |
| 2 seeds identiques | raté (astres, colonie) | |

Hypothèse pour la suite : les lumières disparaissent avec « warm low sunlight » en plein jour. Le
critère est peut-être inutile, puisque la colonie se lit déjà par sa silhouette. Question posée à
l'utilisateur.

## Essais e2 à e4 (retour de l'utilisateur sur e1)

Retour de l'utilisateur : l'image est trop lumineuse, et le cadrage trop large pour un téléphone, il
faut cadrer plus près. Pour séparer les deux effets, j'ai fait trois variantes, avec les mêmes seeds :

- e2 : lumière seule. Nouveau bloc `light` de la charte (le texte de e1 en devient la valeur par
  défaut), remplacé par « dark low-key image with subdued exposure, dim late-afternoon light, deep
  long shadows, dark muted neutral grey palette, light atmospheric haze ».
- e3 : cadrage seul. Changement en chaîne : « crête basse, près de la colonie » dans `view`, et
  dans `subject` une colonie « in the middle distance … spanning about a third of the frame width ».
  Le `detail` de e1 (« only a small detail ») contredisait ce cadrage, je l'ai remplacé par « The
  colony and the sky above it share the frame, both large and clearly visible ».
- e4 : e2 et e3 ensemble.

Luminance moyenne (0 à 255, image réduite) : e1 120 ; e2 55 ; e3 116 ; e4 52.

| Critère | e2 4242 | e2 7777 | e3 4242 | e3 7777 | e4 4242 | e4 7777 |
| --- | --- | --- | --- | --- | --- | --- |
| Moins lumineux | réussi | réussi | raté (inchangé) | raté | réussi | réussi |
| Colonie plus grande | non (inchangé) | non | un peu | réussi, ~1/3 de la largeur | réussi, ~1/3 | réussi, ~1/3 |
| Géante + une lune | réussi | réussi | réussi | réussi | réussi | réussi |
| Lumières allumées | raté | raté | raté | raté | raté | raté |
| Tiers bas libre | réussi | réussi | réussi | réussi | réussi | réussi |
| Pas de texte, structure | réussi | réussi | réussi | réussi | réussi | réussi |

Les deux changements agissent séparément, sans effet visible de l'un sur l'autre. e4 est le seul
essai où les deux seeds passent les critères de lumière, de cadrage et d'astres. Les lumières
restent invisibles, même dans l'image sombre.

## Essais e5 et e6 (retour de l'utilisateur sur e2 à e4)

Retour de l'utilisateur : la taille d'e3-temperate-7777 lui convient. Il n'a pas répondu non à l'idée
de voir la colonie, mais le terrain est triste : il faut une scène plus optimiste. Il craint aussi
pour l'affichage sur un téléphone en vertical. Réponse : le hero n'est pas recadré, il s'affiche en
entier sur la largeur de l'écran (environ 400 × 170 dp), et la simulation à 420 × 180 correspond à ce
cas. Le critère des lumières est abandonné : la colonie se lit à sa silhouette.

- e5 : e3, plus un `light` optimiste : « hopeful and optimistic mood, bright golden-hour sunlight
  with rich warm tones on the rock, crisp clear air with good contrast, a deep clear blue-teal sky,
  the colony gleaming white and sunlit ».
- e6 : e5, plus une colonie en activité dans `detail` (petits vaisseaux au-dessus de la colonie,
  véhicules sur une route claire qui y mène).

Luminance moyenne : e5 108 et 105 ; e6 108 et 104 (e1 : 120). L'image n'est pas plus claire, mais
plus contrastée et plus colorée.

| Critère | e5 4242 | e5 7777 | e6 4242 | e6 7777 |
| --- | --- | --- | --- | --- |
| Ambiance optimiste (ciel bleu, roche dorée) | réussi | réussi | réussi | réussi |
| Colonie au cadrage d'e3 | réussi | réussi, même composition qu'e3 | réussi | réussi |
| Géante + une lune | réussi (soleil en plus) | réussi | réussi | réussi |
| Tiers bas libre | réussi | réussi | réussi | la route descend dans le tiers bas, sans gêne |
| Structure | réussi | bord droit de la géante qui se fond dans le ciel | réussi | même défaut |
| Activité visible | sans objet | sans objet | vaisseaux minuscules | réussi : vaisseaux et route lisibles |

## Retenue : e6-temperate-7777 (2026-11-10)

L'utilisateur l'a validée telle quelle, avec le bord de la géante un peu fondu. Elle devient
`planet_hero.temperate` v1 au registre.

## Déclinaisons d1 (froid, chaud)

Elles repartent d'e6-temperate-7777 avec la seed 7777 et `denoise` 0,90. Seul `site` change ; les
textes sont adaptés de la charte des bâtiments (vallée au lieu de pied de falaise).

| Critère | d1-cold-7777 | d1-hot-7777 |
| --- | --- | --- |
| Composition d'e6 conservée | réussi : colonie, route, vaisseaux, astres | réussi |
| Climat lisible | à moitié : neige dans la vallée et sur les montagnes, mais la crête du premier plan et le flanc des falaises restent bruns, avec un peu de givre | réussi : terre rouge-brun, fissures de lave sur la falaise de droite, colonnes de fumée |
| Ambiance optimiste conservée | réussi | réussi |
| Bord de la géante | net (corrigé par la passe) | net |
