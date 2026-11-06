import 'dart:io';

import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/core/economy/offline.dart';
import 'package:calcetinopolis/core/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );
  final eco = Economy(config);
  final t0 = DateTime.utc(2026, 11, 3, 12);
  late GameState s;

  setUp(() {
    s = eco.newGame();
    s.businesses[0]
      ..owned = 10
      ..hasManager = true;
  });

  OfflineReport at(Duration away, {double? cap}) =>
      computeOffline(eco, s, lastSeen: t0, now: t0.add(away), capHours: cap);

  test('ganancia = \$/s con manager por el tiempo fuera', () {
    final r = at(const Duration(minutes: 10));
    expect(r.gain, eco.managedIncomePerSecond(s).mulDouble(600));
    expect(r.secondsAway, 600);
    expect(r.capped, isFalse);
  });

  test('tope de 4 h: el exceso se ignora', () {
    final r = at(const Duration(hours: 30));
    expect(r.secondsCounted, 4 * 3600);
    expect(r.capped, isTrue);
    expect(r.gain, eco.managedIncomePerSecond(s).mulDouble(4 * 3600));
  });

  test('adelantar el reloj un año da lo mismo que 4 h', () {
    final trick = at(const Duration(days: 365));
    final honest = at(const Duration(hours: 4));
    expect(trick.gain, honest.gain);
  });

  test('tope ampliado hasta 24 h, nunca más', () {
    expect(at(const Duration(hours: 100), cap: 12).secondsCounted, 12 * 3600);
    expect(at(const Duration(hours: 100), cap: 999).secondsCounted, 24 * 3600);
  });

  test('reloj atrasado: sin ganancia y se marca', () {
    final r = at(const Duration(hours: -3));
    expect(r.gain, BigNum.zero);
    expect(r.clockWentBack, isTrue);
  });

  test('sin managers no hay ganancia offline', () {
    s.businesses[0].hasManager = false;
    expect(at(const Duration(hours: 2)).gain, BigNum.zero);
  });
}
