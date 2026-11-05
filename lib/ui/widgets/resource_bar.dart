import 'package:flutter/material.dart';

import '../../domain/resources.dart';
import '../format.dart';
import '../game_controller.dart';

/// Stocks interpolés à [now], capacité, production horaire et bilan d'énergie.
class ResourceBar extends StatelessWidget {
  const ResourceBar({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final planet = controller.state.planet;
    final rules = controller.rules;
    final stock = rules.produce(planet, now.difference(planet.lastUpdate));
    final cap = rules.capacity(planet.levels);
    final rate = rules.hourlyProduction(planet.levels, tempMax: planet.tempMax);
    final energy = rules.energy(planet.levels);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              for (final k in ResourceKind.values)
                Expanded(
                  child: _ResourceTile(
                    name: resourceName(k),
                    stock: stock[k],
                    capacity: cap[k],
                    perHour: rate[k],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.bolt,
                size: 16,
                color: energy.net < 0 ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Énergie ${fmtAmount(energy.net)}  '
                '(${fmtAmount(energy.produced)} / ${fmtAmount(energy.consumed)})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: energy.net < 0 ? theme.colorScheme.error : null,
                ),
              ),
              if (energy.factor < 1) ...[
                const Spacer(),
                Text(
                  'Mines à ${(energy.factor * 100).floor()} %',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    required this.name,
    required this.stock,
    required this.capacity,
    required this.perHour,
  });

  final String name;
  final double stock;
  final double capacity;
  final double perHour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final full = stock >= capacity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: theme.textTheme.labelSmall),
        Text(
          fmtAmount(stock),
          style: theme.textTheme.titleMedium?.copyWith(
            color: full ? theme.colorScheme.error : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          '/ ${fmtAmount(capacity)}  +${fmtAmount(perHour)}/h',
          style: theme.textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
