import 'dart:math' as math;

import 'game_data.dart';
import 'rules.dart';

/// Un camp : ses unités et ses technos de combat (Armes, Bouclier, Protection).
class CombatSide {
  const CombatSide({required this.units, this.tech = const {}});

  final Map<UnitKind, int> units;
  final TechLevels tech;
}

enum CombatWinner { attacker, defender, draw }

/// Tirs d'un camp pendant un round.
class Volley {
  const Volley({this.shots = 0, this.fired = 0, this.toShields = 0, this.toHull = 0});

  final int shots;

  /// Puissance totale tirée.
  final double fired;

  /// Part encaissée par les boucliers ennemis.
  final double toShields;

  /// Part infligée aux coques (dégâts réels).
  final double toHull;

  /// Part perdue : règle du 1 %, cibles déjà détruites, excédent sur une coque.
  double get wasted => fired - toShields - toHull;
}

/// Puissance totale d'un camp, technos comprises.
class SideStrength {
  const SideStrength({
    required this.units,
    required this.attack,
    required this.shield,
    required this.hull,
  });

  factory SideStrength.of(GameData data, CombatSide side) {
    var units = 0;
    var attack = 0.0;
    var shield = 0.0;
    var hull = 0.0;
    for (final e in side.units.entries) {
      if (e.value <= 0) continue;
      final s = UnitStats.of(data.unit(e.key), side.tech);
      units += e.value;
      attack += s.attack * e.value;
      shield += s.shield * e.value;
      hull += s.hull * e.value;
    }
    return SideStrength(units: units, attack: attack, shield: shield, hull: hull);
  }

  final int units;

  /// Puissance de feu par round, hors tir rapide.
  final double attack;
  final double shield;
  final double hull;
}

class CombatRound {
  const CombatRound({
    required this.attacker,
    required this.defender,
    required this.attackerLeft,
    required this.defenderLeft,
  });

  /// Tirs de l'attaquant et du défenseur.
  final Volley attacker;
  final Volley defender;

  int get attackerShots => attacker.shots;
  int get defenderShots => defender.shots;

  /// Unités restantes à la fin du round.
  final Map<UnitKind, int> attackerLeft;
  final Map<UnitKind, int> defenderLeft;
}

class CombatResult {
  const CombatResult({
    required this.winner,
    required this.rounds,
    required this.attackerStart,
    required this.defenderStart,
    required this.attackerLeft,
    required this.defenderLeft,
    required this.rebuilt,
  });

  final CombatWinner winner;
  final List<CombatRound> rounds;
  final Map<UnitKind, int> attackerStart;
  final Map<UnitKind, int> defenderStart;
  final Map<UnitKind, int> attackerLeft;

  /// Unités du défenseur après reconstruction des défenses.
  final Map<UnitKind, int> defenderLeft;

  /// Défenses détruites puis reconstruites (70 % en moyenne).
  final Map<UnitKind, int> rebuilt;

  Map<UnitKind, int> get attackerLosses => _diff(attackerStart, attackerLeft);
  Map<UnitKind, int> get defenderLosses => _diff(defenderStart, defenderLeft);

  static Map<UnitKind, int> _diff(Map<UnitKind, int> a, Map<UnitKind, int> b) => {
    for (final e in a.entries)
      if (e.value - (b[e.key] ?? 0) > 0) e.key: e.value - (b[e.key] ?? 0),
  };
}

/// Caractéristiques de combat d'une unité, technos comprises (+10 % par niveau).
class UnitStats {
  const UnitStats({required this.attack, required this.shield, required this.hull});

  final double attack;
  final double shield;
  final double hull;

  factory UnitStats.of(UnitSpec spec, TechLevels tech) => UnitStats(
    attack: spec.attack * (1 + 0.1 * (tech[TechKind.weapons] ?? 0)),
    shield: spec.shield * (1 + 0.1 * (tech[TechKind.shielding] ?? 0)),
    hull: spec.hull * (1 + 0.1 * (tech[TechKind.armour] ?? 0)),
  );
}

/// Part des défenses détruites reconstruites après la bataille.
const defenseRebuildChance = 0.7;
const maxRounds = 6;

