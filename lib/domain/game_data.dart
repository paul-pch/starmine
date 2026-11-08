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

/// Officiers (spec 12) : personnages gagnés en jouant, qui donnent un bonus permanent.
enum OfficerKind {
  geologist('geologist'),
  technocrat('technocrat'),
  architect('architect'),
  engineer('engineer'),
  commander('commander'),
  researchDirector('research_director'),
  shipyardMaster('shipyard_master');

  const OfficerKind(this.key);

  final String key;

  static OfficerKind fromKey(String key) => values.firstWhere(
    (k) => k.key == key,
    orElse: () => throw FormatException('Officier inconnu : $key'),
  );
}

/// Compteurs de progression tenus par `advance()`, prérequis possibles des officiers.
enum Counter {
  raidsRepelled('raids_repelled');

  const Counter(this.key);

  final String key;

  static Counter? tryKey(String key) => values.where((k) => k.key == key).firstOrNull;
}

/// Effet d'un officier, par niveau.
enum OfficerBonus {
  /// Production des mines (fraction ajoutée : 0.05 = +5 %).
  mineProduction('mine_production'),

  /// Durée de recherche réduite (0.05 = −5 %).
  researchTime('research_time'),

  /// Durée de construction des bâtiments réduite.
  buildTime('build_time'),

  /// Part des défenses détruites reconstruites, ajoutée aux 70 % de base.
  defenseRebuild('defense_rebuild'),

  /// Ordres en plus dans la file de construction, de recherche ou du chantier (spec 13).
  constructionQueue('construction_queue'),
  researchQueue('research_queue'),
  shipyardQueue('shipyard_queue');

  const OfficerBonus(this.key);

  final String key;

  static OfficerBonus fromKey(String key) => values.firstWhere(
    (k) => k.key == key,
    orElse: () => throw FormatException('Bonus d’officier inconnu : $key'),
  );
}

/// Prérequis d'un niveau d'officier : niveaux de bâtiments et technos, compteurs.
class OfficerLevelSpec {
  const OfficerLevelSpec({this.requires = const {}, this.counters = const {}});

  final Map<Unlockable, int> requires;
  final Map<Counter, int> counters;
}

class OfficerSpec {
  const OfficerSpec({
    required this.kind,
    required this.name,
    this.description = '',
    required this.bonus,
    required this.perLevel,
    required this.levels,
  });

  final OfficerKind kind;
  final String name;
  final String description;
  final OfficerBonus bonus;

  /// Valeur du bonus par niveau (fraction).
  final double perLevel;

  /// Prérequis de chaque niveau, du premier au dernier (le plafond).
  final List<OfficerLevelSpec> levels;

  int get maxLevel => levels.length;
}

/// Sens d'un événement ponctuel (spec 14).
enum StoryKind { bonus, malus, choice }

/// Effet d'un événement ponctuel.
enum StoryEffectType {
  /// Production des mines d'une ressource (toutes si absente) : `value` ajouté au bonus,
  /// pendant `hours`.
  production,

  /// Énergie produite multipliée par (1 + `value`) pendant `hours`.
  energy,

  /// Temps restant de l'ordre en cours (`target`) multiplié par (1 − `value`) ; une valeur
  /// négative retarde.
  shorten,

  /// Stock d'une ressource (toutes si absente) multiplié par (1 + `value`).
  stock,

  /// Gain immédiat de `hours` heures de production (à ×1) d'une ressource.
  gain,

  /// Le prochain raid arrive `hours` heures plus tôt.
  raid,
}

/// File visée par un effet `shorten`.
enum OrderTarget { construction, research }

class StoryEffectSpec {
  const StoryEffectSpec({
    required this.type,
    this.resource,
    this.target,
    this.value = 0,
    this.hours = 0,
  });

  final StoryEffectType type;
  final ResourceKind? resource;
  final OrderTarget? target;
  final double value;
  final double hours;
}

class StoryOptionSpec {
  const StoryOptionSpec({required this.label, this.effects = const []});

