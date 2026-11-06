import 'package:flutter/material.dart';

import '../../domain/combat.dart';
import '../../domain/resources.dart';
import '../format.dart';
import '../game_controller.dart';
import '../widgets/combat_report.dart';
import '../widgets/info_button.dart';
import '../widgets/raid_banner.dart';

/// Historique des raids, les plus récents d'abord.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports de raid'),
        actions: const [InfoButton(title: 'Raids pirates', body: raidHelp)],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final reports = controller.reports;
          if (reports.isEmpty) {
            return const Center(child: Text('Aucun raid pour l’instant'));
          }
          return ListView.separated(
            itemCount: reports.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = reports[i].report;
              final at = r.at.toLocal();
              String two(int n) => n.toString().padLeft(2, '0');
              final scheme = Theme.of(context).colorScheme;
              return ListTile(
                leading: Icon(
                  r.winner == CombatWinner.attacker
                      ? Icons.gpp_bad_outlined
                      : Icons.gpp_good_outlined,
                  color: r.winner == CombatWinner.attacker ? scheme.error : scheme.primary,
                ),
                title: Text(CombatReport.verdict(r)),
                subtitle: Text(
                  [
                    '${two(at.day)}/${two(at.month)} ${two(at.hour)}:${two(at.minute)}',
                    if (r.loot != Resources.zero) 'pillé ${fmtCost(r.loot)}',
                  ].join(' · '),
                ),
                onTap: () => CombatReport.show(context, controller.data, r),
              );
            },
          );
        },
      ),
    );
  }
}
