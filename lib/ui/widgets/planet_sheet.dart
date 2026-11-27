import 'package:flutter/material.dart';

import '../../domain/game_data.dart';
import '../../domain/planet.dart';
import '../format.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'info_button.dart';

const traitsHelp =
    'Chaque planète a un atout et un défaut, tirés à sa naissance et liés en partie à son '
    'climat : une planète chaude a plus de chances d’un soleil généreux et d’eaux rares, une '
    'planète froide l’inverse.\n\n'
    'Ils durent toute la partie et s’ajoutent aux officiers et aux événements.';

String bandName(TemperatureBand b) => switch (b) {
  TemperatureBand.cold => 'Monde froid',
  TemperatureBand.temperate => 'Monde tempéré',
  TemperatureBand.hot => 'Monde chaud',
};

/// Effet d'un trait en texte : atout [boon] ou défaut, de valeur [value] (0.1 = 10 %).
String traitEffectText(TraitEffect e, double value, {required bool boon}) {
  final pct = '${(value * 100).round()} %';
  final plus = '+$pct';
  final minus = '−$pct';
  return switch (e) {
    TraitEffect.metal => '${boon ? plus : minus} de production de métal',
    TraitEffect.crystal => '${boon ? plus : minus} de production de cristal',
    TraitEffect.deuterium => '${boon ? plus : minus} de production de deutérium',
    TraitEffect.energy => '${boon ? plus : minus} d’énergie produite',
    TraitEffect.build => '${boon ? minus : plus} de durée de construction',
    TraitEffect.research => '${boon ? minus : plus} de durée de recherche',
    TraitEffect.rebuild => '${boon ? plus : minus} de défenses reconstruites après un combat',
  };
}

/// Feuille de la planète (spec 16) : nom et renommage, climat, description, atout et défaut.
abstract final class PlanetSheet {
  static Future<void> show(BuildContext context, GameController controller) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => ListenableBuilder(
          listenable: controller,
          builder: (context, _) => _PlanetDetail(controller: controller),
        ),
      );
}

class _PlanetDetail extends StatelessWidget {
  const _PlanetDetail({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final p = controller.state.planet;
    final cfg = data.planet;
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    final f = data.formulas;
    final deut = f.deuteriumTempIntercept + f.deuteriumTempSlope * p.tempMax;
    Widget trait(TraitEffect? e, {required bool boon}) {
      final spec = e == null ? null : cfg.traits[e];
      if (e == null || spec == null) return const SizedBox.shrink();
      final color = boon ? Palette.free : theme.colorScheme.error;
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(boon ? Icons.add_circle_outline : Icons.remove_circle_outline, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${boon ? 'Atout' : 'Défaut'} · ${boon ? spec.boon : spec.flaw}',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    traitEffectText(e, cfg.traitValue, boon: boon),
                    style: theme.textTheme.bodyMedium?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(p.name, style: theme.textTheme.titleLarge)),
                IconButton(
                  tooltip: 'Renommer',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _rename(context),
                ),
              ],
            ),
            Text(
              '${bandName(p.band)} · ${fmtTempRange(p.tempMax - data.start.tempSpread, p.tempMax)}',
              style: mono(secondary),
            ),
            if (cfg.descriptions[p.band] case final text?) ...[
              const SizedBox(height: 12),
              Text(text, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('Traits', style: theme.textTheme.titleSmall)),
                const InfoButton(title: 'Traits de la planète', body: traitsHelp),
              ],
            ),
            trait(p.boon, boon: true),
            trait(p.flaw, boon: false),
            const SizedBox(height: 12),
            Text(
              'Température : synthétiseur de deutérium × '
              '${deut.toStringAsFixed(2).replaceAll('.', ',')}',
              style: secondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final field = TextEditingController(text: controller.state.planet.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer la planète'),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLength: planetNameMax,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nom'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
    if (name != null) await controller.rename(name);
  }
}
