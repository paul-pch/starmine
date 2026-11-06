import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';

/// Filtre « Réalisables » d'une liste (spec 10) : masque ce qui ne peut pas être lancé
/// maintenant. Évalué à l'activation et à l'ouverture de l'onglet, pas chaque seconde.
class RealizableFilter<T> {
  const RealizableFilter({
    required this.enabled,
    required this.onChanged,
    required this.isRealizable,
    required this.waitFor,
    required this.nameOf,
  });

  /// Choix mémorisé par onglet (préférence d'affichage).
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool Function(T item) isRealizable;

  /// Attente avant que l'élément soit réalisable, `null` s'il est verrouillé.
  final Duration? Function(T item) waitFor;
  final String Function(T item) nameOf;
}

/// Liste filtrable par catégorie : rangée de puces (« Tout » + catégories), et titres de
/// section dans la vue « Tout ». Les catégories viennent du YAML (`categories`).
class CategorizedList<T> extends StatefulWidget {
  const CategorizedList({
    super.key,
    required this.categories,
    required this.items,
    required this.categoryOf,
    required this.itemBuilder,
    this.header,
    this.filter,
  });

  /// Clé → libellé, dans l'ordre d'affichage.
  final Map<String, String> categories;
  final List<T> items;
  final String Function(T item) categoryOf;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Au-dessus des puces, hors défilement (carte « En cours »).
  final Widget? header;

  final RealizableFilter<T>? filter;

  @override
  State<CategorizedList<T>> createState() => _CategorizedListState<T>();
}

class _CategorizedListState<T> extends State<CategorizedList<T>> {
  /// Catégorie sélectionnée, `null` = Tout.
  String? _selected;

  /// Éléments réalisables figés à l'activation du filtre (ou à l'ouverture de l'onglet).
  Set<T>? _snapshot;

  Set<T> _realizable(RealizableFilter<T> f) => {
    for (final i in widget.items)
      if (f.isRealizable(i)) i,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = widget.filter;
    final filtering = filter?.enabled ?? false;
    final current = filter != null && filter.enabled ? _realizable(filter) : <T>{};
    if (!filtering) {
      _snapshot = null;
    } else {
      _snapshot ??= current;
    }
    final shown = _snapshot;
    final visible = shown == null ? widget.items : widget.items.where(shown.contains).toList();
    final fresh = shown == null ? 0 : current.difference(shown).length;

    final groups = {
      for (final c in widget.categories.keys)
        c: [
          for (final i in visible)
            if (widget.categoryOf(i) == c) i,
        ],
    }..removeWhere((_, items) => items.isEmpty);
    // Éléments sans catégorie connue : affichés en fin de vue « Tout ».
    final others = [
      for (final i in visible)
        if (!widget.categories.containsKey(widget.categoryOf(i))) i,
    ];
    // Une catégorie vidée par le filtre ramène à « Tout ».
    if (_selected != null && !groups.containsKey(_selected)) _selected = null;

    final chips = SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12),
              children: [
                for (final entry in [null, ...groups.keys])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry == null ? 'Tout' : widget.categories[entry]!),
                      selected: _selected == entry,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _selected = entry),
                    ),
                  ),
              ],
            ),
          ),
          if (filter != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: FilterChip(
                label: const Text('Réalisables'),
                selected: filtering,
                visualDensity: VisualDensity.compact,
                onSelected: filter.onChanged,
              ),
            ),
        ],
      ),
    );

    final selected = _selected;
    final children = <Widget>[
      if (selected != null)
        for (final i in groups[selected] ?? <T>[]) widget.itemBuilder(context, i)
      else ...[
        for (final g in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(widget.categories[g.key]!, style: theme.textTheme.labelLarge),
          ),
          for (final i in g.value) widget.itemBuilder(context, i),
        ],
        for (final i in others) widget.itemBuilder(context, i),
      ],
      if (filter != null && filtering && visible.isEmpty) _empty(theme, filter),
    ];

    return Column(
      children: [
        ?widget.header,
        chips,
        if (fresh > 0)
          InkWell(
            onTap: () => setState(() => _snapshot = current),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                fresh == 1
                    ? '1 nouvel élément réalisable · Actualiser'
                    : '$fresh nouveaux éléments réalisables · Actualiser',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          ),
        Expanded(
          child: ListView(padding: const EdgeInsets.only(bottom: 8), children: children),
        ),
      ],
    );
  }
}

  /// Liste vide : l'élément accessible le plus tôt, au rythme de production actuel.
  Widget _empty(ThemeData theme, RealizableFilter<T> filter) {
    T? best;
    Duration? bestWait;
    for (final i in widget.items) {
      final w = filter.waitFor(i);
      if (w != null && (bestWait == null || w < bestWait)) {
        best = i;
        bestWait = w;
      }
    }
    final next = best;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rien de réalisable', style: theme.textTheme.titleMedium),
          if (next != null && bestWait != null)
            Text(
              '${filter.nameOf(next)} dans ${fmtDuration(bestWait)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: Palette.textSecondary),
            ),
        ],
      ),
    );
  }
}
