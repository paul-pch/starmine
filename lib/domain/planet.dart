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
    Map<BuildingKind, int> percents = const {},
    Map<UnitKind, int> units = const {},
    this.debris = Resources.zero,
    this.boon,
    this.flaw,
    required this.lastUpdate,
  }) : units = Map.unmodifiable({for (final k in UnitKind.values) k: units[k] ?? 0}),
       levels = Map.unmodifiable({for (final k in BuildingKind.values) k: levels[k] ?? 0}),
       percents = Map.unmodifiable({for (final k in BuildingKind.values) k: percents[k] ?? 100});

  /// Nouvelle planète : ressources de départ, bâtiments au niveau 0, Tmax tirée au sort.
  factory Planet.create({
    required GameData data,
    required math.Random random,
    required DateTime now,
    int id = 1,
    String name = 'Planète mère',
  }) {
    final s = data.start;
    final tempMax = s.tempMaxMin + random.nextInt(s.tempMaxMax - s.tempMaxMin + 1);
    final traits = drawTraits(tempMax, data.planet, random);
    return Planet(
      id: id,
      name: name,
      tempMax: tempMax,
      resources: s.resources,
      levels: const {},
      boon: traits?.boon,
      flaw: traits?.flaw,
      lastUpdate: now,
    );
  }

  final int id;
  final String name;
  final int tempMax;
  final Resources resources;
  final Map<BuildingKind, int> levels;

  /// Réglage de production de chaque bâtiment, de 0 à 100 (défaut 100).
  final Map<BuildingKind, int> percents;

  /// Unités stationnées sur la planète (défenses en V2).
  final Map<UnitKind, int> units;

  /// Champ de débris en orbite (métal et cristal), collecté par les recycleurs (spec 15).
  final Resources debris;

  /// Traits (spec 16) : effet de l'atout et du défaut ; `null` avant leur tirage (ancienne
  /// sauvegarde).
  final TraitEffect? boon;
  final TraitEffect? flaw;

  TemperatureBand get band => TemperatureBand.of(tempMax);
  final DateTime lastUpdate;

  int level(BuildingKind kind) => levels[kind]!;

  int percent(BuildingKind kind) => percents[kind]!;

  int count(UnitKind kind) => units[kind]!;

  Planet copyWith({
    String? name,
    TraitEffect? boon,
    TraitEffect? flaw,
    Resources? resources,
    Map<BuildingKind, int>? levels,
    Map<BuildingKind, int>? percents,
    Map<UnitKind, int>? units,
    Resources? debris,
    DateTime? lastUpdate,
  }) => Planet(
    id: id,
    name: name ?? this.name,
    tempMax: tempMax,
    boon: boon ?? this.boon,
    flaw: flaw ?? this.flaw,
    resources: resources ?? this.resources,
    levels: levels ?? this.levels,
    percents: percents ?? this.percents,
    units: units ?? this.units,
    debris: debris ?? this.debris,
    lastUpdate: lastUpdate ?? this.lastUpdate,
  );

  Planet withLevel(BuildingKind kind, int level) => copyWith(levels: {...levels, kind: level});
}

/// Planète avec ses traits : tirés avec [seed] s'ils manquent (ancienne sauvegarde).
Planet withTraits(Planet p, PlanetConfig cfg, int seed) {
  if (p.boon != null && p.flaw != null) return p;
  final traits = drawTraits(p.tempMax, cfg, math.Random(seed ^ 0x7a17));
  return traits == null ? p : p.copyWith(boon: traits.boon, flaw: traits.flaw);
}

/// Longueur maximale du nom d'une planète.
const planetNameMax = 24;

/// Tire l'atout et le défaut d'une planète de Tmax [tempMax] (spec 16) : atout selon
/// `boon_weight` de sa tranche, défaut parmi les autres effets selon `flaw_weight`. `null`
/// si le catalogue a moins de deux traits.
({TraitEffect boon, TraitEffect flaw})? drawTraits(
  int tempMax,
  PlanetConfig cfg,
  math.Random random,
) {
  if (cfg.traits.length < 2) return null;
  final band = TemperatureBand.of(tempMax);
  TraitEffect pick(Iterable<PlanetTrait> traits, double Function(PlanetTrait) weight) {
    final list = traits.toList();
    final total = list.fold(0.0, (sum, t) => sum + weight(t));
    var roll = random.nextDouble() * total;
    for (final t in list) {
      roll -= weight(t);
      if (roll < 0) return t.effect;
    }
    return list.last.effect;
  }

  // Ordre stable : celui de l'énumération, pas celui du YAML.
  final traits = [
    for (final e in TraitEffect.values)
      if (cfg.traits[e] case final t?) t,
  ];
  final boon = pick(traits, (t) => t.boonWeight[band] ?? 1);
  final flaw = pick(traits.where((t) => t.effect != boon), (t) => t.flawWeight[band] ?? 1);
  return (boon: boon, flaw: flaw);
}
