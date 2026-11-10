import 'dart:math' as math;

import 'events.dart';
import 'fleet.dart';
import 'game_data.dart';
import 'planet.dart';
import 'raid.dart';
import 'resources.dart';
import 'rules.dart';
import 'story.dart';

/// État complet d'une partie (une planète), technologies et événements en attente.
class GameState {
  GameState({
    required this.planet,
    TechLevels research = const {},
    required List<GameEvent> pending,
    Map<OfficerKind, int> officers = const {},
    Map<Counter, int> counters = const {},
    List<QueuedOrder> queue = const [],
    List<ActiveEffect> effects = const [],
    List<PirateBase> bases = const [],
  }) : bases = List<PirateBase>.unmodifiable(bases),
       queue = List<QueuedOrder>.unmodifiable(queue),
       effects = List<ActiveEffect>.unmodifiable(effects),
       research = Map.unmodifiable({for (final k in TechKind.values) k: research[k] ?? 0}),
       officers = Map.unmodifiable({for (final k in OfficerKind.values) k: officers[k] ?? 0}),
       counters = Map.unmodifiable({for (final k in Counter.values) k: counters[k] ?? 0}),
       pending = List<GameEvent>.unmodifiable(<GameEvent>[...pending]..sort(GameEvent.compare));

  final Planet planet;

  /// Niveaux de technologie, globaux à la partie.
  final TechLevels research;

  /// Niveau de chaque officier (0 = pas encore débloqué), spec 12.
  final Map<OfficerKind, int> officers;

  /// Compteurs de progression (raids repoussés…), tenus par `advance()`.
  final Map<Counter, int> counters;

  /// Ordres en attente, toutes files confondues, dans l'ordre d'ajout (spec 13). Rien n'est
  /// payé tant qu'un ordre attend.
  final List<QueuedOrder> queue;

  /// Effets temporaires des événements en cours (spec 14), retirés à leur fin par
  /// `advance()`.
  final List<ActiveEffect> effects;

  /// Bases pirates (V3b), dans l'ordre du catalogue.
  final List<PirateBase> bases;

  /// Ordres en attente de [slot], dans l'ordre.
  List<QueuedOrder> queued(Slot slot) => [
    for (final q in queue)
      if (q.slot == slot) q,
  ];

  /// Ordre en cours dans [slot] : [OrderDone] ou [ShipyardBatch].
  GameEvent? current(Slot slot) => switch (slot) {
    Slot.construction => currentConstruction,
    Slot.research => currentResearch,
    Slot.shipyard => currentBatch,
  };

  /// Événements non encore appliqués, triés par (dueAt, id).
  final List<GameEvent> pending;

  BuildingDone? get currentConstruction => pending.whereType<BuildingDone>().firstOrNull;

  ResearchDone? get currentResearch => pending.whereType<ResearchDone>().firstOrNull;

  ShipyardBatch? get currentBatch => pending.whereType<ShipyardBatch>().firstOrNull;

  int levelOf(Unlockable item) => switch (item) {
    BuildingKind() => planet.level(item),
    TechKind() => research[item]!,
  };

  /// Bonus des officiers. Tous les officiers débloqués sont actifs ; un nombre limité de
  /// places actives est une option d'équilibrage pour plus tard (spec 12).
  Modifiers modifiers(GameData data) {
    var mine = 0.0;
    var research = 0.0;
    var build = 0.0;
    var rebuild = 0.0;
    final extra = {for (final k in Slot.values) k: 0.0};
    var byResource = Resources.zero;
    var energy = 1.0;
    var expeditions = 0.0;
    for (final e in effects) {
      switch (e.type) {
        case StoryEffectType.production:
          byResource =
              byResource + Resources.of((k) => e.resource == null || e.resource == k ? e.value : 0);
        case StoryEffectType.energy:
          energy *= 1 + e.value;
        case StoryEffectType.shorten ||
            StoryEffectType.stock ||
            StoryEffectType.gain ||
            StoryEffectType.raid ||
            StoryEffectType.units ||
            StoryEffectType.debris ||
            StoryEffectType.delayed ||
            StoryEffectType.gamble:
          break;
      }
    }
    for (final spec in data.officers.values) {
      final value = spec.perLevel * (officers[spec.kind] ?? 0);
      switch (spec.bonus) {
        case OfficerBonus.mineProduction:
          mine += value;
        case OfficerBonus.researchTime:
          research += value;
        case OfficerBonus.buildTime:
          build += value;
        case OfficerBonus.defenseRebuild:
          rebuild += value;
        case OfficerBonus.constructionQueue:
          extra[Slot.construction] = extra[Slot.construction]! + value;
        case OfficerBonus.researchQueue:
          extra[Slot.research] = extra[Slot.research]! + value;
        case OfficerBonus.shipyardQueue:
          extra[Slot.shipyard] = extra[Slot.shipyard]! + value;
        case OfficerBonus.expeditionSlots:
          expeditions += value;
      }
    }
    return Modifiers(
      mineProduction: mine,
      researchTime: research,
      buildTime: build,
      defenseRebuild: rebuild,
      constructionQueue: extra[Slot.construction]!.round(),
      researchQueue: extra[Slot.research]!.round(),
      shipyardQueue: extra[Slot.shipyard]!.round(),
      expeditionSlots: expeditions.round(),
      mineByResource: byResource,
      energyFactor: math.max(0, energy),
      productionFactor: data.startBoost.factor(economyPoints(this, Rules(data))),
    );
  }

