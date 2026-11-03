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
  final eco = Economy(config);
  late GameState s;
  setUp(() => s = eco.newGame());

  int cost(String id, int level) =>
      config.shop.firstWhere((i) => i.id == id).levels[level].cost.toInt();

  test('comprar gasta Hilvanes, no Parejas, y sube de nivel', () {
    s.pairsClaimed = n('100');
    s.hilvanes = n('1000');
    expect(eco.buyShop(s, 'detergente'), isTrue);
    expect(eco.shopLevel(s, 'detergente'), 1);
    expect(s.hilvanes, n('1000') - BigNum.fromInt(cost('detergente', 0)));
    expect(s.pairsClaimed, n('100'), reason: 'el bono nunca baja');
  });

  test('sin Hilvanes suficientes o al máximo no compra', () {
    expect(eco.buyShop(s, 'detergente'), isFalse);
    s.hilvanes = n('1e12');
    for (var i = 0; i < 4; i++) {
      expect(eco.buyShop(s, 'detergente'), isTrue);
    }
    expect(eco.buyShop(s, 'detergente'), isFalse);
    expect(eco.nextShopLevel(s, 'detergente'), isNull);
  });

  test('Detergente multiplica las ganancias con el nivel', () {
    final base = eco.incomePerCycle(s, 0);
    s.hilvanes = n('1e12');
    eco.buyShop(s, 'detergente');
    expect(
      eco.incomePerCycle(s, 0).toDouble(),
      closeTo(base.toDouble() * 1.25, 1e-9),
    );
    eco.buyShop(s, 'detergente');
    expect(
      eco.incomePerCycle(s, 0).toDouble(),
      closeTo(base.toDouble() * 1.5, 1e-9),
    );
  });

  test('Cesto más grande sube el tope offline (máx. 24 h)', () {
    expect(eco.offlineCapHours(s), 4);
    s.hilvanes = n('1e12');
    eco.buyShop(s, 'cesto_grande');
    expect(eco.offlineCapHours(s), 8);
    eco.buyShop(s, 'cesto_grande');
    eco.buyShop(s, 'cesto_grande');
    expect(eco.offlineCapHours(s), 24);
    s.businesses[0].hasManager = true;
    final gain = eco.offlineGain(s, 100 * 3600);
    expect(gain, eco.managedIncomePerSecond(s).mulDouble(24 * 3600));
  });

  test(
    'Calcetín de la suerte: da Pelusitas al comprarlo y en cada Centrifugado',
    () {
      s.hilvanes = n('1e12');
      eco.buyShop(s, 'suerte');
      expect(s.money, BigNum.fromInt(1000));
      eco.buyShop(s, 'suerte'); // nivel 2: 1e6 en total, no 1e6 + 1e3
      expect(s.money, n('1e6'));
      s.lifetimeEarnings = n('1e14');
      eco.prestige(s);
      expect(s.money, n('1e6'));
    },
  );

  test('Primeras ayudas: managers gratis tras centrifugar', () {
    s.hilvanes = n('1e12');
    eco.buyShop(s, 'ayudantes');
    expect(s.businesses[0].hasManager, isTrue);
    s.businesses[0].hasManager = false;
    s.lifetimeEarnings = n('1e14');
    eco.prestige(s);
    expect(s.businesses[0].hasManager, isTrue);
    expect(
      s.businesses[1].hasManager,
      isFalse,
      reason: 'nivel 1 = solo el primero',
    );
    eco.buyShop(s, 'ayudantes');
    eco.buyShop(s, 'ayudantes');
    expect(s.businesses.take(3).every((b) => b.hasManager), isTrue);
  });

  test('un manager regalado funciona cuando compras la primera unidad', () {
    s.hilvanes = n('1e12');
    for (var i = 0; i < 3; i++) {
      eco.buyShop(s, 'ayudantes');
    }
    s.money = n('1000');
    eco.buy(s, 1, 1);
    eco.tick(s, 10);
    expect(s.businesses[1].progress, isNot(0));
    expect(s.money.isPositive, isTrue);
  });

  test('las mejoras de la tienda sobreviven al Centrifugado', () {
    s.hilvanes = n('1e12');
    eco.buyShop(s, 'detergente');
    eco.buyShop(s, 'cesto_grande');
    s.lifetimeEarnings = n('1e14');
    eco.prestige(s);
    expect(eco.shopLevel(s, 'detergente'), 1);
    expect(eco.shopLevel(s, 'cesto_grande'), 1);
  });

  test('copy() conserva la tienda', () {
    s.hilvanes = n('1e12');
    eco.buyShop(s, 'detergente');
    final c = s.copy();
    expect(c.shopLevels, {'detergente': 1});
    c.shopLevels['detergente'] = 3;
    expect(s.shopLevels['detergente'], 1, reason: 'copia independiente');
  });

  test('la config rechaza tipos y niveles inválidos', () {
    expect(
      () => EconomyConfig.fromJsonString(
        File('config/economy.json')
            .readAsStringSync()
            .replaceFirst('"global_mult"', '"inventado"'),
      ),
      throwsFormatException,
    );
  });
}
