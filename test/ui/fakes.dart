import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/ui/notifications.dart';

/// Notifications en mémoire : id d'événement → échéance.
class FakeNotifier implements BuildNotifier {
  final scheduled = <int, DateTime>{};
  var cancelAllCount = 0;

  @override
  Future<void> schedule(GameEvent event, GameData data) async =>
      scheduled[event.id] = notifyAt(event);

  @override
  Future<void> scheduleCancelled(QueueCancelled cancelled, GameData data) async =>
      scheduled[queueCancelledNotificationId(cancelled.first)] = cancelled.at;

  @override
  Future<void> cancel(int eventId) async => scheduled.remove(eventId);

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled.clear();
  }

  @override
  Future<bool> canScheduleExact() async => true;

  @override
  Future<void> requestExact() async {}
}

/// Horloge pilotable.
class FakeClock {
  FakeClock(this.current);

  DateTime current;

  DateTime call() => current;

  void advance(Duration d) => current = current.add(d);
}
