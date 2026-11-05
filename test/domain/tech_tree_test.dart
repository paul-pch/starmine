import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/tech_tree.dart';

import 'helpers.dart';

void main() {
  test('paliers selon les prérequis technologiques', () {
    expect(gameData.techsByTier(), {
      1: [TechKind.energy, TechKind.computer, TechKind.weapons, TechKind.armour],
      2: [TechKind.laser, TechKind.shielding],
      3: [TechKind.ion],
      4: [TechKind.plasma],
    });
  });

  test('débloque : prérequis directs inversés, bâtiments et défenses compris', () {
    List<String> names(Unlockable item) => [for (final s in gameData.unlockedBy(item)) s.name];

    expect(names(TechKind.energy), [
      'Centrale à fusion',
      'Technologie Laser',
      'Technologie Ions',
      'Technologie Plasma',
      'Technologie Bouclier',
      'Laser léger',
      'Laser lourd',
      'Canon de Gauss',
    ]);
    expect(names(BuildingKind.roboticsFactory), ['Usine de nanites', 'Chantier spatial']);
    expect(names(TechKind.armour), isEmpty);
    expect(
      gameData.unlockedBy(BuildingKind.researchLab),
      [for (final k in TechKind.values) gameData.tech(k)],
    );
  });
}
