# 00 · Vision et roadmap

## Objet

Idle solo façon OGame, en temps réel, avec des menaces PvE, joué sur un téléphone Android.
Grande fidélité aux règles OGame classiques ; on diverge seulement quand le solo l'exige.

## Principes

- **Plateforme** : Android 15+ (minSdk 35), APK arm64 installé à la main, `dev.pch.starmine`.
- **Stack** : Flutter, Drift (SQLite), flutter_local_notifications. 100 % local, sans backend.
- **Temps réel** avec multiplicateur de vitesse (×1, ×10, ×100) pour le confort et le debug.
- **Le temps n'avance que par `advance(state, now)`** : aucune boucle de jeu, l'état est
  rattrapé à la demande (spec 01).
- **Domaine en Dart pur** (`lib/domain/`), déterministe et testé ; la CI refuse tout import
  Flutter ou persistance dans ce dossier.
- **Données de jeu dans le YAML** ; formules dans le code.
- **UX mobile** : toute mécanique non évidente a une infobulle au tap (spec 10).
- **L'image ne porte jamais d'information** (refonte visuelle) : chiffres, coûts et timers
  restent en texte.
- **Aucun achat, jamais** : pas de monnaie premium ni de paiement réel. Ce qui est payant dans
  OGame (officiers, file d'attente du Commandant) se **gagne en jouant** (spec 12).
- **Vitesse par défaut ×1**, température max tirée au hasard à la création (questions ouvertes
  du spec V0, tranchées par l'implémentation).

## Versions

| Version | Contenu | État |
| --- | --- | --- |
| V0 | Économie : mines, énergie, stockage, file de construction, moteur d'événements, SQLite, notifications | Livrée |
| V1 | Recherche : labo, 5 technos, prérequis, fusion, nanites, réglage de production | Livrée |
| V2a | Chantier, 8 défenses, technos de combat, simulateur de combat | Livrée |
| V2b | Raids pirates : détection, force indexée sur les points, pillage, rapports | Livrée |
| V2c | Officiers : écran de déblocage, prérequis indexés sur la progression, niveaux plafonnés, bonus permanents (spec 12) ; refonte de la force des raids (spec 07) | Spécifiée, à implémenter |
| V2d | Événements ponctuels : effets temporaires positifs ou négatifs justifiés par l'histoire, certains à choix, liés aux officiers (spec 14) | Spécifiée, à implémenter |
| V3 | Flotte : vaisseaux constructibles, attaques de bases pirates (le pillage devient un revenu), champ de débris et recycleurs, technos de propulsion et d'espionnage, missions d'exploration et officiers d'exploration (spec 12) | À spécifier |
| V4 | Galaxie : systèmes, colonisation, multi-planètes, transports, réseau de recherche intergalactique | À spécifier |
| V5 | Fin de jeu : expéditions, objectif final | À spécifier |

Hors version, à placer :

| Sujet | Contenu | État |
| --- | --- | --- |
| Filtre « Réalisables » | Masquer ce qui n'est pas lançable maintenant (spec 10) | Décidé, à faire en BSR à la prochaine session de code |
| Message de raid résolu | Le dernier remplace le précédent au lieu de s'empiler (spec 07) | Décidé, BSR |
| File d'attente d'ordres | Plusieurs ordres enchaînés par file ; candidat : avantage du Commandant (spec 13) | À spécifier |

Transverse en cours : **refonte visuelle** — disposition cible validée (spec 10, ambiances
Équilibrée / Immersive / Sobre), images SF réalistes pré-générées avec Higgsfield et registre
`art/registry.yaml` (spec 11). Décisions et historique : projet claude.ai,
`claude/visuels-decisions.md`.

## Méthode

- **BSR (Boy Scout Rule)** : la dette repérée est corrigée au fil de l'eau, dans la session de
  code suivante, en plus du lot prévu (commits séparés).

## Points ouverts

- Équilibrage des raids : V2b jugée bonne en jeu ; refonte de la force décidée (spec 07).
- Valeurs OGame « à vérifier » dans le YAML (fusion, labo, nanites, Plasma, défenses, vaisseaux).
