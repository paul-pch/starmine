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

## e13 — storage_leak (néfaste)

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Silo éventré dominant, centré | réussi | réussi |
| Métal lisible (ni lave ni gravats) | réussi : lingots dans le flot et le tas | à moitié : flot granuleux, lingots au sol seulement |
| Drones de réparation | réussi | réussi, plus petits |
| Adossé à la falaise | raté : silo isolé dans une vallée | raté |
| Témoin de dos | à moitié : assis | à moitié : assis en tailleur |
| Ton néfaste | réussi | réussi |

Recommandation : 4242. Retenue par l'utilisateur : e13-storage_leak-7777, colon assis accepté.

## e14 — orbital_battle (abandonnée)

Deux seeds générées : une coque coupée en deux plutôt que deux vaisseaux distincts. Retour de l'utilisateur : trop
proche des deux événements d'épave (`drifting_wreck`, `unstable_wreck`). L'événement est retiré du jeu (YAML, spec
14), et l'entrée e14 du fichier de série aussi.

## e15 — merchant_convoy (pari, espace)

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Convoi de plusieurs vaisseaux | réussi | réussi |
| Cargaison de cristal lisible | réussi, net en vignette | réussi |
| Vaisseau spatial, pas un bateau | raté : quille, proue, mâts | à moitié : mâts et superstructures |
| Centré | réussi | réussi |
| Ton pari | réussi | réussi |

Recommandation : 7777. Retenue par l'utilisateur : e15-merchant_convoy-4242.

## e16 — escort_request (pari, espace)

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Transporteur dominant, centré | réussi | réussi |
| Poursuite lisible | à moitié : chasseurs sur les côtés | réussi |
| Fuite vers la caméra | réussi | raté : s'éloigne |
| Spatial | réussi | réussi |

Retour de l'utilisateur : le sens du vaisseau et des propulseurs semble inversé sur les deux. Hypothèse : une vue
de face ou de dos rend la direction ambiguë.

## e17 — escort_request, vue de profil

Un seul changement : vaisseau vu de profil, nez à droite, réacteurs et traînée à gauche, pirates derrière à gauche.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Sens du vol cohérent | réussi | réussi |
| Poursuite lisible | réussi | réussi |
| Centré | à moitié : un peu petit, haut | réussi |
| Rien au bord | à moitié : chasseurs près du bord gauche | à moitié : collés au bord |

Règle : pour une direction de vol, une vue de profil avec le nez et les réacteurs placés explicitement lève
l'ambiguïté. Recommandation : 7777. Retenue par l'utilisateur : e17-escort_request-4242.

## e18 — pirate_deserters (pari, sol)

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Reddition lisible | raté : pilotes de dos, mains levées face à leurs chasseurs | réussi : pilotes de face |
| 3 pilotes | raté : 4, plus des silhouettes dans les cockpits | raté : idem |
| Témoin de dos | absent | absent |

Retour de l'utilisateur : aucune des deux. 4242 fait avion de chasse (F-15), pas SF, et les pilotes de dos face aux
avions sont bizarres ; 7777 a des vaisseaux étranges et montre les visages, qu'il ne veut pas voir.

## e19 — pirate_deserters, vaisseaux SF et visages cachés

Trois changements, chacun lié à un critère raté : vaisseaux « clearly science fiction and not shaped like aircraft,
no wings and no tail fins » ; « only three pilots », cockpits « open and empty » ; casques fermés à visière miroir
opaque.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Vaisseaux SF, pas d'avion | réussi : coques blindées sur pattes | réussi, marques rouges nettes |
| 3 pilotes, cockpits vides | réussi | réussi |
| Visages cachés | réussi | réussi |
| Reddition lisible | à moitié : un salue, un bras baissés | réussi : trois mains levées |
| Centré | réussi | réussi |

Règles : « not shaped like aircraft, no wings and no tail fins » retire l'allure d'avion de chasse ; un nombre précédé
de « only » est respecté sur les 2 seeds ; une visière miroir opaque cache les visages. Retenue :
e19-pirate_deserters-7777.

