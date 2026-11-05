import 'package:flutter/material.dart';

import '../../domain/game_data.dart';
import '../game_controller.dart';
import '../widgets/categorized_list.dart';
import '../widgets/item_card.dart';

/// Bâtiments, filtrables par catégorie.
class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    return CategorizedList<BuildingKind>(
      categories: data.categories['buildings'] ?? const {},
      items: BuildingKind.values,
      categoryOf: (k) => data[k].category,
      itemBuilder: (context, k) => ItemCard(controller: controller, item: k, now: now),
    );
  }
}

/// Technologies, filtrables par catégorie ; le palier est indiqué sur chaque carte.
class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    return CategorizedList<TechKind>(
      categories: data.categories['research'] ?? const {},
      items: TechKind.values,
      categoryOf: (k) => data.tech(k).category,
      itemBuilder: (context, k) => ItemCard(controller: controller, item: k, now: now),
    );
  }
}
