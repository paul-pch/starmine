import 'dart:async';

import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'screens/buildings_screen.dart';
import 'screens/debug_screen.dart';
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
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _ticker.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _tick() {
    setState(() => _now = _c.now());
    final current = _c.state.currentConstruction;
    if (current != null && !current.dueAt.isAfter(_now)) _refresh();
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
        final pages = [
          BuildingsScreen(controller: _c, now: _now),
          QueueScreen(controller: _c, now: _now),
          DebugScreen(controller: _c),
        ];
        return Scaffold(
          appBar: AppBar(title: Text(_c.state.planet.name)),
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
              const NavigationDestination(icon: Icon(Icons.factory_outlined), label: 'Bâtiments'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: _c.state.currentConstruction != null,
                  smallSize: 8,
                  child: const Icon(Icons.schedule_outlined),
                ),
                label: 'File',
              ),
              const NavigationDestination(icon: Icon(Icons.tune_outlined), label: 'Debug'),
            ],
          ),
        );
      },
    );
  }
}
