import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/events.dart';
import '../domain/game_data.dart';

/// Notifications de fin de construction ou de recherche.
/// L'id de notification est l'id de l'événement.
/// Moment de la notification : fin de l'ordre, ou dernière unité d'un lot.
DateTime notifyAt(GameEvent event) => switch (event) {
  ShipyardBatch() => event.finishAt,
  _ => event.dueAt,
};

abstract interface class BuildNotifier {
  Future<void> schedule(GameEvent event, GameData data);
  Future<void> cancel(int eventId);
  Future<void> cancelAll();

  /// Vrai si les alarmes exactes sont autorisées (sinon décalage de quelques minutes).
  Future<bool> canScheduleExact();

  /// Ouvre le réglage système des alarmes exactes.
  Future<void> requestExact();
}

/// Implémentation Android (flutter_local_notifications). Les notifications programmées
/// sont conservées par le plugin et reprogrammées par lui après un redémarrage.
class LocalBuildNotifier implements BuildNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _buildings = NotificationDetails(
    android: AndroidNotificationDetails(
      'constructions',
      'Constructions',
      channelDescription: 'Fin des constructions',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static const _research = NotificationDetails(
    android: AndroidNotificationDetails(
      'recherches',
      'Recherches',
      channelDescription: 'Fin des recherches',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_star'),
      ),
    );
    await _android?.requestNotificationsPermission();
  }

  @override
  Future<bool> canScheduleExact() async => await _android?.canScheduleExactNotifications() ?? false;

  @override
  Future<void> requestExact() async => _android?.requestExactAlarmsPermission();

  @override
  Future<void> schedule(GameEvent event, GameData data) async {
    final exact = await canScheduleExact();
    final (title, body, details) = switch (event) {
      BuildingDone() => (
        'Construction terminée',
        '${data.spec(event.item).name} niveau ${event.targetLevel}',
        _buildings,
      ),
      ResearchDone() => (
        'Recherche terminée',
        '${data.spec(event.item).name} niveau ${event.targetLevel}',
        _research,
      ),
      ShipyardBatch() => (
        'Chantier terminé',
        '${event.ordered} × ${data.unit(event.unit).name}',
        _buildings,
      ),
    };
    await _plugin.zonedSchedule(
      id: event.id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(notifyAt(event), tz.UTC),
      notificationDetails: details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int eventId) => _plugin.cancel(id: eventId);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
