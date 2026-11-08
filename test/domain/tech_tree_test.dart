import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/tech_tree.dart';

import 'helpers.dart';

void main() {
  test('paliers selon les prérequis technologiques', () {
    expect(gameData.techsByTier(), {
      1: [
        TechKind.energy,
        TechKind.computer,
        TechKind.weapons,
        TechKind.armour,
        TechKind.espionage,
      ],
      2: [TechKind.laser, TechKind.shielding, TechKind.combustion, TechKind.impulse],
      3: [TechKind.ion, TechKind.hyperspace],
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
      'Réacteur à combustion',
      'Réacteur à impulsion',
      'Propulsion hyperespace',
      'Laser léger',
      'Laser lourd',
      'Canon de Gauss',
    ]);
    expect(names(BuildingKind.roboticsFactory), ['Usine de nanites', 'Chantier spatial']);
    expect(names(TechKind.armour), ['Chasseur lourd']);
    expect(gameData.unlockedBy(BuildingKind.researchLab), [
      for (final k in TechKind.values)
        if (k != TechKind.combustion) gameData.tech(k),
    ]);
  });
}
