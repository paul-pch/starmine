import 'game_data.dart';
import 'resources.dart';

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
