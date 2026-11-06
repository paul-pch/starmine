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

## Versions

| Version | Contenu | État |
| --- | --- | --- |
| V0 | Économie : mines, énergie, stockage, file de construction, moteur d'événements, SQLite, notifications | Livrée |
| V1 | Recherche : labo, 5 technos, prérequis, fusion, nanites, réglage de production | Livrée |
| V2a | Chantier, 8 défenses, technos de combat, simulateur de combat | Livrée |
| V2b | Raids pirates : détection, force indexée sur les points, pillage, rapports | Livrée |
| V3 | Flotte : vaisseaux constructibles, attaques de bases pirates, champ de débris | À spécifier |
| V4 | Galaxie : systèmes, colonisation, multi-planètes, transports | À spécifier |
| V5 | Fin de jeu : expéditions, événements rares, objectif final | À spécifier |

Transverse en cours : **refonte visuelle** — disposition cible validée (spec 10, ambiances
Équilibrée / Immersive / Sobre), images SF réalistes pré-générées avec Higgsfield et registre
`art/registry.yaml` (spec 11). Décisions et historique : projet claude.ai,
`claude/visuels-decisions.md`.

## Points ouverts

- Équilibrage des raids à valider en jouant (spec 07).
- Valeurs OGame « à vérifier » dans le YAML (fusion, labo, nanites, Plasma, défenses, vaisseaux).
