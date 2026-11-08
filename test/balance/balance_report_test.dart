// Mesure d'équilibrage (skill starmine-balance) : un joueur automatique simple joue 14 jours
// à ×1, avec et sans coup de pouce de départ. Imprime des lignes « BALANCE| » lues dans la
// sortie de la CI ; aucune assertion d'équilibre pour l'instant.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/combat.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/fleet.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/officers.dart';
import 'package:starmine/domain/raid.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

import '../domain/helpers.dart';

void out(String s) => print('BALANCE|$s');

String r0(double v) => v.round().toString();

double total(Resources r) => r.metal + r.crystal + r.deuterium;

class Run {
  Run(this.label, this.data) : rules = Rules(data);

  final String label;
  final GameData data;
  final Rules rules;
  late GameState s;
  var id = 100;
  final milestones = <String, double>{};
  var raids = 0;
  var repelled = 0;
  var looted = 0.0;
  final stories = <String, int>{};
  var actions = 0;
  final actionsByDay = <int, int>{};

  double hoursAt(DateTime t) => t.difference(t0).inMinutes / 60;

  void mark(String key, DateTime t) => milestones.putIfAbsent(key, () => hoursAt(t));

  Modifiers get mods => s.modifiers(data);

  void act(DateTime t, int day) {
    actions++;
    actionsByDay[day] = (actionsByDay[day] ?? 0) + 1;
  }

  /// Bâtiment le moins cher parmi ceux qui ont du sens à ce stade.
  BuildingKind? nextBuilding() {
    final p = s.planet;
    int lv(BuildingKind k) => p.level(k);
    final energy = rules.energy(p, s.research, mods);
    final cands = <BuildingKind>[
      if (energy.net < 0) BuildingKind.solarPlant,
      if (energy.net >= 0) ...[
        BuildingKind.metalMine,
        if (lv(BuildingKind.crystalMine) < lv(BuildingKind.metalMine)) BuildingKind.crystalMine,
        if (lv(BuildingKind.crystalMine) >= 3 &&
            lv(BuildingKind.deuteriumSynthesizer) < lv(BuildingKind.crystalMine) - 1)
          BuildingKind.deuteriumSynthesizer,
        if (lv(BuildingKind.roboticsFactory) < math.min(10, lv(BuildingKind.metalMine) ~/ 3))
          BuildingKind.roboticsFactory,
        if (lv(BuildingKind.roboticsFactory) >= 2 &&
            lv(BuildingKind.shipyard) < math.max(1, lv(BuildingKind.metalMine) ~/ 3))
          BuildingKind.shipyard,
        if (lv(BuildingKind.researchLab) < math.max(1, lv(BuildingKind.metalMine) ~/ 3))
          BuildingKind.researchLab,
      ],
    ];
    // Hangars : quand le prochain coût dépasse 80 % de la capacité.
    final cap = rules.capacity(p.levels);
    for (final (store, res) in [
      (BuildingKind.metalStorage, ResourceKind.metal),
      (BuildingKind.crystalStorage, ResourceKind.crystal),
      (BuildingKind.deuteriumTank, ResourceKind.deuterium),
    ]) {
      final needs = cands.any((k) => rules.cost(k, lv(k) + 1)[res] > cap[res] * 0.8);
      if (needs) cands.add(store);
    }
    BuildingKind? best;
    var bestCost = double.infinity;
    for (final k in cands) {
      if (missingRequirements(s, k, rules).isNotEmpty) continue;
      final c = total(rules.cost(k, lv(k) + 1));
      if (c < bestCost) {
        best = k;
        bestCost = c;
      }
    }
    return best;
  }

  TechKind? nextTech() {
    TechKind? best;
    var bestCost = double.infinity;
    for (final k in TechKind.values) {
      if (s.research[k]! >= 10 || missingRequirements(s, k, rules).isNotEmpty) continue;
      final c = total(rules.cost(k, s.research[k]! + 1));
      if (c < bestCost) {
        best = k;
        bestCost = c;
      }
    }
    return best;
  }

