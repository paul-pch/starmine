import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/game_repository.dart';
import '../data/save_codec.dart';
import '../domain/engine.dart';
import '../domain/events.dart';
import '../domain/fleet.dart' as fleet;
import '../domain/game_data.dart';
import '../domain/officers.dart' as officers;
import '../domain/planet.dart';
import '../domain/resources.dart';
import '../domain/raid.dart' as raid;
import '../domain/raid.dart' show RaidReport;
import '../domain/rules.dart';
import '../domain/story.dart' as story;
import '../domain/story.dart' show StoryOutcome;
import 'notifications.dart';
import 'visuals.dart';

/// Horloge UTC tronquée à la milliseconde (précision de la base).
DateTime systemClock() =>
    DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch, isUtc: true);

/// Orchestration : avance → commande → sauvegarde → notifications.
/// Les opérations sont sérialisées pour qu'aucune écriture ne s'entrelace.
class GameController extends ChangeNotifier {
  GameController({
    required GameRepository repository,
    required this.data,
    required BuildNotifier notifier,
    DateTime Function() clock = systemClock,
    math.Random? random,
  }) : _repo = repository,
       _notifier = notifier,
       _clock = clock,
       _random = random ?? math.Random();

  final GameData data;
  final GameRepository _repo;
  final BuildNotifier _notifier;

  BuildNotifier get notifier => _notifier;
  final DateTime Function() _clock;
  final math.Random _random;

  late SaveGame _save;
  late Rules _rules;
  Future<void> _lock = Future.value();

  /// Les notifications ne sont programmées que lorsque l'app n'est pas visible.
  var _visible = true;

  GameState get state => _save.state;
  Rules get rules => _rules;
  double get speed => _save.speed;
  DateTime now() => _clock();

  /// État affiché à [at] : stocks produits jusque-là, sans rien écrire ni appliquer
  /// d'événement (le rattrapage réel passe par [refresh]).
  GameState interpolated(DateTime at) {
    final p = state.planet;
    return state.copyWith(
      planet: p.copyWith(
        resources: _rules.produce(
          p,
          state.research,
          at.difference(p.lastUpdate),
          state.modifiers(data),
        ),
      ),
    );
  }

  Future<void> init() => _serialized(() async {
    final loaded = await _repo.load();
    if (loaded == null) {
      await _replace(_newGame(speed: 1));
    } else {
      _set(loaded);
    }
    await _advanceAndSave();
    await _ensureRaid();
    await _ensureStory();
    await _ensureBases();
    _reports = await _repo.loadReports();
    _storyLog = await _repo.loadStoryLog();
    _ambiance = Ambiance.fromName(await _repo.ambiance());
    for (final screen in filterScreens) {
      if (await _repo.realizableOnly(screen)) _realizableOnly.add(screen);
    }
  });

  /// Onglets qui ont le filtre « Réalisables ».
  static const filterScreens = ['buildings', 'research', 'defense'];

  final _realizableOnly = <String>{};

  /// Filtre « Réalisables » actif sur l'onglet [screen] (préférence d'affichage).
  bool realizableOnly(String screen) => _realizableOnly.contains(screen);

  Future<void> setRealizableOnly(String screen, bool on) => _serialized(() async {
    await _repo.setRealizableOnly(screen, on);
    if (on) {
      _realizableOnly.add(screen);
    } else {
      _realizableOnly.remove(screen);
    }
    notifyListeners();
  });

  /// Ambiance d'affichage : préférence, pas un état de jeu.
  Ambiance get ambiance => _ambiance;
  var _ambiance = Ambiance.balanced;

  Future<void> setAmbiance(Ambiance value) => _serialized(() async {
    await _repo.setAmbiance(value.name);
    _ambiance = value;
    notifyListeners();
  });

  /// Dernière file annulée (message dans l'app) et nombre d'annulations depuis le lancement.
  QueueCancelled? get lastQueueCancelled => _lastQueueCancelled;
  QueueCancelled? _lastQueueCancelled;
  int get queueCancelledCount => _queueCancelledCount;
  var _queueCancelledCount = 0;

  /// Rapports de raid, les plus récents d'abord.
  List<StoredReport> get reports => _reports;
  var _reports = <StoredReport>[];

  int get unseenReports => _reports.where((r) => !r.seen).length;

  /// Rapport ouvert depuis le message de fin de raid : sa pastille disparaît.
  Future<void> markReportSeen(int id) => _serialized(() async {
    await _repo.markReportSeen(id);
    _reports = await _repo.loadReports();
    notifyListeners();
  });

  Future<void> markReportsSeen() => _serialized(() async {
    if (unseenReports == 0) return;
    await _repo.markReportsSeen();
    _reports = await _repo.loadReports();
    notifyListeners();
  });

