import 'resources.dart';

/// Les bâtiments de la V0. La clé est celle de `assets/game_data.yaml` et de la base.
enum BuildingKind {
  metalMine('metal_mine'),
  crystalMine('crystal_mine'),
  deuteriumSynthesizer('deuterium_synthesizer'),
  solarPlant('solar_plant'),
  metalStorage('metal_storage'),
  crystalStorage('crystal_storage'),
  deuteriumTank('deuterium_tank'),
  roboticsFactory('robotics_factory');

  const BuildingKind(this.key);

  final String key;

  static BuildingKind fromKey(String key) => values.firstWhere(
    (k) => k.key == key,
    orElse: () => throw FormatException('Bâtiment inconnu : $key'),
  );
}

/// Paramètres d'un bâtiment. Un bâtiment produit, consomme, stocke ou ne fait rien
/// (usine de robots) ; les champs non concernés valent 0 ou null.
class BuildingSpec {
  const BuildingSpec({
    required this.kind,
    required this.name,
    required this.baseCost,
    required this.costFactor,
    this.produces,
    this.productionCoefficient = 0,
    this.energyConsumption = 0,
    this.energyProduction = 0,
    this.stores,
  });

  final BuildingKind kind;
  final String name;
  final Resources baseCost;
  final double costFactor;
  final ResourceKind? produces;
  final double productionCoefficient;
  final double energyConsumption;
  final double energyProduction;
  final ResourceKind? stores;
}

/// Constantes des formules globales (voir le doc de specs, section Règles et formules).
class FormulaConstants {
  const FormulaConstants({
    required this.growth,
    required this.baseProductionPerHour,
    required this.deuteriumTempIntercept,
    required this.deuteriumTempSlope,
    required this.storageBase,
    required this.storageMultiplier,
    required this.storageExponentNumerator,
    required this.storageExponentDenominator,
    required this.buildTimeDivisor,
  });

  /// Base de croissance N × growth^N (1.1 dans OGame).
  final double growth;
  final Resources baseProductionPerHour;

  /// Facteur deutérium = intercept + slope × Tmax (1.44 − 0.004 × Tmax).
  final double deuteriumTempIntercept;
  final double deuteriumTempSlope;

  /// Capacité = base × floor(multiplier × e^(num × N / den)).
  final double storageBase;
  final double storageMultiplier;
  final double storageExponentNumerator;
  final double storageExponentDenominator;

  /// Durée (h) = (M + C) / (divisor × (1 + robots) × vitesse).
  final double buildTimeDivisor;
}

class StartConditions {
  const StartConditions({
    required this.resources,
    required this.tempMaxMin,
    required this.tempMaxMax,
  });

  final Resources resources;
  final int tempMaxMin;
  final int tempMaxMax;
}

/// Toutes les données de jeu, construites depuis une Map (le chargement YAML est dans `data/`).
class GameData {
  GameData({
    required this.formulas,
    required this.start,
    required Map<BuildingKind, BuildingSpec> buildings,
  }) : buildings = Map.unmodifiable(buildings) {
    final missing = BuildingKind.values.where((k) => !buildings.containsKey(k));
    if (missing.isNotEmpty) {
      throw FormatException('Bâtiments absents de la config : ${missing.map((k) => k.key)}');
    }
  }

  final FormulaConstants formulas;
  final StartConditions start;
  final Map<BuildingKind, BuildingSpec> buildings;

  BuildingSpec operator [](BuildingKind kind) => buildings[kind]!;

  factory GameData.fromMap(Map<String, Object?> map) {
    final f = _map(map, 'formulas');
    final storage = _map(f, 'storage');
    final deut = _map(f, 'deuterium_temperature');
    final start = _map(map, 'start');
    final temp = _map(start, 'temp_max');
    final buildings = _map(map, 'buildings');

    return GameData(
      formulas: FormulaConstants(
        growth: _num(f, 'growth'),
        baseProductionPerHour: _resources(_map(f, 'base_production_per_hour')),
        deuteriumTempIntercept: _num(deut, 'intercept'),
        deuteriumTempSlope: _num(deut, 'slope'),
        storageBase: _num(storage, 'base'),
        storageMultiplier: _num(storage, 'multiplier'),
        storageExponentNumerator: _num(storage, 'exponent_numerator'),
        storageExponentDenominator: _num(storage, 'exponent_denominator'),
        buildTimeDivisor: _num(f, 'build_time_divisor'),
      ),
      start: StartConditions(
        resources: _resources(_map(start, 'resources')),
        tempMaxMin: _num(temp, 'min').toInt(),
        tempMaxMax: _num(temp, 'max').toInt(),
      ),
      buildings: {
        for (final entry in buildings.entries)
          BuildingKind.fromKey(entry.key): _building(
            BuildingKind.fromKey(entry.key),
            _asMap(entry.value, entry.key),
          ),
      },
    );
  }

  static BuildingSpec _building(BuildingKind kind, Map<String, Object?> m) {
    final production = m['production'] == null ? null : _map(m, 'production');
    final energy = m['energy'] == null ? null : _map(m, 'energy');
    return BuildingSpec(
      kind: kind,
      name: _string(m, 'name'),
      baseCost: _resources(_map(m, 'cost')),
      costFactor: _num(m, 'factor'),
      produces: production == null ? null : _resourceKind(_string(production, 'resource')),
      productionCoefficient: production == null ? 0 : _num(production, 'coefficient'),
      energyConsumption: energy?['consumption'] == null ? 0 : _num(energy!, 'consumption'),
      energyProduction: energy?['production'] == null ? 0 : _num(energy!, 'production'),
      stores: m['stores'] == null ? null : _resourceKind(_string(m, 'stores')),
    );
  }

  static Resources _resources(Map<String, Object?> m) => Resources(
    metal: _numOr(m, 'metal'),
    crystal: _numOr(m, 'crystal'),
    deuterium: _numOr(m, 'deuterium'),
  );

  static ResourceKind _resourceKind(String name) => ResourceKind.values.firstWhere(
    (k) => k.name == name,
    orElse: () => throw FormatException('Ressource inconnue : $name'),
  );

  static Map<String, Object?> _map(Map<String, Object?> m, String key) => _asMap(m[key], key);

  static Map<String, Object?> _asMap(Object? v, String key) {
    if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
    throw FormatException('« $key » doit être une table');
  }

  static double _num(Map<String, Object?> m, String key) {
    final v = m[key];
    if (v is num) return v.toDouble();
    throw FormatException('« $key » doit être un nombre');
  }

  static double _numOr(Map<String, Object?> m, String key) => m[key] == null ? 0 : _num(m, key);

  static String _string(Map<String, Object?> m, String key) {
    final v = m[key];
    if (v is String) return v;
    throw FormatException('« $key » doit être une chaîne');
  }
}
