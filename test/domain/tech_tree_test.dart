import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/tech_tree.dart';

import 'helpers.dart';

void main() {
  test('paliers : Énergie et Informatique 1, Laser 2, Ions 3, Plasma 4', () {
    expect(gameData.techsByTier(), {
      1: [TechKind.energy, TechKind.computer],
      2: [TechKind.laser],
      3: [TechKind.ion],
      4: [TechKind.plasma],
    });
  });

  test('débloque : prérequis directs inversés, bâtiments compris', () {
    expect(gameData.unlockedBy(TechKind.energy), [
      BuildingKind.fusionReactor,
      TechKind.laser,
      TechKind.ion,
      TechKind.plasma,
    ]);
    expect(gameData.unlockedBy(BuildingKind.roboticsFactory), [BuildingKind.naniteFactory]);
    expect(gameData.unlockedBy(TechKind.plasma), isEmpty);
    expect(gameData.unlockedBy(BuildingKind.researchLab), TechKind.values);
  });
}
