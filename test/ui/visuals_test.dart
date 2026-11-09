import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';
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
