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

/// Fin de construction d'un bâtiment. [cost] est conservé pour un remboursement exact
/// même si la config de jeu change entre-temps.
class BuildingDone extends GameEvent {
  const BuildingDone({
    required super.id,
    required super.planetId,
    required super.dueAt,
    required this.startedAt,
    required this.building,
    required this.targetLevel,
    required this.cost,
  });

  final DateTime startedAt;
  final BuildingKind building;
  final int targetLevel;
  final Resources cost;
}
