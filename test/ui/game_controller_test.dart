import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/database.dart';
import 'package:starmine/data/game_repository.dart';
import 'package:starmine/data/save_codec.dart';
import 'package:starmine/domain/combat.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/ui/game_controller.dart';
import 'package:starmine/ui/notifications.dart';

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
    expect(await c.order(BuildingKind.metalMine), isNull);
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
    await c.order(BuildingKind.metalMine);
    expect(await c.order(BuildingKind.solarPlant), isA<QueueBusy>());
  });

  test('annulation : remboursement et notification supprimée', () async {
    final c = controller();
    await c.init();
    await c.order(BuildingKind.solarPlant);
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
    await c.order(BuildingKind.crystalMine);
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
    await c.order(BuildingKind.metalMine);
    await c.onHidden();
    // Construction + prochain raid ; aucun événement ponctuel (app ouverte seulement).
    expect(notifier.scheduled, hasLength(2));

    clock.advance(const Duration(hours: 1));
    await c.onVisible();
    expect(notifier.scheduled, isEmpty);
    expect(c.state.planet.level(BuildingKind.metalMine), 1);
  });

  test('construction lancée app masquée (rare) : notifiée directement', () async {
    final c = controller();
    await c.init();
    await c.onHidden();
    await c.order(BuildingKind.metalMine);
    expect(notifier.scheduled, containsPair(c.state.currentConstruction!.id, isNotNull));
  });

  test('raid : planifié dès la première ouverture, rapport après passage', () async {
    final c = controller();
    await c.init();
    expect(c.state.pending.whereType<RaidDetected>(), hasLength(1));
    expect(c.reports, isEmpty);

    await c.raidNow();
    clock.advance(const Duration(seconds: 1));
    await c.refresh();
    expect(c.incomingRaid, isNotNull);

    clock.advance(const Duration(hours: 1));
    await c.refresh();
    expect(c.incomingRaid, isNull);
    expect(c.reports, hasLength(1));
    expect(c.unseenReports, 1);
    // Pas de défense : les pirates gagnent et pillent.
    expect(c.reports.single.report.winner, CombatWinner.attacker);

    await c.markReportsSeen();
    expect(c.unseenReports, 0);
    // Le raid suivant est déjà planifié.
    expect(c.state.pending.whereType<RaidDetected>(), hasLength(1));
  });

  test('recherche : refusée sans labo', () async {
    final c = controller();
    await c.init();
    expect(await c.order(TechKind.energy), isA<RequirementsNotMet>());
  });

  test('réglage de production persisté au rechargement', () async {
    var c = controller();
    await c.init();
    await c.setPercent(BuildingKind.metalMine, 30);
    c = controller();
    await c.init();
    expect(c.state.planet.percent(BuildingKind.metalMine), 30);
  });

  test('chantier : refusé sans chantier spatial', () async {
    final c = controller();
    await c.init();
    expect(await c.orderUnits(UnitKind.rocketLauncher, 1), isA<RequirementsNotMet>());
  });

  test('import invalide : FormatException, partie intacte', () async {
    final c = controller();
    await c.init();
    final before = c.state.planet.resources;
    await expectLater(c.importJson('{"format":"autre"}'), throwsFormatException);
    expect(c.state.planet.resources, before);
  });

  test('file d’attente app fermée : fins prévues et annulation notifiées', () async {
    // Commandant 2 ; de quoi payer deux mines de métal, pas une troisième construction.
    await GameRepository(db).replaceAll(
      SaveGame(
        state: GameState(
          planet: planet(resources: const Resources(metal: 160, crystal: 40)),
          pending: const [],
          officers: {OfficerKind.commander: 2},
        ),
        speed: 1,
        seed: 3,
      ),
    );
    final c = controller();
    await c.init();
    expect(await c.order(BuildingKind.metalMine), isNull);
    expect(await c.order(BuildingKind.metalMine), isNull);
    expect(await c.order(BuildingKind.researchLab), isNull);
    expect(c.state.queue, hasLength(2));

    await c.onHidden();
    final second = c.state.queue.first;
    final third = c.state.queue.last;
    // Fin de la seconde mine prévue par simulation, et annulation de la file au tour du labo.
    expect(notifier.scheduled.containsKey(second.id), isTrue);
    expect(notifier.scheduled.containsKey(third.id), isFalse);
    expect(notifier.scheduled.containsKey(queueCancelledNotificationId(second)), isFalse);
    expect(notifier.scheduled.containsKey(queueCancelledNotificationId(third)), isTrue);

    // Rattrapage : la file a bien été annulée.
    clock.advance(const Duration(days: 1));
    await c.onVisible();
    expect(c.state.queue, isEmpty);
    expect(c.state.planet.level(BuildingKind.metalMine), 2);
    expect(c.queueCancelledCount, 1);
  });
}
