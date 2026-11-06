import 'package:flutter/material.dart';

/// Infobulle mobile : une icône (i) qui ouvre l'explication au tap, dans une feuille du
/// bas. Le Tooltip standard ne s'ouvre qu'à l'appui long, peu découvrable sur téléphone.
class InfoButton extends StatelessWidget {
  const InfoButton({super.key, required this.title, required this.body, this.size = 18});

  final String title;
  final String body;
  final double size;

  static Future<void> show(BuildContext context, {required String title, required String body}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => show(context, title: title, body: body),
      icon: Icon(Icons.info_outline, size: size),
      tooltip: 'Explication',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }
}
