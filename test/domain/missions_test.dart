import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/combat.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/fleet.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);
  const fuel = Resources(metal: 1e5, crystal: 1e5, deuterium: 1e5);

  GameState world({
    Map<UnitKind, int> units = const {},
    TechLevels research = const {},
    Resources resources = fuel,
  }) => ensureBases(
    game(planet(units: units, resources: resources), research: research),
    t0,
    rules,
    seed: 3,
  );

  ({GameState state, MissionBlock? block}) send(
    GameState s,
    MissionKind kind,
    int? target,
    Map<UnitKind, int> ships, {
    int speed = 100,
    double hours = 0,
  }) => sendMission(
    s,
    kind,
    target,
    ships,
    speed,
    t0,
    rules,
    eventId: 50,
    seed: 1,
    shelterHours: hours,
  );

  test('bases : quatre, créées une fois', () {
    final s = world();
    expect(s.bases, hasLength(4));
    expect(ensureBases(s, t0, rules, seed: 9).bases.map((b) => b.seed), s.bases.map((b) => b.seed));
  });

  test('trajet : formule OGame × 3, vitesse du plus lent, réacteur, vitesse réglable', () {
    final d = gameData.pirateBases.list[0].distance;
    expect(d, 2700 + 95 * 2);
    final lf = {UnitKind.lightFighter: 1};
    final seconds = (10 + 35000 / 100 * math.sqrt(d * 10 / 12500)) * 3;
    expect(flightDuration(lf, d, 100, const {}, rules).inMilliseconds, (seconds * 1000).round());
    expect(unitSpeed(UnitKind.lightFighter, {TechKind.combustion: 2}, gameData), closeTo(15000, 1e-6));
    final mixed = {UnitKind.lightFighter: 1, UnitKind.recycler: 1};
    expect(fleetSpeed(mixed, const {}, gameData), 2000);
    expect(
      flightDuration(lf, d, 50, const {}, rules),
      greaterThan(flightDuration(lf, d, 100, const {}, rules)),
    );
    // Carburant d'un aller : 20 × d / 35 000 × (1 + 1)², arrondi au-dessus.
    expect(fuelCost(lf, d, 100, gameData), (20 * d / 35000 * 4).ceilToDouble());
    expect(fuelCost(lf, d, 50, gameData), lessThan(fuelCost(lf, d, 100, gameData)));
  });

  test('envoi : vaisseaux retirés, carburant aller-retour payé, place de flotte', () {
    final s = world(units: {UnitKind.lightFighter: 10});
    final out = send(s, MissionKind.attack, 0, {UnitKind.lightFighter: 4});
    expect(out.block, isNull);
    expect(out.state.planet.count(UnitKind.lightFighter), 6);
    final preview = missionPreview(s, MissionKind.attack, 0, {UnitKind.lightFighter: 4}, 100, rules);
    expect(out.state.planet.resources.deuterium, fuel.deuterium - preview.fuel);
    // Informatique 0 : une seule place.
    final again = sendMission(
      out.state,
      MissionKind.attack,
      1,
      {UnitKind.lightFighter: 1},
      100,
      t0,
      rules,
      eventId: 51,
      seed: 2,
    );
    expect(again.block, MissionBlock.noSlot);
    expect(send(s, MissionKind.attack, 0, {UnitKind.lightFighter: 11}).block, MissionBlock.notEnoughShips);
    final dry = world(units: {UnitKind.lightFighter: 10}, resources: Resources.zero);
    expect(send(dry, MissionKind.attack, 0, {UnitKind.lightFighter: 4}).block, MissionBlock.noFuel);
  });

  test('attaque gagnée : pillage, débris, base détruite puis remplacée, retour chargé', () {
    final s = world(units: {UnitKind.battleship: 40, UnitKind.largeCargo: 10});
    final out = send(s, MissionKind.attack, 0, {UnitKind.battleship: 40, UnitKind.largeCargo: 10});
    final m = missions(out.state).single;
    final arrived = advance(out.state, m.dueAt, rules);
    final report = arrived.reports.single;
    expect(report.baseName, gameData.pirateBases.list[0].name);
    expect(report.winner, CombatWinner.attacker);
    expect(report.loot.metal + report.loot.crystal, greaterThan(0));
    final base = arrived.state.bases[0];
    expect(baseAvailable(base, m.dueAt), isFalse);
    final back = missions(arrived.state).single;
    expect(back.returning, isTrue);
    expect(back.cargo, report.loot);

    final home = advance(arrived.state, back.dueAt, rules).state;
    expect(missions(home), isEmpty);
    expect(home.planet.count(UnitKind.battleship), 40);
    expect(home.planet.resources.metal, greaterThanOrEqualTo(fuel.metal + report.loot.metal));
    // Réapparition après 24 h : nouvelle génération, stock plein.
    final later = m.dueAt.add(const Duration(hours: 25));
    expect(baseAvailable(home.bases[0], later), isTrue);
  });

  test('espionnage : détail selon la technologie', () {
    GameState spyWith(int level) {
      final s = world(
        units: {UnitKind.espionageProbe: 1},
        research: {TechKind.espionage: level},
      );
      final out = send(s, MissionKind.spy, 1, {UnitKind.espionageProbe: 1});
      expect(out.block, isNull);
      return advance(out.state, missions(out.state).single.dueAt, rules).state;
    }

    final low = spyWith(1).bases[1].spy!;
    expect(low.resources, isNotNull);
    expect(low.ships, isNull);
    final high = spyWith(6).bases[1].spy!;
    expect(high.ships, isNotNull);
    expect(high.defenses, isNotNull);
    expect(high.tech, isNotNull);
    final s = world(units: {UnitKind.lightFighter: 1, UnitKind.espionageProbe: 1});
    expect(
      send(s, MissionKind.spy, 1, {UnitKind.lightFighter: 1}).block,
      MissionBlock.noProbe,
    );
  });

  test('rappel : demi-tour, retour en autant de temps que l’aller parcouru', () {
    final s = world(units: {UnitKind.lightFighter: 3});
    final out = send(s, MissionKind.attack, 2, {UnitKind.lightFighter: 3});
    final now = t0.add(const Duration(minutes: 10));
    final back = recallMission(out.state, 50, now, rules);
    final m = missions(back).single;
    expect(m.returning, isTrue);
    expect(m.dueAt, now.add(const Duration(minutes: 10)));
    final home = advance(back, m.dueAt, rules).state;
    expect(home.planet.count(UnitKind.lightFighter), 3);
  });

  test('mise à l’abri : absente la durée choisie, ne combat pas pendant ce temps', () {
    final s = world(units: {UnitKind.battleship: 5});
    final out = send(s, MissionKind.shelter, null, {UnitKind.battleship: 5}, hours: 4);
    expect(out.block, isNull);
    final m = missions(out.state).single;
    expect(m.returning, isTrue);
    expect(m.dueAt, t0.add(const Duration(hours: 4)));
    expect(out.state.planet.count(UnitKind.battleship), 0);
    final home = advance(out.state, m.dueAt, rules).state;
    expect(home.planet.count(UnitKind.battleship), 5);
  });

  test('défaite : flotte détruite, rien ne revient ; la base garde ses survivants', () {
    // Une sonde (sans arme) ne peut que perdre.
    final s = world(units: {UnitKind.espionageProbe: 1});
    final out = send(s, MissionKind.attack, 3, {UnitKind.espionageProbe: 1});
    final r = advance(out.state, missions(out.state).single.dueAt, rules);
    expect(r.reports.single.winner, CombatWinner.defender);
    expect(missions(r.state), isEmpty);
    expect(r.state.bases[3].survivors, isNotNull);
  });
}
