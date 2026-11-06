import 'dart:math' as math;

import 'events.dart';
import 'game_data.dart';
import 'planet.dart';
import 'raid.dart';
import 'resources.dart';
import 'rules.dart';

/// État complet d'une partie (une planète), technologies et événements en attente.
class GameState {
  GameState({
    required this.planet,
    TechLevels research = const {},
    required List<GameEvent> pending,
  }) : research = Map.unmodifiable({for (final k in TechKind.values) k: research[k] ?? 0}),
       pending = List<GameEvent>.unmodifiable(<GameEvent>[...pending]..sort(GameEvent.compare));

  final Planet planet;

  /// Niveaux de technologie, globaux à la partie.
  final TechLevels research;

  /// Événements non encore appliqués, triés par (dueAt, id).
  final List<GameEvent> pending;

  BuildingDone? get currentConstruction => pending.whereType<BuildingDone>().firstOrNull;

  ResearchDone? get currentResearch => pending.whereType<ResearchDone>().firstOrNull;

  ShipyardBatch? get currentBatch => pending.whereType<ShipyardBatch>().firstOrNull;

  int levelOf(Unlockable item) => switch (item) {
    BuildingKind() => planet.level(item),
    TechKind() => research[item]!,
  };

  GameState copyWith({Planet? planet, TechLevels? research, List<GameEvent>? pending}) => GameState(
    planet: planet ?? this.planet,
    research: research ?? this.research,
    pending: pending ?? this.pending,
  );
}

class AdvanceResult {
  const AdvanceResult(this.state, this.applied, [this.reports = const []]);

  final GameState state;

  /// Événements appliqués pendant ce rattrapage, dans l'ordre.
  final List<GameEvent> applied;

  /// Rapports des raids résolus pendant ce rattrapage.
  final List<RaidReport> reports;
}

/// Avance la simulation jusqu'à [now], événement par événement :
/// production jusqu'à l'échéance, application, puis production jusqu'à [now].
/// Fonction pure. Un [now] antérieur à `lastUpdate` (horloge reculée) ne fait rien.
AdvanceResult advance(GameState state, DateTime now, Rules rules) {
  if (!now.isAfter(state.planet.lastUpdate)) return AdvanceResult(state, const []);

  var current = state;
  final applied = <GameEvent>[];
  final reports = <RaidReport>[];
  final queue = [...state.pending];
  while (queue.isNotEmpty && !queue.first.dueAt.isAfter(now)) {
    final event = queue.removeAt(0);
    current = _produceUntil(current, event.dueAt, rules);
    final step = _apply(current, event, rules);
    current = step.state;
    applied.add(event);
    if (step.report case final report?) reports.add(report);
    // Événement suivant de la même chaîne (lot du chantier, raid), même id.
    if (step.next case final next?) {
      queue
        ..add(next)
        ..sort(GameEvent.compare);
    }
  }
  current = _produceUntil(current, now, rules).copyWith(pending: queue);
  return AdvanceResult(current, applied, reports);
}

GameState _produceUntil(GameState s, DateTime t, Rules rules) {
  final planet = s.planet;
  if (!t.isAfter(planet.lastUpdate)) return s;
  return s.copyWith(
    planet: planet.copyWith(
      resources: rules.produce(planet, s.research, t.difference(planet.lastUpdate)),
      lastUpdate: t,
    ),
  );
}

({GameState state, GameEvent? next, RaidReport? report}) _apply(
  GameState s,
  GameEvent event,
  Rules rules,
) => switch (event) {
  BuildingDone(:final building, :final targetLevel) => (
    state: s.copyWith(planet: s.planet.withLevel(building, targetLevel)),
    next: null,
    report: null,
  ),
  ResearchDone(:final tech, :final targetLevel) => (
    state: s.copyWith(research: {...s.research, tech: targetLevel}),
    next: null,
    report: null,
  ),
  ShipyardBatch(:final unit, :final next) => (
    state: s.copyWith(
      planet: s.planet.copyWith(units: {...s.planet.units, unit: s.planet.count(unit) + 1}),
    ),
    next: next,
    report: null,
  ),
  RaidDetected() => detectRaid(s, event, rules),
  RaidArrival() => resolveRaid(s, event, rules),
};

