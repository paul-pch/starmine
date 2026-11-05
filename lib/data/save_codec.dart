import '../domain/engine.dart';
import '../domain/events.dart';
import '../domain/game_data.dart';
import '../domain/planet.dart';
import '../domain/resources.dart';

/// Identifiant du format de sauvegarde exportée.
const saveFormat = 'starmine-save';

/// v2 (V1) : technologies et réglages de production. Une sauvegarde v1 reste lisible.
const saveVersion = 2;

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

String eventType(GameEvent event) => switch (event) {
  BuildingDone() => buildingDoneType,
  ResearchDone() => researchDoneType,
};

Map<String, Object?> eventPayload(GameEvent event) => switch (event) {
  BuildingDone() => {'building': event.building.key, ..._orderPayload(event)},
  ResearchDone() => {'tech': event.tech.key, ..._orderPayload(event)},
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
    },
    'research': {for (final e in save.state.research.entries) e.key.key: e.value},
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
  final research = json['research'] == null ? const <String, Object?>{} : _map(json, 'research');
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
  );
  final events = [for (final raw in _list(json, 'events')) _decodeSavedEvent(raw)];
  return SaveGame(
    state: GameState(
      planet: planet,
      research: {
        for (final e in research.entries) TechKind.fromKey(e.key): (e.value as num?)?.toInt() ?? 0,
      },
      pending: events,
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
