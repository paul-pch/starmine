import '../domain/combat.dart';
import '../domain/engine.dart';
import '../domain/events.dart';
import '../domain/game_data.dart';
import '../domain/planet.dart';
import '../domain/raid.dart';
import '../domain/resources.dart';
import '../domain/rules.dart';

/// Identifiant du format de sauvegarde exportée.
const saveFormat = 'starmine-save';

/// v2 (V1) : technologies et réglages de production. Une sauvegarde v1 reste lisible.
/// v3 (V2a) : unités et lots du chantier. v4 (V2b) : raids pirates.
/// v5 (V2c) : officiers, compteurs, relevé des raids et technos pirates.
/// v6 : files d'attente.
const saveVersion = 6;

/// Sauvegarde complète : état de jeu et réglages persistés.
class SaveGame {
  const SaveGame({required this.state, required this.speed, required this.seed});

  final GameState state;
  final double speed;
  final int seed;

  SaveGame copyWith({GameState? state, double? speed}) =>
      SaveGame(state: state ?? this.state, speed: speed ?? this.speed, seed: seed);
}

DateTime fromEpochMs(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

// --- Événements -------------------------------------------------------------

const buildingDoneType = 'building_done';
const researchDoneType = 'research_done';
const shipyardBatchType = 'shipyard_batch';
const raidDetectedType = 'raid_detected';
const raidArrivalType = 'raid_arrival';

String eventType(GameEvent event) => switch (event) {
  BuildingDone() => buildingDoneType,
  ResearchDone() => researchDoneType,
  ShipyardBatch() => shipyardBatchType,
  RaidDetected() => raidDetectedType,
  RaidArrival() => raidArrivalType,
};

Map<String, Object?> eventPayload(GameEvent event) => switch (event) {
  BuildingDone() => {'building': event.building.key, ..._orderPayload(event)},
  ResearchDone() => {'tech': event.tech.key, ..._orderPayload(event)},
  ShipyardBatch() => {
    'unit': event.unit.key,
    'ordered': event.ordered,
    'remaining': event.remaining,
    'unit_duration_ms': event.unitDuration.inMilliseconds,
    'started_at': event.startedAt.millisecondsSinceEpoch,
    'unit_cost': encodeResources(event.unitCost),
  },
  RaidDetected() => {
    'arrival_at': event.arrivalAt.millisecondsSinceEpoch,
    'seed': event.seed,
    if (event.base case final base?) ...{
      'base_points': base.points,
      'base_tech': encodeTech(base.tech),
    },
  },
  RaidArrival() => {
    'detected_at': event.detectedAt.millisecondsSinceEpoch,
    'seed': event.seed,
    'fleet': encodeUnits(event.fleet),
    'tech': encodeTech(event.tech),
  },
};

Map<String, Object?> encodeUnits(Map<UnitKind, int> units) => {
  for (final e in units.entries)
    if (e.value > 0) e.key.key: e.value,
};

Map<UnitKind, int> decodeUnits(Map<String, Object?> m) => {
  for (final e in m.entries) UnitKind.fromKey(e.key): (e.value as num?)?.toInt() ?? 0,
};

Map<String, Object?> encodeQueued(QueuedOrder q) => switch (q) {
  QueuedLevel(:final item) => {'item': item.key},
  QueuedBatch(:final unit, :final count) => {'unit': unit.key, 'count': count},
};

QueuedOrder decodeQueued(int id, Map<String, Object?> m) => m['unit'] == null
    ? QueuedLevel(id, Unlockable.fromKey(_string(m, 'item')))
    : QueuedBatch(id, UnitKind.fromKey(_string(m, 'unit')), _int(m, 'count'));

Map<String, Object?> encodeTech(TechLevels tech) => {
  for (final e in tech.entries)
    if (e.value > 0) e.key.key: e.value,
};

TechLevels decodeTech(Map<String, Object?> m) => {
  for (final e in m.entries) TechKind.fromKey(e.key): (e.value as num?)?.toInt() ?? 0,
};

Map<String, Object?> _orderPayload(OrderDone e) => {
  'target_level': e.targetLevel,
  'started_at': e.startedAt.millisecondsSinceEpoch,
  'cost': encodeResources(e.cost),
};

GameEvent decodeEvent({
  required int id,
  required int planetId,
  required String type,
  required int dueAtMs,
  required Map<String, Object?> payload,
}) {
  switch (type) {
    case buildingDoneType:
      return BuildingDone(
        id: id,
        planetId: planetId,
        dueAt: fromEpochMs(dueAtMs),
        startedAt: fromEpochMs(_int(payload, 'started_at')),
        building: BuildingKind.fromKey(_string(payload, 'building')),
        targetLevel: _int(payload, 'target_level'),
        cost: decodeResources(_map(payload, 'cost')),
      );
    case researchDoneType:
      return ResearchDone(
        id: id,
        planetId: planetId,
        dueAt: fromEpochMs(dueAtMs),
        startedAt: fromEpochMs(_int(payload, 'started_at')),
        tech: TechKind.fromKey(_string(payload, 'tech')),
        targetLevel: _int(payload, 'target_level'),
        cost: decodeResources(_map(payload, 'cost')),
      );
    case shipyardBatchType:
      return ShipyardBatch(
        id: id,
        planetId: planetId,
        dueAt: fromEpochMs(dueAtMs),
        startedAt: fromEpochMs(_int(payload, 'started_at')),
        unit: UnitKind.fromKey(_string(payload, 'unit')),
        ordered: _int(payload, 'ordered'),
        remaining: _int(payload, 'remaining'),
        unitDuration: Duration(milliseconds: _int(payload, 'unit_duration_ms')),
        unitCost: decodeResources(_map(payload, 'unit_cost')),
      );
    case raidDetectedType:
      return RaidDetected(
        id: id,
        planetId: planetId,
        dueAt: fromEpochMs(dueAtMs),
        arrivalAt: fromEpochMs(_int(payload, 'arrival_at')),
        seed: _int(payload, 'seed'),
        // Absent avant la V2c : relevé pris à la détection.
        base: payload['base_points'] == null
            ? null
            : RaidBase(
                points: _double(payload, 'base_points'),
                tech: decodeTech(_map(payload, 'base_tech')),
              ),
      );
    case raidArrivalType:
      return RaidArrival(
        id: id,
        planetId: planetId,
        dueAt: fromEpochMs(dueAtMs),
        detectedAt: fromEpochMs(_int(payload, 'detected_at')),
        seed: _int(payload, 'seed'),
        fleet: decodeUnits(_map(payload, 'fleet')),
        tech: payload['tech'] == null ? const {} : decodeTech(_map(payload, 'tech')),
      );
    default:
      throw FormatException('Type d’événement inconnu : $type');
  }
}

Map<String, Object?> encodeResources(Resources r) => {
  'metal': r.metal,
  'crystal': r.crystal,
  'deuterium': r.deuterium,
};

Resources decodeResources(Map<String, Object?> m) => Resources(
  metal: _double(m, 'metal'),
  crystal: _double(m, 'crystal'),
  deuterium: _double(m, 'deuterium'),
);

// --- Sauvegarde complète -----------------------------------------------------

Map<String, Object?> encodeSave(SaveGame save, {required DateTime exportedAt}) {
  final p = save.state.planet;
  return {
    'format': saveFormat,
    'version': saveVersion,
    'exported_at': exportedAt.toUtc().toIso8601String(),
    'game_speed': save.speed,
    'rng_seed': save.seed,
    'planet': {
      'id': p.id,
      'name': p.name,
      'temp_max': p.tempMax,
      'last_update': p.lastUpdate.millisecondsSinceEpoch,
      'resources': encodeResources(p.resources),
      'buildings': {for (final e in p.levels.entries) e.key.key: e.value},
      'production_percent': {for (final e in p.percents.entries) e.key.key: e.value},
      'units': {
        for (final e in p.units.entries)
          if (e.value > 0) e.key.key: e.value,
      },
    },
    'research': {for (final e in save.state.research.entries) e.key.key: e.value},
    'officers': {
      for (final e in save.state.officers.entries)
        if (e.value > 0) e.key.key: e.value,
    },
    'counters': {for (final e in save.state.counters.entries) e.key.key: e.value},
    'queue': [
      for (final q in save.state.queue) {'id': q.id, ...encodeQueued(q)},
    ],
    'events': [
      for (final e in save.state.pending)
        {
          'id': e.id,
          'planet_id': e.planetId,
          'type': eventType(e),
          'due_at': e.dueAt.millisecondsSinceEpoch,
          'payload': eventPayload(e),
        },
    ],
  };
}

SaveGame decodeSave(Map<String, Object?> json) {
  if (json['format'] != saveFormat) {
    throw const FormatException('Ce fichier n’est pas une sauvegarde Starmine');
  }
  final version = _int(json, 'version');
  if (version > saveVersion) {
    throw FormatException('Sauvegarde v$version, plus récente que l’app (v$saveVersion)');
  }
  final p = _map(json, 'planet');
  final buildings = _map(p, 'buildings');
  // Absents en v1 : réglages à 100 %, technos à 0.
  final percents = p['production_percent'] == null
      ? const <String, Object?>{}
      : _map(p, 'production_percent');
  final units = p['units'] == null ? const <String, Object?>{} : _map(p, 'units');
  final research = json['research'] == null ? const <String, Object?>{} : _map(json, 'research');
  // Absents avant la v5 : aucun officier, compteurs à 0.
  final officers = json['officers'] == null ? const <String, Object?>{} : _map(json, 'officers');
  final counters = json['counters'] == null ? const <String, Object?>{} : _map(json, 'counters');
  // Absente avant la v6 : file vide.
  final queue = json['queue'] == null ? const <Object?>[] : _list(json, 'queue');
  final planet = Planet(
    id: _int(p, 'id'),
    name: _string(p, 'name'),
    tempMax: _int(p, 'temp_max'),
    lastUpdate: fromEpochMs(_int(p, 'last_update')),
    resources: decodeResources(_map(p, 'resources')),
    levels: {
      for (final e in buildings.entries)
        BuildingKind.fromKey(e.key): (e.value as num?)?.toInt() ?? 0,
    },
    percents: {
      for (final e in percents.entries)
        BuildingKind.fromKey(e.key): (e.value as num?)?.toInt() ?? 100,
    },
    units: {
      for (final e in units.entries) UnitKind.fromKey(e.key): (e.value as num?)?.toInt() ?? 0,
    },
  );
  final events = [for (final raw in _list(json, 'events')) _decodeSavedEvent(raw)];
  return SaveGame(
    state: GameState(
      planet: planet,
      research: {
        for (final e in research.entries) TechKind.fromKey(e.key): (e.value as num?)?.toInt() ?? 0,
      },
      pending: events,
      officers: {
        for (final e in officers.entries)
          OfficerKind.fromKey(e.key): (e.value as num?)?.toInt() ?? 0,
      },
      counters: {
        for (final e in counters.entries) ?Counter.tryKey(e.key): (e.value as num?)?.toInt() ?? 0,
      },
      queue: [
        for (final raw in queue)
          decodeQueued(_int(_asMap(raw, 'queue[]'), 'id'), _asMap(raw, 'queue[]')),
      ],
    ),
    speed: _double(json, 'game_speed'),
    seed: _int(json, 'rng_seed'),
  );
}

GameEvent _decodeSavedEvent(Object? raw) {
  final e = _asMap(raw, 'events[]');
  return decodeEvent(
    id: _int(e, 'id'),
    planetId: _int(e, 'planet_id'),
    type: _string(e, 'type'),
    dueAtMs: _int(e, 'due_at'),
    payload: _map(e, 'payload'),
  );
}

// --- Lecture typée ------------------------------------------------------------

Map<String, Object?> _map(Map<String, Object?> m, String key) => _asMap(m[key], key);

Map<String, Object?> _asMap(Object? v, String key) {
  if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
  throw FormatException('« $key » doit être un objet');
}

List<Object?> _list(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is List) return v.cast<Object?>();
  throw FormatException('« $key » doit être une liste');
}

