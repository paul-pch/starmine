import 'dart:math' as math;

import 'combat.dart';
import 'engine.dart';
import 'events.dart';
import 'game_data.dart';
import 'raid.dart';
import 'resources.dart';
import 'rules.dart';

// --- Bases pirates ------------------------------------------------------------------

/// Ce qu'une sonde a rapporté d'une base (détail selon la technologie Espionnage).
class SpyReport {
  const SpyReport({required this.at, this.resources, this.ships, this.defenses, this.tech});

  final DateTime at;
  final Resources? resources;
  final Map<UnitKind, int>? ships;
  final Map<UnitKind, int>? defenses;
  final TechLevels? tech;
}

/// État d'une base pirate (spec 15). La composition complète se calcule à la demande
/// (points du joueur × force, graine de la génération) ; seules les traces d'un combat,
/// le stock et la destruction sont stockés.
class PirateBase {
  const PirateBase({
    required this.index,
    required this.seed,
    this.generation = 0,
    this.stockFraction = 1,
    required this.stockAt,
    this.survivors,
    this.survivorsUntil,
    this.destroyedUntil,
    this.debris = Resources.zero,
    this.spy,
  });

  final int index;
  final int seed;

  /// Incrémentée à chaque destruction : nouvelle base, nouvelle composition.
  final int generation;

  /// Stock relatif (0 à 1) à [stockAt], remonte linéairement jusqu'à 1.
  final double stockFraction;
  final DateTime stockAt;

  /// Unités restantes après un combat, jusqu'à [survivorsUntil] (défenses relevées).
  final Map<UnitKind, int>? survivors;
  final DateTime? survivorsUntil;

  /// Base détruite : remplacée à cette date.
  final DateTime? destroyedUntil;

  /// Champ de débris en orbite de la base.
  final Resources debris;
  final SpyReport? spy;

  PirateBase copyWith({
    int? generation,
    double? stockFraction,
    DateTime? stockAt,
    Map<UnitKind, int>? Function()? survivors,
    DateTime? Function()? survivorsUntil,
    DateTime? Function()? destroyedUntil,
    Resources? debris,
    SpyReport? spy,
  }) => PirateBase(
    index: index,
    seed: seed,
    generation: generation ?? this.generation,
    stockFraction: stockFraction ?? this.stockFraction,
    stockAt: stockAt ?? this.stockAt,
    survivors: survivors == null ? this.survivors : survivors(),
    survivorsUntil: survivorsUntil == null ? this.survivorsUntil : survivorsUntil(),
    destroyedUntil: destroyedUntil == null ? this.destroyedUntil : destroyedUntil(),
    debris: debris ?? this.debris,
    spy: spy ?? this.spy,
  );
}

/// Crée les bases du catalogue si la partie n'en a pas encore.
GameState ensureBases(GameState s, DateTime now, Rules rules, {required int seed}) {
  final list = rules.data.pirateBases.list;
  if (s.bases.length >= list.length) return s;
  final random = math.Random(seed);
  return s.copyWith(
    bases: [
      ...s.bases,
      for (var i = s.bases.length; i < list.length; i++)
        PirateBase(index: i, seed: random.nextInt(1 << 31), stockAt: now),
    ],
  );
}

/// Base disponible à [at] (pas détruite).
bool baseAvailable(PirateBase b, DateTime at) {
  final until = b.destroyedUntil;
  return until == null || !until.isAfter(at);
}

/// Base à [at] après une éventuelle réapparition : nouvelle génération, stock plein.
PirateBase _respawned(PirateBase b) {
  final until = b.destroyedUntil;
  if (until == null) return b;
  return b.copyWith(
    generation: b.generation + 1,
    stockFraction: 1,
    stockAt: until,
    survivors: () => null,
    survivorsUntil: () => null,
    destroyedUntil: () => null,
  );
}

