import 'dart:math' as math;

import 'game_data.dart';
import 'planet.dart';
import 'resources.dart';

/// Bilan d'énergie instantané de la planète.
class EnergyBalance {
  const EnergyBalance({required this.produced, required this.consumed});

  final double produced;
  final double consumed;

  double get net => produced - consumed;

  /// Facteur appliqué à la production des mines : min(1, produite / consommée).
  double get factor => consumed <= 0 ? 1 : math.min(1, produced / consumed);
}

/// Formules de jeu (OGame classique). [speed] multiplie la production et divise les durées.
class Rules {
  const Rules(this.data, {this.speed = 1});

  final GameData data;
  final double speed;

  FormulaConstants get _f => data.formulas;

  double _scaled(int level) => level * math.pow(_f.growth, level).toDouble();

  /// Coût pour passer au niveau [targetLevel] (≥ 1) : floor(base × facteur^(N−1)).
  Resources cost(BuildingKind kind, int targetLevel) {
    assert(targetLevel >= 1);
    final spec = data[kind];
    final k = math.pow(spec.costFactor, targetLevel - 1).toDouble();
    return spec.baseCost.map((_, v) => (v * k).floorToDouble());
  }

  /// Durée de construction : (M + C) / (divisor × (1 + robots) × vitesse) heures,
  /// arrondie à la seconde inférieure, au moins 1 s.
  Duration buildDuration(Resources cost, {required int roboticsLevel}) {
    final hours = (cost.metal + cost.crystal) / (_f.buildTimeDivisor * (1 + roboticsLevel) * speed);
    final seconds = (hours * 3600).floor();
    return Duration(seconds: math.max(1, seconds));
  }

  EnergyBalance energy(Map<BuildingKind, int> levels) {
    var produced = 0.0;
    var consumed = 0.0;
    for (final spec in data.buildings.values) {
      final scaled = _scaled(levels[spec.kind] ?? 0);
      produced += spec.energyProduction * scaled;
      consumed += spec.energyConsumption * scaled;
    }
    return EnergyBalance(produced: produced, consumed: consumed);
  }

  /// Production horaire, vitesse et facteur d'énergie inclus. La production de base
  /// n'est pas affectée par l'énergie.
  Resources hourlyProduction(Map<BuildingKind, int> levels, {required int tempMax}) {
    final factor = energy(levels).factor;
    var mines = Resources.zero;
    for (final spec in data.buildings.values) {
      final produces = spec.produces;
      if (produces == null) continue;
      var amount = spec.productionCoefficient * _scaled(levels[spec.kind] ?? 0);
      if (produces == ResourceKind.deuterium) {
        amount *= _f.deuteriumTempIntercept + _f.deuteriumTempSlope * tempMax;
      }
      mines = mines + _single(produces, amount);
    }
    return (_f.baseProductionPerHour + mines * factor) * speed;
  }

  /// Capacité d'un hangar de niveau N : base × floor(multiplier × e^(num × N / den)).
  double storageCapacity(int level) {
    final exponent = _f.storageExponentNumerator * level / _f.storageExponentDenominator;
    return _f.storageBase * (_f.storageMultiplier * math.exp(exponent)).floorToDouble();
  }

  Resources capacity(Map<BuildingKind, int> levels) {
    final byResource = {
      for (final spec in data.buildings.values)
        if (spec.stores != null) spec.stores!: storageCapacity(levels[spec.kind] ?? 0),
    };
    return Resources.of((k) => byResource[k] ?? double.infinity);
  }

  /// Production entre deux instants à niveaux constants, plafonnée au stockage.
  /// Un stock déjà au-dessus de la capacité (remboursement) est conservé, sans production.
  Resources produce(Planet planet, Duration elapsed) {
    if (elapsed <= Duration.zero) return planet.resources;
    final hours = elapsed.inMicroseconds / Duration.microsecondsPerHour;
    final rate = hourlyProduction(planet.levels, tempMax: planet.tempMax);
    final cap = capacity(planet.levels);
    return planet.resources.map((k, stock) {
      if (stock >= cap[k]) return stock;
      return math.min(cap[k], stock + rate[k] * hours);
    });
  }

  static Resources _single(ResourceKind kind, double amount) => switch (kind) {
    ResourceKind.metal => Resources(metal: amount),
    ResourceKind.crystal => Resources(crystal: amount),
    ResourceKind.deuterium => Resources(deuterium: amount),
  };
}
