# Séries 06 et 07 : mine de métal, bâtiment et foreuse

Suite de la série 05 : l'utilisateur veut garder le rendu de 4242, avec un bâtiment plutôt qu'une
grosse machine seule. Fiche inchangée (`serie-05-metal-mine.md`). Mêmes réglages et seeds. Prompts
complets : `run.json`, dans chaque dossier de sortie.

## Série 06

Fichier : fichier de série supprimé, prompts dans `run.json`. Changement : le `subject` seul, avec un bâtiment à étages ancré
dans la falaise, « from which one giant cylindrical drill head extends and bores into the rock ».

Résultat, 2 images vues en taille réelle et à 512 px : la foreuse pointe vers l'extérieur et ne perce
plus la falaise sur les 2 seeds. Sur 7777, elle ressemble à une épave. Sur 4242, le bâtiment reste un
amas de tuyaux. Claude a relancé un essai sans attendre de retour, car le mix demandé n'était pas
obtenu.

## Série 07

Fichier : fichier de série supprimé, prompts dans `run.json`. Changements : le `subject`, avec un arbre de forage qui part du
bâtiment au pied de la falaise et s'enfonce dans la paroi, tête invisible ; le `detail`, qui ne peut
plus citer la tête de forage.

Hypothèse : sans tête visible et avec le bâtiment au pied de la paroi, la foreuse perce la roche.

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Un bâtiment plutôt qu'une machine | oui | oui |
| Arbre relié au bâtiment | non : tube isolé | oui |
| Arbre qui s'enfonce dans la roche | non : posé contre la paroi | non : posé contre la paroi |
| Filons lisibles comme du métal | oui | moyen : motif de trame |
| Machines éclairées, en activité | non | non |
| Jamais abandonné | oui | moyen : véhicules proches de l'épave |

### Observations

- Hypothèse infirmée : l'arbre longe la paroi vers le haut au lieu d'y entrer.
- 4242 garde le rendu et les filons demandés, avec un vrai bâtiment. Le tube ressemble à une cheminée.
- Le critère « la foreuse perce la roche » a échoué 2 essais de suite. Au troisième échec, le prompt
  n'est plus le bon levier (section 5 du skill).

## Série 08

Décision de l'utilisateur : dernier essai sans foreuse. Fichier : `serie-08-metal-mine.json`.
Changements : le `subject`, avec un bâtiment construit autour de l'entrée d'une galerie et un
convoyeur qui en sort le minerai ; le `detail`, adapté à l'entrée de galerie.

Hypothèse : retirer l'élément qui échoue donne un bâtiment clairement minier, sans problème de
raccord.

### Notes proposées par Claude

2 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Un bâtiment plutôt qu'une machine | oui | oui |
| Bâtiment ancré dans la falaise | oui : portail intégré à la paroi | moyen : posé dans la cavité |
| Mine reconnue à 512 px | oui | oui |
| Convoyeur cohérent | oui | oui |
| Filons lisibles comme du métal | oui | oui, avec motif de trame au zoom |
| Monumental | oui | moyen : bâtiment plus petit |
| Machines éclairées, en activité | non | non |
| Jamais abandonné | oui | moyen : bâtiment terne |

### Observations

- Hypothèse confirmée : la galerie et le convoyeur disent « mine » mieux que la foreuse.
- 4242 reste la meilleure et conserve le rendu que l'utilisateur préfère.
- Les lumières manquent sur toutes les images de mine depuis la série 05.

## Retour de l'utilisateur

`serie-08-metal-mine/metal_mine-4242` est sélectionnée, en recherche et évaluation,
sans ajout de projecteurs.
