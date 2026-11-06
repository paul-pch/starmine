import 'dart:math' as math;

import 'combat.dart';
import 'engine.dart';
import 'events.dart';
import 'game_data.dart';
import 'resources.dart';
import 'rules.dart';

/// Points du joueur (classement OGame) : ressources dépensées ÷ 1000, bâtiments,
/// technologies et unités. Les ordres en cours ne comptent pas.
double points(GameState state, Rules rules) {
  var spent = 0.0;
  for (final item in <Unlockable>[...BuildingKind.values, ...TechKind.values]) {
    for (var l = 1; l <= state.levelOf(item); l++) {
      spent += _total(rules.cost(item, l));
    }
  }
  for (final e in state.planet.units.entries) {
    spent += e.value * _total(rules.data.unit(e.key).baseCost);
  }
  return spent / 1000;
}

double _total(Resources r) => r.metal + r.crystal + r.deuterium;

/// Composition d'une flotte pirate pour un joueur à [playerPoints] points.
/// Budget = max(plancher, points × 1000 × force) ; une part va aux transporteurs.
Map<UnitKind, int> pirateFleet(double playerPoints, GameData data, math.Random random) {
  final cfg = data.pirates;
  final strength = cfg.strengthMin + random.nextDouble() * (cfg.strengthMax - cfg.strengthMin);
  final budget = math.max(cfg.minBudget, playerPoints * 1000 * strength);

  final warships = [
    for (final e in cfg.warships.entries)
      if (playerPoints >= e.value) e.key,
  ];
  final weights = [for (final _ in warships) 0.5 + random.nextDouble()];
  final weightSum = weights.fold(0.0, (a, b) => a + b);
  final combatBudget = budget * (1 - cfg.cargoShare);

  final fleet = <UnitKind, int>{};
  for (var i = 0; i < warships.length; i++) {
    final n = (combatBudget * weights[i] / weightSum / _total(data.unit(warships[i]).baseCost))
        .floor();
    if (n > 0) fleet[warships[i]] = n;
  }
  if (fleet.isEmpty) fleet[warships.first] = 1;

  UnitKind? cargo;
  for (final e in cfg.cargoShips.entries) {
    if (playerPoints >= e.value) cargo = e.key;
  }
  if (cargo != null) {
    final n = (budget * cfg.cargoShare / _total(data.unit(cargo).baseCost)).floor();
    if (n > 0) fleet[cargo] = n;
  }
  return fleet;
}

/// Capacité de soute d'une flotte.
double cargoCapacity(Map<UnitKind, int> fleet, GameData data) =>
    fleet.entries.fold(0.0, (sum, e) => sum + e.value * data.unit(e.key).cargo);

/// Butin : au plus [share] de chaque stock, réduit proportionnellement à la soute.
Resources loot(Resources stock, double capacity, double share) {
  final max = stock.map((_, v) => math.max(0.0, v * share).floorToDouble());
  final total = _total(max);
  if (total <= capacity) return max;
  return max.map((_, v) => (v * capacity / total).floorToDouble());
}

/// Rapport d'un combat (raid ou simulation).
class RaidReport {
  const RaidReport({
    required this.at,
    required this.winner,
    required this.rounds,
    required this.attackerStart,
    required this.attackerLeft,
    required this.defenderStart,
    required this.defenderLeft,
    required this.rebuilt,
    this.loot = Resources.zero,
    this.simulated = false,
    this.attackerStrength,
    this.defenderStrength,
    this.roundDetails = const [],
  });

  factory RaidReport.fromCombat(
    CombatResult r, {
    required DateTime at,
    Resources loot = Resources.zero,
    bool simulated = false,
    SideStrength? attackerStrength,
    SideStrength? defenderStrength,
  }) => RaidReport(
    at: at,
    winner: r.winner,
    rounds: r.rounds.length,
    attackerStart: r.attackerStart,
    attackerLeft: r.attackerLeft,
    defenderStart: r.defenderStart,
    defenderLeft: r.defenderLeft,
    rebuilt: r.rebuilt,
    loot: loot,
    simulated: simulated,
    attackerStrength: attackerStrength,
    defenderStrength: defenderStrength,
    roundDetails: r.rounds,
  );

