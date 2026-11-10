import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/database.dart';
import 'data/game_data_loader.dart';
import 'data/game_repository.dart';
import 'ui/game_controller.dart';
import 'ui/home_shell.dart';
import 'ui/notifications.dart';
import 'ui/theme.dart';
import 'ui/visuals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = parseGameData(await rootBundle.loadString(gameDataAsset));
  final notifier = LocalBuildNotifier();
  await notifier.init();
  final controller = GameController(
    repository: GameRepository(StarmineDatabase.open()),
    data: data,
    notifier: notifier,
  );
  await controller.init();
  runApp(StarmineApp(controller: controller, visuals: await Visuals.load(rootBundle)));
}

class StarmineApp extends StatelessWidget {
  const StarmineApp({super.key, required this.controller, this.visuals = const Visuals()});

  final GameController controller;
  final Visuals visuals;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Starmine',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Au-dessus du Navigator : les feuilles, popovers et écrans poussés voient les images
      // (spec 11) ; l'ambiance suit le contrôleur.
      builder: (context, child) => ListenableBuilder(
        listenable: controller,
        builder: (_, _) => VisualsScope(
          visuals: visuals.withAmbiance(controller.ambiance),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: HomeShell(controller: controller, visuals: visuals),
    );
  }
}