// --- Vérifications -----------------------------------------------------------

/// Raison pour laquelle une construction ou une recherche est impossible.
sealed class OrderBlock {
  const OrderBlock();
}

/// La file concernée (construction ou recherche) est occupée.
class QueueBusy extends OrderBlock {
  const QueueBusy(this.current);

  /// Ordre en cours : [OrderDone] ou [ShipyardBatch].
  final GameEvent current;
}

/// Règle OGame : le chantier ne peut pas être agrandi pendant un lot, et inversement.
class ShipyardBusy extends OrderBlock {
  const ShipyardBusy();
}

/// Limite par planète atteinte (dômes : 1).
class MaxReached extends OrderBlock {
  const MaxReached(this.max);

  final int max;
}

/// Unité non constructible dans cette version (vaisseaux avant la V3).
class NotBuildable extends OrderBlock {
  const NotBuildable();
}

/// Règle OGame : le labo ne peut pas être agrandi pendant une recherche, et inversement.
class LabBusy extends OrderBlock {
  const LabBusy();
}

class RequirementsNotMet extends OrderBlock {
  const RequirementsNotMet(this.missing);

  /// Prérequis non satisfaits : élément → niveau requis.
  final Map<Unlockable, int> missing;
}

class NotEnoughResources extends OrderBlock {
  const NotEnoughResources(this.missing);

  final Resources missing;
}

/// Prérequis non satisfaits de [item] (vide si tout est bon).
Map<Unlockable, int> missingRequirements(GameState state, Unlockable item, Rules rules) =>
    unmet(state, rules.data.spec(item).requires);

/// Prérequis de [requires] non satisfaits dans [state].
Map<Unlockable, int> unmet(GameState state, Map<Unlockable, int> requires) => {
  for (final e in requires.entries)
    if (state.levelOf(e.key) < e.value) e.key: e.value,
};

/// Vérifie si [item] peut être lancé sur un état déjà avancé à l'instant courant.
/// Ordre des raisons : file, labo, prérequis, ressources.
OrderBlock? checkOrder(GameState state, Unlockable item, Rules rules) {
  switch (item) {
    case BuildingKind():
      final current = state.currentConstruction;
      if (current != null) return QueueBusy(current);
      if (item == BuildingKind.researchLab && state.currentResearch != null) return const LabBusy();
      if (item == BuildingKind.shipyard && state.currentBatch != null) return const ShipyardBusy();
    case TechKind():
      final current = state.currentResearch;
      if (current != null) return QueueBusy(current);
      if (state.currentConstruction?.building == BuildingKind.researchLab) return const LabBusy();
  }
  final missing = missingRequirements(state, item, rules);
  if (missing.isNotEmpty) return RequirementsNotMet(missing);
  final cost = rules.cost(item, state.levelOf(item) + 1);
  if (!state.planet.resources.covers(cost)) {
    return NotEnoughResources(state.planet.resources.missingFor(cost));
  }
  return null;
}

/// Durée du prochain niveau de [item] dans l'état courant.
Duration orderDuration(GameState state, Unlockable item, Rules rules) {
  final cost = rules.cost(item, state.levelOf(item) + 1);
  final p = state.planet;
  return switch (item) {
    BuildingKind() => rules.buildDuration(
      cost,
      roboticsLevel: p.level(BuildingKind.roboticsFactory),
      naniteLevel: p.level(BuildingKind.naniteFactory),
    ),
    TechKind() => rules.researchDuration(cost, labLevel: p.level(BuildingKind.researchLab)),
  };
}