  final DateTime at;
  final CombatWinner winner;
  final int rounds;
  final Map<UnitKind, int> attackerStart;
  final Map<UnitKind, int> attackerLeft;
  final Map<UnitKind, int> defenderStart;
  final Map<UnitKind, int> defenderLeft;
  final Map<UnitKind, int> rebuilt;
  final Resources loot;

  /// Simulation (debug, estimation) : pas un vrai raid.
  final bool simulated;

  /// Forces en présence au début du combat (absentes des rapports antérieurs).
  final SideStrength? attackerStrength;
  final SideStrength? defenderStrength;

  /// Détail des rounds (vide pour les rapports antérieurs).
  final List<CombatRound> roundDetails;
}

/// Valeur en ressources (M + C + D) d'un ensemble d'unités.
double fleetValue(Map<UnitKind, num> units, GameData data) =>
    units.entries.fold(0.0, (sum, e) => sum + e.value * _total(data.unit(e.key).baseCost));

/// Bilan de [runs] batailles simulées : probabilités et moyennes.
class SimulationSummary {
  const SimulationSummary({
    required this.runs,
    required this.attackerWins,
    required this.defenderWins,
    required this.draws,
    required this.averageRounds,
    required this.attackerLosses,
    required this.defenderLosses,
    required this.averageLoot,
    required this.attackerStrength,
    required this.defenderStrength,
  });

  final int runs;
  final int attackerWins;
  final int defenderWins;
  final int draws;
  final double averageRounds;

  /// Pertes moyennes par type (défenses : après reconstruction).
  final Map<UnitKind, double> attackerLosses;
  final Map<UnitKind, double> defenderLosses;

  /// Pillage moyen, toutes batailles confondues.
  final Resources averageLoot;
  final SideStrength attackerStrength;
  final SideStrength defenderStrength;

  double rate(int n) => n / runs;
}

/// Simule [runs] fois un raid de [fleet] contre la planète de [state] (stocks actuels).
SimulationSummary simulateRaid(
  GameState state,
  Map<UnitKind, int> fleet,
  GameData data, {
  int runs = 100,
  required math.Random random,
}) {
  final attacker = CombatSide(units: fleet);
  final defender = CombatSide(units: state.planet.units, tech: state.research);
  var aWins = 0;
  var dWins = 0;
  var draws = 0;
  var rounds = 0;
  var lootSum = Resources.zero;
  final aLoss = <UnitKind, double>{};
  final dLoss = <UnitKind, double>{};
  for (var i = 0; i < runs; i++) {
    final r = simulateCombat(data, attacker, defender, random);
    rounds += r.rounds.length;
    switch (r.winner) {
      case CombatWinner.attacker:
        aWins++;
        lootSum =
            lootSum +
            loot(
              state.planet.resources,
              cargoCapacity(r.attackerLeft, data),
              data.pirates.lootShare,
            );
      case CombatWinner.defender:
        dWins++;
      case CombatWinner.draw:
        draws++;
    }
    for (final e in r.attackerLosses.entries) {
      aLoss[e.key] = (aLoss[e.key] ?? 0) + e.value / runs;
    }
    for (final e in r.defenderLosses.entries) {
      dLoss[e.key] = (dLoss[e.key] ?? 0) + e.value / runs;
    }
  }
  return SimulationSummary(
    runs: runs,
    attackerWins: aWins,
    defenderWins: dWins,
    draws: draws,
    averageRounds: rounds / runs,
    attackerLosses: aLoss,
    defenderLosses: dLoss,
    averageLoot: lootSum * (1 / runs),
    attackerStrength: SideStrength.of(data, attacker),
    defenderStrength: SideStrength.of(data, defender),
  );
}

