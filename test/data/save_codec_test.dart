import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/save_codec.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import '../domain/helpers.dart';

void main() {
  final rules = Rules(gameData);

  SaveGame sample() {
    final base = GameState(
      planet: planet(
        levels: {BuildingKind.metalMine: 3, BuildingKind.solarPlant: 2},
        resources: const Resources(metal: 1234.56, crystal: 789.1, deuterium: 12),
        tempMax: -12,
      ),
      pending: const [],
    );
    final started =
        startBuilding(base, BuildingKind.crystalMine, t0, rules, eventId: 5) as BuildStarted;
    return SaveGame(state: started.state, speed: 10, seed: 42);
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
    expect(b.resources, a.resources);
    expect(b.lastUpdate, a.lastUpdate);
    expect(restored.speed, 10);
    expect(restored.seed, 42);

    final e = restored.state.pending.single as BuildingDone;
    final o = original.state.pending.single as BuildingDone;
    expect(e.id, o.id);
    expect(e.dueAt, o.dueAt);
    expect(e.startedAt, o.startedAt);
    expect(e.building, o.building);
    expect(e.targetLevel, o.targetLevel);
    expect(e.cost, o.cost);
  });

  test('refuse un fichier qui n’est pas une sauvegarde', () {
    expect(() => decodeSave({'format': 'autre'}), throwsFormatException);
  });

  test('refuse une sauvegarde d’une version future', () {
    final json = encodeSave(sample(), exportedAt: t0)..['version'] = saveVersion + 1;
    expect(() => decodeSave(json), throwsFormatException);
  });
}
