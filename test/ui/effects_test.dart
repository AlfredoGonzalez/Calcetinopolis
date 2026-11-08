import 'dart:io';

import 'package:calcetinopolis/app/game_controller.dart';
import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/ui/effects.dart';
import 'package:calcetinopolis/ui/home_shell.dart';
import 'package:calcetinopolis/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );

  Future<GameController> open(WidgetTester t, {bool reduce = false}) async {
    final c = GameController(Economy(config));
    c.state.tutorialDone = true;
    c.state.businesses[0].owned = 24;
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

  group('umbral', () {
    testWidgets('cruzar el umbral 25 muestra el destello y se apaga', (
      t,
    ) async {
      final c = await open(t);
      expect(find.byKey(const Key('threshold-fx')), findsNothing);
      c.state.businesses[0].owned = 25;
      c.advance(0);
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('threshold-fx')), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('threshold-fx')), findsNothing);
    });

    testWidgets('comprar sin cruzar umbral no destella', (t) async {
      final c = await open(t);
      c.state.businesses[0].owned = 24;
      c.state.businesses[0].owned = 24;
      c.advance(0);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('threshold-fx')), findsNothing);
    });

    testWidgets('con reducir animaciones no destella', (t) async {
      final c = await open(t, reduce: true);
      c.state.businesses[0].owned = 25;
      c.advance(0);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('threshold-fx')), findsNothing);
    });
  });

  group('monedas', () {
    testWidgets('los Botones Dorados destellan al subir', (t) async {
      final c = await open(t);
      c.state.goldButtons = BigNum.fromInt(5);
      c.advance(0);
      await t.pump();
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
      c.state.goldButtons = BigNum.fromInt(20);
      c.advance(0);
      await t.pump();
      await t.pump(const Duration(milliseconds: 250));
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      await t.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('las Pelusitas solo destellan con un premio grande', (t) async {
      final c = await open(t);
      c.state.money = BigNum.fromInt(100);
      c.advance(0);
      await t.pump();
      c.state.money = BigNum.fromInt(110); // ingreso normal
      c.advance(0);
      await t.pump();
      await t.pump(const Duration(milliseconds: 250));
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
      c.state.money = BigNum.fromInt(1000); // premio
      c.advance(0);
      await t.pump();
      await t.pump(const Duration(milliseconds: 250));
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      await t.pump(const Duration(seconds: 2));
    });
  });

  testWidgets('las pelusas de fondo avanzan con el tiempo de juego', (t) async {
    final c = await open(t);
    expect(find.byType(FloatingLint), findsOneWidget);
    final before = t.widget<FloatingLint>(find.byType(FloatingLint)).time;
    c.advance(0.5);
    await t.pump();
    expect(
      t.widget<FloatingLint>(find.byType(FloatingLint)).time,
      before + 0.5,
    );
  });
}
