import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/availability.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);

  test('réalisable : prérequis et ressources, file ignorée', () {
    final s = game(planet());
    expect(realizable(s, BuildingKind.metalMine, rules), isTrue);
    expect(realizable(s, BuildingKind.naniteFactory, rules), isFalse);
    expect(realizable(s, TechKind.energy, rules), isFalse);
    expect(
      realizable(game(planet(resources: Resources.zero)), BuildingKind.metalMine, rules),
      isFalse,
    );
  });

  test('défense réalisable : prérequis, limite par planète, une unité payable', () {
    const rich = Resources(metal: 1e6, crystal: 1e6, deuterium: 1e6);
    final s = game(planet(levels: {BuildingKind.shipyard: 1}, resources: rich));
    expect(realizableUnit(s, UnitKind.rocketLauncher, rules), isTrue);
    expect(realizableUnit(s, UnitKind.lightFighter, rules), isFalse);
    final drive = game(s.planet, research: {TechKind.combustion: 1});
    expect(realizableUnit(drive, UnitKind.lightFighter, rules), isTrue);
    expect(realizableUnit(s, UnitKind.cruiser, rules), isFalse);
    final dome = game(
      planet(
        levels: {BuildingKind.shipyard: 1},
        resources: rich,
        units: {UnitKind.smallShieldDome: 1},
      ),
      research: {TechKind.shielding: 2},
    );
    expect(realizableUnit(dome, UnitKind.smallShieldDome, rules), isFalse);
    expect(waitForUnit(dome, UnitKind.smallShieldDome, rules), isNull);
  });

  test('attente : ressource la plus lente, null si verrouillé ou hors d’atteinte', () {
    final empty = game(planet(resources: Resources.zero));
    // Mine de métal 1 : 60 métal et 15 cristal ; base 30 métal/h et 15 cristal/h.
    expect(waitFor(empty, BuildingKind.metalMine, rules), const Duration(hours: 2));
    expect(waitFor(empty, TechKind.energy, rules), isNull);
    expect(timeToAfford(empty, const Resources(deuterium: 1), rules), isNull);
    expect(timeToAfford(empty, const Resources(metal: 1e7), rules), isNull);
    expect(timeToAfford(game(planet()), const Resources(metal: 10), rules), Duration.zero);
  });
}
