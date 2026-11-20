import 'package:flutter/material.dart';

import '../theme.dart';
import '../visuals.dart';
import 'info_button.dart';

/// Carte d'élément de l'ambiance Immersive (spec 10, maquette C) : image 4:3 en tête, nom,
/// une ligne (niveau ou nombre possédé, durée) et le coût sur le bouton d'action. Le reste
/// (effet, blocage, prérequis, description) est dans la feuille de détail, au tap.
class GridCard extends StatelessWidget {
  const GridCard({
    super.key,
    required this.image,
    required this.icon,
    required this.name,
    required this.line,
    required this.action,
    required this.actionLabel,
    required this.onAction,
    required this.onDetails,
    this.grayed = false,
    this.locked = false,
  });

  final String? image;
  final IconData icon;
  final String name;

  /// « Niv. 3 · 12 min » ou « × 40 · 30 s par unité ».
  final String line;

  /// Contenu du bouton : le coût, ou « Verrouillé ».
  final Widget action;

  /// Libellé accessible du bouton : action + nom.
  final String actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDetails;
  final bool grayed;

  /// Prérequis manquants : carte atténuée, comme en ambiance Équilibrée.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Opacity(
          opacity: locked ? 0.6 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, box) => GameImage(
                  path: image,
                  icon: icon,
                  iconSize: 40,
                  width: box.maxWidth,
                  height: box.maxWidth * 3 / 4,
                  grayed: grayed,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InfoButton(title: name, body: '', onPressed: onDetails),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      line,
                      style: mono(theme.textTheme.bodySmall)?.copyWith(color: Palette.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      button: true,
                      label: actionLabel,
                      excludeSemantics: true,
                      child: FilledButton.tonal(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: FittedBox(fit: BoxFit.scaleDown, child: action),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
