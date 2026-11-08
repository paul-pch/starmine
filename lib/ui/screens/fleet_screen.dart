import 'package:flutter/material.dart';

import '../../domain/events.dart';
import '../../domain/fleet.dart';
import '../../domain/game_data.dart';
import '../../domain/resources.dart';
import '../format.dart';
import '../game_controller.dart';
import '../resource_style.dart';
import '../theme.dart';
import '../widgets/info_button.dart';

const fleetHelp =
    'Envoie tes vaisseaux attaquer les bases pirates : le butin et les débris deviennent un '
    'revenu. Espionne d’abord avec des sondes pour connaître leur force.\n\n'
    'Un trajet dure selon la distance et le vaisseau le plus lent ; plus lent, il consomme '
    'moins de deutérium (payé au départ, aller et retour). Une flotte en vol ne défend pas la '
    'planète : la mise à l’abri l’éloigne pendant un raid.\n\n'
    'Places de flotte : une, plus une par niveau de la technologie Informatique.';

String missionName(MissionKind k) => switch (k) {
  MissionKind.attack => 'Attaque',
  MissionKind.spy => 'Espionnage',
  MissionKind.recycle => 'Recyclage',
  MissionKind.shelter => 'Mise à l’abri',
};

String missionBlockText(MissionBlock b) => switch (b) {
  MissionBlock.noShips => 'Choisis au moins un vaisseau',
  MissionBlock.notEnoughShips => 'Vaisseaux indisponibles',
  MissionBlock.noSlot => 'Plus de place de flotte',
  MissionBlock.noFuel => 'Pas assez de deutérium',
  MissionBlock.unavailable => 'Base détruite pour l’instant',
  MissionBlock.noDebris => 'Aucun débris à collecter',
  MissionBlock.noProbe => 'Seules les sondes espionnent',
};

String _units(Map<UnitKind, int> units, GameData data) => units.entries
    .where((e) => e.value > 0)
    .map((e) => '${fmtAmount(e.value.toDouble())} ${data.unit(e.key).name}')
    .join(' · ');

