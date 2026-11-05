import 'events.dart';
import 'game_data.dart';
import 'planet.dart';
import 'resources.dart';
import 'rules.dart';

/// État complet d'une partie (V0 : une planète) et ses événements en attente.
class GameState {
  GameState({required this.planet, required List<GameEvent> pending})
    : pending = List.unmodifiable([...pending]..sort(GameEvent.compare));

  final Planet planet;

  /// Événements non encore appliqués, triés par (dueAt, id).
  final List<GameEvent> pending;

  BuildingDone? get currentConstruction => pending.whereType<BuildingDone>().firstOrNull;
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
  var planet = state.planet;
  if (!now.isAfter(planet.lastUpdate)) return AdvanceResult(state, const []);

  final applied = <GameEvent>[];
  final remaining = <GameEvent>[];
  for (final event in state.pending) {
    if (event.dueAt.isAfter(now)) {
      remaining.add(event);
      continue;
    }
    planet = _produceUntil(planet, event.dueAt, rules);
    planet = _apply(planet, event);
    applied.add(event);
  }
  planet = _produceUntil(planet, now, rules);
  return AdvanceResult(GameState(planet: planet, pending: remaining), applied);
}

Planet _produceUntil(Planet planet, DateTime t, Rules rules) {
  if (!t.isAfter(planet.lastUpdate)) return planet;
  return planet.copyWith(
    resources: rules.produce(planet, t.difference(planet.lastUpdate)),
    lastUpdate: t,
  );
}

Planet _apply(Planet planet, GameEvent event) => switch (event) {
  BuildingDone(:final building, :final targetLevel) => planet.withLevel(building, targetLevel),
};

/// Raison pour laquelle une construction est impossible.
sealed class BuildBlock {
  const BuildBlock();
}

class QueueBusy extends BuildBlock {
  const QueueBusy(this.current);

  final BuildingDone current;
}

class NotEnoughResources extends BuildBlock {
  const NotEnoughResources(this.missing);

  final Resources missing;
}

/// Vérifie si [kind] peut être lancé sur un état déjà avancé à l'instant courant.
BuildBlock? checkBuild(GameState state, BuildingKind kind, Rules rules) {
  final current = state.currentConstruction;
  if (current != null) return QueueBusy(current);
  final cost = rules.cost(kind, state.planet.level(kind) + 1);
  if (!state.planet.resources.covers(cost)) {
    return NotEnoughResources(state.planet.resources.missingFor(cost));
  }
  return null;
}

sealed class BuildOutcome {
  const BuildOutcome(this.state);

  final GameState state;
}

class BuildStarted extends BuildOutcome {
  const BuildStarted(super.state, this.event);

  final BuildingDone event;
}

class BuildRejected extends BuildOutcome {
  const BuildRejected(super.state, this.reason);

  final BuildBlock reason;
}

/// Lance la construction du niveau suivant de [kind] à [now].
/// Avance d'abord l'état jusqu'à [now] ; les ressources sont débitées immédiatement.
/// [eventId] est attribué par la couche de persistance.
BuildOutcome startBuilding(
  GameState state,
  BuildingKind kind,
  DateTime now,
  Rules rules, {
  required int eventId,
}) {
  final advanced = advance(state, now, rules).state;
  final block = checkBuild(advanced, kind, rules);
  if (block != null) return BuildRejected(advanced, block);

  final planet = advanced.planet;
  final target = planet.level(kind) + 1;
  final cost = rules.cost(kind, target);
  final duration = rules.buildDuration(
    cost,
    roboticsLevel: planet.level(BuildingKind.roboticsFactory),
  );
  final event = BuildingDone(
    id: eventId,
    planetId: planet.id,
    startedAt: now,
    dueAt: now.add(duration),
    building: kind,
    targetLevel: target,
    cost: cost,
  );
  return BuildStarted(
    GameState(
      planet: planet.copyWith(resources: planet.resources - cost),
      pending: [...advanced.pending, event],
    ),
    event,
  );
}

/// Annule la construction [eventId] avec remboursement intégral (le stock peut alors
/// dépasser la capacité). Sans effet si l'événement n'est plus en attente.
GameState cancelBuilding(GameState state, int eventId, DateTime now, Rules rules) {
  final advanced = advance(state, now, rules).state;
  final event = advanced.pending.whereType<BuildingDone>().where((e) => e.id == eventId).firstOrNull;
  if (event == null) return advanced;
  return GameState(
    planet: advanced.planet.copyWith(resources: advanced.planet.resources + event.cost),
    pending: advanced.pending.where((e) => e.id != eventId).toList(),
  );
}
