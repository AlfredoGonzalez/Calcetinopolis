import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/game_controller.dart';
import 'core/config/economy_config.dart';
import 'core/economy/engine.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = EconomyConfig.fromJsonString(
    await rootBundle.loadString('config/economy.json'),
  );
  final controller = GameController(Economy(config))..start();
  runApp(CalcetinopolisApp(controller: controller));
}

class CalcetinopolisApp extends StatelessWidget {
  const CalcetinopolisApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calcetinópolis',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeShell(controller: controller),
    );
  }
}
