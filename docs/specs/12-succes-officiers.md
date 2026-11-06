# 12 · Succès et officiers

> **À spécifier** — version V2c. Rien n'est implémenté. Cette page consigne ce qui a été
> décidé, proposé et laissé ouvert en conversation.

## Objet

Récompenser la progression : des **succès** débloquent des **officiers**, des personnages qui
donnent des avantages en jeu.

## Décidé

- Les officiers se **débloquent en jouant**, jamais par un achat (spec 00).
- Sources de déblocage : **missions d'exploration**, **succès de défense** (raids repoussés),
  **paliers de construction**.
- La fonctionnalité entre dans la roadmap (V2c).

## Proposé

| Officier | Débloqué par | Avantage |
| --- | --- | --- |
| Commandant | Palier de construction (ex. 50 niveaux de bâtiments cumulés) | File d'attente de plusieurs ordres (spec 13) |
| Géologue | Palier de mines (niveaux de mines cumulés) | +10 % de production des mines |
| Technocrate | Palier de recherche (ex. 20 niveaux de technos cumulés) | −25 % de durée de recherche |
| Ingénieur | Raids repoussés (ex. 5) | Défenses reconstruites à 85 % au lieu de 70 % |
| Amiral | Missions d'exploration réussies (V3) | Avantages de flotte |

Seuils et bonus : à mettre dans le YAML (section `officers`), comme tout chiffre de jeu.

Technique proposée :

- **succès** = compteurs tenus à jour dans `advance()` (raids repoussés, niveaux cumulés…),
  donc exacts même app fermée ; persistés (table dédiée) et dans la sauvegarde JSON ;
- **officiers** = modificateurs déclarés dans le YAML, appliqués par les formules existantes
  (production, durées, reconstruction) ;
- écran ou section **Succès** montrant les progrès (« Raids repoussés : 3 / 5 ») ;
- portraits : catégorie `character` du registre d'images (spec 11).

## À trancher

1. Officiers **tous actifs**, ou un **nombre limité de places** (ex. 3 actifs parmi ceux
   débloqués) ? Recommandation : places limitées (choix stratégique selon la phase de jeu).
2. **Rangs** (I, II, III) débloqués par les paliers successifs du même succès, bonus
   croissant ? Recommandation : oui.
3. **Missions d'exploration** : attendre la flotte (V3), ou des missions simples sans
   vaisseaux dès la V2c (temps d'envoi, résultat aléatoire à graine) ? Recommandation :
   officiers de construction, recherche et défense en V2c, exploration en V3.
4. **Écran des succès** : onglet, ou section accessible depuis le hero / Debug ?
5. Notification au déblocage d'un officier ?

## Code

À venir : `lib/domain/achievements.dart`, `lib/domain/officers.dart` (noms indicatifs).
