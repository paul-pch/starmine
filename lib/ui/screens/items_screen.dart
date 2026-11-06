import 'package:flutter/material.dart';

import '../../domain/availability.dart';
import '../../domain/engine.dart';
import '../../domain/game_data.dart';
import '../game_controller.dart';
import '../widgets/categorized_list.dart';
import '../widgets/in_progress_card.dart';
import '../widgets/item_card.dart';

/// Bâtiments, filtrables par catégorie.
class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen({
    super.key,
    required this.controller,
    required this.now,
    required this.onOpenQueue,
  });

  final GameController controller;
  final DateTime now;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    return CategorizedList<BuildingKind>(
      header: InProgressCard(
        controller: controller,
        slot: Slot.construction,
        now: now,
        onTap: onOpenQueue,
      ),
      categories: data.categories['buildings'] ?? const {},
      items: BuildingKind.values,
      categoryOf: (k) => data[k].category,
      filter: realizableFilter(controller, 'buildings', now),
      itemBuilder: (context, k) => ItemCard(controller: controller, item: k, now: now),
    );
  }
}

/// Technologies, filtrables par catégorie ; le palier est indiqué sur chaque carte.
class ResearchScreen extends StatelessWidget {
  const ResearchScreen({
    super.key,
    required this.controller,
    required this.now,
    required this.onOpenQueue,
  });

  final GameController controller;
  final DateTime now;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    return CategorizedList<TechKind>(
      header: InProgressCard(
        controller: controller,
        slot: Slot.research,
        now: now,
        onTap: onOpenQueue,
      ),
      categories: data.categories['research'] ?? const {},
      items: TechKind.values,
      categoryOf: (k) => data.tech(k).category,
      filter: realizableFilter(controller, 'research', now),
      itemBuilder: (context, k) => ItemCard(controller: controller, item: k, now: now),
    );
  }
}

/// Filtre « Réalisables » d'un onglet de bâtiments ou de technos.
RealizableFilter<T> realizableFilter<T extends Unlockable>(
  GameController controller,
  String screen,
  DateTime now,
) {
  final state = controller.interpolated(now);
  final rules = controller.rules;
  return RealizableFilter<T>(
    enabled: controller.realizableOnly(screen),
    onChanged: (on) => controller.setRealizableOnly(screen, on),
    isRealizable: (k) => realizable(state, k, rules),
    waitFor: (k) => waitFor(state, k, rules),
    nameOf: (k) => controller.data.spec(k).name,
  );
}
