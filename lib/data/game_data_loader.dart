import 'package:yaml/yaml.dart';

import '../domain/game_data.dart';

/// Chemin de la config embarquée (déclarée dans pubspec.yaml).
const gameDataAsset = 'assets/game_data.yaml';

/// Parse le contenu de `assets/game_data.yaml`.
GameData parseGameData(String yamlText) {
  final doc = loadYaml(yamlText);
  if (doc is! Map) throw const FormatException('game_data.yaml : la racine doit être une table');
  return GameData.fromMap(doc.map((k, v) => MapEntry(k.toString(), v)));
}