/// Composition d'une base pour un budget (en ressources) : une **doctrine** tirée avec la
/// graine (part des vaisseaux 20, 50 ou 80 %) et une partie seulement des types débloqués à
/// [points] : deux générations ne se ressemblent pas, d'où l'intérêt d'espionner avant.
Map<UnitKind, int> pirateBaseUnits(double budget, double points, GameData data, int seed) {
  final random = math.Random(seed);
  final shipShare = const [0.2, 0.5, 0.8][random.nextInt(3)];
  final units = <UnitKind, int>{};
  void spend(Map<UnitKind, double> available, double share) {
    final unlocked = [
      for (final e in available.entries)
        if (points >= e.value) e.key,
    ];
    final kinds = [
      for (final k in unlocked)
        if (random.nextDouble() < 0.6) k,
    ];
    if (kinds.isEmpty && unlocked.isNotEmpty) kinds.add(unlocked[random.nextInt(unlocked.length)]);
    final weights = [for (final _ in kinds) 0.5 + random.nextDouble()];
    for (final e in allocateBudget(budget * share, kinds, weights, data).entries) {
      units[e.key] = (units[e.key] ?? 0) + e.value;
    }
  }

  spend(data.pirates.warships, shipShare);
  spend(data.pirateBases.defenses, 1 - shipShare);
  if (units.isEmpty) units[UnitKind.lightFighter] = 1;
  return units;
}

/// Ta production horaire totale (métal + cristal + deutérium), à ×1.
double productionPerHour(GameState s, Rules rules) {
  final rate = rules.hourlyProduction(s.planet, s.research, s.modifiers(rules.data));
  return [rate.metal, rate.crystal, rate.deuterium].fold(0.0, (sum, v) => sum + math.max(0.0, v)) /
      rules.speed;
}

/// Unités de la base [b] à [at] : valeur = `defense_hours` de ta production (plancher
/// `pirate_bases.min_budget`), ou les survivants d'un combat récent.
Map<UnitKind, int> baseUnits(GameState s, PirateBase b, DateTime at, Rules rules) {
  final until = b.survivorsUntil;
  final survivors = b.survivors;
  if (survivors != null && until != null && until.isAfter(at)) return survivors;
  final cfg = rules.data.pirateBases;
  final spec = cfg.list[b.index];
  final budget = math.max(cfg.minBudget, spec.defenseHours * productionPerHour(s, rules));
  return pirateBaseUnits(budget, economyPoints(s, rules), rules.data, b.seed + b.generation * 7919);
}

/// Stock de la base [b] à [at] : `stock_hours` de ta production (×1), au prorata de son
/// remplissage.
Resources baseStock(GameState s, PirateBase b, DateTime at, Rules rules) {
  final cfg = rules.data.pirateBases;
  final spec = cfg.list[b.index];
  final rate = rules.hourlyProduction(s.planet, s.research, s.modifiers(rules.data));
  final hours = at.difference(b.stockAt).inMilliseconds / Duration.millisecondsPerHour;
  final fill = math.min(1.0, b.stockFraction + hours * rules.speed / cfg.refillHours);
  return rate.map(
    (_, v) => (math.max(0.0, v / rules.speed) * spec.stockHours * fill).floorToDouble(),
  );
}

/// Technos des pirates d'une base : les tiennes moins le décalage des raids.
TechLevels baseTech(GameState s, Rules rules) => pirateTech(s.research, rules.data.pirates);

// --- Trajets -------------------------------------------------------------------------

/// Vitesse d'un vaisseau, réacteur compris.
double unitSpeed(UnitKind unit, TechLevels tech, GameData data) {
  final spec = data.unit(unit);
  final drive = spec.drive;
  if (drive == null) return spec.speed;
  return spec.speed * (1 + data.tech(drive).driveBonus * (tech[drive] ?? 0));
}

/// Vitesse d'une flotte : celle de son vaisseau le plus lent.
double fleetSpeed(Map<UnitKind, int> ships, TechLevels tech, GameData data) {
  var speed = double.infinity;
  for (final e in ships.entries) {
    if (e.value > 0) speed = math.min(speed, unitSpeed(e.key, tech, data));
  }
  return speed.isFinite ? speed : 0;
}

/// Durée d'un aller (formule OGame × `fleet.flight_factor`, divisée par la vitesse de jeu).
Duration flightDuration(
  Map<UnitKind, int> ships,
  double distance,
  int speedPercent,
  TechLevels tech,
  Rules rules,
) {
  final v = fleetSpeed(ships, tech, rules.data);
  if (v <= 0) return Duration.zero;
  final seconds =
      (10 + 35000 / speedPercent * math.sqrt(distance * 10 / v)) * rules.data.fleet.flightFactor;
  return Duration(milliseconds: (seconds * 1000 / rules.speed).round());
}

