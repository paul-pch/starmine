# Série 62 — scènes de combat et champ de débris (scene)

Catégorie `scene` de la spec 11 : `scene.<raid_won|raid_lost|attack_won|attack_lost|debris>`, 16:9, export
1280 × 720, sujet centré, en-tête de la popover de fin de combat et carte du champ de débris. Pas encore de
charte propre : base `art/style/story_prompt.md` (vue, témoin de dos tête nue au sol, vue sans personne dans
l'espace, ton par `mood`). Modèle Qwen-Image-2.1 (int8), 25 pas, cfg 1, euler/simple.

Demande de l'utilisateur (2026-11-13) : une série d'exploration, 3 propositions par scène. Seed 4242 seule ;
la seed 7777 se teste sur les propositions retenues.

## Fiche commune

```yaml
id: scene.<clé>
sujet: l'issue du combat, ou le champ de débris, grand et centré
élément clé: qui a gagné se lit sans titre (colonie intacte ou pillée, base pirate en feu ou intacte)
cadrage: 16:9, sujet au centre, rien d'important près des bords
interdit: texte, visages en gros plan, casque au sol, ruines, matière ambiguë
critères:
  - l'issue se reconnaît sans titre, au format popover (350 × 197)
  - vaisseaux du joueur (lisses, gris clair, filets bleus) et pirates (coques rapiécées, sombres) se distinguent
  - le sujet est centré
  - l'ambiance correspond au ton (victoire chaude, défaite sombre, débris calme)
  - pas de texte, structure cohérente
```

## Propositions s1 à s5

| Scène | a | b | c |
| --- | --- | --- | --- |
| `raid_won` (sol, favorable) | colonie intacte, épaves pirates écrasées, témoin | bouclier en dôme, pirates détruits contre lui | pirates en fuite, témoin |
| `raid_lost` (sol, néfaste) | silos éventrés, cargos pirates qui repartent, témoin | tourelles détruites en feu, fumée | dépôt vidé, caisses éparpillées, témoin |
| `attack_won` (espace) | base pirate en feu, flotte du joueur en formation | flotte qui emporte le butin | base qui explose, silhouettes de la flotte |
| `attack_lost` (espace) | base intacte, épaves du joueur | un vaisseau du joueur en fuite, poursuivi par les tirs | coque brisée du joueur au premier plan, base au loin |
| `debris` (espace, calme) | champ de débris seul | recycleur au travail | traînée de débris, demi-coque |

## Revue (seed 4242)

Notes de Claude, à confirmer par l'utilisateur.

| Code | Issue lisible | Remarques |
| --- | --- | --- |
| s1a-raid_won | oui | colonie intacte, tourelles qui tirent encore, deux épaves pirates ; témoin assis, tête nue |
| s1b-raid_won | oui, la plus forte | bouclier en dôme, pirates qui se brisent dessus ; témoin ajouté par la vue, **capuche et sac** (tête nue raté) |
| s1c-raid_won | moyenne | pirates en fuite, un en feu ; en vignette, on peut y lire une attaque en cours ; témoin assis, tête nue |
| s2a-raid_lost | oui | dômes éventrés, conteneurs ; **cargos pirates en forme de navires** (passerelle, coque de bateau) malgré « not shaped like boats » |
| s2b-raid_lost | oui | tourelles en feu, mais d'allure chars ou artillerie ; **témoin soldat casqué** ; très sombre |
| s2c-raid_lost | oui | dépôt béant et vide, caisses, feux ; témoin debout, tête nue ; structure cohérente |
| s3a-attack_won | oui | base astéroïde en feu, flotte blanche à filets bleus bien distincte ; beaucoup de vaisseaux |
| s3b-attack_won | non | flotte arrimée à la base, conteneurs ; se lit comme un amarrage, pas comme une victoire |
| s3c-attack_won | oui, la plus forte | base qui explose, flotte du joueur au premier plan ; vaisseau de gauche coupé par le bord |
| s4a-attack_lost | non | vaisseaux du joueur presque intacts autour de la base : ressemble à s3a |
| s4b-attack_lost | non | vaisseau du joueur **fusionné** avec la base (structure incohérente) |
| s4c-attack_lost | oui | coque du joueur brisée en deux, base aux feux rouges derrière ; base un peu sombre |
| s5a-debris | oui | nuage de fragments seul, lisible, assez abstrait |
| s5b-debris | moyenne | le recycleur ressemble lui-même à une épave (coque ouverte) |
| s5c-debris | oui | traînée de débris autour d'une demi-coque |

Constats : la vue par défaut ajoute le témoin même quand il n'est pas demandé (s1b, s2b), et sans le
décrire il porte casque ou capuche ; il faut toujours décrire le témoin tête nue dans les scènes au sol. « cargo
ships » pirates donne des navires (s2a), comme « freighter » en série 60.

## Retours de l'utilisateur (2026-11-13)

- `raid_lost` : **s2b-raid_lost-4242 retenue** (le témoin y porte un casque : à confirmer comme exception à la
  règle tête nue).
- `attack_won` : refusé, le bloc d'astéroïde est étrange et la victoire ne se sent pas. Choix en Q/R : base
  pirate = **station spatiale rapiécée** (modules disparates, anneaux, docks ; vaut aussi pour les futures
  `pirate_base`) ; signe de victoire = **flotte du joueur intacte devant la base vaincue** (éteinte, tourelles
  détruites, petits feux).
- `debris` : refusé, on ne comprend pas. C'est la carte du champ de débris (spec 15 : 30 % du métal et du cristal
  des vaisseaux détruits, en orbite, ramassés par le recycleur). Choix : **épaves seules**, vaisseaux délabrés et
  brisés qui dérivent parmi des plaques et des éclats de cristal, sans recycleur.

