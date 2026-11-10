# Série 60 — illustrations d'événements (story)

Charte : `art/style/story_prompt.md`. Modèle Qwen-Image-2.1 (int8), 25 pas, cfg 1, euler/simple,
seeds 4242 et 7777.

## Fiche

```yaml
id: story.<clé>   # mise au point sur rich_vein, solar_storm, unstable_wreck
sujet: l'objet de l'événement (filon, tempête sur la colonie, épave), grand et centré
élément clé: ce qui fait reconnaître l'événement sans titre
cadrage: 16:9, sujet au centre, rien d'important près des bords
interdit: texte, personnage au premier plan, matière ambiguë
critères:
  - l'événement se reconnaît sans son titre, au format popover (350 × 197)
  - le sujet est centré
  - l'ambiance correspond au ton (favorable, néfaste, pari)
  - humains minuscules seulement
  - pas de texte, structure cohérente
  - les 2 seeds respectent les mêmes critères
```

Choix de l'utilisateur (Q/R, 2026-11-10) : sans climat, ambiance selon le ton, vaisseaux et lieux avec
des humains minuscules, 3 scènes types pour commencer.

## e1 (21:9, 1792 × 768)

- solar_storm : réussi sur les 2 seeds (aurores, éclairs sur les pylônes, colonie sombre).
- unstable_wreck : réussi (coque éventrée, soutes, fuite du réacteur, lune).
- rich_vein : raté, le filon blanc passe pour de la neige ou de la glace (matière ambiguë).

Retour de l'utilisateur : le téléphone sera surtout tenu en vertical, et les éléments doivent être
bien centrés. Décision : 16:9 (1664 × 928, export 1280 × 720) pour `story` et `scene`. La popover
passe à 9/16 et la spec 11 est mise à jour.

## e2 (16:9, vue « subject sits in the middle »)

Raté : sur rich_vein et solar_storm, un personnage assis apparaît au centre, au premier plan, sur les
2 seeds. Le mot « sits » appliqué à « subject » a fait naître une personne. L'épave n'est pas touchée.

## e3 (rich_vein seul, matière)

Filon décrit « dark gunmetal grey with a bright polished metallic sheen like steel … clearly metal
and not ice » : il devient métallique. Le personnage d'e2 reste, puisque la vue est inchangée.

## e4 (vue réécrite)

Un seul changement : « the main element of the scene is placed in the middle of the frame … and no
person in the foreground ». rich_vein reprend le sujet d'e3.

| Critère | rich_vein 4242 | rich_vein 7777 | solar_storm 4242 | solar_storm 7777 | wreck 4242 | wreck 7777 |
| --- | --- | --- | --- | --- | --- | --- |
| Pas de personnage au premier plan | réussi | réussi | réussi | réussi | réussi | réussi |
| Centré | bande horizontale sur toute la largeur | idem | réussi (dôme au centre) | réussi | réussi | réussi |
| Reconnaissable | à moitié : le filon ressemble à un gros tuyau métallique | réussi : veine métallique dans la paroi | réussi | réussi | réussi | réussi |
| Ton | réussi | réussi | réussi | réussi | réussi | réussi |

## Retenues (2026-11-10)

L'utilisateur garde e2-rich_vein-4242, e2-solar_storm-7777 et e2-unstable_wreck-4242, donc la vue
d'e2 avec le personnage au premier plan pour les scènes au sol, et le filon clair d'e1/e2. Elles
deviennent `story.<clé>` v1 au registre.

Décision : le témoin de dos devient la règle des scènes au sol, avec la vue d'e2 conservée telle
quelle dans la charte.

## e5 — deuterium_geyser (favorable)

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Reconnaissable (geyser près du synthétiseur) | réussi : jet blanc, sphère de pression derrière | réussi : jet blanc, grande sphère à droite |
| Centré | geyser un peu à gauche du centre | réussi |
| Témoin de dos | réussi | réussi |
| Ton favorable | réussi | réussi |
| Matière | eau et vapeur sans ambiguïté | idem |

Retenue : e5-deuterium_geyser-4242.

