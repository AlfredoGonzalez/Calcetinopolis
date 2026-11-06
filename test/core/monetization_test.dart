import 'dart:convert';
import 'dart:io';

import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/core/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

BigNum n(String s) => BigNum.parse(s);

void main() {
  final source = File('config/economy.json').readAsStringSync();
  final config = EconomyConfig.fromJsonString(source);
  final eco = Economy(config);
  final now = DateTime(2026, 11, 6, 10);
  late GameState s;

  setUp(() {
    s = eco.newGame();
    s.businesses[0]
      ..owned = 100
      ..hasManager = true;
  });

  group('config', () {
    test('productos de la spec 10.2 con precios en MXN', () {
      final p = {for (final p in config.monetization!.products) p.id: p};
      expect(p['vip']!.priceMxn, 149);
      expect(p['starter']!.priceMxn, 49);
      expect(
        [
          for (final id in ['gold_1', 'gold_2', 'gold_3', 'gold_4'])
            p[id]!.priceMxn,
        ],
        [29, 79, 149, 299],
      );
      expect(
        [
          for (final id in ['mult_1', 'mult_2', 'mult_3']) p[id]!.priceMxn,
        ],
        [99, 199, 349],
      );
      expect(
        config.monetization!.maxMultiplierLevel,
        3,
        reason: 'tope de 3 compras',
      );
    });

    test('no hay cajas aleatorias ni suscripción: solo tipos conocidos', () {
      for (final p in config.monetization!.products) {
        expect(ProductKind.all, contains(p.kind));
      }
    });

    test('rechaza configuraciones inválidas', () {
      Map<String, dynamic> mutate(void Function(List products) f) {
        final m = jsonDecode(source) as Map<String, dynamic>;
        f(m['monetization']['products'] as List);
        return m;
      }

      expect(
        () => EconomyConfig.fromJson(mutate((p) => p[0]['kind'] = 'loot_box')),
        throwsFormatException,
      );
      expect(
        () => EconomyConfig.fromJson(mutate((p) => p[1]['id'] = p[0]['id'])),
        throwsFormatException,
      );
      expect(
        () => EconomyConfig.fromJson(mutate((p) => p[0]['price_mxn'] = 0)),
        throwsFormatException,
      );
      expect(
        () => EconomyConfig.fromJson(
          mutate((p) => p.firstWhere((x) => x['id'] == 'mult_2')['level'] = 5),
        ),
        throwsFormatException,
      );
    });
  });

  group('anuncios (spec 9.10 y 10.1)', () {
    test(
      'no hay anuncios antes del primer regreso ni del primer Centrifugado',
      () {
        expect(eco.adsUnlocked(s), isFalse);
        expect(eco.claimWarpAd(s, now), isNull);
        expect(eco.dailyGoldAdAvailable(s, now), isFalse);
        s.firstReturnDone = true;
        expect(eco.adsUnlocked(s), isTrue);
      },
    );

    test('haber centrifugado también los desbloquea', () {
      s.pairsClaimed = n('5');
      expect(eco.adsUnlocked(s), isTrue);
    });

    test('boost: se puede sumar hasta llenar las 12 h', () {
      expect(eco.canAddBoost(s), isTrue);
      for (var i = 0; i < 3; i++) {
        eco.addBoostView(s);
      }
      expect(s.boostSeconds, 12 * 3600);
      expect(eco.canAddBoost(s), isFalse);
      s.boostSeconds = 7 * 3600;
      expect(eco.canAddBoost(s), isTrue);
      s.boostSeconds = 10 * 3600;
      expect(
        eco.canAddBoost(s),
        isTrue,
        reason: 'suma lo que quepa hasta el tope',
      );
      eco.addBoostView(s);
      expect(s.boostSeconds, 12 * 3600);
    });

    test('saltar espera: 15 min de producción, 3 al día, el día siguiente se renuevan', () {
      s.firstReturnDone = true;
      final rate = eco.managedIncomePerSecond(s);
      final first = eco.claimWarpAd(s, now)!;
      expect(first, rate.mulDouble(15 * 60));
      expect(s.money, first);
      expect(
        s.lifetimeEarnings,
        first,
        reason: 'es producción: cuenta para el prestigio',
      );
      expect(eco.warpAdsLeft(s, now), 2);
      eco.claimWarpAd(s, now);
      eco.claimWarpAd(s, now);
      expect(eco.warpAdsLeft(s, now), 0);
      expect(eco.claimWarpAd(s, now), isNull);
      expect(eco.warpAdsLeft(s, now.add(const Duration(days: 1))), 3);
    });

    test('bono diario de Botones Dorados: una vez al día', () {
      s.firstReturnDone = true;
      expect(eco.claimDailyGoldAd(s, now), config.monetization!.dailyGiftGold);
      expect(s.goldButtons, BigNum.fromInt(config.monetization!.dailyGiftGold));
      expect(eco.claimDailyGoldAd(s, now), isNull);
      expect(
        eco.claimDailyGoldAd(s, now.add(const Duration(days: 1))),
        isNotNull,
      );
    });
  });

  group('saltos con Botones Dorados', () {
    test('cuesta Botones y da producción; sin saldo no pasa nada', () {
      expect(eco.buyWarpWithGold(s, 'warp_1h'), isNull);
      s.goldButtons = n('100');
      final gain = eco.buyWarpWithGold(s, 'warp_4h')!;
      expect(gain, eco.managedIncomePerSecond(s).mulDouble(4 * 3600));
      expect(s.goldButtons, n('65'));
      expect(s.money, gain);
    });

    test('sin negocios con manager no da nada pero cobra (el jugador lo ve en la UI)', () {
      s.businesses[0].hasManager = false;
      s.goldButtons = n('100');
      expect(eco.buyWarpWithGold(s, 'warp_1h'), BigNum.zero);
    });
  });

  group('compras', () {
    test('Pase VIP: una vez', () {
      expect(eco.canBuyProduct(s, 'vip'), isTrue);
      expect(eco.applyProduct(s, 'vip'), isTrue);
      expect(s.vip, isTrue);
      expect(eco.canBuyProduct(s, 'vip'), isFalse);
      expect(eco.applyProduct(s, 'vip'), isFalse);
    });

    test('Botones Dorados: se pueden comprar varias veces y suman', () {
      eco.applyProduct(s, 'gold_2');
      eco.applyProduct(s, 'gold_2');
      expect(s.goldButtons, BigNum.fromInt(180));
      expect(eco.canBuyProduct(s, 'gold_2'), isTrue);
    });

    test(
      'Paquete de inicio: nunca antes del primer Centrifugado y una sola vez',
      () {
        expect(eco.starterAvailable(s), isFalse);
        expect(eco.canBuyProduct(s, 'starter'), isFalse);
        s.pairsClaimed = n('10');
        expect(eco.starterAvailable(s), isTrue);
        final before = eco.multiplier(s, 0);
        eco.applyProduct(s, 'starter');
        expect(s.goldButtons, BigNum.fromInt(50));
        expect(
          eco.multiplier(s, 0).toDouble(),
          closeTo(before.toDouble() * 1.25, 1e-6),
        );
        expect(eco.starterAvailable(s), isFalse);
        expect(eco.applyProduct(s, 'starter'), isFalse);
      },
    );

    test(
      'multiplicador permanente: niveles en orden, tope de 3, x2 cada uno',
      () {
        final base = eco.multiplier(s, 0);
        expect(
          eco.canBuyProduct(s, 'mult_2'),
          isFalse,
          reason: 'primero el nivel 1',
        );
        expect(eco.canBuyProduct(s, 'mult_1'), isTrue);
        eco.applyProduct(s, 'mult_1');
        expect(
          eco.multiplier(s, 0).toDouble(),
          closeTo(base.toDouble() * 2, 1e-6),
        );
        eco.applyProduct(s, 'mult_2');
        eco.applyProduct(s, 'mult_3');
        expect(
          eco.multiplier(s, 0).toDouble(),
          closeTo(base.toDouble() * 8, 1e-6),
        );
        expect(s.multLevel, 3);
        expect(eco.canBuyProduct(s, 'mult_3'), isFalse);
        expect(eco.applyProduct(s, 'mult_1'), isFalse, reason: 'no retrocede');
      },
    );

    test('las compras sobreviven al Centrifugado', () {
      eco.applyProduct(s, 'vip');
      eco.applyProduct(s, 'mult_1');
      eco.applyProduct(s, 'gold_1');
      s.lifetimeEarnings = n('1e14');
      eco.prestige(s);
      expect(s.vip, isTrue);
      expect(s.multLevel, 1);
      expect(s.goldButtons, BigNum.fromInt(30));
    });

    test('restaurar: recupera lo permanente sin regalar el oro del paquete de inicio', () {
      final restored = eco.restoreProducts(s, {
        'vip',
        'starter',
        'mult_1',
        'mult_2',
      });
      expect(restored, 3);
      expect(s.vip, isTrue);
      expect(s.starterBought, isTrue);
      expect(s.multLevel, 2);
      expect(s.goldButtons, BigNum.zero);
      expect(
        eco.restoreProducts(s, {'vip', 'mult_2'}),
        0,
        reason: 'idempotente',
      );
    });
  });

  test('el multiplicador por compras es 1 con partida nueva (el balance no cambia)', () {
    expect(eco.purchasedMultiplier(eco.newGame()), 1);
  });
}
