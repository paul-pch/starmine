import 'resources.dart';

/// Ce qui a un niveau et peut servir de prérequis : bâtiment ou technologie.
/// La clé est celle de `assets/game_data.yaml` et de la base.
sealed class Unlockable {
  String get key;

  static Unlockable fromKey(String key) {
    for (final k in BuildingKind.values) {
      if (k.key == key) return k;
    }
    for (final k in TechKind.values) {
      if (k.key == key) return k;
    }
    throw FormatException('Bâtiment ou technologie inconnu : $key');
  }
}

enum BuildingKind implements Unlockable {
  metalMine('metal_mine'),
  crystalMine('crystal_mine'),
  deuteriumSynthesizer('deuterium_synthesizer'),
  solarPlant('solar_plant'),
  fusionReactor('fusion_reactor'),
  metalStorage('metal_storage'),
  crystalStorage('crystal_storage'),
  deuteriumTank('deuterium_tank'),
  roboticsFactory('robotics_factory'),
  naniteFactory('nanite_factory'),
  shipyard('shipyard'),
  researchLab('research_lab');

  const BuildingKind(this.key);

  @override
  final String key;

  static BuildingKind fromKey(String key) => values.firstWhere(
    (k) => k.key == key,
    orElse: () => throw FormatException('Bâtiment inconnu : $key'),
  );
}

enum TechKind implements Unlockable {
  energy('energy_technology'),
  laser('laser_technology'),
  ion('ion_technology'),
  plasma('plasma_technology'),
  computer('computer_technology'),
  weapons('weapons_technology'),
  shielding('shielding_technology'),
  armour('armour_technology');

  const TechKind(this.key);

  @override
  final String key;

  static TechKind fromKey(String key) => values.firstWhere(
    (k) => k.key == key,
    orElse: () => throw FormatException('Technologie inconnue : $key'),
  );
}

/// Unités produites au chantier : défenses (V2) et vaisseaux (pirates en V2, joueur en V3).
enum UnitKind {
  rocketLauncher('rocket_launcher'),
  lightLaser('light_laser'),
  heavyLaser('heavy_laser'),
  gaussCannon('gauss_cannon'),
  ionCannon('ion_cannon'),
  plasmaTurret('plasma_turret'),
  smallShieldDome('small_shield_dome'),
  largeShieldDome('large_shield_dome'),
  smallCargo('small_cargo'),
  largeCargo('large_cargo'),
  lightFighter('light_fighter'),
  heavyFighter('heavy_fighter'),
  cruiser('cruiser'),
  battleship('battleship');

  const UnitKind(this.key);

  final String key;

  static UnitKind fromKey(String key) => values.firstWhere(
    (k) => k.key == key,
    orElse: () => throw FormatException('Unité inconnue : $key'),
  );
}

/// Partie commune aux bâtiments et technologies.
abstract class ItemSpec {
  const ItemSpec({
    required this.name,
    required this.description,
    required this.baseCost,
    required this.costFactor,
    required this.requires,
  });

  final String name;
  final String description;
  final Resources baseCost;
  final double costFactor;

  /// Niveaux minimums requis pour construire ou rechercher le premier niveau.
  final Map<Unlockable, int> requires;
}

/// Paramètres d'un bâtiment ; les champs non concernés valent 0 ou null.
class BuildingSpec extends ItemSpec {
  const BuildingSpec({
    required this.kind,
    required super.name,
    super.description = '',
    required super.baseCost,
    required super.costFactor,
    super.requires = const {},
    this.produces,
    this.productionCoefficient = 0,
    this.consumes,
    this.consumptionCoefficient = 0,
    this.energyConsumption = 0,
    this.energyProduction = 0,
    this.energyGrowth,
    this.energyGrowthTech,
    this.energyGrowthPerTechLevel = 0,
    this.stores,
  });

  final BuildingKind kind;

  /// Production horaire : coefficient × N × growth^N.
  final ResourceKind? produces;
  final double productionCoefficient;

  /// Consommation horaire de ressource (fusion) : coefficient × N × growth^N.
  final ResourceKind? consumes;
  final double consumptionCoefficient;

  /// Énergie consommée : coefficient × N × growth^N.
  final double energyConsumption;

