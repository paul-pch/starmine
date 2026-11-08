import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/availability.dart';
import '../../domain/combat.dart';
import '../../domain/engine.dart';
import '../../domain/game_data.dart';
import '../format.dart';
import '../game_controller.dart';
import '../resource_style.dart';
import '../theme.dart';
import '../visuals.dart';
import '../widgets/categorized_list.dart';
import '../widgets/in_progress_card.dart';
import '../widgets/info_button.dart';

/// Défenses constructibles au chantier.
class DefenseScreen extends StatelessWidget {
  const DefenseScreen({
    super.key,
    required this.controller,
    required this.now,
    required this.onOpenQueue,
  });

  final GameController controller;
  final DateTime now;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    final state = controller.interpolated(now);
    // Onglet Chantier (V3a) : défenses puis vaisseaux, catégories des deux familles.
    return CategorizedList<UnitKind>(
      header: Column(
        children: [
          DebrisCard(controller: controller, now: now),
          InProgressCard(
            controller: controller,
            slot: Slot.shipyard,
            now: now,
            onTap: onOpenQueue,
          ),
        ],
      ),
      categories: {...?data.categories['defense'], ...?data.categories['fleet']},
      items: [
        for (final k in UnitKind.values)
          if (data.unit(k).defense) k,
        for (final k in UnitKind.values)
          if (!data.unit(k).defense) k,
      ],
      categoryOf: (k) => data.unit(k).category,
      filter: RealizableFilter<UnitKind>(
        enabled: controller.realizableOnly('defense'),
        onChanged: (on) => controller.setRealizableOnly('defense', on),
        isRealizable: (k) => realizableUnit(state, k, controller.rules),
        waitFor: (k) => waitForUnit(state, k, controller.rules),
        nameOf: (k) => data.unit(k).name,
      ),
      itemBuilder: (context, k) => _UnitCard(controller: controller, unit: k, now: now),
    );
  }
}

/// Attaque, bouclier et coque avec icônes.
class UnitStatsLine extends StatelessWidget {
  const UnitStatsLine({super.key, required this.stats});

  final UnitStats stats;

  @override
  Widget build(BuildContext context) {
    final style = mono(Theme.of(context).textTheme.bodySmall);
    Widget part(IconData icon, double v) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 3),
        Text(fmtAmount(v), style: style),
      ],
    );
    return Wrap(
      spacing: 12,
      children: [
        part(Icons.gps_fixed, stats.attack),
        part(Icons.shield_outlined, stats.shield),
        part(Icons.favorite_border, stats.hull),
      ],
    );
  }
}

