import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/engine.dart';
import '../../domain/game_data.dart';
import '../../domain/resources.dart';
import '../format.dart';
import '../game_controller.dart';

class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final kind in BuildingKind.values)
          _BuildingCard(controller: controller, kind: kind, now: now),
      ],
    );
  }
}

class _BuildingCard extends StatelessWidget {
  const _BuildingCard({required this.controller, required this.kind, required this.now});

  final GameController controller;
  final BuildingKind kind;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rules = controller.rules;
    final planet = controller.state.planet;
    final level = planet.level(kind);
    final cost = rules.cost(kind, level + 1);
    final duration = rules.buildDuration(
      cost,
      roboticsLevel: planet.level(BuildingKind.roboticsFactory),
    );
    // Stocks interpolés : le bouton s'active dès que les ressources sont là.
    final stock = rules.produce(planet, now.difference(planet.lastUpdate));
    final missing = stock.missingFor(cost);
    final building = controller.state.currentConstruction?.building == kind;
    final queueBusy = controller.state.currentConstruction != null;
    final affordable = stock.covers(cost);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(controller.data[kind].name, style: theme.textTheme.titleMedium),
                ),
                Text('Niv. $level', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(_effect(), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fmtCost(cost),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: affordable ? null : theme.colorScheme.error,
                        ),
                      ),
                      Text(fmtDuration(duration), style: theme.textTheme.bodySmall),
                      if (!affordable)
                        Text(
                          _missingHint(missing),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: queueBusy || !affordable ? null : () => _build(context),
                  child: Text(building ? 'En cours' : 'Niv. ${level + 1}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _build(BuildContext context) async {
    final reason = await controller.build(kind);
    if (reason == null || !context.mounted) return;
    final text = switch (reason) {
      QueueBusy() => 'Une construction est déjà en cours',
      NotEnoughResources(:final missing) => 'Il manque ${fmtCost(missing)}',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Gain apporté par le niveau suivant.
  String _effect() {
    final rules = controller.rules;
    final planet = controller.state.planet;
    final spec = controller.data[kind];
    final levels = planet.levels;
    final next = {...levels, kind: levels[kind]! + 1};

    final produces = spec.produces;
    if (produces != null) {
      final before = rules.hourlyProduction(levels, tempMax: planet.tempMax)[produces];
      final after = rules.hourlyProduction(next, tempMax: planet.tempMax)[produces];
      final energy = rules.energy(next).consumed - rules.energy(levels).consumed;
      return '+${fmtAmount(after - before)} ${resourceName(produces).toLowerCase()}/h · '
          '−${fmtAmount(energy)} énergie';
    }
    if (spec.energyProduction > 0) {
      final gain = rules.energy(next).produced - rules.energy(levels).produced;
      return '+${fmtAmount(gain)} énergie';
    }
    final stores = spec.stores;
    if (stores != null) {
      return 'Capacité ${fmtAmount(rules.storageCapacity(levels[kind]!))} → '
          '${fmtAmount(rules.storageCapacity(levels[kind]! + 1))}';
    }
    if (kind == BuildingKind.roboticsFactory) {
      final r = levels[kind]!;
      final reduction = 1 - (1 + r) / (2 + r);
      return 'Durées de construction −${(reduction * 100).round()} %';
    }
    return '';
  }

  /// « Manque 120 M · dans 14 min », ou capacité insuffisante.
  String _missingHint(Resources missing) {
    final rules = controller.rules;
    final planet = controller.state.planet;
    final rate = rules.hourlyProduction(planet.levels, tempMax: planet.tempMax);
    final cap = rules.capacity(planet.levels);
    final cost = rules.cost(kind, planet.level(kind) + 1);
    var hours = 0.0;
    for (final k in ResourceKind.values) {
      if (missing[k] <= 0) continue;
      if (cost[k] > cap[k]) return 'Manque ${fmtCost(missing)} · capacité insuffisante';
      if (rate[k] <= 0) return 'Manque ${fmtCost(missing)}';
      hours = math.max(hours, missing[k] / rate[k]);
    }
    final wait = Duration(seconds: (hours * 3600).ceil());
    return 'Manque ${fmtCost(missing)} · dans ${fmtDuration(wait)}';
  }
}
