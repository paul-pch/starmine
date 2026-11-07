import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/engine.dart';
import '../../domain/events.dart';
import '../../domain/game_data.dart';
import '../../domain/resources.dart';
import '../../domain/tech_tree.dart';
import '../format.dart';
import '../game_controller.dart';
import '../resource_style.dart';
import '../theme.dart';
import '../visuals.dart';
import 'info_button.dart';

/// Ce qu'on sait d'un élément à [now] : partagé par la carte et sa feuille de détail.
class ItemFacts {
  ItemFacts(this.controller, this.item, DateTime now) : state = controller.interpolated(now);

  final GameController controller;
  final Unlockable item;
  final GameState state;

  int get level => state.levelOf(item);

  /// Slot de l'élément ; un ordre placé maintenant irait dans la file d'attente.
  Slot get slot => item is BuildingKind ? Slot.construction : Slot.research;
  bool get queues => wouldQueue(state, slot);

  /// Niveau de départ de l'ordre : actuel, ou prévu après la file (spec 13).
  int get startLevel => queues ? projectedLevel(state, item) : level;
  Resources get cost => controller.rules.cost(item, startLevel + 1);
  Duration get duration => orderDuration(state, item, controller.rules, level: startLevel);
  OrderBlock? get block => checkPlacement(state, item, controller.rules);

  /// Libellé de l'action ; aussi le libellé accessible du bouton de la carte.
  String get verb => queues
      ? 'Ajouter à la file'
      : switch (item) {
          TechKind() => 'Rechercher',
          BuildingKind() => level == 0 ? 'Construire' : 'Améliorer',
        };

  /// Réglage de production du bâtiment, 100 pour une techno.
  int get percent => switch (item) {
    final BuildingKind kind => state.planet.percent(kind),
    TechKind() => 100,
  };

  String requirements(Map<Unlockable, int> items) => [
    for (final e in items.entries)
      '${controller.data.spec(e.key).name} ${e.value} (${state.levelOf(e.key)})',
  ].join(' · ');

  String? blockText() => switch (block) {
    null || RequirementsNotMet() => null,
    QueueBusy(current: final OrderDone current) =>
      'File occupée : ${controller.data.spec(current.item).name} ${current.targetLevel}',
    QueueBusy() => 'File occupée',
    QueueFull(:final capacity) => 'File pleine : $capacity ordres',
    ShipyardBusy() => 'Impossible pendant une production du chantier',
    MaxReached() || NotBuildable() => null,
    LabBusy() => switch (item) {
      BuildingKind() => 'Impossible pendant une recherche',
      TechKind() => 'Impossible pendant l’agrandissement du labo',
    },
    NotEnoughResources(:final missing) => _missingHint(missing),
  };

  /// « Manque 120 M · dans 14 min », ou capacité insuffisante.
  String _missingHint(Resources missing) {
    final rules = controller.rules;
    final rate = controller.hourlyRate(state);
    final cap = rules.capacity(state.planet.levels);
    var hours = 0.0;
    for (final k in ResourceKind.values) {
      if (missing[k] <= 0) continue;
      if (cost[k] > cap[k]) return 'Manque ${fmtCost(missing)} · capacité insuffisante';
      if (rate[k] <= 0) return 'Manque ${fmtCost(missing)}';
      hours = math.max(hours, missing[k] / rate[k]);
    }
    return 'Manque ${fmtCost(missing)} · dans ${fmtDuration(Duration(seconds: (hours * 3600).ceil()))}';
  }