const statsHelp =
    'Cible : attaque par tir. Bouclier : absorbe les dégâts avant la coque, se régénère à '
    'chaque round ; un tir inférieur à 1 % du bouclier n’a aucun effet. Cœur : coque, '
    '(métal + cristal) ÷ 10. Les technos Armes, Bouclier et Protection ajoutent 10 % par '
    'niveau.';

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.controller, required this.unit, required this.now});

  final GameController controller;
  final UnitKind unit;
  final DateTime now;

  String get _helpText {
    final description = controller.data.unit(unit).description;
    return [if (description.isNotEmpty) description, statsHelp].join('\n\n');
  }

  String _requirements(GameState state, Map<Unlockable, int> items) => [
    for (final e in items.entries)
      '${controller.data.spec(e.key).name} ${e.value} (${state.levelOf(e.key)})',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rules = controller.rules;
    final state = controller.interpolated(now);
    final spec = controller.data.unit(unit);
    final owned = state.planet.count(unit);
    final block = checkBatchPlacement(state, unit, 1, rules);
    final locked = block is RequirementsNotMet;
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    final error = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _details(context),
        child: Opacity(
          opacity: locked ? 0.6 : 1,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    GameImage(
                      path: VisualsScope.of(context).unit(unit),
                      icon: ItemStyle.unitIcon,
                      width: 64,
                      radius: 10,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Marge à droite : place de l'icône (i), posée au-dessus.
                          Padding(
                            padding: const EdgeInsets.only(right: 36),
                            child: Text(spec.name, style: theme.textTheme.titleSmall),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('× ${fmtAmount(owned.toDouble())}', style: mono(secondary)),
                              UnitStatsLine(stats: UnitStats.of(spec, state.research)),
                              if (!spec.defense && spec.cargo > 0)
                                Text('Soute ${fmtAmount(spec.cargo)}', style: mono(secondary)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (block case RequirementsNotMet(:final missing))
                            Text('Requiert ${_requirements(state, missing)}', style: error)
                          else ...[
                            Wrap(
                              spacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                CostLine(cost: spec.baseCost, available: state.planet.resources),
                                Text(
                                  '${fmtDuration(unitDuration(state, unit, rules))} par unité',
                                  style: mono(secondary),
                                ),
                              ],
                            ),
                            if (_blockText(block) case final text?) Text(text, style: error),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Commander ${spec.name}',
                      onPressed: block == null ? () => _order(context) : null,
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(wouldQueue(state, Slot.shipyard) ? Icons.playlist_add : Icons.add),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 56,
                child: InfoButton(title: spec.name, body: _helpText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Feuille de détail : description, caractéristiques, prérequis complets.
  Future<void> _details(BuildContext context) {
    final state = controller.interpolated(now);
    final spec = controller.data.unit(unit);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        const gap = SizedBox(height: 8);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.name, style: theme.textTheme.titleLarge),
                gap,
                UnitStatsLine(stats: UnitStats.of(spec, state.research)),
                gap,
                Text(_helpText, style: theme.textTheme.bodyMedium),
                if (spec.requires.isNotEmpty) ...[
                  gap,
                  Text(
                    'Requiert ${_requirements(state, spec.requires)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String? _blockText(OrderBlock? block) => switch (block) {
    null || RequirementsNotMet() => null,
    QueueBusy() => 'Chantier occupé',
    QueueFull(:final capacity) => 'File du chantier pleine : $capacity lots',
    ShipyardBusy() => 'Impossible pendant l’agrandissement du chantier',
    MaxReached(:final max) => 'Maximum $max par planète',
    NotEnoughResources() => 'Ressources insuffisantes',
    LabBusy() || NotBuildable() => null,
  };

  Future<void> _order(BuildContext context) async {
    final state = controller.interpolated(now);
    final max = math.max(1, math.min(9999, maxOrderable(state, unit, controller.rules)));
    final count = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _QuantitySheet(controller: controller, unit: unit, max: max),
    );
    if (count == null) return;
    final reason = await controller.orderUnits(unit, count);
    if (reason != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Commande impossible')));
    }
  }
}

/// Choix de la quantité : curseur, raccourcis, coût et durée totaux.
class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({required this.controller, required this.unit, required this.max});

  final GameController controller;
  final UnitKind unit;
  final int max;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  var _count = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.controller;
    final spec = c.data.unit(widget.unit);
    final per = unitDuration(c.state, widget.unit, c.rules);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${spec.name} × $_count', style: theme.textTheme.titleMedium),
            if (widget.max > 1)
              Slider(
                value: _count.toDouble(),
                min: 1,
                max: widget.max.toDouble(),
                divisions: widget.max - 1,
                label: '$_count',
                onChanged: (v) => setState(() => _count = v.round()),
              ),
            Wrap(
              spacing: 8,
              children: [
                for (final n in {1, 10, 100, widget.max})
                  if (n <= widget.max)
                    ActionChip(
                      label: Text(n == widget.max ? 'Max ($n)' : '$n'),
                      onPressed: () => setState(() => _count = n),
                    ),
              ],
            ),
            const SizedBox(height: 12),
            CostLine(cost: spec.baseCost * _count.toDouble(), available: c.state.planet.resources),
            Text('Durée totale ${fmtDuration(per * _count)}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _count),
                child: Text(
                  wouldQueue(c.state, Slot.shipyard)
                      ? 'Ajouter $_count à la file'
                      : 'Construire $_count',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const debrisHelp =
    'Quand des vaisseaux sont détruits au-dessus de la planète, une partie de leur métal et '
    'de leur cristal reste en orbite : c’est le champ de débris. Les défenses n’en laissent '
    'pas.\n\nEnvoie des recycleurs pour le collecter : ils partent un moment, ne combattent '
    'pas pendant leur absence, et rapportent au plus leur soute.';

/// Champ de débris de la planète et mission de recyclage (spec 15). Rien s'il n'y a ni
/// débris ni mission.
class DebrisCard extends StatelessWidget {
  const DebrisCard({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final debris = state.planet.debris;
    final mission = currentRecycling(state);
    if (mission == null && debris.metal + debris.crystal < 1) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final recyclers = state.planet.count(UnitKind.recycler);
    final cargo = controller.data.unit(UnitKind.recycler).cargo;
    final total = debris.metal + debris.crystal;
    // Assez de recycleurs pour tout prendre, dans la limite de ceux présents.
    final needed = (total / cargo).ceil().clamp(1, 1 << 20);
    final send = recyclers < needed ? recyclers : needed;
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.blur_on, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Champ de débris', style: theme.textTheme.titleSmall)),
                  const InfoButton(title: 'Champ de débris', body: debrisHelp),
                ],
              ),
              CostLine(cost: debris),
              const SizedBox(height: 4),
              if (mission != null)
                Text(
                  '${mission.recyclers} recycleurs en route · retour dans '
                  '${fmtDuration(mission.dueAt.difference(now))}',
                  style: secondary,
                )
              else if (recyclers == 0)
                Text('Construis des recycleurs pour le collecter', style: secondary)
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: () => controller.recycle(send),
                      icon: const Icon(Icons.recycling),
                      label: Text('Envoyer $send recycleur${send > 1 ? 's' : ''}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