  GameState copyWith({
    Planet? planet,
    TechLevels? research,
    List<GameEvent>? pending,
    Map<OfficerKind, int>? officers,
    Map<Counter, int>? counters,
    List<QueuedOrder>? queue,
    List<ActiveEffect>? effects,
    List<PirateBase>? bases,
  }) => GameState(
    planet: planet ?? this.planet,
    research: research ?? this.research,
    pending: pending ?? this.pending,
    officers: officers ?? this.officers,
    counters: counters ?? this.counters,
    queue: queue ?? this.queue,
    effects: effects ?? this.effects,
    bases: bases ?? this.bases,
  );
}

class AdvanceResult {
  const AdvanceResult(
    this.state,
    this.applied, [
    this.reports = const [],
    this.cancelled = const [],
    this.stories = const [],
  ]);

  final GameState state;

  /// Événements appliqués pendant ce rattrapage, dans l'ordre.
  final List<GameEvent> applied;

  /// Rapports des raids résolus pendant ce rattrapage.
  final List<RaidReport> reports;

  /// Files annulées : un ordre en attente n'a pas pu démarrer à son tour.
  final List<QueueCancelled> cancelled;

  /// Événements ponctuels survenus (spec 14).
  final List<StoryOutcome> stories;
}

/// Avance la simulation jusqu'à [now], événement par événement :
/// production jusqu'à l'échéance, application, puis production jusqu'à [now].
/// Fonction pure. Un [now] antérieur à `lastUpdate` (horloge reculée) ne fait rien.
AdvanceResult advance(GameState state, DateTime now, Rules rules) {
  if (!now.isAfter(state.planet.lastUpdate)) return AdvanceResult(state, const []);

  var current = state;
  final applied = <GameEvent>[];
  final reports = <RaidReport>[];
  final cancelled = <QueueCancelled>[];
  final stories = <StoryOutcome>[];
  final queue = [...state.pending];
  void schedule(GameEvent e) => queue
    ..add(e)
    ..sort(GameEvent.compare);
  while (queue.isNotEmpty && !queue.first.dueAt.isAfter(now)) {
    final event = queue.removeAt(0);
    current = _produceUntil(current, event.dueAt, rules).copyWith(pending: queue);
    final step = _apply(current, event, rules);
    current = step.state;
    applied.add(event);
    if (step.report case final report?) reports.add(report);
    if (step.story case final story?) stories.add(story);
    // Un événement peut déplacer des échéances (événement ponctuel : ordre raccourci, raid
    // avancé) : la file suit l'état.
    queue
      ..clear()
      ..addAll(current.pending);
    // Événement suivant de la même chaîne (lot du chantier, raid), même id.
    if (step.next case final next?) schedule(next);
    // Une file qui se libère démarre son prochain ordre en attente, à cet instant.
    final freed = switch (event) {
      BuildingDone() => Slot.construction,
      ResearchDone() => Slot.research,
      ShipyardBatch() when step.next == null => Slot.shipyard,
      _ => null,
    };
    if (freed != null) {
      final start = startNextQueued(current.copyWith(pending: queue), freed, event.dueAt, rules);
      current = start.state;
      if (start.started case final e?) schedule(e);
      if (start.cancelled case final c?) cancelled.add(c);
    }
  }
  current = _produceUntil(current, now, rules).copyWith(pending: queue);
  return AdvanceResult(current, applied, reports, cancelled, stories);
}