  /// Gain apporté par le niveau suivant, en clair.
  String effect() {
    final rules = controller.rules;
    final data = controller.data;
    final next = switch (item) {
      BuildingKind() => state.copyWith(
        planet: state.planet.withLevel(item as BuildingKind, state.levelOf(item) + 1),
      ),
      TechKind() => state.copyWith(
        research: {...state.research, item as TechKind: state.levelOf(item) + 1},
      ),
    };
    final before = controller.hourlyRate(state);
    final after = controller.hourlyRate(next);
    final eBefore = controller.energyOf(state);
    final eAfter = controller.energyOf(next);

    final parts = <String>[];
    for (final k in ResourceKind.values) {
      final d = after[k] - before[k];
      if (d.abs() >= 1) {
        parts.add('${d > 0 ? '+' : '−'}${fmtAmount(d.abs())} ${resourceName(k).toLowerCase()}/h');
      }
    }
    final dProduced = eAfter.produced - eBefore.produced;
    final dConsumed = eAfter.consumed - eBefore.consumed;
    if (dProduced >= 1) parts.add('+${fmtAmount(dProduced)} énergie');
    if (dConsumed >= 1) parts.add('−${fmtAmount(dConsumed)} énergie');

    switch (item) {
      case BuildingKind.metalStorage || BuildingKind.crystalStorage || BuildingKind.deuteriumTank:
        final l = state.levelOf(item);
        parts.add(
          'Capacité ${fmtAmount(rules.storageCapacity(l))} → ${fmtAmount(rules.storageCapacity(l + 1))}',
        );
      case BuildingKind.roboticsFactory:
        final r = state.levelOf(item);
        parts.add('Constructions −${((1 - (1 + r) / (2 + r)) * 100).round()} %');
      case BuildingKind.naniteFactory:
        parts.add('Constructions −50 %');
      case BuildingKind.researchLab:
        final l = state.levelOf(item);
        parts.add('Recherches −${((1 - (1 + l) / (2 + l)) * 100).round()} %');
      case TechKind():
        final bonus = data.tech(item as TechKind).productionBonus;
        if (bonus != Resources.zero && parts.isEmpty) parts.add('Bonus de production des mines');
      default:
        break;
    }
    return parts.join(' · ');
  }
}

/// Lance le niveau suivant ; un refus s'affiche en message sur [context].
Future<void> _order(BuildContext context, GameController controller, Unlockable item) async {
  final reason = await controller.order(item);
  if (reason == null || !context.mounted) return;
  final text = switch (reason) {
    QueueBusy() => 'La file est occupée',
    QueueFull(:final capacity) => 'La file est pleine ($capacity ordres)',
    LabBusy() => 'Le laboratoire est occupé',
    ShipyardBusy() => 'Le chantier est occupé',
    MaxReached() || NotBuildable() => 'Impossible',
    RequirementsNotMet() => 'Prérequis manquants',
    NotEnoughResources(:final missing) => 'Il manque ${fmtCost(missing)}',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

/// Carte d'un bâtiment ou d'une technologie : l'essentiel pour décider. Le tap ouvre la
/// feuille de détail (description, débloque, prérequis, réglage de production).
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.controller, required this.item, required this.now});

  final GameController controller;
  final Unlockable item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = ItemFacts(controller, item, now);
    final spec = controller.data.spec(item);
    final block = facts.block;
    final locked = block is RequirementsNotMet;
    final effect = facts.effect();
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    final error = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error);
    final level = facts.level;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ItemDetailSheet.show(context, controller, item),
        child: Opacity(
          opacity: locked ? 0.6 : 1,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    GameImage(
                      path: VisualsScope.of(context).unlockable(item, level),
                      icon: ItemStyle.icon(item),
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
                            child: Row(
                              children: [
                                Flexible(child: Text(spec.name, style: theme.textTheme.titleSmall)),
                                if (item case final TechKind tech)
                                  _TierLabel(tier: controller.data.tier(tech)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                effect.isEmpty ? 'Niv. $level' : 'Niv. $level · $effect',
                                style: secondary,
                              ),
                              if (facts.percent < 100) _PercentChip(percent: facts.percent),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (block case RequirementsNotMet(:final missing))
                            Text('Requiert ${facts.requirements(missing)}', style: error)
                          else ...[
                            Wrap(
                              spacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                CostLine(cost: facts.cost, available: facts.state.planet.resources),
                                Text(fmtDuration(facts.duration), style: mono(secondary)),
                              ],
                            ),
                            if (facts.blockText() case final text?) Text(text, style: error),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: '${facts.verb} ${spec.name}',
                      onPressed: block == null ? () => _order(context, controller, item) : null,
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(facts.queues ? Icons.playlist_add : Icons.arrow_upward),
                    ),
                  ],
                ),
              ),
              if (spec.description.isNotEmpty)
                Positioned(
                  top: 0,
                  right: 56,
                  child: InfoButton(title: spec.name, body: spec.description),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Puce « Production X % » : réglage inférieur à 100 %.
class _PercentChip extends StatelessWidget {
  const _PercentChip({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Production $percent %',
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
      ),
    );
  }
}