## s6 (attack_won) et s7 (debris)

- s6a : formation de 3 vaisseaux du joueur au premier plan, station vaincue derrière.
- s6b : station vaincue au centre, flotte devant.
- s6c : vue depuis l'arrière du vaisseau amiral, station en face.
- s7a : deux épaves, une pirate et une du joueur, plaques et éclats de cristal.
- s7b : trois épaves éventrées, longtemps après le combat.
- s7c : grande épave brisée en deux, petites épaves derrière.

### Revue s6 et s7 (seed 4242)

| Code | Issue lisible | Remarques |
| --- | --- | --- |
| s6a-attack_won | oui, la plus forte | flotte du joueur au premier plan, station en feu et fumante derrière ; vaisseaux de gauche un peu soudés entre eux |
| s6b-attack_won | moyenne | station au centre entourée par la flotte ; station encore éclairée (filets bleus), peu de dégâts visibles |
| s6c-attack_won | faible | proue du vaisseau amiral au premier plan, mais station presque intacte : se lit comme une arrivée |
| s7a-debris | moyenne | les deux épaves se soudent en une seule coque ; silhouette de navire |
| s7b-debris | oui, la plus forte | trois coques éventrées et criblées, fragments autour ; épaves évidentes ; éclats de cristal peu visibles |
| s7c-debris | moyenne | épave nette, mais superstructure et mâts de cuirassé de mer malgré « not shaped like a boat » |

Constat : « lights out » n'éteint pas la station (s6b, s6c) ; la victoire se lit surtout par le feu et la fumée
sur la station (s6a). « warship » sur une épave donne un navire de guerre de mer (s7c).

## Retours de l'utilisateur, 2e tour

- `raid_lost` : s2b refusée en l'état, à refaire **sans casque**, même image.
- `raid_won` : refusé, les vaisseaux pirates sont des « pâtés informes ». Il faut des **chasseurs pirates en
  déroute**.
- `debris` : refusé, s7b et s7c ressemblent à des paquebots. Il faut des **épaves de vaisseaux spatiaux**.

## s8 (raid_lost sans casque), s9 (raid_won), s10 (debris)

