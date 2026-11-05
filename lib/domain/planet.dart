import 'dart:math' as math;

import 'game_data.dart';
import 'resources.dart';

/// État d'une planète à l'instant [lastUpdate]. Immuable.
class Planet {
  Planet({
    required this.id,
    required this.name,
    required this.tempMax,
    required this.resources,
    required Map<BuildingKind, int> levels,
    required this.lastUpdate,
  }) : levels = Map.unmodifiable({for (final k in BuildingKind.values) k: levels[k] ?? 0});

  /// Nouvelle planète : ressources de départ, bâtiments au niveau 0, Tmax tirée au sort.
  factory Planet.create({
    required GameData data,
    required math.Random random,
    required DateTime now,
    int id = 1,
    String name = 'Planète mère',
  }) {
    final s = data.start;
    return Planet(
      id: id,
      name: name,
      tempMax: s.tempMaxMin + random.nextInt(s.tempMaxMax - s.tempMaxMin + 1),
      resources: s.resources,
      levels: const {},
      lastUpdate: now,
    );
  }

  final int id;
  final String name;
  final int tempMax;
  final Resources resources;
  final Map<BuildingKind, int> levels;
  final DateTime lastUpdate;

  int level(BuildingKind kind) => levels[kind]!;

  Planet copyWith({Resources? resources, Map<BuildingKind, int>? levels, DateTime? lastUpdate}) =>
      Planet(
        id: id,
        name: name,
        tempMax: tempMax,
        resources: resources ?? this.resources,
        levels: levels ?? this.levels,
        lastUpdate: lastUpdate ?? this.lastUpdate,
      );

  Planet withLevel(BuildingKind kind, int level) =>
      copyWith(levels: {...levels, kind: level});
}
