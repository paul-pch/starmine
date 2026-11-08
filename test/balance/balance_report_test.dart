// Mesure d'équilibrage (skill starmine-balance) : le joueur automatique (bot.dart) joue 14
// jours à ×1, avec et sans coup de pouce de départ. Imprime des lignes « BALANCE| ».
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/fleet.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/raid.dart';

import '../domain/helpers.dart';
import 'bot.dart';

void main() {
  test('rapport d’équilibrage (mesure)', () {
    final boosted = Run('avec', shippedGameData)..play();
    Run('sans', gameData).play();

    final data = shippedGameData;
    // Force des raids selon les points d'économie (moyenne de 20 tirages).
    for (final pts in [0, 2, 5, 10, 20, 50, 100, 200, 500, 1000]) {
      var value = 0.0;
      var cargo = 0.0;
      for (var seed = 0; seed < 20; seed++) {
        final f = pirateFleet(pts.toDouble(), data, math.Random(seed));
        value += fleetValue(f, data) / 20;
        cargo += cargoCapacity(f, data) / 20;
      }
      out(
        'raid|eco=$pts|valeur=${r0(value)}|soute=${r0(cargo)}|lanceurs_equiv=${(value / 2000).toStringAsFixed(1)}',
      );
    }
    // Bases pirates : valeur des unités selon les points d'économie.
    for (final pts in [5, 20, 50, 100, 300, 1000]) {
      final line = [
        for (final (i, b) in data.pirateBases.list.indexed)
          '${b.name}=${r0(fleetValue(pirateBaseUnits(pts.toDouble(), b.strength, data, i), data))}',
      ].join('|');
      out('base|eco=$pts|$line');
    }
    // Bases à l'état final du joueur avec coup de pouce : stock et valeur.
    final s = boosted.s;
    final rules = boosted.rules;
    for (final b in s.bases) {
      final spec = data.pirateBases.list[b.index];
      out(
        'base_fin|${spec.name}|unites=${r0(fleetValue(baseUnits(s, b, s.planet.lastUpdate, rules), data))}'
        '|stock=${r0(total(baseStock(s, b, s.planet.lastUpdate, rules)))}',
      );
    }
    // Officiers : prérequis du niveau 1 (coût cumulé, en points).
    for (final o in data.officers.values) {
      final reqs = o.levels.first.requires;
      out(
        'officier|${o.name}|niv1=${reqs.entries.map((e) => '${e.key.key}:${e.value}').join(',')}'
        '|${o.levels.first.counters.entries.map((e) => '${e.key.key}:${e.value}').join(',')}',
      );
    }
    // Événements : effets exprimés en heures de production (×1).
    for (final e in data.story.catalog.values) {
      out(
        'evenement|${e.key}|${e.kind.name}|${e.effects.map((x) => '${x.type.name}:${x.value}:${x.hours}h').join(',')}',
      );
    }
    expect(boosted.s.planet.level(BuildingKind.metalMine), greaterThan(0));
  });
}
