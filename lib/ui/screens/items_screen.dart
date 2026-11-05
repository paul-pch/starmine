import 'package:flutter/material.dart';

import '../../domain/game_data.dart';
import '../game_controller.dart';
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
      children: [
        for (final item in items) ItemCard(controller: controller, item: item, now: now),
      ],
    );
  }
}
