import 'package:flutter/material.dart';

import '../../domain/game_data.dart';
import '../../domain/tech_tree.dart';
import '../game_controller.dart';
import '../widgets/info_button.dart';
import '../widgets/item_card.dart';

/// Liste de bâtiments ou de technologies, dans l'ordre de leur déclaration.
class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key, required this.controller, required this.items, required this.now});

  final GameController controller;
  final List<Unlockable> items;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [for (final item in items) ItemCard(controller: controller, item: item, now: now)],
    );
  }
}

/// Technologies groupées par palier (profondeur dans l'arbre des prérequis).
class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final MapEntry(key: tier, value: techs) in controller.data.techsByTier().entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text('Palier $tier', style: theme.textTheme.labelLarge),
                if (tier == 1)
                  const InfoButton(
                    title: 'Paliers de recherche',
                    body:
                        'Le palier est la profondeur d’une technologie dans l’arbre : une '
                        'techno de palier 3 demande au moins une techno de palier 2, et ainsi '
                        'de suite. « Requiert » indique ce qui manque, « Débloque » ce que la '
                        'techno ouvre ensuite.',
                    size: 16,
                  ),
              ],
            ),
          ),
          for (final t in techs) ItemCard(controller: controller, item: t, now: now),
        ],
      ],
    );
  }
}