- s8a, s8b, s8c : départ de s2b-raid_lost-4242, même prompt, témoin décrit assis, tête nue ; `denoise` 0,92, 0,96
  et 1,0 (série 60 : un grand casque résiste jusqu'à 0,92).
- s9 : chasseurs pirates décrits comme chasseurs monoplaces (corps en dard, ailes courtes en flèche, tuyères,
  coque rapiécée), en fuite désordonnée au-dessus de la colonie intacte ; témoin debout, tête nue. a : vers les
  montagnes ; b : poursuivis par les tirs des tourelles ; c : un en vrille, les autres en fuite.
- s10 : « spacecraft » au lieu de « ship » et de « warship », et une phrase qui exclut navire et paquebot (pas de
  mâts, de ponts ni de rangées de hublots ; tuyères, ailes ou ailerons, verrière). a : trois chasseurs ; b : une
  douzaine d'épaves petites et moyennes ; c : un appareil armé moyen et deux chasseurs.

### Revue s8, s9 et s10 (seed 4242)

| Code | Issue lisible | Remarques |
| --- | --- | --- |
| s8a-raid_lost (0,92) | oui | casque retiré, tête nue et cheveux visibles ; composition de s2b gardée, colon en combinaison blanche |
| s8b-raid_lost (0,96) | oui | idem, gros vaisseau un peu plus net ; écart minime avec s8a |
| s8c-raid_lost (1,0) | oui | composition proche, dômes moins visibles, vaisseaux plus petits |
| s9a-raid_won | moyenne | essaim de chasseurs nets (forme de dard, ailes), quelques fumées ; trop nombreux, se lit aussi comme une attaque |
| s9b-raid_won | faible | chasseurs qui montent, postcombustion : se lit comme un décollage ; pas de tir visible |
| s9c-raid_won | oui, la plus forte | 7 chasseurs qui s'éloignent, plusieurs en feu et fumants ; aucun en vrille |
| s10a-debris | moyenne | trois chasseurs nets, mais presque entiers : épaves peu évidentes |
| s10b-debris | oui | dizaine d'épaves de chasseurs, mais l'épave centrale garde des mâts |
| s10c-debris | oui, la plus forte | appareil moyen au nez arraché, deux chasseurs brisés, éclats de cristal ; tous clairement spatiaux |

Constats : à 0,92, le casque part sur un témoin de taille moyenne (contrairement à la série 60) une fois le témoin
décrit tête nue. Le témoin s'assoit dans les 3 images s9 malgré « stands » : c'est la vue de la charte qui le
fait. « single-seat fighter, dart-shaped, swept wings » donne des chasseurs reconnaissables ; « spacecraft » et la
phrase anti-navire retirent le paquebot, sauf au centre de s10b.

## Retenues (utilisateur, 2026-11-13)

- `scene.raid_lost` : **s8c-raid_lost-4242** (depuis s2b, `denoise` 1,0, témoin tête nue).
- `scene.raid_won` : **s9b-raid_won-4242** (chasseurs pirates qui s'enfuient vers le ciel).
- `scene.debris` : **s10b-debris-4242** (une dizaine d'épaves de chasseurs et d'appareils).

Validées sur la seule seed 4242, sans essai 7777. Masters `art/masters/scene.<clé>/v1.png`, entrées `validated`
au registre, WebP exportés. Restent `attack_won` (s6a proposée) et `attack_lost` (s4c proposée), sans retour.

## Retour de l'utilisateur, 3e tour

Vocabulaire clarifié : `raid_*` = attaque des pirates sur la planète du joueur (au sol), `attack_*` = attaque de
la flotte du joueur sur une base pirate (dans l'espace). s8c et s9b confirmées pour `raid_lost` et `raid_won`. La
remarque « pâté informe, chasseurs pirates en déroute » visait en fait s6 (`attack_won`) : la station pirate s6
est une masse sans forme.

## s11 (attack_won) et s12 (attack_lost)

Station décrite par une silhouette nette (anneau à rayons autour d'un moyeu, modules de récupération), plus petite
ou au fond ; chasseurs pirates de s9 ; vaisseaux du joueur gris clair à filets bleus.

- s11a : chasseurs pirates en déroute au centre, station en feu au loin, deux vaisseaux du joueur qui poursuivent.
- s11b : formation du joueur au premier plan, chasseurs en fuite devant, station en feu au fond.
- s11c : station vaincue au centre (anneau brisé), chasseurs qui fuient, flotte du joueur intacte.
- s12a : vaisseau du joueur désemparé, en feu, encerclé par les chasseurs ; station intacte derrière.
- s12b : station intacte au centre, épaves du joueur devant, chasseurs victorieux.
- s12c : deux vaisseaux du joueur en fuite, poursuivis par les chasseurs, station au fond.

### Revue s11 et s12 (seed 4242)

| Code | Issue lisible | Remarques |
| --- | --- | --- |
| s11a-attack_won | faible | essaim de chasseurs qui vient **vers** le spectateur : se lit comme une charge, pas une déroute ; station en croix, moyeu en feu |
| s11b-attack_won | oui | vaisseau amiral du joueur au premier plan, chasseurs pirates en feu autour, anneau de la station en feu au fond |
| s11c-attack_won | oui | station en roue très nette (anneau, rayons, moyeu), en feu ; chasseurs et vaisseaux du joueur mêlés autour |
| s12a-attack_lost | moyenne | vaisseau du joueur encerclé par l'essaim, quelques feux, mais presque entier ; station intacte derrière |
| s12b-attack_lost | faible | station intacte et éclairée, essaim ; les deux grands vaisseaux paraissent intacts : pas de défaite lisible |
| s12c-attack_lost | oui, la plus forte | deux vaisseaux du joueur abîmés et fumants qui fuient vers le spectateur, chasseurs derrière, station au fond |

Constats : « spoked ring around a central hub » donne une station à la silhouette nette (s11c, s12b) au lieu du
« pâté ». « flee away from the viewer » n'est pas tenu dans s11a. Les chasseurs pirates prennent parfois des filets
bleus (s12c), ce qui les rapproche des vaisseaux du joueur.

## Retenues, suite (utilisateur, 2026-11-13)

- `scene.attack_won` : **s11c-attack_won-4242** (station en roue en feu).
- `scene.attack_lost` : **s12b-attack_lost-4242** (station intacte, essaim de chasseurs pirates).

Série terminée : 5 scènes sur 5, toutes sur la seed 4242. Base pirate retenue pour la suite (`pirate_base`) :
station en anneau à rayons autour d'un moyeu, modules de récupération.
