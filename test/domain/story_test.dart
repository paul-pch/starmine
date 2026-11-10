import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';
import 'package:starmine/domain/story.dart';

import 'helpers.dart';

void main() {
  final rules = Rules(gameData);
  final catalog = gameData.story.catalog;
  StoryEventSpec spec(String key) => catalog[key]!;

  /// Planète où presque tout est éligible.
  GameState developed({Resources resources = const Resources(metal: 10000, crystal: 10000)}) =>
      game(
        planet(
          levels: {
            BuildingKind.metalMine: 5,
            BuildingKind.crystalMine: 5,
            BuildingKind.deuteriumSynthesizer: 2,
            BuildingKind.solarPlant: 8,
            BuildingKind.researchLab: 1,
          },
          resources: resources,
        ),
      );

  test('config : catalogue, choix avec option par défaut', () {
    expect(catalog.length, greaterThanOrEqualTo(8));
    expect(spec('merchant_convoy').kind, StoryKind.choice);
    expect(spec('merchant_convoy').options[spec('merchant_convoy').defaultOption].label, 'Refuser');
    expect(spec('rich_vein').officer, OfficerKind.geologist);
  });

  test('tirage : moitié positifs, moitié négatifs, déterministe', () {
    final s = developed();
    var positive = 0;
    for (var seed = 0; seed < 400; seed++) {
      final a = drawStory(s, gameData, math.Random(seed));
      final b = drawStory(s, gameData, math.Random(seed));
      expect(a?.key, b?.key);
      if (a!.kind != StoryKind.malus) positive++;
    }
    expect(positive, inInclusiveRange(160, 240));
  });

  test('jamais deux malus actifs à la fois', () {
    final s = developed().copyWith(
      effects: [
        ActiveEffect(
          source: 'gallery_collapse',
          type: StoryEffectType.production,
          resource: ResourceKind.crystal,
          value: -0.5,
          endsAt: t0.add(const Duration(hours: 8)),
        ),
      ],
    );
    for (var seed = 0; seed < 100; seed++) {
      expect(drawStory(s, gameData, math.Random(seed))!.kind, isNot(StoryKind.malus));
    }
  });

  test('éligibilité : prérequis et ordre en cours pour un raccourci', () {
    final bare = game(planet());
    expect(storyEligible(bare, spec('rich_vein')), isFalse);
    expect(storyEligible(bare, spec('sabotage')), isFalse);
    expect(storyEligible(bare, spec('drifting_wreck')), isTrue);
    final building = startOrder(bare, BuildingKind.metalMine, t0, rules, eventId: 1).state;
    expect(storyEligible(building, spec('sabotage')), isTrue);
  });

  test('effet temporaire : production augmentée puis retirée à sa fin, exact', () {
    final s = developed(resources: Resources.zero);
    final boosted = applyStoryEffects(s, spec('rich_vein'), spec('rich_vein').effects, t0, rules);
    final effect = boosted.effects.single;
    expect(effect.endsAt, t0.add(const Duration(hours: 12)));
    expect(boosted.modifiers(gameData).mineByResource.metal, closeTo(0.3, 1e-12));

    final end = t0.add(const Duration(hours: 20));
    final r = advance(boosted, end, rules).state;
    expect(r.effects, isEmpty);
    // 12 h boostées puis 8 h normales.
    final during = rules.hourlyProduction(s.planet, s.research, boosted.modifiers(gameData));
    final after = rules.hourlyProduction(s.planet, s.research);
    expect(r.planet.resources.metal, closeTo(during.metal * 12 + after.metal * 8, 1e-6));
  });

  test('cumul : le même événement deux fois, effets additionnés', () {
    final s = developed();
    final once = applyStoryEffects(s, spec('rich_vein'), spec('rich_vein').effects, t0, rules);
    final later = t0.add(const Duration(hours: 5));
    final twice = applyStoryEffects(
      once,
      spec('rich_vein'),
      spec('rich_vein').effects,
      later,
      rules,
    );
    expect(twice.effects, hasLength(2));
    expect(twice.modifiers(gameData).mineByResource.metal, closeTo(0.6, 1e-12));
  });

  test('officier lié : bonus prolongé, malus atténué', () {
    final s = developed().copyWith(officers: {OfficerKind.geologist: 2, OfficerKind.engineer: 3});
    final vein = applyStoryEffects(s, spec('rich_vein'), spec('rich_vein').effects, t0, rules);
    // Géologue 2 × 10 % : 12 h → 14,4 h.
    expect(vein.effects.single.endsAt, t0.add(const Duration(minutes: 864)));
    final storm = applyStoryEffects(s, spec('solar_storm'), spec('solar_storm').effects, t0, rules);
    // Ingénieur 3 × 10 % : −25 % → −17,5 %.
    expect(storm.effects.single.value, closeTo(-0.175, 1e-12));
  });

  test('raccourci et retard de l’ordre en cours', () {
    final s = startOrder(developed(), BuildingKind.metalMine, t0, rules, eventId: 1).state;
    final due = s.currentConstruction!.dueAt;
    final left = due.difference(t0).inMilliseconds;
    final slowed = applyStoryEffects(s, spec('sabotage'), spec('sabotage').effects, t0, rules);
    expect(
      slowed.currentConstruction!.dueAt.difference(t0).inMilliseconds,
      closeTo(left * 1.25, 1),
    );
  });

  test('stock et gain immédiats', () {
    final s = developed(resources: const Resources(metal: 5000, crystal: 5000));
    final leak = applyStoryEffects(
      s,
      spec('storage_leak'),
      spec('storage_leak').effects,
      t0,
      rules,
    );
    expect(leak.planet.resources.metal, 4500);
    expect(leak.planet.resources.crystal, 5000);
    final wreck = applyStoryEffects(
      s,
      spec('drifting_wreck'),
      spec('drifting_wreck').effects,
      t0,
      rules,
    );
    final rate = rules.hourlyProduction(s.planet, s.research);
    expect(wreck.planet.resources.metal, closeTo(5000 + rate.metal * 4, 1));
  });

  /// Chaîne avec [stock] événements servables à [t0].
  GameState withStock(GameState s, {int stock = 1, int seed = 7}) => s.copyWith(
    pending: [
      ...s.pending,
      StoryEvent.chain(
        id: 5,
        planetId: 1,
        seed: seed,
        accrueAt: t0.add(const Duration(hours: 4)),
        stock: stock,
      ),
    ],
  );

  /// Graine dont le tirage sur [s] est un choix.
  int choiceSeed(GameState s) {
    var seed = 0;
    while (drawStory(s, gameData, math.Random(seed))?.kind != StoryKind.choice) {
      seed++;
    }
    return seed;
  }

  test('choix servi : en attente, puis option par défaut à l’échéance, même app fermée', () {
    final base = developed();
    final seed = choiceSeed(base);
    final drawn = drawStory(base, gameData, math.Random(seed))!;
    final served = serveStory(withStock(base, seed: seed), t0, rules)!;
    expect(served.outcome!.kind, StoryOutcomeKind.awaiting);
    final waiting = pendingStory(served.state)!;
    expect(waiting.id, 5);
    expect(waiting.stock, 0);
    expect(waiting.choiceKey, drawn.key);
    expect(waiting.deadline, t0.add(const Duration(hours: 6)));
    expect(pendingChoice(served.state, gameData)!.key, drawn.key);

    final r = advance(served.state, t0.add(const Duration(hours: 6)), rules);
    final defaulted = r.stories.where((o) => o.kind == StoryOutcomeKind.defaulted).single;
    expect(defaulted.option, drawn.defaultOption);
    final next = pendingStory(r.state)!;
    expect(next.choiceKey, isNull);
    expect(next.serveAt!.isAfter(t0.add(const Duration(hours: 6))), isTrue);
  });

  test('réponse du joueur : option appliquée, service suivant après le délai', () {
    final s = developed(resources: const Resources(metal: 6000, crystal: 5000)).copyWith(
      pending: [
        StoryEvent.chain(
          id: 5,
          planetId: 1,
          seed: 1,
          accrueAt: t0.add(const Duration(hours: 3)),
          choiceKey: 'merchant_convoy',
          deadline: t0.add(const Duration(hours: 6)),
          stock: 1,
        ),
      ],
    );
    expect(canServe(s, t0), isFalse);
    final out = answerChoice(s, 0, t0, rules)!;
    expect(out.outcome.kind, StoryOutcomeKind.answered);
    expect(out.state.planet.resources.metal, 5100);
    expect(out.state.planet.resources.crystal, greaterThan(5000));
    final next = pendingStory(out.state)!;
    expect(next.choiceKey, isNull);
    expect(next.stock, 1);
    expect(next.serveAt!.difference(t0).inMinutes, inInclusiveRange(20, 40));
    expect(canServe(out.state, t0), isFalse);
    expect(canServe(out.state, next.serveAt!), isTrue);
    expect(answerChoice(out.state, 0, t0, rules), isNull);
  });

  test('raid avancé par un choix', () {
    final raid = RaidDetected(
      id: 9,
      planetId: 1,
      dueAt: t0.add(const Duration(hours: 30)),
      arrivalAt: t0.add(const Duration(hours: 31)),
      seed: 1,
    );
    final s = developed().copyWith(pending: [raid]);
    final escort = spec('escort_request');
    final r = applyStoryEffects(s, escort, escort.options[0].effects, t0, rules);
    final moved = r.pending.whereType<RaidDetected>().single;
    expect(moved.dueAt, t0.add(const Duration(hours: 18)));
    expect(moved.arrivalAt, t0.add(const Duration(hours: 19)));
  });

  test('hors ligne : 3 semaines, stock plafonné, aucun effet subi', () {
    final start = ensureStoryScheduled(developed(), t0, rules, seed: 7, eventId: 1);
    final end = t0.add(const Duration(days: 21));
    final a = advance(start, end, rules);
    final b = advance(start, end, rules);
    expect(a.stories, isEmpty);
    expect(a.state.effects, isEmpty);
    expect(pendingStory(a.state)!.id, 1);
    expect(pendingStory(a.state)!.stock, gameData.story.maxStock);
    expect(pendingStory(a.state)!.accrueAt, pendingStory(b.state)!.accrueAt);
    // Sans événement, la production est celle d'une planète sans chaîne.
    expect(a.state.planet.resources, advance(developed(), end, rules).state.planet.resources);
  });

  test('service : un à la fois, délai entre deux, déterministe', () {
    final s = withStock(developed(), stock: 3);
    final first = serveStory(s, t0, rules)!;
    expect(first.outcome, isNotNull);
    final again = serveStory(s, t0, rules)!;
    expect(again.outcome!.key, first.outcome!.key);
    final e = pendingStory(first.state)!;
    expect(e.stock, 2);
    if (e.choiceKey == null) {
      expect(serveStory(first.state, t0, rules), isNull);
      final later = advance(first.state, e.serveAt!, rules).state;
      expect(serveStory(later, e.serveAt!, rules), isNotNull);
    } else {
      // Un choix bloque le service suivant.
      expect(canServe(first.state, t0.add(const Duration(hours: 1))), isFalse);
    }
    expect(serveStory(withStock(developed(), stock: 0), t0, rules), isNull);
  });

  test('unités, débris, versement différé', () {
    final s = developed();
    const deserters = StoryEventSpec(key: 'x', name: 'x', kind: StoryKind.bonus);
    final more = applyStoryEffects(
      s,
      deserters,
      const [StoryEffectSpec(type: StoryEffectType.units, unit: UnitKind.lightFighter, value: 3)],
      t0,
      rules,
    );
    expect(more.planet.count(UnitKind.lightFighter), 3);
    final fewer = applyStoryEffects(
      more,
      deserters,
      const [StoryEffectSpec(type: StoryEffectType.units, unit: UnitKind.lightFighter, value: -5)],
      t0,
      rules,
    );
    expect(fewer.planet.count(UnitKind.lightFighter), 0);

    final rate = rules.hourlyProduction(s.planet, s.research);
    final battle = applyStoryEffects(
      s,
      spec('orbital_battle'),
      spec('orbital_battle').effects,
      t0,
      rules,
    );
    expect(battle.planet.debris.metal, closeTo(rate.metal * 6, 1));
    expect(battle.planet.debris.crystal, closeTo(rate.crystal * 6, 1));

    final contract = spec('advance_contract');
    final invested = applyStoryEffects(s, contract, contract.options[0].effects, t0, rules);
    final owed = invested.effects.where((e) => e.type == StoryEffectType.delayed).toList();
    expect(owed, hasLength(2));
    expect(owed.first.endsAt, t0.add(const Duration(hours: 24)));
    final before = advance(invested, t0.add(const Duration(hours: 23)), rules).state;
    final after = advance(invested, t0.add(const Duration(hours: 25)), rules).state;
    final plain = advance(
      invested.copyWith(effects: const []),
      t0.add(const Duration(hours: 25)),
      rules,
    ).state;
    expect(before.effects, hasLength(2));
    expect(after.effects, isEmpty);
    expect(
      after.planet.resources.metal,
      closeTo(plain.planet.resources.metal + owed.first.value, 1),
    );
  });

  test('pari : déterministe, les deux issues', () {
    final s = developed(resources: const Resources(metal: 5000, crystal: 5000));
    final wreck = spec('unstable_wreck');
    var wins = 0;
    var losses = 0;
    for (var seed = 0; seed < 200; seed++) {
      final a = resolveGambles(wreck.options[0].effects, math.Random(seed));
      final b = resolveGambles(wreck.options[0].effects, math.Random(seed));
      expect(a.won, b.won);
      final r = applyStoryEffects(s, wreck, a.effects, t0, rules);
      if (a.won!) {
        wins++;
        expect(r.planet.resources.metal, greaterThan(5000));
      } else {
        losses++;
        expect(r.planet.resources.crystal, 4500);
      }
    }
    expect(wins, inInclusiveRange(95, 145));
    expect(losses, greaterThan(0));
  });

  test('debug : un événement servi tout de suite', () {
    final s = ensureStoryScheduled(developed(), t0, rules, seed: 7, eventId: 1);
    expect(canServe(s, t0), isFalse);
    final now = storyNow(s, t0, rules);
    expect(pendingStory(now)!.stock, 1);
    expect(serveStory(now, t0, rules)?.outcome, isNotNull);
  });
}
