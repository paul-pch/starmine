// Mesure d'équilibrage : variantes du coup de pouce et rentabilité des bases pirates.
// Imprime des lignes « BALANCE| » ; aucune donnée de jeu n'est modifiée.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/game_data_loader.dart';
import 'package:starmine/domain/combat.dart';
import 'package:starmine/domain/fleet.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/raid.dart';
import 'package:yaml/yaml.dart';

import 'bot.dart';

/// Config réelle avec des clés remplacées.
GameData variant(void Function(Map<String, dynamic> m) edit) {
  final m =
      (jsonDecode(jsonEncode(loadYaml(File(gameDataAsset).readAsStringSync())))
          as Map<String, dynamic>);
  edit(m);
  return GameData.fromMap(m);
}

void main() {
  test('variantes du coup de pouce', () {
    // Sans événements (une tempête solaire fausse la mesure de baisse) ; x1 = référence.
    for (final (extra, fade) in [(0, 100), (3, 100), (3, 300), (2, 300), (2, 500), (3, 1000)]) {
      final run = Run(
        'boost x${extra + 1}/$fade',
        variant((m) {
          m['start_boost'] = {'extra': extra, 'fade_points': fade};
          (m['story_events'] as Map<String, dynamic>)['catalog'] = <String, dynamic>{};
        }),
      )..play(verbose: false);
      final p = run.production;
      out(
        'boost|x${extra + 1}|fade=$fade|baisse_max_6h=${(run.worstDrop * 100).round()}%'
        '|prod_12h=${r0(p[12])}|prod_24h=${r0(p[24])}|prod_48h=${r0(p[48])}'
        '|prod_72h=${r0(p[72])}|prod_7j=${r0(p[168])}|prod_14j=${r0(p[336])}'
        '|actions_j1=${run.actionsByDay[0]}|actions_j2=${run.actionsByDay[1]}'
        '|actions_j3=${run.actionsByDay[2]}|actions_j4_7=${[3, 4, 5, 6].map((d) => run.actionsByDay[d] ?? 0).join('/')}',
      );
    }
  });

  test('bases indexées sur la production (proposition)', () {
    // Défenses = defense_hours × production horaire (×1), stock = stock_hours × production :
    // le rapport défense / butin reste constant toute la partie.
    for (final days in [3, 7, 14]) {
      final run = Run('prod', variant((_) {}))..play(days: days, verbose: false);
      final s = run.s;
      final data = run.data;
      final rules = run.rules;
      final rate = rules.hourlyProduction(s.planet, s.research, s.modifiers(data));
      final perHour = rate.metal + rate.crystal + rate.deuterium;
      final eco = economyPoints(s, rules);
      for (final (i, (name, stockHours, defenseHours)) in [
        ('Kessa', 6.0, 1.8),
        ('Croc', 12.0, 4.8),
        ('Ulvar', 24.0, 12.0),
        ('Citadelle', 48.0, 28.8),
      ].indexed) {
        final strength = defenseHours * perHour / (eco * 1000);
        final units = pirateBaseUnits(eco, strength, data, i);
        final side = CombatSide(units: units, tech: baseTech(s, rules));
        var n = 2;
        double wins = 0;
        double losses = 0;
        double debris = 0;
        while (n < 5000) {
          wins = 0;
          losses = 0;
          debris = 0;
          for (var k = 0; k < 40; k++) {
            final r = simulateCombat(
              data,
              CombatSide(units: {UnitKind.lightFighter: n}, tech: s.research),
              side,
              math.Random(k),
            );
            if (r.winner == CombatWinner.attacker) wins++;
            losses += fleetValue(r.attackerLosses, data) / 40;
            final d = combatDebris(r, data);
            debris += (d.metal + d.crystal) / 40;
          }
          if (wins / 40 >= 0.9) break;
          n = (n * 1.25).ceil();
        }
        final loot = stockHours * perHour * data.pirateBases.lootShare;
        final net = loot + debris - losses;
        out(
          'base_prod|j$days|$name|prod_h=${r0(perHour)}|unites=${r0(fleetValue(units, data))}'
          '|chasseurs=$n|pertes=${r0(losses)}|butin=${r0(loot)}|debris=${r0(debris)}'
          '|net=${r0(net)}|net_en_h_prod=${(net / perHour).toStringAsFixed(1)}',
        );
      }
    }
  });

  test('rentabilité des bases pirates', () {
    final run = Run('base', variant((_) {}))..play(verbose: false);
    final s = run.s;
    final data = run.data;
    final rules = run.rules;
    final at = s.planet.lastUpdate;
    // Flotte type : chasseurs légers aux technos du joueur ; nombre minimal pour gagner
    // 90 % de 40 combats.
    for (final b in s.bases) {
      final spec = data.pirateBases.list[b.index];
      final defender = CombatSide(units: baseUnits(s, b, at, rules), tech: baseTech(s, rules));
      final stock = total(baseStock(s, b, at, rules));
      for (final strength in [1.0, 0.5]) {
        final units = strength == 1.0
            ? defender.units
            : pirateBaseUnits(economyPoints(s, rules), spec.strength * 0.5, data, b.seed);
        final side = CombatSide(units: units, tech: defender.tech);
        var n = 5;
        double wins = 0;
        double losses = 0;
        double debris = 0;
        while (n < 5000) {
          wins = 0;
          losses = 0;
          debris = 0;
          for (var i = 0; i < 40; i++) {
            final r = simulateCombat(
              data,
              CombatSide(units: {UnitKind.lightFighter: n}, tech: s.research),
              side,
              math.Random(i),
            );
            if (r.winner == CombatWinner.attacker) wins++;
            losses += fleetValue(r.attackerLosses, data) / 40;
            final d = combatDebris(r, data);
            debris += (d.metal + d.crystal) / 40;
          }
          if (wins / 40 >= 0.9) break;
          n = (n * 1.25).ceil();
        }
        final fuel = 2 * fuelCost({UnitKind.lightFighter: n}, spec.distance, 100, data);
        final loot = stock * data.pirateBases.lootShare;
        out(
          'base_roi|${spec.name}|force×$strength|unites=${r0(fleetValue(units, data))}'
          '|chasseurs=$n|pertes=${r0(losses)}|carburant=${r0(fuel)}|butin=${r0(loot)}'
          '|debris=${r0(debris)}|net=${r0(loot + debris - losses - fuel)}'
          '|stock_par_h_de_prod=${r0(stock / spec.stockHours)}',
        );
      }
    }
    expect(s.bases, isNotEmpty);
  });
}