// --- Commandes ---------------------------------------------------------------

sealed class OrderOutcome {
  const OrderOutcome(this.state);

  final GameState state;
}

class OrderStarted extends OrderOutcome {
  const OrderStarted(super.state, this.event);

  final OrderDone event;
}

class OrderRejected extends OrderOutcome {
  const OrderRejected(super.state, this.reason);

  final OrderBlock reason;
}

/// Lance le niveau suivant de [item] (construction ou recherche) à [now].
/// Avance d'abord l'état jusqu'à [now] ; les ressources sont débitées immédiatement.
/// [eventId] est attribué par la couche de persistance.
OrderOutcome startOrder(
  GameState state,
  Unlockable item,
  DateTime now,
  Rules rules, {
  required int eventId,
}) {
  final advanced = advance(state, now, rules).state;
  final block = checkOrder(advanced, item, rules);
  if (block != null) return OrderRejected(advanced, block);

  final planet = advanced.planet;
  final target = advanced.levelOf(item) + 1;
  final cost = rules.cost(item, target);
  final dueAt = now.add(orderDuration(advanced, item, rules));
  final OrderDone event = switch (item) {
    BuildingKind() => BuildingDone(
      id: eventId,
      planetId: planet.id,
      startedAt: now,
      dueAt: dueAt,
      building: item,
      targetLevel: target,
      cost: cost,
    ),
    TechKind() => ResearchDone(
      id: eventId,
      planetId: planet.id,
      startedAt: now,
      dueAt: dueAt,
      tech: item,
      targetLevel: target,
      cost: cost,
    ),
  };
  return OrderStarted(
    advanced.copyWith(
      planet: planet.copyWith(resources: planet.resources - cost),
      pending: [...advanced.pending, event],
    ),
    event,
  );
}

/// Annule l'ordre [eventId] avec remboursement intégral (le stock peut alors dépasser la
/// capacité). Sans effet si l'événement n'est plus en attente.
GameState cancelOrder(GameState state, int eventId, DateTime now, Rules rules) {
  final advanced = advance(state, now, rules).state;
  final event = advanced.pending.whereType<OrderDone>().where((e) => e.id == eventId).firstOrNull;
  if (event == null) return advanced;
  return advanced.copyWith(
    planet: advanced.planet.copyWith(resources: advanced.planet.resources + event.cost),
    pending: advanced.pending.where((e) => e.id != eventId).toList(),
  );
}

/// Règle la production de [kind] à [percent] % (0 à 100, pas de 10).
/// Le passé est soldé à l'ancien réglage.
GameState setProductionPercent(
  GameState state,
  BuildingKind kind,
  int percent,
  DateTime now,
  Rules rules,
) {
  if (!rules.data[kind].adjustable) {
    throw ArgumentError('${kind.key} ne se règle pas');
  }
  if (percent < 0 || percent > 100 || percent % 10 != 0) {
    throw ArgumentError.value(percent, 'percent', 'de 0 à 100 par pas de 10');
  }
  final advanced = advance(state, now, rules).state;
  return advanced.copyWith(
    planet: advanced.planet.copyWith(percents: {...advanced.planet.percents, kind: percent}),
  );
}

// --- Chantier ----------------------------------------------------------------

/// Durée de production d'une unité de [unit] dans l'état courant.
Duration unitDuration(GameState state, UnitKind unit, Rules rules) {
  final p = state.planet;
  return rules.unitDuration(
    rules.data.unit(unit).baseCost,
    shipyardLevel: p.level(BuildingKind.shipyard),
    naniteLevel: p.level(BuildingKind.naniteFactory),
  );
}

