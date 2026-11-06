import 'package:flutter/material.dart';

import '../../domain/engine.dart';
import '../../domain/events.dart';
import '../format.dart';
import '../game_controller.dart';
import '../theme.dart';

/// Avancement d'un ordre à [now], entre 0 et 1.
double orderProgress(OrderDone order, DateTime now) {
  final total = order.dueAt.difference(order.startedAt).inMilliseconds;
  if (total <= 0) return 1;
  return (1 - order.dueAt.difference(now).inMilliseconds / total).clamp(0.0, 1.0);
}

/// En tête d'onglet : ce qui occupe la file ou la bloque. Rien si elle est libre.
/// Le tap ouvre l'onglet File.
class InProgressCard extends StatelessWidget {
  const InProgressCard({
    super.key,
    required this.controller,
    required this.slot,
    required this.now,
    required this.onTap,
  });

  final GameController controller;
  final Slot slot;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final data = controller.data;
    final OrderDone? order = switch (slot) {
      Slot.construction => state.currentConstruction,
      Slot.research => state.currentResearch,
      Slot.shipyard => null,
    };
    final batch = slot == Slot.shipyard ? state.currentBatch : null;
    final upgrade = state.currentConstruction;

    if (order != null) {
      return _running(
        context,
        title: 'En cours · ${data.spec(order.item).name} → ${order.targetLevel}',
        left: order.dueAt.difference(now),
        progress: orderProgress(order, now),
      );
    }
    if (batch != null) {
      final done = batch.ordered - batch.remaining;
      return _running(
        context,
        title: 'En cours · ${data.unit(batch.unit).name} · $done / ${batch.ordered}',
        left: batch.finishAt.difference(now),
        progress: done / batch.ordered,
      );
    }
    if (slotStatus(state, slot) == SlotStatus.blocked && upgrade != null) {
      return _blocked(context, upgrade.dueAt.difference(now));
    }
    return const SizedBox.shrink();
  }

  Widget _frame({required Color color, required Color border, required Widget child}) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    ),
  );

  Widget _running(
    BuildContext context, {
    required String title,
    required Duration left,
    required double progress,
  }) {
    final style = Theme.of(context).textTheme.bodySmall;
    return _frame(
      color: Palette.inProgress,
      border: Palette.inProgressLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: style?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(fmtDuration(left), style: mono(style)?.copyWith(color: Palette.action)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: Palette.action,
              backgroundColor: Palette.inProgressTrack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocked(BuildContext context, Duration left) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    final building = slot == Slot.research ? 'Laboratoire' : 'Chantier';
    return _frame(
      color: Palette.surface,
      border: error,
      child: Row(
        children: [
          Icon(Icons.lock_clock_outlined, size: 18, color: error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$building en agrandissement : impossible pendant encore ${fmtDuration(left)}',
              style: theme.textTheme.bodySmall?.copyWith(color: error),
            ),
          ),
        ],
      ),
    );
  }
}
