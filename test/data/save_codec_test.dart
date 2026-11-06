import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/save_codec.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/raid.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import '../domain/helpers.dart';

void main() {
  final rules = Rules(gameData);

  SaveGame sample() {
    final base = GameState(
      planet: planet(
        levels: {
          BuildingKind.metalMine: 3,
          BuildingKind.solarPlant: 2,
          BuildingKind.researchLab: 1,
        },
        percents: {BuildingKind.metalMine: 70},
        units: {UnitKind.rocketLauncher: 12},
        resources: const Resources(metal: 1234.56, crystal: 1789.1, deuterium: 912),
        tempMax: -12,
      ),
      research: {TechKind.computer: 2},
      pending: const [],
    );
    final built = startOrder(base, BuildingKind.crystalMine, t0, rules, eventId: 5);
    final researching = startOrder(built.state, TechKind.energy, t0, rules, eventId: 6);
    final withRaid = ensureRaidScheduled(
      (researching as OrderStarted).state,
      t0,
      rules,
      seed: 3,
      eventId: 7,
    );
    return SaveGame(state: withRaid, speed: 10, seed: 42);
  }

  test('export puis import : partie identique', () {
    final original = sample();
    // Passage par une chaîne JSON, comme un vrai fichier.
    final text = jsonEncode(encodeSave(original, exportedAt: t0));
    final restored = decodeSave((jsonDecode(text) as Map).cast<String, Object?>());

    final a = original.state.planet;
    final b = restored.state.planet;
    expect(b.id, a.id);
    expect(b.name, a.name);
    expect(b.tempMax, a.tempMax);
    expect(b.levels, a.levels);
    expect(b.percents, a.percents);
    expect(b.units, a.units);
    expect(restored.state.research, original.state.research);
    expect(b.resources, a.resources);
    expect(b.lastUpdate, a.lastUpdate);
    expect(restored.speed, 10);
    expect(restored.seed, 42);

    expect(restored.state.pending, hasLength(3));
    final raidA = pendingRaid(original.state)! as RaidDetected;
    final raidB = pendingRaid(restored.state)! as RaidDetected;
    expect(raidB.id, raidA.id);
    expect(raidB.dueAt, raidA.dueAt);
    expect(raidB.arrivalAt, raidA.arrivalAt);
    expect(raidB.seed, raidA.seed);
    expect(raidB.base!.points, raidA.base!.points);
    expect(encodeTech(raidB.base!.tech), encodeTech(raidA.base!.tech));
    expect(raidB.base!.tech[TechKind.computer], 2);
    final restoredOrders = restored.state.pending.whereType<OrderDone>().toList();
    final originalOrders = original.state.pending.whereType<OrderDone>().toList();
    for (var i = 0; i < 2; i++) {
      final e = restoredOrders[i];
      final o = originalOrders[i];
      expect(e.runtimeType, o.runtimeType);
      expect(e.id, o.id);
      expect(e.item, o.item);
      expect(e.dueAt, o.dueAt);
      expect(e.startedAt, o.startedAt);
      expect(e.targetLevel, o.targetLevel);
      expect(e.cost, o.cost);
    }
  });

  test('sauvegarde v1 (sans technos ni réglages) : importée avec les valeurs par défaut', () {
    final json = encodeSave(sample(), exportedAt: t0)..['version'] = 1;
    json.remove('research');
    (json['planet']! as Map<String, Object?>).remove('production_percent');
    json['events'] = <Object?>[];
    final restored = decodeSave(json);
    expect(restored.state.research.values, everyElement(0));
    expect(restored.state.planet.percents.values, everyElement(100));
  });

  test('raids d’avant la V2c : sans relevé ni technos pirates', () {
    final detected = decodeEvent(
      id: 1,
      planetId: 1,
      type: raidDetectedType,
      dueAtMs: 1000,
      payload: {'arrival_at': 2000, 'seed': 3},
    );
    expect((detected as RaidDetected).base, isNull);
    final arrival = decodeEvent(
      id: 1,
      planetId: 1,
      type: raidArrivalType,
      dueAtMs: 2000,
      payload: {
        'detected_at': 1000,
        'seed': 3,
        'fleet': {'light_fighter': 3},
      },
    );
    expect((arrival as RaidArrival).tech, isEmpty);
  });

  test('refuse un fichier qui n’est pas une sauvegarde', () {
    expect(() => decodeSave({'format': 'autre'}), throwsFormatException);
  });

  test('refuse une sauvegarde d’une version future', () {
    final json = encodeSave(sample(), exportedAt: t0)..['version'] = saveVersion + 1;
    expect(() => decodeSave(json), throwsFormatException);
  });
}
