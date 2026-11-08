// Mesure d'équilibrage : variantes du coup de pouce et rentabilité des bases pirates.
// Imprime des lignes « BALANCE| » ; aucune donnée de jeu n'est modifiée.

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';

import 'bot.dart';

void main() {
  test('variantes du coup de pouce', () {
    // Sans événements (une tempête solaire fausse la mesure de baisse) ; x1 = référence.
    for (final (extra, fade) in [(0, 100), (3, 100), (3, 300), (2, 300), (2, 500), (3, 1000)]) {
      final run = Run(
        'boost x${extra + 1}/$fade',
        variant((m) {
          m['start_boost'] = {'extra': extra, 'fade_points': fade};
          (m['story_events'] as Map<String, dynamic>)['catalog'] = <String, dynamic>{};
        }),
      )..play(verbose: false);
      final p = run.production;
      out(
        'boost|x${extra + 1}|fade=$fade|baisse_max_6h=${(run.worstDrop * 100).round()}%'
        '|prod_12h=${r0(p[12])}|prod_24h=${r0(p[24])}|prod_48h=${r0(p[48])}'
        '|prod_72h=${r0(p[72])}|prod_7j=${r0(p[168])}|prod_14j=${r0(p[336])}'
        '|actions_j1=${run.actionsByDay[0]}|actions_j2=${run.actionsByDay[1]}'
        '|actions_j3=${run.actionsByDay[2]}|actions_j4_7=${[3, 4, 5, 6].map((d) => run.actionsByDay[d] ?? 0).join('/')}',
      );
    }
  });

  test('rentabilité des bases pirates', () {
    // Pour chaque base, aux jours 3, 7 et 14 du joueur automatique : la plus petite flotte
    // (chasseurs légers, puis croiseurs) qui gagne 9 combats sur 10, ses pertes, le butin
    // et les débris ; gain net exprimé en heures de production du joueur.
    for (final days in [3, 7, 14]) {
      final run = Run('bases', variant((_) {}))..play(days: days, verbose: false);
      for (final b in run.s.bases) {
        for (final ship in [UnitKind.lightFighter, UnitKind.cruiser]) {
          final r = attackCost(run, b, ship);
          final name = run.data.pirateBases.list[b.index].name;
          out(
            'base|j$days|$name|${run.data.unit(ship).name}|prod_h=${r0(r.perHour)}'
            '|defense=${r0(r.defense)}|flotte=${r0(r.fleet)} (${r.count})|pertes=${r0(r.losses)}'
            '|butin=${r0(r.loot)}|debris=${r0(r.debris)}|net=${r0(r.net)}'
            '|net_h=${(r.net / r.perHour).toStringAsFixed(1)}',
          );
        }
      }
    }
  });
}
