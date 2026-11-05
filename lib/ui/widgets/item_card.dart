import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/engine.dart';
import '../../domain/events.dart';
import '../../domain/game_data.dart';
import '../../domain/resources.dart';
import '../../domain/tech_tree.dart';
import '../format.dart';
import '../game_controller.dart';
import '../resource_style.dart';
import 'info_button.dart';

/// Carte d'un bâtiment ou d'une technologie : niveau, effet du niveau suivant, coût,
/// durée, ce qui bloque, bouton de lancement et réglage de production.
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.controller, required this.item, required this.now});

  final GameController controller;
  final Unlockable item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rules = controller.rules;
    final state = controller.interpolated(now);
    final spec = controller.data.spec(item);
    final level = state.levelOf(item);
    final cost = rules.cost(item, level + 1);
    final block = checkOrder(state, item, rules);
    final locked = block is RequirementsNotMet;
    final effect = _effect(state);
    final running = state.pending.whereType<OrderDone>().any((e) => e.item == item);
    final unlocks = controller.data.unlockedBy(item);

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
                  if (item is TechKind) ...[
                    Icon(ResourceStyle.researchIcon, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                  ],
                  Flexible(child: Text(spec.name, style: theme.textTheme.titleMedium)),
                  if (item case final TechKind tech) _TierLabel(tier: controller.data.tier(tech)),
                  if (spec.description.isNotEmpty)
                    InfoButton(title: spec.name, body: spec.description),
                  const Spacer(),
                  Text('Niv. $level', style: theme.textTheme.titleMedium),
                ],
              ),
              if (effect.isNotEmpty) Text(effect, style: theme.textTheme.bodyMedium),
              if (locked) ...[
                const SizedBox(height: 4),
                Text(
                  'Requiert ${_requirements(state, block.missing)}',
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
                          CostLine(cost: cost, available: state.planet.resources),
                          const SizedBox(height: 2),
                          Text(
                            fmtDuration(orderDuration(state, item, rules)),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (_blockText(state, block) case final text?)
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
                      child: Text(running ? 'En cours' : 'Niv. ${level + 1}'),
                    ),
                  ],
                ),
              ],
              if (unlocks.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Débloque ${unlocks.map((u) => u.name).join(' · ')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (item case final BuildingKind kind
                  when controller.data[kind].adjustable && level > 0)
                _PercentRow(controller: controller, kind: kind),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _order(BuildContext context) async {
    final reason = await controller.order(item);
    if (reason == null || !context.mounted) return;
    final text = switch (reason) {
      QueueBusy() => 'La file est occupée',
      LabBusy() => 'Le laboratoire est occupé',
      ShipyardBusy() => 'Le chantier est occupé',
      MaxReached() || NotBuildable() => 'Impossible',
      RequirementsNotMet() => 'Prérequis manquants',
      NotEnoughResources(:final missing) => 'Il manque ${fmtCost(missing)}',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _requirements(GameState state, Map<Unlockable, int> missing) => [
    for (final e in missing.entries)
      '${controller.data.spec(e.key).name} ${e.value} (${state.levelOf(e.key)})',
  ].join(' · ');

  String? _blockText(GameState state, OrderBlock? block) => switch (block) {
    null || RequirementsNotMet() => null,
    QueueBusy(current: final OrderDone current) =>
      'File occupée : ${controller.data.spec(current.item).name} ${current.targetLevel}',
    QueueBusy() => 'File occupée',
    ShipyardBusy() => 'Impossible pendant une production du chantier',
    MaxReached() || NotBuildable() => null,
    LabBusy() => switch (item) {
      BuildingKind() => 'Impossible pendant une recherche',
      TechKind() => 'Impossible pendant l’agrandissement du labo',
    },
    NotEnoughResources(:final missing) => _missingHint(state, missing),
  };

  /// « Manque 120 M · dans 14 min », ou capacité insuffisante.
  String _missingHint(GameState state, Resources missing) {
    final rules = controller.rules;
    final rate = rules.hourlyProduction(state.planet, state.research);
    final cap = rules.capacity(state.planet.levels);
    final cost = rules.cost(item, state.levelOf(item) + 1);
    var hours = 0.0;
    for (final k in ResourceKind.values) {
      if (missing[k] <= 0) continue;
      if (cost[k] > cap[k]) return 'Manque ${fmtCost(missing)} · capacité insuffisante';
      if (rate[k] <= 0) return 'Manque ${fmtCost(missing)}';
      hours = math.max(hours, missing[k] / rate[k]);
    }
    return 'Manque ${fmtCost(missing)} · dans ${fmtDuration(Duration(seconds: (hours * 3600).ceil()))}';
  }

  /// Gain apporté par le niveau suivant, en clair.
  String _effect(GameState state) {
    final rules = controller.rules;
    final data = controller.data;
    final next = switch (item) {
      BuildingKind() => state.copyWith(
        planet: state.planet.withLevel(item as BuildingKind, state.levelOf(item) + 1),
      ),
      TechKind() => state.copyWith(
        research: {...state.research, item as TechKind: state.levelOf(item) + 1},
      ),
    };
    final before = rules.hourlyProduction(state.planet, state.research);
    final after = rules.hourlyProduction(next.planet, next.research);
    final eBefore = rules.energy(state.planet, state.research);
    final eAfter = rules.energy(next.planet, next.research);

    final parts = <String>[];
    for (final k in ResourceKind.values) {
      final d = after[k] - before[k];
      if (d.abs() >= 1) {
        parts.add('${d > 0 ? '+' : '−'}${fmtAmount(d.abs())} ${resourceName(k).toLowerCase()}/h');
      }
    }
    final dProduced = eAfter.produced - eBefore.produced;
    final dConsumed = eAfter.consumed - eBefore.consumed;
    if (dProduced >= 1) parts.add('+${fmtAmount(dProduced)} énergie');
    if (dConsumed >= 1) parts.add('−${fmtAmount(dConsumed)} énergie');

    switch (item) {
      case BuildingKind.metalStorage || BuildingKind.crystalStorage || BuildingKind.deuteriumTank:
        final l = state.levelOf(item);
        parts.add(
          'Capacité ${fmtAmount(rules.storageCapacity(l))} → ${fmtAmount(rules.storageCapacity(l + 1))}',
        );
      case BuildingKind.roboticsFactory:
        final r = state.levelOf(item);
        parts.add('Constructions −${((1 - (1 + r) / (2 + r)) * 100).round()} %');
      case BuildingKind.naniteFactory:
        parts.add('Constructions −50 %');
      case BuildingKind.researchLab:
        final l = state.levelOf(item);
        parts.add('Recherches −${((1 - (1 + l) / (2 + l)) * 100).round()} %');
      case TechKind():
        final bonus = data.tech(item as TechKind).productionBonus;
        if (bonus != Resources.zero && parts.isEmpty) parts.add('Bonus de production des mines');
      default:
        break;
    }
    return parts.join(' · ');
  }
}

/// Réglage de production 0 à 100 %, pas de 10.
class _PercentRow extends StatelessWidget {
  const _PercentRow({required this.controller, required this.kind});

  final GameController controller;
  final BuildingKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = controller.state.planet.percent(kind);
    return Row(
      children: [
        Text('Production', style: theme.textTheme.bodySmall),
        const InfoButton(
          title: 'Réglage de production',
          body:
              'Réduit la production et, dans la même proportion, la consommation d’énergie '
              'ou de deutérium du bâtiment. Utile pour libérer de l’énergie ou économiser du '
              'deutérium.',
          size: 16,
        ),
        const Spacer(),
        DropdownButton<int>(
          value: percent,
          isDense: true,
          underline: const SizedBox.shrink(),
          items: [
            for (var p = 100; p >= 0; p -= 10) DropdownMenuItem(value: p, child: Text('$p %')),
          ],
          onChanged: (p) {
            if (p != null && p != percent) controller.setPercent(kind, p);
          },
        ),
      ],
    );
  }
}

/// Étiquette « Palier N » ; au tap, explique la notion de palier.
class _TierLabel extends StatelessWidget {
  const _TierLabel({required this.tier});

  final int tier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => InfoButton.show(
          context,
          title: 'Paliers de recherche',
          body:
              'Le palier est la profondeur d’une technologie dans l’arbre : une techno de '
              'palier 3 demande au moins une techno de palier 2, et ainsi de suite. '
              '« Requiert » indique ce qui manque, « Débloque » ce que la techno ouvre ensuite.',
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Palier $tier',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
