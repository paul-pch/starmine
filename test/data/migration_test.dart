import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/database.dart';
import 'package:starmine/data/game_repository.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';

import '../domain/helpers.dart';

/// Schéma v1 (V0) tel que publié, avec une partie en cours.
const _v1 = [
  'CREATE TABLE planets (id INTEGER NOT NULL PRIMARY KEY, name TEXT NOT NULL, '
      'temp_max INTEGER NOT NULL, metal REAL NOT NULL, crystal REAL NOT NULL, '
      'deuterium REAL NOT NULL, last_update_ms INTEGER NOT NULL)',
  'CREATE TABLE buildings (planet_id INTEGER NOT NULL REFERENCES planets (id), '
      'kind TEXT NOT NULL, level INTEGER NOT NULL, PRIMARY KEY (planet_id, kind))',
  'CREATE TABLE events (id INTEGER NOT NULL PRIMARY KEY, '
      'planet_id INTEGER NOT NULL REFERENCES planets (id), type TEXT NOT NULL, '
      'due_at_ms INTEGER NOT NULL, payload TEXT NOT NULL, status TEXT NOT NULL, '
      'created_at_ms INTEGER NOT NULL)',
  'CREATE TABLE meta (name TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)',
  "INSERT INTO planets VALUES (1, 'Planète mère', 21, 1234.5, 678.9, 42.0, 1767254400000)",
  "INSERT INTO buildings VALUES (1, 'metal_mine', 5), (1, 'solar_plant', 4)",
  'INSERT INTO events VALUES (3, 1, \'building_done\', 1767258000000, '
      '\'{"building":"crystal_mine","target_level":1,"started_at":1767254400000,'
      '"cost":{"metal":48.0,"crystal":24.0,"deuterium":0.0}}\', \'pending\', 1767254400000)',
  "INSERT INTO meta VALUES ('game_speed', '10.0'), ('rng_seed', '99')",
  'PRAGMA user_version = 1',
];

void main() {
  test('base v1 → v5 : partie conservée, technos et officiers à 0, réglages à 100 %', () async {
    final db = StarmineDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final sql in _v1) {
            raw.execute(sql);
          }
        },
      ),
    );
    addTearDown(db.close);

    final save = (await GameRepository(db).load())!;
    final p = save.state.planet;
    expect(p.tempMax, 21);
    expect(p.resources, const Resources(metal: 1234.5, crystal: 678.9, deuterium: 42));
    expect(p.level(BuildingKind.metalMine), 5);
    expect(p.level(BuildingKind.solarPlant), 4);
    expect(p.percents.values, everyElement(100));
    expect(save.state.research.values, everyElement(0));
    expect(save.state.officers.values, everyElement(0));
    expect(save.state.counters.values, everyElement(0));
    expect(save.speed, 10);
    expect(save.seed, 99);
    final e = save.state.pending.single as BuildingDone;
    expect(e.id, 3);
    expect(e.building, BuildingKind.crystalMine);

    // La base migrée accepte les nouvelles données.
    await GameRepository(db).save(
      save.state.copyWith(
        research: {TechKind.energy: 2},
        officers: {OfficerKind.geologist: 3},
        counters: {Counter.raidsRepelled: 4},
      ),
    );
    final reloaded = (await GameRepository(db).load())!;
    expect(reloaded.state.research[TechKind.energy], 2);
    expect(reloaded.state.officers[OfficerKind.geologist], 3);
    expect(reloaded.state.counters[Counter.raidsRepelled], 4);
    expect(reloaded.state.planet.lastUpdate, t0);
    expect(await GameRepository(db).loadReports(), isEmpty);
  });
}