/// Nombre maximal commandable maintenant : ressources et limite par planète.
int maxOrderable(GameState state, UnitKind unit, Rules rules) {
  final spec = rules.data.unit(unit);
  var n = 1 << 30;
  for (final k in ResourceKind.values) {
    final c = spec.baseCost[k];
    if (c > 0) n = math.min(n, (state.planet.resources[k] / c).floor());
  }
  final max = spec.maxCount;
  if (max != null) n = math.min(n, math.max(0, max - state.planet.count(unit)));
  return math.max(0, n);
}

/// Vérifie une commande de [count] unités sur un état déjà avancé.
/// Ordre des raisons : constructible, file, chantier, prérequis, limite, ressources.
OrderBlock? checkBatch(GameState state, UnitKind unit, int count, Rules rules) {
  assert(count >= 1);
  final spec = rules.data.unit(unit);
  if (!spec.defense) return const NotBuildable();
  final current = state.currentBatch;
  if (current != null) return QueueBusy(current);
  if (state.currentConstruction?.building == BuildingKind.shipyard) return const ShipyardBusy();
  final missing = unmet(state, spec.requires);
  if (missing.isNotEmpty) return RequirementsNotMet(missing);
  final max = spec.maxCount;
  if (max != null && state.planet.count(unit) + count > max) return MaxReached(max);
  final cost = spec.baseCost * count.toDouble();
  if (!state.planet.resources.covers(cost)) {
    return NotEnoughResources(state.planet.resources.missingFor(cost));
  }
  return null;
}

class BatchStarted extends OrderOutcome {
  const BatchStarted(super.state, this.batch);

  final ShipyardBatch batch;
}

/// Commande [count] unités de [unit] à [now], payées immédiatement, livrées une à une.
OrderOutcome startBatch(
  GameState state,
  UnitKind unit,
  int count,
  DateTime now,
  Rules rules, {
  required int eventId,
}) {
  final advanced = advance(state, now, rules).state;
  final block = checkBatch(advanced, unit, count, rules);
  if (block != null) return OrderRejected(advanced, block);
  final spec = rules.data.unit(unit);
  final duration = unitDuration(advanced, unit, rules);
  final batch = ShipyardBatch(
    id: eventId,
    planetId: advanced.planet.id,
    dueAt: now.add(duration),
    startedAt: now,
    unit: unit,
    ordered: count,
    remaining: count,
    unitDuration: duration,
    unitCost: spec.baseCost,
  );
  final planet = advanced.planet;
  return BatchStarted(
    advanced.copyWith(
      planet: planet.copyWith(resources: planet.resources - spec.baseCost * count.toDouble()),
      pending: [...advanced.pending, batch],
    ),
    batch,
  );
}

// --- État des files ----------------------------------------------------------------

/// État d'une file pour l'affichage (pastilles, messages).
enum SlotStatus {
  /// Rien ne tourne : on peut lancer quelque chose.
  free,

  /// Un ordre est en cours.
  busy,

  /// Bloquée par l'agrandissement du bâtiment qui l'abrite (labo, chantier).
  blocked,

  /// Bâtiment requis pas encore construit.
  unavailable,
}

enum Slot { construction, research, shipyard }

SlotStatus slotStatus(GameState s, Slot slot) {
  final upgrading = s.currentConstruction?.building;
  return switch (slot) {
    Slot.construction => s.currentConstruction == null ? SlotStatus.free : SlotStatus.busy,
    Slot.research => _slot(
      built: s.planet.level(BuildingKind.researchLab) > 0,
      busy: s.currentResearch != null,
      blocked: upgrading == BuildingKind.researchLab,
    ),
    Slot.shipyard => _slot(
      built: s.planet.level(BuildingKind.shipyard) > 0,
      busy: s.currentBatch != null,
      blocked: upgrading == BuildingKind.shipyard,
    ),
  };
}

SlotStatus _slot({required bool built, required bool busy, required bool blocked}) {
  if (busy) return SlotStatus.busy;
  if (!built) return SlotStatus.unavailable;
  if (blocked) return SlotStatus.blocked;
  return SlotStatus.free;
}
