import 'package:flutter/material.dart';

import '../../domain/combat.dart';
import '../../domain/events.dart';
import '../../domain/raid.dart';
import '../format.dart';
import '../game_controller.dart';
import 'combat_stats.dart';
import 'info_button.dart';

const raidHelp =
    'Des pirates attaquent régulièrement la planète. Leur flotte est repérée un moment avant '
    'son arrivée ; sa force dépend de tes points (ressources dépensées ÷ 1000).\n\n'
    'S’ils gagnent, ils emportent jusqu’à la moitié de chaque ressource, dans la limite de '
    'leur soute. Dépenser tes ressources avant l’arrivée limite donc le pillage.\n\n'
    'Après le combat, 70 % des défenses détruites sont reconstruites.';

/// Bandeau d'alerte quand une flotte pirate est en route.
class RaidBanner extends StatelessWidget {
  const RaidBanner({super.key, required this.controller, required this.raid, required this.now});

  final GameController controller;
  final RaidArrival raid;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: InkWell(
        onTap: () => _details(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Flotte pirate en approche · arrivée dans '
                  '${fmtDuration(raid.dueAt.difference(now))}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
                ),
              ),
              Text(
                'Voir',
                style: theme.textTheme.labelLarge?.copyWith(color: scheme.onErrorContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _details(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: _RaidDetails(controller: controller, raid: raid),
      ),
    ),
  );
}

class _RaidDetails extends StatelessWidget {
  const _RaidDetails({required this.controller, required this.raid});

  final GameController controller;
  final RaidArrival raid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Flotte pirate', style: theme.textTheme.titleLarge)),
            const InfoButton(title: 'Raids pirates', body: raidHelp),
          ],
        ),
        const SizedBox(height: 8),
        for (final e in raid.fleet.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(child: Text(data.unit(e.key).name)),
                Text(fmtAmount(e.value.toDouble())),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Soute : ${fmtAmount(cargoCapacity(raid.fleet, data))}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        ForcesTable(
          attacker: SideStrength.of(data, CombatSide(units: raid.fleet)),
          defender: SideStrength.of(
            data,
            CombatSide(units: controller.state.planet.units, tech: controller.state.research),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: () => SimulationSheet.show(context, controller, raid.fleet),
            icon: const Icon(Icons.gps_fixed),
            label: const Text('Simuler 100 batailles'),
          ),
        ),
      ],
    );
  }
}
