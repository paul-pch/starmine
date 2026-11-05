import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);

  group('coûts', () {
    test('niveau 1 = coût de base', () {
      expect(rules.cost(BuildingKind.metalMine, 1), const Resources(metal: 60, crystal: 15));
      expect(
        rules.cost(BuildingKind.roboticsFactory, 1),
        const Resources(metal: 400, crystal: 120, deuterium: 200),
      );
    });

    test('croissance géométrique arrondie à l’inférieur', () {
      // 60 × 1.5 = 90 ; 15 × 1.5 = 22.5 → 22
      expect(rules.cost(BuildingKind.metalMine, 2), const Resources(metal: 90, crystal: 22));
      // 48 × 1.6^2 = 122.88 → 122 ; 24 × 2.56 = 61.44 → 61
      expect(rules.cost(BuildingKind.crystalMine, 3), const Resources(metal: 122, crystal: 61));
      expect(rules.cost(BuildingKind.metalStorage, 4), const Resources(metal: 8000));
    });
  });

  group('production', () {
    test('production de base sans aucune mine', () {
      expect(
        rules.hourlyProduction(const {}, tempMax: 40),
        const Resources(metal: 30, crystal: 15),
      );
    });

    test('mines alimentées : base + coefficient × N × 1.1^N', () {
      final levels = {
        BuildingKind.metalMine: 1,
        BuildingKind.crystalMine: 1,
        BuildingKind.deuteriumSynthesizer: 1,
        BuildingKind.solarPlant: 5,
      };
      final p = rules.hourlyProduction(levels, tempMax: 40);
      expect(p.metal, closeTo(30 + 30 * 1.1, 1e-9));
      expect(p.crystal, closeTo(15 + 20 * 1.1, 1e-9));
      expect(p.deuterium, closeTo(10 * 1.1 * (1.44 - 0.004 * 40), 1e-9));
    });

    test('planète froide = plus de deutérium', () {
      final levels = {BuildingKind.deuteriumSynthesizer: 5, BuildingKind.solarPlant: 10};
      final cold = rules.hourlyProduction(levels, tempMax: -40).deuterium;
      final hot = rules.hourlyProduction(levels, tempMax: 80).deuterium;
      expect(cold, greaterThan(hot));
    });

    test('la vitesse multiplie toute la production', () {
      final fast = Rules(gameData, speed: 10).hourlyProduction(const {}, tempMax: 0);
      expect(fast, const Resources(metal: 300, crystal: 150));
    });
  });

  group('énergie', () {
    test('bilan : 20 × N × 1.1^N produits, 10 ou 20 × N × 1.1^N consommés', () {
      final e = rules.energy({
        BuildingKind.solarPlant: 2,
        BuildingKind.metalMine: 1,
        BuildingKind.deuteriumSynthesizer: 1,
      });
      expect(e.produced, closeTo(20 * 2 * 1.21, 1e-9));
      expect(e.consumed, closeTo(10 * 1.1 + 20 * 1.1, 1e-9));
      expect(e.factor, 1);
    });

    test('énergie négative : les mines ralentissent, pas la base', () {
      // Mine niveau 1 sans centrale : facteur 0, seule la base reste.
      final noPower = rules.hourlyProduction({BuildingKind.metalMine: 1}, tempMax: 40);
      expect(noPower.metal, 30);

      // Centrale 1 (22) pour mine métal 2 (24.2) : facteur 22 / 24.2.
      final levels = {BuildingKind.metalMine: 2, BuildingKind.solarPlant: 1};
      final factor = (20 * 1.1) / (10 * 2 * 1.21);
      expect(rules.energy(levels).factor, closeTo(factor, 1e-12));
      expect(
        rules.hourlyProduction(levels, tempMax: 40).metal,
        closeTo(30 + 30 * 2 * 1.21 * factor, 1e-9),
      );
    });
  });

  group('stockage', () {
    test('capacités OGame aux niveaux 0 à 3', () {
      expect([0, 1, 2, 3].map(rules.storageCapacity), [10000, 20000, 40000, 75000]);
    });

    test('chaque hangar plafonne sa ressource', () {
      final cap = rules.capacity({BuildingKind.crystalStorage: 2});
      expect(cap, const Resources(metal: 10000, crystal: 40000, deuterium: 10000));
    });
  });

  group('durée de construction', () {
    test('(M + C) / (2500 × (1 + robots)) heures', () {
      // 75 / 2500 h = 108 s
      expect(
        rules.buildDuration(const Resources(metal: 60, crystal: 15), roboticsLevel: 0),
        const Duration(seconds: 108),
      );
      expect(
        rules.buildDuration(const Resources(metal: 60, crystal: 15), roboticsLevel: 2),
        const Duration(seconds: 36),
      );
    });

    test('vitesse et minimum d’une seconde', () {
      final fast = Rules(gameData, speed: 100);
      expect(
        fast.buildDuration(const Resources(metal: 60, crystal: 15), roboticsLevel: 0),
        const Duration(seconds: 1),
      );
    });
  });

  test('config : tous les bâtiments sont présents et cohérents', () {
    expect(gameData.buildings.keys, containsAll(BuildingKind.values));
    expect(gameData.start.resources, const Resources(metal: 500, crystal: 500));
    expect(gameData.formulas.growth, 1.1);
    expect(gameData.start.tempMaxMin, -40);
    expect(gameData.start.tempMaxMax, 80);
  });
}
