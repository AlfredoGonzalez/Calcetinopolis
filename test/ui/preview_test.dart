import 'dart:io';

import 'package:calcetinopolis/app/game_controller.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/ui/settings_page.dart';
import 'package:calcetinopolis/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );

  Future<GameController> open(WidgetTester t, {required bool testMode}) async {
    final c = GameController(Economy(config), testMode: testMode);
    await t.binding.setSurfaceSize(const Size(420, 2400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: SettingsPage(controller: c),
      ),
    );
    return c;
  }

  testWidgets('sin modo de prueba no hay vista previa de animaciones', (
    t,
  ) async {
    await open(t, testMode: false);
    expect(find.byKey(const Key('preview-centrifuge')), findsNothing);
  });

  testWidgets('las vistas previas abren sin tocar la partida', (t) async {
    final c = await open(t, testMode: true);
    final money = c.state.money;

    await t.tap(find.byKey(const Key('preview-centrifuge')));
    await t.pump();
    expect(find.byKey(const Key('centrifuge-anim')), findsOneWidget);
    await t.tap(find.byKey(const Key('centrifuge-anim')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('centrifuge-done')));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('preview-offline')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('offline-gain')), findsOneWidget);
    expect(find.byKey(const Key('offline-x2')), findsNothing);
    await t.tap(find.byKey(const Key('offline-claim')));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('preview-mascot')));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Mascota'), findsWidgets);
    await t.tap(find.text('Cerrar'));
    await t.pumpAndSettle();

    expect(c.state.money, money);
    expect(c.state.firstReturnDone, isFalse);
  });
}
