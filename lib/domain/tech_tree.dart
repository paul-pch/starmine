import 'game_data.dart';

/// Lecture de l'arbre des prérequis, pour l'affichage et la planification.
extension TechTree on GameData {
  /// Bâtiments, technos et unités qui ont [item] parmi leurs prérequis directs, dans
  /// l'ordre de déclaration.
  List<ItemSpec> unlockedBy(Unlockable item) => [
    for (final k in BuildingKind.values)
      if (this[k].requires.containsKey(item)) this[k],
    for (final k in TechKind.values)
      if (tech(k).requires.containsKey(item)) tech(k),
    for (final k in UnitKind.values)
      if (unit(k).defense && unit(k).requires.containsKey(item)) unit(k),
  ];

  /// Palier d'une techno : 1 + palier maximal de ses prérequis technologiques
  /// (les prérequis de bâtiments ne comptent pas). Énergie = 1, Plasma = 4.
  int tier(TechKind kind) {
    var depth = 0;
    for (final req in tech(kind).requires.keys) {
      if (req is TechKind) {
        final t = tier(req);
        if (t > depth) depth = t;
      }
    }
    return depth + 1;
  }

  /// Technos regroupées par palier croissant, ordre de déclaration dans chaque palier.
  Map<int, List<TechKind>> techsByTier() {
    final byTier = <int, List<TechKind>>{};
    for (final k in TechKind.values) {
      byTier.putIfAbsent(tier(k), () => []).add(k);
    }
    return Map.fromEntries(byTier.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }
}
