import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/engine.dart';
import '../domain/events.dart';
import '../domain/game_data.dart';
import '../domain/planet.dart';
import 'database.dart';
import 'save_codec.dart';

/// Lecture et écriture de l'état de jeu. Chaque écriture est une transaction unique.
class GameRepository {
  GameRepository(this._db);

  final StarmineDatabase _db;

  static const _speedKey = 'game_speed';
  static const _seedKey = 'rng_seed';

  /// Charge la partie (V0 : la première planète) ou `null` s'il n'y en a pas.
  Future<SaveGame?> load() async {
    final row =
        await (_db.select(_db.planets)
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;

    final buildings = await (_db.select(
      _db.buildings,
    )..where((t) => t.planetId.equals(row.id))).get();
    final events = await (_db.select(
      _db.events,
    )..where((t) => t.planetId.equals(row.id) & t.status.equalsValue(EventStatus.pending))).get();

    final planet = Planet(
      id: row.id,
      name: row.name,
      tempMax: row.tempMax,
      resources: decodeResources({
        'metal': row.metal,
        'crystal': row.crystal,
        'deuterium': row.deuterium,
      }),
      levels: {for (final b in buildings) BuildingKind.fromKey(b.kind): b.level},
      percents: {for (final b in buildings) BuildingKind.fromKey(b.kind): b.percent},
      lastUpdate: fromEpochMs(row.lastUpdateMs),
    );
    final research = await _db.select(_db.research).get();
    return SaveGame(
      state: GameState(
        planet: planet,
        research: {for (final r in research) TechKind.fromKey(r.kind): r.level},
        pending: events.map(_decodeRow).toList(),
      ),
      speed: double.tryParse(await _meta(_speedKey) ?? '') ?? 1,
      seed: int.tryParse(await _meta(_seedKey) ?? '') ?? 0,
    );
  }

  /// Écrit l'état après un `advance` ou une commande : planète, niveaux, événements en
  /// attente ; marque [applied] comme traités et [cancelledIds] comme annulés.
  Future<void> save(
    GameState state, {
    Iterable<GameEvent> applied = const [],
    Iterable<int> cancelledIds = const [],
  }) {
    return _db.transaction(() async {
      await _writeState(state);
      await _setStatus(applied.map((e) => e.id), EventStatus.done);
      await _setStatus(cancelledIds, EventStatus.cancelled);
    });
  }

  /// Remplace toute la partie (nouvelle partie, reset, import de sauvegarde).
  Future<void> replaceAll(SaveGame save) {
    return _db.transaction(() async {
      await _db.delete(_db.events).go();
      await _db.delete(_db.research).go();
      await _db.delete(_db.buildings).go();
      await _db.delete(_db.planets).go();
      await _writeState(save.state);
      await _setMeta(_speedKey, save.speed.toString());
      await _setMeta(_seedKey, save.seed.toString());
    });
  }

  Future<void> setSpeed(double speed) => _setMeta(_speedKey, speed.toString());

  /// Prochain identifiant d'événement libre (historique compris).
  Future<int> nextEventId() async {
    final maxId = _db.events.id.max();
    final row = await (_db.selectOnly(_db.events)..addColumns([maxId])).getSingle();
    return (row.read(maxId) ?? 0) + 1;
  }

  Future<void> _writeState(GameState state) async {
    final p = state.planet;
    await _db
        .into(_db.planets)
        .insertOnConflictUpdate(
          PlanetsCompanion(
            id: Value(p.id),
            name: Value(p.name),
            tempMax: Value(p.tempMax),
            metal: Value(p.resources.metal),
            crystal: Value(p.resources.crystal),
            deuterium: Value(p.resources.deuterium),
            lastUpdateMs: Value(p.lastUpdate.millisecondsSinceEpoch),
          ),
        );
    await _db.batch((b) {
      b.insertAllOnConflictUpdate(_db.buildings, [
        for (final e in p.levels.entries)
          BuildingsCompanion.insert(
            planetId: p.id,
            kind: e.key.key,
            level: e.value,
            percent: Value(p.percent(e.key)),
          ),
      ]);
      b.insertAllOnConflictUpdate(_db.research, [
        for (final e in state.research.entries)
          ResearchCompanion.insert(kind: e.key.key, level: e.value),
      ]);
      b.insertAllOnConflictUpdate(_db.events, [
        for (final e in state.pending)
          EventsCompanion(
            id: Value(e.id),
            planetId: Value(e.planetId),
            type: Value(eventType(e)),
            dueAtMs: Value(e.dueAt.millisecondsSinceEpoch),
            payload: Value(jsonEncode(eventPayload(e))),
            status: const Value(EventStatus.pending),
            createdAtMs: Value(_createdAt(e).millisecondsSinceEpoch),
          ),
      ]);
    });
  }

  Future<void> _setStatus(Iterable<int> ids, EventStatus status) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    await (_db.update(
      _db.events,
    )..where((t) => t.id.isIn(list))).write(EventsCompanion(status: Value(status)));
  }

  Future<String?> _meta(String name) async {
    final row = await (_db.select(_db.meta)..where((t) => t.name.equals(name))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _setMeta(String name, String value) =>
      _db.into(_db.meta).insertOnConflictUpdate(MetaCompanion.insert(name: name, value: value));

  static DateTime _createdAt(GameEvent e) => switch (e) {
    OrderDone(:final startedAt) => startedAt,
  };

  static GameEvent _decodeRow(EventRow r) => decodeEvent(
    id: r.id,
    planetId: r.planetId,
    type: r.type,
    dueAtMs: r.dueAtMs,
    payload: (jsonDecode(r.payload) as Map).cast<String, Object?>(),
  );
}