/// Onglet Flotte (spec 15) : places, missions en vol, mise à l'abri, bases pirates.
class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = controller.state;
    final data = controller.data;
    final flying = missions(state);
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    final hasShips = UnitKind.values.any((k) => !data.unit(k).defense && state.planet.count(k) > 0);
    return ListView(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + MediaQuery.paddingOf(context).bottom),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Places de flotte : ${flying.length} / ${fleetSlots(state, data)}',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const InfoButton(title: 'Flotte', body: fleetHelp),
          ],
        ),
        for (final m in flying) _MissionCard(controller: controller, mission: m, now: now),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shield_moon_outlined),
            title: const Text('Mettre la flotte à l’abri'),
            subtitle: Text('Éloigne tes vaisseaux pendant un raid', style: secondary),
            trailing: const Icon(Icons.chevron_right),
            enabled: hasShips,
            onTap: () => SendSheet.show(context, controller, MissionKind.shelter, null),
          ),
        ),
        const SizedBox(height: 8),
        Text('Bases pirates', style: theme.textTheme.titleSmall),
        for (final b in state.bases) _BaseCard(controller: controller, base: b, now: now),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.controller, required this.mission, required this.now});

  final GameController controller;
  final FleetMission mission;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final m = mission;
    final target = m.target == null ? null : data.pirateBases.list[m.target!].name;
    final left = fmtDuration(m.dueAt.difference(now));
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text([missionName(m.kind), ?target].join(' · '), style: theme.textTheme.titleSmall),
            Text(
              m.returning ? 'Retour dans $left' : 'Arrivée dans $left',
              style: mono(theme.textTheme.bodySmall),
            ),
            Text(_units(m.ships, data), style: theme.textTheme.bodySmall),
            if (m.cargo != Resources.zero) CostLine(cost: m.cargo),
            if (!m.returning)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => controller.recall(m.id),
                  icon: const Icon(Icons.undo),
                  label: const Text('Rappeler'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({required this.controller, required this.base, required this.now});

  final GameController controller;
  final PirateBase base;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final state = controller.state;
    final spec = data.pirateBases.list[base.index];
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    final available = baseAvailable(base, now);
    final spy = base.spy;
    final probes = state.planet.count(UnitKind.espionageProbe);
    final recyclers = state.planet.count(UnitKind.recycler);
    final hasDebris = base.debris.metal + base.debris.crystal >= 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(spec.name, style: theme.textTheme.titleSmall),
            Text('À ${spec.systems} systèmes', style: secondary),
            if (!available)
              Text(
                'Détruite · nouvelle base dans '
                '${fmtDuration(base.destroyedUntil!.difference(now))}',
                style: secondary,
              ),
            if (hasDebris) ...[
              const SizedBox(height: 4),
              Text('Champ de débris', style: theme.textTheme.labelMedium),
              CostLine(cost: base.debris),
            ],
            if (spy != null) ...[
              const SizedBox(height: 4),
              Text(
                'Espionnée il y a ${fmtDuration(now.difference(spy.at))}',
                style: theme.textTheme.labelMedium,
              ),
              if (spy.resources case final r?) CostLine(cost: r),
              if (spy.ships case final u?)
                Text(u.isEmpty ? 'Aucun vaisseau' : _units(u, data), style: secondary),
              if (spy.defenses case final u?)
                Text(u.isEmpty ? 'Aucune défense' : _units(u, data), style: secondary),
              if (spy.ships == null) Text('Flotte inconnue (Espionnage 2)', style: secondary),
            ],
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                if (probes > 0 && available)
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: () =>
                        SendSheet.show(context, controller, MissionKind.spy, base.index),
                    child: const Text('Espionner'),
                  ),
                if (hasDebris && recyclers > 0)
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: () =>
                        SendSheet.show(context, controller, MissionKind.recycle, base.index),
                    child: const Text('Recycler'),
                  ),
                if (available)
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: () =>
                        SendSheet.show(context, controller, MissionKind.attack, base.index),
                    child: const Text('Attaquer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille d'envoi : vaisseaux, vitesse (ou durée d'abri), durée, carburant, soute.
class SendSheet extends StatefulWidget {
  const SendSheet({super.key, required this.controller, required this.kind, required this.target});

  final GameController controller;
  final MissionKind kind;
  final int? target;

  static Future<void> show(
    BuildContext context,
    GameController controller,
    MissionKind kind,
    int? target,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SendSheet(controller: controller, kind: kind, target: target),
  );

  @override
  State<SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<SendSheet> {
  final _ships = <UnitKind, int>{};
  var _speed = 100;
  late double _hours = widget.controller.data.fleet.shelterHours.first;

  List<UnitKind> get _available {
    final c = widget.controller;
    return [
      for (final k in UnitKind.values)
        if (!c.data.unit(k).defense &&
            c.state.planet.count(k) > 0 &&
            switch (widget.kind) {
              MissionKind.spy => k == UnitKind.espionageProbe,
              MissionKind.recycle => k == UnitKind.recycler,
              MissionKind.attack => k != UnitKind.espionageProbe,
              MissionKind.shelter => true,
            })
          k,
    ];
  }

  @override
  void initState() {
    super.initState();
    // Par défaut : tout ce qui convient à la mission.
    for (final k in _available) {
      _ships[k] = widget.controller.state.planet.count(k);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.controller;
    final data = c.data;
    final state = c.state;
    final shelter = widget.kind == MissionKind.shelter;
    final preview = missionPreview(state, widget.kind, widget.target, _ships, _speed, c.rules);
    final block = checkMission(state, widget.kind, widget.target, _ships, _speed, c.now(), c.rules);
    final title = [
      missionName(widget.kind),
      if (widget.target case final t?) data.pirateBases.list[t].name,
    ].join(' · ');
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final k in _available)
              Row(
                children: [
                  Expanded(child: Text(data.unit(k).name)),
                  IconButton(
                    tooltip: 'Moins',
                    onPressed: (_ships[k] ?? 0) > 0
                        ? () => setState(() => _ships[k] = (_ships[k] ?? 0) - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      '${_ships[k] ?? 0} / ${state.planet.count(k)}',
                      textAlign: TextAlign.center,
                      style: mono(theme.textTheme.bodyMedium),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Plus',
                    onPressed: (_ships[k] ?? 0) < state.planet.count(k)
                        ? () => setState(() => _ships[k] = (_ships[k] ?? 0) + 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (shelter) ...[
              Text('Durée d’absence', style: theme.textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final h in data.fleet.shelterHours)
                    ChoiceChip(
                      label: Text('${h.round()} h'),
                      selected: _hours == h,
                      onSelected: (_) => setState(() => _hours = h),
                    ),
                ],
              ),
            ] else ...[
              Text('Vitesse : $_speed %', style: theme.textTheme.titleSmall),
              Slider(
                value: _speed.toDouble(),
                min: 10,
                max: 100,
                divisions: 9,
                label: '$_speed %',
                onChanged: (v) => setState(() => _speed = v.round()),
              ),
            ],
            Text(
              shelter
                  ? 'Absence ${fmtDuration(Duration(milliseconds: (_hours * Duration.millisecondsPerHour / c.rules.speed).round()))}'
                  : 'Aller ${fmtDuration(preview.oneWay)} · retour ${fmtDuration(preview.oneWay)}',
              style: mono(theme.textTheme.bodySmall),
            ),
            CostLine(
              cost: Resources(deuterium: preview.fuel),
              available: state.planet.resources,
            ),
            if (widget.kind != MissionKind.spy)
              Text('Soute ${fmtAmount(preview.cargo)}', style: theme.textTheme.bodySmall),
            if (block != null)
              Text(
                missionBlockText(block),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: block != null
                    ? null
                    : () {
                        Navigator.pop(context);
                        c.sendMission(
                          widget.kind,
                          widget.target,
                          Map.of(_ships),
                          speedPercent: _speed,
                          shelterHours: _hours,
                        );
                      },
                child: const Text('Envoyer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
