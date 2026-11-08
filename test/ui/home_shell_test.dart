import 'dart:io';

import 'package:calcetinopolis/app/game_controller.dart';
import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/app/save_manager.dart';
import 'package:calcetinopolis/services/services.dart';
import 'package:calcetinopolis/ui/home_shell.dart';
import 'package:calcetinopolis/ui/mascot_burst.dart';
import 'package:calcetinopolis/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );
  late GameController c;

  setUp(resetMascotCooldown);

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
    Badge badge() => t.widget<Badge>(find.byKey(const Key('badge-mejoras')));
    expect(badge().isLabelVisible, isFalse);
    c.state.money = BigNum.parse('1e6');
    c.advance(0); // notifica a la UI
    await t.pump();
    expect(badge().isLabelVisible, isTrue);

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

  testWidgets('la pestaña Tienda muestra Botones Dorados y boosts', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Tienda'));
    await t.pump();
    expect(find.byKey(const Key('gold-balance')), findsOneWidget);
    expect(find.byKey(const Key('shop-boost')), findsOneWidget);
  });

  testWidgets('Atrás vuelve a Negocios', (t) async {
    await pumpApp(t);
    await t.tap(find.text('Tienda'));
    await t.pump();
    expect(find.byKey(const Key('gold-balance')), findsOneWidget);
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

  testWidgets('ventana de bienvenida offline: aparece y Recoger paga', (
    t,
  ) async {
    final t0 = DateTime.utc(2026, 11, 3, 12);
    final time = FakeTimeService(t0);
    c = GameController(Economy(config), time: time, lastSeen: t0);
    c.state.tutorialDone = true; // el banner anima en bucle
    c.state.businesses[0]
      ..owned = 10
      ..hasManager = true;
    time.advance(const Duration(hours: 2));
    c.checkOffline(t0);
    final gain = c.pendingOffline!.gain;

    await t.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: HomeShell(controller: c),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('¡Tus calcetines trabajaron!'), findsOneWidget);
    expect(
      find.byKey(const Key('offline-x2')),
      findsNothing,
      reason: 'sin anuncios hasta F7',
    );
    await t.tap(find.byKey(const Key('offline-claim')));
    await t.pumpAndSettle();
    expect(find.text('¡Tus calcetines trabajaron!'), findsNothing);
    expect(c.state.money, gain);
    expect(c.pendingOffline, isNull);
  });

  testWidgets('con anuncios disponibles ofrece Recoger x2', (t) async {
    final t0 = DateTime.utc(2026, 11, 3, 12);
    final time = FakeTimeService(t0);
    c = GameController(
      Economy(config),
      time: time,
      lastSeen: t0,
      ads: MockAdService(),
    );
    c.state.tutorialDone = true; // el banner anima en bucle
    c.state.businesses[0]
      ..owned = 10
      ..hasManager = true;
    time.advance(const Duration(hours: 2));
    c.checkOffline(t0);
    final gain = c.pendingOffline!.gain;

    await t.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: HomeShell(controller: c),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('offline-x2')));
    await t.pumpAndSettle();
    expect(c.state.money, gain.mulDouble(2));
  });

  group('Centrifugado', () {
    Future<void> openTab(WidgetTester t) async {
      await pumpApp(t);
      await t.tap(find.text('Centrifugado'));
      await t.pumpAndSettle();
    }

    testWidgets('sin Parejas por cobrar el botón está inactivo', (t) async {
      await openTab(t);
      expect(
        t.widget<FilledButton>(find.byKey(const Key('centrifuge'))).onPressed,
        isNull,
      );
      expect(find.byKey(const Key('good-time')), findsNothing);
      expect(t.widget<Text>(find.byKey(const Key('pairs-pending'))).data, '+0');
    });

    testWidgets('muestra antes y después, y buen momento', (t) async {
      await openTab(t);
      c.state.lifetimeEarnings = BigNum.parse('1e14');
      c.advance(0);
      await t.pump();
      expect(
        t.widget<Text>(find.byKey(const Key('pairs-pending'))).data,
        '+150',
      );
      expect(t.widget<Text>(find.byKey(const Key('bonus-now'))).data, 'x1');
      expect(t.widget<Text>(find.byKey(const Key('bonus-after'))).data, 'x4');
      expect(find.byKey(const Key('good-time')), findsOneWidget);
    });

    testWidgets('cancelar no cambia nada', (t) async {
      await openTab(t);
      c.state.lifetimeEarnings = BigNum.parse('1e14');
      c.state.money = BigNum.fromInt(500);
      c.advance(0);
      await t.pump();
      await t.tap(find.byKey(const Key('centrifuge')));
      await t.pumpAndSettle();
      expect(find.text('Se pierde:'), findsOneWidget);
      expect(find.text('Se conserva:'), findsOneWidget);
      await t.tap(find.byKey(const Key('cancel-centrifuge')));
      await t.pumpAndSettle();
      expect(c.state.pairsClaimed, BigNum.zero);
      expect(c.state.money, BigNum.fromInt(500));
    });

    testWidgets('confirmar centrifuga, anima (se puede saltar) y da Hilvanes', (
      t,
    ) async {
      await openTab(t);
      c.state.lifetimeEarnings = BigNum.parse('1e14');
      c.state.money = BigNum.fromInt(500);
      c.advance(0);
      await t.pump();
      await t.tap(find.byKey(const Key('centrifuge')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('confirm-centrifuge')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('centrifuge-anim')), findsOneWidget);
      expect(
        find.byKey(const Key('centrifuge-result')),
        findsNothing,
        reason: 'aún animando',
      );
      await t.tap(find.byKey(const Key('centrifuge-anim')));
      await t.pump();
      expect(find.byKey(const Key('centrifuge-result')), findsOneWidget);
      await t.tap(find.byKey(const Key('centrifuge-done')));
      await t.pumpAndSettle();
      expect(c.state.pairsClaimed, BigNum.fromInt(150));
      expect(c.state.hilvanes, BigNum.fromInt(150));
      expect(c.state.money, BigNum.zero);
      expect(t.widget<Text>(find.byKey(const Key('pairs-now'))).data, '150');
    });

    testWidgets('la animación termina sola en 3.5 s', (t) async {
      await openTab(t);
      c.state.lifetimeEarnings = BigNum.parse('1e14');
      c.advance(0);
      await t.pump();
      await t.tap(find.byKey(const Key('centrifuge')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('confirm-centrifuge')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 3600));
      expect(find.byKey(const Key('centrifuge-result')), findsOneWidget);
    });

    testWidgets('tienda: comprar con Hilvanes y botón inactivo sin ellas', (
      t,
    ) async {
      await openTab(t);
      expect(
        t
            .widget<FilledButton>(find.byKey(const Key('shop-detergente')))
            .onPressed,
        isNull,
      );
      c.state.hilvanes = BigNum.fromInt(1000);
      c.advance(0);
      await t.pump();
      await t.tap(find.byKey(const Key('shop-detergente')));
      await t.pump();
      expect(c.economy.shopLevel(c.state, 'detergente'), 1);
      expect(c.state.hilvanes, BigNum.fromInt(600));
      expect(
        t.widget<Text>(find.byKey(const Key('shop-now-detergente'))).data,
        contains('x1.25'),
      );
      expect(c.state.pairsClaimed, BigNum.zero);
    });
  });

  group('Metas', () {
    Future<void> openTab(WidgetTester t) async {
      await pumpApp(t);
      await t.tap(find.text('Metas'));
      await t.pumpAndSettle();
    }

    testWidgets('lista las metas y reclama una cumplida', (t) async {
      await openTab(t);
      expect(find.text('Regalo diario'), findsOneWidget);
      expect(find.text('Primeros 10 Tendederos'), findsOneWidget);
      expect(
        t.widget<FilledButton>(find.byKey(const Key('claim-own10'))).onPressed,
        isNull,
      );
      c.state.businesses[0].owned = 10;
      c.advance(0);
      await t.pump();
      final money = c.state.money;
      await t.tap(find.byKey(const Key('claim-own10')));
      await t.pump();
      expect(c.state.money > money, isTrue);
      expect(find.text('Cobrada'), findsOneWidget);
      expect(find.byKey(const Key('mascot-burst')), findsOneWidget);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('mascot-burst')), findsNothing);
    });

    testWidgets('regalo diario: recoger y volver mañana', (t) async {
      await openTab(t);
      await t.tap(find.byKey(const Key('daily-claim')));
      await t.pump();
      expect(c.state.dailyStreak, 1);
      expect(find.text('Vuelve mañana'), findsOneWidget);
      expect(
        t.widget<FilledButton>(find.byKey(const Key('daily-claim'))).onPressed,
        isNull,
      );
    });

    testWidgets('punto de aviso en la pestaña Metas', (t) async {
      await pumpApp(t);
      Badge badge() => t.widget<Badge>(find.byKey(const Key('badge-metas')));
      expect(
        badge().isLabelVisible,
        isTrue,
        reason: 'regalo diario disponible',
      );
      c.claimDaily();
      await t.pump();
      expect(badge().isLabelVisible, isFalse);
    });
  });

  group('Tutorial', () {
    testWidgets('se ve al inicio y se salta', (t) async {
      await pumpApp(t);
      expect(find.byKey(const Key('tutorial')), findsOneWidget);
      expect(find.textContaining('Paso 1 de 3'), findsOneWidget);
      await t.tap(find.byKey(const Key('tutorial-skip')));
      await t.pump();
      expect(find.byKey(const Key('tutorial')), findsNothing);
    });

    testWidgets('la mascota salta al avanzar un paso y se va sola', (t) async {
      await pumpApp(t);
      expect(find.byKey(const Key('mascot-burst')), findsNothing);
      c.tap(0);
      c.advance(1);
      await t.pump();
      expect(find.byKey(const Key('mascot-burst')), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      expect(find.byKey(const Key('mascot-burst')), findsNothing);
    });

    testWidgets('la celebración espera 30 s antes de repetirse', (t) async {
      var now = DateTime.utc(2026, 11, 8, 12);
      mascotClock = () => now;
      addTearDown(() => mascotClock = DateTime.now);
      await pumpApp(t);
      final ctx = t.element(find.byType(HomeShell));
      playMascot(ctx, MascotMove.celebrate);
      await t.pump();
      expect(find.byKey(const Key('mascot-burst')), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      expect(find.byKey(const Key('mascot-burst')), findsNothing);

      now = now.add(const Duration(seconds: 29));
      playMascot(ctx, MascotMove.celebrate);
      await t.pump();
      expect(find.byKey(const Key('mascot-burst')), findsNothing);

      now = now.add(const Duration(seconds: 2));
      playMascot(ctx, MascotMove.celebrate);
      await t.pump();
      expect(find.byKey(const Key('mascot-burst')), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
    });

    testWidgets('el salto no tiene espera', (t) async {
      await pumpApp(t);
      final ctx = t.element(find.byType(HomeShell));
      playMascot(ctx, MascotMove.jump);
      await t.pump();
      await t.pump(const Duration(seconds: 5));
      playMascot(ctx, MascotMove.jump);
      await t.pump();
      expect(find.byKey(const Key('mascot-burst')), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
    });

    testWidgets('sin animaciones no aparece la mascota', (t) async {
      c = GameController(Economy(config));
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: HomeShell(controller: c),
        ),
      );
      c.tap(0);
      c.advance(1);
      await t.pump();
      expect(find.byKey(const Key('mascot-burst')), findsNothing);
    });

    testWidgets('el texto cambia con el progreso', (t) async {
      await pumpApp(t);
      c.tap(0);
      c.advance(1);
      await t.pump();
      expect(find.textContaining('Paso 2 de 3'), findsOneWidget);
    });
  });

  group('Ajustes', () {
    late MemorySaveService store;

    Future<void> openSettings(WidgetTester t) async {
      store = MemorySaveService();
      c = GameController(
        Economy(config),
        saveManager: SaveManager(store, SaveCodec(config.businesses.length)),
      );
      await t.binding.setSurfaceSize(const Size(400, 1200));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: HomeShell(controller: c),
        ),
      );
      await t.tap(find.byKey(const Key('settings')));
      await t.pumpAndSettle();
    }

    testWidgets('cambiar el formato de números actualiza la pantalla', (
      t,
    ) async {
      await openSettings(t);
      expect(
        t.widget<Text>(find.byKey(const Key('fmt-sample'))).data,
        contains('1.5T'),
      );
      await t.tap(find.byKey(const Key('fmt-scientific')));
      await t.pump();
      expect(
        t.widget<Text>(find.byKey(const Key('fmt-sample'))).data,
        contains('1.5e12'),
      );
      await t.tap(find.byKey(const Key('fmt-names')));
      await t.pump();
      expect(
        t.widget<Text>(find.byKey(const Key('fmt-sample'))).data,
        contains('billón'),
      );
      expect(c.state.settings.numberFormat, 'names');
    });

    testWidgets('interruptores de sonido y vibración', (t) async {
      await openSettings(t);
      await t.tap(find.byKey(const Key('sound')));
      await t.tap(find.byKey(const Key('vibration')));
      await t.pump();
      expect(c.state.settings.sound, isFalse);
      expect(c.state.settings.vibration, isFalse);
    });

    testWidgets('exportar muestra el texto de la partida', (t) async {
      await openSettings(t);
      await t.tap(find.byKey(const Key('export')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('export-text')), findsOneWidget);
    });

    testWidgets('importar un texto inválido avisa y no cambia nada', (t) async {
      await openSettings(t);
      c.state.money = BigNum.fromInt(42);
      await t.tap(find.byKey(const Key('import')));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const Key('import-field')),
        'no es una partida',
      );
      await t.tap(find.byKey(const Key('import-confirm')));
      await t.pumpAndSettle();
      expect(find.textContaining('no es una partida válida'), findsOneWidget);
      expect(c.state.money, BigNum.fromInt(42));
    });

    testWidgets('reiniciar exige escribir REINICIAR', (t) async {
      await openSettings(t);
      c.state.money = BigNum.fromInt(42);
      await t.tap(find.byKey(const Key('reset')));
      await t.pumpAndSettle();
      expect(
        t.widget<TextButton>(find.byKey(const Key('reset-confirm'))).onPressed,
        isNull,
      );
      await t.enterText(find.byKey(const Key('reset-field')), 'reiniciar');
      await t.pump();
      expect(
        t.widget<TextButton>(find.byKey(const Key('reset-confirm'))).onPressed,
        isNotNull,
        reason: 'acepta minúsculas',
      );
      await t.enterText(find.byKey(const Key('reset-field')), 'REINICIA');
      await t.pump();
      expect(
        t.widget<TextButton>(find.byKey(const Key('reset-confirm'))).onPressed,
        isNull,
      );
      await t.enterText(find.byKey(const Key('reset-field')), 'REINICIAR');
      await t.pump();
      await t.tap(find.byKey(const Key('reset-confirm')));
      await t.pumpAndSettle();
      expect(c.state.money, BigNum.zero);
    });

    testWidgets('cancelar el reinicio no borra nada', (t) async {
      await openSettings(t);
      c.state.money = BigNum.fromInt(42);
      await t.tap(find.byKey(const Key('reset')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('reset-cancel')));
      await t.pumpAndSettle();
      expect(c.state.money, BigNum.fromInt(42));
    });
  });
}
