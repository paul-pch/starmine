// Cibles d'équilibrage figées (skill starmine-balance) : un réglage futur qui les casse doit
// être une décision, pas un accident.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/fleet.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/raid.dart';
import 'package:starmine/domain/resources.dart';

import 'bot.dart';

void main() {
  test('coup de pouce : début rapide, production sans chute', () {
    // Sans événements : une tempête solaire baisse l'énergie, ce n'est pas le coup de pouce.
    final data = variant(
      (m) => (m['story_events'] as Map<String, dynamic>)['catalog'] = <String, dynamic>{},
    );
    final run = Run('cible', data)..play(days: 10, verbose: false);
    expect(run.actionsByDay[0], greaterThanOrEqualTo(40));
    expect(run.worstDrop, lessThan(0.15));
  });

  test('bases pirates : dures à gagner, rentables avec la bonne flotte', () {
    final run = Run('cible', variant((_) {}))..play(days: 7, verbose: false);
    for (final b in run.s.bases) {
      final costs = [
        for (final ship in [UnitKind.lightFighter, UnitKind.cruiser]) attackCost(run, b, ship),
      ];
      final best = costs.reduce((a, c) => a.net > c.net ? a : c);
      final name = run.data.pirateBases.list[b.index].name;
      // Dure : quelle que soit la flotte, il en faut une plus chère que la base.
      for (final c in costs) {
        expect(c.fleet, greaterThan(c.defense), reason: name);
      }
      // Rentable avec la bonne flotte.
      expect(best.net, greaterThan(0), reason: name);
    }
  });

  test('plafond de vaisseaux : chaque base prenable au plafond maximal (V3c)', () {
    final run = Run('cible', variant((_) {}))..play(days: 7, verbose: false);
    final f = run.data.fleet;
    final maxCap = f.shipsBase + f.shipsPerLevel * f.shipsMaxLevel;
    for (final b in run.s.bases) {
      final c = attackCost(run, b, UnitKind.cruiser);
      final name = run.data.pirateBases.list[b.index].name;
      // ignore: avoid_print
      print('BALANCE|plafond|$name|croiseurs=${c.count}|plafond=$maxCap');
      expect(c.count, lessThanOrEqualTo(maxCap), reason: name);
    }
  });

  test('expédition : rentable en moyenne (V3c)', () {
    final run = Run('cible', variant((_) {}))..play(days: 7, verbose: false);
    final rules = run.rules;
    final data = run.data;
    const ships = {UnitKind.largeCargo: 5, UnitKind.cruiser: 5};
    final p = run.s.planet;
    final start = run.s.copyWith(
      pending: const [],
      research: {...run.s.research, TechKind.computer: 10},
      planet: p.copyWith(
        units: {for (final k in UnitKind.values) k: p.count(k) + (ships[k] ?? 0)},
        resources: p.resources + const Resources(deuterium: 1e6),
      ),
    );
    final at = p.lastUpdate;
    var net = 0.0;
    const n = 300;
    for (var seed = 0; seed < n; seed++) {
      final out = sendMission(
        start,
        MissionKind.expedition,
        null,
        ships,
        100,
        at,
        rules,
        eventId: 900,
        seed: seed,
        exploreHours: 4,
      );
      final fuel = start.planet.resources.deuterium - out.state.planet.resources.deuterium;
      final arrived = advance(out.state, missions(out.state).single.dueAt, rules).state;
      final r = advance(arrived, missions(arrived).single.dueAt, rules);
      final rep = r.reports.single;
      final back = missions(r.state).firstOrNull;
      final cargo = back?.cargo ?? Resources.zero;
      final lost =
          fleetValue(ships, data) -
          fleetValue(rep.attackerLeft, data) +
          fleetValue(rep.found, data);
      net +=
          cargo.metal +
          cargo.crystal +
          cargo.deuterium +
          fleetValue(rep.found, data) -
          math.max(0.0, lost) -
          fuel;
    }
    // ignore: avoid_print
    print('BALANCE|expedition|net_moyen=${(net / n).round()}');
    expect(net / n, greaterThan(0));
  });
}
