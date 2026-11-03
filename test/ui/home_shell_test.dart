import 'dart:io';

import 'package:calcetinopolis/app/game_controller.dart';
import 'package:calcetinopolis/core/big_num.dart';
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
  late GameController c;

  Future<void> pumpApp(WidgetTester t) async {
    c = GameController(Economy(config));
    await t.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: HomeShell(controller: c),
      ),
    );
  }

  testWidgets('arranca con Negocios, monedas y 5 pestañas', (t) async {
    await pumpApp(t);
    expect(find.text('Tendedero de pelusas'), findsOneWidget);
    for (final label in [
      'Negocios',
      'Mejoras',
      'Centrifugado',
      'Metas',
      'Tienda',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byKey(const Key('money')), findsOneWidget);
  });

  testWidgets('toca el negocio, pasa el ciclo y gana pelusitas', (t) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('card-0')));
    c.advance(1);
    await t.pump();
    expect(c.state.money, BigNum.one);
    expect(
      find.descendant(
        of: find.byKey(const Key('money')),
        matching: find.text('1'),
      ),
      findsNothing,
    );
    expect(t.widget<Text>(find.byKey(const Key('money'))).data, '1');
  });

  testWidgets('comprar atenuado sin dinero muestra lo que falta', (t) async {
    await pumpApp(t);
    expect(find.textContaining('Faltan 4.28'), findsOneWidget);
    await t.tap(find.byKey(const Key('buy-0')));
    await t.pump();
    expect(c.state.businesses[0].owned, 1);
  });

  testWidgets('comprar con dinero sube la cantidad', (t) async {
    await pumpApp(t);
    c.state.money = BigNum.fromInt(100);
    c.setAmount(BuyAmount.ten);
    await t.pump();
    await t.tap(find.byKey(const Key('buy-0')));
    await t.pump();
    expect(c.state.businesses[0].owned, 11);
    expect(t.widget<Text>(find.byKey(const Key('owned-0'))).data, 'x11');
  });

  testWidgets('el selector de cantidad se recuerda para toda la lista', (
    t,
  ) async {
    await pumpApp(t);
    await t.tap(find.byKey(const Key('amount-hundred')));
    await t.pump();
    expect(c.amount, BuyAmount.hundred);
    expect(find.text('Comprar 100'), findsWidgets);
  });

  testWidgets('negocios no desbloqueados son silueta con costo', (t) async {
    await pumpApp(t);
    await t.scrollUntilVisible(
      find.text('???').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('???'), findsWidgets);
    expect(find.byIcon(Icons.lock), findsWidgets);
  });

  testWidgets('comprar manager desde la tarjeta', (t) async {
    await pumpApp(t);
    c.state.money = BigNum.fromInt(1000);
    c.advance(0); // notifica a la UI
    await t.pump();
    await t.tap(find.byKey(const Key('manager-0')));
    await t.pump();
    expect(c.state.businesses[0].hasManager, isTrue);
    expect(find.text('Manager ✓'), findsOneWidget);
  });

  testWidgets('con manager la barra avanza sola', (t) async {
    await pumpApp(t);
    c.state.businesses[0].hasManager = true;
    c.advance(0.5);
    await t.pump();
    expect(c.state.money.toDouble(), closeTo(0.5, 1e-9));
  });

  testWidgets('pestaña Mejoras: punto de aviso y compras', (t) async {
    await pumpApp(t);
    expect(find.byType(Badge), findsOneWidget);
    expect(t.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    c.state.money = BigNum.parse('1e6');
    c.advance(0); // notifica a la UI
    await t.pump();
    expect(t.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);

    await t.tap(find.text('Mejoras'));
    await t.pumpAndSettle();
    expect(find.text('Doña Pinza'), findsOneWidget);
    await t.tap(find.byKey(const Key('mgr-tab-0')));
    await t.pump();
    expect(c.state.businesses[0].hasManager, isTrue);

    await t.tap(find.text('Upgrades'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('buy-all-upgrades')));
    await t.pump();
    expect(c.state.upgrades, isNotEmpty);

    await t.tap(find.text('Umbrales'));
    await t.pumpAndSettle();
    expect(find.text('Tendedero de pelusas'), findsOneWidget);
  });

  testWidgets('pestañas futuras muestran marcador', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Centrifugado'));
    await t.pump();
    expect(find.text('Llega en F4.'), findsOneWidget);
  });

  testWidgets('Atrás vuelve a Negocios', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Tienda'));
    await t.pump();
    expect(find.text('Llega en F7.'), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pump();
    expect(find.text('Tendedero de pelusas'), findsOneWidget);
  });

  testWidgets('ciclos menores a 0.25 s muestran \$/s con la barra llena', (
    t,
  ) async {
    await pumpApp(t);
    c.state.businesses[0]
      ..owned = 400
      ..hasManager = true;
    c.advance(0);
    await t.pump();
    expect(find.textContaining('/s'), findsWidgets);
    final bar = t.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator).first,
    );
    expect(bar.value, 1);
  });
}