/// Résultat d'un événement de raid : nouvel état, événement suivant, rapport éventuel.
typedef RaidStep = ({GameState state, GameEvent next, RaidReport? report});

/// [h] heures de jeu à ×1, arrondies à la milliseconde (précision de la base).
Duration _hours(double h, Rules rules) =>
    Duration(milliseconds: (h * Duration.millisecondsPerHour / rules.speed).round());

/// Détection : la composition est fixée selon les points actuels.
RaidStep detectRaid(GameState s, RaidDetected e, Rules rules) {
  final random = math.Random(e.seed);
  return (
    state: s,
    next: RaidArrival(
      id: e.id,
      planetId: e.planetId,
      dueAt: e.arrivalAt,
      detectedAt: e.dueAt,
      fleet: pirateFleet(points(s, rules), rules.data, random),
      seed: random.nextInt(1 << 31),
    ),
    report: null,
  );
}

/// Arrivée : combat contre les unités de la planète, pillage si les pirates gagnent,
/// défenses perdues retirées, raid suivant planifié.
RaidStep resolveRaid(GameState s, RaidArrival e, Rules rules) {
  final data = rules.data;
  final random = math.Random(e.seed);
  final planet = s.planet;
  final attacker = CombatSide(units: e.fleet);
  final defender = CombatSide(units: planet.units, tech: s.research);
  final result = simulateCombat(data, attacker, defender, random);
  final taken = result.winner == CombatWinner.attacker
      ? loot(planet.resources, cargoCapacity(result.attackerLeft, data), data.pirates.lootShare)
      : Resources.zero;
  final next = planet.copyWith(
    resources: planet.resources - taken,
    units: {for (final k in UnitKind.values) k: result.defenderLeft[k] ?? 0},
  );
  return (
    state: s.copyWith(planet: next),
    next: _nextRaid(e.id, e.planetId, e.dueAt, random, rules),
    report: RaidReport.fromCombat(
      result,
      at: e.dueAt,
      loot: taken,
      attackerStrength: SideStrength.of(data, attacker),
      defenderStrength: SideStrength.of(data, defender),
    ),
  );
}

RaidDetected _nextRaid(int id, int planetId, DateTime after, math.Random random, Rules rules) {
  final cfg = rules.data.pirates;
  final delay =
      cfg.intervalHoursMin + random.nextDouble() * (cfg.intervalHoursMax - cfg.intervalHoursMin);
  final arrival = after.add(_hours(delay, rules));
  return RaidDetected(
    id: id,
    planetId: planetId,
    dueAt: arrival.subtract(_hours(cfg.warningMinutes / 60, rules)),
    arrivalAt: arrival,
    seed: random.nextInt(1 << 31),
  );
}

/// Raid en attente (détecté ou non).
GameEvent? pendingRaid(GameState s) =>
    s.pending.where((e) => e is RaidDetected || e is RaidArrival).firstOrNull;

/// Planifie le premier raid si aucun n'est en attente.
GameState ensureRaidScheduled(
  GameState s,
  DateTime now,
  Rules rules, {
  required int seed,
  required int eventId,
}) {
  if (pendingRaid(s) != null) return s;
  final raid = _nextRaid(eventId, s.planet.id, now, math.Random(seed), rules);
  return s.copyWith(pending: [...s.pending, raid]);
}

/// Debug : avance le raid en attente pour qu'il soit détecté à [now].
GameState raidNow(GameState s, DateTime now, Rules rules) {
  final raid = pendingRaid(s);
  if (raid == null) return s;
  final seed = switch (raid) {
    RaidDetected(:final seed) || RaidArrival(:final seed) => seed,
    _ => 0,
  };
  final warning = _hours(rules.data.pirates.warningMinutes / 60, rules);
  final replaced = RaidDetected(
    id: raid.id,
    planetId: raid.planetId,
    dueAt: now,
    arrivalAt: now.add(warning),
    seed: seed,
  );
  return s.copyWith(pending: [for (final e in s.pending) e.id == raid.id ? replaced : e]);
}
