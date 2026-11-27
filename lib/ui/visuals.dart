import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/combat.dart';
import '../domain/game_data.dart';
import '../domain/raid.dart';
import 'theme.dart';

// Tranche de température : définie dans le domaine (spec 16), utilisée ici pour les images.
export '../domain/game_data.dart' show TemperatureBand;

/// Préférence d'affichage (spec 10) : ne change aucune information affichée.
enum Ambiance {
  balanced('Équilibrée'),
  immersive('Immersive'),
  plain('Sobre');

  const Ambiance(this.label);

  final String label;

  static Ambiance fromName(String? name) =>
      values.firstWhere((a) => a.name == name, orElse: () => balanced);
}


/// Paysage de la planète (spec 11) : déduit de Tmax, déjà tirée avec une graine stockée, sans
/// rien changer à la sauvegarde. Le rocheux garde les ids historiques (`planet_hero.<climat>`).
enum Biome {
  rocky(null),
  coast('coast'),
  mesas('mesas'),
  jungle('jungle');

  const Biome(this.key);

  /// Segment d'id de l'image, `null` pour le rocheux.
  final String? key;

  /// Tmax modulo le nombre de paysages (reste positif en Dart, même pour Tmax < 0).
  static Biome of(int tempMax) => values[tempMax % values.length];
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

  /// Ambiance Immersive : fond plein écran, panneaux opaques, cartes en grille de 2 colonnes
  /// avec image 4:3 en tête (spec 10). Les écrans lisent ce drapeau, jamais l'ambiance.
  bool get immersive => ambiance == Ambiance.immersive;

  static Future<Visuals> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return Visuals(assets: manifest.listAssets().toSet());
  }

  Visuals withAmbiance(Ambiance value) => Visuals(assets: assets, ambiance: value);

  String? _resolve(String id) {
    final path = 'assets/visuels/$id.webp';
    return !plain && assets.contains(path) ? path : null;
  }

  String? hero(int tempMax) => _landscape('planet_hero', tempMax);

  /// Fond plein écran de l'ambiance Immersive, par paysage et tranche de température ; rien
  /// ailleurs.
  String? background(int tempMax) => immersive ? _landscape('background', tempMax) : null;

  /// Image du paysage de la planète dans son climat ; paysage sans image : le rocheux du même
  /// climat, sinon repli.
  String? _landscape(String category, int tempMax) {
    final band = TemperatureBand.of(tempMax).name;
    final biome = Biome.of(tempMax).key;
    return (biome == null ? null : _resolve('$category.$biome.$band')) ??
        _resolve('$category.$band');
  }

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

  /// Illustration d'un événement ponctuel (en-tête de la popover), `story.<clé>`.
  String? story(String key) => _resolve('story.$key');

  /// Défense (`defense.<clé>`) ou vaisseau (`ship.<clé>`), sans climat.
  String? unit(UnitSpec spec) => _resolve('${spec.defense ? 'defense' : 'ship'}.${spec.kind.key}');

  /// En-tête de la popover de fin de combat (`scene.<clé>`, spec 11) : raid pirate subi, ou
  /// attaque d'une base. Pas d'image pour un match nul, une patrouille, une expédition ni
  /// une simulation.
  String? combat(RaidReport r) {
    if (r.simulated || r.patrol || r.expedition != null) return null;
    final raid = r.baseName == null;
    final key = switch (r.winner) {
      CombatWinner.draw => null,
      CombatWinner.attacker => raid ? 'raid_lost' : 'attack_won',
      CombatWinner.defender => raid ? 'raid_won' : 'attack_lost',
    };
    return key == null ? null : _resolve('scene.$key');
  }

  /// Carte du champ de débris de la planète (`scene.debris`).
  String? get debris => _resolve('scene.debris');

  /// Feuille du raid détecté, au tap du bandeau d'alerte (`scene.raid_incoming`).
  String? get raidIncoming => _resolve('scene.raid_incoming');

  /// Portrait d'un officier (`character.<clé>`), carte de l'écran Officiers.
  String? officer(OfficerKind kind) => _resolve('character.${kind.key}');

  /// Base pirate, par son rang dans `pirate_bases.list` (`pirate_base.<rang>`, 4:3).
  String? pirateBase(int index) => _resolve('pirate_base.$index');
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
