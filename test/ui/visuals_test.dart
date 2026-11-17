import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/game_data_loader.dart';
import 'package:starmine/domain/combat.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/raid.dart';
import 'package:starmine/ui/visuals.dart';

void main() {
  const mine = BuildingKind.metalMine;
  const temperate = 20;
  const cold = -10;
  const hot = 60;
  const t1 = 'assets/visuels/building.metal_mine.t1.temperate.webp';
  const t2 = 'assets/visuels/building.metal_mine.t2.temperate.webp';
  const t1Cold = 'assets/visuels/building.metal_mine.t1.cold.webp';
  const t1Hot = 'assets/visuels/building.metal_mine.t1.hot.webp';

  test('palier selon le niveau et les seuils', () {
    expect(buildingTier(mine, 0), 1);
    expect(buildingTier(mine, 9), 1);
    expect(buildingTier(mine, 10), 2);
    expect(buildingTier(mine, 20), 3);
    expect(buildingTier(BuildingKind.naniteFactory, 4), 2);
    expect(buildingTier(BuildingKind.naniteFactory, 8), 3);
  });

  test('tranche de température selon Tmax', () {
    expect(TemperatureBand.of(-1), TemperatureBand.cold);
    expect(TemperatureBand.of(0), TemperatureBand.temperate);
    expect(TemperatureBand.of(39), TemperatureBand.temperate);
    expect(TemperatureBand.of(40), TemperatureBand.hot);
  });

  test('image du climat de la planète', () {
    const visuals = Visuals(assets: {t1, t1Cold, t1Hot});
    expect(visuals.building(mine, 1, cold), t1Cold);
    expect(visuals.building(mine, 1, temperate), t1);
    expect(visuals.building(mine, 1, hot), t1Hot);
  });

  test('climat sans image : repli, jamais un autre climat', () {
    expect(const Visuals(assets: {t1}).building(mine, 1, cold), isNull);
  });

  test('palier sans image : palier inférieur, sinon repli', () {
    const visuals = Visuals(assets: {t1});
    expect(visuals.building(mine, 25, temperate), t1);
    expect(const Visuals(assets: {t2}).building(mine, 25, temperate), t2);
    expect(const Visuals(assets: {t2}).building(mine, 1, temperate), isNull);
    expect(const Visuals().building(mine, 1, temperate), isNull);
  });

  test('unité : défense ou vaisseau selon le YAML', () {
    final data = parseGameData(File(gameDataAsset).readAsStringSync());
    const defense = 'assets/visuels/defense.rocket_launcher.webp';
    const ship = 'assets/visuels/ship.small_cargo.webp';
    const visuals = Visuals(assets: {defense, ship});
    expect(visuals.unit(data.unit(UnitKind.rocketLauncher)), defense);
    expect(visuals.unit(data.unit(UnitKind.smallCargo)), ship);
    expect(visuals.unit(data.unit(UnitKind.cruiser)), isNull);
  });

  test('fin de combat : scène selon le camp du joueur et le vainqueur', () {
    String scene(String key) => 'assets/visuels/scene.$key.webp';
    final visuals = Visuals(
      assets: {for (final k in ['raid_won', 'raid_lost', 'attack_won', 'attack_lost', 'debris']) scene(k)},
    );
    RaidReport report(
      CombatWinner winner, {
      String? baseName,
      bool patrol = false,
      bool simulated = false,
      ExpeditionOutcome? expedition,
    }) => RaidReport(
      at: DateTime.utc(2026),
      winner: winner,
      rounds: 1,
      attackerStart: const {},
      attackerLeft: const {},
      defenderStart: const {},
      defenderLeft: const {},
      rebuilt: const {},
      baseName: baseName,
      patrol: patrol,
      simulated: simulated,
      expedition: expedition,
    );
    expect(visuals.combat(report(CombatWinner.defender)), scene('raid_won'));
    expect(visuals.combat(report(CombatWinner.attacker)), scene('raid_lost'));
    expect(visuals.combat(report(CombatWinner.attacker, baseName: 'Repaire')), scene('attack_won'));
    expect(visuals.combat(report(CombatWinner.defender, baseName: 'Repaire')), scene('attack_lost'));
    expect(visuals.combat(report(CombatWinner.draw)), isNull);
    expect(visuals.combat(report(CombatWinner.attacker, baseName: 'Repaire', patrol: true)), isNull);
    expect(visuals.combat(report(CombatWinner.defender, simulated: true)), isNull);
    expect(
      visuals.combat(report(CombatWinner.attacker, expedition: ExpeditionOutcome.ambush)),
      isNull,
    );
    expect(visuals.debris, scene('debris'));
    expect(const Visuals().debris, isNull);
  });

  test('menace pirate : raid à venir et base par son rang', () {
    const raid = 'assets/visuels/scene.raid_incoming.webp';
    const base = 'assets/visuels/pirate_base.2.webp';
    const visuals = Visuals(assets: {raid, base});
    expect(visuals.raidIncoming, raid);
    expect(visuals.pirateBase(2), base);
    expect(visuals.pirateBase(3), isNull);
    expect(const Visuals(assets: {raid, base}, ambiance: Ambiance.plain).pirateBase(2), isNull);
  });

  test('ambiance Sobre : aucune image', () {
    const visuals = Visuals(assets: {t1}, ambiance: Ambiance.plain);
    expect(visuals.building(mine, 1, temperate), isNull);
  });

  test('ambiance inconnue : Équilibrée', () {
    expect(Ambiance.fromName(null), Ambiance.balanced);
    expect(Ambiance.fromName('plain'), Ambiance.plain);
    expect(Ambiance.fromName('autre'), Ambiance.balanced);
  });

  testWidgets('image absente : repli sur l’icône', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameImage(path: null, icon: Icons.public, width: 64)),
    );
    expect(find.byIcon(Icons.public), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('vignette grisée : seulement avec une image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameImage(path: t1, icon: Icons.public, width: 64, grayed: true),
      ),
    );
    expect(find.byType(ColorFiltered), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: GameImage(path: null, icon: Icons.public, width: 64, grayed: true)),
    );
    expect(find.byType(ColorFiltered), findsNothing);
  });
}
