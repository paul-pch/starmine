import 'package:flutter/material.dart';

import '../theme.dart';
import '../visuals.dart';

/// Action d'une popover : libellé et ce qu'elle fait après la fermeture.
class PopoverAction {
  const PopoverAction(this.label, this.onPressed, {this.primary = false});

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
}

/// Popover d'événement (spec 10) : fenêtre centrée qui annonce ce qui vient de se passer
/// app ouverte (raid, événement, file annulée) et servira au narratif. Une image facultative
/// (décorative, registre spec 11) prend la tête ; sans image, aucune place réservée.
class EventPopover extends StatelessWidget {
  const EventPopover({
    super.key,
    required this.icon,
    required this.title,
    this.body = '',
    this.lines = const [],
    this.image,
    this.content,
    this.actions = const [],
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;

  /// Texte d'histoire ou explication.
  final String body;

  /// Effets ou chiffres, une ligne chacun.
  final List<String> lines;

  /// Chemin d'asset résolu par [Visuals], ou `null`.
  final String? image;

  /// Contenu propre (options d'un choix), sous le texte.
  final Widget? content;

  /// Boutons ; « Fermer » seul si vide.
  final List<PopoverAction> actions;

  /// Affiche la popover ; se ferme au tap hors de la fenêtre ou par un bouton.
  static Future<void> show(BuildContext context, EventPopover popover) =>
      showDialog<void>(context: context, builder: (_) => popover);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttons = actions.isEmpty ? const [PopoverAction('Fermer', null)] : actions;
    return Dialog(
      backgroundColor: Palette.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Palette.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image != null)
                LayoutBuilder(
                  builder: (context, c) => GameImage(
                    path: image,
                    icon: icon,
                    width: c.maxWidth,
                    height: c.maxWidth * 9 / 21,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: iconColor ?? theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(body, style: theme.textTheme.bodyMedium),
                    ],
                    if (lines.isNotEmpty) const SizedBox(height: 8),
                    for (final l in lines)
                      Text(
                        l,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Palette.textSecondary,
                        ),
                      ),
                    if (content != null) ...[const SizedBox(height: 12), content!],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    for (final a in buttons)
                      a.primary
                          ? FilledButton(
                              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                              onPressed: () => _press(context, a),
                              child: Text(a.label),
                            )
                          : TextButton(
                              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                              onPressed: () => _press(context, a),
                              child: Text(a.label),
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

  void _press(BuildContext context, PopoverAction a) {
    Navigator.pop(context);
    a.onPressed?.call();
  }
}
