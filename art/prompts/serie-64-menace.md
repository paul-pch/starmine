# Série 64 — menace : annonce du raid pirate (scene.raid_incoming)

Catégorie `scene` de la spec 11 : `scene.raid_incoming`, 16:9, export 1280 × 720, sujet centré, feuille du raid
détecté (bandeau d'alerte, spec 07). Charte `art/style/story_prompt.md`. Modèle Qwen-Image-2.1 (int8), 25 pas,
cfg 1, euler/simple, 1664 × 928. Les bases pirates, prévues ici au départ, sont passées en série 65 (format 4:3).

Demande de l'utilisateur (2026-11-17) : 3 propositions. Une par variante (i1a, i1b, i1c), seed 4242.

Constat repris de la série 63 : une coque claire ne distingue pas le pirate du joueur ; coque sombre
« dark gunmetal and rust-brown patchwork » et tuyères orange-rouge.

## Variantes

- i1a : en orbite, flotte pirate qui fonce vers le spectateur, deux canonnières en tête, chasseurs autour.
- i1b : vue de derrière et du dessus, flotte qui descend vers la planète, lumières d'une colonie côté nuit.
- i1c : au sol, chasseurs pirates en piqué au-dessus de la colonie, colon de dos tête nue, tourelles levées.

## Revue i1 (512 px)

| Code | Menace lisible | Pirate distinct du joueur | Avant l'attaque | Remarques |
| --- | --- | --- | --- | --- |
| i1a-raid_incoming-4242 | oui, face à nous | oui (coque rouille sombre, tuyères rouges) | oui | canonnière de tête massive, un peu « navire » par sa superstructure |
| i1b-raid_incoming-4242 | moyenne | oui | oui | canonnières vues de dos, chasseurs nombreux ; lumières de la colonie peu visibles |
| i1c-raid_incoming-4242 | oui | oui | oui | colon assis et non debout, tête nue ; tourelles et dômes lisibles ; seule image qui montre la colonie visée |

Décision : à l'utilisateur.

## Retour de l'utilisateur sur i1 (2026-11-17)

Aucune retenue. « Il y a un sens d'arrivée mais les réacteurs sont de dos, c'est bizarre » : la flotte vient vers
nous ou vers la planète, et pourtant on voit les tuyères allumées, comme si elle s'éloignait. Le sens de la
marche et les réacteurs se contredisent.

## i2 — sens de la marche cohérent avec les réacteurs

Un seul changement par variante, sur la même scène que i1 : la flotte vient vers nous et ses réacteurs sont cachés
(i2a, i2c), ou elle traverse de profil et ses réacteurs sont visibles derrière elle (i2b). Seed 4242.

| Code | Sens cohérent | Pirate distinct | Avant l'attaque | Remarques |
| --- | --- | --- | --- | --- |
| i2a-raid_incoming-4242 | oui : proues et feux rouges vers nous, pas de tuyère | oui (coque rouille sombre) | oui | canonnière centrale imposante, chasseurs autour ; la plus menaçante |
| i2b-raid_incoming-4242 | oui : de profil vers la droite, traînées orange à gauche | oui | oui | flotte en bande étroite au milieu, petite en vignette ; grand vide en haut |
| i2c-raid_incoming-4242 | oui : chasseurs en piqué, nez vers le bas | **non** : coques gris clair, proches des vaisseaux du joueur | oui | colon debout, tête nue ; « dark hull » ne tient pas face au ciel clair |

## Sélection (utilisateur, 2026-11-17)

`scene.raid_incoming` : **i2a-raid_incoming-4242**. Inscrite au registre en `validated` v1, WebP 1280 × 720.
Pas encore branchée (feuille du raid détecté, au tap du bandeau d'alerte).
