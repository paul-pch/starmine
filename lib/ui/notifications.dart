import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/engine.dart';
import '../domain/events.dart';
import '../domain/game_data.dart';
import '../domain/story.dart';

/// Id de la notification d'arrivée d'un raid (celle de détection porte l'id de l'événement).
int raidArrivalNotificationId(int eventId) => eventId + 1000000;

/// Id de la notification d'annulation d'une file (id réservé de son premier ordre).
int queueCancelledNotificationId(QueuedOrder first) => first.id + 2000000;

/// Titre et texte de l'annulation d'une file (notification, message dans l'app).
(String, String) queueCancelledText(QueueCancelled c, GameData data) {
  final title = switch (c.slot) {
    Slot.construction => 'File de construction annulée',
    Slot.research => 'File de recherche annulée',
    Slot.shipyard => 'File du chantier annulée',
  };
  final name = switch (c.first) {
    QueuedLevel(:final item) => data.spec(item).name,
    QueuedBatch(:final unit, :final count) => '$count × ${data.unit(unit).name}',
  };
  final why = switch (c.reason) {
    NotEnoughResources() => 'ressources insuffisantes',
    RequirementsNotMet() => 'prérequis manquants',
    LabBusy() => 'laboratoire occupé',
    ShipyardBusy() => 'chantier occupé',
    MaxReached() => 'limite atteinte',
    QueueBusy() || QueueFull() || NotBuildable() => 'impossible',
  };
  final n = c.dropped.length;
  return (title, '$name : $why. ${n > 1 ? '$n ordres retirés.' : '1 ordre retiré.'}');
}

/// Id des notifications d'événements ponctuels prévus ([index] : rang dans la prévision).
int storyNotificationId(int index) => 3000000 + index;

/// Titre et texte d'un événement ponctuel (notification, message dans l'app).
(String, String) storyText(StoryOutcome o, GameData data) {
  final spec = data.story.catalog[o.key];
  final name = spec?.name ?? o.key;
  String label(int? i) => spec == null || i == null ? '' : spec.options[i].label;
  return switch (o.kind) {
    StoryOutcomeKind.happened => (name, spec?.description ?? ''),
    StoryOutcomeKind.awaiting => ('Décision attendue : $name', spec?.description ?? ''),
    StoryOutcomeKind.answered => (name, 'Choix : ${label(o.option)}'),
    StoryOutcomeKind.defaulted => (name, 'Sans réponse : « ${label(o.option)} » appliqué'),
  };
}

/// Rappel d'un choix en attente, avant l'application de l'option par défaut.
const choiceReminder = Duration(hours: 1);

/// Moment de la (première) notification : fin de l'ordre, dernière unité d'un lot,
/// détection ou arrivée d'un raid.
DateTime notifyAt(GameEvent event) => switch (event) {
  ShipyardBatch() => event.finishAt,
  StoryEvent(choiceKey: _?) => event.dueAt.subtract(choiceReminder),
  _ => event.dueAt,
};

/// Notifications locales des événements de jeu. L'id de notification est l'id de
/// l'événement (plus [raidArrivalNotificationId] pour l'arrivée d'un raid).
abstract interface class BuildNotifier {
  Future<void> schedule(GameEvent event, GameData data);

  /// Événement ponctuel prévu (spec 14), [index] : rang dans la prévision.
  Future<void> scheduleStory(StoryOutcome outcome, int index, GameData data);

  /// Annulation prévue d'une file d'attente (spec 13).
  Future<void> scheduleCancelled(QueueCancelled cancelled, GameData data);
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

  static const _raids = NotificationDetails(
    android: AndroidNotificationDetails(
      'raids',
      'Raids pirates',
      channelDescription: 'Détection et résultat des raids pirates',
      importance: Importance.max,
      priority: Priority.max,
    ),
  );

  static const _story = NotificationDetails(
    android: AndroidNotificationDetails(
      'evenements',
      'Événements',
      channelDescription: 'Événements ponctuels et décisions à prendre',
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
    String clock(DateTime t) {
      final l = t.toLocal();
      return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }

    const raidReport = 'Les pirates ont attaqué : consulte le rapport.';
    final notes = <(int, DateTime, String, String, NotificationDetails)>[
      ...switch (event) {
        BuildingDone() => [
          (
            event.id,
            event.dueAt,
            'Construction terminée',
            '${data.spec(event.item).name} niveau ${event.targetLevel}',
            _buildings,
          ),
        ],
        ResearchDone() => [
          (
            event.id,
            event.dueAt,
            'Recherche terminée',
            '${data.spec(event.item).name} niveau ${event.targetLevel}',
            _research,
          ),
        ],
        ShipyardBatch() => [
          (
            event.id,
            event.finishAt,
            'Chantier terminé',
            '${event.ordered} × ${data.unit(event.unit).name}',
            _buildings,
          ),
        ],
        RaidDetected() => [
          (
            event.id,
            event.dueAt,
            'Flotte pirate détectée',
            'Arrivée prévue à ${clock(event.arrivalAt)}. Prépare tes défenses.',
            _raids,
          ),
          (raidArrivalNotificationId(event.id), event.arrivalAt, 'Raid pirate', raidReport, _raids),
        ],
        RaidArrival() => [
          (raidArrivalNotificationId(event.id), event.dueAt, 'Raid pirate', raidReport, _raids),
        ],
        // Choix en attente : rappel avant l'option par défaut. Les tirages sont prévus par
        // simulation (scheduleStory).
        StoryEvent(:final choiceKey?) => [
          (
            event.id,
            notifyAt(event),
            'Décision attendue : ${data.story.catalog[choiceKey]?.name ?? choiceKey}',
            'Sans réponse, l’option par défaut s’appliquera.',
            _story,
          ),
        ],
        StoryEvent() => [],
      },
    ];
    final exact = await canScheduleExact();
    for (final (id, at, title, body, details) in notes) {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        notificationDetails: details,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> scheduleStory(StoryOutcome outcome, int index, GameData data) async {
    final (title, body) = storyText(outcome, data);
    final exact = await canScheduleExact();
    await _plugin.zonedSchedule(
      id: storyNotificationId(index),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(outcome.at, tz.UTC),
      notificationDetails: _story,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> scheduleCancelled(QueueCancelled cancelled, GameData data) async {
    final (title, body) = queueCancelledText(cancelled, data);
    final exact = await canScheduleExact();
    await _plugin.zonedSchedule(
      id: queueCancelledNotificationId(cancelled.first),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(cancelled.at, tz.UTC),
      notificationDetails: cancelled.slot == Slot.research ? _research : _buildings,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int eventId) async {
    await _plugin.cancel(id: eventId);
    await _plugin.cancel(id: raidArrivalNotificationId(eventId));
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