  void play({int days = 14}) {
    s = game(planet(resources: data.start.resources));
    s = ensureRaidScheduled(s, t0, rules, seed: 11, eventId: 1);
    s = ensureStoryScheduled(s, t0, rules, seed: 12, eventId: 2);
    s = ensureBases(s, t0, rules, seed: 13);
    final end = t0.add(Duration(days: days));
    const step = Duration(minutes: 10);
    final checkpoints = [1, 3, 6, 12, 24, 48, 72, 120, 168, 240, 336];
    for (var t = t0; !t.isAfter(end); t = t.add(step)) {
      final day = t.difference(t0).inDays;
      final adv = advance(s, t, rules);
      s = adv.state;
      for (final r in adv.reports) {
        raids++;
        if (r.winner != CombatWinner.attacker) repelled++;
        looted += total(r.loot);
      }
      for (final o in adv.stories) {
        stories[o.key] = (stories[o.key] ?? 0) + 1;
      }
      // Choix : option par défaut (comme un joueur absent).
      for (final k in availableOfficers(s, data)) {
        s = promoteOfficer(s, k, t, rules).state;
        mark('officier ${data.officers[k]!.name} niv. ${s.officers[k]}', t);
        act(t, day);
      }
      if (s.currentConstruction == null) {
        final b = nextBuilding();
        if (b != null) {
          final o = startOrder(s, b, t, rules, eventId: id++);
          if (o is OrderStarted) {
            s = o.state;
            act(t, day);
          }
        }
      }
      if (s.planet.level(BuildingKind.researchLab) > 0 && s.currentResearch == null) {
        final k = nextTech();
        if (k != null) {
          final o = startOrder(s, k, t, rules, eventId: id++);
          if (o is OrderStarted) {
            s = o.state;
            act(t, day);
          }
        }
      }
      // Défense : viser 30 % de la valeur de l'économie en lanceurs de missiles.
      if (s.planet.level(BuildingKind.shipyard) > 0 && s.currentBatch == null) {
        final target = economyPoints(s, rules) * 1000 * 0.3;
        final have = fleetValue(s.planet.units, data);
        final n = math.min(
          ((target - have) / 2000).floor(),
          maxOrderable(s, UnitKind.rocketLauncher, rules),
        );
        if (n > 0) {
          final o = startBatch(s, UnitKind.rocketLauncher, n, t, rules, eventId: id++);
          if (o is BatchStarted) {
            s = o.state;
            act(t, day);
            mark('premier lanceur commandé', t);
          }
        }
      }
      final p = s.planet;
      if (p.level(BuildingKind.shipyard) > 0) mark('chantier 1', t);
      if (p.level(BuildingKind.researchLab) > 0) mark('labo 1', t);
      if (p.level(BuildingKind.metalMine) >= 10) mark('mine de métal 10', t);
      if (s.modifiers(data).productionFactor <= 2) mark('coup de pouce ≤ ×2', t);
      if (s.modifiers(data).productionFactor <= 1) mark('coup de pouce fini', t);
      final h = t.difference(t0).inMinutes / 60;
      if (checkpoints.contains(h.round()) && t.difference(t0).inMinutes % 60 == 0) {
        final rate = rules.hourlyProduction(p, s.research, s.modifiers(data));
        out(
          '$label|t=${h.round()}h|pts=${r0(points(s, rules))}|eco=${r0(economyPoints(s, rules))}'
          '|boost=${s.modifiers(data).productionFactor.toStringAsFixed(2)}'
          '|prod/h=${r0(rate.metal)}/${r0(rate.crystal)}/${r0(rate.deuterium)}'
          '|mines=${p.level(BuildingKind.metalMine)}/${p.level(BuildingKind.crystalMine)}/'
          '${p.level(BuildingKind.deuteriumSynthesizer)}'
          '|solaire=${p.level(BuildingKind.solarPlant)}|robots=${p.level(BuildingKind.roboticsFactory)}'
          '|chantier=${p.level(BuildingKind.shipyard)}|labo=${p.level(BuildingKind.researchLab)}'
          '|technos=${s.research.values.fold(0, (a, b) => a + b)}'
          '|lanceurs=${p.count(UnitKind.rocketLauncher)}'
          '|raids=$raids|repousses=$repelled|pille=${r0(looted)}|actions=$actions',
        );
      }
    }
    for (final e in milestones.entries) {
      out('$label|jalon|${e.key}|${e.value.toStringAsFixed(1)}h');
    }
    out('$label|actions_par_jour|${[for (var d = 0; d < days; d++) actionsByDay[d] ?? 0].join(',')}');
    out('$label|evenements|${stories.entries.map((e) => '${e.key}:${e.value}').join(',')}');
  }
}

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
      out('raid|eco=$pts|valeur=${r0(value)}|soute=${r0(cargo)}|lanceurs_equiv=${(value / 2000).toStringAsFixed(1)}');
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
      out('officier|${o.name}|niv1=${reqs.entries.map((e) => '${e.key.key}:${e.value}').join(',')}'
          '|${o.levels.first.counters.entries.map((e) => '${e.key.key}:${e.value}').join(',')}');
    }
    // Événements : effets exprimés en heures de production (×1).
    for (final e in data.story.catalog.values) {
      out('evenement|${e.key}|${e.kind.name}|${e.effects.map((x) => '${x.type.name}:${x.value}:${x.hours}h').join(',')}');
    }
    expect(boosted.s.planet.level(BuildingKind.metalMine), greaterThan(0));
  });
}
