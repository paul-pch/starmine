import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/database.dart';
import 'package:starmine/data/game_repository.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/main.dart';
import 'package:starmine/ui/format.dart';
import 'package:starmine/ui/game_controller.dart';
import 'package:starmine/ui/visuals.dart';

import '../domain/helpers.dart';
import 'fakes.dart';

void main() {
  /// Téléphone de référence : 390 × 844 dp.
  Future<(GameController, StarmineDatabase)> open(WidgetTester tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.reset);
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
    return (controller, db);
  }

  /// Démonte l'écran pour arrêter l'horloge d'affichage avant la fin du test.
  Future<void> close(WidgetTester tester, StarmineDatabase db) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  }

  testWidgets('écran principal : ressources, bâtiments, onglets', (tester) async {
    final (controller, db) = await open(tester);

    expect(find.byKey(const ValueKey('resource.metal')), findsOneWidget);
    expect(find.text('Mine de métal'), findsOneWidget);
    final tMax = controller.state.planet.tempMax;
    expect(find.text(fmtTempRange(tMax - 40, tMax)), findsOneWidget);
    expect(find.textContaining('Niv. 0'), findsWidgets);

    await tester.tap(find.text('Recherche'));
    await tester.pump();
    expect(find.text('Technologie Énergie'), findsOneWidget);
    expect(find.text('Palier 1'), findsWidgets);
    expect(find.text('Fondamentales'), findsWidgets);
    expect(find.textContaining('Requiert Laboratoire de recherche 1'), findsWidgets);
    // Filtre : seules les technos de combat restent.
    // Les puces défilent, après la bascule « Réalisables ».
    await tester.dragUntilVisible(
      find.widgetWithText(ChoiceChip, 'Combat'),
      find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal),
      const Offset(-80, 0),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Combat'));
    await tester.pump();
    expect(find.text('Technologie Armes'), findsOneWidget);
    expect(find.text('Technologie Énergie'), findsNothing);

    await tester.tap(find.text('Défense'));
    await tester.pump();
    expect(find.text('Lanceur de missiles'), findsOneWidget);

    await tester.tap(find.text('File'));
    await tester.pump();
    expect(find.text('Aucune construction en cours'), findsOneWidget);
    expect(find.textContaining('Construis un laboratoire'), findsOneWidget);
    expect(find.textContaining('Construis un chantier spatial'), findsOneWidget);

    await tester.tap(find.text('Debug'));
    await tester.pump();
    expect(find.text('Vitesse de jeu'), findsOneWidget);
    expect(find.text('Ambiance'), findsOneWidget);

    await close(tester, db);
  });

  testWidgets('feuille de ressource et d’énergie', (tester) async {
    final (_, db) = await open(tester);

    await tester.tap(find.byKey(const ValueKey('resource.metal')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Métal'), findsOneWidget);
    expect(find.text('Production de base'), findsOneWidget);
    expect(find.text('Stock'), findsOneWidget);
    Navigator.of(tester.element(find.text('Stock'))).pop();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const ValueKey('resource.energy')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Produite'), findsOneWidget);
    expect(find.text('Consommée'), findsOneWidget);
    expect(find.textContaining('Le solde est'), findsOneWidget);

    await close(tester, db);
  });

  testWidgets('feuille de détail : débloque, prérequis, description', (tester) async {
    final (controller, db) = await open(tester);

    await tester.tap(find.text('Recherche'));
    await tester.pump();
    await tester.tap(find.text('Technologie Énergie'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Débloque Centrale à fusion'), findsOneWidget);
    expect(find.text(controller.data.spec(TechKind.energy).description), findsOneWidget);

    await close(tester, db);
  });

  testWidgets('carte « En cours » : ordre lancé, tap vers la file', (tester) async {
    final (controller, db) = await open(tester);

    await tester.runAsync(() => controller.order(BuildingKind.metalMine));
    await tester.pump();
    expect(find.textContaining('En cours · Mine de métal → 1'), findsOneWidget);

    await tester.tap(find.textContaining('En cours · Mine de métal'));
    await tester.pump();
    expect(find.text('Mine de métal → niveau 1'), findsOneWidget);

    await close(tester, db);
  });

  testWidgets('ambiance Sobre : même information, mémorisée', (tester) async {
    final (controller, db) = await open(tester);

    await tester.runAsync(() => controller.setAmbiance(Ambiance.plain));
    await tester.pump();
    expect(controller.ambiance, Ambiance.plain);
    expect(find.text(controller.state.planet.name), findsOneWidget);
    expect(find.text('Mine de métal'), findsOneWidget);

    final reloaded = GameController(
      repository: GameRepository(db),
      data: gameData,
      notifier: FakeNotifier(),
      clock: FakeClock(t0).call,
      random: math.Random(1),
    );
    await tester.runAsync(reloaded.init);
    expect(reloaded.ambiance, Ambiance.plain);

    await close(tester, db);
  });

  testWidgets('filtre « Réalisables » : masque, liste vide, mémorisé par onglet', (tester) async {
    final (controller, db) = await open(tester);

    expect(find.widgetWithText(FilterChip, 'Réalisables'), findsOneWidget);
    await tester.runAsync(() => controller.setRealizableOnly('buildings', true));
    await tester.pump();
    expect(find.text('Mine de métal'), findsOneWidget);
    expect(find.text('Usine de nanites'), findsNothing);

    await tester.runAsync(() => controller.setRealizableOnly('research', true));
    await tester.tap(find.text('Recherche'));
    await tester.pump();
    expect(find.text('Rien de réalisable'), findsOneWidget);
    expect(find.text('Technologie Énergie'), findsNothing);

    final reloaded = GameController(
      repository: GameRepository(db),
      data: gameData,
      notifier: FakeNotifier(),
      clock: FakeClock(t0).call,
      random: math.Random(1),
    );
    await tester.runAsync(reloaded.init);
    expect(reloaded.realizableOnly('buildings'), isTrue);
    expect(reloaded.realizableOnly('defense'), isFalse);

    await close(tester, db);
  });

  testWidgets('officiers : écran depuis le hero, prérequis, déblocage explicite', (tester) async {
    final (controller, db) = await open(tester);

    await tester.tap(find.byIcon(Icons.military_tech_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Officiers'), findsOneWidget);
    expect(find.text('Géologue'), findsOneWidget);
    expect(find.text('Mine de métal 5 (0)'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Débloquer').first,
    );
    expect(button.onPressed, isNull);
    expect(controller.availableOfficers, isEmpty);

    await close(tester, db);
  });
}
