import 'package:flutter/material.dart';

/// Icône de chaque catégorie du YAML (`categories`), pour des puces de filtre compactes.
/// Le nom reste affiché en texte (titre de section, ligne sous les puces).
abstract final class CategoryStyle {
  static const all = Icons.apps;
  static const realizable = Icons.task_alt;

  static IconData icon(String key) => switch (key) {
    'production' => Icons.diamond_outlined,
    'energy' => Icons.bolt,
    'storage' => Icons.inventory_2_outlined,
    'infrastructure' => Icons.apartment,
    'basic' => Icons.science_outlined,
    'combat' => Icons.gps_fixed,
    'advanced' => Icons.auto_awesome_outlined,
    'propulsion' => Icons.speed,
    'light' => Icons.shield_outlined,
    'heavy' => Icons.rocket_launch_outlined,
    'shields' => Icons.shield_moon_outlined,
    'civil' => Icons.local_shipping_outlined,
    'warships' => Icons.rocket_outlined,
    _ => Icons.label_outline,
  };
}
