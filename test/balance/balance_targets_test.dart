// Cibles d'équilibrage figées (skill starmine-balance) : un réglage futur qui les casse doit
// être une décision, pas un accident.
import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';

import 'bot.dart';

void main() {
  test('coup de pouce : début rapide, production sans chute', () {
    // Sans événements : une tempête solaire baisse l'énergie, ce n'est pas le coup de pouce.
    final data = variant(
      (m) => (m['story_events'] as Map<String, dynamic>)['catalog'] = <String, dynamic>{},
    );
    final run = Run('cible', data)..play(days: 10, verbose: false);
    expect(run.actionsByDay[0], greaterThanOrEqualTo(40));
    expect(run.worstDrop, lessThan(0.15));
  });

  test('bases pirates : dures à gagner, rentables avec la bonne flotte', () {
    final run = Run('cible', variant((_) {}))..play(days: 7, verbose: false);
    for (final b in run.s.bases) {
      final costs = [
        for (final ship in [UnitKind.lightFighter, UnitKind.cruiser]) attackCost(run, b, ship),
      ];
      final best = costs.reduce((a, c) => a.net > c.net ? a : c);
      final name = run.data.pirateBases.list[b.index].name;
      // Dure : quelle que soit la flotte, il en faut une plus chère que la base.
      for (final c in costs) {
        expect(c.fleet, greaterThan(c.defense), reason: name);
      }
      // Rentable avec la bonne flotte.
      expect(best.net, greaterThan(0), reason: name);
    }
  });
}
