import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/planet.dart';
import 'package:starmine/domain/rules.dart';

import 'helpers.dart';

void main() {
  final cfg = gameData.planet;

  test('config : trois descriptions, sept traits, valeur 10 %', () {
    expect(cfg.descriptions.keys, unorderedEquals(TemperatureBand.values));
    expect(cfg.traits.keys, unorderedEquals(TraitEffect.values));
    expect(cfg.traitValue, 0.1);
  });

  test('tirage : déterministe, atout et défaut distincts', () {
    for (var seed = 0; seed < 200; seed++) {
      final a = drawTraits(20, cfg, math.Random(seed))!;
      final b = drawTraits(20, cfg, math.Random(seed))!;
      expect(a, b);
      expect(a.boon, isNot(a.flaw));
    }
  });

  test('pondération : planète chaude, plus d’atouts d’énergie et de défauts de deutérium', () {
    int count(int tempMax, bool Function(({TraitEffect boon, TraitEffect flaw})) test) => [
      for (var seed = 0; seed < 2000; seed++)
        if (test(drawTraits(tempMax, cfg, math.Random(seed))!)) 1,
    ].length;
    bool energyBoon(({TraitEffect boon, TraitEffect flaw}) t) => t.boon == TraitEffect.energy;
    bool deutFlaw(({TraitEffect boon, TraitEffect flaw}) t) => t.flaw == TraitEffect.deuterium;
    expect(count(60, energyBoon), greaterThan(count(-20, energyBoon) * 2));
    expect(count(60, deutFlaw), greaterThan(count(-20, deutFlaw) * 2));
  });

  test('création : traits tirés ; ancienne planète : tirés une fois avec la graine', () {
    final p = Planet.create(data: gameData, random: math.Random(5), now: t0);
    expect(p.boon, isNotNull);
    expect(p.flaw, isNotNull);
    final old = planet();
    expect(old.boon, isNull);
    final a = withTraits(old, cfg, 42);
    expect(a.boon, isNotNull);
    expect(withTraits(old, cfg, 42).boon, a.boon);
    expect(identical(withTraits(a, cfg, 7), a), isTrue);
  });

  test('effets : production, énergie, durées, reconstruction', () {
    Modifiers mods(TraitEffect boon, TraitEffect flaw) =>
        game(planet().copyWith(boon: boon, flaw: flaw)).modifiers(gameData);
    final m = mods(TraitEffect.metal, TraitEffect.crystal);
    expect(m.mineByResource.metal, closeTo(0.1, 1e-9));
    expect(m.mineByResource.crystal, closeTo(-0.1, 1e-9));
    final e = mods(TraitEffect.energy, TraitEffect.build);
    expect(e.energyFactor, closeTo(1.1, 1e-9));
    expect(e.buildTime, closeTo(-0.1, 1e-9));
    final r = mods(TraitEffect.research, TraitEffect.rebuild);
    expect(r.researchTime, closeTo(0.1, 1e-9));
    expect(r.defenseRebuild, closeTo(-0.1, 1e-9));

    // Production réelle : mine de métal niveau 10, atout métal > sans trait.
    final rules = Rules(gameData);
    final base = planet(levels: {BuildingKind.metalMine: 10, BuildingKind.solarPlant: 15});
    double metal(Planet p) {
      final s = game(p);
      return rules.hourlyProduction(s.planet, s.research, s.modifiers(gameData)).metal;
    }

    expect(
      metal(base.copyWith(boon: TraitEffect.metal, flaw: TraitEffect.research)),
      greaterThan(metal(base)),
    );
  });
}
