import 'package:flutter/material.dart';

import '../format.dart';
import '../game_controller.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = controller.state.currentConstruction;
    if (current == null) {
      return Center(child: Text('Aucune construction en cours', style: theme.textTheme.bodyLarge));
    }

    final total = current.dueAt.difference(current.startedAt);
    final remaining = current.dueAt.difference(now);
    final progress = total.inMilliseconds <= 0
        ? 1.0
        : (1 - remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.data[current.building].name} → niveau ${current.targetLevel}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Reste ${fmtDuration(remaining)}', style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    Text(
                      'Fin ${_clock(current.dueAt.toLocal())}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancel(context, current.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _cancel(BuildContext context, int eventId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la construction ?'),
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
    if (ok == true) await controller.cancel(eventId);
  }

  static String _clock(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}
