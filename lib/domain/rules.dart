import 'dart:math' as math;

import 'game_data.dart';
import 'planet.dart';
import 'resources.dart';

/// Niveaux des technologies (globaux à la partie). Une techno absente vaut 0.
typedef TechLevels = Map<TechKind, int>;

/// Modificateurs appliqués par les formules : bonus des officiers (spec 12), et plus tard
/// effets des événements (spec 14). Toutes les valeurs sont des fractions.
class Modifiers {
  const Modifiers({
    this.mineProduction = 0,
    this.researchTime = 0,
    this.buildTime = 0,
    this.defenseRebuild = 0,
    this.constructionQueue = 0,
    this.researchQueue = 0,
    this.shipyardQueue = 0,
  });

  static const none = Modifiers();

  /// Ajouté au bonus de production des mines (0.1 = +10 %).
  final double mineProduction;

  /// Réduction de la durée de recherche (0.1 = −10 %).
  final double researchTime;

  /// Réduction de la durée de construction des bâtiments.
  final double buildTime;

  /// Ajouté à la part de défenses reconstruites après un combat.
  final double defenseRebuild;

  /// Ordres en plus dans chaque file d'attente (spec 13).
  final int constructionQueue;
  final int researchQueue;
  final int shipyardQueue;
}

/// Bilan d'énergie instantané de la planète.
class EnergyBalance {
  const EnergyBalance({required this.produced, required this.consumed});

  final double produced;
  final double consumed;

  double get net => produced - consumed;

  /// Facteur appliqué à la production des mines : min(1, produite / consommée).
  double get factor => consumed <= 0 ? 1 : math.min(1, produced / consumed);
}

/// Formules de jeu (OGame classique). [speed] multiplie production et consommation, et
/// divise les durées.
class Rules {
  const Rules(this.data, {this.speed = 1});

  final GameData data;
  final double speed;

  FormulaConstants get _f => data.formulas;

  double _scaled(int level, [double? growth]) =>
      level * math.pow(growth ?? _f.growth, level).toDouble();

  static int _t(TechLevels tech, TechKind k) => tech[k] ?? 0;

  /// Coût pour passer au niveau [targetLevel] (≥ 1) : floor(base × facteur^(N−1)).
  Resources cost(Unlockable item, int targetLevel) {
    assert(targetLevel >= 1);
    final spec = data.spec(item);
    final k = math.pow(spec.costFactor, targetLevel - 1).toDouble();
    return spec.baseCost.map((_, v) => (v * k).floorToDouble());
  }

  /// Construction : (M + C) / (divisor × (1 + robots) × 2^nanites × vitesse) heures,
  /// réduite de [reduction] (Architecte).
  Duration buildDuration(
    Resources cost, {
    required int roboticsLevel,
    int naniteLevel = 0,
    double reduction = 0,
  }) {
    final divisor = _f.buildTimeDivisor * (1 + roboticsLevel) * math.pow(2, naniteLevel).toDouble();
    return _duration(cost, divisor, reduction);
  }

  /// Unité du chantier : (M + C) / (divisor × (1 + chantier) × 2^nanites × vitesse) heures.
  Duration unitDuration(Resources cost, {required int shipyardLevel, int naniteLevel = 0}) {
    final divisor = _f.buildTimeDivisor * (1 + shipyardLevel) * math.pow(2, naniteLevel).toDouble();
    return _duration(cost, divisor);
  }

  /// Recherche : (M + C) / (divisor × (1 + labo) × vitesse) heures, réduite de
  /// [reduction] (Technocrate).
  Duration researchDuration(Resources cost, {required int labLevel, double reduction = 0}) =>
      _duration(cost, _f.researchTimeDivisor * (1 + labLevel), reduction);

  /// Arrondi à la seconde inférieure, au moins 1 s.
  Duration _duration(Resources cost, double divisor, [double reduction = 0]) {
    final hours = (cost.metal + cost.crystal) / (divisor * speed) * (1 - reduction);
    return Duration(seconds: math.max(1, (hours * 3600).floor()));
  }

  EnergyBalance energy(Planet planet, TechLevels tech) {
    var produced = 0.0;
    var consumed = 0.0;
    for (final spec in data.buildings.values) {
      final level = planet.level(spec.kind);
      if (level == 0) continue;
      final p = planet.percent(spec.kind) / 100;
      if (spec.energyProduction > 0) {
        final growthTech = spec.energyGrowthTech;
        final growth =
            (spec.energyGrowth ?? _f.growth) +
            (growthTech == null ? 0 : spec.energyGrowthPerTechLevel * _t(tech, growthTech));
        produced += p * spec.energyProduction * _scaled(level, growth);
      }
      consumed += p * spec.energyConsumption * _scaled(level);
    }
    return EnergyBalance(produced: produced, consumed: consumed);
  }

  /// Bonus de production des mines apporté par les technos (0.05 = +5 %).
  Resources productionBonus(TechLevels tech) {
    var bonus = Resources.zero;
    for (final spec in data.research.values) {
      bonus = bonus + spec.productionBonus * _t(tech, spec.kind).toDouble();
    }
    return bonus;
  }

  /// Production horaire nette, vitesse comprise :
  /// base + mines × facteur d'énergie × (1 + bonus des technos + officiers)
  /// − consommations (fusion). La production de base et les consommations ne dépendent pas
  /// de l'énergie.
  Resources hourlyProduction(Planet planet, TechLevels tech, [Modifiers mods = Modifiers.none]) {
    final factor = energy(planet, tech).factor;
    final bonus = productionBonus(tech).map((_, v) => v + mods.mineProduction);
    var mines = Resources.zero;
    var consumption = Resources.zero;
    for (final spec in data.buildings.values) {
      final level = planet.level(spec.kind);
      if (level == 0) continue;
      final p = planet.percent(spec.kind) / 100;
      final produces = spec.produces;
      if (produces != null) {
        var amount = p * spec.productionCoefficient * _scaled(level);
        if (produces == ResourceKind.deuterium) {
          amount *= _f.deuteriumTempIntercept + _f.deuteriumTempSlope * planet.tempMax;
        }
        mines = mines + _single(produces, amount);
      }
      final consumes = spec.consumes;
      if (consumes != null) {
        consumption =
            consumption + _single(consumes, p * spec.consumptionCoefficient * _scaled(level));
      }
    }
    final boosted = Resources.of((k) => mines[k] * factor * (1 + bonus[k]));
    return (_f.baseProductionPerHour + boosted - consumption) * speed;
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

  /// Production entre deux instants à niveaux constants. Plafonnée au stockage ; un stock
  /// déjà au-dessus (remboursement) est conservé sans production. Une production nette
  /// négative (fusion) fait baisser le stock jusqu'à 0.
  Resources produce(
    Planet planet,
    TechLevels tech,
    Duration elapsed, [
    Modifiers mods = Modifiers.none,
  ]) {
    if (elapsed <= Duration.zero) return planet.resources;
    final hours = elapsed.inMicroseconds / Duration.microsecondsPerHour;
    final rate = hourlyProduction(planet, tech, mods);
    final cap = capacity(planet.levels);
    return planet.resources.map((k, stock) {
      if (rate[k] < 0) return math.max(0.0, stock + rate[k] * hours);
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
