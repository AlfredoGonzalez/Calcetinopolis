import 'dart:io';

import 'package:calcetinopolis/app/game_controller.dart';
import 'package:calcetinopolis/app/save_manager.dart';
import 'package:calcetinopolis/services/services.dart';
import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/core/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  persistenceTests();
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );
  late GameController c;

  setUp(() => c = GameController(Economy(config)));

  test('unidades según la cantidad elegida', () {
    c.state.money = BigNum.parse('1e6');
    expect(c.unitsFor(0), 1);
    c.setAmount(BuyAmount.ten);
    expect(c.unitsFor(0), 10);
    c.setAmount(BuyAmount.hundred);
    expect(c.unitsFor(0), 100);
    c.setAmount(BuyAmount.nextThreshold);
    expect(c.unitsFor(0), 24);
    c.setAmount(BuyAmount.max);
    expect(c.unitsFor(0), c.economy.maxAffordable(c.state, 0));
  });

  test('canBuy, missing y buy', () {
    expect(c.canBuy(0), isFalse);
    expect(c.missing(0).toDouble(), closeTo(4.28, 1e-9));
    c.state.money = BigNum.fromInt(10);
    expect(c.canBuy(0), isTrue);
    c.buy(0);
    expect(c.state.businesses[0].owned, 2);
    expect(c.missing(0), BigNum.zero);
  });

  test('Max sin dinero apunta a 1 y no compra', () {
    c.setAmount(BuyAmount.max);
    expect(c.unitsFor(0), 1);
    expect(c.canBuy(0), isFalse);
  });

  test('advance acota dt grandes y notifica', () {
    var calls = 0;
    c.addListener(() => calls++);
    c.economy.tap(c.state, 0);
    c.advance(50);
    expect(calls, 1);
    expect(c.state.money, BigNum.one);
  });

  test('tap solo notifica si hizo algo', () {
    var calls = 0;
    c.addListener(() => calls++);
    c.tap(0);
    c.tap(0);
    c.tap(3);
    expect(calls, 1);
  });

  test('comprar todos los upgrades asequibles', () {
    c.state.money = BigNum.parse('1e9');
    c.state.businesses[0].owned = 5;
    final bought = c.buyAllAffordableUpgrades();
    expect(bought, greaterThan(0));
    expect(c.state.upgrades.length, bought);
    expect(c.buyAllAffordableUpgrades(), 0);
  });

  test('aviso de mejoras asequibles', () {
    expect(c.hasAffordableUpgrade, isFalse);
    c.state.money = BigNum.fromInt(1000);
    expect(c.hasAffordableUpgrade, isTrue, reason: 'manager del negocio 1');
  });

  test('negocios: revelado y siguiente por desbloquear', () {
    expect(c.isRevealed(0), isTrue);
    expect(c.isNextToUnlock(1), isTrue);
    expect(c.isNextToUnlock(2), isFalse);
    expect(c.isRevealed(2), isFalse);
  });

  test('step usa el reloj real sin romperse', () {
    c.start(every: const Duration(days: 1));
    c.step();
    c.dispose();
  });
}