/// Deutérium d'un aller.
double fuelCost(Map<UnitKind, int> ships, double distance, int speedPercent, GameData data) {
  var fuel = 0.0;
  final k = math.pow(speedPercent / 100 + 1, 2);
  for (final e in ships.entries) {
    fuel += e.value * data.unit(e.key).fuel * distance / 35000 * k;
  }
  return fuel.ceilToDouble();
}

/// Soute d'une flotte.
double shipsCargo(Map<UnitKind, int> ships, GameData data) =>
    ships.entries.fold(0.0, (sum, e) => sum + e.value * data.unit(e.key).cargo);

List<FleetMission> missions(GameState s) => s.pending.whereType<FleetMission>().toList();

/// Missions de [kind] en vol (aller, exploration ou retour).
int missionsOf(GameState s, MissionKind kind) => missions(s).where((m) => m.kind == kind).length;

/// Plafond de vaisseaux par mission (V3c) : `ships_base` + `ships_per_level` ×
/// min(Informatique, `ships_max_level`).
int shipCap(GameState s, GameData data) {
  final cfg = data.fleet;
  final level = math.min(s.research[TechKind.computer] ?? 0, cfg.shipsMaxLevel);
  return cfg.shipsBase + cfg.shipsPerLevel * level;
}

/// Vaisseaux comptés dans le plafond : ni sondes ni recycleurs.
int cappedShips(Map<UnitKind, int> ships) => ships.entries
    .where((e) => e.key != UnitKind.espionageProbe && e.key != UnitKind.recycler)
    .fold(0, (sum, e) => sum + e.value);

/// Les missions soumises au plafond de vaisseaux.
bool isCapped(MissionKind kind) =>
    kind == MissionKind.attack || kind == MissionKind.expedition || kind == MissionKind.recycle;

/// Places d'expédition : 1 + Amiral.
int expeditionSlots(GameState s, GameData data) => 1 + s.modifiers(data).expeditionSlots;

// --- Missions --------------------------------------------------------------------------

enum MissionBlock {
  noShips,
  notEnoughShips,
  attackBusy,
  expeditionsFull,
  overCap,
  noFuel,
  unavailable,
  noDebris,
  noProbe,
  noRecycler,
}

/// Distance d'une mise à l'abri : celle de la base la plus proche.
double shelterDistance(GameData data) => data.pirateBases.list.isEmpty
    ? 2700
    : data.pirateBases.list.map((b) => b.distance).reduce(math.min);

double _distance(MissionKind kind, int? target, GameData data) => switch (kind) {
  MissionKind.expedition => data.expedition.distance,
  MissionKind.shelter => shelterDistance(data),
  _ => target == null ? shelterDistance(data) : data.pirateBases.list[target].distance,
};

/// Prévision d'un envoi : durée d'un aller, carburant aller-retour, soute.
({Duration oneWay, double fuel, double cargo}) missionPreview(
  GameState s,
  MissionKind kind,
  int? target,
  Map<UnitKind, int> ships,
  int speedPercent,
  Rules rules,
) {
  final data = rules.data;
  final distance = _distance(kind, target, data);
  return (
    oneWay: flightDuration(ships, distance, speedPercent, s.research, rules),
    fuel: 2 * fuelCost(ships, distance, speedPercent, data),
    cargo: shipsCargo(ships, data),
  );
}

