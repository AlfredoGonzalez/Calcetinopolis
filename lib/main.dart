import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app/game_controller.dart';
import 'app/save_manager.dart';
import 'core/config/economy_config.dart';
import 'core/economy/engine.dart';
import 'services/file_save_service.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = EconomyConfig.fromJsonString(
    await rootBundle.loadString('config/economy.json'),
  );
  final economy = Economy(config);
  final dir = await getApplicationSupportDirectory();
  final manager = SaveManager(
    FileSaveService(dir),
    SaveCodec(config.businesses.length),
  );
  final loaded = await manager.load();
  final controller = GameController(
    economy,
    initial: loaded.data?.state,
    saveManager: manager,
    lastSeen: loaded.data?.savedAt,
  );
  if (loaded.data != null) controller.checkOffline(loaded.data!.savedAt);
  controller.start();
  runApp(CalcetinopolisApp(controller: controller));
}

class CalcetinopolisApp extends StatelessWidget {
  const CalcetinopolisApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        title: 'Calcetinópolis',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(controller.state.settings.fontScale),
          ),
          child: child!,
        ),
        home: HomeShell(controller: controller),
      ),
    );
  }
}
