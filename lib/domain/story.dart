import 'dart:math' as math;

import 'engine.dart';
import 'events.dart';
import 'game_data.dart';
import 'resources.dart';
import 'rules.dart';

/// Effet temporaire d'un événement en cours (production, énergie). [source] est la clé de
/// l'événement : un même événement ne se cumule pas, le nouveau remplace l'ancien.
class ActiveEffect {
  const ActiveEffect({
    required this.source,
    required this.type,
    this.resource,
    required this.value,
    required this.endsAt,
  });

  final String source;
  final StoryEffectType type;
  final ResourceKind? resource;
  final double value;
  final DateTime endsAt;
}

/// Ce qui s'est passé pour un événement (journal, notification, message).
enum StoryOutcomeKind {
  /// Bonus ou malus appliqué au tirage.
  happened,

  /// Choix proposé, en attente de réponse.
  awaiting,

  /// Option choisie par le joueur.
  answered,

  /// Sans réponse à l'échéance : option par défaut.
  defaulted,
}

class StoryOutcome {
  const StoryOutcome({required this.key, required this.at, required this.kind, this.option});

  final String key;
  final DateTime at;
  final StoryOutcomeKind kind;

  /// Option appliquée (choix).
  final int? option;
}

/// Résultat de l'application d'un [StoryEvent] dans `advance()`.
typedef StoryStep = ({GameState state, GameEvent next, StoryOutcome? outcome});

/// [h] heures de jeu à ×1, arrondies à la milliseconde.
Duration _hours(double h, Rules rules) =>
    Duration(milliseconds: (h * Duration.millisecondsPerHour / rules.speed).round());

/// Événement en attente de la chaîne.
StoryEvent? pendingStory(GameState s) => s.pending.whereType<StoryEvent>().firstOrNull;

/// Choix proposé au joueur, en attente de réponse.
StoryEventSpec? pendingChoice(GameState s, GameData data) {
  final key = pendingStory(s)?.choiceKey;
  return key == null ? null : data.story.catalog[key];
}

/// Peut être tiré maintenant : prérequis remplis, et un ordre en cours si l'effet en vise un.
bool storyEligible(GameState s, StoryEventSpec spec) {
  if (unmet(s, spec.requires).isNotEmpty) return false;
  for (final e in spec.effects) {
    if (e.type == StoryEffectType.shorten && _order(s, e.target) == null) return false;
  }
  return true;
}

/// Un malus est-il en cours ? Jamais deux à la fois.
bool malusActive(GameState s, GameData data) =>
    s.effects.any((e) => data.story.catalog[e.source]?.kind == StoryKind.malus);

/// Tirage : sens positif ou négatif à parts égales (les choix comptent comme positifs ;
/// positif forcé si un malus est en cours), puis un événement éligible de ce sens. Repli
/// sur l'autre sens si aucun n'est éligible.
StoryEventSpec? drawStory(GameState s, GameData data, math.Random random) {
  final roll = random.nextDouble();
  final positive = roll < 0.5 || malusActive(s, data);
  final eligible = [
    for (final spec in data.story.catalog.values)
      if (storyEligible(s, spec)) spec,
  ];
  bool isPositive(StoryEventSpec e) => e.kind != StoryKind.malus;
  var pool = [
    for (final e in eligible)
      if (isPositive(e) == positive) e,
  ];
  if (pool.isEmpty && !malusActive(s, data)) {
    pool = [
      for (final e in eligible)
        if (isPositive(e) != positive) e,
    ];
  }
  if (pool.isEmpty) return null;
  return pool[random.nextInt(pool.length)];
}

/// Part de l'officier lié : niveau × `per_level` (0 sans officier).
double officerShare(GameState s, StoryEventSpec spec) {
  final officer = spec.officer;
  if (officer == null) return 0;
  return math.min(1, spec.officerPerLevel * (s.officers[officer] ?? 0));
}

