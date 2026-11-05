import 'dart:io';

import 'package:starmine/data/game_data_loader.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/domain/planet.dart';
import 'package:starmine/domain/resources.dart';

/// La vraie config du jeu : les tests valident aussi le fichier embarqué.
final GameData gameData = parseGameData(File(gameDataAsset).readAsStringSync());

final DateTime t0 = DateTime.utc(2026, 1, 1, 8);

Planet planet({
  Map<BuildingKind, int> levels = const {},
  Resources resources = const Resources(metal: 500, crystal: 500),
  int tempMax = 40,
  DateTime? at,
}) => Planet(
  id: 1,
  name: 'Test',
  tempMax: tempMax,
  resources: resources,
  levels: levels,
  lastUpdate: at ?? t0,
);