int _int(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is num) return v.toInt();
  throw FormatException('« $key » doit être un entier');
}

double _double(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is num) return v.toDouble();
  throw FormatException('« $key » doit être un nombre');
}

String _string(Map<String, Object?> m, String key) {
  final v = m[key];
  if (v is String) return v;
  throw FormatException('« $key » doit être une chaîne');
}

// --- Rapports de combat --------------------------------------------------------

Map<String, Object?> encodeReport(RaidReport r) => {
  'at': r.at.millisecondsSinceEpoch,
  'winner': r.winner.name,
  'rounds': r.rounds,
  'attacker_start': encodeUnits(r.attackerStart),
  'attacker_left': encodeUnits(r.attackerLeft),
  'defender_start': encodeUnits(r.defenderStart),
  'defender_left': encodeUnits(r.defenderLeft),
  'rebuilt': encodeUnits(r.rebuilt),
  'loot': encodeResources(r.loot),
  if (r.attackerStrength case final a?) 'attacker_strength': _encodeStrength(a),
  if (r.defenderStrength case final d?) 'defender_strength': _encodeStrength(d),
  'round_details': [
    for (final round in r.roundDetails)
      {
        'attacker': _encodeVolley(round.attacker),
        'defender': _encodeVolley(round.defender),
        'attacker_left': encodeUnits(round.attackerLeft),
        'defender_left': encodeUnits(round.defenderLeft),
      },
  ],
};

