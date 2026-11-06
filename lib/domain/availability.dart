import 'engine.dart';
import 'game_data.dart';
import 'resources.dart';
import 'rules.dart';

/// Filtre « Réalisables » (spec 10) : prérequis remplis et ressources disponibles. La file
/// n'est pas prise en compte, sinon tout disparaît pendant une construction.
bool realizable(GameState s, Unlockable item, Rules rules) =>
    missingRequirements(s, item, rules).isEmpty &&
    s.planet.resources.covers(rules.cost(item, s.levelOf(item) + 1));

/// Défense réalisable : au moins une unité commandable (prérequis, limite, ressources).
bool realizableUnit(GameState s, UnitKind unit, Rules rules) {
  final spec = rules.data.unit(unit);
  if (!spec.defense || unmet(s, spec.requires).isNotEmpty || _maxed(s, spec)) return false;
  return s.planet.resources.covers(spec.baseCost);
}

/// Attente avant que [item] soit réalisable au rythme actuel, ou `null` s'il est verrouillé
/// (prérequis) ou hors d'atteinte (production nulle, coût au-delà du stockage).
Duration? waitFor(GameState s, Unlockable item, Rules rules) {
  if (missingRequirements(s, item, rules).isNotEmpty) return null;
  return timeToAfford(s, rules.cost(item, s.levelOf(item) + 1), rules);
}

/// Comme [waitFor], pour une unité de défense.
Duration? waitForUnit(GameState s, UnitKind unit, Rules rules) {
  final spec = rules.data.unit(unit);
  if (!spec.defense || unmet(s, spec.requires).isNotEmpty || _maxed(s, spec)) return null;
  return timeToAfford(s, spec.baseCost, rules);
}

/// Temps de production avant de couvrir [cost] (zéro si c'est déjà le cas), ou `null` si
/// une ressource manquante n'est pas produite ou dépasse la capacité de stockage.
Duration? timeToAfford(GameState s, Resources cost, Rules rules) {
  final planet = s.planet;
  final rate = rules.hourlyProduction(planet, s.research, s.modifiers(rules.data));
  final cap = rules.capacity(planet.levels);
  var hours = 0.0;
  for (final k in ResourceKind.values) {
    final missing = cost[k] - planet.resources[k];
    if (missing <= 0) continue;
    if (cost[k] > cap[k] || rate[k] <= 0) return null;
    final h = missing / rate[k];
    if (h > hours) hours = h;
  }
  return Duration(seconds: (hours * 3600).ceil());
}

bool _maxed(GameState s, UnitSpec spec) {
  final max = spec.maxCount;
  return max != null && s.planet.count(spec.kind) >= max;
}
