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

  test('le même événement ne se cumule pas : le nouveau remplace l’ancien', () {
    final s = developed();
    final once = applyStoryEffects(s, spec('rich_vein'), spec('rich_vein').effects, t0, rules);
    final later = t0.add(const Duration(hours: 5));
    final twice = applyStoryEffects(once, spec('rich_vein'), spec('rich_vein').effects, later, rules);
    expect(twice.effects, hasLength(1));
    expect(twice.effects.single.endsAt, later.add(const Duration(hours: 12)));
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
    final leak = applyStoryEffects(s, spec('storage_leak'), spec('storage_leak').effects, t0, rules);
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

  test('choix : en attente, puis option par défaut à l’échéance', () {
    // Seed qui tire un choix sur cette planète.
    final s = developed();
    var seed = 0;
    while (drawStory(s, gameData, math.Random(seed))?.kind != StoryKind.choice) {
      seed++;
    }
    final drawn = drawStory(s, gameData, math.Random(seed))!;
    final e = StoryEvent(id: 5, planetId: 1, dueAt: t0, seed: seed);
    final step = applyStory(s, e, rules);
    expect(step.outcome!.kind, StoryOutcomeKind.awaiting);
    final waiting = step.next as StoryEvent;
    expect(waiting.id, 5);
    expect(waiting.choiceKey, drawn.key);
    expect(waiting.dueAt, t0.add(const Duration(hours: 6)));

    final state = s.copyWith(pending: [waiting]);
    expect(pendingChoice(state, gameData)!.key, drawn.key);
    final r = advance(state, waiting.dueAt, rules);
    expect(r.stories.single.kind, StoryOutcomeKind.defaulted);
    expect(r.stories.single.option, drawn.defaultOption);
    final next = pendingStory(r.state)!;
    expect(next.choiceKey, isNull);
    expect(next.dueAt.difference(waiting.dueAt).inHours, inInclusiveRange(60, 108));
  });

  test('réponse du joueur : option appliquée, événement suivant planifié', () {
    final s = developed(resources: const Resources(metal: 6000, crystal: 5000)).copyWith(
      pending: [
        StoryEvent(
          id: 5,
          planetId: 1,
          dueAt: t0.add(const Duration(hours: 6)),
          seed: 1,
          choiceKey: 'merchant_convoy',
        ),
      ],
    );
    final out = answerChoice(s, 0, t0, rules)!;
    expect(out.outcome.kind, StoryOutcomeKind.answered);
    expect(out.state.planet.resources.metal, 5100);
    expect(out.state.planet.resources.crystal, greaterThan(5000));
    expect(pendingStory(out.state)!.choiceKey, isNull);
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

  test('chaîne : rattrapage de 3 semaines, plusieurs événements, déterministe', () {
    final start = ensureStoryScheduled(developed(), t0, rules, seed: 7, eventId: 1);
    final end = t0.add(const Duration(days: 21));
    final a = advance(start, end, rules);
    final b = advance(start, end, rules);
    expect(a.stories.length, inInclusiveRange(4, 20));
    expect(a.stories.map((o) => o.key), b.stories.map((o) => o.key));
    expect(a.state.planet.resources, b.state.planet.resources);
    expect(pendingStory(a.state)!.id, 1);
  });

  test('debug : l’événement survient tout de suite', () {
    final s = ensureStoryScheduled(developed(), t0, rules, seed: 7, eventId: 1);
    final now = storyNow(s, t0);
    expect(pendingStory(now)!.dueAt, t0);
    expect(advance(now, t0.add(const Duration(seconds: 1)), rules).stories, isNotEmpty);
  });
}
