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
