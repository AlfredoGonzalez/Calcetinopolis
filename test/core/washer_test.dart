import 'dart:convert';
import 'dart:io';

import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/core/economy/offline.dart';
import 'package:calcetinopolis/core/sim/simulator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('config/economy.json').readAsStringSync();
  final config = EconomyConfig.fromJsonString(source);

  /// Una partida con un negocio con manager, para medir el ingreso.
  (Economy, dynamic) game() {
    final eco = Economy(config);
    final s = eco.newGame();
    s.businesses[0]
      ..owned = 10
      ..hasManager = true;
    return (eco, s);
  }

  double gain(Economy eco, dynamic s, {double dt = 1}) {
    final before = s.money as BigNum;
    eco.tick(s, dt);
    return ((s.money as BigNum) - before).toDouble();
  }

  group('configuración', () {
    test('la lavadora trae valores por defecto: +2% por toque, máx +100%', () {
      expect(config.washer.tapBonus, 0.02);
      expect(config.washer.maxBonus, 1.0);
      expect(config.washer.decayPerSecond, greaterThan(0));
    });

    test('sin sección "washer" usa los valores por defecto', () {
      final j = jsonDecode(source) as Map<String, dynamic>..remove('washer');
      final c = EconomyConfig.fromJson(j);
      expect(c.washer.tapBonus, 0.02);
    });

    test('valores inválidos se rechazan', () {
      final j = jsonDecode(source) as Map<String, dynamic>;
      j['washer'] = {
        'tap_bonus': 2.0,
        'max_bonus': 1.0,
        'decay_per_second': 0.03,
      };
      expect(() => EconomyConfig.fromJson(j), throwsFormatException);
    });

    test('hay mejoras de Hilvanes para el toque y para el máximo', () {
      final types = config.shop.map((e) => e.type).toSet();
      expect(types, containsAll([ShopType.tapPower, ShopType.washerMax]));
    });
  });

  group('factor en vivo', () {
    test('liveFactor suma boost de anuncio y lavadora, igual que tick', () {
      final eco = Economy(config);
      final s = eco.newGame();
      expect(eco.liveFactor(s), 1);
      eco.tapWasher(s);
      expect(eco.liveFactor(s), closeTo(1.02, 1e-9));
      s.boostSeconds = 100;
      expect(eco.liveFactor(s), closeTo(2.02, 1e-9));
    });
  });

  group('toques', () {
    test('cada toque suma su bono y se detiene en el máximo', () {
      final eco = Economy(config);
      final s = eco.newGame();
      eco.tapWasher(s);
      expect(s.washerBonus, closeTo(0.02, 1e-9));
      for (var i = 0; i < 500; i++) {
        eco.tapWasher(s);
      }
      expect(s.washerBonus, closeTo(1.0, 1e-9));
    });

    test('el bono baja solo en cuanto se deja de tocar, sin pasar de cero', () {
      final eco = Economy(config);
      final s = eco.newGame();
      s.washerBonus = 0.5;
      final d = config.washer.decayPerSecond;
      eco.tick(s, 2);
      expect(s.washerBonus, closeTo(0.5 - d * 2, 1e-9));
      eco.tick(s, 1000);
      expect(s.washerBonus, 0);
    });

    test('las mejoras cambian lo que suma cada toque y el máximo', () {
      final eco = Economy(config);
      final s = eco.newGame();
      s.hilvanes = BigNum.fromInt(100000);
      expect(eco.washerTapBonus(s), 0.02);
      expect(eco.washerMaxBonus(s), 1.0);
      expect(eco.buyShop(s, 'pulso'), isTrue);
      expect(eco.washerTapBonus(s), closeTo(0.03, 1e-9));
      expect(eco.buyShop(s, 'tanque'), isTrue);
      expect(eco.washerMaxBonus(s), closeTo(1.5, 1e-9));
      for (var i = 0; i < 500; i++) {
        eco.tapWasher(s);
      }
      expect(s.washerBonus, closeTo(1.5, 1e-9));
    });
  });

  group('ganancias', () {
    test('un bono de +50% sube la producción alrededor de 1.5 veces', () {
      final (eco, a) = game();
      final base = gain(eco, a);
      final (eco2, b) = game();
      b.washerBonus = 0.5;
      final boosted = gain(eco2, b);
      expect(boosted / base, closeTo(1.5, 0.02));
    });

    test('el bono de la lavadora se SUMA al del boost de anuncios', () {
      final (eco, a) = game();
      final base = gain(eco, a);
      final (eco2, b) = game();
      b
        ..boostSeconds = 100.0
        ..washerBonus = 0.5;
      final both = gain(eco2, b);
      // x2 del boost + 0.5 de la lavadora = x2.5 (no x3).
      expect(both / base, closeTo(2.5, 0.03));
    });

    test('sin bono todo sigue igual', () {
      final (eco, a) = game();
      final (eco2, b) = game();
      expect(gain(eco, a), gain(eco2, b));
    });

    test('el bono no cuenta en las ganancias offline', () {
      final (eco, a) = game();
      final (_, b) = game();
      b.washerBonus = 1.0;
      final t0 = DateTime.utc(2026, 11, 3, 12);
      final now = t0.add(const Duration(hours: 1));
      final ra = computeOffline(eco, a, lastSeen: t0, now: now);
      final rb = computeOffline(eco, b, lastSeen: t0, now: now);
      expect(rb.gain, ra.gain);
    });
  });

  group('estado', () {
    test('no se guarda: al volver empieza en cero', () {
      final eco = Economy(config);
      final s = eco.newGame()..washerBonus = 0.7;
      expect(s.toJson().containsKey('washerBonus'), isFalse);
      expect(s.copy().washerBonus, 0.7);
    });
  });

  group('simulador', () {
    test('sin tocar la lavadora el bot sigue igual de rápido', () {
      final base = Simulator(Economy(config)).run(maxRuns: 1);
      final again = Simulator(
        Economy(config),
        washerTapsPerSecond: 0,
      ).run(maxRuns: 1);
      expect(
        again.runs.first.prestigeSuggested,
        base.runs.first.prestigeSuggested,
      );
    });

    test('tocándola sin parar el primer Centrifugado llega antes', () {
      final base = Simulator(Economy(config)).run(maxRuns: 1);
      final active = Simulator(
        Economy(config),
        washerTapsPerSecond: 5,
      ).run(maxRuns: 1);
      expect(
        active.runs.first.prestigeSuggested!,
        lessThan(base.runs.first.prestigeSuggested!),
      );
    });
  });
}