/// Feuille de détail : tout ce que la carte ne montre pas. Suit l'état du jeu tant qu'elle
/// est ouverte (réglage de production).
abstract final class ItemDetailSheet {
  static Future<void> show(BuildContext context, GameController controller, Unlockable item) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheet) => ListenableBuilder(
          listenable: controller,
          builder: (_, _) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _ItemDetail(
                controller: controller,
                item: item,
                onOrder: () {
                  Navigator.pop(sheet);
                  unawaited(_order(context, controller, item));
                },
              ),
            ),
          ),
        ),
      );
}

class _ItemDetail extends StatelessWidget {
  const _ItemDetail({required this.controller, required this.item, required this.onOrder});

  final GameController controller;
  final Unlockable item;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = ItemFacts(controller, item, controller.now());
    final spec = controller.data.spec(item);
    final block = facts.block;
    final locked = block is RequirementsNotMet;
    final effect = facts.effect();
    final unlocks = controller.data.unlockedBy(item);
    final body = theme.textTheme.bodyMedium;
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    final error = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error);
    const gap = SizedBox(height: 8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(spec.name, style: theme.textTheme.titleLarge)),
            Text('Niv. ${facts.level}', style: mono(theme.textTheme.titleSmall)),
          ],
        ),
        if (spec.description.isNotEmpty) ...[gap, Text(spec.description, style: body)],
        if (effect.isNotEmpty) ...[gap, Text('Niveau suivant : $effect', style: body)],
        gap,
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CostLine(cost: facts.cost, available: facts.state.planet.resources),
            Text(fmtDuration(facts.duration), style: mono(secondary)),
          ],
        ),
        if (facts.blockText() case final text?) Text(text, style: error),
        if (spec.requires.isNotEmpty) ...[
          gap,
          Text('Requiert ${facts.requirements(spec.requires)}', style: locked ? error : secondary),
        ],
        if (unlocks.isNotEmpty) ...[
          gap,
          Text('Débloque ${unlocks.map((u) => u.name).join(' · ')}', style: secondary),
        ],
        if (item case final BuildingKind kind
            when controller.data[kind].adjustable && facts.level > 0)
          _PercentRow(controller: controller, kind: kind),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: block == null ? onOrder : null, child: Text(facts.verb)),
        ),
      ],
    );
  }
}

/// Réglage de production 0 à 100 %, pas de 10.
class _PercentRow extends StatelessWidget {
  const _PercentRow({required this.controller, required this.kind});

  final GameController controller;
  final BuildingKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = controller.state.planet.percent(kind);
    return Row(
      children: [
        Text('Production', style: theme.textTheme.bodySmall),
        const InfoButton(
          title: 'Réglage de production',
          body:
              'Réduit la production et, dans la même proportion, la consommation d’énergie '
              'ou de deutérium du bâtiment. Utile pour libérer de l’énergie ou économiser du '
              'deutérium.',
          size: 16,
        ),
        const Spacer(),
        DropdownButton<int>(
          value: percent,
          isDense: true,
          underline: const SizedBox.shrink(),
          items: [
            for (var p = 100; p >= 0; p -= 10) DropdownMenuItem(value: p, child: Text('$p %')),
          ],
          onChanged: (p) {
            if (p != null && p != percent) controller.setPercent(kind, p);
          },
        ),
      ],
    );
  }
}

/// Étiquette « Palier N » ; au tap, explique la notion de palier.
class _TierLabel extends StatelessWidget {
  const _TierLabel({required this.tier});

  final int tier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => InfoButton.show(
          context,
          title: 'Paliers de recherche',
          body:
              'Le palier est la profondeur d’une technologie dans l’arbre : une techno de '
              'palier 3 demande au moins une techno de palier 2, et ainsi de suite. '
              '« Requiert » indique ce qui manque, « Débloque » ce que la techno ouvre ensuite.',
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Palier $tier',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
