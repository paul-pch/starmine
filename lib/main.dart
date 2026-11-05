import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/database.dart';
import 'data/game_data_loader.dart';
import 'data/game_repository.dart';
import 'ui/game_controller.dart';
import 'ui/home_shell.dart';
import 'ui/notifications.dart';

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
  runApp(StarmineApp(controller: controller));
}

class StarmineApp extends StatelessWidget {
  const StarmineApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Starmine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF5C451),
          brightness: Brightness.dark,
        ),
      ),
      home: HomeShell(controller: controller),
    );
  }
}
