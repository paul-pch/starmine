import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/database.dart';
import 'package:starmine/data/game_repository.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/ui/game_controller.dart';

import '../domain/helpers.dart';
import 'fakes.dart';

void main() {
  late StarmineDatabase db;
  late FakeNotifier notifier;
  late FakeClock clock;

  GameController controller() => GameController(
    repository: GameRepository(db),
    data: gameData,
    notifier: notifier,
    clock: clock.call,
    random: math.Random(1),
  );

  setUp(() {
    db = StarmineDatabase(NativeDatabase.memory());
    notifier = FakeNotifier();
    clock = FakeClock(t0);
  });

  tearDown(() => db.close());

  test('première ouverture : nouvelle partie', () async {
    final c = controller();
    await c.init();
    expect(c.state.planet.resources, const Resources(metal: 500, crystal: 500));
    expect(c.speed, 1);
  });

  test('construction : notification programmée, puis appliquée app « fermée »', () async {
    var c = controller();
    await c.init();
    expect(await c.build(BuildingKind.metalMine), isNull);
    final event = c.state.currentConstruction!;
    // App visible : pas de notification.
    expect(notifier.scheduled, isEmpty);

    // App masquée : notification programmée à l'échéance.
    await c.onHidden();
    expect(notifier.scheduled[event.id], event.dueAt);

    // Réouverture 1 h plus tard avec un nouveau contrôleur (process tué).
    clock.advance(const Duration(hours: 1));
    c = controller();
    await c.init();
    expect(c.state.currentConstruction, isNull);
    expect(c.state.planet.level(BuildingKind.metalMine), 1);
  });

  test('refus si la file est occupée', () async {
    final c = controller();
    await c.init();
    await c.build(BuildingKind.metalMine);
    expect(await c.build(BuildingKind.solarPlant), isA<QueueBusy>());
  });

  test('annulation : remboursement et notification supprimée', () async {
    final c = controller();
    await c.init();
    await c.build(BuildingKind.solarPlant);
    final id = c.state.currentConstruction!.id;
    await c.cancel(id);
    expect(c.state.currentConstruction, isNull);
    expect(c.state.planet.resources, const Resources(metal: 500, crystal: 500));
    expect(notifier.scheduled, isEmpty);
  });

  test('export → reset → import : partie identique', () async {
    final c = controller();
    await c.init();
    await c.setSpeed(10);
    await c.build(BuildingKind.crystalMine);
    clock.advance(const Duration(seconds: 3));
    final json = await c.exportJson();
    final before = c.state;

    await c.reset();
    expect(c.state.currentConstruction, isNull);
    expect(notifier.scheduled, isEmpty);

    await c.importJson(json);
    expect(c.speed, 10);
    expect(c.state.planet.resources, before.planet.resources);
    expect(c.state.planet.levels, before.planet.levels);
    expect(c.state.planet.tempMax, before.planet.tempMax);
    final restored = c.state.currentConstruction!;
    expect(restored.dueAt, before.currentConstruction!.dueAt);
    await c.onHidden();
    expect(notifier.scheduled[restored.id], restored.dueAt);
  });

  test('retour au premier plan : notifications retirées, temps rattrapé', () async {
    final c = controller();
    await c.init();
    await c.build(BuildingKind.metalMine);
    await c.onHidden();
    expect(notifier.scheduled, hasLength(1));

    clock.advance(const Duration(hours: 1));
    await c.onVisible();
    expect(notifier.scheduled, isEmpty);
    expect(c.state.planet.level(BuildingKind.metalMine), 1);
  });

  test('construction lancée app masquée (rare) : notifiée directement', () async {
    final c = controller();
    await c.init();
    await c.onHidden();
    await c.build(BuildingKind.metalMine);
    expect(notifier.scheduled, hasLength(1));
  });

  test('import invalide : FormatException, partie intacte', () async {
    final c = controller();
    await c.init();
    final before = c.state.planet.resources;
    await expectLater(c.importJson('{"format":"autre"}'), throwsFormatException);
    expect(c.state.planet.resources, before);
  });
}
