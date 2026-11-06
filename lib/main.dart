import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app/game_controller.dart';
import 'app/save_manager.dart';
import 'core/config/economy_config.dart';
import 'core/economy/engine.dart';
import 'services/file_save_service.dart';
import 'services/prefs_save_service.dart';
import 'services/services.dart';
import 'ui/home_shell.dart';
import 'ui/test_services.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = EconomyConfig.fromJsonString(
    await rootBundle.loadString('config/economy.json'),
  );
  final economy = Economy(config);
  // Web: localStorage. Android: archivos con escritura atómica.
  final SaveService store = kIsWeb
      ? await PrefsSaveService.create()
      : FileSaveService(await getApplicationSupportDirectory());
  final manager = SaveManager(store, SaveCodec(config.businesses.length));
  final loaded = await manager.load();
  // F7 en modo de prueba: anuncios y compras simulados (los reales llegan en F8).
  final navigatorKey = GlobalKey<NavigatorState>();
  final products = config.monetization?.products ?? const <ProductConfig>[];
  final iap = TestIapService(
    navigatorKey,
    {for (final p in products) p.id: p.priceMxn},
    durable: {
      for (final p in products)
        if (p.isDurable) p.id,
    },
  );
  await iap.load({for (final p in products) p.id});
  final controller = GameController(
    economy,
    initial: loaded.data?.state,
    saveManager: manager,
    lastSeen: loaded.data?.savedAt,
    ads: TestAdService(navigatorKey),
    iap: iap,
    testMode: true,
  );
  if (loaded.data != null) controller.checkOffline(loaded.data!.savedAt);
  controller.start();
  runApp(CalcetinopolisApp(controller: controller, navigatorKey: navigatorKey));
}

class CalcetinopolisApp extends StatelessWidget {
  const CalcetinopolisApp({
    super.key,
    required this.controller,
    this.navigatorKey,
  });

  final GameController controller;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
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
