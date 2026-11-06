import 'package:flutter/material.dart';

import '../../domain/combat.dart';
import '../../domain/game_data.dart';
import '../../domain/officers.dart';
import '../game_controller.dart';
import '../theme.dart';
import '../widgets/info_button.dart';

const officersHelp =
    'Les officiers se gagnent en jouant, jamais en payant. Quand les prérequis d’un niveau '
    'sont remplis, l’officier est disponible : appuie sur « Débloquer » ou « Promouvoir » '
    'pour le recruter. Rien ne se débloque sans toi.\n\n'
    'Chaque niveau augmente un bonus permanent, jusqu’à un plafond. Tous les officiers '
    'débloqués sont actifs en même temps.';

/// Effet d'un officier pour une valeur de bonus, en clair.
String officerBonusText(OfficerBonus bonus, double value) {
  String pct(double v) => '${(v * 100).round()} %';
  return switch (bonus) {
    OfficerBonus.mineProduction => '+${pct(value)} de production des mines',
    OfficerBonus.researchTime => '−${pct(value)} de durée de recherche',
    OfficerBonus.buildTime => '−${pct(value)} de durée de construction',
    OfficerBonus.defenseRebuild =>
      '${pct(defenseRebuildChance + value)} des défenses détruites reconstruites',
  };
}

/// Liste des officiers : niveau, bonus actuel et suivant, prérequis, déblocage.
class OfficersScreen extends StatelessWidget {
  const OfficersScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officiers'),
        actions: const [InfoButton(title: 'Officiers', body: officersHelp)],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final kind in controller.data.officers.keys)
              _OfficerCard(controller: controller, kind: kind),
          ],
        ),
      ),
    );
  }
}

class _OfficerCard extends StatelessWidget {
  const _OfficerCard({required this.controller, required this.kind});

  final GameController controller;
  final OfficerKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final state = controller.state;
    final spec = data.officers[kind]!;
    final level = state.officers[kind]!;
    final next = nextOfficerLevel(state, kind, data);
    final available = officerAvailable(state, kind, data);
    final secondary = theme.textTheme.bodySmall?.copyWith(color: Palette.textSecondary);
    final error = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Portrait : registre d'images (catégorie character) à venir ; repli icône.
                CircleAvatar(
                  backgroundColor: Palette.bar,
                  child: Icon(
                    Icons.military_tech_outlined,
                    color: level > 0 ? theme.colorScheme.primary : Palette.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spec.name, style: theme.textTheme.titleMedium),
                      Text('Niveau $level / ${spec.maxLevel}', style: mono(secondary)),
                    ],
                  ),
                ),
                InfoButton(title: spec.name, body: spec.description),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              level == 0
                  ? 'Pas encore recruté'
                  : 'Bonus : ${officerBonusText(spec.bonus, spec.perLevel * level)}',
              style: theme.textTheme.bodyMedium,
            ),
            if (next == null)
              Text('Niveau maximal atteint', style: secondary)
            else ...[
              Text(
                'Niveau ${level + 1} : ${officerBonusText(spec.bonus, spec.perLevel * (level + 1))}',
                style: secondary,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                children: [
                  for (final e in next.requires.entries)
                    Text(
                      '${data.spec(e.key).name} ${e.value} (${state.levelOf(e.key)})',
                      style: state.levelOf(e.key) >= e.value ? secondary : error,
                    ),
                  for (final e in next.counters.entries)
                    Text(
                      '${data.counterNames[e.key] ?? e.key.key} ${e.value} '
                      '(${state.counters[e.key]})',
                      style: state.counters[e.key]! >= e.value ? secondary : error,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: available ? () => _promote(context, spec, level) : null,
                    child: Text(level == 0 ? 'Débloquer' : 'Promouvoir'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _promote(BuildContext context, OfficerSpec spec, int level) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await controller.promoteOfficer(kind);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '${spec.name} : niveau ${level + 1}'
                : 'Prérequis non remplis pour ${spec.name}',
          ),
        ),
      );
  }
}

