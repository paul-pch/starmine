import 'dart:async';

import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'notifications.dart';
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
    final good = CombatReport.good(r);
    _enqueue(
      () => EventPopover(
        icon: CombatReport.icon(r),
        iconColor: good ? null : Theme.of(context).colorScheme.error,
        title: CombatReport.verdict(r),
        lines: [
          if (r.loot != Resources.zero)
            '${r.expedition == null && r.baseName == null ? 'Pillage' : 'Butin'} : '
                '${fmtCost(r.loot)}',
          for (final e in r.found.entries) '+${e.value} ${_c.data.unit(e.key).name}',
        ],
        image: widget.visuals.withAmbiance(_c.ambiance).combat(r),
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
    final spec = _c.data.story.catalog[o.key];
    if (spec == null) return;
    _enqueue(() {
      // Décision : options seulement si elle attend toujours (sinon déjà tranchée).
      final awaiting = o.kind == StoryOutcomeKind.awaiting && _c.pendingChoice?.key == spec.key;
      final (title, _) = storyText(o, _c.data);
      final scheme = Theme.of(context).colorScheme;
      return EventPopover(
        icon: switch (o.won) {
          _ when awaiting => Icons.help_outline,
          true => Icons.check_circle_outline,
          false => Icons.cancel_outlined,
          null => Icons.auto_stories_outlined,
        },
        iconColor: switch (o.won) {
          true => Palette.free,
          false => scheme.error,
          null => null,
        },
        title: switch (o.won) {
          _ when awaiting => spec.name,
          true => '${spec.name} : pari réussi',
          false => '${spec.name} : pari raté',
          null => title,
        },
        // Réponse : le texte d'histoire vient d'être lu, on montre l'issue seulement.
        body: o.kind == StoryOutcomeKind.answered ? '' : spec.description,
        lines: storyOutcomeLines(_c.data, spec, o, verdict: false),
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
        final visuals = widget.visuals.withAmbiance(_c.ambiance);
        // Ambiance Immersive (spec 10) : fond plein écran, barre et contenu sur des panneaux.
        final immersive = visuals.immersive;
        final content = Column(
          children: [
            if (_c.incomingRaid case final raid?) RaidBanner(controller: _c, raid: raid, now: _now),
            StoryBanner(controller: _c, now: _now),
            Expanded(child: pages[_tab]),
          ],
        );
        final column = Column(
          children: [
            if (immersive)
              SafeArea(
                bottom: false,
                child: _Panel(
                  color: Palette.panel,
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  radius: BorderRadius.circular(12),
                  child: ResourceBar(controller: _c, now: _now, color: Colors.transparent),
                ),
              )
            else ...[
              ResourceBar(controller: _c, now: _now),
              const Divider(height: 1),
            ],
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
                body: immersive
                    ? _Panel(
                        color: Palette.panelStrong,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        radius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: content,
                      )
                    : content,
              ),
            ),
          ],
        );
        return Scaffold(
          body: VisualsScope(
            visuals: visuals,
            child: immersive
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: _Background(path: visuals.background(state.planet.tempMax)),
                      ),
                      column,
                    ],
                  )
                : column,
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

/// Panneau opaque posé sur le fond de l'ambiance Immersive.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.color,
    required this.margin,
    required this.radius,
    required this.child,
  });

  final Color color;
  final EdgeInsets margin;
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: Palette.panelLine),
      ),
      child: child,
    );
  }
}

/// Fond plein écran de l'ambiance Immersive ; sans image, la couleur de fond seule.
class _Background extends StatelessWidget {
  const _Background({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null) return const ColoredBox(color: Palette.background);
    final size = MediaQuery.sizeOf(context);
    return GameImage(path: path, icon: Icons.public, width: size.width, height: size.height);
  }
}
