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
    'Attaques : une à la fois. Expéditions : une à la fois, plus une par niveau d’Amiral. '
    'Recyclage, espionnage et mise à l’abri : sans limite.\n\n'
    'Plafond de vaisseaux par attaque, expédition ou escorte de recyclage : il augmente avec '
    'la technologie Informatique (jusqu’au niveau 10). Les sondes et les recycleurs ne '
    'comptent pas.';

const expeditionHelp =
    'Une expédition explore l’espace profond pendant la durée choisie. Au retour : '
    'ressources (dans la limite de la soute), vaisseaux trouvés, ou rien. Elle peut aussi '
    'tomber dans une embuscade pirate, revenir plus tôt ou plus tard, et, rarement, '
    'disparaître dans un trou noir avec toute la flotte.\n\n'
    'Plus l’exploration est longue, plus le butin est gros et moins on rentre bredouille.';

String missionName(MissionKind k) => switch (k) {
  MissionKind.attack => 'Attaque',
  MissionKind.spy => 'Espionnage',
  MissionKind.recycle => 'Recyclage',
  MissionKind.shelter => 'Mise à l’abri',
  MissionKind.expedition => 'Expédition',
};

String missionBlockText(MissionBlock b) => switch (b) {
  MissionBlock.noShips => 'Choisis au moins un vaisseau',
  MissionBlock.notEnoughShips => 'Vaisseaux indisponibles',
  MissionBlock.attackBusy => 'Une attaque est déjà en vol',
  MissionBlock.expeditionsFull => 'Toutes les places d’expédition sont occupées',
  MissionBlock.overCap => 'Trop de vaisseaux pour une mission (plafond de l’Informatique)',
  MissionBlock.noRecycler => 'Il faut au moins un recycleur',
  MissionBlock.noFuel => 'Pas assez de deutérium',
  MissionBlock.unavailable => 'Base détruite pour l’instant',
  MissionBlock.noDebris => 'Aucun débris à collecter',
  MissionBlock.noProbe => 'Seules les sondes espionnent',
};

String _units(Map<UnitKind, int> units, GameData data) => units.entries
    .where((e) => e.value > 0)
    .map((e) => '${fmtAmount(e.value.toDouble())} ${data.unit(e.key).name}')
    .join(' · ');

