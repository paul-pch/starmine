import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/game_repository.dart';
import '../data/save_codec.dart';
import '../domain/engine.dart';
import '../domain/events.dart';
import '../domain/game_data.dart';
import '../domain/planet.dart';
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

  Future<void> init() => _serialized(() async {
    final loaded = await _repo.load();
    if (loaded == null) {
      await _replace(_newGame(speed: 1));
    } else {
      _set(loaded);
    }
    await _advanceAndSave();
  });

  /// Rattrape le temps écoulé (ouverture, retour au premier plan, échéance d'un timer).
  Future<void> refresh() => _serialized(_advanceAndSave);

  /// Lance le niveau suivant de [kind]. Renvoie la raison du refus, ou `null`.
  Future<BuildBlock?> build(BuildingKind kind) => _serialized(() async {
    final adv = advance(state, now(), _rules);
    final id = await _repo.nextEventId();
    final outcome = startBuilding(adv.state, kind, now(), _rules, eventId: id);
    switch (outcome) {
      case BuildRejected(:final reason):
        await _commit(adv.state, applied: adv.applied);
        return reason;
      case BuildStarted(:final event):
        await _commit(outcome.state, applied: adv.applied);
        if (!_visible) await _notifier.schedule(event, data);
        return null;
    }
  });

  Future<void> cancel(int eventId) => _serialized(() async {
    final adv = advance(state, now(), _rules);
    final next = cancelBuilding(adv.state, eventId, now(), _rules);
    await _commit(next, applied: adv.applied, cancelledIds: [eventId]);
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
  });

  Future<void> reset() => _serialized(() async {
    await _replace(_newGame(speed: speed));
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
    for (final e in state.pending.whereType<BuildingDone>()) {
      if (e.dueAt.isAfter(now())) await _notifier.schedule(e, data);
    }
  }

  Future<void> _advanceAndSave() async {
    final result = advance(state, now(), _rules);
    if (identical(result.state, state)) return;
    await _commit(result.state, applied: result.applied);
  }

  Future<void> _commit(
    GameState next, {
    Iterable<GameEvent> applied = const [],
    Iterable<int> cancelledIds = const [],
  }) async {
    await _repo.save(next, applied: applied, cancelledIds: cancelledIds);
    _set(_save.copyWith(state: next));
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