  /// Flotte pirate détectée et en route, s'il y en a une.
  RaidArrival? get incomingRaid => state.pending.whereType<RaidArrival>().firstOrNull;

  /// Production horaire de [s], bonus des officiers compris.
  Resources hourlyRate(GameState s) =>
      _rules.hourlyProduction(s.planet, s.research, s.modifiers(data));

  /// Points du joueur (classement).
  double get points => raid.points(state, _rules);

  /// Points d'économie et de recherche : base de la force des raids.
  double get economyPoints => raid.economyPoints(state, _rules);

  /// Officiers dont un niveau peut être débloqué (pastille du hero).
  List<OfficerKind> get availableOfficers => officers.availableOfficers(state, data);

  /// Débloque ou promeut un officier ; `false` si ce n'est pas possible.
  Future<bool> promoteOfficer(OfficerKind kind) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    final outcome = officers.promoteOfficer(adv.state, kind, t, _rules);
    await _commit(
      outcome.state,
      applied: adv.applied,
      reports: adv.reports,
      queueCancelled: adv.cancelled,
      stories: adv.stories,
    );
    return outcome.promoted;
  });

  /// Événements ponctuels (spec 14) : journal, dernier survenu (message), effets en cours.
  List<StoryOutcome> get storyLog => _storyLog;
  var _storyLog = <StoryOutcome>[];
  StoryOutcome? get lastStory => _lastStory;
  StoryOutcome? _lastStory;
  int get storyCount => _storyCount;
  var _storyCount = 0;

  /// Efface les rapports de combat (raids et attaques).
  Future<void> clearReports() => _serialized(() async {
    await _repo.clearReports();
    _reports = [];
    notifyListeners();
  });

  /// Efface le journal des événements (les effets en cours ne changent pas).
  Future<void> clearStoryLog() => _serialized(() async {
    await _repo.clearStoryLog();
    _storyLog = [];
    notifyListeners();
  });

  /// Choix proposé au joueur, en attente de réponse.
  StoryEventSpec? get pendingChoice => story.pendingChoice(state, data);

  /// Échéance du choix en attente (option par défaut).
  DateTime? get choiceDeadline => story.pendingStory(state)?.dueAt;

  /// Répond au choix en attente.
  Future<void> answerChoice(int option) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    final out = story.answerChoice(adv.state, option, t, _rules);
    await _commit(
      out?.state ?? adv.state,
      applied: adv.applied,
      reports: adv.reports,
      queueCancelled: adv.cancelled,
      stories: [...adv.stories, ?out?.outcome],
    );
  });

  /// Debug : l'événement ponctuel en attente survient tout de suite.
  Future<void> storyNow() => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    final moved = story.storyNow(adv.state, t);
    final after = advance(moved, t, _rules);
    await _commit(
      after.state,
      applied: [...adv.applied, ...after.applied],
      reports: [...adv.reports, ...after.reports],
      queueCancelled: [...adv.cancelled, ...after.cancelled],
      stories: [...adv.stories, ...after.stories],
    );
  });

  Future<void> _ensureStory() async {
    if (story.pendingStory(state) != null) return;
    final id = await _repo.nextEventId();
    await _commit(
      story.ensureStoryScheduled(state, now(), _rules, seed: _random.nextInt(1 << 31), eventId: id),
    );
    if (!_visible) await _scheduleAll();
  }

  /// Bilan d'énergie de [s], effets d'événements compris.
  EnergyBalance energyOf(GameState s) => _rules.energy(s.planet, s.research, s.modifiers(data));

  /// Envoie une flotte (spec 15, V3b). Renvoie la raison du refus, ou `null`.
  Future<fleet.MissionBlock?> sendMission(
    MissionKind kind,
    int? target,
    Map<UnitKind, int> ships, {
    int speedPercent = 100,
    double shelterHours = 0,
  }) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    final id = await _repo.nextEventId();
    final out = fleet.sendMission(
      adv.state,
      kind,
      target,
      ships,
      speedPercent,
      t,
      _rules,
      eventId: id,
      seed: _random.nextInt(1 << 31),
      shelterHours: shelterHours,
    );
    await _commit(
      out.state,
      applied: adv.applied,
      reports: adv.reports,
      queueCancelled: adv.cancelled,
      stories: adv.stories,
    );
    return out.block;
  });

  /// Fait faire demi-tour à une flotte à l'aller.
  Future<void> recall(int missionId) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    await _commit(
      fleet.recallMission(adv.state, missionId, t, _rules),
      applied: adv.applied,
      reports: adv.reports,
      queueCancelled: adv.cancelled,
      stories: adv.stories,
    );
  });

  Future<void> _ensureBases() async {
    if (state.bases.length >= data.pirateBases.list.length) return;
    await _commit(fleet.ensureBases(state, now(), _rules, seed: _random.nextInt(1 << 31)));
  }

  /// Envoie [count] recycleurs collecter le champ de débris (spec 15).
  Future<RecycleBlock?> recycle(int count) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    final id = await _repo.nextEventId();
    final out = startRecycling(adv.state, count, t, _rules, eventId: id);
    await _commit(
      out.state,
      applied: adv.applied,
      reports: adv.reports,
      queueCancelled: adv.cancelled,
      stories: adv.stories,
    );
    return out.block;
  });

  /// Debug : la prochaine flotte pirate est détectée tout de suite.
  Future<void> raidNow() => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    await _commit(
      raid.raidNow(adv.state, t, _rules),
      applied: adv.applied,
      reports: adv.reports,
      queueCancelled: adv.cancelled,
      stories: adv.stories,
    );
  });

  Future<void> _ensureRaid() async {
    if (raid.pendingRaid(state) != null) return;
    final id = await _repo.nextEventId();
    final next = raid.ensureRaidScheduled(
      state,
      now(),
      _rules,
      seed: _random.nextInt(1 << 31),
      eventId: id,
    );
    await _commit(next);
    if (!_visible) await _scheduleAll();
  }

  /// Rattrape le temps écoulé (ouverture, retour au premier plan, échéance d'un timer).
  Future<void> refresh() => _serialized(_advanceAndSave);

  /// Lance le niveau suivant de [item] (bâtiment ou techno). Renvoie la raison du refus,
  /// ou `null`.
  Future<OrderBlock?> order(Unlockable item) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    final id = await _repo.nextEventId();
    final outcome = placeOrder(adv.state, item, t, _rules, eventId: id);
    switch (outcome) {
      case OrderQueued():
        await _commit(
          outcome.state,
          applied: adv.applied,
          reports: adv.reports,
          queueCancelled: adv.cancelled,
          stories: adv.stories,
        );
        return null;
      case OrderRejected(:final reason):
        await _commit(
          adv.state,
          applied: adv.applied,
          reports: adv.reports,
          queueCancelled: adv.cancelled,
          stories: adv.stories,
        );
        return reason;
      case OrderStarted(:final event):
        await _commit(
          outcome.state,
          applied: adv.applied,
          reports: adv.reports,
          queueCancelled: adv.cancelled,
          stories: adv.stories,
        );
        if (!_visible) await _notifier.schedule(event, data);
        return null;
      case BatchStarted():
        throw StateError('placeOrder ne renvoie pas de lot');
    }
  });

  /// Commande [count] unités au chantier. Renvoie la raison du refus, ou `null`.
  Future<OrderBlock?> orderUnits(UnitKind unit, int count) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    final id = await _repo.nextEventId();
    final outcome = placeBatch(adv.state, unit, count, t, _rules, eventId: id);
    switch (outcome) {
      case OrderQueued():
        await _commit(
          outcome.state,
          applied: adv.applied,
          reports: adv.reports,
          queueCancelled: adv.cancelled,
          stories: adv.stories,
        );
        return null;
      case OrderRejected(:final reason):
        await _commit(
          adv.state,
          applied: adv.applied,
          reports: adv.reports,
          queueCancelled: adv.cancelled,
          stories: adv.stories,
        );
        return reason;
      case BatchStarted(:final batch):
        await _commit(
          outcome.state,
          applied: adv.applied,
          reports: adv.reports,
          queueCancelled: adv.cancelled,
          stories: adv.stories,
        );
        if (!_visible) await _notifier.schedule(batch, data);
        return null;
      case OrderStarted():
        throw StateError('placeBatch renvoie un lot');
    }
  });

  /// Règle la production d'un bâtiment (0 à 100 %, pas de 10).
  Future<void> setPercent(BuildingKind kind, int percent) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    await _commit(
      setProductionPercent(adv.state, kind, percent, t, _rules),
      applied: adv.applied,
      reports: adv.reports,
      queueCancelled: adv.cancelled,
      stories: adv.stories,
    );
  });

  Future<void> cancel(int eventId) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    final out = cancelOrQueue(adv.state, eventId, t, _rules);
    await _commit(
      out.state,
      applied: adv.applied,
      reports: adv.reports,
      queueCancelled: [...adv.cancelled, ?out.cancelled],
      stories: adv.stories,
      cancelledIds: [eventId],
    );
    await _notifier.cancel(eventId);
  });

  /// Change la vitesse : le passé est soldé à l'ancienne vitesse. Les échéances déjà
  /// programmées ne bougent pas.
  Future<void> setSpeed(double speed) => _serialized(() async {
    await _advanceAndSave();
    await _repo.setSpeed(speed);
    _set(_save.copyWith(speed: speed));
    notifyListeners();
  });

  Future<String> exportJson() => _serialized(() async {
    await _advanceAndSave();
    return const JsonEncoder.withIndent('  ').convert(encodeSave(_save, exportedAt: now()));
  });

  /// Remplace la partie par une sauvegarde. Lève une [FormatException] si invalide.
  Future<void> importJson(String text) => _serialized(() async {
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const FormatException('JSON invalide : objet attendu');
    await _replace(decodeSave(decoded.cast<String, Object?>()));
    await _advanceAndSave();
    await _ensureRaid();
    await _ensureStory();
    await _ensureBases();
    _reports = await _repo.loadReports();
    _storyLog = await _repo.loadStoryLog();
  });

  Future<void> reset() => _serialized(() async {
    await _replace(_newGame(speed: speed));
    await _ensureRaid();
    await _ensureStory();
    await _ensureBases();
    _reports = await _repo.loadReports();
    _storyLog = await _repo.loadStoryLog();
    notifyListeners();
  });

  SaveGame _newGame({required double speed}) {
    final seed = _random.nextInt(1 << 31);
    final planet = Planet.create(data: data, random: math.Random(seed), now: now());
    return SaveGame(
      state: GameState(planet: planet, pending: const []),
      speed: speed,
      seed: seed,
    );
  }

  /// App masquée : programme une notification par événement à venir.
  Future<void> onHidden() => _serialized(() async {
    _visible = false;
    await _scheduleAll();
  });

  /// App de nouveau visible : plus de notifications, rattrapage du temps écoulé.
  Future<void> onVisible() => _serialized(() async {
    _visible = true;
    await _notifier.cancelAll();
    await _advanceAndSave();
  });

  Future<void> _replace(SaveGame save) async {
    await _repo.replaceAll(save);
    _set(save);
    await _notifier.cancelAll();
    if (!_visible) await _scheduleAll();
  }

  /// Horizon de prévision des notifications de la file d'attente.
  static const _forecast = Duration(days: 7);

  Future<void> _scheduleAll() async {
    await _notifier.cancelAll();
    final t = now();
    for (final e in state.pending) {
      // Un tirage d'événement n'est notifié que par la prévision ci-dessous.
      if (e is StoryEvent && e.choiceKey == null) continue;
      if (notifyAt(e).isAfter(t)) await _notifier.schedule(e, data);
    }
    // Les ordres en attente n'ont pas encore d'échéance et les événements ponctuels ne sont
    // connus qu'au tirage : on simule la suite (déterministe, raids compris) pour prévoir
    // les fins d'ordres, une éventuelle annulation de file et les événements.
    final queuedIds = {for (final q in state.queue) q.id};
    final sim = advance(state, t.add(_forecast), _rules);
    for (final (i, o) in sim.stories.indexed) {
      await _notifier.scheduleStory(o, i, data);
    }
    for (final e in [...sim.applied, ...sim.state.pending]) {
      if (queuedIds.contains(e.id) && notifyAt(e).isAfter(t)) await _notifier.schedule(e, data);
    }
    for (final c in sim.cancelled) {
      await _notifier.scheduleCancelled(c, data);
    }
  }

  Future<void> _advanceAndSave() async {
    final result = advance(state, now(), _rules);
    if (identical(result.state, state)) return;
    await _commit(
      result.state,
      applied: result.applied,
      reports: result.reports,
      queueCancelled: result.cancelled,
      stories: result.stories,
    );
  }

  Future<void> _commit(
    GameState next, {
    Iterable<GameEvent> applied = const [],
    Iterable<int> cancelledIds = const [],
    Iterable<RaidReport> reports = const [],
    Iterable<QueueCancelled> queueCancelled = const [],
    Iterable<StoryOutcome> stories = const [],
  }) async {
    await _repo.save(
      next,
      applied: applied,
      cancelledIds: cancelledIds,
      reports: reports,
      stories: stories,
    );
    _set(_save.copyWith(state: next));
    if (stories.isNotEmpty) {
      _lastStory = stories.last;
      _storyCount += stories.length;
      _storyLog = await _repo.loadStoryLog();
    }
    if (queueCancelled.isNotEmpty) {
      _lastQueueCancelled = queueCancelled.last;
      _queueCancelledCount += queueCancelled.length;
    }
    if (reports.isNotEmpty) _reports = await _repo.loadReports();
    notifyListeners();
  }

  void _set(SaveGame save) {
    _save = save;
    _rules = Rules(data, speed: save.speed);
  }

  Future<T> _serialized<T>(Future<T> Function() op) {
    final result = _lock.then((_) => op());
    _lock = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
