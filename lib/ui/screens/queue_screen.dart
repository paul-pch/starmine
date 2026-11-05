import 'package:flutter/material.dart';

import '../../domain/events.dart';
import '../format.dart';
import '../game_controller.dart';

/// Les deux files : construction et recherche.
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _Slot(
          title: 'Construction',
          empty: 'Aucune construction en cours',
          order: state.currentConstruction,
          controller: controller,
          now: now,
        ),
        const SizedBox(height: 8),
        _Slot(
          title: 'Recherche',
          empty: 'Aucune recherche en cours',
          order: state.currentResearch,
          controller: controller,
          now: now,
        ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.title,
    required this.empty,
    required this.order,
    required this.controller,
    required this.now,
  });

  final String title;
  final String empty;
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
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (current == null)
              Text(empty, style: theme.textTheme.bodyMedium)
            else ...[
              Text(
                '${controller.data.spec(current.item).name} → niveau ${current.targetLevel}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _progress(current)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Reste ${fmtDuration(current.dueAt.difference(now))}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text('Fin ${_clock(current.dueAt.toLocal())}', style: theme.textTheme.bodySmall),
                ],
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

  double _progress(OrderDone o) {
    final total = o.dueAt.difference(o.startedAt).inMilliseconds;
    if (total <= 0) return 1;
    return (1 - o.dueAt.difference(now).inMilliseconds / total).clamp(0.0, 1.0);
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
