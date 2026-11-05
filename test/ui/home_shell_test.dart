import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/database.dart';
import 'package:starmine/data/game_repository.dart';
import 'package:starmine/main.dart';
import 'package:starmine/ui/game_controller.dart';

import '../domain/helpers.dart';
import 'fakes.dart';

void main() {
  testWidgets('écran principal : ressources, bâtiments, onglets', (tester) async {
    final db = StarmineDatabase(NativeDatabase.memory());
    final controller = GameController(
      repository: GameRepository(db),
      data: gameData,
      notifier: FakeNotifier(),
      clock: FakeClock(t0).call,
      random: math.Random(1),
    );
    // La base fait de vraies entrées/sorties : hors de la zone de temps simulé.
    await tester.runAsync(controller.init);

    await tester.pumpWidget(StarmineApp(controller: controller));
    expect(find.text('Métal'), findsOneWidget);
    expect(find.text('Mine de métal'), findsOneWidget);
    final tMax = controller.state.planet.tempMax;
    expect(find.text('Température ${tMax - 40} °C à $tMax °C'), findsOneWidget);
    expect(find.text('Niv. 1'), findsWidgets);

    await tester.tap(find.text('Recherche'));
    await tester.pump();
    expect(find.text('Technologie Énergie'), findsOneWidget);
    expect(find.text('Palier 1'), findsOneWidget);
    expect(find.textContaining('Débloque Centrale à fusion'), findsOneWidget);
    expect(find.textContaining('Requiert Laboratoire de recherche 1'), findsWidgets);

    await tester.tap(find.text('File'));
    await tester.pump();
    expect(find.text('Aucune construction en cours'), findsOneWidget);
    expect(find.text('Aucune recherche en cours'), findsOneWidget);

    await tester.tap(find.text('Debug'));
    await tester.pump();
    expect(find.text('Vitesse de jeu'), findsOneWidget);

    // Démonte l'écran pour arrêter l'horloge d'affichage avant la fin du test.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
