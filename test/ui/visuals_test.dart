import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/ui/visuals.dart';

void main() {
  const mine = BuildingKind.metalMine;
  const t1 = 'assets/visuels/building.metal_mine.t1.webp';
  const t2 = 'assets/visuels/building.metal_mine.t2.webp';

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

  test('palier sans image : palier inférieur, sinon repli', () {
    const visuals = Visuals(assets: {t1});
    expect(visuals.building(mine, 25), t1);
    expect(const Visuals(assets: {t2}).building(mine, 25), t2);
    expect(const Visuals(assets: {t2}).building(mine, 1), isNull);
    expect(const Visuals().building(mine, 1), isNull);
  });

  test('ambiance Sobre : aucune image', () {
    const visuals = Visuals(assets: {t1}, ambiance: Ambiance.plain);
    expect(visuals.building(mine, 1), isNull);
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
}