## e20 — advance_contract (pari, sol)

Cargo de la guilde, rampe baissée, robots chargeant des lingots. Images lisibles (recommandation 4242), mais retour de
l'utilisateur : la scène montre l'investissement déjà fait, alors que l'événement est une offre en attente.

## e21 — advance_contract, l'offre

Soute vide, deux émissaires à visière opaque, l'un tend un lingot. Raté sur les 2 seeds : ils se passent le lingot
entre eux. Retour de l'utilisateur sur 7777 : l'offre est lisible, mais on croit à un trafic d'or ; différencier un
colon du joueur et un émissaire de la guilde.

## e22 — advance_contract, colon et émissaire

Deux changements demandés par l'utilisateur : lingot « dull grey raw iron » ; à gauche un colon en combinaison blanche
et grise qui tend le lingot, à droite l'émissaire en tenue bronze qui le prend, une tablette de contrat à la main.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Pas d'or | réussi, lingot pris pour une roche | réussi |
| Deux camps distincts | réussi | réussi |
| Offre lisible | réussi, tablette lumineuse | réussi, échange du lingot |
| Visages cachés | réussi | à moitié |

Règle : un échange se lit avec deux camps de tenues contrastées (blanc et gris contre bronze) ; « raw iron, dull grey »
retire l'or. Retenue : e22-advance_contract-7777.

## e23 et e24 — prospectors (pari, sol)

e23 : astéroïde « hangs low in the sky, close » : rocher en lévitation au ras du sol, lu comme une menace (raté sur les
2 seeds) ; nombre de personnages faux. e24 : « small like a moon, high in the sky » : une vraie lune ronde (raté).
Retour de l'utilisateur : personne ne regarde dans le bon sens, et ce n'est pas une lune.

## e25 — prospectors, groupe de dos

Deux changements : astéroïde « irregular potato-shaped, rough and cratered, clearly not round and not a moon » ;
groupe de dos regardant l'astéroïde, « only three prospectors and only one colonist ».

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Astéroïde, pas une lune | réussi | réussi |
| Regards dans le même sens | réussi | réussi |
| 3 prospecteurs, 1 colon | raté : 2 et 2 | réussi |
| Casques | têtes nues | colon casqué seul |

## e26 — prospectors, sans casque

Décision de l'utilisateur : retirer le casque du colon, et règle de charte « tête nue » sur la planète. Départ de
e25-7777, seed 7777, prompt « bareheaded, no helmets ». `denoise` 0,60 et 0,75 : casque conservé ; 0,85 : retiré,
composition identique ; 0,92 : retiré, petits écarts. « short dark hair » donne un crâne rasé. Règle : retirer un
accessoire d'une image retenue demande un `denoise` d'au moins 0,85. Retenue : e26d-prospectors-7777.

## e27 — distress_signal (pari, espace)

Trois transporteurs immobiles, réacteurs éteints, balise rouge. 4242 : les trois fusionnent en un seul ; 7777 : convoi
lisible, très sombre. Retour de l'utilisateur : aucune ; montrer un vaisseau fonctionnel et partiellement endommagé.

## e28 — distress_signal, un vaisseau fonctionnel endommagé

Un seul transporteur, hublots et feux allumés, brèche noircie qui fuit du gaz, balise rouge ; lumière rasante ajoutée
au `mood`.

| Critère | 4242 | 7777 |
| --- | --- | --- |
| Fonctionnel | réussi | réussi |
| Partiellement endommagé | réussi | réussi, panache de gaz net |
| Pas une épave | réussi | réussi |
| Balise rouge | réussi | réussi, centrée |
| Lisible en vignette | réussi | réussi |

Règle : « windows and running lights brightly lit » distingue un vaisseau en avarie d'une épave ; « low raking sunlight »
éclaire la coque sans casser le ton. Retenue : e28-distress_signal-7777. Série 60 terminée : 15 illustrations sur 15.
