import 'dart:io';

import 'package:calcetinopolis/app/game_controller.dart';
import 'package:calcetinopolis/app/save_manager.dart';
import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/services/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );
  final t0 = DateTime(2026, 11, 6, 10);

  late MemorySaveService store;
  late FakeTimeService time;
  late MemoryAnalyticsService analytics;
  late MockAdService ads;
  late MockIapService iap;

  GameController make({bool withAds = true, bool unlocked = true}) {
    final c = GameController(
      Economy(config),
      saveManager: SaveManager(store, SaveCodec(config.businesses.length)),
      time: time,
      ads: withAds ? ads : null,
      iap: iap,
      analytics: analytics,
      lastSeen: t0,
    );
    c.state.businesses[0]
      ..owned = 100
      ..hasManager = true;
    c.state.firstReturnDone = unlocked;
    return c;
  }

  setUp(() {
    store = MemorySaveService();
    time = FakeTimeService(t0);
    analytics = MemoryAnalyticsService();
    ads = MockAdService();
    iap = MockIapService(prices: {'vip': '\$149.00 MXN'});
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('anuncios opcionales', () {
    test(
      'boost: solo si el jugador lo pide; suma 4 h y registra analítica',
      () async {
        final c = make();
        expect(c.state.boostSeconds, 0, reason: 'nada se dispara solo');
        expect(await c.watchBoostAd(), isTrue);
        expect(c.state.boostSeconds, 4 * 3600);
        expect(ads.shown, ['boost']);
        final names = analytics.events.map((e) => e.$1).toList();
        expect(
          names,
          containsAllInOrder(['ad_offer_accepted', 'ad_completed']),
        );
      },
    );

    test('si el anuncio no se completa no hay recompensa', () async {
      ads = MockAdService(completes: false);
      final c = make();
      expect(await c.watchBoostAd(), isFalse);
      expect(c.state.boostSeconds, 0);
      expect(analytics.events.any((e) => e.$1 == 'ad_completed'), isFalse);
    });

    test('antes del primer regreso no hay anuncios', () async {
      final c = make(unlocked: false);
      expect(c.canWatchBoost, isFalse);
      expect(await c.watchBoostAd(), isFalse);
      expect(ads.shown, isEmpty);
      expect(await c.watchWarpAd(), isNull);
      expect(await c.watchDailyGoldAd(), isNull);
    });

    test('boost lleno: el botón se bloquea', () async {
      final c = make();
      for (var i = 0; i < 3; i++) {
        await c.watchBoostAd();
      }
      expect(c.state.boostSeconds, 12 * 3600);
      expect(c.canWatchBoost, isFalse);
      expect(await c.watchBoostAd(), isFalse);
      expect(ads.shown.length, 3);
    });

    test('saltar espera: 3 al día', () async {
      final c = make();
      for (var i = 0; i < 3; i++) {
        expect(await c.watchWarpAd(), isNotNull);
      }
      expect(c.warpAdsLeft, 0);
      expect(c.canWatchWarp, isFalse);
      expect(await c.watchWarpAd(), isNull);
      expect(ads.shown.length, 3);
    });

    test('bono diario de Botones Dorados', () async {
      final c = make();
      expect(await c.watchDailyGoldAd(), config.monetization!.dailyGiftGold);
      expect(c.state.goldButtons.isPositive, isTrue);
      expect(c.canWatchDailyGoldAd, isFalse);
    });

    test('sin servicio de anuncios no se ofrece nada', () async {
      final c = make(withAds: false);
      expect(c.canWatchBoost, isFalse);
      expect(c.canWatchWarp, isFalse);
      expect(c.canDoubleOffline, isFalse);
    });

    test('guarda después de cada recompensa', () async {
      final c = make();
      await c.watchBoostAd();
      expect(store.data[0], isNotNull);
    });
  });

  group('Pase VIP', () {
    test('las recompensas se dan sin ver anuncios', () async {
      final c = make();
      c.state.vip = true;
      expect(await c.watchBoostAd(), isTrue);
      expect(await c.watchWarpAd(), isNotNull);
      expect(await c.watchDailyGoldAd(), isNotNull);
      expect(ads.shown, isEmpty, reason: 'VIP no ve anuncios');
      expect(analytics.events.where((e) => e.$1 == 'ad_skipped_vip').length, 3);
    });

    test('VIP funciona aunque no haya servicio de anuncios', () async {
      final c = make(withAds: false);
      c.state.vip = true;
      expect(c.canWatchBoost, isTrue);
      expect(await c.watchBoostAd(), isTrue);
    });

    test('x2 offline gratis con VIP', () async {
      final c = make();
      c.state.vip = true;
      time.advance(const Duration(hours: 1));
      c.checkOffline(t0);
      final gain = c.pendingOffline!.gain;
      await c.claimOffline(doubled: true);
      expect(c.state.money, gain.mulDouble(2));
      expect(ads.shown, isEmpty);
    });
  });

  group('primer regreso', () {
    test('recoger la ganancia offline desbloquea los anuncios', () async {
      final c = make(unlocked: false);
      time.advance(const Duration(hours: 1));
      c.checkOffline(t0);
      expect(c.adsUnlocked, isFalse);
      await c.claimOffline();
      expect(c.state.firstReturnDone, isTrue);
      expect(c.adsUnlocked, isTrue);
    });
  });

  group('compras', () {
    test('comprar aplica el producto, registra y guarda', () async {
      final c = make();
      expect(await c.purchase('vip'), isTrue);
      expect(c.state.vip, isTrue);
      expect(iap.purchases, ['vip']);
      expect(analytics.events.any((e) => e.$1 == 'iap_purchase'), isTrue);
      await settle();
      expect(store.data[0], isNotNull);
    });

    test('si la tienda cancela o falla, el juego no cambia', () async {
      iap = MockIapService(succeeds: false);
      final c = make();
      expect(await c.purchase('vip'), isFalse);
      expect(c.state.vip, isFalse);
      expect(analytics.events.any((e) => e.$1 == 'iap_purchase'), isFalse);
    });

    test(
      'las reglas del juego mandan: no cobra lo que no se puede comprar',
      () async {
        final c = make();
        expect(
          await c.purchase('starter'),
          isFalse,
          reason: 'antes del primer Centrifugado',
        );
        expect(await c.purchase('mult_2'), isFalse, reason: 'falta el nivel 1');
        expect(iap.purchases, isEmpty, reason: 'ni siquiera se llegó a cobrar');
        c.state.vip = true;
        expect(await c.purchase('vip'), isFalse, reason: 'ya lo tiene');
      },
    );

    test('paquete de inicio después del primer Centrifugado', () async {
      final c = make();
      c.state.pairsClaimed = BigNum.fromInt(10);
      expect(await c.purchase('starter'), isTrue);
      expect(c.state.starterBought, isTrue);
      expect(c.state.goldButtons, BigNum.fromInt(50));
      expect(await c.purchase('starter'), isFalse);
    });

    test('sin servicio de compras no pasa nada', () async {
      final c = GameController(Economy(config), time: time);
      expect(await c.purchase('vip'), isFalse);
      expect(await c.restorePurchases(), 0);
    });

    test('restaurar compras', () async {
      iap.owned.addAll({'vip', 'mult_1'});
      final c = make();
      expect(await c.restorePurchases(), 2);
      expect(c.state.vip, isTrue);
      expect(c.state.multLevel, 1);
      expect(await c.restorePurchases(), 0);
    });

    test('precio: el de la tienda, o el de referencia si no lo conoce', () {
      final c = make();
      expect(c.priceOf('vip'), '\$149.00 MXN');
      expect(c.priceOf('gold_1'), '\$29 MXN');
    });

    test('botones dorados para saltar espera', () async {
      final c = make();
      expect(c.canBuyWarpWithGold('warp_1h'), isFalse);
      c.state.goldButtons = BigNum.fromInt(100);
      expect(c.canBuyWarpWithGold('warp_1h'), isTrue);
      final gain = c.buyWarpWithGold('warp_1h');
      expect(gain, isNotNull);
      expect(c.state.goldButtons, BigNum.fromInt(90));
    });
  });

  test('analítica mínima: session_start e iap_view', () {
    final c = make();
    c.start(every: const Duration(days: 1));
    c.logIapView();
    final names = analytics.events.map((e) => e.$1);
    expect(names, containsAll(['session_start', 'iap_view']));
    c.dispose();
  });
}