/// Effet réellement appliqué : un bonus est prolongé ou renforcé par l'officier lié, un
/// malus atténué. Les options d'un choix ne sont pas modifiées.
StoryEffectSpec adjustedEffect(GameState s, StoryEventSpec spec, StoryEffectSpec e) {
  final f = officerShare(s, spec);
  if (f == 0 || spec.kind == StoryKind.choice) return e;
  if (spec.kind == StoryKind.malus) {
    return StoryEffectSpec(
      type: e.type,
      resource: e.resource,
      target: e.target,
      value: e.value * (1 - f),
      hours: e.hours,
    );
  }
  return StoryEffectSpec(
    type: e.type,
    resource: e.resource,
    target: e.target,
    value: e.type == StoryEffectType.shorten ? math.min(0.9, e.value * (1 + f)) : e.value,
    hours: e.hours * (1 + f),
  );
}

OrderDone? _order(GameState s, OrderTarget? target) => switch (target) {
  OrderTarget.construction => s.currentConstruction,
  OrderTarget.research => s.currentResearch,
  null => null,
};

OrderDone _withDue(OrderDone o, DateTime due) => switch (o) {
  BuildingDone() => BuildingDone(
    id: o.id,
    planetId: o.planetId,
    dueAt: due,
    startedAt: o.startedAt,
    building: o.building,
    targetLevel: o.targetLevel,
    cost: o.cost,
  ),
  ResearchDone() => ResearchDone(
    id: o.id,
    planetId: o.planetId,
    dueAt: due,
    startedAt: o.startedAt,
    tech: o.tech,
    targetLevel: o.targetLevel,
    cost: o.cost,
  ),
};

/// Applique [effects] de [spec] à [at] (état déjà avancé à [at]).
GameState applyStoryEffects(
  GameState s,
  StoryEventSpec spec,
  List<StoryEffectSpec> effects,
  DateTime at,
  Rules rules,
) {
  var state = s;
  for (final raw in effects) {
    final e = adjustedEffect(s, spec, raw);
    switch (e.type) {
      case StoryEffectType.production || StoryEffectType.energy:
        state = state.copyWith(
          effects: [
            for (final a in state.effects)
              if (a.source != spec.key || a.type != e.type || a.resource != e.resource) a,
            ActiveEffect(
              source: spec.key,
              type: e.type,
              resource: e.resource,
              value: e.value,
              endsAt: at.add(_hours(e.hours, rules)),
            ),
          ],
        );
      case StoryEffectType.shorten:
        final order = _order(state, e.target);
        if (order == null || !order.dueAt.isAfter(at)) continue;
        final left = order.dueAt.difference(at).inMilliseconds;
        final due = at.add(Duration(milliseconds: (left * (1 - e.value)).round()));
        state = state.copyWith(
          pending: [for (final p in state.pending) p.id == order.id ? _withDue(order, due) : p],
        );
      case StoryEffectType.stock:
        final res = state.planet.resources;
        state = state.copyWith(
          planet: state.planet.copyWith(
            resources: res.map(
              (k, v) => e.resource == null || e.resource == k
                  ? math.max(0.0, (v * (1 + e.value)).floorToDouble())
                  : v,
            ),
          ),
        );
      case StoryEffectType.gain:
        final rate = rules.hourlyProduction(
          state.planet,
          state.research,
          state.modifiers(rules.data),
        );
        final cap = rules.capacity(state.planet.levels);
        state = state.copyWith(
          planet: state.planet.copyWith(
            resources: state.planet.resources.map((k, v) {
              if (e.resource != null && e.resource != k) return v;
              if (v >= cap[k]) return v;
              final gain = math.max(0.0, rate[k] / rules.speed) * e.hours;
              return math.min(cap[k], v + gain).floorToDouble();
            }),
          ),
        );
      case StoryEffectType.raid:
        final raid = state.pending.whereType<RaidDetected>().firstOrNull;
        if (raid == null) continue;
        final earlier = raid.dueAt.subtract(_hours(e.hours, rules));
        final due = earlier.isBefore(at) ? at : earlier;
        final shift = raid.dueAt.difference(due);
        state = state.copyWith(
          pending: [
            for (final p in state.pending)
              p.id == raid.id
                  ? RaidDetected(
                      id: raid.id,
                      planetId: raid.planetId,
                      dueAt: due,
                      arrivalAt: raid.arrivalAt.subtract(shift),
                      seed: raid.seed,
                      base: raid.base,
                    )
                  : p,
          ],
        );
    }
  }
  return state;
}

