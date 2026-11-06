import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/combat.dart';
import '../../domain/game_data.dart';
import '../../domain/raid.dart';
import '../../domain/resources.dart';
import '../format.dart';
import '../game_controller.dart';
import '../resource_style.dart';
import 'combat_report.dart';
import 'info_button.dart';

const forcesHelp =
    'Attaque : puissance de feu totale par round, hors tir rapide. Boucliers : dégâts '
    'absorbés chaque round avant la coque (ils se régénèrent). Coque : points de structure ; '
    'une unité sous 70 % de coque peut exploser. Technos Armes, Bouclier et Protection '
    'comprises.';

const roundsHelp =
    'Pour chaque round et chaque camp : nombre de tirs (tir rapide compris), puissance tirée, '
    'part encaissée par les boucliers adverses, part infligée aux coques. Le reste est perdu '
    '(règle du 1 %, cible déjà détruite, excédent).';

/// Forces en présence : attaque, boucliers, coque, nombre d'unités, côte à côte.
class ForcesTable extends StatelessWidget {
  const ForcesTable({
    super.key,
    required this.attacker,
    required this.defender,
    this.attackerName = 'Pirates',
    this.defenderName = 'Planète',
  });

  final SideStrength attacker;
  final SideStrength defender;
  final String attackerName;
  final String defenderName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final head = theme.textTheme.labelMedium;
    final cell = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    TableRow row(IconData icon, String label, double a, double d) {
      // Le camp le plus fort sur la ligne est mis en évidence.
      final strong = theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(icon, size: 14),
                const SizedBox(width: 4),
                Text(label, style: cell),
              ],
            ),
          ),
          Text(fmtAmount(a), textAlign: TextAlign.end, style: a > d ? strong : cell),
          Text(fmtAmount(d), textAlign: TextAlign.end, style: d > a ? strong : cell),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Forces en présence', style: theme.textTheme.titleSmall),
            const InfoButton(title: 'Forces en présence', body: forcesHelp, size: 16),
          ],
        ),
        Table(
          columnWidths: const {0: FlexColumnWidth(1.4), 1: FlexColumnWidth(), 2: FlexColumnWidth()},
          children: [
            TableRow(
              children: [
                const SizedBox.shrink(),
                Text(attackerName, textAlign: TextAlign.end, style: head),
                Text(defenderName, textAlign: TextAlign.end, style: head),
              ],
            ),
            row(Icons.groups_outlined, 'Unités', attacker.units.toDouble(), defender.units.toDouble()),
            row(Icons.gps_fixed, 'Attaque', attacker.attack, defender.attack),
            row(Icons.shield_outlined, 'Boucliers', attacker.shield, defender.shield),
            row(Icons.favorite_border, 'Coque', attacker.hull, defender.hull),
          ],
        ),
      ],
    );
  }
}

/// Détail des rounds, repliable.
class RoundsTable extends StatelessWidget {
  const RoundsTable({super.key, required this.rounds});

  final List<CombatRound> rounds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cell = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final head = theme.textTheme.labelSmall;

    TableRow line(String who, Volley v) => TableRow(
      children: [
        Text(who, style: cell),
        Text(fmtAmount(v.shots.toDouble()), textAlign: TextAlign.end, style: cell),
        Text(fmtAmount(v.fired), textAlign: TextAlign.end, style: cell),
        Text(fmtAmount(v.toShields), textAlign: TextAlign.end, style: cell),
        Text(fmtAmount(v.toHull), textAlign: TextAlign.end, style: cell),
      ],
    );

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Row(
        children: [
          Text('Détail des rounds', style: theme.textTheme.titleSmall),
          const InfoButton(title: 'Détail des rounds', body: roundsHelp, size: 16),
        ],
      ),
      children: [
        for (var i = 0; i < rounds.length; i++) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Text('Round ${i + 1}', style: theme.textTheme.labelLarge),
            ),
          ),
          Table(
            columnWidths: const {0: FlexColumnWidth(1.2)},
            children: [
              TableRow(
                children: [
                  const SizedBox.shrink(),
                  Text('Tirs', textAlign: TextAlign.end, style: head),
                  Text('Puissance', textAlign: TextAlign.end, style: head),
                  Text('Boucliers', textAlign: TextAlign.end, style: head),
                  Text('Coques', textAlign: TextAlign.end, style: head),
                ],
              ),
              line('Pirates', rounds[i].attacker),
              line('Planète', rounds[i].defender),
            ],
          ),
          Text(
            'Restants : pirates ${fmtAmount(_count(rounds[i].attackerLeft))} · '
            'planète ${fmtAmount(_count(rounds[i].defenderLeft))}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  static double _count(Map<UnitKind, int> units) =>
      units.values.fold(0, (a, b) => a + b).toDouble();
}

