import 'package:flutter/material.dart';

import '../../domain/combat.dart';
import '../../domain/resources.dart';
import '../format.dart';
import '../game_controller.dart';
import '../widgets/combat_report.dart';
import '../widgets/info_button.dart';
import '../../domain/story.dart';
import '../notifications.dart';
import '../widgets/raid_banner.dart';
import '../widgets/story_banner.dart';

/// Historique des raids, les plus récents d'abord.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rapports'),
          actions: const [InfoButton(title: 'Raids pirates', body: raidHelp)],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Raids'),
              Tab(text: 'Événements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _raids(),
            _StoryLogList(controller: controller),
          ],
        ),
      ),
    );
  }

  Widget _raids() {
    return ListenableBuilder(
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
    );
  }
}

/// Journal des événements ponctuels (spec 14), les plus récents d'abord.
class _StoryLogList extends StatelessWidget {
  const _StoryLogList({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final log = controller.storyLog;
        if (log.isEmpty) return const Center(child: Text('Aucun événement pour l’instant'));
        return ListView.separated(
          itemCount: log.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final o = log[i];
            final (title, body) = storyText(o, controller.data);
            final at = o.at.toLocal();
            String two(int n) => n.toString().padLeft(2, '0');
            return ListTile(
              leading: const Icon(Icons.auto_stories_outlined),
              title: Text(title),
              subtitle: Text(
                '${two(at.day)}/${two(at.month)} ${two(at.hour)}:${two(at.minute)}'
                '${o.kind == StoryOutcomeKind.happened ? '' : ' · $body'}',
              ),
              onTap: () {
                final spec = controller.data.story.catalog[o.key];
                if (spec == null) return;
                InfoButton.show(
                  context,
                  title: spec.name,
                  body: [
                    spec.description,
                    for (final e in spec.effects) storyEffectText(e),
                  ].join('\n\n'),
                );
              },
            );
          },
        );
      },
    );
  }
}
