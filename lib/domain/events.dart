import 'game_data.dart';
import 'resources.dart';
import 'rules.dart';

/// Événement futur. L'ordre d'application est (dueAt, id).
sealed class GameEvent {
  const GameEvent({required this.id, required this.planetId, required this.dueAt});

  final int id;
  final int planetId;
  final DateTime dueAt;

  static int compare(GameEvent a, GameEvent b) {
    final byDate = a.dueAt.compareTo(b.dueAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }
}

/// Fin d'un ordre payé d'avance (construction, recherche). [cost] est conservé pour un
/// remboursement exact même si la config de jeu change entre-temps.
sealed class OrderDone extends GameEvent {
  const OrderDone({
    required super.id,
    required super.planetId,
    required super.dueAt,
    required this.startedAt,
    required this.targetLevel,
    required this.cost,
  });

  final DateTime startedAt;
  final int targetLevel;
  final Resources cost;

  Unlockable get item;
}

class BuildingDone extends OrderDone {
  const BuildingDone({
    required super.id,
    required super.planetId,
    required super.dueAt,
    required super.startedAt,
    required this.building,
    required super.targetLevel,
    required super.cost,
  });

  final BuildingKind building;

  @override
  BuildingKind get item => building;
}

class ResearchDone extends OrderDone {
  const ResearchDone({
    required super.id,
    required super.planetId,
    required super.dueAt,
    required super.startedAt,
    required this.tech,
    required super.targetLevel,
    required super.cost,
  });

  final TechKind tech;

  @override
  TechKind get item => tech;
}

/// Lot du chantier, livré unité par unité. [dueAt] est la livraison de la prochaine
/// unité ; une fois appliqué, l'événement est remplacé par le même lot (même id) avec
/// une unité de moins, jusqu'à épuisement. Payé intégralement à la commande.
class ShipyardBatch extends GameEvent {
  const ShipyardBatch({
    required super.id,
    required super.planetId,
    required super.dueAt,
    required this.startedAt,
    required this.unit,
    required this.ordered,
    required this.remaining,
    required this.unitDuration,
    required this.unitCost,
  });

  final DateTime startedAt;
  final UnitKind unit;

  /// Taille du lot commandé, et unités encore à livrer (prochaine comprise).
  final int ordered;
  final int remaining;
  final Duration unitDuration;
  final Resources unitCost;

  /// Livraison de la dernière unité.
  DateTime get finishAt => dueAt.add(unitDuration * (remaining - 1));

  /// Le lot après livraison d'une unité, ou `null` s'il est terminé.
  ShipyardBatch? get next => remaining <= 1
      ? null
      : ShipyardBatch(
          id: id,
          planetId: planetId,
          dueAt: dueAt.add(unitDuration),
          startedAt: startedAt,
          unit: unit,
          ordered: ordered,
          remaining: remaining - 1,
          unitDuration: unitDuration,
          unitCost: unitCost,
        );
}

/// Flotte pirate repérée : à [dueAt], sa composition est fixée selon les points du joueur
/// et l'événement devient un [RaidArrival] (même id) dû à [arrivalAt].
class RaidDetected extends GameEvent {
  const RaidDetected({
    required super.id,
    required super.planetId,
    required super.dueAt,
    required this.arrivalAt,
    required this.seed,
    this.base,
  });

  final DateTime arrivalAt;

  /// Graine de l'aléatoire du raid (composition, combat, raid suivant).
  final int seed;

  /// Relevé du joueur à la planification (raid précédent) : les pirates ont du retard.
  /// Absent des sauvegardes antérieures : relevé pris à la détection.
  final RaidBase? base;
}

/// Ce que les pirates savent du joueur : points d'économie et de recherche, technos.
class RaidBase {
  const RaidBase({required this.points, required this.tech});

  final double points;
  final TechLevels tech;
}

/// Flotte pirate en approche, composition connue. À [dueAt] : combat, pillage, rapport,
/// puis le raid suivant est planifié (même id).
class RaidArrival extends GameEvent {
  const RaidArrival({
    required super.id,
    required super.planetId,
    required super.dueAt,
    required this.detectedAt,
    required this.fleet,
    required this.seed,
    this.tech = const {},
  });

  final DateTime detectedAt;
  final Map<UnitKind, int> fleet;
  final int seed;

