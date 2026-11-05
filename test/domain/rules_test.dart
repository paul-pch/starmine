import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);
  const noTech = <TechKind, int>{};

  group('coûts', () {
    test('niveau 1 = coût de base', () {
      expect(rules.cost(BuildingKind.metalMine, 1), const Resources(metal: 60, crystal: 15));
      expect(
        rules.cost(BuildingKind.roboticsFactory, 1),
        const Resources(metal: 400, crystal: 120, deuterium: 200),
      );
      expect(rules.cost(TechKind.energy, 1), const Resources(crystal: 800, deuterium: 400));
    });

    test('croissance géométrique arrondie à l’inférieur', () {
      // 60 × 1.5 = 90 ; 15 × 1.5 = 22.5 → 22
      expect(rules.cost(BuildingKind.metalMine, 2), const Resources(metal: 90, crystal: 22));
      // 48 × 1.6^2 = 122.88 → 122 ; 24 × 2.56 = 61.44 → 61
      expect(rules.cost(BuildingKind.crystalMine, 3), const Resources(metal: 122, crystal: 61));
      expect(rules.cost(BuildingKind.metalStorage, 4), const Resources(metal: 8000));
      // 900 × 1.8 = 1620 ; 360 × 1.8 = 648 ; 180 × 1.8 = 324
      expect(
        rules.cost(BuildingKind.fusionReactor, 2),
        const Resources(metal: 1620, crystal: 648, deuterium: 324),
      );
      expect(rules.cost(TechKind.laser, 3), const Resources(metal: 800, crystal: 400));
    });
  });

  group('production', () {
    test('production de base sans aucune mine', () {
      expect(rules.hourlyProduction(planet(), noTech), const Resources(metal: 30, crystal: 15));
    });

    test('mines alimentées : base + coefficient × N × 1.1^N', () {
      final p = planet(
        levels: {
          BuildingKind.metalMine: 1,
          BuildingKind.crystalMine: 1,
          BuildingKind.deuteriumSynthesizer: 1,
          BuildingKind.solarPlant: 5,
        },
      );
      final r = rules.hourlyProduction(p, noTech);
      expect(r.metal, closeTo(30 + 30 * 1.1, 1e-9));
      expect(r.crystal, closeTo(15 + 20 * 1.1, 1e-9));
      expect(r.deuterium, closeTo(10 * 1.1 * (1.44 - 0.004 * 40), 1e-9));
    });

    test('planète froide = plus de deutérium', () {
      final levels = {BuildingKind.deuteriumSynthesizer: 5, BuildingKind.solarPlant: 10};
      final cold = rules.hourlyProduction(planet(levels: levels, tempMax: -40), noTech);
      final hot = rules.hourlyProduction(planet(levels: levels, tempMax: 80), noTech);
      expect(cold.deuterium, greaterThan(hot.deuterium));
    });

    test('la vitesse multiplie toute la production', () {
      final fast = Rules(gameData, speed: 10).hourlyProduction(planet(), noTech);
      expect(fast, const Resources(metal: 300, crystal: 150));
    });

    test('Plasma : bonus sur les mines, pas sur la base', () {
      final p = planet(levels: {BuildingKind.metalMine: 1, BuildingKind.solarPlant: 5});
      final r = rules.hourlyProduction(p, {TechKind.plasma: 2});
      expect(r.metal, closeTo(30 + 30 * 1.1 * 1.02, 1e-9));
    });

    test('réglage à 50 % : production et consommation divisées par deux', () {
      final p = planet(
        levels: {BuildingKind.metalMine: 1, BuildingKind.solarPlant: 5},
        percents: {BuildingKind.metalMine: 50},
      );
      expect(rules.hourlyProduction(p, noTech).metal, closeTo(30 + 15 * 1.1, 1e-9));
      expect(rules.energy(p, noTech).consumed, closeTo(5 * 1.1, 1e-9));
    });
  });

  group('énergie', () {
    test('bilan : 20 × N × 1.1^N produits, 10 ou 20 × N × 1.1^N consommés', () {
      final e = rules.energy(
        planet(
          levels: {
            BuildingKind.solarPlant: 2,
            BuildingKind.metalMine: 1,
            BuildingKind.deuteriumSynthesizer: 1,
          },
        ),
        noTech,
      );
      expect(e.produced, closeTo(20 * 2 * 1.21, 1e-9));
      expect(e.consumed, closeTo(10 * 1.1 + 20 * 1.1, 1e-9));
      expect(e.factor, 1);
    });

    test('énergie négative : les mines ralentissent, pas la base', () {
      // Mine niveau 1 sans centrale : facteur 0, seule la base reste.
      final noPower = planet(levels: {BuildingKind.metalMine: 1});
      expect(rules.hourlyProduction(noPower, noTech).metal, 30);

      // Centrale 1 (22) pour mine métal 2 (24.2) : facteur 22 / 24.2.
      final p = planet(levels: {BuildingKind.metalMine: 2, BuildingKind.solarPlant: 1});
      final factor = (20 * 1.1) / (10 * 2 * 1.21);
      expect(rules.energy(p, noTech).factor, closeTo(factor, 1e-12));
      expect(rules.hourlyProduction(p, noTech).metal, closeTo(30 + 30 * 2 * 1.21 * factor, 1e-9));
    });

    test('fusion : 30 × N × (1.05 + 0.01 × E)^N, consomme 10 × N × 1.1^N deutérium', () {
      final p = planet(levels: {BuildingKind.fusionReactor: 2});
      final e = rules.energy(p, {TechKind.energy: 3});
      expect(e.produced, closeTo(30 * 2 * 1.08 * 1.08, 1e-9));
      expect(
        rules.hourlyProduction(p, {TechKind.energy: 3}).deuterium,
        closeTo(-10 * 2 * 1.21, 1e-9),
      );
    });

    test('fusion à 0 % : ni énergie ni consommation', () {
      final p = planet(
        levels: {BuildingKind.fusionReactor: 2},
        percents: {BuildingKind.fusionReactor: 0},
      );
      expect(rules.energy(p, noTech).produced, 0);
      expect(rules.hourlyProduction(p, noTech).deuterium, 0);
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

    test('production négative : le stock baisse jusqu’à 0, jamais en dessous', () {
      final p = planet(
        levels: {BuildingKind.fusionReactor: 1},
        resources: const Resources(deuterium: 5),
      );
      final after = rules.produce(p, noTech, const Duration(hours: 10));
      expect(after.deuterium, 0);
    });
  });

  group('durées', () {
    const cost = Resources(metal: 60, crystal: 15);

    test('construction : (M + C) / (2500 × (1 + robots) × 2^nanites) heures', () {
      // 75 / 2500 h = 108 s
      expect(rules.buildDuration(cost, roboticsLevel: 0), const Duration(seconds: 108));
      expect(rules.buildDuration(cost, roboticsLevel: 2), const Duration(seconds: 36));
      expect(
        rules.buildDuration(cost, roboticsLevel: 0, naniteLevel: 2),
        const Duration(seconds: 27),
      );
    });

    test('recherche : (M + C) / (1000 × (1 + labo)) heures', () {
      // Énergie 1 : 800 / (1000 × 2) h = 1440 s
      expect(
        rules.researchDuration(rules.cost(TechKind.energy, 1), labLevel: 1),
        const Duration(seconds: 1440),
      );
    });

    test('vitesse et minimum d’une seconde', () {
      final fast = Rules(gameData, speed: 100);
      expect(fast.buildDuration(cost, roboticsLevel: 0), const Duration(seconds: 1));
    });
  });

  test('config : chaque bâtiment, techno et défense a une catégorie déclarée', () {
    for (final b in gameData.buildings.values) {
      expect(gameData.categories['buildings'], contains(b.category), reason: b.name);
    }
    for (final t in gameData.research.values) {
      expect(gameData.categories['research'], contains(t.category), reason: t.name);
    }
    for (final u in gameData.units.values.where((u) => u.defense)) {
      expect(gameData.categories['defense'], contains(u.category), reason: u.name);
    }
  });

  test('config : tous les éléments présents, prérequis connus', () {
    expect(gameData.buildings.keys, containsAll(BuildingKind.values));
    expect(gameData.research.keys, containsAll(TechKind.values));
    expect(gameData.start.resources, const Resources(metal: 500, crystal: 500));
    expect(gameData.start.tempMaxMin, -40);
    expect(gameData.start.tempMaxMax, 80);
    expect(gameData.start.tempSpread, 40);
    expect(gameData[BuildingKind.fusionReactor].requires, {
      BuildingKind.deuteriumSynthesizer: 5,
      TechKind.energy: 3,
    });
    expect(gameData[BuildingKind.fusionReactor].adjustable, isTrue);
    expect(gameData[BuildingKind.metalStorage].adjustable, isFalse);
  });
}