MissionBlock? checkMission(
  GameState s,
  MissionKind kind,
  int? target,
  Map<UnitKind, int> ships,
  int speedPercent,
  DateTime at,
  Rules rules,
) {
  final selected = {
    for (final e in ships.entries)
      if (e.value > 0) e.key: e.value,
  };
  if (selected.isEmpty) return MissionBlock.noShips;
  for (final e in selected.entries) {
    if (s.planet.count(e.key) < e.value) return MissionBlock.notEnoughShips;
  }
  final data = rules.data;
  if (kind == MissionKind.attack && missionsOf(s, kind) >= data.fleet.attackSlots) {
    return MissionBlock.attackBusy;
  }
  if (kind == MissionKind.expedition && missionsOf(s, kind) >= expeditionSlots(s, data)) {
    return MissionBlock.expeditionsFull;
  }
  if (isCapped(kind) && cappedShips(selected) > shipCap(s, data)) return MissionBlock.overCap;
  if (target != null && !baseAvailable(s.bases[target], at)) return MissionBlock.unavailable;
  if (kind == MissionKind.spy && selected.keys.any((k) => k != UnitKind.espionageProbe)) {
    return MissionBlock.noProbe;
  }
  if (kind == MissionKind.recycle) {
    if ((selected[UnitKind.recycler] ?? 0) == 0) return MissionBlock.noRecycler;
    final d = s.bases[target!].debris;
    if (d.metal + d.crystal < 1) return MissionBlock.noDebris;
  }
  final fuel = missionPreview(s, kind, target, selected, speedPercent, rules).fuel;
  if (s.planet.resources.deuterium < fuel) return MissionBlock.noFuel;
  return null;
}

/// Envoie une flotte à [now] : vaisseaux retirés de la planète, carburant aller-retour payé.
/// Mise à l'abri : [shelterHours] heures (à ×1) hors de la planète, retour direct.
({GameState state, MissionBlock? block}) sendMission(
  GameState state,
  MissionKind kind,
  int? target,
  Map<UnitKind, int> ships,
  int speedPercent,
  DateTime now,
  Rules rules, {
  required int eventId,
  required int seed,
  double shelterHours = 0,
  double exploreHours = 0,
}) {
  final s = advance(state, now, rules).state;
  final block = checkMission(s, kind, target, ships, speedPercent, now, rules);
  if (block != null) return (state: s, block: block);
  final selected = {
    for (final e in ships.entries)
      if (e.value > 0) e.key: e.value,
  };
  final preview = missionPreview(s, kind, target, selected, speedPercent, rules);
  final shelter = kind == MissionKind.shelter;
  final away = Duration(
    milliseconds: (shelterHours * Duration.millisecondsPerHour / rules.speed).round(),
  );
  final mission = FleetMission(
    id: eventId,
    planetId: s.planet.id,
    dueAt: now.add(shelter ? away : preview.oneWay),
    kind: kind,
    target: shelter || kind == MissionKind.expedition ? null : target,
    ships: selected,
    returning: shelter,
    departedAt: now,
    speedPercent: speedPercent,
    seed: seed,
    exploreHours: kind == MissionKind.expedition ? exploreHours : 0,
  );
  final p = s.planet;
  return (
    state: s.copyWith(
      planet: p.copyWith(
        units: {for (final k in UnitKind.values) k: p.count(k) - (selected[k] ?? 0)},
        resources: p.resources - Resources(deuterium: preview.fuel),
      ),
      pending: [...s.pending, mission],
    ),
    block: null,
  );
}

/// Rappel d'une flotte à l'aller : demi-tour, le retour prend le temps déjà parcouru.
GameState recallMission(GameState state, int id, DateTime now, Rules rules) {
  final s = advance(state, now, rules).state;
  final m = missions(s).where((e) => e.id == id && !e.returning).firstOrNull;
  if (m == null) return s;
  // En exploration : retour direct, durée d'un aller.
  final elapsed = m.exploring
      ? flightDuration(
          m.ships,
          _distance(m.kind, m.target, rules.data),
          m.speedPercent,
          s.research,
          rules,
        )
      : now.difference(m.departedAt);
  final back = m.copyWith(dueAt: now.add(elapsed), returning: true, exploring: false);
  return s.copyWith(pending: [for (final e in s.pending) e.id == id ? back : e]);
}

GameState _withBase(GameState s, PirateBase b) =>
    s.copyWith(bases: [for (final x in s.bases) x.index == b.index ? b : x]);

