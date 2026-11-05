import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/combat.dart';
import '../../domain/engine.dart';
import '../../domain/game_data.dart';
import '../format.dart';
import '../game_controller.dart';
import '../resource_style.dart';
import '../widgets/info_button.dart';

/// Défenses constructibles au chantier.
class DefenseScreen extends StatelessWidget {
  const DefenseScreen({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final defenses = [
      for (final k in UnitKind.values)
        if (controller.data.unit(k).defense) k,
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [for (final k in defenses) _UnitCard(controller: controller, unit: k, now: now)],
    );
  }
}

/// Attaque, bouclier et coque avec icônes.
class UnitStatsLine extends StatelessWidget {
  const UnitStatsLine({super.key, required this.stats});

  final UnitStats stats;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    Widget part(IconData icon, double v) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 3),
        Text(fmtAmount(v), style: style),
      ],
    );
    return Wrap(
      spacing: 12,
      children: [
        part(Icons.gps_fixed, stats.attack),
        part(Icons.shield_outlined, stats.shield),
        part(Icons.favorite_border, stats.hull),
      ],
    );
  }
}

const statsHelp =
    'Cible : attaque par tir. Bouclier : absorbe les dégâts avant la coque, se régénère à '
    'chaque round ; un tir inférieur à 1 % du bouclier n’a aucun effet. Cœur : coque, '
    '(métal + cristal) ÷ 10. Les technos Armes, Bouclier et Protection ajoutent 10 % par '
    'niveau.';

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.controller, required this.unit, required this.now});

  final GameController controller;
  final UnitKind unit;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rules = controller.rules;
    final state = controller.interpolated(now);
    final spec = controller.data.unit(unit);
    final owned = state.planet.count(unit);
    final block = checkBatch(state, unit, 1, rules);
    final locked = block is RequirementsNotMet;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(spec.name, style: theme.textTheme.titleMedium)),
                  InfoButton(
                    title: spec.name,
                    body: [
                      if (spec.description.isNotEmpty) spec.description,
                      statsHelp,
                    ].join('\n\n'),
                  ),
                  const Spacer(),
                  Text('× ${fmtAmount(owned.toDouble())}', style: theme.textTheme.titleMedium),
                ],
              ),
              UnitStatsLine(stats: UnitStats.of(spec, state.research)),
              if (locked) ...[
                const SizedBox(height: 4),
                Text(
                  'Requiert ${[for (final e in block.missing.entries) '${controller.data.spec(e.key).name} ${e.value} (${state.levelOf(e.key)})'].join(' · ')}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CostLine(cost: spec.baseCost, available: state.planet.resources),
                          const SizedBox(height: 2),
                          Text(
                            '${fmtDuration(unitDuration(state, unit, rules))} par unité',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (_blockText(block) case final text?)
                            Text(
                              text,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: block == null ? () => _order(context) : null,
                      child: const Text('Construire'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _blockText(OrderBlock? block) => switch (block) {
    null || RequirementsNotMet() => null,
    QueueBusy() => 'Chantier occupé',
    ShipyardBusy() => 'Impossible pendant l’agrandissement du chantier',
    MaxReached(:final max) => 'Maximum $max par planète',
    NotEnoughResources() => 'Ressources insuffisantes',
    LabBusy() || NotBuildable() => null,
  };

  Future<void> _order(BuildContext context) async {
    final state = controller.interpolated(now);
    final max = math.max(1, math.min(9999, maxOrderable(state, unit, controller.rules)));
    final count = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _QuantitySheet(controller: controller, unit: unit, max: max),
    );
    if (count == null) return;
    final reason = await controller.orderUnits(unit, count);
    if (reason != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Commande impossible')));
    }
  }
}

/// Choix de la quantité : curseur, raccourcis, coût et durée totaux.
class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({required this.controller, required this.unit, required this.max});

  final GameController controller;
  final UnitKind unit;
  final int max;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  var _count = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.controller;
    final spec = c.data.unit(widget.unit);
    final per = unitDuration(c.state, widget.unit, c.rules);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${spec.name} × $_count', style: theme.textTheme.titleMedium),
            if (widget.max > 1)
              Slider(
                value: _count.toDouble(),
                min: 1,
                max: widget.max.toDouble(),
                divisions: widget.max - 1,
                label: '$_count',
                onChanged: (v) => setState(() => _count = v.round()),
              ),
            Wrap(
              spacing: 8,
              children: [
                for (final n in {1, 10, 100, widget.max})
                  if (n <= widget.max)
                    ActionChip(
                      label: Text(n == widget.max ? 'Max ($n)' : '$n'),
                      onPressed: () => setState(() => _count = n),
                    ),
              ],
            ),
            const SizedBox(height: 12),
            CostLine(cost: spec.baseCost * _count.toDouble(), available: c.state.planet.resources),
            Text('Durée totale ${fmtDuration(per * _count)}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _count),
                child: Text('Construire $_count'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
