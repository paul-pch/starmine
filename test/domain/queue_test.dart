import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);
  const rich = Resources(metal: 1e6, crystal: 1e6, deuterium: 1e6);

  /// Commandant au niveau [commander] : 1 + niveau ordres dans la file de construction.
  GameState start({int commander = 2, Resources resources = rich}) =>
      game(planet(resources: resources)).copyWith(officers: {OfficerKind.commander: commander});

  GameState place(GameState s, Unlockable item, int id) {
    final out = placeOrder(s, item, t0, rules, eventId: id);
    expect(out, isNot(isA<OrderRejected>()), reason: '$item');
    return out.state;
  }

  test('sans Commandant : une seule place, file occupée', () {
    final s = place(start(commander: 0), BuildingKind.metalMine, 1);
    final out = placeOrder(s, BuildingKind.crystalMine, t0, rules, eventId: 2);
    expect((out as OrderRejected).reason, isA<QueueBusy>());
  });

  test('Commandant 2 : trois ordres, rien de payé en attente, puis file pleine', () {
    var s = place(start(), BuildingKind.metalMine, 1);
    final paid = s.planet.resources;
    s = place(s, BuildingKind.crystalMine, 2);
    s = place(s, BuildingKind.metalMine, 3);
    expect(s.planet.resources, paid);
    expect(s.queued(Slot.construction).map((q) => q.id), [2, 3]);
    final full = placeOrder(s, BuildingKind.solarPlant, t0, rules, eventId: 4);
    expect((full as OrderRejected).reason, isA<QueueFull>());
    expect((full.reason as QueueFull).capacity, 3);
  });

  test('prérequis comptés avec les ordres placés avant', () {
    var s = place(start(), BuildingKind.roboticsFactory, 1);
    // Chantier : Usine de robots 2 ; 1 en cours, il en faut une seconde en file.
    final early = placeOrder(s, BuildingKind.shipyard, t0, rules, eventId: 2);
    expect((early as OrderRejected).reason, isA<RequirementsNotMet>());
    s = place(s, BuildingKind.roboticsFactory, 2);
    s = place(s, BuildingKind.shipyard, 3);
    expect(projectedLevel(s, BuildingKind.roboticsFactory), 2);
  });

  test('enchaînement : l’ordre suivant démarre et se paie à la fin du précédent', () {
    var s = place(start(), BuildingKind.metalMine, 1);
    s = place(s, BuildingKind.metalMine, 2);
    final first = s.currentConstruction!;
    final before = advance(s, first.dueAt, rules);
    final next = before.state.currentConstruction!;
    expect(next.id, 2);
    expect(next.startedAt, first.dueAt);
    expect(next.targetLevel, 2);
    expect(next.cost, rules.cost(BuildingKind.metalMine, 2));
    expect(before.state.queue, isEmpty);
    // Payé au démarrage : le stock a baissé du coût du niveau 2.
    final produced = rules.produce(s.planet, s.research, first.dueAt.difference(t0));
    expect(before.state.planet.resources.metal, closeTo(produced.metal - next.cost.metal, 1e-6));
    // Puis le niveau 2 est livré.
    final after = advance(s, next.dueAt, rules).state;
    expect(after.planet.level(BuildingKind.metalMine), 2);
  });

  test('ressources manquantes au démarrage : toute la file est annulée', () {
    // De quoi payer la mine de métal 1, pas la suite.
    var s = place(start(resources: const Resources(metal: 60, crystal: 15)), BuildingKind.metalMine, 1);
    s = place(s, BuildingKind.crystalMine, 2);
    s = place(s, BuildingKind.solarPlant, 3);
    final due = s.currentConstruction!.dueAt;
    final r = advance(s, due.add(const Duration(minutes: 1)), rules);
    expect(r.cancelled, hasLength(1));
    final c = r.cancelled.single;
    expect(c.slot, Slot.construction);
    expect(c.at, due);
    expect(c.first.id, 2);
    expect(c.reason, isA<NotEnoughResources>());
    expect(c.dropped.map((q) => q.id), [2, 3]);
    expect(r.state.queue, isEmpty);
    expect(r.state.currentConstruction, isNull);
    expect(r.state.planet.level(BuildingKind.metalMine), 1);
  });

  test('labo à agrandir pendant une recherche : file de construction annulée', () {
    var s = game(
      planet(levels: {BuildingKind.researchLab: 1}, resources: rich),
    ).copyWith(officers: {OfficerKind.researchDirector: 1, OfficerKind.commander: 1});
    s = place(s, TechKind.energy, 1);
    s = place(s, TechKind.computer, 2);
    final research = s.currentResearch!;
    // Le labo arrive en file derrière une mine courte : son tour tombe pendant la recherche.
    s = place(s, BuildingKind.metalMine, 3);
    s = place(s, BuildingKind.researchLab, 4);
    final mine = s.currentConstruction!;
    expect(mine.dueAt.isBefore(research.dueAt), isTrue);
    final r = advance(s, research.dueAt, rules);
    expect(r.cancelled.first.slot, Slot.construction);
    expect(r.cancelled.first.reason, isA<LabBusy>());
    // La recherche suivante démarre normalement.
    expect(r.state.currentResearch!.id, 2);
  });

  test('annulation : en attente sans frais ; en cours remboursé, le suivant démarre', () {
    var s = place(start(), BuildingKind.metalMine, 1);
    s = place(s, BuildingKind.crystalMine, 2);
    s = place(s, BuildingKind.solarPlant, 3);
    final res = s.planet.resources;
    final dropped = cancelOrQueue(s, 3, t0, rules).state;
    expect(dropped.queue.map((q) => q.id), [2]);
    expect(dropped.planet.resources, res);

    final out = cancelOrQueue(dropped, 1, t0, rules);
    expect(out.cancelled, isNull);
    expect(out.state.currentConstruction!.id, 2);
    expect(out.state.currentConstruction!.startedAt, t0);
    expect(out.state.queue, isEmpty);
  });

  test('chantier : lots en file, limite par planète comptée avec la file', () {
    var s = game(
      planet(levels: {BuildingKind.shipyard: 1}, resources: rich),
      research: {TechKind.shielding: 2},
    ).copyWith(officers: {OfficerKind.shipyardMaster: 1});
    s = placeBatch(s, UnitKind.rocketLauncher, 3, t0, rules, eventId: 1).state;
    final dome = placeBatch(s, UnitKind.smallShieldDome, 1, t0, rules, eventId: 2);
    expect(dome, isA<OrderQueued>());
    s = dome.state;
    final second = checkQueueBatch(s, UnitKind.smallShieldDome, 1, rules);
    expect(second, anyOf(isA<QueueFull>(), isA<MaxReached>()));
    final batch = s.currentBatch!;
    final r = advance(s, batch.finishAt, rules).state;
    expect(r.currentBatch!.unit, UnitKind.smallShieldDome);
    expect(r.currentBatch!.id, 2);
  });

  test('déterministe : même rattrapage, même résultat', () {
    var s = place(start(), BuildingKind.metalMine, 1);
    s = place(s, BuildingKind.metalMine, 2);
    s = place(s, BuildingKind.metalMine, 3);
    final end = t0.add(const Duration(hours: 2));
    final a = advance(s, end, rules);
    final b = advance(s, end, rules);
    expect(a.state.planet.resources, b.state.planet.resources);
    expect(a.state.planet.level(BuildingKind.metalMine), 3);
    // Pas à pas : identique au rattrapage d'un coup.
    var step = s;
    for (var t = t0; t.isBefore(end); t = t.add(const Duration(minutes: 1))) {
      step = advance(step, t, rules).state;
    }
    step = advance(step, end, rules).state;
    expect(step.planet.level(BuildingKind.metalMine), 3);
    expect(step.planet.resources.metal, closeTo(a.state.planet.resources.metal, 1e-6));
  });
}
