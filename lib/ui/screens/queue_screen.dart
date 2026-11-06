import 'package:flutter/material.dart';

import '../../domain/engine.dart';
import '../../domain/events.dart';
import '../format.dart';
import '../game_controller.dart';
import '../resource_style.dart';
import '../widgets/in_progress_card.dart';

/// Les deux files : construction et recherche.
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final upgrade = state.currentConstruction;
    final upgradeLeft = upgrade == null ? '' : fmtDuration(upgrade.dueAt.difference(now));
    (String, bool) idle(Slot slot, String none, String missing, String building) =>
        switch (slotStatus(state, slot)) {
          SlotStatus.unavailable => (missing, false),
          SlotStatus.blocked => (
            '$building en agrandissement : impossible pendant encore $upgradeLeft',
            true,
          ),
          SlotStatus.free || SlotStatus.busy => (none, false),
        };
    final research = idle(
      Slot.research,
      'Aucune recherche en cours',
      'Construis un laboratoire de recherche pour lancer des recherches',
      'Laboratoire',
    );
    final shipyard = idle(
      Slot.shipyard,
      'Aucune production en cours',
      'Construis un chantier spatial pour produire des défenses',
      'Chantier',
    );
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _Slot(
          icon: Icons.factory_outlined,
          title: 'Construction',
          empty: 'Aucune construction en cours',
          order: state.currentConstruction,
          controller: controller,
          now: now,
        ),
        const SizedBox(height: 8),
        _Slot(
          icon: ResourceStyle.researchIcon,
          title: 'Recherche',
          empty: research.$1,
          blocked: research.$2,
          order: state.currentResearch,
          controller: controller,
          now: now,
        ),
        const SizedBox(height: 8),
        _BatchSlot(
          batch: state.currentBatch,
          empty: shipyard.$1,
          blocked: shipyard.$2,
          controller: controller,
          now: now,
        ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.icon,
    required this.title,
    required this.empty,
    this.blocked = false,
    required this.order,
    required this.controller,
    required this.now,
  });

  final IconData icon;
  final String title;
  final String empty;
  final bool blocked;
  final OrderDone? order;
  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = order;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(title, style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            if (current == null)
              _EmptyText(text: empty, blocked: blocked)
            else ...[
              Text(
                '${controller.data.spec(current.item).name} → niveau ${current.targetLevel}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: orderProgress(current, now)),
              const SizedBox(height: 8),
              _TimeLine(
                left: 'Reste ${fmtDuration(current.dueAt.difference(now))}',
                right: 'Fin ${_clock(current.dueAt.toLocal())}',
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _cancel(context, current),
                  icon: const Icon(Icons.close),
                  label: const Text('Annuler'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, OrderDone o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(o is ResearchDone ? 'Annuler la recherche ?' : 'Annuler la construction ?'),
        content: const Text('Les ressources sont remboursées intégralement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.cancel(o.id);
  }

  static String _clock(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

/// Lot du chantier : progression du lot et de l'unité en cours. Pas d'annulation.
class _BatchSlot extends StatelessWidget {
  const _BatchSlot({
    required this.batch,
    required this.empty,
    required this.blocked,
    required this.controller,
    required this.now,
  });

  final ShipyardBatch? batch;
  final String empty;
  final bool blocked;
  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = batch;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('Chantier', style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            if (b == null)
              _EmptyText(text: empty, blocked: blocked)
            else ...[
              Text(
                '${controller.data.unit(b.unit).name} · ${b.ordered - b.remaining} / ${b.ordered}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: (b.ordered - b.remaining) / b.ordered),
              const SizedBox(height: 8),
              _TimeLine(
                left: 'Prochaine dans ${fmtDuration(b.dueAt.difference(now))}',
                right: 'Fin ${fmtDuration(b.finishAt.difference(now))}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reste et fin, aux deux bords ; passent l'un sous l'autre si la largeur manque.
class _TimeLine extends StatelessWidget {
  const _TimeLine({required this.left, required this.right});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        children: [
          Text(left, style: theme.textTheme.bodyMedium),
          Text(right, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Message d'une file vide ; en rouge avec un cadenas quand elle est bloquée.
class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text, required this.blocked});

  final String text;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!blocked) return Text(text, style: theme.textTheme.bodyMedium);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_clock_outlined, size: 18, color: theme.colorScheme.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
        ),
      ],
    );
  }
}
