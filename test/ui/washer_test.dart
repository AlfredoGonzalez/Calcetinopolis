import 'dart:io';

import 'package:calcetinopolis/app/game_controller.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/ui/home_shell.dart';
import 'package:calcetinopolis/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );

  Future<GameController> open(WidgetTester t, {bool reduce = false}) async {
    final c = GameController(Economy(config))..state.tutorialDone = true;
    await t.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        builder: reduce
            ? (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              )
            : null,
        home: HomeShell(controller: c),
      ),
    );
    return c;
  }

  String bonusText(WidgetTester t) =>
      t.widget<Text>(find.byKey(const Key('washer-bonus'))).data!;

  testWidgets('la lavadora arranca en +0% con una invitación a tocar', (
    t,
  ) async {
    await open(t);
    expect(find.byKey(const Key('washer')), findsOneWidget);
    expect(bonusText(t), '+0%');
    expect(
      t.widget<Text>(find.byKey(const Key('washer-hint'))).data,
      contains('¡Toca para lavar!'),
    );
    expect(find.byKey(const Key('washer-chip')), findsNothing);
  });

  testWidgets('cada toque suma 2% y el encabezado lo muestra', (t) async {
    final c = await open(t);
    for (var i = 0; i < 12; i++) {
      await t.tap(find.byKey(const Key('washer')));
      await t.pump(const Duration(milliseconds: 20));
    }
    expect(c.washerBonus, closeTo(0.24, 1e-9));
    expect(bonusText(t), '+24%');
    expect(find.byKey(const Key('washer-chip')), findsOneWidget);
    expect(
      t.widget<Text>(find.byKey(const Key('washer-hint'))).data,
      contains('Se consume si dejas de tocar'),
    );
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('el bono se consume solo cuando se deja de tocar', (t) async {
    final c = await open(t);
    for (var i = 0; i < 20; i++) {
      await t.tap(find.byKey(const Key('washer')));
      await t.pump(const Duration(milliseconds: 10));
    }
    final before = c.washerBonus;
    c.advance(1);
    await t.pump();
    expect(c.washerBonus, lessThan(before));
    // advance() recorta cada paso a 1 s.
    for (var i = 0; i < 40; i++) {
      c.advance(1);
    }
    await t.pump();
    expect(c.washerBonus, 0);
    expect(bonusText(t), '+0%');
    expect(find.byKey(const Key('washer-chip')), findsNothing);
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('la barra se llena y se detiene en el máximo', (t) async {
    final c = await open(t);
    for (var i = 0; i < 150; i++) {
      c.tapWasher();
    }
    await t.pump();
    expect(c.washerFill, 1);
    expect(bonusText(t), '+100%');
    final bar = t.widget<FractionallySizedBox>(
      find.byKey(const Key('washer-bar')),
    );
    expect(bar.widthFactor, 1);
  });

  testWidgets('los pelusas/seg del encabezado suben con el bono', (t) async {
    final c = await open(t);
    c.state.businesses[0]
      ..owned = 5
      ..hasManager = true;
    c.advance(0);
    await t.pump();
    final before = t.widget<Text>(find.byKey(const Key('income-rate'))).data!;
    for (var i = 0; i < 10; i++) {
      await t.tap(find.byKey(const Key('washer')));
      await t.pump(const Duration(milliseconds: 20));
    }
    final after = t.widget<Text>(find.byKey(const Key('income-rate'))).data!;
    expect(after, isNot(before));
  });

  testWidgets('con reducir animaciones también suma, sin rebote', (t) async {
    final c = await open(t, reduce: true);
    await t.tap(find.byKey(const Key('washer')));
    await t.pump();
    expect(c.washerBonus, closeTo(0.02, 1e-9));
  });

  testWidgets('los botones de la derecha no se mueven cuando suben los bonos', (
    t,
  ) async {
    final c = await open(t);
    Offset at(String key) => t.getTopLeft(find.byKey(Key(key)));
    final gold = at('gold-top');
    final pairs = at('pairs-top');
    final settings = at('settings');
    for (var i = 0; i < 40; i++) {
      c.tapWasher();
    }
    c.state.boostSeconds = 3600;
    c.advance(0);
    await t.pump();
    expect(find.byKey(const Key('washer-chip')), findsOneWidget);
    expect(find.byKey(const Key('boost-chip')), findsOneWidget);
    expect(at('gold-top'), gold);
    expect(at('pairs-top'), pairs);
    expect(at('settings'), settings);
  });
}
