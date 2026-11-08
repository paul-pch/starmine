import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../game_controller.dart';
import '../theme.dart';
import '../visuals.dart';

/// Hero 21:9 : image par tranche de température et bandeau opaque (nom, températures,
/// rapports). En ambiance Sobre, le bandeau seul.
class PlanetHero extends StatelessWidget {
  const PlanetHero({
    super.key,
    required this.controller,
    required this.onReports,
    required this.onOfficers,
    required this.onDebug,
  });

  /// Évite qu'un écran large ou un test de widgets ne donne tout l'écran au hero.
  static const _maxHeight = 200.0;

  final GameController controller;
  final VoidCallback onReports;
  final VoidCallback onOfficers;
  final VoidCallback onDebug;

  @override
  Widget build(BuildContext context) {
    final visuals = VisualsScope.of(context);
    final planet = controller.state.planet;
    final banner = _Banner(
      controller: controller,
      onReports: onReports,
      onOfficers: onOfficers,
      onDebug: onDebug,
    );
    if (visuals.plain) return ColoredBox(color: Palette.bar, child: banner);
    final width = MediaQuery.sizeOf(context).width;
    final height = math.min(width * 9 / 21, _maxHeight);
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          GameImage(
            path: visuals.hero(planet.tempMax),
            icon: Icons.public,
            iconSize: 48,
            width: width,
            height: height,
          ),
          Align(alignment: Alignment.bottomCenter, child: banner),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.controller,
    required this.onReports,
    required this.onOfficers,
    required this.onDebug,
  });

  final GameController controller;
  final VoidCallback onReports;
  final VoidCallback onOfficers;
  final VoidCallback onDebug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planet = controller.state.planet;
    final unseen = controller.unseenReports;
    final officers = controller.availableOfficers.length;
    return ColoredBox(
      color: Palette.heroScrim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(planet.name, style: theme.textTheme.titleLarge),
                  Text(
                    fmtTempRange(planet.tempMax - controller.data.start.tempSpread, planet.tempMax),
                    style: theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(tooltip: 'Debug', onPressed: onDebug, icon: const Icon(Icons.tune_outlined)),
            // Pastille : un officier attend d'être débloqué ou promu.
            IconButton(
              tooltip: officers > 0 ? 'Officiers, $officers disponibles' : 'Officiers',
              onPressed: onOfficers,
              icon: Badge(
                isLabelVisible: officers > 0,
                label: Text('$officers'),
                child: const Icon(Icons.military_tech_outlined),
              ),
            ),
            IconButton(
              tooltip: unseen > 0 ? 'Rapports de raid, $unseen non lus' : 'Rapports de raid',
              onPressed: onReports,
              icon: Badge(
                isLabelVisible: unseen > 0,
                label: Text('$unseen'),
                child: const Icon(Icons.article_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