// ---------------------------------------------------------------- F3
void persistenceTests() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );
  final t0 = DateTime.utc(2026, 11, 3, 12);

  late MemorySaveService store;
  late SaveManager manager;
  late FakeTimeService time;
  late MockAdService ads;
  late MemoryAnalyticsService analytics;

  GameController make({bool withAds = true, GameState? initial}) {
    final c = GameController(
      Economy(config),
      initial: initial,
      saveManager: manager,
      time: time,
      ads: withAds ? ads : null,
      analytics: analytics,
      lastSeen: t0,
    );
    c.state.businesses[0]
      ..owned = 10
      ..hasManager = true;
    return c;
  }

  setUp(() {
    store = MemorySaveService();
    manager = SaveManager(store, SaveCodec(config.businesses.length));
    time = FakeTimeService(t0);
    ads = MockAdService();
    analytics = MemoryAnalyticsService();
  });

  group('offline y guardado', () {
    test('menos de 60 s fuera: no hay ventana', () {
      final c = make();
      time.advance(const Duration(seconds: 30));
      c.checkOffline(t0);
      expect(c.pendingOffline, isNull);
    });

    test('al volver deja la ganancia pendiente y recogerla la suma', () async {
      final c = make();
      time.advance(const Duration(hours: 1));
      c.checkOffline(t0);
      final gain = c.pendingOffline!.gain;
      expect(gain.isPositive, isTrue);
      expect(c.state.money, BigNum.zero, reason: 'no se paga hasta recoger');
      await c.claimOffline();
      expect(c.state.money, gain);
      expect(c.state.lifetimeEarnings, gain, reason: 'cuenta para E_vida');
      expect(c.pendingOffline, isNull);
      expect(analytics.events.single.$1, 'offline_claim');
    });

    test(
      'x2 viendo un anuncio duplica; si el anuncio falla, paga normal',
      () async {
        final c = make();
        time.advance(const Duration(hours: 1));
        c.checkOffline(t0);
        final gain = c.pendingOffline!.gain;
        await c.claimOffline(doubled: true);
        expect(c.state.money, gain.mulDouble(2));
        expect(ads.shown, ['offline_x2']);

        final c2 = GameController(
          Economy(config),
          saveManager: manager,
          time: time,
          ads: MockAdService(completes: false),
          lastSeen: t0,
        );
        c2.state.businesses[0]
          ..owned = 10
          ..hasManager = true;
        c2.checkOffline(t0);
        final g2 = c2.pendingOffline!.gain;
        await c2.claimOffline(doubled: true);
        expect(c2.state.money, g2);
      },
    );

    test('sin servicio de anuncios no hay x2 aunque se pida', () async {
      final c = make(withAds: false);
      time.advance(const Duration(hours: 1));
      c.checkOffline(t0);
      final gain = c.pendingOffline!.gain;
      await c.claimOffline(doubled: true);
      expect(c.state.money, gain);
    });

    test('reloj atrasado: no hay ventana', () {
      final c = make();
      time.advance(const Duration(hours: -5));
      c.checkOffline(t0);
      expect(c.pendingOffline, isNull);
    });

    test('recoger sin pendiente no hace nada', () async {
      final c = make();
      await c.claimOffline();
      expect(c.state.money, BigNum.zero);
    });

    test('pausar guarda; volver calcula lo ganado fuera', () async {
      final c = make();
      await c.onPaused();
      expect(store.data[0], isNotNull);
      time.advance(const Duration(hours: 2));
      c.onResumed();
      expect(c.pendingOffline, isNotNull);
      expect(c.pendingOffline!.secondsAway, closeTo(7200, 1));
    });

    test('no se acumula una segunda ventana si ya hay una pendiente', () {
      final c = make();
      time.advance(const Duration(hours: 1));
      c.onResumed();
      final first = c.pendingOffline;
      time.advance(const Duration(hours: 1));
      c.onResumed();
      expect(identical(c.pendingOffline, first), isTrue);
    });

    test('autoguardado cada 30 s de juego', () async {
      final c = make();
      for (var i = 0; i < 29; i++) {
        c.advance(1);
      }
      expect(store.data, isEmpty);
      c.advance(1);
      await Future<void>.delayed(Duration.zero);
      expect(store.data[0], isNotNull);
    });

    test('guarda al comprar manager o upgrade', () async {
      final c = make();
      c.state.money = BigNum.parse('1e9');
      c.state.businesses[1].owned = 1;
      c.buyManager(1);
      await Future<void>.delayed(Duration.zero);
      expect(store.data[0], isNotNull);
      store.data.clear();
      c.buyUpgrade('all_x3_1');
      await Future<void>.delayed(Duration.zero);
      expect(store.data[0], isNotNull);
    });

    test('un fallo de disco no tumba el juego', () async {
      final c = GameController(
        Economy(config),
        saveManager: SaveManager(_BrokenStore(), SaveCodec(10)),
        time: time,
      );
      await c.save();
      c.advance(1);
    });

    test('guardar y cargar devuelve la misma partida', () async {
      final c = make();
      c.state.money = BigNum.parse('7e7');
      await c.save();
      final loaded = await manager.load();
      expect(loaded.data!.state.money, BigNum.parse('7e7'));
      expect(loaded.data!.savedAt, t0);
    });
  });
}

class _BrokenStore implements SaveService {
  @override
  Future<String?> read(int slot) async =>
      throw const FileSystemException('disco lleno');
  @override
  Future<void> write(int slot, String data) async =>
      throw const FileSystemException('disco lleno');
}
