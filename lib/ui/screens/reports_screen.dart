import 'package:flutter/material.dart';

import '../../data/game_repository.dart';
import '../../domain/resources.dart';
import '../../domain/story.dart';
import '../format.dart';
import '../game_controller.dart';
import '../notifications.dart';
import '../widgets/combat_report.dart';
import '../widgets/info_button.dart';
import '../widgets/raid_banner.dart';
import '../widgets/story_banner.dart';

/// Une entrée du journal : rapport de combat ou événement ponctuel.
sealed class JournalEntry {
  DateTime get at;
}

final class ReportEntry extends JournalEntry {
  ReportEntry(this.stored);

  final StoredReport stored;

  @override
  DateTime get at => stored.report.at;
}

final class StoryEntry extends JournalEntry {
  StoryEntry(this.outcome);

  final StoryOutcome outcome;

  @override
  DateTime get at => outcome.at;
}

/// Rapports et événements fusionnés, les plus récents d'abord.
List<JournalEntry> journal(List<StoredReport> reports, List<StoryOutcome> log) =>
    [for (final r in reports) ReportEntry(r), for (final o in log) StoryEntry(o)]
      ..sort((a, b) => b.at.compareTo(a.at));

/// Journal : raids, attaques et événements ponctuels dans une seule liste.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
        actions: const [
          InfoButton(title: 'Raids pirates', body: raidHelp),
          InfoButton(title: 'Événements', body: storyHelp),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final entries = journal(controller.reports, controller.storyLog);
          if (entries.isEmpty) {
            return const Center(child: Text('Aucun rapport ni événement pour l’instant'));
          }
          return ListView.separated(
            itemCount: entries.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => index == 0
                ? _ClearButton(onConfirm: controller.clearJournal)
                : switch (entries[index - 1]) {
                    final ReportEntry e => _ReportTile(controller: controller, entry: e),
                    final StoryEntry e => _StoryTile(controller: controller, entry: e),
                  },
          );
        },
      ),
    );
  }
}

String _date(DateTime at) {
  final t = at.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.controller, required this.entry});

  final GameController controller;
  final ReportEntry entry;

  @override
  Widget build(BuildContext context) {
    final r = entry.stored.report;
    final scheme = Theme.of(context).colorScheme;
    final good = CombatReport.good(r);
    return ListTile(
      leading: Icon(CombatReport.icon(r), color: good ? scheme.primary : scheme.error),
      title: Text(CombatReport.verdict(r)),
      subtitle: Text(
        [
          _date(r.at),
          if (r.loot != Resources.zero) '${r.expedition == null ? 'pillé' : 'rapporté'} ${fmtCost(r.loot)}',
        ].join(' · '),
      ),
      onTap: () => CombatReport.show(context, controller.data, r),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.controller, required this.entry});

  final GameController controller;
  final StoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final o = entry.outcome;
    final (title, body) = storyText(o, controller.data);
    return ListTile(
      leading: const Icon(Icons.auto_stories_outlined),
      title: Text(title),
      subtitle: Text(
        '${_date(o.at)}'
        '${o.kind == StoryOutcomeKind.happened ? gambleText(o.won) : ' · $body'}',
      ),
      onTap: () {
        final spec = controller.data.story.catalog[o.key];
        if (spec == null) return;
        InfoButton.show(
          context,
          title: spec.name,
          body: [
            spec.description,
            for (final e in spec.effects) storyEffectText(controller.data, e),
          ].join('\n\n'),
        );
      },
    );
  }
}

/// En tête de liste : efface rapports et événements, avec confirmation.
class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onConfirm});

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
              title: const Text('Effacer le journal ?'),
              content: const Text(
                'Les rapports de combat et les événements passés disparaissent ; les effets '
                'en cours et une décision en attente restent.',
              ),
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
        label: const Text('Effacer le journal'),
      ),
    );
  }
}
