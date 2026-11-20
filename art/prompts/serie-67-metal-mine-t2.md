# Série 67 — mine de métal, palier t2 (tempéré)

`building.metal_mine.t2.temperate`, 1:1, depuis l'image t1 validée (`serie-08-metal-mine/metal_mine-4242`), seed
4242, charte `art/style/base_prompt.md`. Qwen-Image-2.1 (int8), 25 pas, cfg 1, euler/simple.

## Fiche (Q/R avec l'utilisateur, 2026-11-17)

```yaml
id: building.metal_mine.t2
sujet: la mine t1, même bâtiment et même paysage
élément clé: t2 = une fonderie au pied (cheminées, lingots incandescents) ; t3 = complexe sur toute la falaise
cadrage: celui du t1
interdit: paysage déplacé, mine t1 méconnaissable
critères:
  - le bâtiment et la falaise du t1 restent en place
  - l'ajout se lit à 512 px et à 256 px
  - aucune matière ambiguë (lingots pris pour de la lave)
```

Méthode : t2 tempéré depuis le t1 tempéré, puis t3 depuis le t2 ; froid et chaud déclinés depuis chaque palier
tempéré retenu (`site` de la charte, `denoise` 0,90).

## e1 — balayage du `denoise`, fonderie dans `subject`

« ... conveyor carrying raw ore out of the tunnel to a large foundry at the foot of the building, with tall chimneys
and rows of glowing orange molten metal ingots. »

| Code | Paysage gardé | Fonderie lisible | Remarques |
| --- | --- | --- | --- |
| d70-metal_mine-4242 | oui | non : lingots orange seuls | |
| d80-metal_mine-4242 | oui | faible : une cheminée, lingots | |
| d90-metal_mine-4242 | oui | moyenne : deux cheminées, lingots, pas de bâtiment | |

Constat : la fonderie, ajoutée en fin de phrase, ne devient qu'un détail. Hypothèse : en faire un bâtiment
séparé, nommé, au premier plan.

## f2 — fonderie comme bâtiment séparé (`denoise` 0,90)

« At the end of the conveyor, in the foreground, stands a large separate foundry building with glowing orange
furnace mouths, two tall smoking chimneys and rows of glowing molten metal ingots cooling outside. »

| Code | Paysage gardé | Fonderie lisible | Remarques |
| --- | --- | --- | --- |
| f2-metal_mine-4242 | oui : falaise, filons, galerie et tour du t1 | oui : bâtiment, fours ouverts, 2 cheminées fumantes, lingots | lingots lisibles comme du métal, pas de la lave |

Décision : à l'utilisateur.

Retour de l'utilisateur sur f2 (2026-11-17) : rien de validé. L'image sera petite en jeu : le palier doit se voir
comme **un bloc, un bâtiment en plus**. Demande : une fonderie dédiée, sur la droite.

## f3 — fonderie dédiée à droite

« On the right side of the frame, next to the tunnel, stands a second large and clearly separate block: a dedicated
foundry building with glowing orange furnace mouths, two tall smoking chimneys and rows of glowing molten metal
ingots cooling outside. » Vérifié à 512 et à 128 px.

| Code | `denoise` | Paysage gardé | Bloc en plus à 128 px | Remarques |
| --- | --- | --- | --- | --- |
| f3a-metal_mine-4242 | 0,90 | oui ; caméra un peu plus proche | oui : tour droite, lueur orange | cheminées fines, peu visibles |
| f3b-metal_mine-4242 | 0,95 | oui ; filons recouverts en partie | oui, le plus net : bloc plus large, 2 cheminées fumantes | lingots devant, lisibles comme métal |

Décision : à l'utilisateur.

## Sélection (utilisateur, 2026-11-17)

`building.metal_mine.t2.temperate` : **f3b-metal_mine-4242** (`denoise` 0,95). Inscrite au registre en `validated`
v1, `parent` = t1 tempéré.
