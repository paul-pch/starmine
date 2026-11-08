import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/raid.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final data = shippedGameData;
  final rules = Rules(data);
  final boost = data.startBoost;

  test('config : ×4 au départ, disparaît à 100 points', () {
    expect(boost.factor(0), 4);
    expect(boost.factor(50), closeTo(2.5, 1e-12));
    expect(boost.factor(100), 1);
    expect(boost.factor(5000), 1);
  });

  test('nouvelle partie : production de base et des mines multipliée, pas les consommations', () {
    final s = game(planet(levels: {BuildingKind.metalMine: 1, BuildingKind.solarPlant: 1}));
    final points = economyPoints(s, rules);
    final f = boost.factor(points);
    expect(f, greaterThan(3.9));
    final plain = rules.hourlyProduction(s.planet, s.research);
    final boosted = rules.hourlyProduction(s.planet, s.research, s.modifiers(data));
    expect(boosted.metal, closeTo(plain.metal * f, 1e-9));
    expect(boosted.crystal, closeTo(plain.crystal * f, 1e-9));
  });

  test('rattrapage : le stock suit la production boostée, et le bonus baisse avec les points', () {
    final s = game(planet(resources: Resources.zero));
    final r = advance(s, t0.add(const Duration(hours: 1)), rules).state;
    expect(r.planet.resources.metal, closeTo(30 * boost.factor(0), 1e-6));
    final big = game(
      planet(levels: {BuildingKind.metalMine: 12, BuildingKind.crystalMine: 10}),
    );
    expect(big.modifiers(data).productionFactor, lessThan(s.modifiers(data).productionFactor));
  });
}
