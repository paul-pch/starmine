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
          itemCount: reports.length + 1,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ClearButton(
                label: 'Effacer les rapports',
                question: 'Effacer les rapports ?',
                detail: 'Les rapports de combat passés disparaissent.',
                onConfirm: controller.clearReports,
              );
            }
            final r = reports[index - 1].report;
            final at = r.at.toLocal();
            String two(int n) => n.toString().padLeft(2, '0');
            final scheme = Theme.of(context).colorScheme;
            // Raid subi : bon si repoussé. Attaque d'une base : bon si gagnée.
            final good = r.baseName == null
                ? r.winner != CombatWinner.attacker
                : r.winner == CombatWinner.attacker;
            return ListTile(
              leading: Icon(
                r.baseName != null
                    ? Icons.rocket_launch_outlined
                    : good
                    ? Icons.gpp_good_outlined
                    : Icons.gpp_bad_outlined,
                color: good ? scheme.primary : scheme.error,
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
          itemCount: log.length + 1,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ClearButton(
                label: 'Effacer le journal',
                question: 'Effacer le journal ?',
                detail: 'Les événements passés disparaissent ; les effets en cours restent.',
                onConfirm: controller.clearStoryLog,
              );
            }
            final o = log[index - 1];
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

/// En tête des onglets Raids et Événements : même effacement, avec confirmation.
class _ClearButton extends StatelessWidget {
  const _ClearButton({
    required this.label,
    required this.question,
    required this.detail,
    required this.onConfirm,
  });

  final String label;
  final String question;
  final String detail;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(question),
              content: Text(detail),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Non'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Effacer'),
                ),
              ],
            ),
          );
          if (ok == true) await onConfirm();
        },
        icon: const Icon(Icons.delete_sweep_outlined),
        label: Text(label),
      ),
    );
  }
}
