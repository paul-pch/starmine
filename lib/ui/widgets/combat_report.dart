import 'package:flutter/material.dart';

import '../../domain/combat.dart';
import '../../domain/game_data.dart';
import '../format.dart';

/// Rapport de combat : issue, rounds, pertes par camp, défenses reconstruites.
class CombatReport extends StatelessWidget {
  const CombatReport({
    super.key,
    required this.data,
    required this.result,
    this.attackerName = 'Pirates',
    this.defenderName = 'Planète',
  });

  final GameData data;
  final CombatResult result;
  final String attackerName;
  final String defenderName;

  static Future<void> show(BuildContext context, GameData data, CombatResult result) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (context, scroll) => SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: CombatReport(data: data, result: result),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = switch (result.winner) {
      CombatWinner.attacker => '$attackerName victorieux',
      CombatWinner.defender => '$defenderName victorieuse',
      CombatWinner.draw => 'Match nul',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(verdict, style: theme.textTheme.titleLarge),
        Text(
          '${result.rounds.length} round${result.rounds.length > 1 ? 's' : ''}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _SideTable(
          title: attackerName,
          data: data,
          start: result.attackerStart,
          left: result.attackerLeft,
        ),
        const SizedBox(height: 16),
        _SideTable(
          title: defenderName,
          data: data,
          start: result.defenderStart,
          left: result.defenderLeft,
          rebuilt: result.rebuilt,
        ),
      ],
    );
  }
}

class _SideTable extends StatelessWidget {
  const _SideTable({
    required this.title,
    required this.data,
    required this.start,
    required this.left,
    this.rebuilt = const {},
  });

  final String title;
  final GameData data;
  final Map<UnitKind, int> start;
  final Map<UnitKind, int> left;
  final Map<UnitKind, int> rebuilt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    String n(int v) => fmtAmount(v.toDouble());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        if (start.isEmpty) Text('Aucune unité', style: small),
        for (final e in start.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(child: Text(data.unit(e.key).name)),
                Text(
                  [
                    n(e.value),
                    '→ ${n(left[e.key] ?? 0)}',
                    if ((rebuilt[e.key] ?? 0) > 0) '(${n(rebuilt[e.key]!)} reconstruits)',
                  ].join(' '),
                  style: small,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
