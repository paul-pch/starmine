import 'dart:async';

import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'notifications.dart';
import '../domain/engine.dart';
import 'resource_style.dart';
import 'theme.dart';
import 'visuals.dart';
import 'screens/debug_screen.dart';
import 'screens/officers_screen.dart';
import 'screens/reports_screen.dart';
import 'widgets/combat_report.dart';
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
        s.effects.any((e) => !e.endsAt.isAfter(_now))) {
      _refresh();
    }
  }

  /// Raid résolu pendant que l'app est ouverte : message avec accès au rapport. Le dernier
  /// remplace le précédent (pas de file de messages).
  void _onChange() {
    _onQueueCancelled();
    _onStory();
    final latest = _c.reports.firstOrNull;
    if (latest == null || latest.id == _lastReportId) return;
    _lastReportId = latest.id;
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(CombatReport.verdict(latest.report)),
          action: SnackBarAction(
            label: 'Rapport',
            onPressed: () {
              unawaited(_c.markReportSeen(latest.id));
              unawaited(CombatReport.show(context, _c.data, latest.report));
            },
          ),
        ),
      );
  }

  /// File annulée pendant que l'app est ouverte (spec 13) : message, le dernier remplace le
  /// précédent.
  void _onQueueCancelled() {
    final cancelled = _c.lastQueueCancelled;
    if (_c.queueCancelledCount == _queueCancelledSeen || cancelled == null || !mounted) return;
    _queueCancelledSeen = _c.queueCancelledCount;
    final (title, body) = queueCancelledText(cancelled, _c.data);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$title · $body')));
  }

  /// Événement ponctuel survenu app ouverte (spec 14) : message ; une décision ouvre sa
  /// feuille depuis le message.
  void _onStory() {
    final o = _c.lastStory;
    if (_c.storyCount == _storySeen || o == null || !mounted) return;
    _storySeen = _c.storyCount;
    if (o.kind == StoryOutcomeKind.answered) return;
    final (title, _) = storyText(o, _c.data);
    final spec = _c.data.story.catalog[o.key];
    final effects = o.kind == StoryOutcomeKind.happened && spec != null
        ? ' · ${spec.effects.map(storyEffectText).join(' · ')}'
        : '';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title$effects'),
          action: o.kind == StoryOutcomeKind.awaiting
              ? SnackBarAction(
                  label: 'Choisir',
                  onPressed: () => unawaited(StoryBanner.showChoice(context, _c)),
                )
              : null,
        ),
      );
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
          DebugScreen(controller: _c),
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
                  child: const Icon(Icons.shield_outlined),
                ),
                label: 'Défense',
              ),
              const NavigationDestination(icon: Icon(Icons.schedule_outlined), label: 'File'),
              const NavigationDestination(icon: Icon(Icons.tune_outlined), label: 'Debug'),
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