  /// Énergie produite : coefficient × N × g^N, avec
  /// g = energyGrowth (défaut : growth global) + energyGrowthPerTechLevel × niveau de la techno.
  final double energyProduction;
  final double? energyGrowth;
  final TechKind? energyGrowthTech;
  final double energyGrowthPerTechLevel;

  final ResourceKind? stores;

  /// Bâtiment dont la production peut être réglée de 0 à 100 %.
  bool get adjustable => produces != null || energyProduction > 0;
}

/// Défense ou vaisseau. La coque vaut (M + C) / 10.
class UnitSpec extends ItemSpec {
  const UnitSpec({
    required this.kind,
    required super.name,
    super.description = '',
    required super.baseCost,
    super.requires = const {},
    required this.defense,
    required this.attack,
    required this.shield,
    this.cargo = 0,
    this.maxCount,
    this.rapidFire = const {},
  }) : super(costFactor: 1);

  final UnitKind kind;

  /// Défense planétaire (constructible en V2) ; sinon vaisseau.
  final bool defense;
  final double attack;
  final double shield;
  final double cargo;

  /// Nombre maximal par planète (dômes : 1), `null` = illimité.
  final int? maxCount;

  /// Tir rapide contre un type : n = chance (n − 1) / n de tirer à nouveau.
  final Map<UnitKind, int> rapidFire;

  double get hull => (baseCost.metal + baseCost.crystal) / 10;
}

class TechSpec extends ItemSpec {
  const TechSpec({
    required this.kind,
    required super.name,
    super.description = '',
    required super.baseCost,
    required super.costFactor,
    super.requires = const {},
    this.productionBonus = Resources.zero,
  });

  final TechKind kind;

  /// Bonus de production des mines par niveau (fraction : 0.01 = +1 %).
  final Resources productionBonus;
}

/// Constantes des formules globales (voir le doc de specs).
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
    required this.researchTimeDivisor,
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

  /// Construction (h) = (M + C) / (divisor × (1 + robots) × 2^nanites × vitesse).
  final double buildTimeDivisor;

  /// Recherche (h) = (M + C) / (divisor × (1 + labo) × vitesse).
  final double researchTimeDivisor;
}

class StartConditions {
  const StartConditions({
    required this.resources,
    required this.tempMaxMin,
    required this.tempMaxMax,
    required this.tempSpread,
  });

  final Resources resources;
  final int tempMaxMin;
  final int tempMaxMax;

  /// Écart entre températures max et min d'une planète.
  final int tempSpread;
}

/// Toutes les données de jeu, construites depuis une Map (le chargement YAML est dans `data/`).
class GameData {
  GameData({
    required this.formulas,
    required this.start,
    required Map<BuildingKind, BuildingSpec> buildings,
    required Map<TechKind, TechSpec> research,
    required Map<UnitKind, UnitSpec> units,
  }) : units = Map.unmodifiable(units),
       buildings = Map.unmodifiable(buildings),
       research = Map.unmodifiable(research) {
    final missing = <Unlockable>[
      ...BuildingKind.values.where((k) => !buildings.containsKey(k)),
      ...TechKind.values.where((k) => !research.containsKey(k)),
    ];
    final missingUnits = UnitKind.values.where((k) => !units.containsKey(k)).map((k) => k.key);
    if (missingUnits.isNotEmpty) {
      throw FormatException('Unités absentes de la config : $missingUnits');
    }
    if (missing.isNotEmpty) {
      throw FormatException('Absents de la config : ${missing.map((k) => k.key)}');
    }
  }

  final FormulaConstants formulas;
  final StartConditions start;
  final Map<BuildingKind, BuildingSpec> buildings;
  final Map<TechKind, TechSpec> research;
  final Map<UnitKind, UnitSpec> units;

  UnitSpec unit(UnitKind kind) => units[kind]!;

  BuildingSpec operator [](BuildingKind kind) => buildings[kind]!;

  TechSpec tech(TechKind kind) => research[kind]!;

  ItemSpec spec(Unlockable item) => switch (item) {
    BuildingKind() => buildings[item]!,
    TechKind() => research[item]!,
  };

