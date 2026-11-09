# Série 20 : températures, neige et terre terracotta

Suite de la série 19, décidée par l'utilisateur. Fichiers : `serie-20-temperature.json`, charte
`art/style/base_prompt.md`, inchangée. Qwen-Image-2.1, seeds 4242 et 7777, 1024 × 1024, 25 passes,
cfg 1, `euler` / `simple`. 10 images. Prompts complets : `run.json`, dans le dossier de sortie. Fiche :
`serie-19-temperature.md`, inchangée, sauf la lave, désormais admise en petite quantité sur la terre,
jamais sur la mer.

## Essai 2

Seul `site` change, sur plusieurs points à la demande de l'utilisateur :

- froid : neige épaisse sur le sol, le plateau et la falaise ; deutérium froid non regénéré ;
- chaud : terre terracotta, quelques fines fissures de lave sur la falaise, épaisses colonnes de
  fumée au loin.

Ces points ne sont donc pas testés séparément.

Hypothèses : la neige rend le froid lisible sur téléphone ; le terracotta, la lave et la fumée
distinguent le chaud d'un désert aride.

### Notes proposées par Claude

10 images vues en taille réelle et à 512 px. L'utilisateur n'a pas encore noté. Chaque case donne
4242 / 7777.

| Critère | Mine froid | Mine chaud | Labo froid | Labo chaud | Deutérium chaud |
| --- | --- | --- | --- | --- | --- |
| Climat reconnu à 512 px | oui / oui | oui / oui | oui / oui | oui / oui | oui / oui |
| Bâtiment reconnu à 512 px | oui / oui | oui / oui | oui / oui | oui / oui | oui / oui |
| Bâtiment proche de la sélection t1 | oui / moyen | moyen / non | moyen / oui | moyen / oui | non / non |
| Aucune matière ambiguë | oui / oui | oui / oui | oui / oui | oui / oui | moyen / moyen : colonne au-dessus de la mer |

### Observations

- Hypothèses confirmées : les deux climats se lisent immédiatement à 512 px.
- La neige n'a pas abîmé les bâtiments ; les filons de métal restent visibles sur la mine.
- Le rouge terracotta est saturé et s'écarte de « muted neutral grey palette », ce qui donne un air de
  Mars. À faire juger par l'utilisateur.
- La lave n'est pas toujours fine : petite sur le labo, coulée épaisse sur le deutérium.
- Deutérium chaud, régression : la terre terracotta repousse la mer, le bâtiment passe sur une plaine
  loin de la falaise, et la grande sphère de 4242 devient quatre sphères égales.
- Deutérium chaud 7777 : la colonne au-dessus de la mer évoque une trombe.
- Mine chaud 4242 : l'entrée de galerie reste masquée, comme en série 19.
- Mine chaud 7777 : la tour devient un immeuble, et une longue machine remplace le convoyeur.

## Retour de l'utilisateur

- Gardées : `metal_mine_cold-4242` et `research_lab_cold-4242`, cette dernière sans la tente à gauche
  (séries 24 et 25). Le deutérium froid retenu est celui de la série 19 : `deuterium_synthesizer_cold-4242`.
- Terre à rendre plus sourde et d'un rouge plus profond : série 21 pour la mine, série 22 pour le labo.
- Deutérium chaud : la mer chaude de la série 19 est très bien faite, le rouge ne doit pas l'en
  éloigner. Fumées au loin. Série 23.

Suite décidée : ne plus mélanger les bâtiments, travailler bâtiment par bâtiment.
