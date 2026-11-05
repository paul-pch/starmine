import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/planet.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);

  BuildingDone build(
    BuildingKind kind,
    int target, {
    required int id,
    required DateTime due,
    Resources cost = Resources.zero,
  }) => BuildingDone(
    id: id,
    planetId: 1,
    startedAt: t0,
    dueAt: due,
    building: kind,
    targetLevel: target,
    cost: cost,
  );

  /// Référence naïve : pas d'une seconde, événements appliqués à leur seconde.
  Planet secondBySecond(Planet start, List<GameEvent> events, DateTime end) {
    var p = start;
    final queue = [...events]..sort(GameEvent.compare);
    var t = start.lastUpdate;
    while (t.isBefore(end)) {
      final next = t.add(const Duration(seconds: 1));
      p = p.copyWith(resources: rules.produce(p, const Duration(seconds: 1)), lastUpdate: next);
      while (queue.isNotEmpty && !queue.first.dueAt.isAfter(next)) {
        final e = queue.removeAt(0) as BuildingDone;
        p = p.withLevel(e.building, e.targetLevel);
      }
      t = next;
    }
    return p;
  }

  void expectSameResources(Resources actual, Resources expected) {
    for (final k in ResourceKind.values) {
      expect(actual[k], closeTo(expected[k], 1e-6 * math.max(1, expected[k])), reason: k.name);
    }
  }

  test('rattrapage de 12 h avec 2 fins de construction = simulation seconde par seconde', () {
    final start = planet(
      levels: {
        BuildingKind.metalMine: 3,
        BuildingKind.crystalMine: 2,
        BuildingKind.deuteriumSynthesizer: 1,
        BuildingKind.solarPlant: 3,
      },
      resources: const Resources(metal: 1000, crystal: 800, deuterium: 50),
    );
    // Énergie déjà négative (facteur < 1), aggravée par la mine 4, rétablie par la centrale 4.
    final events = <GameEvent>[
      build(BuildingKind.metalMine, 4, id: 1, due: t0.add(const Duration(hours: 2, seconds: 17))),
      build(BuildingKind.solarPlant, 4, id: 2, due: t0.add(const Duration(hours: 7, minutes: 3))),
    ];
    final end = t0.add(const Duration(hours: 12));

    final result = advance(GameState(planet: start, pending: events), end, rules);
    final reference = secondBySecond(start, events, end);

    expect(result.applied.map((e) => e.id), [1, 2]);
    expect(result.state.pending, isEmpty);
    expect(result.state.planet.levels, reference.levels);
    expect(result.state.planet.lastUpdate, end);
    expectSameResources(result.state.planet.resources, reference.resources);
  });

  test('les événements futurs restent en attente', () {
    final e = build(BuildingKind.metalMine, 1, id: 1, due: t0.add(const Duration(hours: 5)));
    final result = advance(
      GameState(planet: planet(), pending: [e]),
      t0.add(const Duration(hours: 1)),
      rules,
    );
    expect(result.applied, isEmpty);
    expect(result.state.pending, [e]);
    expect(result.state.planet.level(BuildingKind.metalMine), 0);
  });

  test('le stockage plafonne pendant le rattrapage', () {
    final start = planet(resources: const Resources(metal: 9990, crystal: 0));
    final after = advance(
      GameState(planet: start, pending: const []),
      t0.add(const Duration(days: 30)),
      rules,
    ).state.planet;
    expect(after.resources.metal, 10000);
    expect(after.resources.crystal, 10000);
  });

  test('un stock au-dessus de la capacité est conservé, sans production', () {
    final start = planet(resources: const Resources(metal: 12000));
    final after = advance(
      GameState(planet: start, pending: const []),
      t0.add(const Duration(hours: 3)),
      rules,
    ).state.planet;
    expect(after.resources.metal, 12000);
  });

  test('horloge reculée : aucun effet', () {
    final state = GameState(planet: planet(), pending: const []);
    final result = advance(state, t0.subtract(const Duration(hours: 1)), rules);
    expect(result.state, same(state));
  });

  group('construction', () {
    test('lancement : débit immédiat, événement à la bonne échéance', () {
      final state = GameState(planet: planet(), pending: const []);
      final outcome = startBuilding(state, BuildingKind.metalMine, t0, rules, eventId: 7);

      expect(outcome, isA<BuildStarted>());
      final started = outcome as BuildStarted;
      expect(started.event.id, 7);
      expect(started.event.targetLevel, 1);
      expect(started.event.dueAt, t0.add(const Duration(seconds: 108)));
      expect(started.state.planet.resources, const Resources(metal: 440, crystal: 485));
      expect(started.state.currentConstruction, started.event);
    });

    test('file à 1 slot', () {
      final state = GameState(planet: planet(), pending: const []);
      final first = startBuilding(state, BuildingKind.metalMine, t0, rules, eventId: 1);
      final second = startBuilding(first.state, BuildingKind.crystalMine, t0, rules, eventId: 2);
      expect((second as BuildRejected).reason, isA<QueueBusy>());
    });

    test('ressources insuffisantes : indique le manque', () {
      final state = GameState(planet: planet(), pending: const []);
      final outcome = startBuilding(state, BuildingKind.roboticsFactory, t0, rules, eventId: 1);
      final reason = (outcome as BuildRejected).reason as NotEnoughResources;
      expect(reason.missing, const Resources(deuterium: 200));
    });

    test('annulation : remboursement intégral, même au-delà de la capacité', () {
      final full = planet(resources: const Resources(metal: 10000, crystal: 10000));
      final outcome = startBuilding(
        GameState(planet: full, pending: const []),
        BuildingKind.metalStorage,
        t0,
        rules,
        eventId: 1,
      );
      final started = outcome as BuildStarted;
      final later = t0.add(const Duration(minutes: 10));
      final cancelled = cancelBuilding(started.state, 1, later, rules);

      expect(cancelled.pending, isEmpty);
      // 9000 + production pendant 10 min (sous la capacité) + 1000 remboursés.
      final produced = rules.hourlyProduction(full.levels, tempMax: full.tempMax).metal / 6;
      expect(cancelled.planet.resources.metal, closeTo(10000 + produced, 1e-9));
      expect(cancelled.planet.level(BuildingKind.metalStorage), 0);
    });
  });

  test('nouvelle planète : ressources de départ, niveaux à 0, Tmax dans la plage', () {
    final p = Planet.create(data: gameData, random: math.Random(42), now: t0);
    expect(p.resources, const Resources(metal: 500, crystal: 500));
    expect(p.levels.values, everyElement(0));
    expect(p.tempMax, inInclusiveRange(-40, 80));
  });
}