/// Onglet Flotte (spec 15) : état de la flotte, limites, missions en vol, mise à l'abri,
/// expédition, bases pirates.
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
    final cap = shipCap(state, data);
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    final hasShips = UnitKind.values.any((k) => !data.unit(k).defense && state.planet.count(k) > 0);
    return ListView(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + MediaQuery.paddingOf(context).bottom),
      children: [
        FleetStatusCard(controller: controller),
        Row(
          children: [
            Expanded(
              child: Text(
                'Attaques ${missionsOf(state, MissionKind.attack)} / ${data.fleet.attackSlots} · '
                'Expéditions ${missionsOf(state, MissionKind.expedition)} / '
                '${expeditionSlots(state, data)} · $cap vaisseaux par mission',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const InfoButton(title: 'Limites de la flotte', body: fleetHelp),
          ],
        ),
        for (final m in flying) _MissionCard(controller: controller, mission: m, now: now),
        Card(
          child: ListTile(
            leading: const Icon(Icons.travel_explore),
            title: const Text('Expédition dans l’espace profond'),
            subtitle: Text('Ressources, vaisseaux… ou embuscade', style: secondary),
            trailing: const Icon(Icons.chevron_right),
            enabled: hasShips,
            onTap: () => SendSheet.show(context, controller, MissionKind.expedition, null),
          ),
        ),
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

  /// Étapes de la mission et rang de l'étape en cours.
  (List<String>, int) get _steps {
    final m = mission;
    return switch (m.kind) {
      MissionKind.shelter => (const ['Absence'], 0),
      MissionKind.expedition => (
        const ['Aller', 'Exploration', 'Retour'],
        m.returning
            ? 2
            : m.exploring
            ? 1
            : 0,
      ),
      _ => (const ['Aller', 'Retour'], m.returning ? 1 : 0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final m = mission;
    final target = m.kind == MissionKind.expedition
        ? 'Espace profond'
        : m.target == null
        ? null
        : data.pirateBases.list[m.target!].name;
    final (steps, current) = _steps;
    final end = m.dueAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final small = theme.textTheme.bodySmall;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text([missionName(m.kind), ?target].join(' · '), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            // Étapes : passées en secondaire, en cours en couleur d'action, à venir en tertiaire.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (i, step) in steps.indexed) ...[
                  if (i > 0) const Icon(Icons.chevron_right, size: 16, color: Palette.textTertiary),
                  if (i < current) const Icon(Icons.check, size: 14, color: Palette.textSecondary),
                  Text(
                    step,
                    style: small?.copyWith(
                      color: i == current
                          ? Palette.action
                          : i < current
                          ? Palette.textSecondary
                          : Palette.textTertiary,
                      fontWeight: i == current ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4, right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: m.progress(now),
                  minHeight: 6,
                  color: Palette.action,
                  backgroundColor: Palette.inProgressTrack,
                  semanticsLabel: '${steps[current]} de la mission',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${steps[current]} · reste ${fmtDuration(m.dueAt.difference(now))}',
                      style: mono(small),
                    ),
                  ),
                  Text('Fin ${two(end.hour)}:${two(end.minute)}', style: mono(small)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(_units(m.ships, data), style: small),
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

/// Base pirate, en une ligne : nom, distance, état, débris, dernier espionnage. Le tap ouvre
/// le détail (rapport d'espionnage complet) et les actions.
class _BaseCard extends StatelessWidget {
  const _BaseCard({required this.controller, required this.base, required this.now});

  final GameController controller;
  final PirateBase base;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = controller.data.pirateBases.list[base.index];
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    final debris = base.debris.metal + base.debris.crystal;
    final spy = base.spy;
    final summary = [
      '${spec.systems} systèmes',
      if (!baseAvailable(base, now))
        'détruite, retour dans ${fmtDuration(base.destroyedUntil!.difference(now))}',
      if (debris >= 1) 'débris ${fmtAmount(debris)}',
      spy == null ? 'jamais espionnée' : 'espionnée il y a ${fmtDuration(now.difference(spy.at))}',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => ListenableBuilder(
            listenable: controller,
            builder: (sheet, _) => SafeArea(
              child: SingleChildScrollView(
                child: _BaseDetail(
                  controller: controller,
                  base: controller.state.bases[base.index],
                  now: controller.now(),
                ),
              ),
            ),
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spec.name, style: theme.textTheme.titleSmall),
                      Text(summary, style: secondary),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BaseDetail extends StatelessWidget {
  const _BaseDetail({required this.controller, required this.base, required this.now});

  final GameController controller;
  final PirateBase base;
  final DateTime now;

  /// Ferme la feuille de la base, puis ouvre la feuille d'envoi.
  void _send(BuildContext context, MissionKind kind) {
    final navigator = Navigator.of(context);
    final outer = navigator.context;
    navigator.pop();
    SendSheet.show(outer, controller, kind, base.index);
  }

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec.name, style: theme.textTheme.titleLarge),
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
                  onPressed: () => _send(context, MissionKind.spy),
                  child: const Text('Espionner'),
                ),
              if (hasDebris && recyclers > 0)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => _send(context, MissionKind.recycle),
                  child: const Text('Recycler'),
                ),
              if (available)
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => _send(context, MissionKind.attack),
                  child: const Text('Attaquer'),
                ),
            ],
          ),
        ],
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
  late double _explore = widget.controller.data.expedition.hours.first;

  List<UnitKind> get _available {
    final c = widget.controller;
    return [
      for (final k in UnitKind.values)
        if (!c.data.unit(k).defense &&
            c.state.planet.count(k) > 0 &&
            switch (widget.kind) {
              MissionKind.spy => k == UnitKind.espionageProbe,
              MissionKind.recycle ||
              MissionKind.attack ||
              MissionKind.expedition => k != UnitKind.espionageProbe,
              MissionKind.shelter => true,
            })
          k,
    ];
  }

  @override
  void initState() {
    super.initState();
    // Par défaut : tout ce qui convient à la mission, dans la limite du plafond ; un
    // recyclage part sans escorte.
    final c = widget.controller;
    var room = shipCap(c.state, c.data);
    for (final k in _available) {
      final have = c.state.planet.count(k);
      final free = k == UnitKind.espionageProbe || k == UnitKind.recycler;
      if (widget.kind == MissionKind.recycle && !free) {
        _ships[k] = 0;
      } else if (!isCapped(widget.kind) || free) {
        _ships[k] = have;
      } else {
        _ships[k] = have < room ? have : room;
        room -= _ships[k]!;
      }
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
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                if (widget.kind == MissionKind.expedition)
                  const InfoButton(title: 'Expédition', body: expeditionHelp),
              ],
            ),
            if (isCapped(widget.kind))
              Text(
                'Vaisseaux : ${cappedShips(_ships)} / ${shipCap(state, data)}'
                '${widget.kind == MissionKind.recycle ? ' (escorte ; recycleurs sans limite)' : ''}',
                style: mono(theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 8),
            // Tout ou rien en un tap ; par type : curseur 0 → max, − / + pour l'unité.
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Tout'),
                  onPressed: () => setState(() {
                    for (final k in _available) {
                      _ships[k] = state.planet.count(k);
                    }
                  }),
                ),
                ActionChip(
                  label: const Text('Aucun'),
                  onPressed: () => setState(() {
                    for (final k in _available) {
                      _ships[k] = 0;
                    }
                  }),
                ),
              ],
            ),
            for (final k in _available) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(data.unit(k).name)),
                  Text(
                    '${_ships[k] ?? 0} / ${state.planet.count(k)}',
                    style: mono(theme.textTheme.bodyMedium),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Moins de ${data.unit(k).name}',
                    onPressed: (_ships[k] ?? 0) > 0
                        ? () => setState(() => _ships[k] = (_ships[k] ?? 0) - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Slider(
                      value: (_ships[k] ?? 0).toDouble(),
                      max: state.planet.count(k).toDouble(),
                      divisions: state.planet.count(k),
                      label: '${_ships[k] ?? 0}',
                      semanticFormatterCallback: (v) => '${v.round()} ${data.unit(k).name}',
                      onChanged: (v) => setState(() => _ships[k] = v.round()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Plus de ${data.unit(k).name}',
                    onPressed: (_ships[k] ?? 0) < state.planet.count(k)
                        ? () => setState(() => _ships[k] = (_ships[k] ?? 0) + 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
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
              if (widget.kind == MissionKind.expedition) ...[
                Text('Durée d’exploration', style: theme.textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final h in data.expedition.hours)
                      ChoiceChip(
                        label: Text('${h.round()} h'),
                        selected: _explore == h,
                        onSelected: (_) => setState(() => _explore = h),
                      ),
                  ],
                ),
              ],
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
                  : widget.kind == MissionKind.expedition
                  ? 'Aller ${fmtDuration(preview.oneWay)} · exploration '
                        '${fmtDuration(Duration(milliseconds: (_explore * Duration.millisecondsPerHour / c.rules.speed).round()))}'
                        ' · retour ${fmtDuration(preview.oneWay)}'
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
                          exploreHours: _explore,
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

/// État de la flotte (spec 15) : par type de vaisseau, à quai et en vol. Seuls les types
/// possédés apparaissent.
class FleetStatusCard extends StatelessWidget {
  const FleetStatusCard({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final state = controller.state;
    final away = <UnitKind, int>{};
    for (final m in missions(state)) {
      for (final e in m.ships.entries) {
        away[e.key] = (away[e.key] ?? 0) + e.value;
      }
    }
    final kinds = [
      for (final k in UnitKind.values)
        if (!data.unit(k).defense && state.planet.count(k) + (away[k] ?? 0) > 0) k,
    ];
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ta flotte', style: theme.textTheme.titleSmall),
            if (kinds.isEmpty)
              Text('Aucun vaisseau : construis-en au chantier.', style: secondary)
            else ...[
              Text('À quai · en vol', style: secondary),
              const SizedBox(height: 4),
              for (final k in kinds)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(data.unit(k).name)),
                      Text(
                        fmtAmount(state.planet.count(k).toDouble()),
                        style: mono(theme.textTheme.bodyMedium),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          (away[k] ?? 0) > 0 ? '· ${fmtAmount(away[k]!.toDouble())} en vol' : '',
                          textAlign: TextAlign.right,
                          style: mono(secondary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
