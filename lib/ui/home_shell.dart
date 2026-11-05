import 'dart:async';

import 'package:flutter/material.dart';

import 'game_controller.dart';
import '../domain/game_data.dart';
import 'resource_style.dart';
import 'screens/debug_screen.dart';
import 'screens/defense_screen.dart';
import 'screens/items_screen.dart';
import 'screens/queue_screen.dart';
import 'widgets/resource_bar.dart';

/// Écran principal : barre de ressources, trois onglets.
/// Une horloge d'affichage (1 s) interpole les stocks sans rien écrire ; quand une
/// échéance est passée, elle déclenche un rattrapage réel via le contrôleur.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final GameController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late DateTime _now;
  late final Timer _ticker;
  late final AppLifecycleListener _lifecycle;
  var _tab = 0;
  var _refreshing = false;

  GameController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _now = _c.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(_c.onHidden()),
      onShow: () => unawaited(_c.onVisible()),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _tick() {
    setState(() => _now = _c.now());
    // Une échéance passée (construction ou recherche) : rattrapage réel.
    if (_c.state.pending.any((e) => !e.dueAt.isAfter(_now))) _refresh();
  }

  void _refresh() {
    if (_refreshing) return;
    _refreshing = true;
    unawaited(_c.refresh().whenComplete(() => _refreshing = false));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final state = _c.state;
        final pages = [
          ItemsScreen(controller: _c, items: BuildingKind.values, now: _now),
          ResearchScreen(controller: _c, now: _now),
          DefenseScreen(controller: _c, now: _now),
          QueueScreen(controller: _c, now: _now),
          DebugScreen(controller: _c),
        ];
        return Scaffold(
          appBar: AppBar(title: _PlanetTitle(controller: _c)),
          body: Column(
            children: [
              ResourceBar(controller: _c, now: _now),
              const Divider(height: 1),
              Expanded(child: pages[_tab]),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              // Pastille = slot libre : quelque chose peut être lancé dans cet onglet.
              NavigationDestination(
                icon: _FreeSlot(
                  free: state.currentConstruction == null,
                  child: const Icon(Icons.factory_outlined),
                ),
                label: 'Bâtiments',
              ),
              NavigationDestination(
                icon: _FreeSlot(
                  free:
                      state.currentResearch == null &&
                      state.planet.level(BuildingKind.researchLab) > 0,
                  child: const Icon(ResourceStyle.researchIcon),
                ),
                label: 'Recherche',
              ),
              NavigationDestination(
                icon: _FreeSlot(
                  free: state.currentBatch == null && state.planet.level(BuildingKind.shipyard) > 0,
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

/// Nom de la planète et sa plage de températures.
class _PlanetTitle extends StatelessWidget {
  const _PlanetTitle({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final planet = controller.state.planet;
    final tempMin = planet.tempMax - controller.data.start.tempSpread;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(planet.name),
        Text(
          'Température $tempMin °C à ${planet.tempMax} °C',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Petite pastille verte sur l'icône d'onglet quand le slot correspondant est libre.
class _FreeSlot extends StatelessWidget {
  const _FreeSlot({required this.free, required this.child});

  final bool free;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: free,
      smallSize: 7,
      backgroundColor: const Color(0xFF66BB6A),
      child: child,
    );
  }
}