  factory GameData.fromMap(Map<String, Object?> map) {
    final f = _map(map, 'formulas');
    final storage = _map(f, 'storage');
    final deut = _map(f, 'deuterium_temperature');
    final start = _map(map, 'start');
    final temp = _map(start, 'temp_max');
    final buildings = _map(map, 'buildings');
    final research = _map(map, 'research');
    final units = _map(map, 'units');

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
        researchTimeDivisor: _num(f, 'research_time_divisor'),
      ),
      start: StartConditions(
        resources: _resources(_map(start, 'resources')),
        tempMaxMin: _num(temp, 'min').toInt(),
        tempMaxMax: _num(temp, 'max').toInt(),
        tempSpread: _num(start, 'temp_spread').toInt(),
      ),
      buildings: {
        for (final e in buildings.entries)
          BuildingKind.fromKey(e.key): _building(
            BuildingKind.fromKey(e.key),
            _asMap(e.value, e.key),
          ),
      },
      research: {
        for (final e in research.entries)
          TechKind.fromKey(e.key): _tech(TechKind.fromKey(e.key), _asMap(e.value, e.key)),
      },
      units: {
        for (final e in units.entries)
          UnitKind.fromKey(e.key): _unit(UnitKind.fromKey(e.key), _asMap(e.value, e.key)),
      },
    );
  }

  static BuildingSpec _building(BuildingKind kind, Map<String, Object?> m) {
    final production = _optMap(m, 'production');
    final consumption = _optMap(m, 'consumption');
    final energy = _optMap(m, 'energy');
    final growthTech = energy == null ? null : _optMap(energy, 'growth_per_tech_level');
    return BuildingSpec(
      kind: kind,
      name: _string(m, 'name'),
      description: _stringOr(m, 'description'),
      baseCost: _resources(_map(m, 'cost')),
      costFactor: _num(m, 'factor'),
      requires: _requires(m),
      produces: production == null ? null : _resourceKind(_string(production, 'resource')),
      productionCoefficient: production == null ? 0 : _num(production, 'coefficient'),
      consumes: consumption == null ? null : _resourceKind(_string(consumption, 'resource')),
      consumptionCoefficient: consumption == null ? 0 : _num(consumption, 'coefficient'),
      energyConsumption: energy == null ? 0 : _numOr(energy, 'consumption'),
      energyProduction: energy == null ? 0 : _numOr(energy, 'production'),
      energyGrowth: energy?['growth'] == null ? null : _num(energy!, 'growth'),
      energyGrowthTech: growthTech == null ? null : TechKind.fromKey(growthTech.keys.single),
      energyGrowthPerTechLevel: growthTech == null ? 0 : _num(growthTech, growthTech.keys.single),
      stores: m['stores'] == null ? null : _resourceKind(_string(m, 'stores')),
    );
  }

  static UnitSpec _unit(UnitKind kind, Map<String, Object?> m) {
    final rf = _optMap(m, 'rapid_fire');
    return UnitSpec(
      kind: kind,
      name: _string(m, 'name'),
      description: _stringOr(m, 'description'),
      baseCost: _resources(_map(m, 'cost')),
      requires: _requires(m),
      defense: m['defense'] == true,
      attack: _num(m, 'attack'),
      shield: _num(m, 'shield'),
      cargo: _numOr(m, 'cargo'),
      maxCount: m['max'] == null ? null : _num(m, 'max').toInt(),
      rapidFire: rf == null
          ? const {}
          : {for (final e in rf.entries) UnitKind.fromKey(e.key): _num(rf, e.key).toInt()},
    );
  }

  static TechSpec _tech(TechKind kind, Map<String, Object?> m) {
    final bonus = _optMap(m, 'production_bonus');
    return TechSpec(
      kind: kind,
      name: _string(m, 'name'),
      description: _stringOr(m, 'description'),
      baseCost: _resources(_map(m, 'cost')),
      costFactor: _num(m, 'factor'),
      requires: _requires(m),
      productionBonus: bonus == null ? Resources.zero : _resources(bonus),
    );
  }

  static Map<Unlockable, int> _requires(Map<String, Object?> m) {
    final r = _optMap(m, 'requires');
    if (r == null) return const {};
    return {for (final e in r.entries) Unlockable.fromKey(e.key): _num(r, e.key).toInt()};
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

  static Map<String, Object?>? _optMap(Map<String, Object?> m, String key) =>
      m[key] == null ? null : _map(m, key);

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

  static String _stringOr(Map<String, Object?> m, String key) =>
      m[key] == null ? '' : _string(m, key);
}
