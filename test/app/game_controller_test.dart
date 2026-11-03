import 'dart:io';

import 'package:calcetinopolis/app/game_controller.dart';
import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
