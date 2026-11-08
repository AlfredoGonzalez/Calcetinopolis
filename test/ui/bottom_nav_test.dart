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
  const labels = ['Mejoras', 'Metas', 'Negocios', 'Centrifugado', 'Tienda'];

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

  double scaleOf(WidgetTester t, String label) {
    final scale = find.descendant(
      of: find.byKey(Key('nav-$label')),
      matching: find.byType(Transform),
    );
    // El primer Transform con escala es el del ícono (translate, rotate, scale).
    final m = t.widget<Transform>(scale.last).transform;
    return m.getMaxScaleOnAxis();
  }

  testWidgets('el orden es Mejoras, Metas, Negocios, Centrifugado, Tienda', (
    t,
  ) async {
    await open(t);
    final xs = [
      for (final l in labels) t.getCenter(find.byKey(Key('nav-$l'))).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));
    expect(xs.toSet().length, 5);
  });

  testWidgets('arranca en Negocios y el botón atrás vuelve a Negocios', (
    t,
  ) async {
    await open(t);
    expect(find.text('Tendedero de pelusas'), findsOneWidget);
    await t.tap(find.byKey(const Key('nav-Metas')));
    await t.pumpAndSettle();
    expect(find.text('Regalo diario'), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Tendedero de pelusas'), findsOneWidget);
  });

  testWidgets('la pestaña elegida se agranda al doble y sube', (t) async {
    await open(t);
    await t.pumpAndSettle();
    expect(scaleOf(t, 'Negocios'), closeTo(2.0, 0.05));
    expect(scaleOf(t, 'Tienda'), closeTo(1.0, 0.01));
    final y0 = t.getTopLeft(find.byKey(const Key('nav-Metas'))).dy;

    await t.tap(find.byKey(const Key('nav-Tienda')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 150));
    // Durante la sacudida el ícono gira.
    final rot = find.descendant(
      of: find.byKey(const Key('nav-Tienda')),
      matching: find.byType(Transform),
    );
    expect(rot, findsWidgets);
    await t.pumpAndSettle();
    expect(scaleOf(t, 'Tienda'), closeTo(2.0, 0.05));
    expect(scaleOf(t, 'Negocios'), closeTo(1.0, 0.05));
    expect(t.getTopLeft(find.byKey(const Key('nav-Metas'))).dy, y0);
  });

  testWidgets('con reducir animaciones cambia sin sacudirse', (t) async {
    await open(t, reduce: true);
    await t.tap(find.byKey(const Key('nav-Tienda')));
    await t.pump();
    expect(scaleOf(t, 'Tienda'), closeTo(2.0, 0.05));
  });
}
