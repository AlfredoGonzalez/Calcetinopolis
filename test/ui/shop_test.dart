import 'dart:io';

import 'package:calcetinopolis/app/game_controller.dart';
import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/services/services.dart';
import 'package:calcetinopolis/ui/home_shell.dart';
import 'package:calcetinopolis/ui/test_services.dart';
import 'package:calcetinopolis/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );
  late GameController c;
  late MockAdService ads;
  late MockIapService iap;
  late MemoryAnalyticsService analytics;

  Future<void> openShop(
    WidgetTester t, {
    bool unlocked = true,
    bool testMode = true,
  }) async {
    ads = MockAdService();
    iap = MockIapService();
    analytics = MemoryAnalyticsService();
    c = GameController(
      Economy(config),
      ads: ads,
      iap: iap,
      analytics: analytics,
      testMode: testMode,
    );
    c.state.businesses[0]
      ..owned = 100
      ..hasManager = true;
    c.state.firstReturnDone = unlocked;
    c.state.tutorialDone = true;
    await t.binding.setSurfaceSize(const Size(420, 3600));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: HomeShell(controller: c),
      ),
    );
    await t.tap(find.text('Tienda'));
    await t.pumpAndSettle();
  }

  testWidgets('muestra aviso de modo de prueba solo cuando aplica', (t) async {
    await openShop(t);
    expect(find.byKey(const Key('shop-test-banner')), findsOneWidget);
    await openShop(t, testMode: false);
    expect(find.byKey(const Key('shop-test-banner')), findsNothing);
  });

  testWidgets('registra iap_view al abrir la Tienda', (t) async {
    await openShop(t);
    expect(analytics.events.any((e) => e.$1 == 'iap_view'), isTrue);
  });

  testWidgets('boost con anuncio: suma 4 h y aparece en la barra', (t) async {
    await openShop(t);
    expect(find.byKey(const Key('boost-chip')), findsNothing);
    await t.tap(find.byKey(const Key('shop-boost')));
    await t.pumpAndSettle();
    expect(c.state.boostSeconds, 4 * 3600);
    expect(find.byKey(const Key('boost-chip')), findsOneWidget);
    expect(find.textContaining('Te quedan 4 h'), findsOneWidget);
    expect(ads.shown, ['boost']);
  });

  testWidgets('antes del primer regreso: botones bloqueados y explicación', (
    t,
  ) async {
    await openShop(t, unlocked: false);
    expect(find.byKey(const Key('ads-locked')), findsOneWidget);
    expect(
      t.widget<FilledButton>(find.byKey(const Key('shop-boost'))).onPressed,
      isNull,
    );
    expect(
      t.widget<FilledButton>(find.byKey(const Key('shop-warp-ad'))).onPressed,
      isNull,
    );
  });

  testWidgets('saltar espera con anuncio y con Botones Dorados', (t) async {
    await openShop(t);
    await t.tap(find.byKey(const Key('shop-warp-ad')));
    await t.pumpAndSettle();
    expect(c.state.money.isPositive, isTrue);
    expect(c.warpAdsLeft, 2);

    final before = c.state.money;
    expect(
      t
          .widget<OutlinedButton>(
            find.byKey(const Key('shop-warp-gold-warp_1h')),
          )
          .onPressed,
      isNull,
      reason: 'sin Botones Dorados',
    );
    c.state.goldButtons = BigNum.fromInt(100);
    c.advance(0);
    await t.pump();
    await t.tap(find.byKey(const Key('shop-warp-gold-warp_1h')));
    await t.pump();
    expect(c.state.money > before, isTrue);
    expect(c.state.goldButtons, BigNum.fromInt(90));
  });

  testWidgets('cada producto muestra qué da y su precio en MXN', (t) async {
    await openShop(t);
    expect(find.text('Pase VIP'), findsWidgets);
    expect(find.textContaining('sin suscripción'), findsOneWidget);
    expect(
      find.text('\$149 MXN'),
      findsNWidgets(2),
      reason: 'VIP y frasco de Botones',
    );
    expect(find.text('\$29 MXN'), findsOneWidget);
    expect(find.text('\$349 MXN'), findsOneWidget);
    expect(find.textContaining('250'), findsNothing);
  });

  testWidgets('la oferta de inicio no aparece antes del primer Centrifugado', (
    t,
  ) async {
    await openShop(t);
    expect(find.byKey(const Key('shop-buy-starter')), findsNothing);
    c.state.pairsClaimed = BigNum.fromInt(5);
    c.advance(0);
    await t.pump();
    expect(find.byKey(const Key('shop-buy-starter')), findsOneWidget);
  });

  testWidgets('comprar el Pase VIP', (t) async {
    await openShop(t);
    await t.tap(find.byKey(const Key('shop-buy-vip')));
    await t.pumpAndSettle();
    expect(c.state.vip, isTrue);
    expect(find.text('Activo'), findsOneWidget);
    expect(find.byKey(const Key('shop-buy-vip')), findsNothing);
  });

  testWidgets('multiplicador: niveles en orden y tope de 3', (t) async {
    await openShop(t);
    expect(
      t
          .widget<FilledButton>(find.byKey(const Key('shop-buy-mult_2')))
          .onPressed,
      isNull,
    );
    expect(find.text('Compra el nivel anterior'), findsNWidgets(2));
    await t.tap(find.byKey(const Key('shop-buy-mult_1')));
    await t.pumpAndSettle();
    expect(c.state.multLevel, 1);
    expect(
      t
          .widget<FilledButton>(find.byKey(const Key('shop-buy-mult_2')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Botones Dorados comprados suman al saldo', (t) async {
    await openShop(t);
    await t.tap(find.byKey(const Key('shop-buy-gold_1')));
    await t.pumpAndSettle();
    expect(c.state.goldButtons, BigNum.fromInt(30));
    expect(
      t.widget<Text>(find.byKey(const Key('gold-balance'))).data,
      contains('30'),
    );
    expect(find.byKey(const Key('gold-top')), findsOneWidget);
  });

  testWidgets('restaurar compras', (t) async {
    await openShop(t);
    iap.owned.add('vip');
    await t.ensureVisible(find.byKey(const Key('shop-restore')));
    await t.tap(find.byKey(const Key('shop-restore')));
    await t.pumpAndSettle();
    expect(c.state.vip, isTrue);
    expect(find.text('Se restauraron 1 compras'), findsOneWidget);
  });

  testWidgets(
    'regalo diario: Botones Dorados viendo un anuncio, una vez al día',
    (t) async {
      await openShop(t);
      await t.tap(find.text('Metas'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('daily-gold-ad')));
      await t.pumpAndSettle();
      expect(
        c.state.goldButtons,
        BigNum.fromInt(config.monetization!.dailyGiftGold),
      );
      expect(find.text('Bono de hoy recogido'), findsOneWidget);
      expect(
        t
            .widget<OutlinedButton>(find.byKey(const Key('daily-gold-ad')))
            .onPressed,
        isNull,
      );
    },
  );

  group('servicios de prueba', () {
    testWidgets(
      'anuncio de prueba: hay que esperar para recoger la recompensa',
      (t) async {
        final key = GlobalKey<NavigatorState>();
        final service = TestAdService(key, seconds: 2);
        await t.pumpWidget(
          MaterialApp(
            navigatorKey: key,
            home: const Scaffold(body: SizedBox()),
          ),
        );
        late Future<bool> result;
        result = service.showRewarded('boost');
        await t.pump();
        expect(find.text('Anuncio de prueba'), findsOneWidget);
        expect(
          t
              .widget<FilledButton>(find.byKey(const Key('test-ad-done')))
              .onPressed,
          isNull,
        );
        await t.pump(const Duration(seconds: 3));
        expect(
          t
              .widget<FilledButton>(find.byKey(const Key('test-ad-done')))
              .onPressed,
          isNotNull,
        );
        await t.tap(find.byKey(const Key('test-ad-done')));
        await t.pumpAndSettle();
        expect(await result, isTrue);
      },
    );

    testWidgets('cerrar el anuncio sin recoger no da recompensa', (t) async {
      final key = GlobalKey<NavigatorState>();
      final service = TestAdService(key);
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final result = service.showRewarded('boost');
      await t.pump();
      await t.tap(find.byKey(const Key('test-ad-skip')));
      await t.pumpAndSettle();
      expect(await result, isFalse);
    });

    testWidgets('compra de prueba: confirmar o cancelar, sin cobrar', (
      t,
    ) async {
      final key = GlobalKey<NavigatorState>();
      final service = TestIapService(key, {'vip': 149}, durable: {'vip'});
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      expect(service.priceOf('vip'), '\$149 MXN');
      expect(service.priceOf('nada'), isNull);

      var result = service.purchase('vip');
      await t.pump();
      expect(find.textContaining('No se cobra nada'), findsOneWidget);
      await t.tap(find.byKey(const Key('test-iap-cancel')));
      await t.pumpAndSettle();
      expect(await result, isFalse);
      expect(await service.restore(), isEmpty);

      result = service.purchase('vip');
      await t.pump();
      await t.tap(find.byKey(const Key('test-iap-ok')));
      await t.pumpAndSettle();
      expect(await result, isTrue);
      expect(await service.restore(), {
        'vip',
      }, reason: 'lo permanente se restaura');
    });
  });
}