/// Production jusqu'à [t], découpée à la fin de chaque effet temporaire (retiré à cet
/// instant) : exacte même app fermée.
GameState _produceUntil(GameState s, DateTime t, Rules rules) {
  var cur = s;
  while (true) {
    final planet = cur.planet;
    if (!t.isAfter(planet.lastUpdate)) return cur;
    var until = t;
    for (final e in cur.effects) {
      if (e.endsAt.isBefore(until) && e.endsAt.isAfter(planet.lastUpdate)) until = e.endsAt;
    }
    // Versements différés échus à [until] : ajoutés au stock, au-delà du stockage.
    var delivered = Resources.zero;
    for (final e in cur.effects) {
      if (e.type == StoryEffectType.delayed && !e.endsAt.isAfter(until)) {
        delivered = delivered + Resources.of((k) => e.resource == k ? e.value : 0);
      }
    }
    cur = cur.copyWith(
      planet: planet.copyWith(
        resources:
            rules.produce(
              planet,
              cur.research,
              until.difference(planet.lastUpdate),
              cur.modifiers(rules.data),
            ) +
            delivered,
        lastUpdate: until,
      ),
      effects: [
        for (final e in cur.effects)
          if (e.endsAt.isAfter(until)) e,
      ],
    );
  }
}

typedef _Step = ({GameState state, GameEvent? next, RaidReport? report, StoryOutcome? story});

_Step _raid(RaidStep r) => (state: r.state, next: r.next, report: r.report, story: null);

_Step _story(StoryStep r) => (state: r.state, next: r.next, report: null, story: r.outcome);

