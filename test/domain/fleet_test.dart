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
  const rich = Resources(metal: 1e6, crystal: 1e6, deuterium: 1e6);

  RaidArrival arrival(Map<UnitKind, int> fleet, {int seed = 1}) => RaidArrival(
    id: 9,
    planetId: 1,
    dueAt: t0,
    detectedAt: t0,
    fleet: fleet,
    seed: seed,
  );

  test('vaisseaux constructibles au chantier, prérequis compris', () {
    final s = game(planet(levels: {BuildingKind.shipyard: 1}, resources: rich));
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
    final lost = step.report!.attackerStart[UnitKind.lightFighter]! -
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

  group('recyclage', () {
    GameState withDebris(int recyclers, Resources debris) => game(
      planet(units: {UnitKind.recycler: recyclers}).copyWith(debris: debris),
    );

    test('refus : sans débris, sans recycleur, mission déjà en cours', () {
      expect(checkRecycle(withDebris(2, Resources.zero), 1), RecycleBlock.noDebris);
      expect(
        checkRecycle(withDebris(0, const Resources(metal: 100)), 1),
        RecycleBlock.noRecycler,
      );
      final s = withDebris(2, const Resources(metal: 100));
      final out = startRecycling(s, 1, t0, rules, eventId: 1);
      expect(checkRecycle(out.state, 1), RecycleBlock.busy);
    });

    test('mission : recycleurs absents, retour avec tout le champ si la soute suffit', () {
      final s = withDebris(2, const Resources(metal: 9000, crystal: 3000));
      final out = startRecycling(s, 1, t0, rules, eventId: 1);
      expect(out.block, isNull);
      expect(out.state.planet.count(UnitKind.recycler), 1);
      final mission = currentRecycling(out.state)!;
      expect(mission.dueAt, t0.add(const Duration(hours: 1)));
      final back = advance(out.state, mission.dueAt, rules).state;
      expect(back.planet.count(UnitKind.recycler), 2);
      expect(back.planet.debris, Resources.zero);
      final produced = rules.produce(s.planet, s.research, const Duration(hours: 1));
      expect(back.planet.resources.metal, closeTo(produced.metal + 9000, 1e-6));
      expect(back.planet.resources.crystal, closeTo(produced.crystal + 3000, 1e-6));
    });

    test('soute limitée : au prorata, le reste du champ demeure', () {
      final s = withDebris(1, const Resources(metal: 30000, crystal: 10000));
      final out = startRecycling(s, 1, t0, rules, eventId: 1);
      final back = advance(out.state, currentRecycling(out.state)!.dueAt, rules).state;
      // Soute 20 000 sur 40 000 : la moitié de chaque.
      expect(back.planet.debris, const Resources(metal: 15000, crystal: 5000));
    });
  });
}
