import 'package:flutter/material.dart';

import '../../domain/game_data.dart';
import '../../domain/resources.dart';
import '../../domain/story.dart';
import '../format.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'info_button.dart';

const storyHelp =
    'Des événements surviennent sur la planète environ deux fois par semaine : bonus, malus '
    'ou décisions à prendre. Leurs effets sont temporaires.\n\n'
    'Une décision attend ta réponse quelques heures ; sans réponse, l’option par défaut '
    '(la plus prudente) s’applique. Certains officiers prolongent les bonus ou atténuent '
    'les malus.';

String _pct(double v) => '${v > 0 ? '+' : '−'}${(v.abs() * 100).round()} %';

String _resource(ResourceKind? k) =>
    k == null ? 'toutes ressources' : resourceName(k).toLowerCase();

/// Un effet du catalogue, en clair (« +30 % de production de métal pendant 12 h »).
String storyEffectText(GameData data, StoryEffectSpec e) => switch (e.type) {
  StoryEffectType.production =>
    '${_pct(e.value)} de production (${_resource(e.resource)}) pendant ${fmtHours(e.hours)}',
  StoryEffectType.energy => '${_pct(e.value)} d’énergie produite pendant ${fmtHours(e.hours)}',
  StoryEffectType.shorten =>
    e.value >= 0
        ? '${(e.value * 100).round()} % du temps restant en moins '
              '(${e.target == OrderTarget.research ? 'recherche' : 'construction'} en cours)'
        : '${(-e.value * 100).round()} % de temps restant en plus '
              '(${e.target == OrderTarget.research ? 'recherche' : 'construction'} en cours)',
  StoryEffectType.stock => '${_pct(e.value)} du stock (${_resource(e.resource)})',
  StoryEffectType.gain => '${fmtHours(e.hours)} de production offertes (${_resource(e.resource)})',
  StoryEffectType.raid => 'le prochain raid arrive ${fmtHours(e.hours)} plus tôt',
  StoryEffectType.units =>
    e.value >= 0
        ? '+${e.value.round()} ${_unitName(data, e)}'
        : '−${(-e.value).round()} ${_unitName(data, e)} (dans la limite des présents)',
  StoryEffectType.debris =>
    '${fmtHours(e.hours)} de production de métal et de cristal en débris (à recycler)',
  StoryEffectType.delayed =>
    '${fmtHours(e.hours)} de production (${_resource(e.resource)}) versées dans '
        '${fmtHours(e.delay)}',
  StoryEffectType.gamble =>
    '${(e.chance * 100).round()} % de chances : ${_list(data, e.win)} ; '
        'sinon : ${_list(data, e.lose)}',
};

String _list(GameData data, List<StoryEffectSpec> effects) => effects.isEmpty
    ? 'rien'
    : [for (final e in effects) storyEffectText(data, e)].join(', ');

String _unitName(GameData data, StoryEffectSpec e) =>
    e.unit == null ? 'unités' : data.unit(e.unit!).name.toLowerCase();

/// Un effet en cours, en clair.
String activeEffectText(ActiveEffect e) => switch (e.type) {
  StoryEffectType.energy => '${_pct(e.value)} d’énergie',
  StoryEffectType.delayed => '${fmtAmount(e.value)} ${_resource(e.resource)} à recevoir',
  _ => '${_pct(e.value)} ${_resource(e.resource)}',
};

String fmtHours(double h) =>
    h == h.roundToDouble() ? '${h.round()} h' : '${h.toStringAsFixed(1)} h';

/// Sous le bandeau de raid : décision attendue et effets en cours. Rien sinon.
class StoryBanner extends StatelessWidget {
  const StoryBanner({super.key, required this.controller, required this.now});

  final GameController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final choice = controller.pendingChoice;
    final deadline = controller.choiceDeadline;
    final effects = controller.state.effects;
    if (choice == null && effects.isEmpty) return const SizedBox.shrink();
    final style = theme.textTheme.bodyMedium;
    return Material(
      color: Palette.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (choice != null && deadline != null)
            InkWell(
              onTap: () => showChoice(context, controller),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Décision : ${choice.name} · ${fmtDuration(deadline.difference(now))}',
                        style: style,
                      ),
                    ),
                    Text(
                      'Choisir',
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          for (final e in effects)
            InkWell(
              onTap: () => _details(context, data.story.catalog[e.source]),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      e.value >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: e.value >= 0 ? Palette.free : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${data.story.catalog[e.source]?.name ?? e.source} · '
                        '${activeEffectText(e)}',
                        style: style,
                      ),
                    ),
                    Text(
                      fmtDuration(e.endsAt.difference(now)),
                      style: mono(theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _details(BuildContext context, StoryEventSpec? spec) {
    if (spec == null) return Future.value();
    return InfoButton.show(
      context,
      title: spec.name,
      body: [
        spec.description,
        for (final e in spec.effects) storyEffectText(controller.data, e),
      ].join('\n\n'),
    );
  }

  /// Feuille de décision : texte d'histoire, options et leurs effets, option par défaut.
  static Future<void> showChoice(BuildContext context, GameController controller) {
    final spec = controller.pendingChoice;
    if (spec == null) return Future.value();
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(spec.name, style: theme.textTheme.titleLarge)),
                    const InfoButton(title: 'Événements', body: storyHelp),
                  ],
                ),
                Text(spec.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                ChoiceOptions(
                  controller: controller,
                  spec: spec,
                  onAnswered: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Une carte par option : libellé (option par défaut signalée), effets, bouton. Partagée par
/// la feuille de décision et la popover d'événement.
class ChoiceOptions extends StatelessWidget {
  const ChoiceOptions({
    super.key,
    required this.controller,
    required this.spec,
    required this.onAnswered,
  });

  final GameController controller;
  final StoryEventSpec spec;

  /// Appelé avant la réponse (fermer la feuille ou la popover).
  final VoidCallback onAnswered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, o) in spec.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i == spec.defaultOption ? '${o.label} (par défaut)' : o.label,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (o.effects.isEmpty)
                      Text('Rien ne se passe', style: theme.textTheme.bodySmall)
                    else
                      for (final e in o.effects)
                        Text(storyEffectText(controller.data, e), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                        onPressed: () {
                          onAnswered();
                          // La décision a pu être prise ailleurs entre-temps (bandeau).
                          if (controller.pendingChoice?.key == spec.key) {
                            controller.answerChoice(i);
                          }
                        },
                        child: Text(o.label),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
