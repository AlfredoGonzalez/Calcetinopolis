import 'dart:io';

import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/core/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

BigNum n(String s) => BigNum.parse(s);

void main() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );
  late Economy eco;
  late GameState s;

  setUp(() {
    eco = Economy(config);
    s = eco.newGame();
  });

  test('partida nueva: primer negocio gratis, sin dinero', () {
    expect(s.businesses[0].owned, 1);
    expect(s.businesses.skip(1).every((b) => b.owned == 0), isTrue);
    expect(s.money, BigNum.zero);
  });

  group('ciclos', () {
    test('sin manager paga una vez por toque', () {
      eco.tick(s, 5);
      expect(s.money, BigNum.zero);
      expect(eco.tap(s, 0), isTrue);
      expect(eco.tap(s, 0), isFalse, reason: 'ya está corriendo');
      eco.tick(s, 1);
      expect(s.money, BigNum.one);
      eco.tick(s, 10);
      expect(s.money, BigNum.one, reason: 'necesita otro toque');
    });

    test('negocio sin unidades no se puede tocar', () {
      expect(eco.tap(s, 1), isFalse);
    });

    test('con manager la producción es continua e independiente del paso de tiempo', () {
      s.money = n('1e6');
      expect(eco.buyManager(s, 0), isTrue);
      s.money = BigNum.zero;
      s.lifetimeEarnings = BigNum.zero;
      final a = s.copy();
      final b = s.copy();
      eco.tick(a, 10);
      for (var i = 0; i < 1000; i++) {
        eco.tick(b, 0.01);
      }
      expect(a.money.toDouble(), closeTo(10, 1e-6));
      expect(b.money.toDouble(), closeTo(a.money.toDouble(), 1e-6));
    });

    test('ciclo menor a 0.25 s: misma economía, sin saltos', () {
      s.businesses[0].owned = 400; // 6 halvings: ciclo 1/64 s
      s.businesses[0].hasManager = true;
      expect(eco.cycleSeconds(s, 0), lessThan(0.25));
      final perSecond = eco.incomePerSecond(s, 0);
      eco.tick(s, 3);
      expect((s.money / perSecond).toDouble(), closeTo(3, 1e-6));
    });

    test('el progreso visual se mantiene entre 0 y 1', () {
      s.businesses[0].hasManager = true;
      eco.tick(s, 12.34);
      expect(s.businesses[0].progress, inInclusiveRange(0, 1));
    });

    test('dt <= 0 no hace nada', () {
      s.businesses[0].hasManager = true;
      eco.tick(s, 0);
      eco.tick(s, -5);
      expect(s.money, BigNum.zero);
    });
  });

  group('compras', () {
    test('comprar descuenta el costo exacto y no hay descuento por lote', () {
      s.money = n('1000');
      final cost10 = eco.costOf(s, 0, 10);
      expect(eco.buy(s, 0, 10), isTrue);
      expect(s.businesses[0].owned, 11);
      expect((s.money - (n('1000') - cost10)).toDouble().abs(), lessThan(1e-9));
    });

    test('no compra sin dinero ni cantidades inválidas', () {
      expect(eco.buy(s, 0, 1), isFalse);
      s.money = n('1e9');
      expect(eco.buy(s, 0, 0), isFalse);
      expect(eco.buy(s, 0, -3), isFalse);
      expect(eco.buy(s, 0, 5000), isFalse, reason: 'excede max_owned');
    });

    test('Max compra todo lo asequible', () {
      s.money = n('500');
      final m = eco.maxAffordable(s, 0);
      expect(eco.buyMax(s, 0), isTrue);
      expect(s.businesses[0].owned, 1 + m);
      expect(eco.maxAffordable(s, 0), 0);
    });

    test('siguiente umbral', () {
      expect(eco.unitsToNextThreshold(s, 0), 24);
      s.money = n('1e12');
      expect(eco.buyToNextThreshold(s, 0), isTrue);
      expect(s.businesses[0].owned, 25);
      expect(eco.unitsToNextThreshold(s, 0), 25);
      s.businesses[0].owned = 400;
      expect(eco.unitsToNextThreshold(s, 0), isNull);
    });

    test('max_owned limita Max', () {
      s.money = n('1e300');
      eco.buyMax(s, 0);
      expect(s.businesses[0].owned, config.businesses[0].maxOwned);
    });

    test('manager: una vez, solo con unidades y dinero', () {
      expect(eco.buyManager(s, 0), isFalse);
      s.money = n('5000');
      expect(eco.buyManager(s, 1), isFalse, reason: 'sin unidades');
      expect(eco.buyManager(s, 0), isTrue);
      expect(eco.buyManager(s, 0), isFalse, reason: 'ya lo tiene');
      expect(s.money, n('4000'));
    });

    test('upgrade multiplica x3 y se compra una sola vez', () {
      final u = config.upgrades.firstWhere((u) => u.target == 'tendedero');
      s.money = u.cost * n('2');
      final before = eco.incomePerCycle(s, 0);
      expect(eco.buyUpgrade(s, u.id), isTrue);
      expect(eco.incomePerCycle(s, 0), before * n('3'));
      expect(eco.buyUpgrade(s, u.id), isFalse);
    });

    test('upgrade global multiplica a todos los negocios', () {
      final u = config.upgrades.firstWhere((u) => u.target == 'all');
      s.money = u.cost;
      s.businesses[1].owned = 2;
      final a = eco.incomePerCycle(s, 0);
      final b = eco.incomePerCycle(s, 1);
      eco.buyUpgrade(s, u.id);
      expect(eco.incomePerCycle(s, 0), a * n('3'));
      expect(eco.incomePerCycle(s, 1), b * n('3'));
    });
  });

  group('umbrales', () {
    test('cada umbral reduce el ciclo a la mitad', () {
      final base = config.businesses[0].baseCycleSeconds;
      for (final (owned, h) in [
        (1, 0),
        (24, 0),
        (25, 1),
        (50, 2),
        (100, 3),
        (200, 4),
        (300, 5),
        (400, 6),
      ]) {
        s.businesses[0].owned = owned;
        expect(
          eco.cycleSeconds(s, 0),
          closeTo(base / (1 << h), 1e-12),
          reason: '$owned',
        );
      }
    });

    test(
      'umbral global: todos los negocios en el umbral aceleran otra vez',
      () {
        for (final b in s.businesses) {
          b.owned = 25;
        }
        expect(eco.halvings(s, 0), 2);
        s.businesses[3].owned = 24;
        expect(eco.halvings(s, 0), 1);
      },
    );

    test('máximo 12 halvings: 400 de todo', () {
      for (final b in s.businesses) {
        b.owned = 400;
      }
      expect(eco.halvings(s, 9), 12);
      expect(eco.cycleSeconds(s, 9), closeTo(10800 / 4096, 1e-9));
    });

    test('desde 500 cada +100 unidades duplica la ganancia', () {
      expect(eco.profitUnlockMultiplier(499), 1);
      expect(eco.profitUnlockMultiplier(500), 2);
      expect(eco.profitUnlockMultiplier(599), 2);
      expect(eco.profitUnlockMultiplier(600), 4);
      expect(eco.profitUnlockMultiplier(1000), 64);
    });
  });

  group('boost por anuncio', () {
    test('cada vista suma 4 h, máximo 12 h', () {
      for (var i = 0; i < 3; i++) {
        eco.addBoostView(s);
      }
      expect(s.boostSeconds, 12 * 3600);
      eco.addBoostView(s);
      expect(s.boostSeconds, 12 * 3600);
    });

    test('duplica ganancias mientras dura y se consume', () {
      s.businesses[0].hasManager = true;
      eco.addBoostView(s);
      eco.tick(s, 10);
      expect(s.money.toDouble(), closeTo(20, 1e-9));
      expect(s.boostSeconds, 4 * 3600 - 10);
    });

    test('si se acaba a media tick, solo se duplica la parte con boost', () {
      s.businesses[0].hasManager = true;
      s.boostSeconds = 5;
      eco.tick(s, 10);
      expect(s.money.toDouble(), closeTo(15, 1e-9));
      expect(s.boostSeconds, 0);
    });
  });

  group('offline', () {
    setUp(() {
      s.businesses[0].hasManager = true;
      s.businesses[0].owned = 10;
    });

    test('ganancia = \$/s con manager por tiempo fuera', () {
      final rate = eco.managedIncomePerSecond(s);
      expect(eco.offlineGain(s, 600), rate.mulDouble(600));
    });

    test('tope de 4 h por defecto; ampliable hasta 24 h', () {
      final rate = eco.managedIncomePerSecond(s);
      expect(eco.offlineGain(s, 100 * 3600), rate.mulDouble(4 * 3600));
      expect(
        eco.offlineGain(s, 100 * 3600, capHours: 12),
        rate.mulDouble(12 * 3600),
      );
      expect(
        eco.offlineGain(s, 100 * 3600, capHours: 99),
        rate.mulDouble(24 * 3600),
      );
    });

    test('reloj atrasado o NaN no da ganancia', () {
      expect(eco.offlineGain(s, -5000), BigNum.zero);
      expect(eco.offlineGain(s, double.nan), BigNum.zero);
    });

    test('los negocios sin manager no producen offline', () {
      s.businesses[0].hasManager = false;
      expect(eco.offlineGain(s, 3600), BigNum.zero);
    });

    test('no modifica el estado', () {
      eco.offlineGain(s, 3600);
      expect(s.money, BigNum.zero);
    });
  });

  group('prestigio', () {
    test('sin ganancias no hay nada que cobrar', () {
      expect(eco.pairsPending(s), BigNum.zero);
      expect(eco.prestige(s), BigNum.zero);
      expect(s.pairsClaimed, BigNum.zero);
    });

    test('cobra P_total - ya cobradas, usando E_vida', () {
      s.lifetimeEarnings = n('1e14'); // S = 1e14 => 150 parejas
      expect(eco.pairsTotal(s), BigNum.fromInt(150));
      expect(eco.prestige(s), BigNum.fromInt(150));
      expect(s.pairsClaimed, BigNum.fromInt(150));
      // Mismo E_vida: ya no hay nada por cobrar.
      expect(eco.pairsPending(s), BigNum.zero);
      s.lifetimeEarnings = n('4e14'); // 2x sqrt => 300 en total
      expect(eco.pairsPending(s), BigNum.fromInt(150));
    });

    test('1 Hilván por Pareja nueva; las Parejas no se gastan', () {
      s.lifetimeEarnings = n('1e14');
      eco.prestige(s);
      expect(s.hilvanes, BigNum.fromInt(150));
      s.hilvanes = BigNum.zero; // gastar Hilvanes en la tienda
      expect(s.pairsClaimed, BigNum.fromInt(150));
      expect(eco.multiplier(s, 0).toDouble(), closeTo(1 + 150 * 0.02, 1e-9));
    });

    test('reinicia lo que debe y conserva lo que debe', () {
      s.money = n('1e9');
      s.lifetimeEarnings = n('1e14');
      s.upgrades.add('all_x3_1');
      s.businesses[0].owned = 90;
      s.businesses[0].hasManager = true;
      s.businesses[4].owned = 7;
      s.boostSeconds = 999;
      eco.prestige(s);
      expect(s.money, BigNum.zero);
      expect(s.upgrades, isEmpty);
      expect(s.boostSeconds, 0);
      expect(s.businesses[0].owned, 1);
      expect(s.businesses[0].hasManager, isFalse);
      expect(s.businesses[4].owned, 0);
      expect(s.lifetimeEarnings, n('1e14'), reason: 'E_vida nunca se reinicia');
      expect(s.pairsClaimed, BigNum.fromInt(150));
    });

    test('el multiplicador nunca baja al centrifugar', () {
      s.lifetimeEarnings = n('1e14');
      final before = eco.multiplier(s, 0);
      final after = eco.multiplierAfterPrestige(s);
      expect(after > before, isTrue);
      eco.prestige(s);
      expect(eco.multiplier(s, 0) >= before, isTrue);
    });

    test('buen momento: por cobrar >= actuales', () {
      s.lifetimeEarnings = n('1e14');
      expect(eco.isGoodTimeToPrestige(s), isTrue);
      eco.prestige(s);
      expect(eco.isGoodTimeToPrestige(s), isFalse);
      s.lifetimeEarnings =
          n('1e14') * n('2.5'); // 237 total: 87 por cobrar < 150
      expect(eco.isGoodTimeToPrestige(s), isFalse);
      s.lifetimeEarnings = n('1e15'); // 474 total: 324 por cobrar
      expect(eco.isGoodTimeToPrestige(s), isTrue);
    });
  });

  test('determinismo: misma secuencia, mismo resultado', () {
    GameState play() {
      final g = eco.newGame();
      g.money = n('1e7');
      eco.buyMax(g, 0);
      eco.buyManager(g, 0);
      for (var i = 0; i < 500; i++) {
        eco.tick(g, 0.37);
      }
      return g;
    }

    final a = play();
    final b = play();
    expect(a.money, b.money);
    expect(a.lifetimeEarnings, b.lifetimeEarnings);
  });
}
