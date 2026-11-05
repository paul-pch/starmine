import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/events.dart';
import '../domain/game_data.dart';

/// Notifications de fin de construction ou de recherche.
/// L'id de notification est l'id de l'événement.
abstract interface class BuildNotifier {
  Future<void> schedule(OrderDone event, GameData data);
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
  Future<void> schedule(OrderDone event, GameData data) async {
    final exact = await canScheduleExact();
    final (title, details) = switch (event) {
      BuildingDone() => ('Construction terminée', _buildings),
      ResearchDone() => ('Recherche terminée', _research),
    };
    await _plugin.zonedSchedule(
      id: event.id,
      title: title,
      body: '${data.spec(event.item).name} niveau ${event.targetLevel}',
      scheduledDate: tz.TZDateTime.from(event.dueAt, tz.UTC),
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
