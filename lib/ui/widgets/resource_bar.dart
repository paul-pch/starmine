import 'package:flutter/material.dart';

import '../../domain/resources.dart';
import '../format.dart';
import '../game_controller.dart';
import 'info_button.dart';

/// Stocks interpolés à [now], capacité, production horaire et bilan d'énergie.
class ResourceBar extends StatelessWidget {
  const ResourceBar({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final planet = state.planet;
    final rules = controller.rules;
    final stock = controller.interpolated(now).planet.resources;
    final cap = rules.capacity(planet.levels);
    final rate = rules.hourlyProduction(planet, state.research);
    final energy = rules.energy(planet, state.research);
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
          // Wrap plutôt que Row : passe à la ligne sur un écran étroit.
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.bolt,
                size: 16,
                color: energy.net < 0 ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
              Text(
                'Énergie ${energy.net > 0 ? '+' : ''}${fmtAmount(energy.net)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: energy.net < 0 ? theme.colorScheme.error : null,
                ),
              ),
              Text(
                '${fmtAmount(energy.produced)} produite · ${fmtAmount(energy.consumed)} consommée',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (energy.factor < 1)
                Text(
                  'Mines à ${(energy.factor * 100).floor()} %',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              const InfoButton(
                title: 'Énergie',
                body:
                    'Le solde est l’énergie produite moins l’énergie consommée par les mines. '
                    'S’il est négatif, toutes les mines tournent au même pourcentage réduit '
                    '(produite ÷ consommée). La production de base de la planète n’est pas '
                    'touchée.',
                size: 16,
              ),
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
          '/ ${fmtAmount(capacity)}  ${perHour < 0 ? '' : '+'}${fmtAmount(perHour)}/h',
          style: theme.textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
