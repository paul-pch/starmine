import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/domain/game_data.dart';
import 'package:starmine/ui/visuals.dart';
import 'package:yaml/yaml.dart';

/// Cohérence du registre et des fichiers packagés (spec 11). Ne lit jamais les masters, locaux
/// et absents de la CI.
void main() {
  final registry = loadYaml(File('art/registry.yaml').readAsStringSync()) as YamlMap;
  final images = (registry['images'] as YamlList).cast<YamlMap>();
  final validated = images.where((e) => e['status'] == 'validated').toList();
  final builds = {for (final e in validated) e['build'] as String};

  test('chaque image validée a son fichier, et inversement', () {
    final files = Directory(
      'assets/visuels',
    ).listSync().whereType<File>().map((f) => f.path).where((p) => p.endsWith('.webp')).toSet();
    expect(files, builds);
  });

  test('le fichier porte le nom de l’id, sans version', () {
    for (final e in validated) {
      expect(e['build'], 'assets/visuels/${e['id']}.webp');
    }
  });

  test('chaque bâtiment a son t1 dans chaque climat', () {
    for (final kind in BuildingKind.values) {
      for (final band in TemperatureBand.values) {
        expect(builds, contains('assets/visuels/building.${kind.key}.t1.${band.name}.webp'));
      }
    }
  });

  test('seuils de palier alignés sur le code', () {
    final tiers = registry['tiers'] as YamlMap;
    final defaults = (tiers['default'] as YamlList).cast<int>();
    for (final kind in BuildingKind.values) {
      final thresholds = ((tiers[kind.key] as YamlList?)?.cast<int>() ?? defaults);
      for (var tier = 1; tier <= thresholds.length; tier++) {
        expect(buildingTier(kind, thresholds[tier - 1]), tier, reason: kind.key);
      }
    }
  });

  test('tranches de température alignées sur le code', () {
    final bands = registry['temperature_bands'] as YamlMap;
    for (final band in TemperatureBand.values) {
      final range = (bands[band.name] as YamlList).cast<int>();
      expect(TemperatureBand.of(range[0]), band);
      expect(TemperatureBand.of(range[1] - 1), band);
    }
  });

  test('poids total des images sous la cible de 15 Mo', () {
    final bytes = builds.fold<int>(0, (sum, path) => sum + File(path).lengthSync());
    expect(bytes, lessThan(15 * 1024 * 1024));
  });
}
