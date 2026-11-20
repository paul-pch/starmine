# Série 68 — mine de métal, palier t3 (tempéré)

`building.metal_mine.t3.temperate`, 1:1, depuis le t2 validé (`serie-67-metal-mine-t2/f3b-metal_mine-4242`),
seed 4242, charte `art/style/base_prompt.md`. Fiche : série 67 (t3 = complexe sur toute la falaise). Règle de
l'utilisateur : chaque palier ajoute un bloc séparé, lisible à 128 px.

Ajout au `subject` du t2 : un troisième bloc à gauche, deuxième galerie avec son chevalement et son convoyeur,
relié par une passerelle.

| Code | Formulation | `denoise` | t2 gardé | Bloc en plus à 128 px | Remarques |
| --- | --- | --- | --- | --- | --- |
| g1a-metal_mine-4242 | « On the left side of the frame » | 0,90 | oui | **non** : tour lointaine, à l'arrière-plan | |
| g1b-metal_mine-4242 | idem | 0,95 | oui | **non** : idem, un peu plus grande | |
| g2a-metal_mine-4242 | « in the foreground and as large as the main building » | 0,90 | oui | **non** : rien n'est ajouté | |
| g2b-metal_mine-4242 | idem | 0,95 | oui | oui : haute tour grise à gauche, petite galerie à sa base, convoyeur | passerelle peu visible |

Constat : sans « foreground ... as large as », le modèle pose le nouveau bloc au loin ; à 0,90, l'image de départ
l'emporte. Comme au t2, 0,95 est nécessaire.

Décision : à l'utilisateur.

Retour de l'utilisateur sur g2b (2026-11-17) : non retenue ; le 3ᵉ bâtiment doit être un peu plus gros et plutôt
dans la montagne.

## g3 — bloc plus gros, dans la montagne

- A : « a huge multi-level mining building carved deep into the mountain itself, its facade embedded in the cliff
  face and rising high up the rock, with a second wide tunnel mouth at its base », plus grand que le bâtiment
  principal ;
- B : « a huge mining building clinging high up on the cliff face, built into the rock of the mountain, with a long
  inclined conveyor running down from it to the ground ».

| Code | Formulation | `denoise` | t2 gardé | Bloc en plus à 128 px | Remarques |
| --- | --- | --- | --- | --- | --- |
| g3a-metal_mine-4242 | A | 0,95 | oui | moyen : façade dans la falaise avec galerie, mais au loin | |
| g3b-metal_mine-4242 | B | 0,95 | oui | moyen : bâtiment perché, convoyeur incliné bien visible | bâtiment petit |
| g3c-metal_mine-4242 | A | 0,97 | presque : tour principale un peu redessinée | oui, le plus net : gros bloc encastré dans la falaise, galerie à sa base | le plus proche de la demande |

Décision : à l'utilisateur.

## Sélection (utilisateur, 2026-11-17)

`building.metal_mine.t3.temperate` : **g3c-metal_mine-4242** (`denoise` 0,97). Inscrite au registre en `validated`
v1, `parent` = t2 tempéré.