## e6 — archaeology (favorable)

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Reconnaissable (ruines, découverte) | réussi : grande arche, chambre éclairée au centre | réussi : portail sculpté, chambre dorée |
| Centré | réussi | réussi |
| Témoin de dos | réussi | réussi |
| Ton favorable | réussi | réussi |
| Écarts | style de temple ancien plutôt humain que « non-human » ; pas de chantier de fouille visible | idem |

Décision de l'utilisateur sur e6 : pas de ruines, cela irait à l'encontre des futurs scénarios.
L'événement est remplacé par `gravity_anomaly` (« Anomalie gravitationnelle »), avec le même effet.

## e7 — gravity_anomaly (favorable)

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Reconnaissable (roches en lévitation) | réussi : gros blocs flottants au-dessus du cratère | réussi : blocs et débris en suspension, cratère net |
| Centré | blocs groupés au centre-gauche | réussi |
| Capteurs au bord du cratère | réussi (mâts) | réussi (mâts et instruments) |
| Ombres des blocs au sol | peu visibles | peu visibles |
| Témoin de dos | réussi | réussi |
| Ton favorable | réussi | réussi |

Retenue : e7-gravity_anomaly-7777.

## e8 — drifting_wreck (favorable, espace)

`site` en orbite basse, `mood` favorable adapté à l'espace (lumière dorée sur la coque).

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Reconnaissable (cargo abandonné, soutes vidées) | réussi : soute ouverte, navettes à l'intérieur | réussi : vu de l'arrière, soute ouverte |
| Centré | un peu à gauche | réussi |
| Pas de témoin dans l'espace | réussi | raté : un colon assis dans la soute |
| Lueur de l'atmosphère sous la coque | raté | raté |
| Ton favorable | réussi (lumière dorée) | réussi |

La vue d'e2 fait apparaître le témoin même dans l'espace, une seed sur deux (l'épave instable e2-4242
n'en avait pas).

Retour de l'utilisateur sur e8 : aucune des deux. On n'a pas encore choisi d'aller à l'épave, donc pas
de navettes ; il faut voir les conteneurs et l'abandon.

## e9 — drifting_wreck

Sujet décrit comme un « derelict cargo freighter » à soute entrouverte, sans navette, et « No person
and no other ship » ajouté à la vue. Raté : coque de navire de mer sur les 2 seeds (« freighter »), et
un colon assis dans la soute sur 7777 malgré « No person ». Retour de l'utilisateur : pas de bateau,
encore moins avec quelqu'un dedans ; il faut un transporteur spatial délabré, mais plein.

## e10 — drifting_wreck

Sujet : « space cargo hauler, built for space and not shaped like a boat », une poutre en treillis
qui porte des rangées de conteneurs, cockpit à l'avant, moteurs à l'arrière, signes d'abandon. Vue d'e4
(aucun personnage sur 6 images), utilisée pour les scènes dans l'espace.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Transporteur spatial, pas un bateau | réussi | réussi |
| Plein, conteneurs visibles | réussi : rangées de conteneurs dans le treillis | réussi : conteneurs qui s'échappent |
| Délabré | réussi | réussi |
| Pas de personne ni de navette | réussi | réussi |
| Centré | réussi | réussi |

Retenue : e10-drifting_wreck-7777.

## e11 — gallery_collapse (néfaste)

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Reconnaissable (galerie effondrée) | réussi : entrée en arche, éboulis de cristaux | à moitié : gros éboulis, entrée peu visible |
| Mine équipée | raté : grotte naturelle, sans structure de mine | raté |
| Cristaux dans les débris | réussi | réussi |
| Véhicules de secours | réussi (gyrophares) | à moitié : lueurs prises pour des feux |
| Témoin de dos | réussi | réussi |
| Ton néfaste | réussi | réussi |

Retenue : e11-gallery_collapse-4242.

## e12 — sabotage (néfaste)

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Reconnaissable (chantier saboté) | réussi : échafaudage éventré, débris projetés, grue renversée | réussi : échafaudage brûlé, grue couchée, feux au sol |
| Bâtiment high-tech | raté : seul l'échafaudage se voit, d'aspect assez ancien | raté |
| Centré | réussi | réussi |
| Témoin de dos | réussi | réussi |
| Ton néfaste | réussi | réussi |

Retenue : e12-sabotage-4242. Arrêt de la série à la demande de l'utilisateur (2026-11-10).
