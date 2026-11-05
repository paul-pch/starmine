/// Les trois ressources stockées. L'énergie n'est pas stockée : c'est un bilan instantané.
enum ResourceKind { metal, crystal, deuterium }

/// Quantité de métal, cristal et deutérium. Immuable, en `double` (affichage tronqué).
class Resources {
  const Resources({this.metal = 0, this.crystal = 0, this.deuterium = 0});

  static const zero = Resources();

  final double metal;
  final double crystal;
  final double deuterium;

  double operator [](ResourceKind kind) => switch (kind) {
    ResourceKind.metal => metal,
    ResourceKind.crystal => crystal,
    ResourceKind.deuterium => deuterium,
  };

  Resources operator +(Resources o) => Resources(
    metal: metal + o.metal,
    crystal: crystal + o.crystal,
    deuterium: deuterium + o.deuterium,
  );

  Resources operator -(Resources o) => Resources(
    metal: metal - o.metal,
    crystal: crystal - o.crystal,
    deuterium: deuterium - o.deuterium,
  );

  Resources operator *(double k) =>
      Resources(metal: metal * k, crystal: crystal * k, deuterium: deuterium * k);

  /// Vrai si chaque ressource de `this` couvre celle de [cost].
  bool covers(Resources cost) =>
      metal >= cost.metal &&
      crystal >= cost.crystal &&
      deuterium >= cost.deuterium;

  /// Ressources manquantes pour payer [cost] (0 quand c'est couvert).
  Resources missingFor(Resources cost) => Resources(
    metal: _positive(cost.metal - metal),
    crystal: _positive(cost.crystal - crystal),
    deuterium: _positive(cost.deuterium - deuterium),
  );

  Resources map(double Function(ResourceKind kind, double value) f) => Resources(
    metal: f(ResourceKind.metal, metal),
    crystal: f(ResourceKind.crystal, crystal),
    deuterium: f(ResourceKind.deuterium, deuterium),
  );

  static Resources of(double Function(ResourceKind kind) f) => Resources(
    metal: f(ResourceKind.metal),
    crystal: f(ResourceKind.crystal),
    deuterium: f(ResourceKind.deuterium),
  );

  static double _positive(double v) => v > 0 ? v : 0;

  @override
  bool operator ==(Object other) =>
      other is Resources &&
      other.metal == metal &&
      other.crystal == crystal &&
      other.deuterium == deuterium;

  @override
  int get hashCode => Object.hash(metal, crystal, deuterium);

  @override
  String toString() => 'Resources(m: $metal, c: $crystal, d: $deuterium)';
}