/// Bataille selon les règles OGame classiques :
/// - jusqu'à 6 rounds ; chaque unité tire sur une unité ennemie au hasard ;
/// - tir rapide n contre la cible : chance (n − 1) / n de tirer à nouveau ;
/// - un tir inférieur à 1 % du bouclier de la cible est absorbé sans effet ;
/// - le bouclier absorbe avant la coque, et se régénère à chaque round ;
/// - sous 70 % de coque, explosion avec une probabilité de 1 − coque / coque initiale ;
/// - 70 % des défenses détruites sont reconstruites.
/// Déterministe pour un [random] donné.
CombatResult simulateCombat(
  GameData data,
  CombatSide attacker,
  CombatSide defender,
  math.Random random,
) {
  final a = _Army.of(data, attacker);
  final d = _Army.of(data, defender);
  final rounds = <CombatRound>[];

  for (var round = 0; round < maxRounds && a.alive > 0 && d.alive > 0; round++) {
    // Tirs simultanés : une unité détruite pendant le round tire quand même.
    final aShots = a.fireAt(d, data, random);
    final dShots = d.fireAt(a, data, random);
    a.endRound(random);
    d.endRound(random);
    rounds.add(
      CombatRound(
        attacker: aShots,
        defender: dShots,
        attackerLeft: a.counts(),
        defenderLeft: d.counts(),
      ),
    );
  }

  final winner = a.alive > 0 && d.alive == 0
      ? CombatWinner.attacker
      : d.alive > 0 && a.alive == 0
      ? CombatWinner.defender
      : CombatWinner.draw;

  final defenderLeft = d.counts();
  final rebuilt = <UnitKind, int>{};
  for (final e in defender.units.entries) {
    if (!data.unit(e.key).defense) continue;
    final lost = e.value - (defenderLeft[e.key] ?? 0);
    var back = 0;
    for (var i = 0; i < lost; i++) {
      if (random.nextDouble() < defenseRebuildChance) back++;
    }
    if (back > 0) {
      rebuilt[e.key] = back;
      defenderLeft[e.key] = (defenderLeft[e.key] ?? 0) + back;
    }
  }

  return CombatResult(
    winner: winner,
    rounds: rounds,
    attackerStart: {...attacker.units}..removeWhere((_, n) => n <= 0),
    defenderStart: {...defender.units}..removeWhere((_, n) => n <= 0),
    attackerLeft: a.counts(),
    defenderLeft: defenderLeft..removeWhere((_, n) => n <= 0),
    rebuilt: rebuilt,
  );
}

/// Unités d'un camp, une entrée par unité (tableaux parallèles).
class _Army {
  _Army(this.kinds, this.stats, this.hull, this.shield);

  factory _Army.of(GameData data, CombatSide side) {
    final kinds = <UnitKind>[];
    final stats = <UnitStats>[];
    for (final e in side.units.entries) {
      final s = UnitStats.of(data.unit(e.key), side.tech);
      for (var i = 0; i < e.value; i++) {
        kinds.add(e.key);
        stats.add(s);
      }
    }
    return _Army(kinds, stats, [for (final s in stats) s.hull], [for (final s in stats) s.shield]);
  }

  List<UnitKind> kinds;
  List<UnitStats> stats;
  List<double> hull;
  List<double> shield;

  int get alive => kinds.length;

  /// Toutes les unités tirent sur [enemy].
  Volley fireAt(_Army enemy, GameData data, math.Random random) {
    if (enemy.alive == 0) return const Volley();
    var shots = 0;
    var fired = 0.0;
    var toShields = 0.0;
    var toHull = 0.0;
    for (var i = 0; i < kinds.length; i++) {
      final rapidFire = data.unit(kinds[i]).rapidFire;
      final attack = stats[i].attack;
      while (true) {
        final target = random.nextInt(enemy.alive);
        final (s, h) = enemy._hit(target, attack);
        shots++;
        fired += attack;
        toShields += s;
        toHull += h;
        final rf = rapidFire[enemy.kinds[target]] ?? 0;
        if (rf <= 1 || random.nextDouble() >= (rf - 1) / rf) break;
      }
    }
    return Volley(shots: shots, fired: fired, toShields: toShields, toHull: toHull);
  }

  /// Applique un tir ; renvoie (encaissé par le bouclier, infligé à la coque).
  (double, double) _hit(int target, double damage) {
    if (hull[target] <= 0) return (0, 0); // déjà détruite ce round : tir perdu
    if (damage < 0.01 * stats[target].shield) return (0, 0); // règle du 1 %
    if (damage <= shield[target]) {
      shield[target] -= damage;
      return (damage, 0);
    }
    final absorbed = shield[target];
    final toHull = math.min(hull[target], damage - absorbed);
    hull[target] -= damage - absorbed;
    shield[target] = 0;
    return (absorbed, toHull);
  }

  /// Explosions, retrait des unités détruites, régénération des boucliers.
  void endRound(math.Random random) {
    final k = <UnitKind>[];
    final s = <UnitStats>[];
    final h = <double>[];
    for (var i = 0; i < kinds.length; i++) {
      final ratio = hull[i] / stats[i].hull;
      if (ratio <= 0) continue;
      if (ratio < 0.7 && random.nextDouble() < 1 - ratio) continue;
      k.add(kinds[i]);
      s.add(stats[i]);
      h.add(hull[i]);
    }
    kinds = k;
    stats = s;
    hull = h;
    shield = [for (final x in s) x.shield];
  }

  Map<UnitKind, int> counts() {
    final c = <UnitKind, int>{};
    for (final k in kinds) {
      c[k] = (c[k] ?? 0) + 1;
    }
    return c;
  }
}
