import 'package:flutter/material.dart';

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
  });

  /// Clé → libellé, dans l'ordre d'affichage.
  final Map<String, String> categories;
  final List<T> items;
  final String Function(T item) categoryOf;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Au-dessus des puces, hors défilement (carte « En cours »).
  final Widget? header;

  @override
  State<CategorizedList<T>> createState() => _CategorizedListState<T>();
}

class _CategorizedListState<T> extends State<CategorizedList<T>> {
  /// Catégorie sélectionnée, `null` = Tout.
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = {
      for (final c in widget.categories.keys)
        c: [
          for (final i in widget.items)
            if (widget.categoryOf(i) == c) i,
        ],
    }..removeWhere((_, items) => items.isEmpty);
    // Éléments sans catégorie connue : affichés en fin de vue « Tout ».
    final others = [
      for (final i in widget.items)
        if (!widget.categories.containsKey(widget.categoryOf(i))) i,
    ];

    final chips = SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
    ];

    return Column(
      children: [
        ?widget.header,
        chips,
        Expanded(
          child: ListView(padding: const EdgeInsets.only(bottom: 8), children: children),
        ),
      ],
    );
  }
}
