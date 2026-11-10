import 'package:flutter/material.dart';

import '../../domain/combat.dart';
import '../../domain/game_data.dart';
import '../../domain/raid.dart';
import '../../domain/resources.dart';
import '../format.dart';
import '../resource_style.dart';
import 'combat_stats.dart';

/// Rapport de combat : issue, pillage, pertes par camp, défenses reconstruites.
class CombatReport extends StatelessWidget {
  const CombatReport({super.key, required this.data, required this.report});

  final GameData data;
  final RaidReport report;

  static Future<void> show(BuildContext context, GameData data, RaidReport report) =>
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
            child: CombatReport(data: data, report: report),
          ),
        ),
      );

  static String verdict(RaidReport r) {
    if (r.expedition case final e?) return expeditionVerdict(e, r);
    if (r.patrol) {
      return switch (r.winner) {
        CombatWinner.attacker => 'Patrouille repoussée : débris de ${r.baseName} collectés',
        _ => 'Recycleurs surpris par une patrouille près de ${r.baseName}',
      };
    }
    return _combatVerdict(r);
  }

  /// Issue favorable au joueur (icône et couleur du journal et de la popover).
  static bool good(RaidReport r) {
    if (r.expedition case final e?) {
      return switch (e) {
        ExpeditionOutcome.resources || ExpeditionOutcome.ships || ExpeditionOutcome.early => true,
        ExpeditionOutcome.ambush => r.winner == CombatWinner.attacker,
        _ => false,
      };
    }
    return r.baseName == null
        ? r.winner != CombatWinner.attacker
        : r.winner == CombatWinner.attacker;
  }

  /// Icône du rapport : raid, attaque ou recyclage, expédition.
  static IconData icon(RaidReport r) => r.expedition != null
      ? Icons.travel_explore
      : r.baseName != null
      ? Icons.rocket_launch_outlined
      : good(r)
      ? Icons.gpp_good_outlined
      : Icons.gpp_bad_outlined;

  /// Titre d'un rapport d'expédition.
  static String expeditionVerdict(ExpeditionOutcome e, RaidReport r) => switch (e) {
    ExpeditionOutcome.nothing => 'Expédition : rien trouvé',
    ExpeditionOutcome.resources => 'Expédition : ressources trouvées',
    ExpeditionOutcome.ships => 'Expédition : vaisseaux trouvés',
    ExpeditionOutcome.ambush =>
      r.winner == CombatWinner.attacker
          ? 'Expédition : embuscade repoussée'
          : 'Expédition : embuscade pirate',
    ExpeditionOutcome.delay => 'Expédition : retour retardé',
    ExpeditionOutcome.early => 'Expédition : retour anticipé',
    ExpeditionOutcome.blackHole => 'Expédition perdue dans un trou noir',
  };

  static String _combatVerdict(RaidReport r) => switch ((r.winner, r.baseName)) {
    (CombatWinner.attacker, null) => 'Raid réussi : planète pillée',
    (CombatWinner.defender, null) => 'Raid repoussé',
    (CombatWinner.draw, null) => 'Match nul : les pirates repartent',
    (CombatWinner.attacker, final base?) => 'Attaque réussie : $base pillée',
    (CombatWinner.defender, final base?) => 'Attaque repoussée par $base',
    (CombatWinner.draw, final base?) => 'Match nul contre $base',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = report;
    final at = r.at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.simulated ? 'Simulation · ${verdict(r)}' : verdict(r),
          style: theme.textTheme.titleLarge,
        ),
        Text(
          [
            if (!r.simulated) '${two(at.day)}/${two(at.month)} ${two(at.hour)}:${two(at.minute)}',
            if (r.hasCombat || r.expedition == null) '${r.rounds} round${r.rounds > 1 ? 's' : ''}',
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        if (r.loot != Resources.zero) ...[
          const SizedBox(height: 12),
          Text(
            _ours(r) ? 'Butin rapporté' : 'Butin emporté',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          CostLine(cost: r.loot),
        ],
        if (r.debris != Resources.zero) ...[
          const SizedBox(height: 12),
          Text('Champ de débris créé', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          CostLine(cost: r.debris),
        ],
        if (r.found.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Vaisseaux trouvés', style: theme.textTheme.titleSmall),
          for (final e in r.found.entries)
            Text('${e.value} × ${data.unit(e.key).name}', style: theme.textTheme.bodySmall),
        ],
        if (r.expedition != null && !r.hasCombat) ...[
          const SizedBox(height: 16),
          _SideTable(title: 'Ta flotte', data: data, start: r.attackerStart, left: r.attackerLeft),
        ] else ...[
        if ((r.attackerStrength, r.defenderStrength) case (final a?, final d?)) ...[
          const SizedBox(height: 16),
          ForcesTable(
            attacker: a,
            defender: d,
            attackerName: _ours(r) ? 'Ta flotte' : 'Pirates',
            defenderName: _theirs(r),
          ),
        ],
        const SizedBox(height: 16),
        _SideTable(
          title: _ours(r) ? 'Ta flotte' : 'Pirates',
          data: data,
          start: r.attackerStart,
          left: r.attackerLeft,
        ),
        const SizedBox(height: 16),
        _SideTable(
          title: _theirs(r),
          data: data,
          start: r.defenderStart,
          left: r.defenderLeft,
          rebuilt: r.rebuilt,
        ),
        if (r.roundDetails.isNotEmpty) ...[
          const SizedBox(height: 8),
          RoundsTable(rounds: r.roundDetails),
        ],
        ],
      ],
    );
  }
}

/// Ta flotte est le camp attaquant : attaque d'une base, patrouille, expédition.
bool _ours(RaidReport r) => r.baseName != null || r.expedition != null;

String _theirs(RaidReport r) => r.expedition != null
    ? 'Pirates'
    : r.patrol
    ? 'Patrouille pirate'
    : r.baseName ?? 'Planète';

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
