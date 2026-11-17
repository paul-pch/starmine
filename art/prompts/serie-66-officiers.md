# Série 66 — officiers (character.<clé>)

Catégorie `character` de la spec 11 : 8 portraits buste, 1:1, export 512 px, cartes de l'écran Officiers (spec 12).
Charte `art/style/character_prompt.md` (créée pour cette série). Modèle Qwen-Image-2.1 (int8), 25 pas, cfg 1,
euler/simple, 1024 × 1024. Seeds 4242 et 7777.

## Fiche (Q/R avec l'utilisateur, 2026-11-17)

```yaml
id: character.<clé>
sujet: un officier en buste, face au spectateur
élément clé: le lieu de son métier, flou derrière lui, et un geste ou un objet du métier
cadrage: tête et épaules dans les deux tiers hauts, léger trois-quarts, regard vers nous
interdit: texte, insigne lisible, logo, écran d'interface, casque
critères:
  - on devine le métier sans le nom, à 256 px
  - tête nue, tenue de travail blanche et grise avec l'accent du métier
  - aucun texte, aucune lettre, aucun logo ni écusson
  - visage net et naturel, mains correctes
  - les 2 seeds respectent les mêmes critères
```

Casting : géologue (femme, 50 ans, Asie de l'Est, orange), technocrate (homme, 60 ans, Asie du Sud, bleu),
architecte (femme, 30 ans, noire, jaune), ingénieur (homme, 40 ans, latino, rouge), commandant (femme, 50 ans,
Afrique du Nord, or), directeur scientifique (homme, 40 ans, Europe du Nord, sarcelle), chef de chantier (femme,
40 ans, Asie du Sud-Est, ambre), amiral (homme, 60 ans, Afrique de l'Est, argent).

## Revue c1 (512 px)

| Officier | Métier lisible | Sans texte ni logo | Remarques |
| --- | --- | --- | --- |
| geologist | oui : galerie, convoyeur, minerai en main | 4242 : écusson à lettres sur l'épaule ; 7777 : oui | 7777 a un col rigide de scaphandre |
| technocrat | oui : dôme vitré, fiole de cristal bleu | oui | 4242 : cristal net ; 7777 : fiole petite |
| architect | oui : bras robotisés | 4242 : oui ; 7777 : petit écusson | instrument tenu comme un outil, ambigu |
| engineer | moyen : la tourelle ressemble à un char | **non** : écusson « F » sur les 2 | crâne rasé (non demandé), clé sur l'épaule |
| commander | oui : colonie et grues, bras croisés | **non** : écusson sur les 2, galon sur 7777 | |
| research_director | oui : labo et chercheurs | oui | crâne rasé (non demandé) |
| shipyard_master | oui : coque de vaisseau en chantier | 4242 : logo sur l'épaule ; 7777 : oui | |
| admiral | oui : passerelle et espace | oui (consoles floues en bas) | |

Constats : le métier se lit sur les 8 grâce au fond. Le critère « sans logo » échoue souvent : la tenue
d'officier ou de travail appelle un écusson d'épaule, malgré « no badge » en fin de prompt (le négatif écrit ne
suffit pas, voir les règles apprises). Hypothèse pour c2 : décrire ce qu'on veut voir, « plain sleeves and
shoulders without any patch », dans le bloc `outfit` de la charte, pour toutes les images.

Décision : à l'utilisateur.

## Sélection c1 (utilisateur, 2026-11-17)

Retenues : `admiral` **c1-admiral-4242**, `architect` **c1-architect-7777**, `commander` **c1-commander-7777**,
`geologist` **c1-geologist-7777**, `research_director` **c1-research_director-7777**, `shipyard_master`
**c1-shipyard_master-4242**, `technocrat` **c1-technocrat-7777**. Inscrites au registre en `validated` v1.

`engineer` à refaire : « le buste est bizarre » (grosse clé en travers de l'épaule, main gantée déformée).

## c2 — ingénieur

- c2a : `detail` seul changé, sans objet : « He stands with his arms relaxed at his sides, his hands out of the
  frame. »
- c2b : même `detail`, et `site` avec une tourelle fixe sur socle en béton, « with no tracks and no wheels ».

| Code | Buste | Tourelle | Sans texte ni logo | Remarques |
| --- | --- | --- | --- | --- |
| c2a-engineer-4242 | **non** : plan en pied, la caméra recule | char à chenilles | écusson à damier | |
| c2a-engineer-7777 | oui, jusqu'à la taille | char | écusson gris uni | |
| c2b-engineer-4242 | **non** : plan en pied | tourelle sur socle | écusson à damier | |
| c2b-engineer-7777 | oui, jusqu'à la taille | tourelle sur socle, lisible | écusson gris uni, sans lettre | la plus proche de la fiche |

Constats : « hands out of the frame » ne tient pas sur 4242, qui recule la caméra (cadre en pied) ; le cadrage
buste revient sur 7777. Le socle et « no tracks » retirent le char (c2b, 2 seeds).

Décision : à l'utilisateur.

Retour de l'utilisateur sur c2 : « remets-lui une clé à molette, les accessoires c'est important ». Règle : garder
l'objet du métier et corriger la pose, jamais retirer l'objet.

## c3 — ingénieur, clé à molette tenue autrement

Base c2b (tourelle sur socle). `outfit` : mains nues, sans gants (la main gantée était déformée en c1). Deux
gestes :

- c3a : « holds a large adjustable wrench upright in his right hand in front of his chest, its head next to his
  shoulder » ;
- c3b : « holds a large adjustable wrench in his right hand, resting its handle on his shoulder, his elbow bent
  naturally ».

| Code | Buste | Clé et main | Tourelle | Sans texte ni logo |
| --- | --- | --- | --- | --- |
| c3a-engineer-4242 | oui | clé droite, main correcte ; clé petite | sur socle | oui |
| c3a-engineer-7777 | oui, serré | clé nette contre l'épaule, main correcte | sur socle, lisible | oui |
| c3b-engineer-4242 | oui | grande clé en travers de l'épaule, main naturelle | sur socle | oui |
| c3b-engineer-7777 | oui | clé devant la poitrine, main correcte | sur socle | oui (bande rouge sans lettre) |

Constats : le cadrage buste revient sur les 2 seeds avec un objet tenu près du visage ; mains nues sans
déformation. Tous les critères passent.

Décision : à l'utilisateur.

## Sélection c3 (utilisateur, 2026-11-17)

`engineer` : **c3b-engineer-4242**. Inscrite au registre en `validated` v1. Les 8 officiers sont faits.
