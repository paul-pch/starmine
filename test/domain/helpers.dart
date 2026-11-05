import 'dart:io';

import 'package:starmine/data/game_data_loader.dart';
import 'package:starmine/domain/engine.dart';
import 'package:starmine/domain/events.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/planet.dart';
import 'package:starmine/domain/resources.dart';
import 'package:starmine/domain/rules.dart';

/// La vraie config du jeu : les tests valident aussi le fichier embarqué.
final GameData gameData = parseGameData(File(gameDataAsset).readAsStringSync());

final DateTime t0 = DateTime.utc(2026, 1, 1, 8);

Planet planet({
  Map<BuildingKind, int> levels = const {},
  Map<BuildingKind, int> percents = const {},
  Resources resources = const Resources(metal: 500, crystal: 500),
  int tempMax = 40,
  DateTime? at,
}) => Planet(
  id: 1,
  name: 'Test',
  tempMax: tempMax,
  resources: resources,
  levels: levels,
  percents: percents,
  lastUpdate: at ?? t0,
);

/// État de partie à partir d'une planète, de technos et d'événements.
GameState game(Planet p, {TechLevels research = const {}, List<GameEvent> pending = const []}) =>
    GameState(planet: p, research: research, pending: pending);
