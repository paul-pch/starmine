import 'engine.dart';
import 'game_data.dart';
import 'rules.dart';

/// Prérequis manquants pour le prochain niveau d'un officier (spec 12).
class OfficerMissing {
  const OfficerMissing({this.requires = const {}, this.counters = const {}});

  /// Élément → niveau requis.
  final Map<Unlockable, int> requires;

  /// Compteur → valeur requise.
  final Map<Counter, int> counters;

  bool get isEmpty => requires.isEmpty && counters.isEmpty;
}

/// Prérequis du niveau suivant de [kind], ou `null` s'il est au plafond.
OfficerLevelSpec? nextOfficerLevel(GameState s, OfficerKind kind, GameData data) {
  final spec = data.officers[kind];
  if (spec == null) return null;
  final level = s.officers[kind]!;
  return level >= spec.maxLevel ? null : spec.levels[level];
}

/// Prérequis non remplis du niveau suivant (vide s'il est disponible ou au plafond).
OfficerMissing officerMissing(GameState s, OfficerKind kind, GameData data) {
  final next = nextOfficerLevel(s, kind, data);
  if (next == null) return const OfficerMissing();
  return OfficerMissing(
    requires: unmet(s, next.requires),
    counters: {
      for (final e in next.counters.entries)
        if (s.counters[e.key]! < e.value) e.key: e.value,
    },
  );
}

/// Vrai si le niveau suivant de [kind] peut être débloqué maintenant.
bool officerAvailable(GameState s, OfficerKind kind, GameData data) =>
    nextOfficerLevel(s, kind, data) != null && officerMissing(s, kind, data).isEmpty;

/// Officiers dont un niveau attend le joueur (pastille).
List<OfficerKind> availableOfficers(GameState s, GameData data) => [
  for (final k in data.officers.keys)
    if (officerAvailable(s, k, data)) k,
];

/// Débloque ou promeut [kind] à [now] : commande explicite du joueur, gratuite. Le bonus
/// s'applique à partir de [now] (le passé est soldé à l'ancien niveau). `promoted` est faux
/// si les prérequis ne sont pas remplis ou si l'officier est au plafond.
({GameState state, bool promoted}) promoteOfficer(
  GameState state,
  OfficerKind kind,
  DateTime now,
  Rules rules,
) {
  final advanced = advance(state, now, rules).state;
  if (!officerAvailable(advanced, kind, rules.data)) return (state: advanced, promoted: false);
  return (
    state: advanced.copyWith(officers: {...advanced.officers, kind: advanced.officers[kind]! + 1}),
    promoted: true,
  );
}