  final String label;
  final List<StoryEffectSpec> effects;
}

/// Un événement du catalogue (`story_events.catalog`).
class StoryEventSpec {
  const StoryEventSpec({
    required this.key,
    required this.name,
    this.description = '',
    required this.kind,
    this.effects = const [],
    this.options = const [],
    this.defaultOption = 0,
    this.requires = const {},
    this.officer,
    this.officerPerLevel = 0,
  });

  final String key;
  final String name;

  /// Texte d'histoire, affiché avec l'effet.
  final String description;
  final StoryKind kind;

  /// Effets d'un bonus ou d'un malus.
  final List<StoryEffectSpec> effects;

  /// Options d'un choix ; [defaultOption] s'applique sans réponse à l'échéance.
  final List<StoryOptionSpec> options;
  final int defaultOption;

  /// Niveaux requis pour que l'événement puisse être tiré.
  final Map<Unlockable, int> requires;

  /// Officier lié : prolonge un bonus (durée × (1 + n × niveau)) ou atténue un malus
  /// (valeur × (1 − n × niveau)).
  final OfficerKind? officer;
  final double officerPerLevel;
}

/// Section `story_events` du YAML.
class StoryConfig {
  const StoryConfig({
    this.intervalHoursMin = 60,
    this.intervalHoursMax = 108,
    this.answerHours = 6,
    this.catalog = const {},
  });

  /// Délai entre deux événements, en heures à ×1.
  final double intervalHoursMin;
  final double intervalHoursMax;

  /// Délai pour répondre à un choix, en heures à ×1.
  final double answerHours;
  final Map<String, StoryEventSpec> catalog;
}

/// Partie commune aux bâtiments et technologies.
abstract class ItemSpec {
  const ItemSpec({
    required this.name,
    required this.description,
    required this.baseCost,
    required this.costFactor,
    required this.requires,
    this.category = '',
  });

  final String name;
  final String description;
  final Resources baseCost;
  final double costFactor;

  /// Niveaux minimums requis pour construire ou rechercher le premier niveau.
  final Map<Unlockable, int> requires;

  /// Groupe d'affichage (clé de `categories` dans le YAML), vide pour les unités pirates.
  final String category;
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
    super.category,
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
    super.category,
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
    super.category,
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

/// Coup de pouce de départ (section `start_boost`) : production × (1 + extra × max(0,
/// 1 − points / fadePoints)).
class StartBoost {
  const StartBoost({this.extra = 0, this.fadePoints = 1});

  final double extra;
  final double fadePoints;

  /// Multiplicateur de production pour [points] d'économie et de recherche.
  double factor(double points) => 1 + extra * (1 - points / fadePoints).clamp(0.0, 1.0);
}

/// Paramètres des raids pirates (section `pirates` du YAML).
class PirateConfig {
  const PirateConfig({
    required this.intervalHoursMin,
    required this.intervalHoursMax,
    required this.warningMinutes,
    required this.minBudget,
    required this.strengthMin,
    required this.strengthMax,
    required this.cargoShare,
    required this.lootShare,
    required this.warships,
    required this.cargoShips,
    this.techOffset = 0,
  });

  /// Délai entre deux arrivées, en heures de jeu à ×1.
  final double intervalHoursMin;
  final double intervalHoursMax;

  /// Préavis entre la détection et l'arrivée, en minutes à ×1.
  final double warningMinutes;

  /// Budget de flotte = max(minBudget, points × 1000 × force).
  final double minBudget;
  final double strengthMin;
  final double strengthMax;

  /// Part du budget consacrée aux transporteurs.
  final double cargoShare;

  /// Part maximale de chaque stock emportée.
  final double lootShare;

  /// Vaisseaux disponibles selon les points du joueur (seuil minimal).
  final Map<UnitKind, double> warships;
  final Map<UnitKind, double> cargoShips;