  /// Technos de combat des pirates (vides dans les sauvegardes antérieures).
  final TechLevels tech;
}

/// Événement ponctuel (spec 14), chaîne toujours planifiée sous le même id. À [dueAt] :
/// tirage dans le catalogue avec [seed] ; un choix attend la réponse du joueur jusqu'à une
/// nouvelle échéance ([choiceKey] renseigné), où l'option par défaut s'applique.
class StoryEvent extends GameEvent {
  /// [dueAt] est la prochaine échéance : ajout au stock ([accrueAt], par défaut [dueAt]) ou
  /// option par défaut d'un choix ([deadline], par défaut [dueAt]). Voir [StoryEvent.chain].
  const StoryEvent({
    required super.id,
    required super.planetId,
    required super.dueAt,
    required this.seed,
    this.choiceKey,
    this.lastKey,
    this.stock = 0,
    DateTime? accrueAt,
    DateTime? deadline,
    this.serveAt,
  }) : _accrueAt = accrueAt,
       _deadline = deadline;

  /// Échéance calculée : la plus proche de [accrueAt] et de [deadline] (choix en attente).
  factory StoryEvent.chain({
    required int id,
    required int planetId,
    required int seed,
    required DateTime accrueAt,
    String? choiceKey,
    DateTime? deadline,
    String? lastKey,
    int stock = 0,
    DateTime? serveAt,
  }) {
    final due = choiceKey != null && deadline != null && deadline.isBefore(accrueAt)
        ? deadline
        : accrueAt;
    return StoryEvent(
      id: id,
      planetId: planetId,
      dueAt: due,
      seed: seed,
      choiceKey: choiceKey,
      lastKey: lastKey,
      stock: stock,
      accrueAt: accrueAt,
      deadline: choiceKey == null ? null : deadline,
      serveAt: serveAt,
    );
  }

  final int seed;

  /// Choix en attente de réponse (clé du catalogue), sinon `null`.
  final String? choiceKey;

  /// Événement précédent : il n'est pas retiré deux fois d'affilée.
  final String? lastKey;

  /// Événements accumulés, à servir app ouverte (spec 14).
  final int stock;

  final DateTime? _accrueAt;
  final DateTime? _deadline;

  /// Prochain ajout au stock.
  DateTime get accrueAt => _accrueAt ?? dueAt;

  /// Échéance du choix en attente (option par défaut).
  DateTime? get deadline => choiceKey == null ? null : (_deadline ?? dueAt);

  /// Pas de service avant cet instant (`null` : pas d'attente).
  final DateTime? serveAt;
}

/// Recycleurs partis collecter le champ de débris (spec 15) : à [dueAt], ils rentrent avec
/// au plus leur soute de débris (métal et cristal, au prorata).
class RecycleMission extends GameEvent {
  const RecycleMission({
    required super.id,
    required super.planetId,
    required super.dueAt,
    required this.startedAt,
    required this.recyclers,
  });

  final DateTime startedAt;
  final int recyclers;
}

/// Type d'une mission de flotte (V3b).
enum MissionKind { attack, spy, recycle, shelter }

/// Flotte en vol (spec 15). Aller : à [dueAt], arrivée sur la base [target] (combat,
/// espionnage, collecte), puis le même id revient (`returning`). Une mise à l'abri n'a que
/// le retour.
class FleetMission extends GameEvent {
  const FleetMission({
    required super.id,
    required super.planetId,
    required super.dueAt,
    required this.kind,
    this.target,
    required this.ships,
    this.cargo = Resources.zero,
    this.returning = false,
    required this.departedAt,
    this.speedPercent = 100,
    required this.seed,
  });

  final MissionKind kind;

  /// Index de la base pirate visée (aucune pour une mise à l'abri).
  final int? target;
  final Map<UnitKind, int> ships;

  /// Chargement rapporté (pillage, débris).
  final Resources cargo;
  final bool returning;
  final DateTime departedAt;
  final int speedPercent;

  /// Graine du combat à l'arrivée.
  final int seed;

  FleetMission copyWith({
    DateTime? dueAt,
    Map<UnitKind, int>? ships,
    Resources? cargo,
    bool? returning,
  }) => FleetMission(
    id: id,
    planetId: planetId,
    dueAt: dueAt ?? this.dueAt,
    kind: kind,
    target: target,
    ships: ships ?? this.ships,
    cargo: cargo ?? this.cargo,
    returning: returning ?? this.returning,
    departedAt: departedAt,
    speedPercent: speedPercent,
    seed: seed,
  );
}
