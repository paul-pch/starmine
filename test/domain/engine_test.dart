import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/planet.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);

  BuildingDone build(BuildingKind kind, int target, {required int id, required DateTime due}) =>
      BuildingDone(
        id: id,
        planetId: 1,
        startedAt: t0,
        dueAt: due,
        building: kind,
        targetLevel: target,
        cost: Resources.zero,
      );

  ResearchDone research(TechKind kind, int target, {required int id, required DateTime due}) =>
      ResearchDone(
        id: id,
        planetId: 1,
        startedAt: t0,
        dueAt: due,
        tech: kind,
        targetLevel: target,
        cost: Resources.zero,
      );

  /// Référence naïve : pas d'une seconde, événements appliqués à leur seconde.
  GameState secondBySecond(GameState start, DateTime end) {
    var s = start;
    final queue = [...start.pending];
    var t = start.planet.lastUpdate;
    while (t.isBefore(end)) {
      final next = t.add(const Duration(seconds: 1));
      final p = s.planet;
      s = s.copyWith(
        planet: p.copyWith(
          resources: rules.produce(p, s.research, const Duration(seconds: 1)),
          lastUpdate: next,
        ),
      );
      while (queue.isNotEmpty && !queue.first.dueAt.isAfter(next)) {
        switch (queue.removeAt(0)) {
          case BuildingDone(:final building, :final targetLevel):
            s = s.copyWith(planet: s.planet.withLevel(building, targetLevel));
          case ResearchDone(:final tech, :final targetLevel):
            s = s.copyWith(research: {...s.research, tech: targetLevel});
          case ShipyardBatch() || RaidDetected() || RaidArrival():
            throw StateError('ni lot ni raid dans ce test');
        }
      }
      t = next;
    }
    return s.copyWith(pending: const []);
  }

  void expectSameResources(Resources actual, Resources expected) {
    for (final k in ResourceKind.values) {
      expect(actual[k], closeTo(expected[k], 1e-6 * math.max(1, expected[k])), reason: k.name);
    }
  }

  test('rattrapage de 12 h, construction et recherche = simulation seconde par seconde', () {
    // Fusion alimentée par le synthétiseur ; la techno Énergie 4 augmente son rendement,
    // la mine de métal 4 aggrave le manque d'énergie.
    final start = game(
      planet(
        levels: {
          BuildingKind.metalMine: 3,
          BuildingKind.crystalMine: 2,
          BuildingKind.deuteriumSynthesizer: 5,
          BuildingKind.solarPlant: 3,
          BuildingKind.fusionReactor: 2,
          BuildingKind.researchLab: 1,
        },
        resources: const Resources(metal: 1000, crystal: 800, deuterium: 50),
      ),
      research: {TechKind.energy: 3},
      pending: [
        build(BuildingKind.metalMine, 4, id: 1, due: t0.add(const Duration(hours: 2, seconds: 17))),
        research(TechKind.energy, 4, id: 2, due: t0.add(const Duration(hours: 7, minutes: 3))),
      ],
    );
    final end = t0.add(const Duration(hours: 12));

    final result = advance(start, end, rules);
    final reference = secondBySecond(start, end);

    expect(result.applied.map((e) => e.id), [1, 2]);
    expect(result.state.pending, isEmpty);
    expect(result.state.planet.levels, reference.planet.levels);
    expect(result.state.research, reference.research);
    expect(result.state.research[TechKind.energy], 4);
    expect(result.state.planet.lastUpdate, end);
    expectSameResources(result.state.planet.resources, reference.planet.resources);
  });

  test('les événements futurs restent en attente', () {
    final e = build(BuildingKind.metalMine, 1, id: 1, due: t0.add(const Duration(hours: 5)));
    final result = advance(game(planet(), pending: [e]), t0.add(const Duration(hours: 1)), rules);
    expect(result.applied, isEmpty);
    expect(result.state.pending, [e]);
    expect(result.state.planet.level(BuildingKind.metalMine), 0);
  });

  test('le stockage plafonne pendant le rattrapage', () {
    final start = game(planet(resources: const Resources(metal: 9990, crystal: 0)));
    final after = advance(start, t0.add(const Duration(days: 30)), rules).state.planet;
    expect(after.resources.metal, 10000);
    expect(after.resources.crystal, 10000);
  });

  test('un stock au-dessus de la capacité est conservé, sans production', () {
    final start = game(planet(resources: const Resources(metal: 12000)));
    final after = advance(start, t0.add(const Duration(hours: 3)), rules).state.planet;
    expect(after.resources.metal, 12000);
  });

  test('deutérium net négatif : le stock s’arrête à 0', () {
    final start = game(
      planet(levels: {BuildingKind.fusionReactor: 3}, resources: const Resources(deuterium: 100)),
    );
    final after = advance(start, t0.add(const Duration(days: 2)), rules).state.planet;
    expect(after.resources.deuterium, 0);
  });

  test('horloge reculée : aucun effet', () {
    final state = game(planet());
    final result = advance(state, t0.subtract(const Duration(hours: 1)), rules);
    expect(result.state, same(state));
  });

  group('construction', () {
    test('lancement : débit immédiat, événement à la bonne échéance', () {
      final outcome = startOrder(game(planet()), BuildingKind.metalMine, t0, rules, eventId: 7);
      final started = outcome as OrderStarted;
      expect(started.event, isA<BuildingDone>());
      expect(started.event.id, 7);
      expect(started.event.targetLevel, 1);
      expect(started.event.dueAt, t0.add(const Duration(seconds: 108)));
      expect(started.state.planet.resources, const Resources(metal: 440, crystal: 485));
      expect(started.state.currentConstruction, started.event);
    });

    test('file à 1 slot', () {
      final first = startOrder(game(planet()), BuildingKind.metalMine, t0, rules, eventId: 1);
      final second = startOrder(first.state, BuildingKind.crystalMine, t0, rules, eventId: 2);
      expect((second as OrderRejected).reason, isA<QueueBusy>());
    });

    test('ressources insuffisantes : indique le manque', () {
      final outcome = startOrder(
        game(planet()),
        BuildingKind.roboticsFactory,
        t0,
        rules,
        eventId: 1,
      );
      final reason = (outcome as OrderRejected).reason as NotEnoughResources;
      expect(reason.missing, const Resources(deuterium: 200));
    });

    test('annulation : remboursement intégral, même au-delà de la capacité', () {
      final full = planet(resources: const Resources(metal: 10000, crystal: 10000));
      final outcome = startOrder(game(full), BuildingKind.metalStorage, t0, rules, eventId: 1);
      final started = outcome as OrderStarted;
      final later = t0.add(const Duration(minutes: 10));
      final cancelled = cancelOrder(started.state, 1, later, rules);

      expect(cancelled.pending, isEmpty);
      // 9000 + production pendant 10 min (sous la capacité) + 1000 remboursés.
      final produced = rules.hourlyProduction(full, const {}).metal / 6;
      expect(cancelled.planet.resources.metal, closeTo(10000 + produced, 1e-9));
      expect(cancelled.planet.level(BuildingKind.metalStorage), 0);
    });

    test('nanites : construction plus rapide', () {
      final p = planet(
        levels: {BuildingKind.naniteFactory: 1},
        resources: const Resources(metal: 500, crystal: 500),
      );
      final outcome = startOrder(game(p), BuildingKind.metalMine, t0, rules, eventId: 1);
      expect((outcome as OrderStarted).event.dueAt, t0.add(const Duration(seconds: 54)));
    });
  });

  group('prérequis', () {
    const rich = Resources(metal: 1e6, crystal: 1e6, deuterium: 1e6);

    test('fusion : synthétiseur 5 et Énergie 3 requis', () {
      final s = game(planet(levels: {BuildingKind.deuteriumSynthesizer: 4}, resources: rich));
      final reason = checkOrder(s, BuildingKind.fusionReactor, rules) as RequirementsNotMet;
      expect(reason.missing, {BuildingKind.deuteriumSynthesizer: 5, TechKind.energy: 3});

      final ok = game(
        planet(levels: {BuildingKind.deuteriumSynthesizer: 5}, resources: rich),
        research: {TechKind.energy: 3},
      );
      expect(checkOrder(ok, BuildingKind.fusionReactor, rules), isNull);
    });

    test('technologie : labo requis', () {
      final s = game(planet(resources: rich));
      final reason = checkOrder(s, TechKind.energy, rules) as RequirementsNotMet;
      expect(reason.missing, {BuildingKind.researchLab: 1});
    });

    test('prérequis vérifiés avant les ressources', () {
      final s = game(planet());
      expect(checkOrder(s, TechKind.plasma, rules), isA<RequirementsNotMet>());
    });
  });

  group('recherche', () {
    const rich = Resources(metal: 1e6, crystal: 1e6, deuterium: 1e6);
    GameState withLab() => game(planet(levels: {BuildingKind.researchLab: 1}, resources: rich));

    test('lancement : durée selon le labo, file séparée de la construction', () {
      final r = startOrder(withLab(), TechKind.energy, t0, rules, eventId: 1) as OrderStarted;
      expect(r.event, isA<ResearchDone>());
      expect(r.event.dueAt, t0.add(const Duration(seconds: 1440)));
      expect(r.state.currentResearch, r.event);

      // Une construction peut tourner en même temps.
      final b = startOrder(r.state, BuildingKind.metalMine, t0, rules, eventId: 2);
      expect(b, isA<OrderStarted>());
      // Mais pas une seconde recherche.
      final r2 = startOrder(b.state, TechKind.computer, t0, rules, eventId: 3);
      expect((r2 as OrderRejected).reason, isA<QueueBusy>());
    });

    test('labo bloqué pendant une recherche', () {
      final r = startOrder(withLab(), TechKind.energy, t0, rules, eventId: 1);
      expect(checkOrder(r.state, BuildingKind.researchLab, rules), isA<LabBusy>());
    });

    test('recherche bloquée pendant l’agrandissement du labo', () {
      final b = startOrder(withLab(), BuildingKind.researchLab, t0, rules, eventId: 1);
      expect(checkOrder(b.state, TechKind.energy, rules), isA<LabBusy>());
    });

    test('annulation d’une recherche : remboursement intégral', () {
      final start = withLab();
      final r = startOrder(start, TechKind.energy, t0, rules, eventId: 1) as OrderStarted;
      final cancelled = cancelOrder(r.state, 1, t0, rules);
      expect(cancelled.currentResearch, isNull);
      expect(cancelled.planet.resources, start.planet.resources);
    });

    test('fin de recherche : niveau de techno appliqué', () {
      final r = startOrder(withLab(), TechKind.energy, t0, rules, eventId: 1) as OrderStarted;
      final after = advance(r.state, t0.add(const Duration(hours: 1)), rules).state;
      expect(after.research[TechKind.energy], 1);
      expect(after.currentResearch, isNull);
    });
  });

  group('réglage de production', () {
    test('le passé est soldé à l’ancien réglage', () {
      final start = game(planet(levels: {BuildingKind.metalMine: 1, BuildingKind.solarPlant: 5}));
      final oneHour = t0.add(const Duration(hours: 1));
      final adjusted = setProductionPercent(start, BuildingKind.metalMine, 0, oneHour, rules);
      expect(adjusted.planet.percent(BuildingKind.metalMine), 0);
      expect(adjusted.planet.resources.metal, closeTo(500 + 30 + 30 * 1.1, 1e-9));

      final later = advance(adjusted, oneHour.add(const Duration(hours: 1)), rules).state;
      expect(later.planet.resources.metal, closeTo(500 + 30 + 30 * 1.1 + 30, 1e-9));
    });

    test('refusé pour un bâtiment non réglable ou une valeur invalide', () {
      final s = game(planet());
      expect(
        () => setProductionPercent(s, BuildingKind.metalStorage, 50, t0, rules),
        throwsArgumentError,
      );
      expect(
        () => setProductionPercent(s, BuildingKind.metalMine, 55, t0, rules),
        throwsArgumentError,
      );
    });
  });

  group('chantier', () {
    const rich = Resources(metal: 1e6, crystal: 1e6, deuterium: 1e6);
    GameState withYard({int level = 1, TechLevels research = const {}}) => game(
      planet(
        levels: {BuildingKind.shipyard: level, BuildingKind.roboticsFactory: 2},
        resources: rich,
      ),
      research: research,
    );

    test('lot payé d’avance, livré unité par unité', () {
      final out = startBatch(withYard(), UnitKind.rocketLauncher, 5, t0, rules, eventId: 1);
      final batch = (out as BatchStarted).batch;
      // 2000 / (2500 × 2) h = 1440 s par unité
      expect(batch.unitDuration, const Duration(seconds: 1440));
      expect(batch.finishAt, t0.add(const Duration(seconds: 1440 * 5)));
      expect(out.state.planet.resources.metal, 1e6 - 10000);

      final mid = advance(out.state, t0.add(const Duration(seconds: 1440 * 2 + 5)), rules);
      expect(mid.state.planet.count(UnitKind.rocketLauncher), 2);
      expect(mid.state.currentBatch!.remaining, 3);
      expect(mid.state.currentBatch!.id, 1);

      final end = advance(mid.state, t0.add(const Duration(days: 1)), rules);
      expect(end.state.planet.count(UnitKind.rocketLauncher), 5);
      expect(end.state.currentBatch, isNull);
      expect(end.applied, hasLength(3));
    });

    test('un lot à la fois, chantier bloqué pendant un lot et inversement', () {
      final out = startBatch(withYard(), UnitKind.rocketLauncher, 2, t0, rules, eventId: 1);
      expect(checkBatch(out.state, UnitKind.rocketLauncher, 1, rules), isA<QueueBusy>());
      expect(checkOrder(out.state, BuildingKind.shipyard, rules), isA<ShipyardBusy>());

      final up = startOrder(withYard(), BuildingKind.shipyard, t0, rules, eventId: 1);
      expect(checkBatch(up.state, UnitKind.rocketLauncher, 1, rules), isA<ShipyardBusy>());
    });

    test('prérequis, limite des dômes, vaisseaux non constructibles', () {
      expect(checkBatch(withYard(), UnitKind.lightLaser, 1, rules), isA<RequirementsNotMet>());
      final s = withYard(research: {TechKind.shielding: 2});
      expect(checkBatch(s, UnitKind.smallShieldDome, 2, rules), isA<MaxReached>());
      expect(checkBatch(s, UnitKind.smallShieldDome, 1, rules), isNull);
      expect(checkBatch(s, UnitKind.cruiser, 1, rules), isA<NotBuildable>());
    });

    test('quantité maximale commandable', () {
      final s = game(
        planet(
          levels: {BuildingKind.shipyard: 1},
          resources: const Resources(metal: 9999, crystal: 500),
        ),
      );
      expect(maxOrderable(s, UnitKind.rocketLauncher, rules), 4);
      expect(maxOrderable(s, UnitKind.lightLaser, rules), 1);
    });
  });

  test('état des files : libre, occupée, bloquée par un agrandissement, indisponible', () {
    const rich = Resources(metal: 1e6, crystal: 1e6, deuterium: 1e6);
    final s = game(
      planet(
        levels: {
          BuildingKind.researchLab: 1,
          BuildingKind.shipyard: 1,
          BuildingKind.roboticsFactory: 2,
        },
        resources: rich,
      ),
    );
    expect(slotStatus(s, Slot.research), SlotStatus.free);
    expect(slotStatus(game(planet()), Slot.shipyard), SlotStatus.unavailable);

    final yardUp = startOrder(s, BuildingKind.shipyard, t0, rules, eventId: 1).state;
    expect(slotStatus(yardUp, Slot.construction), SlotStatus.busy);
    expect(slotStatus(yardUp, Slot.shipyard), SlotStatus.blocked);
    expect(slotStatus(yardUp, Slot.research), SlotStatus.free);

    final labUp = startOrder(s, BuildingKind.researchLab, t0, rules, eventId: 1).state;
    expect(slotStatus(labUp, Slot.research), SlotStatus.blocked);
  });

  test('nouvelle planète : ressources de départ, niveaux à 0, Tmax dans la plage', () {
    final p = Planet.create(data: gameData, random: math.Random(42), now: t0);
    expect(p.resources, const Resources(metal: 500, crystal: 500));
    expect(p.levels.values, everyElement(0));
    expect(p.percents.values, everyElement(100));
    expect(p.tempMax, inInclusiveRange(-40, 80));
  });
}
