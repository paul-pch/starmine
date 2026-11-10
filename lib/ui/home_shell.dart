import 'dart:async';

import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'notifications.dart';
import '../domain/combat.dart';
import '../domain/engine.dart';
import '../domain/resources.dart';
import 'format.dart';
import 'resource_style.dart';
import 'theme.dart';
import 'visuals.dart';
import 'screens/debug_screen.dart';
import 'screens/fleet_screen.dart';
import 'screens/officers_screen.dart';
import 'screens/reports_screen.dart';
import 'widgets/combat_report.dart';
import 'widgets/event_popover.dart';
import 'widgets/planet_hero.dart';
import 'widgets/raid_banner.dart';
import 'widgets/story_banner.dart';
import '../domain/story.dart';
import 'screens/defense_screen.dart';
import 'screens/items_screen.dart';
import 'screens/queue_screen.dart';
import 'widgets/resource_bar.dart';

/// Écran principal : barre de ressources collée en haut, hero qui défile avec le contenu,
/// bandeau de raid, onglet courant, navigation.
/// Une horloge d'affichage (1 s) interpole les stocks sans rien écrire ; quand une
/// échéance est passée, elle déclenche un rattrapage réel via le contrôleur.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller, this.visuals = const Visuals()});

  final GameController controller;
  final Visuals visuals;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late DateTime _now;
  late final Timer _ticker;
  late final AppLifecycleListener _lifecycle;
  static const _queueTab = 3;
  var _tab = 0;
  var _refreshing = false;

  /// Dernier rapport signalé à l'écran (pour n'afficher que les nouveaux).
  int? _lastReportId;

  /// Annulations de file et événements déjà signalés.
  var _queueCancelledSeen = 0;
  var _storySeen = 0;

  GameController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _now = _c.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _lastReportId = _c.reports.firstOrNull?.id;
    _queueCancelledSeen = _c.queueCancelledCount;
    _storySeen = _c.storyCount;
    _c.addListener(_onChange);
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(_c.onHidden()),
      onShow: () => unawaited(_c.onVisible()),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    _lifecycle.dispose();
    _c.removeListener(_onChange);
    super.dispose();
  }

  void _tick() {
    setState(() => _now = _c.now());
    // Une échéance passée (construction ou recherche) : rattrapage réel.
    // Une échéance passée ou un effet d'événement terminé : rattrapage réel.
    final s = _c.state;
    if (s.pending.any((e) => !e.dueAt.isAfter(_now)) ||
        s.effects.any((e) => !e.endsAt.isAfter(_now)) ||
        _c.storyServable(_now)) {
      _refresh();
    }
  }

  /// Popovers en attente : affichées une à une, dans l'ordre d'arrivée.
  final _popovers = <EventPopover Function()>[];
  var _popoverOpen = false;

  void _enqueue(EventPopover Function() build) {
    _popovers.add(build);
    unawaited(_showPopovers());
  }

  Future<void> _showPopovers() async {
    if (_popoverOpen) return;
    _popoverOpen = true;
    while (_popovers.isNotEmpty && mounted) {
      await EventPopover.show(context, _popovers.removeAt(0)());
    }
    _popoverOpen = false;
  }

  /// Raid résolu pendant que l'app est ouverte : popover avec accès au rapport.
  void _onChange() {
    _onQueueCancelled();
    _onStory();
    final latest = _c.reports.firstOrNull;
    if (latest == null || latest.id == _lastReportId) return;
    _lastReportId = latest.id;
    if (!mounted) return;
    final r = latest.report;
    final good = r.baseName == null
        ? r.winner != CombatWinner.attacker
        : r.winner == CombatWinner.attacker;
    _enqueue(
      () => EventPopover(
        icon: r.baseName != null
            ? Icons.rocket_launch_outlined
            : good
            ? Icons.gpp_good_outlined
            : Icons.gpp_bad_outlined,
        iconColor: good ? null : Theme.of(context).colorScheme.error,
        title: CombatReport.verdict(r),
        lines: [if (r.loot != Resources.zero) 'Pillage : ${fmtCost(r.loot)}'],
        actions: [
          const PopoverAction('Fermer', null),
          PopoverAction('Rapport', primary: true, () {
            unawaited(_c.markReportSeen(latest.id));
            unawaited(CombatReport.show(context, _c.data, r));
          }),
        ],
      ),
    );
  }

  /// File annulée pendant que l'app est ouverte (spec 13) : popover.
  void _onQueueCancelled() {
    final cancelled = _c.lastQueueCancelled;
    if (_c.queueCancelledCount == _queueCancelledSeen || cancelled == null || !mounted) return;
    _queueCancelledSeen = _c.queueCancelledCount;
    final (title, body) = queueCancelledText(cancelled, _c.data);
    _enqueue(
      () => EventPopover(
        icon: Icons.playlist_remove,
        iconColor: Theme.of(context).colorScheme.error,
        title: title,
        body: body,
      ),
    );
  }

  /// Événement ponctuel survenu app ouverte (spec 14) : popover avec le texte d'histoire et
  /// les effets ; une décision montre ses options directement.
  void _onStory() {
    final o = _c.lastStory;
    if (_c.storyCount == _storySeen || o == null || !mounted) return;
    _storySeen = _c.storyCount;
    if (o.kind == StoryOutcomeKind.answered) return;
    final spec = _c.data.story.catalog[o.key];
    if (spec == null) return;
    _enqueue(() {
      // Décision : options seulement si elle attend toujours (sinon déjà tranchée).
      final awaiting = o.kind == StoryOutcomeKind.awaiting && _c.pendingChoice?.key == spec.key;
      final (title, body) = storyText(o, _c.data);
      return EventPopover(
        icon: awaiting ? Icons.help_outline : Icons.auto_stories_outlined,
        title: awaiting ? spec.name : title,
        body: spec.description,
        lines: [
          if (o.kind == StoryOutcomeKind.happened)
            for (final e in spec.effects) storyEffectText(_c.data, e),
          if (o.kind == StoryOutcomeKind.happened && o.won != null)
            o.won! ? 'Pari réussi' : 'Pari raté',
          if (o.kind == StoryOutcomeKind.defaulted) body,
        ],
        image: widget.visuals.withAmbiance(_c.ambiance).story(spec.key),
        content: awaiting
            ? Builder(
                builder: (popover) => ChoiceOptions(
                  controller: _c,
                  spec: spec,
                  onAnswered: () => Navigator.pop(popover),
                ),
              )
            : null,
        actions: [PopoverAction(awaiting ? 'Plus tard' : 'Fermer', null)],
      );
    });
  }

  Future<void> _openReports() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ReportsScreen(controller: _c)));
    await _c.markReportsSeen();
  }

  Future<void> _openOfficers() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => OfficersScreen(controller: _c)));

  Future<void> _openDebug() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Debug')),
        body: ListenableBuilder(
          listenable: _c,
          builder: (_, _) => DebugScreen(controller: _c),
        ),
      ),
    ),
  );

  void _refresh() {
    if (_refreshing) return;
    _refreshing = true;
    unawaited(_c.refresh().whenComplete(() => _refreshing = false));
  }

  void _openQueue() => setState(() => _tab = _queueTab);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final state = _c.state;
        final pages = [
          BuildingsScreen(controller: _c, now: _now, onOpenQueue: _openQueue),
          ResearchScreen(controller: _c, now: _now, onOpenQueue: _openQueue),
          DefenseScreen(controller: _c, now: _now, onOpenQueue: _openQueue),
          QueueScreen(controller: _c, now: _now),
          FleetScreen(controller: _c, now: _now),
        ];
        return Scaffold(
          body: VisualsScope(
            visuals: widget.visuals.withAmbiance(_c.ambiance),
            child: Column(
              children: [
                ResourceBar(controller: _c, now: _now),
                const Divider(height: 1),
                Expanded(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(
                        child: PlanetHero(
                          controller: _c,
                          onReports: _openReports,
                          onOfficers: _openOfficers,
                          onDebug: _openDebug,
                        ),
                      ),
                    ],
                    body: Column(
                      children: [
                        if (_c.incomingRaid case final raid?)
                          RaidBanner(controller: _c, raid: raid, now: _now),
                        StoryBanner(controller: _c, now: _now),
                        Expanded(child: pages[_tab]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              // Pastille verte : file libre. Rouge : bloquée par un agrandissement.
              NavigationDestination(
                icon: _SlotBadge(
                  status: slotStatus(state, Slot.construction),
                  child: const Icon(Icons.factory_outlined),
                ),
                label: 'Bâtiments',
              ),
              NavigationDestination(
                icon: _SlotBadge(
                  status: slotStatus(state, Slot.research),
                  child: const Icon(ResourceStyle.researchIcon),
                ),
                label: 'Recherche',
              ),
              NavigationDestination(
                icon: _SlotBadge(
                  status: slotStatus(state, Slot.shipyard),
                  child: const Icon(Icons.rocket_launch_outlined),
                ),
                label: 'Chantier',
              ),
              const NavigationDestination(icon: Icon(Icons.schedule_outlined), label: 'File'),
              const NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Flotte'),
            ],
          ),
        );
      },
    );
  }
}

/// Pastille d'onglet : verte si la file est libre, rouge si elle est bloquée.
class _SlotBadge extends StatelessWidget {
  const _SlotBadge({required this.status, required this.child});

  final SlotStatus status;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: status == SlotStatus.free || status == SlotStatus.blocked,
      smallSize: 7,
      backgroundColor: status == SlotStatus.blocked
          ? Theme.of(context).colorScheme.error
          : Palette.free,
      child: child,
    );
  }
}
