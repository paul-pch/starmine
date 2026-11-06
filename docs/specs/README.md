# Specs fonctionnelles de Starmine

Une spec par fonctionnalité, décrivant le comportement **tel qu'il est implémenté** (une
spec « à implémenter » le dit en tête). Elles
servent de référence pour faire évoluer le jeu et pour la refonte visuelle.

| # | Spec | Contenu |
| --- | --- | --- |
| 00 | [Vision et roadmap](00-vision-roadmap.md) | Principes, plateforme, versions passées et à venir |
| 01 | [Temps et événements](01-temps-evenements.md) | `advance()`, chaînes d'événements, déterminisme, vitesse |
| 02 | [Économie](02-economie.md) | Ressources, production, énergie, stockage, réglage de production |
| 03 | [Bâtiments](03-batiments.md) | Liste, files, règles du labo et du chantier |
| 04 | [Recherche](04-recherche.md) | Technologies, prérequis, paliers, « Débloque » |
| 05 | [Chantier et défenses](05-chantier-defenses.md) | Lots, unités, limites |
| 06 | [Combat](06-combat.md) | Règles de bataille, forces, détail des rounds, simulations |
| 07 | [Raids pirates](07-raids.md) | Détection, force, pillage, rapports |
| 08 | [Persistance et sauvegarde](08-persistance.md) | Schéma SQLite, migrations, export/import |
| 09 | [Notifications](09-notifications.md) | Quand et quoi notifier |
| 10 | [Écrans et UX](10-ecrans-ux.md) | Inventaire des écrans, informations affichées, disposition cible, styles |
| 11 | [Visuels et registre](11-visuels.md) | Images pré-générées, catalogue, paliers, registre, repli (à implémenter) |
| 12 | [Officiers](12-succes-officiers.md) | Déblocage, niveaux, bonus permanents (V2c) |
| 13 | [File d'attente d'ordres](13-file-attente.md) | Plusieurs ordres par file (à spécifier) |
| 14 | [Événements ponctuels](14-evenements.md) | Effets temporaires, choix, lien avec les officiers (à implémenter, V2d) |

Statuts utilisés dans les specs non implémentées : **Décidé** (tranché par l'utilisateur),
**Proposé** (recommandation non contestée, à confirmer), **À trancher** (question ouverte).

## Règles de rédaction

- **Les chiffres vivent dans `assets/game_data.yaml`**, pas dans les specs. Une spec décrit
  une règle ou une formule et renvoie à la clé YAML (ex. `pirates.warning_minutes`).
- Une spec est mise à jour **dans le même commit** que le comportement qu'elle décrit.
- Structure commune : *Objet* · *Règles* · *Données* · *Code* · *Tests* · *Points ouverts*.
- Valeurs OGame non confirmées par une source : marquées « à vérifier » dans le YAML.
- Les specs historiques par version (V0 à V2b) sont dans le doc claude.ai
  « OGame-like solo — Specs V0 & Roadmap ».
