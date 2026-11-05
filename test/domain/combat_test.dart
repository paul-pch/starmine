import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/combat.dart';
import 'package:starmine/domain/game_data.dart';

import 'helpers.dart';

void main() {
  CombatResult fight(
    Map<UnitKind, int> attacker,
    Map<UnitKind, int> defender, {
    int seed = 1,
    Map<TechKind, int> attackerTech = const {},
    Map<TechKind, int> defenderTech = const {},
  }) => simulateCombat(
    gameData,
    CombatSide(units: attacker, tech: attackerTech),
    CombatSide(units: defender, tech: defenderTech),
    math.Random(seed),
  );

  test('coque = (M + C) / 10, technos +10 % par niveau', () {
    final s = UnitStats.of(gameData.unit(UnitKind.rocketLauncher), {
      TechKind.weapons: 2,
      TechKind.shielding: 1,
      TechKind.armour: 10,
    });
    expect(s.attack, closeTo(80 * 1.2, 1e-9));
    expect(s.shield, closeTo(20 * 1.1, 1e-9));
    expect(s.hull, closeTo(200 * 2, 1e-9));
    expect(gameData.unit(UnitKind.gaussCannon).hull, 3500);
  });

  test('écrasement : 200 lanceurs détruisent un chasseur au premier round', () {
    final r = fight({UnitKind.lightFighter: 1}, {UnitKind.rocketLauncher: 200});
    expect(r.winner, CombatWinner.defender);
    expect(r.rounds, hasLength(1));
    expect(r.attackerLeft, isEmpty);
    expect(r.defenderLosses, isEmpty);
  });

  test('règle du 1 % : un transporteur ne peut pas entamer un petit bouclier', () {
    final r = fight({UnitKind.smallCargo: 50}, {UnitKind.smallShieldDome: 1});
    expect(r.winner, CombatWinner.draw);
    expect(r.rounds, hasLength(6));
    expect(r.defenderLeft, {UnitKind.smallShieldDome: 1});
  });

  test('défaite de l’attaquant si plus personne', () {
    final r = fight({UnitKind.smallCargo: 3}, {UnitKind.heavyLaser: 20});
    expect(r.winner, CombatWinner.defender);
    expect(r.attackerLosses, {UnitKind.smallCargo: 3});
  });

  test('déterministe pour une graine donnée', () {
    final a = fight(
      {UnitKind.cruiser: 10, UnitKind.lightFighter: 30},
      {UnitKind.rocketLauncher: 60},
    );
    final b = fight(
      {UnitKind.cruiser: 10, UnitKind.lightFighter: 30},
      {UnitKind.rocketLauncher: 60},
    );
    expect(a.attackerLeft, b.attackerLeft);
    expect(a.defenderLeft, b.defenderLeft);
    expect(a.rounds.length, b.rounds.length);
  });

  test('tir rapide : un croiseur tire en moyenne 10 fois sur des lanceurs', () {
    var shots = 0;
    const n = 200;
    for (var seed = 0; seed < n; seed++) {
      // Lanceurs très nombreux et bien protégés : le croiseur ne vide pas la cible.
      final r = fight(
        {UnitKind.cruiser: 1},
        {UnitKind.rocketLauncher: 5000},
        seed: seed,
        defenderTech: {TechKind.armour: 20},
      );
      shots += r.rounds.first.attackerShots;
    }
    expect(shots / n, closeTo(10, 2.5));
  });

  test('reconstruction : environ 70 % des défenses détruites', () {
    final r = fight({UnitKind.battleship: 500}, {UnitKind.rocketLauncher: 1000}, seed: 3);
    expect(r.winner, CombatWinner.attacker);
    final rebuilt = r.rebuilt[UnitKind.rocketLauncher]!;
    expect(rebuilt / 1000, closeTo(0.7, 0.06));
    expect(r.defenderLeft[UnitKind.rocketLauncher], rebuilt);
  });

  test('les technos de combat font pencher la balance', () {
    var withTech = 0;
    var without = 0;
    // Pertes cumulées de l'attaquant : plus élevées face à un défenseur équipé.
    for (var seed = 0; seed < 40; seed++) {
      final base = fight({UnitKind.lightFighter: 40}, {UnitKind.rocketLauncher: 25}, seed: seed);
      final boosted = fight(
        {UnitKind.lightFighter: 40},
        {UnitKind.rocketLauncher: 25},
        seed: seed,
        defenderTech: {TechKind.weapons: 5, TechKind.shielding: 5, TechKind.armour: 5},
      );
      without += base.attackerLosses[UnitKind.lightFighter] ?? 0;
      withTech += boosted.attackerLosses[UnitKind.lightFighter] ?? 0;
    }
    expect(withTech, greaterThan(without));
  });
}
