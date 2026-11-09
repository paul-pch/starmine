# Séries 46 à 48, computer : circuit imprimé dernière génération

Retour de l'utilisateur sur `computer_technology` de la série 42 : pas fan des tubes, préfère une ambiance de circuit
imprimé dernière génération. La couleur cyan convient.

## Série 46 : nouvelle forme

Nouvelle image, seeds 4242 et 7777. Une grande carte verticale dans un cadre fin, avec des processeurs carrés.
Forme réussie sur les 2 seeds et carte bien présente dans le cadre, mais plus aucune lueur cyan. Hypothèse : « matte
black » et la palette sombre de la charte éteignent les traces.

## Série 47 : la lueur

Depuis la série 46, `denoise` 0,75, chaque image avec sa seed. « matte black » retiré, traces « brilliant neon cyan ».
Lueur faible et bleutée, surtout autour de la puce centrale : raté.

## Série 48 : lueur plus forte

Depuis la série 47, `denoise` 0,90, chaque image avec sa seed. Teinte « turquoise-cyan » et traces « like neon tubes ».

| Code | Résultat |
| --- | --- |
| `d90-computer_technology-4242` | traces franchement cyan, en étoile autour de la puce ; carte de biais ; lisible à 256 px |
| `d90-computer_technology-7777` | traces plus fines et plus bleues, puce centrale très lumineuse, tache bleue sur le banc ; lisible à 256 px |

Effet de bord sur les 2 : le hall s'est éclairci à chaque passe et montre de grandes fenêtres claires, alors que la charte
le veut sombre et sans fenêtre. Il contraste avec les autres recherches, et les fenêtres attirent l'œil sur 4242.

## Décision

L'utilisateur retient `d90-computer_technology-7777` et garde le hall tel quel, plus clair que dans les autres recherches.
La revue conseillait la 4242. Master : `art/masters/research.computer_technology/v1.png`.
