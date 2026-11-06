import 'package:flutter/material.dart';

import '../domain/game_data.dart';
import '../domain/resources.dart';
import 'format.dart';
import 'theme.dart';

/// Icône et couleur de chaque ressource, partout dans l'app.
abstract final class ResourceStyle {
  static const energyColor = Color(0xFFF5C451);
  static const energyIcon = Icons.bolt;
  static const researchIcon = Icons.science_outlined;

  static IconData icon(ResourceKind kind) => switch (kind) {
    ResourceKind.metal => Icons.view_in_ar,
    ResourceKind.crystal => Icons.diamond_outlined,
    ResourceKind.deuterium => Icons.water_drop_outlined,
  };

  static Color color(ResourceKind kind) => switch (kind) {
    ResourceKind.metal => const Color(0xFFA7B1BC),
    ResourceKind.crystal => const Color(0xFF64B5F6),
    ResourceKind.deuterium => const Color(0xFF4DD0C8),
  };
}

/// Icône vectorielle d'un élément : repli quand son image manque (spec 11).
abstract final class ItemStyle {
  static IconData icon(Unlockable item) => switch (item) {
    BuildingKind.metalMine || BuildingKind.metalStorage => ResourceStyle.icon(ResourceKind.metal),
    BuildingKind.crystalMine ||
    BuildingKind.crystalStorage => ResourceStyle.icon(ResourceKind.crystal),
    BuildingKind.deuteriumSynthesizer ||
    BuildingKind.deuteriumTank => ResourceStyle.icon(ResourceKind.deuterium),
    BuildingKind.solarPlant || BuildingKind.fusionReactor => ResourceStyle.energyIcon,
    BuildingKind.roboticsFactory || BuildingKind.naniteFactory => Icons.precision_manufacturing,
    BuildingKind.shipyard => Icons.rocket_launch_outlined,
    BuildingKind.researchLab => ResourceStyle.researchIcon,
    TechKind() => ResourceStyle.researchIcon,
  };

  static const unitIcon = Icons.shield_outlined;
}

/// Coût affiché avec les icônes ; une ressource insuffisante passe en couleur d'erreur.
class CostLine extends StatelessWidget {
  const CostLine({super.key, required this.cost, this.available});

  final Resources cost;

  /// Stocks disponibles ; `null` = pas de mise en évidence du manque.
  final Resources? available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = mono(theme.textTheme.bodySmall);
    final parts = [
      for (final k in ResourceKind.values)
        if (cost[k] > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ResourceStyle.icon(k), size: 14, color: ResourceStyle.color(k)),
              const SizedBox(width: 3),
              Text(
                fmtAmount(cost[k]),
                style: style?.copyWith(
                  color: available != null && available![k] < cost[k]
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
            ],
          ),
    ];
    if (parts.isEmpty) return Text('gratuit', style: style);
    return Wrap(spacing: 10, runSpacing: 2, children: parts);
  }
}