/// Arrivée d'une flotte à sa base : combat et pillage, rapport d'espionnage ou collecte ;
/// la flotte (survivante) repart avec son chargement, même id.
({GameState state, GameEvent? next, RaidReport? report}) missionArrive(
  GameState s,
  FleetMission m,
  Rules rules,
) {
  final data = rules.data;
  final at = m.dueAt;
  if (m.kind == MissionKind.expedition) return _expedition(s, m, rules);
  final target = m.target!;
  final spec = data.pirateBases.list[target];
  final base = _respawned(s.bases[target]);
  final duration = flightDuration(m.ships, spec.distance, m.speedPercent, s.research, rules);
  FleetMission back(Map<UnitKind, int> ships, Resources cargo) =>
      m.copyWith(dueAt: at.add(duration), ships: ships, cargo: cargo, returning: true);

  if (!baseAvailable(base, at)) {
    return (state: _withBase(s, base), next: back(m.ships, Resources.zero), report: null);
  }
  switch (m.kind) {
    case MissionKind.spy:
      final level = s.research[TechKind.espionage] ?? 0;
      final units = baseUnits(s, base, at, rules);
      final report = SpyReport(
        at: at,
        resources: level >= 1 ? baseStock(s, base, at, rules) : null,
        ships: level >= 2
            ? {
                for (final e in units.entries)
                  if (!data.unit(e.key).defense) e.key: e.value,
              }
            : null,
        defenses: level >= 4
            ? {
                for (final e in units.entries)
                  if (data.unit(e.key).defense) e.key: e.value,
              }
            : null,
        tech: level >= 6 ? baseTech(s, rules) : null,
      );
      return (
        state: _withBase(s, base.copyWith(spy: report)),
        next: back(m.ships, Resources.zero),
        report: null,
      );
    case MissionKind.recycle:
      final random = math.Random(m.seed);
      if (random.nextDouble() < data.pirateBases.patrolChance) {
        return _patrol(s, m, base, at, rules, random, back);
      }
      final load = recycleLoad(base.debris, m.ships[UnitKind.recycler] ?? 0, data);
      return (
        state: _withBase(s, base.copyWith(debris: base.debris - load)),
        next: back(m.ships, load),
        report: null,
      );
    case MissionKind.shelter || MissionKind.expedition:
      return (state: s, next: back(m.ships, Resources.zero), report: null);
    case MissionKind.attack:
      final random = math.Random(m.seed);
      final attacker = CombatSide(units: m.ships, tech: s.research);
      final defender = CombatSide(units: baseUnits(s, base, at, rules), tech: baseTech(s, rules));
      final result = simulateCombat(data, attacker, defender, random);
      final stock = baseStock(s, base, at, rules);
      final won = result.winner == CombatWinner.attacker;
      final taken = won
          ? loot(stock, shipsCargo(result.attackerLeft, data), data.pirateBases.lootShare)
          : Resources.zero;
      final debris = combatDebris(result, data);
      final stockTotal = stock.metal + stock.crystal + stock.deuterium;
      final takenTotal = taken.metal + taken.crystal + taken.deuterium;
      final fill = math.min(
        1.0,
        base.stockFraction +
            at.difference(base.stockAt).inMilliseconds /
                Duration.millisecondsPerHour *
                rules.speed /
                data.pirateBases.refillHours,
      );
      final cfg = data.pirateBases;
      Duration hours(double h) =>
          Duration(milliseconds: (h * Duration.millisecondsPerHour / rules.speed).round());
      final after = base.copyWith(
        stockFraction: stockTotal <= 0 ? fill : fill * (1 - takenTotal / stockTotal),
        stockAt: at,
        debris: base.debris + debris,
        survivors: () => won ? null : result.defenderLeft,
        survivorsUntil: () => won ? null : at.add(hours(cfg.rebuildHours)),
        destroyedUntil: () => won ? at.add(hours(cfg.respawnHours)) : null,
      );
      final left = result.attackerLeft;
      return (
        state: _withBase(s, after),
        next: left.values.any((n) => n > 0) ? back(left, taken) : null,
        report: RaidReport.fromCombat(
          result,
          at: at,
          loot: taken,
          debris: debris,
          attackerStrength: SideStrength.of(data, attacker),
          defenderStrength: SideStrength.of(data, defender),
          baseName: spec.name,
        ),
      );
  }
}