Map<String, Object?> _encodeStrength(SideStrength s) => {
  'units': s.units,
  'attack': s.attack,
  'shield': s.shield,
  'hull': s.hull,
};

SideStrength _decodeStrength(Map<String, Object?> m) => SideStrength(
  units: _int(m, 'units'),
  attack: _double(m, 'attack'),
  shield: _double(m, 'shield'),
  hull: _double(m, 'hull'),
);

Map<String, Object?> _encodeVolley(Volley v) => {
  'shots': v.shots,
  'fired': v.fired,
  'to_shields': v.toShields,
  'to_hull': v.toHull,
};

Volley _decodeVolley(Map<String, Object?> m) => Volley(
  shots: _int(m, 'shots'),
  fired: _double(m, 'fired'),
  toShields: _double(m, 'to_shields'),
  toHull: _double(m, 'to_hull'),
);

CombatRound _decodeRound(Object? raw) {
  final m = _asMap(raw, 'round_details[]');
  return CombatRound(
    attacker: _decodeVolley(_map(m, 'attacker')),
    defender: _decodeVolley(_map(m, 'defender')),
    attackerLeft: decodeUnits(_map(m, 'attacker_left')),
    defenderLeft: decodeUnits(_map(m, 'defender_left')),
  );
}

RaidReport decodeReport(Map<String, Object?> m) => RaidReport(
  at: fromEpochMs(_int(m, 'at')),
  winner: CombatWinner.values.byName(_string(m, 'winner')),
  rounds: _int(m, 'rounds'),
  attackerStart: decodeUnits(_map(m, 'attacker_start')),
  attackerLeft: decodeUnits(_map(m, 'attacker_left')),
  defenderStart: decodeUnits(_map(m, 'defender_start')),
  defenderLeft: decodeUnits(_map(m, 'defender_left')),
  rebuilt: decodeUnits(_map(m, 'rebuilt')),
  loot: decodeResources(_map(m, 'loot')),
  // Absents des rapports antérieurs.
  attackerStrength: m['attacker_strength'] == null
      ? null
      : _decodeStrength(_map(m, 'attacker_strength')),
  defenderStrength: m['defender_strength'] == null
      ? null
      : _decodeStrength(_map(m, 'defender_strength')),
  roundDetails: m['round_details'] == null
      ? const []
      : [for (final raw in _list(m, 'round_details')) _decodeRound(raw)],
);
