import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/database.dart';
import 'package:starmine/data/game_repository.dart';
import 'package:starmine/data/save_codec.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/main.dart';
import 'package:starmine/ui/format.dart';
import 'package:starmine/ui/game_controller.dart';
import 'package:starmine/domain/story.dart';
import 'package:starmine/ui/visuals.dart';
import 'package:starmine/ui/widgets/event_popover.dart';
import 'package:starmine/ui/widgets/grid_card.dart';

import '../domain/helpers.dart';
import 'fakes.dart';

void main() {
  /// Téléphone de référence : 390 × 844 dp.
  Future<(GameController, StarmineDatabase)> open(WidgetTester tester, {FakeClock? clock}) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.reset);
    final db = StarmineDatabase(NativeDatabase.memory());
    final controller = GameController(
      repository: GameRepository(db),
      data: gameData,
      notifier: FakeNotifier(),
      clock: (clock ?? FakeClock(t0)).call,
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
    // Puces en icônes, sans défilement ; le filtre actif est écrit sous les puces.
    await tester.tap(find.widgetWithIcon(ChoiceChip, Icons.gps_fixed));
    await tester.pump();
    expect(find.text('Combat'), findsOneWidget);
    expect(find.text('Technologie Armes'), findsOneWidget);
    expect(find.text('Technologie Énergie'), findsNothing);

    await tester.tap(find.text('Chantier'));
    await tester.pump();
    expect(find.text('Lanceur de missiles'), findsOneWidget);

    await tester.tap(find.text('File'));
    await tester.pump();
    expect(find.text('Aucune construction en cours'), findsOneWidget);
    expect(find.textContaining('Construis un laboratoire'), findsOneWidget);
    expect(find.textContaining('Construis un chantier spatial'), findsOneWidget);

    await tester.tap(find.byTooltip('Debug'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
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

  testWidgets('ambiance Immersive : même information, cartes en grille', (tester) async {
    final (controller, db) = await open(tester);

    await tester.runAsync(() => controller.setAmbiance(Ambiance.immersive));
    await tester.pump();
    expect(find.text(controller.state.planet.name), findsOneWidget);
    expect(find.byKey(const ValueKey('resource.metal')), findsOneWidget);
    expect(find.text('Mine de métal'), findsOneWidget);
    expect(find.textContaining('Niv. 0 · '), findsWidgets);
    expect(find.byType(GridCard), findsWidgets);

    await tester.tap(find.text('Mine de métal'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Niveau suivant'), findsOneWidget);

    await close(tester, db);
  });

  testWidgets('filtre « Réalisables » : masque, liste vide, mémorisé par onglet', (tester) async {
    final (controller, db) = await open(tester);

    expect(find.widgetWithIcon(ChoiceChip, Icons.task_alt), findsOneWidget);
    await tester.runAsync(() => controller.setRealizableOnly('buildings', true));
    await tester.pump();
    expect(find.text('Mine de métal'), findsOneWidget);
    expect(find.text('Usine de nanites'), findsNothing);
    expect(find.text('Réalisables · Tout'), findsOneWidget);

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

  testWidgets('événement app ouvert : popover, puis journal unique avec effacement', (
    tester,
  ) async {
    final clock = FakeClock(t0);
    final (controller, db) = await open(tester, clock: clock);

    // L'événement échoit à l'instant ; il survient au rattrapage suivant.
    await tester.runAsync(controller.storyNow);
    clock.advance(const Duration(seconds: 1));
    await tester.runAsync(controller.refresh);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final o = controller.lastStory!;
    final spec = controller.data.story.catalog[o.key]!;
    expect(find.byType(EventPopover), findsOneWidget);
    expect(find.text(spec.description), findsOneWidget);
    await tester.tap(find.text(o.kind == StoryOutcomeKind.awaiting ? 'Plus tard' : 'Fermer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(EventPopover), findsNothing);

    await tester.tap(find.byIcon(Icons.article_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Effacer le journal'), findsOneWidget);
    expect(find.text('Raids'), findsNothing);
    expect(find.textContaining(spec.name), findsOneWidget);

    await close(tester, db);
  });

  testWidgets('réponse à un pari : popover avec l’issue et les effets obtenus', (tester) async {
    final (controller, db) = await open(tester);
    final chain = controller.state.pending.whereType<StoryEvent>().single;
    final waiting = StoryEvent.chain(
      id: chain.id,
      planetId: chain.planetId,
      seed: 1,
      accrueAt: t0.add(const Duration(hours: 9)),
      choiceKey: 'unstable_wreck',
      deadline: t0.add(const Duration(hours: 6)),
    );
    final save = SaveGame(
      state: controller.state.copyWith(
        pending: [for (final e in controller.state.pending) e.id == chain.id ? waiting : e],
      ),
      speed: controller.speed,
      seed: 1,
    );
    await tester.runAsync(
      () => controller.importJson(jsonEncode(encodeSave(save, exportedAt: t0))),
    );
    await tester.runAsync(() => controller.answerChoice(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final o = controller.lastStory!;
    expect(o.kind, StoryOutcomeKind.answered);
    expect(find.byType(EventPopover), findsOneWidget);
    expect(find.text('Épave instable : pari ${o.won! ? 'réussi' : 'raté'}'), findsOneWidget);
    expect(find.text('Choix : Fouiller'), findsOneWidget);

    await close(tester, db);
  });

  testWidgets('recyclage de la planète : feuille avec transporteurs, collecte en cours', (
    tester,
  ) async {
    final (controller, db) = await open(tester);
    final p = controller.state.planet;
    final save = SaveGame(
      state: controller.state.copyWith(
        planet: p.copyWith(
          units: {...p.units, UnitKind.recycler: 1, UnitKind.largeCargo: 2},
          debris: const Resources(metal: 100000, crystal: 40000),
        ),
      ),
      speed: controller.speed,
      seed: 1,
    );
    await tester.runAsync(
      () => controller.importJson(jsonEncode(encodeSave(save, exportedAt: t0))),
    );
    await tester.pump();
    await tester.tap(find.text('Flotte'));
    await tester.pump();
    expect(find.text('Champ de débris'), findsOneWidget);
    await tester.tap(find.text('Recycler'));
    await tester.pumpAndSettle();
    expect(find.text('Recyclage · Champ de la planète'), findsOneWidget);
    expect(find.text('Juste assez'), findsOneWidget);
    // Juste assez : le recycleur et les deux grands transporteurs, 70 000 sur 140 000.
    expect(find.text('Reste dans le champ ${fmtAmount(70000)}'), findsOneWidget);
    expect(find.text('Débit ${fmtAmount(20000)} / h (1 recycleur)'), findsOneWidget);
    expect(find.textContaining('Collecte '), findsWidgets);
    await tester.ensureVisible(find.text('Envoyer'));
    await tester.tap(find.text('Envoyer'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('Collecté 0 / ${fmtAmount(70000)}'), findsOneWidget);

    await close(tester, db);
  });

  testWidgets('feuille de détail : vignette de l’élément (scope des images hors de l’écran)', (
    tester,
  ) async {
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
    await tester.runAsync(controller.init);
    const path = 'assets/visuels/research.energy_technology.webp';
    await tester.pumpWidget(
      StarmineApp(
        controller: controller,
        visuals: const Visuals(assets: {path}),
      ),
    );

    await tester.tap(find.text('Recherche'));
    await tester.pump();
    bool withPath(Widget w) => w is GameImage && w.path == path;
    expect(find.byWidgetPredicate(withPath), findsOneWidget);
    await tester.tap(find.text('Technologie Énergie'));
    await tester.pump(const Duration(milliseconds: 500));
    // La carte et la feuille de détail.
    expect(find.byWidgetPredicate(withPath), findsNWidgets(2));

    await close(tester, db);
  });
}
