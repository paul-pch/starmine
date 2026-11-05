import 'events.dart';
import 'game_data.dart';
import 'planet.dart';
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
  const AdvanceResult(this.state, this.applied);

  final GameState state;

  /// Événements appliqués pendant ce rattrapage, dans l'ordre.
  final List<GameEvent> applied;
}

/// Avance la simulation jusqu'à [now], événement par événement :
/// production jusqu'à l'échéance, application, puis production jusqu'à [now].
/// Fonction pure. Un [now] antérieur à `lastUpdate` (horloge reculée) ne fait rien.
AdvanceResult advance(GameState state, DateTime now, Rules rules) {
  if (!now.isAfter(state.planet.lastUpdate)) return AdvanceResult(state, const []);

  var current = state;
  final applied = <GameEvent>[];
  final remaining = <GameEvent>[];
  for (final event in state.pending) {
    if (event.dueAt.isAfter(now)) {
      remaining.add(event);
      continue;
    }
    current = _produceUntil(current, event.dueAt, rules);
    current = _apply(current, event);
    applied.add(event);
  }
  current = _produceUntil(current, now, rules).copyWith(pending: remaining);
  return AdvanceResult(current, applied);
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

GameState _apply(GameState s, GameEvent event) => switch (event) {
  BuildingDone(:final building, :final targetLevel) => s.copyWith(
    planet: s.planet.withLevel(building, targetLevel),
  ),
  ResearchDone(:final tech, :final targetLevel) => s.copyWith(
    research: {...s.research, tech: targetLevel},
  ),
};

// --- Vérifications -----------------------------------------------------------

/// Raison pour laquelle une construction ou une recherche est impossible.
sealed class OrderBlock {
  const OrderBlock();
}

/// La file concernée (construction ou recherche) est occupée.
class QueueBusy extends OrderBlock {
  const QueueBusy(this.current);

  final OrderDone current;
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
Map<Unlockable, int> missingRequirements(GameState state, Unlockable item, Rules rules) => {
  for (final e in rules.data.spec(item).requires.entries)
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