/// Flotte pirate de vaisseaux seulement, d'une valeur de [budget], types débloqués aux
/// points d'économie du joueur.
Map<UnitKind, int> _pirateShips(double budget, GameState s, Rules rules, math.Random random) {
  final points = economyPoints(s, rules);
  final kinds = [
    for (final e in rules.data.pirates.warships.entries)
      if (points >= e.value) e.key,
  ];
  if (kinds.isEmpty) kinds.add(UnitKind.lightFighter);
  final weights = [for (final _ in kinds) 0.5 + random.nextDouble()];
  final units = allocateBudget(budget, kinds, weights, rules.data);
  if (units.isEmpty) units[kinds.first] = 1;
  return units;
}

/// Patrouille pirate surprise au recyclage d'un champ de base (V3c) : combat contre les
/// recycleurs et leur escorte. Gagné : collecte ; sinon les survivants rentrent à vide. Les
/// débris du combat s'ajoutent au champ.
({GameState state, GameEvent? next, RaidReport? report}) _patrol(
  GameState s,
  FleetMission m,
  PirateBase base,
  DateTime at,
  Rules rules,
  math.Random random,
  FleetMission Function(Map<UnitKind, int>, Resources) back,
) {
  final data = rules.data;
  final cfg = data.pirateBases;
  final budget = math.max(
    cfg.minBudget,
    cfg.list[base.index].defenseHours * productionPerHour(s, rules),
  );
  final attacker = CombatSide(units: m.ships, tech: s.research);
  final defender = CombatSide(
    units: _pirateShips(budget * cfg.patrolStrength, s, rules, random),
    tech: baseTech(s, rules),
  );
  final result = simulateCombat(data, attacker, defender, random);
  final debris = combatDebris(result, data);
  final left = result.attackerLeft;
  final won = result.winner == CombatWinner.attacker;
  final load = won ? recycleLoad(base.debris, left[UnitKind.recycler] ?? 0, data) : Resources.zero;
  return (
    state: _withBase(s, base.copyWith(debris: base.debris - load + debris)),
    next: left.values.any((n) => n > 0) ? back(left, load) : null,
    report: RaidReport.fromCombat(
      result,
      at: at,
      loot: load,
      debris: debris,
      attackerStrength: SideStrength.of(data, attacker),
      defenderStrength: SideStrength.of(data, defender),
      baseName: data.pirateBases.list[base.index].name,
      patrol: true,
    ),
  );
}

/// Tirage du résultat d'une expédition, selon les poids (`nothing` ÷ durée en heures).
ExpeditionOutcome drawExpedition(double hours, GameData data, math.Random random) {
  final weights = {
    for (final e in data.expedition.outcomes.entries)
      e.key: e.key == ExpeditionOutcome.nothing ? e.value / math.max(1, hours) : e.value,
  };
  final total = weights.values.fold(0.0, (a, b) => a + b);
  var roll = random.nextDouble() * total;
  for (final e in weights.entries) {
    roll -= e.value;
    if (roll < 0) return e.key;
  }
  return ExpeditionOutcome.nothing;
}

