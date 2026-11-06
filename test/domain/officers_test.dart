import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/combat.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/officers.dart';
import 'package:starmine/domain/raid.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);
  const mines = {BuildingKind.metalMine: 5, BuildingKind.crystalMine: 4};

  test('config : quatre officiers, niveaux plafonnés, compteurs en prérequis', () {
    expect(gameData.officers.keys, OfficerKind.values);
    expect(gameData.officers[OfficerKind.geologist]!.maxLevel, 5);
    expect(gameData.officers[OfficerKind.engineer]!.levels.first.counters, {
      Counter.raidsRepelled: 1,
    });
    expect(gameData.counterNames[Counter.raidsRepelled], 'Raids repoussés');
  });

  test('verrouillé au départ : refusé, rien ne change', () {
    final s = game(planet());
    expect(availableOfficers(s, gameData), isEmpty);
    final out = promoteOfficer(s, OfficerKind.geologist, t0, rules);
    expect(out.promoted, isFalse);
    expect(out.state.officers[OfficerKind.geologist], 0);
    expect(officerMissing(s, OfficerKind.geologist, gameData).requires, {
      BuildingKind.metalMine: 5,
      BuildingKind.crystalMine: 4,
    });
  });

  test('prérequis remplis : disponible, mais seulement débloqué sur commande', () {
    final s = game(planet(levels: mines));
    expect(availableOfficers(s, gameData), [OfficerKind.geologist]);
    // advance ne débloque rien tout seul.
    final later = advance(s, t0.add(const Duration(hours: 5)), rules).state;
    expect(later.officers.values, everyElement(0));
    final out = promoteOfficer(s, OfficerKind.geologist, t0, rules);
    expect(out.promoted, isTrue);
    expect(out.state.officers[OfficerKind.geologist], 1);
    expect(officerAvailable(out.state, OfficerKind.geologist, gameData), isFalse);
  });

  test('Géologue : +5 % par niveau sur les mines, appliqué à partir du déblocage', () {
    final s = game(
      planet(levels: {...mines, BuildingKind.solarPlant: 10}, resources: Resources.zero),
    );
    final promoted = promoteOfficer(s, OfficerKind.geologist, t0, rules).state;
    final base = rules.hourlyProduction(s.planet, s.research);
    final boosted = rules.hourlyProduction(s.planet, s.research, promoted.modifiers(gameData));
    final mine = base.metal - gameData.formulas.baseProductionPerHour.metal;
    expect(mine, greaterThan(0));
    expect(promoted.modifiers(gameData).mineProduction, closeTo(0.05, 1e-12));
    expect(boosted.metal - base.metal, closeTo(mine * 0.05, 1e-9));
    // Une heure après le déblocage, le stock suit la production boostée.
    final later = advance(promoted, t0.add(const Duration(hours: 1)), rules).state;
    expect(later.planet.resources.metal, closeTo(boosted.metal, 1e-6));
  });

  test('Technocrate et Architecte : durées réduites de 5 % par niveau', () {
    final s = game(
      planet(levels: {BuildingKind.researchLab: 2, BuildingKind.roboticsFactory: 2}),
      research: {TechKind.energy: 1},
    );
    final officers = {OfficerKind.technocrat: 2, OfficerKind.architect: 1};
    final fast = s.copyWith(officers: officers);
    final research = orderDuration(s, TechKind.laser, rules).inSeconds;
    final build = orderDuration(s, BuildingKind.metalMine, rules).inSeconds;
    expect(orderDuration(fast, TechKind.laser, rules).inSeconds, closeTo(research * 0.9, 1));
    expect(orderDuration(fast, BuildingKind.metalMine, rules).inSeconds, closeTo(build * 0.95, 1));
  });

  test('Ingénieur : compteur de raids repoussés en prérequis', () {
    final s = game(planet(levels: {BuildingKind.shipyard: 2}));
    expect(officerMissing(s, OfficerKind.engineer, gameData).counters, {Counter.raidsRepelled: 1});
    final repelled = s.copyWith(counters: {Counter.raidsRepelled: 1});
    expect(officerAvailable(repelled, OfficerKind.engineer, gameData), isTrue);
    final promoted = promoteOfficer(repelled, OfficerKind.engineer, t0, rules).state;
    expect(promoted.modifiers(gameData).defenseRebuild, closeTo(0.03, 1e-12));
  });

  test('plafond : plus de niveau suivant', () {
    final s = game(planet()).copyWith(officers: {OfficerKind.architect: 5});
    expect(nextOfficerLevel(s, OfficerKind.architect, gameData), isNull);
    expect(officerAvailable(s, OfficerKind.architect, gameData), isFalse);
    expect(s.modifiers(gameData).buildTime, closeTo(0.25, 1e-12));
  });

  test('raid repoussé : le compteur avance, pas en cas de défaite', () {
    RaidArrival arrival() => RaidArrival(
      id: 9,
      planetId: 1,
      dueAt: t0,
      detectedAt: t0,
      fleet: const {UnitKind.lightFighter: 3},
      seed: 1,
    );
    final defended = game(planet(units: {UnitKind.rocketLauncher: 30}));
    final win = resolveRaid(defended, arrival(), rules);
    expect(win.report!.winner, CombatWinner.defender);
    expect(win.state.counters[Counter.raidsRepelled], 1);
    final lost = resolveRaid(game(planet()), arrival(), rules);
    expect(lost.state.counters[Counter.raidsRepelled], 0);
  });
}
