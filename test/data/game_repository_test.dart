import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/data/database.dart';
import 'package:starmine/data/game_repository.dart';
import 'package:starmine/data/save_codec.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import '../domain/helpers.dart';

void main() {
  final rules = Rules(gameData);
  late StarmineDatabase db;
  late GameRepository repo;

  setUp(() {
    db = StarmineDatabase(NativeDatabase.memory());
    repo = GameRepository(db);
  });

  tearDown(() => db.close());

  SaveGame fresh() => SaveGame(
    state: GameState(planet: planet(), pending: const []),
    speed: 1,
    seed: 7,
  );

  test('base vide : aucune partie', () async {
    expect(await repo.load(), isNull);
    expect(await repo.nextEventId(), 1);
  });

  test('nouvelle partie puis rechargement', () async {
    await repo.replaceAll(fresh());
    final loaded = (await repo.load())!;
    expect(loaded.state.planet.resources, const Resources(metal: 500, crystal: 500));
    expect(loaded.state.planet.levels.values, everyElement(0));
    expect(loaded.state.planet.lastUpdate, t0);
    expect(loaded.seed, 7);
    expect(loaded.speed, 1);
  });

  test('cycle complet : lancement, rattrapage, événement marqué traité', () async {
    await repo.replaceAll(fresh());
    final id = await repo.nextEventId();
    final started =
        startOrder(fresh().state, BuildingKind.metalMine, t0, rules, eventId: id) as OrderStarted;
    await repo.save(started.state);

    var loaded = (await repo.load())!;
    final pending = loaded.state.pending.single as BuildingDone;
    expect(pending.id, id);
    expect(pending.cost, const Resources(metal: 60, crystal: 15));
    expect(loaded.state.planet.resources, const Resources(metal: 440, crystal: 485));

    final later = t0.add(const Duration(hours: 1));
    final result = advance(loaded.state, later, rules);
    await repo.save(result.state, applied: result.applied);

    loaded = (await repo.load())!;
    expect(loaded.state.pending, isEmpty);
    expect(loaded.state.planet.level(BuildingKind.metalMine), 1);
    expect(loaded.state.planet.lastUpdate, later);
    // L'identifiant reste réservé : l'historique n'est pas réutilisé.
    expect(await repo.nextEventId(), id + 1);
  });

  test('annulation : événement annulé, plus chargé', () async {
    await repo.replaceAll(fresh());
    final started =
        startOrder(fresh().state, BuildingKind.solarPlant, t0, rules, eventId: 1) as OrderStarted;
    await repo.save(started.state);
    final cancelled = cancelOrder(started.state, 1, t0, rules);
    await repo.save(cancelled, cancelledIds: [1]);

    final loaded = (await repo.load())!;
    expect(loaded.state.pending, isEmpty);
    expect(loaded.state.planet.resources, const Resources(metal: 500, crystal: 500));
  });

  test('technos et réglages de production persistés', () async {
    await repo.replaceAll(fresh());
    final state = fresh().state.copyWith(
      research: {TechKind.plasma: 3},
      planet: fresh().state.planet.copyWith(percents: {BuildingKind.crystalMine: 40}),
    );
    await repo.save(state);
    final loaded = (await repo.load())!;
    expect(loaded.state.research[TechKind.plasma], 3);
    expect(loaded.state.planet.percent(BuildingKind.crystalMine), 40);
    expect(loaded.state.planet.percent(BuildingKind.metalMine), 100);
  });

  test('vitesse de jeu persistée', () async {
    await repo.replaceAll(fresh());
    await repo.setSpeed(100);
    expect((await repo.load())!.speed, 100);
  });
}
