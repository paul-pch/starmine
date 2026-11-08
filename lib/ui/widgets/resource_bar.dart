import 'package:flutter/material.dart';

import '../../domain/resources.dart';
import '../format.dart';
import '../game_controller.dart';
import '../resource_style.dart';
import '../theme.dart';

const _energyHelp =
    'Le solde est l’énergie produite moins l’énergie consommée par les mines. S’il est '
    'négatif, toutes les mines tournent au même pourcentage réduit (produite ÷ consommée). '
    'La production de base de la planète n’est pas touchée.';

/// Barre compacte, collée en haut : quatre colonnes (stock interpolé à [now], production,
/// jauge ; solde d'énergie). Le tap ouvre le détail de la ressource.
class ResourceBar extends StatelessWidget {
  const ResourceBar({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final rules = controller.rules;
    final stock = controller.interpolated(now).planet.resources;
    final cap = rules.capacity(state.planet.levels);
    final rate = controller.hourlyRate(state);
    return ColoredBox(
      color: Palette.bar,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              for (final k in ResourceKind.values)
                Expanded(
                  child: _ResourceTile(
                    key: ValueKey('resource.${k.name}'),
                    kind: k,
                    stock: stock[k],
                    capacity: cap[k],
                    perHour: rate[k],
                    onTap: () => _showResource(context, k),
                  ),
                ),
              Expanded(
                child: _EnergyTile(
                  key: const ValueKey('resource.energy'),
                  controller: controller,
                  onTap: () => _showEnergy(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResource(BuildContext context, ResourceKind kind) {
    final state = controller.interpolated(now);
    final rules = controller.rules;
    final total = controller.hourlyRate(state)[kind];
    final boost = state.modifiers(controller.data).productionFactor;
    final base = controller.data.formulas.baseProductionPerHour[kind] * rules.speed * boost;
    final cap = rules.capacity(state.planet.levels)[kind];
    return _showSheet(
      context,
      icon: Icon(ResourceStyle.icon(kind), color: ResourceStyle.color(kind)),
      title: resourceName(kind),
      rows: [
        _Row('Stock', '${fmtAmount(state.planet.resources[kind])} / ${fmtAmount(cap)}'),
        _Row('Production de base', '${_signed(base)}/h'),
        _Row('Mines et consommations', '${_signed(total - base)}/h'),
        _Row('Total', '${_signed(total)}/h'),
        if (boost > 1) _Row('Coup de pouce de départ', '×${boost.toStringAsFixed(1)}'),
      ],
      help: boost > 1 ? _boostHelp : null,
    );
  }

  Future<void> _showEnergy(BuildContext context) {
    final energy = controller.energyOf(controller.state);
    return _showSheet(
      context,
      icon: const Icon(ResourceStyle.energyIcon, color: ResourceStyle.energyColor),
      title: 'Énergie',
      rows: [
        _Row('Produite', fmtAmount(energy.produced)),
        _Row('Consommée', fmtAmount(energy.consumed)),
        _Row('Solde', _signed(energy.net)),
        if (energy.factor < 1) _Row('Mines à', '${(energy.factor * 100).floor()} %'),
      ],
      help: _energyHelp,
    );
  }

  Future<void> _showSheet(
    BuildContext context, {
    required Icon icon,
    required String title,
    required List<_Row> rows,
    String? help,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(title, style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              ...rows,
              if (help != null) ...[
                const SizedBox(height: 12),
                Text(help, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      );
    },
  );
}

const _boostHelp =
    'Coup de pouce de départ : la production de base et des mines est multipliée en début '
    'de partie. Le bonus diminue à mesure que ton économie et ta recherche progressent, '
    'puis disparaît.';

String _signed(double value) => '${value > 0 ? '+' : ''}${fmtAmount(value)}';

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: mono(style)),
        ],
      ),
    );
  }
}

/// Colonne de la barre : icône, deux lignes de chiffres, jauge facultative. Les chiffres se
/// réduisent plutôt que de déborder quand les stocks deviennent grands.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.value,
    required this.valueColor,
    required this.detail,
    required this.detailColor,
    required this.semantics,
    required this.onTap,
    this.gauge,
  });

  final Icon icon;
  final String value;
  final Color valueColor;
  final String detail;
  final Color detailColor;
  final String semantics;
  final VoidCallback onTap;
  final Widget? gauge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget line(String s, TextStyle? style) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(s, style: style, maxLines: 1),
    );
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      line(value, mono(text.bodySmall)?.copyWith(color: valueColor)),
                      line(
                        detail,
                        mono(text.labelSmall)?.copyWith(fontSize: 10, color: detailColor),
                      ),
                      if (gauge case final g?) ...[const SizedBox(height: 2), g],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    super.key,
    required this.kind,
    required this.stock,
    required this.capacity,
    required this.perHour,
    required this.onTap,
  });

  final ResourceKind kind;
  final double stock;
  final double capacity;
  final double perHour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final full = stock >= capacity;
    final rate = '${_signed(perHour)}/h';
    return _Tile(
      icon: Icon(ResourceStyle.icon(kind), size: 18, color: ResourceStyle.color(kind)),
      value: fmtAmount(stock),
      valueColor: full ? error : Palette.text,
      detail: rate,
      detailColor: perHour < 0 ? error : Palette.free,
      semantics: '${resourceName(kind)} : ${fmtAmount(stock)}, $rate',
      onTap: onTap,
      gauge: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: LinearProgressIndicator(
          value: capacity.isFinite && capacity > 0 ? (stock / capacity).clamp(0.0, 1.0) : 0,
          minHeight: 2,
          color: full ? error : ResourceStyle.color(kind),
        ),
      ),
    );
  }
}

class _EnergyTile extends StatelessWidget {
  const _EnergyTile({super.key, required this.controller, required this.onTap});

  final GameController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final energy = controller.energyOf(controller.state);
    final short = energy.factor < 1;
    final detail = short ? 'Mines à ${(energy.factor * 100).floor()} %' : 'énergie';
    return _Tile(
      icon: Icon(
        ResourceStyle.energyIcon,
        size: 18,
        color: energy.net < 0 ? error : ResourceStyle.energyColor,
      ),
      value: _signed(energy.net),
      valueColor: energy.net < 0 ? error : Palette.text,
      detail: detail,
      detailColor: short ? error : Palette.textSecondary,
      semantics: 'Énergie : ${_signed(energy.net)}, $detail',
      onTap: onTap,
    );
  }
}
