import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/combat.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/fleet.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/raid.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);
  const rich = Resources(metal: 1e6, crystal: 1e6, deuterium: 1e6);

  RaidArrival arrival(Map<UnitKind, int> fleet, {int seed = 1}) =>
      RaidArrival(id: 9, planetId: 1, dueAt: t0, detectedAt: t0, fleet: fleet, seed: seed);

  test('vaisseaux constructibles au chantier, prérequis compris', () {
    final s = game(
      planet(levels: {BuildingKind.shipyard: 1}, resources: rich),
      research: {TechKind.combustion: 1},
    );
    final out = startBatch(s, UnitKind.lightFighter, 5, t0, rules, eventId: 1);
    expect(out, isA<BatchStarted>());
    final done = advance(out.state, (out as BatchStarted).batch.finishAt, rules).state;
    expect(done.planet.count(UnitKind.lightFighter), 5);
    expect(checkBatch(s, UnitKind.recycler, 1, rules), isA<RequirementsNotMet>());
  });

  test('la flotte défend la planète ; elle ne compte pas dans la base des raids', () {
    final fleet = game(planet(units: {UnitKind.battleship: 20}));
    final step = resolveRaid(fleet, arrival({UnitKind.lightFighter: 10}), rules);
    expect(step.report!.winner, CombatWinner.defender);
    expect(economyPoints(fleet, rules), 0);
    expect(points(fleet, rules), greaterThan(0));
  });

  test('débris : 30 % du métal et du cristal des vaisseaux détruits, pas des défenses', () {
    final s = game(planet(units: {UnitKind.battleship: 20}));
    final step = resolveRaid(s, arrival({UnitKind.lightFighter: 10}), rules);
    final lost =
        step.report!.attackerStart[UnitKind.lightFighter]! -
        (step.report!.attackerLeft[UnitKind.lightFighter] ?? 0);
    expect(lost, greaterThan(0));
    final expected = Resources(metal: lost * 3000 * 0.3, crystal: lost * 1000 * 0.3);
    expect(step.report!.debris, expected);
    expect(step.state.planet.debris, expected);

    final defended = game(planet(units: {UnitKind.rocketLauncher: 200}));
    final big = resolveRaid(defended, arrival({UnitKind.battleship: 100}, seed: 3), rules);
    // Seuls les vaisseaux pirates détruits laissent des débris.
    final pirateLost = 100 - (big.report!.attackerLeft[UnitKind.battleship] ?? 0);
    expect(big.report!.debris.metal, closeTo(pirateLost * 45000 * 0.3, 1e-6));
  });

  group('recyclage du champ de la planète', () {
    GameState withDebris(Map<UnitKind, int> units, Resources debris) =>
        game(planet(units: units).copyWith(debris: debris));

    ({GameState state, MissionBlock? block}) recycle(
      GameState s,
      Map<UnitKind, int> ships, {
      DateTime? at,
      int id = 1,
    }) => sendMission(
      s,
      MissionKind.recycle,
      null,
      ships,
      100,
      at ?? t0,
      rules,
      eventId: id,
      seed: 1,
    );

    test('refus : sans débris, sans recycleur ; transporteurs dans le plafond', () {
      final empty = withDebris({UnitKind.recycler: 2}, Resources.zero);
      expect(recycle(empty, {UnitKind.recycler: 1}).block, MissionBlock.noDebris);
      final s = withDebris({
        UnitKind.recycler: 1,
        UnitKind.smallCargo: 500,
      }, const Resources(metal: 100));
      expect(recycle(s, {UnitKind.smallCargo: 1}).block, MissionBlock.noRecycler);
      final cap = shipCap(s, gameData);
      expect(
        recycle(s, {UnitKind.recycler: 1, UnitKind.smallCargo: cap + 1}).block,
        MissionBlock.overCap,
      );
    });

    test('collecte : débris réservés au départ, durée selon le débit des recycleurs', () {
      final s = withDebris({
        UnitKind.recycler: 1,
        UnitKind.largeCargo: 2,
      }, const Resources(metal: 100000, crystal: 40000));
      final out = recycle(s, {UnitKind.recycler: 1, UnitKind.largeCargo: 2});
      expect(out.block, isNull);
      // Soute 70 000 sur 140 000 : la moitié de chaque, retirée du champ tout de suite.
      expect(out.state.planet.debris, const Resources(metal: 50000, crystal: 20000));
      expect(out.state.planet.count(UnitKind.largeCargo), 0);
      final m = missions(out.state).single;
      expect(m.exploring, isTrue);
      expect(m.cargo, const Resources(metal: 50000, crystal: 20000));
      // 70 000 pour un recycleur de 20 000 : 3,5 fois la durée de base.
      expect(m.dueAt, t0.add(const Duration(minutes: 210)));
      final back = advance(out.state, m.dueAt, rules).state;
      expect(missions(back), isEmpty);
      expect(back.planet.count(UnitKind.recycler), 1);
      expect(back.planet.count(UnitKind.largeCargo), 2);
      expect(back.planet.debris, const Resources(metal: 50000, crystal: 20000));
      final produced = rules.produce(s.planet, s.research, const Duration(minutes: 210));
      expect(back.planet.resources.metal, closeTo(produced.metal + 50000, 1e-6));
      expect(back.planet.resources.crystal, closeTo(produced.crystal + 20000, 1e-6));
    });

    test('plancher : un petit champ prend la durée de base', () {
      final s = withDebris({UnitKind.recycler: 3}, const Resources(metal: 9000, crystal: 3000));
      final m = missions(recycle(s, {UnitKind.recycler: 3}).state).single;
      expect(m.dueAt, t0.add(const Duration(hours: 1)));
      expect(
        collectDuration(const Resources(metal: 60000), {UnitKind.recycler: 1}, rules),
        const Duration(hours: 3),
      );
    });

    test('deux missions sur le même champ : la seconde prend le reste', () {
      final s = withDebris({UnitKind.recycler: 2}, const Resources(metal: 30000));
      final first = recycle(s, {UnitKind.recycler: 1});
      final second = recycle(first.state, {UnitKind.recycler: 1}, id: 2);
      expect(second.block, isNull);
      expect(missions(second.state).map((m) => m.cargo.metal), [20000, 10000]);
      expect(second.state.planet.debris, Resources.zero);
      expect(recycle(second.state, {UnitKind.recycler: 1}, id: 3).block, isNotNull);
    });

    test('rappel pendant la collecte : la part ramassée rentre, le reste au champ', () {
      final s = withDebris({UnitKind.recycler: 1}, const Resources(metal: 20000, crystal: 20000));
      final out = recycle(s, {UnitKind.recycler: 1});
      final half = t0.add(const Duration(minutes: 30));
      final r = recallMission(out.state, 1, half, rules);
      expect(missions(r), isEmpty);
      expect(r.planet.count(UnitKind.recycler), 1);
      expect(r.planet.debris, const Resources(metal: 15000, crystal: 15000));
      final produced = rules.produce(s.planet, s.research, const Duration(minutes: 30));
      expect(r.planet.resources.metal, closeTo(produced.metal + 5000, 1e-6));
    });

    test('ancienne mission de recyclage (sauvegarde antérieure) : encore appliquée', () {
      final s = withDebris({}, const Resources(metal: 30000, crystal: 10000)).copyWith(
        pending: [
          RecycleMission(
            id: 1,
            planetId: 1,
            dueAt: t0.add(const Duration(hours: 1)),
            startedAt: t0,
            recyclers: 1,
          ),
        ],
      );
      final back = advance(s, t0.add(const Duration(hours: 1)), rules).state;
      expect(back.planet.count(UnitKind.recycler), 1);
      expect(back.planet.debris, const Resources(metal: 15000, crystal: 5000));
    });
  });
}
