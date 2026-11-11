# Série 61 — icône d'application (logo)

Fiche décidée en Q/R avec l'utilisateur : icône de lanceur carrée, sans texte ; motifs étoile-cristal, planète minée,
pioche et étoile ; rendu SF réaliste 3D. Charte : `art/style/logo_prompt.md`. Qwen-Image-2.1, 1024 × 1024, seeds 4242
et 7777. Lisibilité vérifiée à 96 et 48 px.

## l1 — trois motifs

| Critère | star_crystal 4242 | star_crystal 7777 | mined_planet 4242 | mined_planet 7777 | pick_star 4242 | pick_star 7777 |
| --- | --- | --- | --- | --- | --- | --- |
| Objet unique centré, deux tiers du carré | réussi | réussi | réussi | raté : planète écrasée en carré arrondi, fond éclairci en carré | réussi | réussi |
| Lisible à 48 px | réussi, le plus net | réussi | raté : boule sombre, la foreuse disparaît | raté | réussi | réussi |
| Motif compris (étoile + mine) | à moitié : le socle fait trophée ou lampe | à moitié : socle à boulons, plus « mine » | réussi en grand | réussi en grand | réussi : pioche à tête de cristal | réussi : deux pioches croisées |
| Pas de texte | réussi | réussi | réussi | réussi | réussi | réussi |

Retenue par l'utilisateur : l1-mined_planet-app_icon-4242 (malgré sa faible lisibilité à 48 px notée ici). Intégration :
spec 11, section « Icône d'application ».
