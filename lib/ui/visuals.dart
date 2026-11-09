import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/game_data.dart';
import 'theme.dart';

/// Préférence d'affichage (spec 10) : ne change aucune information affichée.
enum Ambiance {
  balanced('Équilibrée'),
  plain('Sobre');

  const Ambiance(this.label);

  final String label;

  static Ambiance fromName(String? name) =>
      values.firstWhere((a) => a.name == name, orElse: () => balanced);
}

/// Tranche de température d'après Tmax (spec 11, `temperature_bands` du registre).
enum TemperatureBand {
  cold,
  temperate,
  hot;

  static TemperatureBand of(int tempMax) => tempMax < 0
      ? cold
      : tempMax < 40
      ? temperate
      : hot;
}

/// Seuils de palier (spec 11, `tiers` du registre).
const _defaultTiers = [1, 10, 20];
const _tiers = {
  'nanite_factory': <int>[1, 4, 8],
};

/// Palier affiché d'un bâtiment : 1 du niveau 0 au premier seuil suivant, etc.
int buildingTier(BuildingKind kind, int level) {
  final thresholds = _tiers[kind.key] ?? _defaultTiers;
  var tier = 1;
  for (var i = 0; i < thresholds.length; i++) {
    if (level >= thresholds[i]) tier = i + 1;
  }
  return tier;
}

/// Résout un id d'image en asset packagé, ou `null` pour le repli : image absente, ou
/// ambiance Sobre. Seul endroit où l'ambiance décide de l'affichage d'une image.
class Visuals {
  const Visuals({this.assets = const {}, this.ambiance = Ambiance.balanced});

  /// Assets connus de l'APK. Aucun accès réseau : la liste vient du manifeste.
  final Set<String> assets;
  final Ambiance ambiance;

  bool get plain => ambiance == Ambiance.plain;

  static Future<Visuals> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return Visuals(assets: manifest.listAssets().toSet());
  }

  Visuals withAmbiance(Ambiance value) => Visuals(assets: assets, ambiance: value);

  String? _resolve(String id) {
    final path = 'assets/visuels/$id.webp';
    return !plain && assets.contains(path) ? path : null;
  }

  String? hero(int tempMax) => _resolve('planet_hero.${TemperatureBand.of(tempMax).name}');

  /// Image du climat de la planète. Palier sans image validée : palier inférieur du même
  /// climat, sinon repli.
  String? building(BuildingKind kind, int level, int tempMax) {
    final band = TemperatureBand.of(tempMax).name;
    for (var t = buildingTier(kind, level); t >= 1; t--) {
      final path = _resolve('building.${kind.key}.t$t.$band');
      if (path != null) return path;
    }
    return null;
  }

  String? unlockable(Unlockable item, int level, int tempMax) => switch (item) {
    final BuildingKind kind => building(kind, level, tempMax),
    final TechKind tech => _resolve('research.${tech.key}'),
  };

  String? unit(UnitKind kind) => _resolve('defense.${kind.key}');
}

/// Donne les [Visuals] de l'ambiance courante aux écrans.
class VisualsScope extends InheritedWidget {
  const VisualsScope({super.key, required this.visuals, required super.child});

  final Visuals visuals;

  static Visuals of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VisualsScope>()?.visuals ?? const Visuals();

  @override
  bool updateShouldNotify(VisualsScope oldWidget) =>
      visuals.ambiance != oldWidget.visuals.ambiance || visuals.assets != oldWidget.visuals.assets;
}

/// Image décorative, ou repli (surface + icône vectorielle) si [path] est `null`. La place
/// est réservée avant chargement : la mise en page ne saute jamais.
class GameImage extends StatelessWidget {
  const GameImage({
    super.key,
    required this.path,
    required this.icon,
    required this.width,
    this.height,
    this.radius = 0,
    this.iconSize = 28,
    this.grayed = false,
  });

  /// Matrice de luminance : vignette d'un bâtiment pas encore construit.
  static const _grayscale = ColorFilter.matrix([
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  final String? path;
  final bool grayed;
  final IconData icon;
  final double width;
  final double? height;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Palette.bar,
      child: Center(
        child: Icon(icon, size: iconSize, color: Palette.textTertiary),
      ),
    );
    final asset = path;
    final Widget image = asset == null
        ? fallback
        : Image.asset(
            asset,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
            errorBuilder: (_, _, _) => fallback,
            frameBuilder: (_, child, frame, sync) => sync
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: child,
                  ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height ?? width,
        child: grayed && asset != null
            ? ColorFiltered(colorFilter: _grayscale, child: image)
            : image,
      ),
    );
  }
}