_Step _apply(GameState s, GameEvent event, Rules rules) => switch (event) {
  BuildingDone(:final building, :final targetLevel) => (
    state: s.copyWith(planet: s.planet.withLevel(building, targetLevel)),
    next: null,
    report: null,
    story: null,
  ),
  ResearchDone(:final tech, :final targetLevel) => (
    state: s.copyWith(research: {...s.research, tech: targetLevel}),
    next: null,
    report: null,
    story: null,
  ),
  ShipyardBatch(:final unit, :final next) => (
    state: s.copyWith(
      planet: s.planet.copyWith(units: {...s.planet.units, unit: s.planet.count(unit) + 1}),
    ),
    next: next,
    report: null,
    story: null,
  ),
  RaidDetected() => _raid(detectRaid(s, event, rules)),
  RaidArrival() => _raid(resolveRaid(s, event, rules)),
  StoryEvent() => _story(applyStory(s, event, rules)),
  RecycleMission() => (
    state: recycleReturn(s, event, rules),
    next: null,
    report: null,
    story: null,
  ),
  FleetMission(returning: true) => (
    state: missionReturn(s, event),
    next: null,
    report: null,
    story: null,
  ),
  FleetMission() => switch (missionArrive(s, event, rules)) {
    final r => (state: r.state, next: r.next, report: r.report, story: null),
  },
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

/// File d'attente pleine (spec 13) : ordre en cours compris, [capacity] ordres au plus.
class QueueFull extends OrderBlock {
  const QueueFull(this.capacity);

  final int capacity;
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
/// [level] : niveau de départ, par défaut le niveau actuel (file d'attente : niveau prévu).
Duration orderDuration(GameState state, Unlockable item, Rules rules, {int? level}) {
  final cost = rules.cost(item, (level ?? state.levelOf(item)) + 1);
  final p = state.planet;
  final mods = state.modifiers(rules.data);
  return switch (item) {
    BuildingKind() => rules.buildDuration(
      cost,
      roboticsLevel: p.level(BuildingKind.roboticsFactory),
      naniteLevel: p.level(BuildingKind.naniteFactory),
      reduction: mods.buildTime,
    ),
    TechKind() => rules.researchDuration(
      cost,
      labLevel: p.level(BuildingKind.researchLab),
      reduction: mods.researchTime,
    ),
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

/// Ordre ajouté à la file d'attente de sa file occupée ; rien n'est payé.
class OrderQueued extends OrderOutcome {
  const OrderQueued(super.state, this.order);

  final QueuedOrder order;
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
  return _begin(advance(state, now, rules).state, item, now, rules, eventId: eventId);
}

/// Démarre [item] à [now] sur un état déjà avancé (commande directe ou file d'attente).
OrderOutcome _begin(
  GameState advanced,
  Unlockable item,
  DateTime now,
  Rules rules, {
  required int eventId,
}) {
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
GameState cancelOrder(GameState state, int eventId, DateTime now, Rules rules) =>
    cancelOrQueue(state, eventId, now, rules).state;

/// Annule [eventId] : un ordre en attente est retiré sans frais (rien n'est payé) ; l'ordre
/// en cours est remboursé et le suivant de sa file démarre tout de suite (spec 13).
({GameState state, QueueCancelled? cancelled}) cancelOrQueue(
  GameState state,
  int eventId,
  DateTime now,
  Rules rules,
) {
  final advanced = advance(state, now, rules).state;
  if (advanced.queue.any((q) => q.id == eventId)) {
    return (
      state: advanced.copyWith(
        queue: [
          for (final q in advanced.queue)
            if (q.id != eventId) q,
        ],
      ),
      cancelled: null,
    );
  }
  final event = advanced.pending.whereType<OrderDone>().where((e) => e.id == eventId).firstOrNull;
  if (event == null) return (state: advanced, cancelled: null);
  final refunded = advanced.copyWith(
    planet: advanced.planet.copyWith(resources: advanced.planet.resources + event.cost),
    pending: advanced.pending.where((e) => e.id != eventId).toList(),
  );
  final slot = event is BuildingDone ? Slot.construction : Slot.research;
  final start = startNextQueued(refunded, slot, now, rules);
  final started = start.started;
  return (
    state: started == null
        ? start.state
        : start.state.copyWith(pending: [...start.state.pending, started]),
    cancelled: start.cancelled,
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
  return _beginBatch(advance(state, now, rules).state, unit, count, now, rules, eventId: eventId);
}

OrderOutcome _beginBatch(
  GameState advanced,
  UnitKind unit,
  int count,
  DateTime now,
  Rules rules, {
  required int eventId,
}) {
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

// --- File d'attente (spec 13) ----------------------------------------------------

/// Ordre en attente dans une file occupée. [id] est l'id d'événement réservé à l'ajout,
/// repris par l'événement quand l'ordre démarre.
sealed class QueuedOrder {
  const QueuedOrder(this.id);

  final int id;

  Slot get slot;
}

/// Niveau suivant d'un bâtiment ou d'une techno.
class QueuedLevel extends QueuedOrder {
  const QueuedLevel(super.id, this.item);

  final Unlockable item;

  @override
  Slot get slot => item is BuildingKind ? Slot.construction : Slot.research;
}

/// Lot du chantier.
class QueuedBatch extends QueuedOrder {
  const QueuedBatch(super.id, this.unit, this.count);

  final UnitKind unit;
  final int count;

  @override
  Slot get slot => Slot.shipyard;
}

/// Une file annulée : [first] n'a pas pu démarrer à [at] pour [reason] ; [dropped] = tous
/// les ordres retirés de la file, [first] compris.
class QueueCancelled {
  const QueueCancelled({
    required this.slot,
    required this.at,
    required this.first,
    required this.reason,
    required this.dropped,
  });

  final Slot slot;
  final DateTime at;
  final QueuedOrder first;
  final OrderBlock reason;
  final List<QueuedOrder> dropped;
}

/// Nombre d'ordres de [slot], en cours compris : 1, plus le niveau de l'officier de la file.
int queueCapacity(GameState s, Slot slot, GameData data) {
  final m = s.modifiers(data);
  return 1 +
      switch (slot) {
        Slot.construction => m.constructionQueue,
        Slot.research => m.researchQueue,
        Slot.shipyard => m.shipyardQueue,
      };
}

/// Niveau qu'aura [item] une fois l'ordre en cours et la file terminés.
int projectedLevel(GameState s, Unlockable item) {
  var level = s.levelOf(item);
  for (final e in s.pending) {
    if (e is OrderDone && e.item == item) level++;
  }
  for (final q in s.queue) {
    if (q is QueuedLevel && q.item == item) level++;
  }
  return level;
}

/// Unités de [unit] une fois le lot en cours et la file livrés.
int projectedCount(GameState s, UnitKind unit) {
  var n = s.planet.count(unit);
  final batch = s.currentBatch;
  if (batch != null && batch.unit == unit) n += batch.remaining;
  for (final q in s.queue) {
    if (q is QueuedBatch && q.unit == unit) n += q.count;
  }
  return n;
}

Map<Unlockable, int> _unmetProjected(GameState s, Map<Unlockable, int> requires) => {
  for (final e in requires.entries)
    if (projectedLevel(s, e.key) < e.value) e.key: e.value,
};

OrderBlock? _checkQueueRoom(GameState s, Slot slot, Rules rules) {
  final capacity = queueCapacity(s, slot, rules.data);
  if (s.queued(slot).length + 1 < capacity) return null;
  return capacity == 1 ? QueueBusy(s.current(slot)!) : QueueFull(capacity);
}

/// Vérifie l'ajout de [item] à sa file occupée : place libre et prérequis remplis en
/// comptant les ordres placés avant. Les ressources ne sont pas vérifiées (payées au
/// démarrage).
OrderBlock? checkQueue(GameState s, Unlockable item, Rules rules) {
  final slot = item is BuildingKind ? Slot.construction : Slot.research;
  final room = _checkQueueRoom(s, slot, rules);
  if (room != null) return room;
  final missing = _unmetProjected(s, rules.data.spec(item).requires);
  return missing.isEmpty ? null : RequirementsNotMet(missing);
}

/// Comme [checkQueue], pour un lot du chantier.
OrderBlock? checkQueueBatch(GameState s, UnitKind unit, int count, Rules rules) {
  final spec = rules.data.unit(unit);
  final room = _checkQueueRoom(s, Slot.shipyard, rules);
  if (room != null) return room;
  final missing = _unmetProjected(s, spec.requires);
  if (missing.isNotEmpty) return RequirementsNotMet(missing);
  final max = spec.maxCount;
  if (max != null && projectedCount(s, unit) + count > max) return MaxReached(max);
  return null;
}

/// Vrai si un nouvel ordre de [slot] irait dans la file d'attente (file occupée).
bool wouldQueue(GameState s, Slot slot) => s.current(slot) != null;

/// Ce qui empêche de lancer ou de mettre en file [item] maintenant (`null` : possible).
OrderBlock? checkPlacement(GameState s, Unlockable item, Rules rules) {
  final slot = item is BuildingKind ? Slot.construction : Slot.research;
  return wouldQueue(s, slot) ? checkQueue(s, item, rules) : checkOrder(s, item, rules);
}

/// Comme [checkPlacement], pour [count] unités.
OrderBlock? checkBatchPlacement(GameState s, UnitKind unit, int count, Rules rules) =>
    wouldQueue(s, Slot.shipyard)
    ? checkQueueBatch(s, unit, count, rules)
    : checkBatch(s, unit, count, rules);

/// Lance [item] si sa file est libre, sinon l'ajoute à la file d'attente.
OrderOutcome placeOrder(
  GameState state,
  Unlockable item,
  DateTime now,
  Rules rules, {
  required int eventId,
}) {
  final advanced = advance(state, now, rules).state;
  final slot = item is BuildingKind ? Slot.construction : Slot.research;
  if (!wouldQueue(advanced, slot)) return _begin(advanced, item, now, rules, eventId: eventId);
  final block = checkQueue(advanced, item, rules);
  if (block != null) return OrderRejected(advanced, block);
  final order = QueuedLevel(eventId, item);
  return OrderQueued(advanced.copyWith(queue: [...advanced.queue, order]), order);
}

/// Lance le lot si le chantier est libre, sinon l'ajoute à la file d'attente.
OrderOutcome placeBatch(
  GameState state,
  UnitKind unit,
  int count,
  DateTime now,
  Rules rules, {
  required int eventId,
}) {
  final advanced = advance(state, now, rules).state;
  if (!wouldQueue(advanced, Slot.shipyard)) {
    return _beginBatch(advanced, unit, count, now, rules, eventId: eventId);
  }
  final block = checkQueueBatch(advanced, unit, count, rules);
  if (block != null) return OrderRejected(advanced, block);
  final order = QueuedBatch(eventId, unit, count);
  return OrderQueued(advanced.copyWith(queue: [...advanced.queue, order]), order);
}

/// Démarre le premier ordre en attente de [slot] à [at] (file libérée), payé à cet instant.
/// S'il ne peut pas démarrer (ressources, prérequis, labo ou chantier occupé, limite), toute
/// la file est annulée. [s] est avancé à [at] ; l'événement démarré n'est pas dans
/// `state.pending`, à l'appelant de le planifier.
({GameState state, GameEvent? started, QueueCancelled? cancelled}) startNextQueued(
  GameState s,
  Slot slot,
  DateTime at,
  Rules rules,
) {
  final waiting = s.queued(slot);
  if (waiting.isEmpty || s.current(slot) != null) return (state: s, started: null, cancelled: null);
  final first = waiting.first;
  final rest = s.copyWith(
    queue: [
      for (final q in s.queue)
        if (!identical(q, first)) q,
    ],
  );
  final outcome = switch (first) {
    QueuedLevel(:final item) => _begin(rest, item, at, rules, eventId: first.id),
    QueuedBatch(:final unit, :final count) => _beginBatch(
      rest,
      unit,
      count,
      at,
      rules,
      eventId: first.id,
    ),
  };
  switch (outcome) {
    case OrderStarted(:final event):
      return (
        state: outcome.state.copyWith(pending: rest.pending),
        started: event,
        cancelled: null,
      );
    case BatchStarted(:final batch):
      return (
        state: outcome.state.copyWith(pending: rest.pending),
        started: batch,
        cancelled: null,
      );
    case OrderRejected(:final reason):
      return (
        state: s.copyWith(
          queue: [
            for (final q in s.queue)
              if (q.slot != slot) q,
          ],
        ),
        started: null,
        cancelled: QueueCancelled(
          slot: slot,
          at: at,
          first: first,
          reason: reason,
          dropped: waiting,
        ),
      );
    case OrderQueued():
      throw StateError('un démarrage ne met pas en file');
  }
}

// --- Recyclage du champ de débris (spec 15) ------------------------------------------

/// Raison pour laquelle une collecte est impossible.
enum RecycleBlock { noDebris, noRecycler, busy }

/// Mission de recyclage en cours.
RecycleMission? currentRecycling(GameState s) => s.pending.whereType<RecycleMission>().firstOrNull;

RecycleBlock? checkRecycle(GameState s, int count) {
  if (currentRecycling(s) != null) return RecycleBlock.busy;
  final d = s.planet.debris;
  if (d.metal + d.crystal < 1) return RecycleBlock.noDebris;
  if (count < 1 || s.planet.count(UnitKind.recycler) < count) return RecycleBlock.noRecycler;
  return null;
}

/// Envoie [count] recycleurs collecter le champ de la planète : absents (ils ne combattent
/// pas) pendant `debris.collect_hours`.
({GameState state, RecycleBlock? block}) startRecycling(
  GameState state,
  int count,
  DateTime now,
  Rules rules, {
  required int eventId,
}) {
  final advanced = advance(state, now, rules).state;
  final block = checkRecycle(advanced, count);
  if (block != null) return (state: advanced, block: block);
  final ms = (rules.data.debris.collectHours * Duration.millisecondsPerHour / rules.speed).round();
  final mission = RecycleMission(
    id: eventId,
    planetId: advanced.planet.id,
    dueAt: now.add(Duration(milliseconds: ms)),
    startedAt: now,
    recyclers: count,
  );
  final p = advanced.planet;
  return (
    state: advanced.copyWith(
      planet: p.copyWith(
        units: {...p.units, UnitKind.recycler: p.count(UnitKind.recycler) - count},
      ),
      pending: [...advanced.pending, mission],
    ),
    block: null,
  );
}

/// Ce que [recyclers] recycleurs rapportent de [debris] : tout si la soute suffit, sinon au
/// prorata du métal et du cristal.
Resources recycleLoad(Resources debris, int recyclers, GameData data) {
  final capacity = recyclers * data.unit(UnitKind.recycler).cargo;
  final total = debris.metal + debris.crystal;
  if (total <= capacity) return Resources(metal: debris.metal, crystal: debris.crystal);
  final k = capacity / total;
  return Resources(
    metal: (debris.metal * k).floorToDouble(),
    crystal: (debris.crystal * k).floorToDouble(),
  );
}

/// Retour des recycleurs : chargement (au-delà du stockage possible, comme un
/// remboursement), champ réduit d'autant, recycleurs revenus.
GameState recycleReturn(GameState s, RecycleMission m, Rules rules) {
  final p = s.planet;
  final load = recycleLoad(p.debris, m.recyclers, rules.data);
  return s.copyWith(
    planet: p.copyWith(
      resources: p.resources + load,
      debris: p.debris - load,
      units: {...p.units, UnitKind.recycler: p.count(UnitKind.recycler) + m.recyclers},
    ),
  );
}
