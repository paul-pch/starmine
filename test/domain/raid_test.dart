import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/combat.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/raid.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);

  RaidArrival arrival(Map<UnitKind, int> fleet, {int seed = 1}) => RaidArrival(
    id: 9,
    planetId: 1,
    dueAt: t0.add(const Duration(hours: 1)),
    detectedAt: t0,
    fleet: fleet,
    seed: seed,
  );

  group('points', () {
    test('ressources dépensées ÷ 1000 : bâtiments, technos, unités', () {
      final s = game(
        planet(levels: {BuildingKind.metalMine: 2}, units: {UnitKind.rocketLauncher: 3}),
        research: {TechKind.energy: 1},
      );
      // Mine 1 (75) + mine 2 (112) + Énergie 1 (1200) + 3 lanceurs (6000).
      expect(points(s, rules), closeTo((75 + 112 + 1200 + 6000) / 1000, 1e-9));
    });
  });

  group('flotte pirate', () {
    test('plancher : 3 chasseurs légers, sans transporteur', () {
      expect(pirateFleet(0, gameData, math.Random(1)), {UnitKind.lightFighter: 3});
    });

    test('la force croît avec les points, nouveaux vaisseaux débloqués', () {
      final small = pirateFleet(10, gameData, math.Random(2));
      final big = pirateFleet(6000, gameData, math.Random(2));
      double value(Map<UnitKind, int> f) => f.entries.fold(
        0,
        (s, e) =>
            s +
            e.value * (gameData.unit(e.key).baseCost.metal + gameData.unit(e.key).baseCost.crystal),
      );
      expect(value(big), greaterThan(value(small) * 10));
      expect(big.keys, containsAll([UnitKind.battleship, UnitKind.largeCargo]));
      expect(small.keys, isNot(contains(UnitKind.cruiser)));
    });
  });

  group('pillage', () {
    test('moitié de chaque stock si la soute suffit', () {
      expect(
        loot(const Resources(metal: 1000, crystal: 400, deuterium: 10), 1e9, 0.5),
        const Resources(metal: 500, crystal: 200, deuterium: 5),
      );
    });

    test('réduit proportionnellement à la soute', () {
      expect(
        loot(const Resources(metal: 3000, crystal: 1000), 1000, 0.5),
        const Resources(metal: 750, crystal: 250),
      );
    });
  });

  group('déroulé d’un raid', () {
    test('détection : composition fixée, même id, arrivée prévue', () {
      final detected = RaidDetected(
        id: 9,
        planetId: 1,
        dueAt: t0,
        arrivalAt: t0.add(const Duration(hours: 1)),
        seed: 5,
      );
      final step = detectRaid(game(planet()), detected, rules);
      final next = step.next as RaidArrival;
      expect(next.id, 9);
      expect(next.dueAt, detected.arrivalAt);
      expect(next.fleet, {UnitKind.lightFighter: 3});
    });

    test('sans défense : défaite, pillage limité par la soute', () {
      final s = game(planet(resources: const Resources(metal: 10000, crystal: 10000)));
      final step = resolveRaid(s, arrival({UnitKind.lightFighter: 3}), rules);
      expect(step.report!.winner, CombatWinner.attacker);
      // 3 chasseurs légers : soute 150, répartie à parts égales.
      expect(step.report!.loot, const Resources(metal: 75, crystal: 75));
      expect(step.state.planet.resources, const Resources(metal: 9925, crystal: 9925));
    });

    test('défenses suffisantes : raid repoussé, rien de pillé', () {
      final s = game(
        planet(
          resources: const Resources(metal: 10000, crystal: 10000),
          units: {UnitKind.rocketLauncher: 30},
        ),
      );
      final step = resolveRaid(s, arrival({UnitKind.lightFighter: 3}), rules);
      expect(step.report!.winner, CombatWinner.defender);
      expect(step.report!.loot, Resources.zero);
      expect(step.state.planet.resources, s.planet.resources);
    });

    test('défenses détruites retirées, 70 % reconstruites', () {
      final s = game(planet(units: {UnitKind.rocketLauncher: 200}));
      final step = resolveRaid(s, arrival({UnitKind.battleship: 100}, seed: 3), rules);
      final left = step.state.planet.count(UnitKind.rocketLauncher);
      expect(left, step.report!.defenderLeft[UnitKind.rocketLauncher] ?? 0);
      expect(left, lessThan(200));
      expect(left, greaterThan(100));
    });

    test('raid suivant : même id, arrivée 6 à 18 h plus tard, détection 1 h avant', () {
      final step = resolveRaid(game(planet()), arrival({UnitKind.lightFighter: 3}), rules);
      final next = step.next as RaidDetected;
      final gap = next.arrivalAt.difference(t0.add(const Duration(hours: 1)));
      expect(next.id, 9);
      expect(gap.inMinutes, inInclusiveRange(6 * 60, 18 * 60));
      expect(next.arrivalAt.difference(next.dueAt), const Duration(hours: 1));
    });

    test('la vitesse raccourcit délais et préavis', () {
      final fast = Rules(gameData, speed: 100);
      final step = resolveRaid(game(planet()), arrival({UnitKind.lightFighter: 3}), fast);
      final next = step.next as RaidDetected;
      expect(next.arrivalAt.difference(next.dueAt), const Duration(seconds: 36));
    });
  });

  test('rattrapage de 3 jours : plusieurs raids, rapports, déterministe', () {
    final start = ensureRaidScheduled(
      game(planet(levels: {BuildingKind.metalMine: 5, BuildingKind.solarPlant: 5})),
      t0,
      rules,
      seed: 42,
      eventId: 1,
    );
    final end = t0.add(const Duration(days: 3));
    final a = advance(start, end, rules);
    final b = advance(start, end, rules);

    expect(a.reports.length, inInclusiveRange(4, 12));
    expect(a.reports.map((r) => r.at), b.reports.map((r) => r.at));
    expect(a.state.planet.resources, b.state.planet.resources);
    expect(pendingRaid(a.state)!.id, 1);
    expect(a.state.pending, hasLength(1));
  });

  test('debug : raid détecté tout de suite', () {
    final s = ensureRaidScheduled(game(planet()), t0, rules, seed: 1, eventId: 4);
    final now = raidNow(s, t0, rules);
    final raid = pendingRaid(now)! as RaidDetected;
    expect(raid.id, 4);
    expect(raid.dueAt, t0);
    expect(raid.arrivalAt, t0.add(const Duration(hours: 1)));
  });
}