/// Prochain événement de la chaîne, `story_events.interval_hours` après [after].
StoryEvent nextStory(int id, int planetId, DateTime after, math.Random random, Rules rules) {
  final cfg = rules.data.story;
  final delay =
      cfg.intervalHoursMin + random.nextDouble() * (cfg.intervalHoursMax - cfg.intervalHoursMin);
  return StoryEvent(
    id: id,
    planetId: planetId,
    dueAt: after.add(_hours(delay, rules)),
    seed: random.nextInt(1 << 31),
  );
}

/// Échéance d'un [StoryEvent] : tirage, ou option par défaut d'un choix resté sans réponse.
StoryStep applyStory(GameState s, StoryEvent e, Rules rules) {
  final data = rules.data;
  final random = math.Random(e.seed);
  final key = e.choiceKey;
  if (key != null) {
    final spec = data.story.catalog[key];
    final state = spec == null
        ? s
        : applyStoryEffects(s, spec, spec.options[spec.defaultOption].effects, e.dueAt, rules);
    return (
      state: state,
      next: nextStory(e.id, e.planetId, e.dueAt, random, rules),
      outcome: spec == null
          ? null
          : StoryOutcome(
              key: key,
              at: e.dueAt,
              kind: StoryOutcomeKind.defaulted,
              option: spec.defaultOption,
            ),
    );
  }
  final spec = drawStory(s, data, random);
  if (spec == null) {
    return (state: s, next: nextStory(e.id, e.planetId, e.dueAt, random, rules), outcome: null);
  }
  if (spec.kind == StoryKind.choice) {
    return (
      state: s,
      next: StoryEvent(
        id: e.id,
        planetId: e.planetId,
        dueAt: e.dueAt.add(_hours(data.story.answerHours, rules)),
        seed: random.nextInt(1 << 31),
        choiceKey: spec.key,
      ),
      outcome: StoryOutcome(key: spec.key, at: e.dueAt, kind: StoryOutcomeKind.awaiting),
    );
  }
  return (
    state: applyStoryEffects(s, spec, spec.effects, e.dueAt, rules),
    next: nextStory(e.id, e.planetId, e.dueAt, random, rules),
    outcome: StoryOutcome(key: spec.key, at: e.dueAt, kind: StoryOutcomeKind.happened),
  );
}

/// Réponse du joueur au choix en attente, à [now] : option appliquée, événement suivant
/// planifié. `null` s'il n'y a pas de choix en attente.
({GameState state, StoryOutcome outcome})? answerChoice(
  GameState state,
  int option,
  DateTime now,
  Rules rules,
) {
  final advanced = advance(state, now, rules).state;
  final pending = pendingStory(advanced);
  final key = pending?.choiceKey;
  final spec = key == null ? null : rules.data.story.catalog[key];
  if (pending == null || spec == null || option < 0 || option >= spec.options.length) {
    return null;
  }
  final applied = applyStoryEffects(advanced, spec, spec.options[option].effects, now, rules);
  final next = nextStory(pending.id, pending.planetId, now, math.Random(pending.seed), rules);
  return (
    state: applied.copyWith(
      pending: [for (final p in applied.pending) p.id == pending.id ? next : p],
    ),
    outcome: StoryOutcome(key: spec.key, at: now, kind: StoryOutcomeKind.answered, option: option),
  );
}

/// Planifie le premier événement si la chaîne n'existe pas.
GameState ensureStoryScheduled(
  GameState s,
  DateTime now,
  Rules rules, {
  required int seed,
  required int eventId,
}) {
  if (pendingStory(s) != null) return s;
  final next = nextStory(eventId, s.planet.id, now, math.Random(seed), rules);
  return s.copyWith(pending: [...s.pending, next]);
}

/// Debug : l'événement en attente survient à [now] (sauf choix déjà proposé).
GameState storyNow(GameState s, DateTime now) {
  final e = pendingStory(s);
  if (e == null || e.choiceKey != null) return s;
  final moved = StoryEvent(id: e.id, planetId: e.planetId, dueAt: now, seed: e.seed);
  return s.copyWith(pending: [for (final p in s.pending) p.id == e.id ? moved : p]);
}