/// Expédition : arrivée (début de l'exploration), puis fin de l'exploration (résultat tiré
/// avec la graine de la mission) et retour.
({GameState state, GameEvent? next, RaidReport? report}) _expedition(
  GameState s,
  FleetMission m,
  Rules rules,
) {
  final data = rules.data;
  final cfg = data.expedition;
  final at = m.dueAt;
  if (!m.exploring) {
    final explore = Duration(
      milliseconds: (m.exploreHours * Duration.millisecondsPerHour / rules.speed).round(),
    );
    return (state: s, next: m.copyWith(dueAt: at.add(explore), exploring: true), report: null);
  }
  final random = math.Random(m.seed);
  final outcome = drawExpedition(m.exploreHours, data, random);
  final counted = s.copyWith(
    counters: {...s.counters, Counter.expeditions: s.counters[Counter.expeditions]! + 1},
  );
  Duration flight(Map<UnitKind, int> ships) =>
      flightDuration(ships, cfg.distance, m.speedPercent, s.research, rules);
  FleetMission back(Map<UnitKind, int> ships, Resources cargo, [double factor = 1]) => m.copyWith(
    dueAt: at.add(flight(ships) * factor),
    ships: ships,
    cargo: cargo,
    returning: true,
    exploring: false,
  );
  RaidReport report({
    Map<UnitKind, int>? left,
    Resources loot = Resources.zero,
    Map<UnitKind, int> found = const {},
  }) => RaidReport(
    at: at,
    winner: CombatWinner.attacker,
    rounds: 0,
    attackerStart: m.ships,
    attackerLeft: left ?? m.ships,
    defenderStart: const {},
    defenderLeft: const {},
    rebuilt: const {},
    loot: loot,
    expedition: outcome,
    found: found,
  );
  final rate = rules.hourlyProduction(s.planet, s.research, s.modifiers(data));
  switch (outcome) {
    case ExpeditionOutcome.nothing:
      return (state: counted, next: back(m.ships, Resources.zero), report: report());
    case ExpeditionOutcome.resources:
      final hours = cfg.resourceHours * m.exploreHours;
      final found = rate.map((_, v) => math.max(0.0, v / rules.speed) * hours);
      final cargo = shipsCargo(m.ships, data);
      final total = found.metal + found.crystal + found.deuterium;
      final scale = total <= cargo || total <= 0 ? 1.0 : cargo / total;
      final loot = found.map((_, v) => (v * scale).floorToDouble());
      return (state: counted, next: back(m.ships, loot), report: report(loot: loot));
    case ExpeditionOutcome.ships:
      final budget = productionPerHour(s, rules) * cfg.shipHours * m.exploreHours;
      final kinds = [
        for (final k in UnitKind.values)
          if (!data.unit(k).defense &&
              k != UnitKind.espionageProbe &&
              unmet(s, data.unit(k).requires).isEmpty)
            k,
      ];
      // Aucun type débloqué au chantier : des vaisseaux semblables à ceux envoyés.
      if (kinds.isEmpty) {
        kinds.addAll(m.ships.keys.where((k) => k != UnitKind.espionageProbe));
      }
      final weights = [for (final _ in kinds) 0.5 + random.nextDouble()];
      final found = allocateBudget(budget, kinds, weights, data);
      // Au moins un vaisseau : le moins cher des types possibles.
      if (found.isEmpty && kinds.isNotEmpty) {
        double value(UnitKind k) => fleetValue({k: 1}, data);
        found[kinds.reduce((a, b) => value(a) <= value(b) ? a : b)] = 1;
      }
      final ships = {
        for (final k in {...m.ships.keys, ...found.keys}) k: (m.ships[k] ?? 0) + (found[k] ?? 0),
      };
      return (
        state: counted,
        next: back(ships, Resources.zero),
        report: report(left: ships, found: found),
      );
    case ExpeditionOutcome.ambush:
      final share = cfg.ambushMin + random.nextDouble() * (cfg.ambushMax - cfg.ambushMin);
      // Risque à la mesure du gain espéré : part du butin d'une exploration de cette durée.
      final budget = math.max(
        1000.0,
        productionPerHour(s, rules) * cfg.resourceHours * m.exploreHours * share,
      );
      final attacker = CombatSide(units: m.ships, tech: s.research);
      final defender = CombatSide(
        units: _pirateShips(budget, s, rules, random),
        tech: pirateTech(s.research, data.pirates),
      );
      final result = simulateCombat(data, attacker, defender, random);
      final left = result.attackerLeft;
      return (
        state: counted,
        next: left.values.any((n) => n > 0) ? back(left, Resources.zero) : null,
        report: RaidReport.fromCombat(
          result,
          at: at,
          attackerStrength: SideStrength.of(data, attacker),
          defenderStrength: SideStrength.of(data, defender),
          expedition: outcome,
        ),
      );
    case ExpeditionOutcome.delay:
      return (
        state: counted,
        next: back(m.ships, Resources.zero, cfg.delayFactor),
        report: report(),
      );
    case ExpeditionOutcome.early:
      return (
        state: counted,
        next: back(m.ships, Resources.zero, cfg.earlyFactor),
        report: report(),
      );
    case ExpeditionOutcome.blackHole:
      return (state: counted, next: null, report: report(left: const {}));
  }
}

/// Retour d'une flotte : vaisseaux et chargement déposés (au-delà du stockage possible).
GameState missionReturn(GameState s, FleetMission m) {
  final p = s.planet;
  return s.copyWith(
    planet: p.copyWith(
      units: {for (final k in UnitKind.values) k: p.count(k) + (m.ships[k] ?? 0)},
      resources: p.resources + m.cargo,
    ),
  );
}