  /// Technos de combat des pirates = celles du joueur (au relevé) moins ce décalage.
  final int techOffset;
}

/// Toutes les données de jeu, construites depuis une Map (le chargement YAML est dans `data/`).
class GameData {
  GameData({
    required this.formulas,
    required this.start,
    required Map<BuildingKind, BuildingSpec> buildings,
    required Map<TechKind, TechSpec> research,
    required Map<UnitKind, UnitSpec> units,
    this.categories = const {},
    required this.pirates,
    Map<OfficerKind, OfficerSpec> officers = const {},
    this.counterNames = const {},
    this.story = const StoryConfig(),
    this.startBoost = const StartBoost(),
  }) : officers = Map.unmodifiable(officers),
       units = Map.unmodifiable(units),
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

  /// Groupes d'affichage par écran (`buildings`, `research`, `defense`) : clé → libellé,
  /// dans l'ordre du YAML.
  final Map<String, Map<String, String>> categories;

  final PirateConfig pirates;

  /// Officiers, dans l'ordre du YAML.
  final Map<OfficerKind, OfficerSpec> officers;

  /// Libellé de chaque compteur (prérequis d'officiers).
  final Map<Counter, String> counterNames;

  /// Événements ponctuels (spec 14).
  final StoryConfig story;

  /// Coup de pouce de production en début de partie (spec 02).
  final StartBoost startBoost;

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
    final categories = _optMap(map, 'categories') ?? const {};
    final pirates = _map(map, 'pirates');
    final officers = _optMap(map, 'officers') ?? const {};
    final counters = _optMap(map, 'counters') ?? const {};
    final story = _optMap(map, 'story_events');
    final boost = _optMap(map, 'start_boost');
    final interval = _map(pirates, 'interval_hours');
    final strength = _map(pirates, 'strength');
    Map<UnitKind, double> ships(String key) => {
      for (final e in _map(pirates, key).entries)
        UnitKind.fromKey(e.key): _num(_map(pirates, key), e.key),
    };

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
      pirates: PirateConfig(
        intervalHoursMin: _num(interval, 'min'),
        intervalHoursMax: _num(interval, 'max'),
        warningMinutes: _num(pirates, 'warning_minutes'),
        minBudget: _num(pirates, 'min_budget'),
        strengthMin: _num(strength, 'min'),
        strengthMax: _num(strength, 'max'),
        cargoShare: _num(pirates, 'cargo_share'),
        lootShare: _num(pirates, 'loot_share'),
        warships: ships('warships'),
        cargoShips: ships('cargo_ships'),
        techOffset: _num(pirates, 'tech_offset').toInt(),
      ),
      categories: {
        for (final screen in categories.keys)
          screen: {
            for (final e in _map(categories, screen).entries)
              e.key: _string(_map(categories, screen), e.key),
          },
      },
      units: {
        for (final e in units.entries)
          UnitKind.fromKey(e.key): _unit(UnitKind.fromKey(e.key), _asMap(e.value, e.key)),
      },
      officers: {
        for (final e in officers.entries)
          OfficerKind.fromKey(e.key): _officer(OfficerKind.fromKey(e.key), _asMap(e.value, e.key)),
      },
      counterNames: {for (final e in counters.entries) _counter(e.key): _string(counters, e.key)},
      story: story == null ? const StoryConfig() : _story(story),
      startBoost: boost == null
          ? const StartBoost()
          : StartBoost(extra: _num(boost, 'extra'), fadePoints: _num(boost, 'fade_points')),
    );
  }

  static StoryConfig _story(Map<String, Object?> m) {
    final interval = _map(m, 'interval_hours');
    final catalog = _map(m, 'catalog');
    return StoryConfig(
      intervalHoursMin: _num(interval, 'min'),
      intervalHoursMax: _num(interval, 'max'),
      answerHours: _num(m, 'answer_hours'),
      catalog: {for (final e in catalog.entries) e.key: _storyEvent(e.key, _asMap(e.value, e.key))},
    );
  }

  static StoryEventSpec _storyEvent(String key, Map<String, Object?> m) {
    final kind = StoryKind.values.firstWhere(
      (k) => k.name == _string(m, 'kind'),
      orElse: () => throw FormatException('« $key.kind » inconnu'),
    );
    final officer = _optMap(m, 'officer');
    final options = m['options'] == null ? const <Object?>[] : _listOf(m, 'options');
    final spec = StoryEventSpec(
      key: key,
      name: _string(m, 'name'),
      description: _stringOr(m, 'description'),
      kind: kind,
      effects: m['effects'] == null ? const [] : _effects(_listOf(m, 'effects'), key),
      options: [for (final raw in options) _option(_asMap(raw, '$key.options[]'), key)],
      defaultOption: m['default'] == null ? 0 : _num(m, 'default').toInt(),
      requires: _requires(m),
      officer: officer == null ? null : OfficerKind.fromKey(_string(officer, 'kind')),
      officerPerLevel: officer == null ? 0 : _num(officer, 'per_level'),
    );
    if (kind == StoryKind.choice &&
        (spec.options.length < 2 || spec.defaultOption >= spec.options.length)) {
      throw FormatException('« $key » : un choix a au moins deux options et un défaut valide');
    }
    return spec;
  }

  static StoryOptionSpec _option(Map<String, Object?> m, String key) => StoryOptionSpec(
    label: _string(m, 'label'),
    effects: m['effects'] == null ? const [] : _effects(_listOf(m, 'effects'), key),
  );

  static List<StoryEffectSpec> _effects(List<Object?> raw, String key) => [
    for (final r in raw) _effect(_asMap(r, '$key.effects[]'), key),
  ];

  static StoryEffectSpec _effect(Map<String, Object?> m, String key) => StoryEffectSpec(
    type: StoryEffectType.values.firstWhere(
      (t) => t.name == _string(m, 'type'),
      orElse: () => throw FormatException('« $key » : effet inconnu ${m['type']}'),
    ),
    resource: m['resource'] == null ? null : _resourceKind(_string(m, 'resource')),
    target: m['target'] == null
        ? null
        : OrderTarget.values.firstWhere(
            (t) => t.name == _string(m, 'target'),
            orElse: () => throw FormatException('« $key » : cible inconnue ${m['target']}'),
          ),
    value: _numOr(m, 'value'),
    hours: _numOr(m, 'hours'),
  );

  static List<Object?> _listOf(Map<String, Object?> m, String key) {
    final v = m[key];
    if (v is List) return v.cast<Object?>();
    throw FormatException('« $key » doit être une liste');
  }

  static Counter _counter(String key) =>
      Counter.tryKey(key) ?? (throw FormatException('Compteur inconnu : $key'));

  static OfficerSpec _officer(OfficerKind kind, Map<String, Object?> m) {
    final bonus = _map(m, 'bonus');
    final levels = m['levels'];
    if (levels is! List || levels.isEmpty) {
      throw FormatException('« ${kind.key}.levels » doit être une liste non vide');
    }
    return OfficerSpec(
      kind: kind,
      name: _string(m, 'name'),
      description: _stringOr(m, 'description'),
      bonus: OfficerBonus.fromKey(_string(bonus, 'type')),
      perLevel: _num(bonus, 'per_level'),
      levels: [for (final raw in levels) _officerLevel(_asMap(raw, '${kind.key}.levels[]'))],
    );
  }

  /// Une clé de `requires` est un compteur, un bâtiment ou une techno.
  static OfficerLevelSpec _officerLevel(Map<String, Object?> m) {
    final r = _map(m, 'requires');
    final requires = <Unlockable, int>{};
    final counters = <Counter, int>{};
    for (final key in r.keys) {
      final n = _num(r, key).toInt();
      final counter = Counter.tryKey(key);
      if (counter != null) {
        counters[counter] = n;
      } else {
        requires[Unlockable.fromKey(key)] = n;
      }
    }
    return OfficerLevelSpec(requires: requires, counters: counters);
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
      category: _stringOr(m, 'category'),
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
      category: _stringOr(m, 'category'),
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
      category: _stringOr(m, 'category'),
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
