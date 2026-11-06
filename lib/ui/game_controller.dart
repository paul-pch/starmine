import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/game_repository.dart';
import '../data/save_codec.dart';
import '../domain/engine.dart';
import '../domain/events.dart';
import '../domain/game_data.dart';
import '../domain/planet.dart';
import '../domain/raid.dart' as raid;
import '../domain/raid.dart' show RaidReport;
import '../domain/rules.dart';
import 'notifications.dart';

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
      planet: p.copyWith(resources: _rules.produce(p, state.research, at.difference(p.lastUpdate))),
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
    _reports = await _repo.loadReports();
  });

  /// Rapports de raid, les plus récents d'abord.
  List<StoredReport> get reports => _reports;
  var _reports = <StoredReport>[];

  int get unseenReports => _reports.where((r) => !r.seen).length;

  Future<void> markReportsSeen() => _serialized(() async {
    if (unseenReports == 0) return;
    await _repo.markReportsSeen();
    _reports = await _repo.loadReports();
    notifyListeners();
  });

  /// Flotte pirate détectée et en route, s'il y en a une.
  RaidArrival? get incomingRaid => state.pending.whereType<RaidArrival>().firstOrNull;

  /// Points du joueur (force des raids).
  double get points => raid.points(state, _rules);

  /// Debug : la prochaine flotte pirate est détectée tout de suite.
  Future<void> raidNow() => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    await _commit(raid.raidNow(adv.state, t, _rules), applied: adv.applied, reports: adv.reports);
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
    final outcome = startOrder(adv.state, item, t, _rules, eventId: id);
    switch (outcome) {
      case OrderRejected(:final reason):
        await _commit(adv.state, applied: adv.applied, reports: adv.reports);
        return reason;
      case OrderStarted(:final event):
        await _commit(outcome.state, applied: adv.applied, reports: adv.reports);
        if (!_visible) await _notifier.schedule(event, data);
        return null;
      case BatchStarted():
        throw StateError('startOrder ne renvoie pas de lot');
    }
  });

  /// Commande [count] unités au chantier. Renvoie la raison du refus, ou `null`.
  Future<OrderBlock?> orderUnits(UnitKind unit, int count) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    final id = await _repo.nextEventId();
    final outcome = startBatch(adv.state, unit, count, t, _rules, eventId: id);
    switch (outcome) {
      case OrderRejected(:final reason):
        await _commit(adv.state, applied: adv.applied, reports: adv.reports);
        return reason;
      case BatchStarted(:final batch):
        await _commit(outcome.state, applied: adv.applied, reports: adv.reports);
        if (!_visible) await _notifier.schedule(batch, data);
        return null;
      case OrderStarted():
        throw StateError('startBatch renvoie un lot');
    }
  });

  /// Règle la production d'un bâtiment (0 à 100 %, pas de 10).
  Future<void> setPercent(BuildingKind kind, int percent) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    await _commit(
      setProductionPercent(adv.state, kind, percent, t, _rules),
      applied: adv.applied, reports: adv.reports,
    );
  });

  Future<void> cancel(int eventId) => _serialized(() async {
    final t = now();
    final adv = advance(state, t, _rules);
    final next = cancelOrder(adv.state, eventId, t, _rules);
    await _commit(next, applied: adv.applied, reports: adv.reports, cancelledIds: [eventId]);
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
    _reports = await _repo.loadReports();
  });

  Future<void> reset() => _serialized(() async {
    await _replace(_newGame(speed: speed));
    await _ensureRaid();
    _reports = await _repo.loadReports();
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

  Future<void> _scheduleAll() async {
    await _notifier.cancelAll();
    for (final e in state.pending) {
      if (notifyAt(e).isAfter(now())) await _notifier.schedule(e, data);
    }
  }

  Future<void> _advanceAndSave() async {
    final result = advance(state, now(), _rules);
    if (identical(result.state, state)) return;
    await _commit(result.state, applied: result.applied, reports: result.reports);
  }

  Future<void> _commit(
    GameState next, {
    Iterable<GameEvent> applied = const [],
    Iterable<int> cancelledIds = const [],
    Iterable<RaidReport> reports = const [],
  }) async {
    await _repo.save(next, applied: applied, cancelledIds: cancelledIds, reports: reports);
    _set(_save.copyWith(state: next));
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
