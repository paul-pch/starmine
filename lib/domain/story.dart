import 'dart:math' as math;

import 'engine.dart';
import 'events.dart';
import 'game_data.dart';
import 'resources.dart';
import 'rules.dart';

/// Effet en cours d'un événement (production, énergie, versement différé). [source] est la
/// clé de l'événement ; les effets se cumulent, même ceux d'un même événement. Pour un
/// versement différé (`delayed`), [value] est le montant versé à [endsAt].
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
  const StoryOutcome({
    required this.key,
    required this.at,
    required this.kind,
    this.option,
    this.won,
  });

  final String key;
  final DateTime at;
  final StoryOutcomeKind kind;

  /// Option appliquée (choix).
  final int? option;

  /// Issue du pari des effets appliqués, `null` sans pari.
  final bool? won;
}

/// Effets d'un pari remplacés par leur issue (`win` ou `lose`), tirée avec [random].
({List<StoryEffectSpec> effects, bool? won}) resolveGambles(
  List<StoryEffectSpec> effects,
  math.Random random,
) {
  bool? won;
  final out = <StoryEffectSpec>[];
  for (final e in effects) {
    if (e.type != StoryEffectType.gamble) {
      out.add(e);
      continue;
    }
    final ok = random.nextDouble() < e.chance;
    won = (won ?? true) && ok;
    out.addAll(ok ? e.win : e.lose);
  }
  return (effects: out, won: won);
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
StoryEventSpec? drawStory(GameState s, GameData data, math.Random random, {String? exclude}) {
  final roll = random.nextDouble();
  final positive = roll < 0.5 || malusActive(s, data);
  final eligible = [
    for (final spec in data.story.catalog.values)
      if (storyEligible(s, spec) && spec.key != exclude) spec,
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

/// Production horaire à ×1 (bonus compris), base des gains en heures de production.
Resources _rate(GameState s, Rules rules) {
  final r = rules.hourlyProduction(s.planet, s.research, s.modifiers(rules.data));
  return r.map((_, v) => math.max(0.0, v / rules.speed));
}

/// Applique [effects] de [spec] à [at] (état déjà avancé à [at]). Un pari doit avoir été
/// résolu avant ([resolveGambles]) ; sinon il est ignoré.
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
            ...state.effects,
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
      case StoryEffectType.units:
        final unit = e.unit;
        if (unit == null) continue;
        final count = math.max(0, state.planet.count(unit) + e.value.round());
        state = state.copyWith(
          planet: state.planet.copyWith(units: {...state.planet.units, unit: count}),
        );
      case StoryEffectType.debris:
        final rate = _rate(state, rules);
        state = state.copyWith(
          planet: state.planet.copyWith(
            debris:
                state.planet.debris +
                Resources(
                  metal: (rate.metal * e.hours).floorToDouble(),
                  crystal: (rate.crystal * e.hours).floorToDouble(),
                ),
          ),
        );
      case StoryEffectType.delayed:
        final rate = _rate(state, rules);
        state = state.copyWith(
          effects: [
            ...state.effects,
            for (final k in ResourceKind.values)
              if ((e.resource == null || e.resource == k) && rate[k] * e.hours >= 1)
                ActiveEffect(
                  source: spec.key,
                  type: StoryEffectType.delayed,
                  resource: k,
                  value: (rate[k] * e.hours).floorToDouble(),
                  endsAt: at.add(_hours(e.delay, rules)),
                ),
          ],
        );
      case StoryEffectType.gamble:
        // Résolu avant l'application (resolveGambles).
        continue;
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

/// Délai tiré dans [min, max] heures, à ×1.
Duration _between(double min, double max, math.Random random, Rules rules) =>
    _hours(min + random.nextDouble() * (max - min), rules);

Duration _accrual(math.Random random, Rules rules) {
  final cfg = rules.data.story;
  return _between(cfg.intervalHoursMin, cfg.intervalHoursMax, random, rules);
}

Duration _serveGap(math.Random random, Rules rules) {
  final cfg = rules.data.story;
  return _between(cfg.serveGapMinutesMin / 60, cfg.serveGapMinutesMax / 60, random, rules);
}

/// Échéance d'un [StoryEvent] dans `advance()` : option par défaut d'un choix échu, ajout au
/// stock. Aucun tirage : les événements ne surviennent qu'app ouverte ([serveStory]).
StoryStep applyStory(GameState s, StoryEvent e, Rules rules) {
  final data = rules.data;
  final random = math.Random(e.seed);
  final at = e.dueAt;
  var state = s;
  StoryOutcome? outcome;
  var choiceKey = e.choiceKey;
  var deadline = e.deadline;
  var serveAt = e.serveAt;
  if (choiceKey != null && deadline != null && !deadline.isAfter(at)) {
    final spec = data.story.catalog[choiceKey];
    if (spec != null) {
      final r = resolveGambles(spec.options[spec.defaultOption].effects, random);
      state = applyStoryEffects(state, spec, r.effects, at, rules);
      outcome = StoryOutcome(
        key: choiceKey,
        at: at,
        kind: StoryOutcomeKind.defaulted,
        option: spec.defaultOption,
        won: r.won,
      );
    }
    choiceKey = null;
    deadline = null;
    serveAt = at.add(_serveGap(random, rules));
  }
  var stock = e.stock;
  var accrueAt = e.accrueAt;
  if (!accrueAt.isAfter(at)) {
    stock = math.min(data.story.maxStock, stock + 1);
    accrueAt = at.add(_accrual(random, rules));
  }
  return (
    state: state,
    next: StoryEvent.chain(
      id: e.id,
      planetId: e.planetId,
      seed: random.nextInt(1 << 31),
      accrueAt: accrueAt,
      choiceKey: choiceKey,
      deadline: deadline,
      lastKey: e.lastKey,
      stock: stock,
      serveAt: serveAt,
    ),
    outcome: outcome,
  );
}

/// Un événement peut être servi à [now] : stock non vide, aucun choix en attente, délai de
/// service passé.
bool canServe(GameState s, DateTime now) {
  final e = pendingStory(s);
  if (e == null || e.choiceKey != null || e.stock <= 0) return false;
  final at = e.serveAt;
  return at == null || !at.isAfter(now);
}

/// Sert un événement du stock à [now], app ouverte (état déjà avancé à [now]) : tirage,
/// effets ou choix proposé. `null` si rien n'est à servir.
({GameState state, StoryOutcome? outcome})? serveStory(GameState s, DateTime now, Rules rules) {
  if (!canServe(s, now)) return null;
  final e = pendingStory(s)!;
  final data = rules.data;
  final random = math.Random(e.seed);
  final spec = drawStory(s, data, random, exclude: e.lastKey);
  var state = s;
  StoryOutcome? outcome;
  String? choiceKey;
  DateTime? deadline;
  if (spec != null && spec.kind == StoryKind.choice) {
    choiceKey = spec.key;
    deadline = now.add(_hours(data.story.answerHours, rules));
    outcome = StoryOutcome(key: spec.key, at: now, kind: StoryOutcomeKind.awaiting);
  } else if (spec != null) {
    final r = resolveGambles(spec.effects, random);
    state = applyStoryEffects(state, spec, r.effects, now, rules);
    outcome = StoryOutcome(
      key: spec.key,
      at: now,
      kind: StoryOutcomeKind.happened,
      won: r.won,
    );
  }
  final next = StoryEvent.chain(
    id: e.id,
    planetId: e.planetId,
    seed: random.nextInt(1 << 31),
    accrueAt: e.accrueAt,
    choiceKey: choiceKey,
    deadline: deadline,
    lastKey: spec?.key ?? e.lastKey,
    stock: e.stock - 1,
    serveAt: choiceKey == null ? now.add(_serveGap(random, rules)) : null,
  );
  return (
    state: state.copyWith(pending: [for (final p in state.pending) p.id == e.id ? next : p]),
    outcome: outcome,
  );
}

/// Réponse du joueur au choix en attente, à [now] : option appliquée, service suivant après
/// le délai. `null` s'il n'y a pas de choix en attente.
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
  final random = math.Random(pending.seed ^ (option + 1));
  final r = resolveGambles(spec.options[option].effects, random);
  final applied = applyStoryEffects(advanced, spec, r.effects, now, rules);
  final next = StoryEvent.chain(
    id: pending.id,
    planetId: pending.planetId,
    seed: random.nextInt(1 << 31),
    accrueAt: pending.accrueAt,
    lastKey: spec.key,
    stock: pending.stock,
    serveAt: now.add(_serveGap(random, rules)),
  );
  return (
    state: applied.copyWith(
      pending: [for (final p in applied.pending) p.id == pending.id ? next : p],
    ),
    outcome: StoryOutcome(
      key: spec.key,
      at: now,
      kind: StoryOutcomeKind.answered,
      option: option,
      won: r.won,
    ),
  );
}

/// Planifie la chaîne si elle n'existe pas : stock vide, premier ajout après un intervalle.
GameState ensureStoryScheduled(
  GameState s,
  DateTime now,
  Rules rules, {
  required int seed,
  required int eventId,
}) {
  if (pendingStory(s) != null) return s;
  final random = math.Random(seed);
  final next = StoryEvent.chain(
    id: eventId,
    planetId: s.planet.id,
    seed: random.nextInt(1 << 31),
    accrueAt: now.add(_accrual(random, rules)),
  );
  return s.copyWith(pending: [...s.pending, next]);
}

/// Debug : un événement s'ajoute au stock, servable tout de suite (sauf choix en attente).
GameState storyNow(GameState s, DateTime now, Rules rules) {
  final e = pendingStory(s);
  if (e == null || e.choiceKey != null) return s;
  final moved = StoryEvent.chain(
    id: e.id,
    planetId: e.planetId,
    seed: e.seed,
    accrueAt: e.accrueAt,
    lastKey: e.lastKey,
    stock: math.min(rules.data.story.maxStock, e.stock + 1),
  );
  return s.copyWith(pending: [for (final p in s.pending) p.id == e.id ? moved : p]);
}