/// Lance 100 simulations et affiche le bilan ; donne accès à une bataille type.
abstract final class SimulationSheet {
  static const runs = 100;

  static Future<void> show(
    BuildContext context,
    GameController controller,
    Map<UnitKind, int> fleet,
  ) {
    final summary = simulateRaid(
      controller.state,
      fleet,
      controller.data,
      runs: runs,
      random: math.Random(),
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimulationSummaryView(data: controller.data, summary: summary),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _typical(context, controller, fleet),
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: const Text('Voir une bataille type'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _typical(
    BuildContext context,
    GameController controller,
    Map<UnitKind, int> fleet,
  ) {
    final state = controller.state;
    final attacker = CombatSide(units: fleet);
    final defender = CombatSide(units: state.planet.units, tech: state.research);
    final data = controller.data;
    final result = simulateCombat(data, attacker, defender, math.Random());
    final taken = result.winner == CombatWinner.attacker
        ? loot(
            state.planet.resources,
            cargoCapacity(result.attackerLeft, data),
            data.pirates.lootShare,
          )
        : Resources.zero;
    return CombatReport.show(
      context,
      data,
      RaidReport.fromCombat(
        result,
        at: controller.now(),
        loot: taken,
        simulated: true,
        attackerStrength: SideStrength.of(data, attacker),
        defenderStrength: SideStrength.of(data, defender),
      ),
    );
  }
}

/// Bilan de simulations : issue en pourcentages, pertes et pillage moyens.
class SimulationSummaryView extends StatelessWidget {
  const SimulationSummaryView({super.key, required this.data, required this.summary});

  final GameData data;
  final SimulationSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = summary;
    String pct(int n) => '${(s.rate(n) * 100).round()} %';

    Widget outcome(String label, int n, Color color) => Expanded(
      child: Column(
        children: [
          Text(pct(n), style: theme.textTheme.headlineSmall?.copyWith(color: color)),
          Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );

    Widget losses(String title, Map<UnitKind, double> l) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title · ${fmtAmount(fleetValue(l, data))} de ressources en moyenne',
          style: theme.textTheme.titleSmall,
        ),
        if (l.isEmpty) Text('Aucune', style: theme.textTheme.bodySmall),
        for (final e in l.entries)
          Row(
            children: [
              Expanded(child: Text(data.unit(e.key).name, style: theme.textTheme.bodySmall)),
              Text(e.value.toStringAsFixed(1), style: theme.textTheme.bodySmall),
            ],
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.runs} batailles simulées', style: theme.textTheme.titleLarge),
        Text(
          '${s.averageRounds.toStringAsFixed(1)} rounds en moyenne',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            outcome('Raid repoussé', s.defenderWins, theme.colorScheme.primary),
            outcome('Match nul', s.draws, theme.colorScheme.onSurfaceVariant),
            outcome('Planète pillée', s.attackerWins, theme.colorScheme.error),
          ],
        ),
        const SizedBox(height: 16),
        ForcesTable(attacker: s.attackerStrength, defender: s.defenderStrength),
        const SizedBox(height: 16),
        Text('Pillage moyen', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        CostLine(cost: s.averageLoot),
        const SizedBox(height: 16),
        losses('Pertes des pirates', s.attackerLosses),
        const SizedBox(height: 12),
        losses('Pertes de la planète (après reconstruction)', s.defenderLosses),
      ],
    );
  }
}
