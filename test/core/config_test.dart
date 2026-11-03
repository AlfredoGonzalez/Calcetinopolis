import 'dart:convert';
import 'dart:io';

import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('config/economy.json').readAsStringSync();

  test('carga config/economy.json con los 10 negocios de 9.2', () {
    final c = EconomyConfig.fromJsonString(source);
    expect(c.businesses.length, 10);
    final first = c.businesses.first;
    expect(first.name, 'Tendedero de pelusas');
    expect(first.baseCost, BigNum.fromInt(4));
    expect(first.coefficient, 1.07);
    expect(first.baseCycleSeconds, 1);
    expect(first.manager.name, 'Doña Pinza');
    expect(first.manager.cost, BigNum.fromInt(1000));
    final last = c.businesses.last;
    expect(last.baseCycleSeconds, 10800);
    expect(last.baseIncome, BigNum.parse('9e9'));
    expect(last.manager.cost, BigNum.parse('3e11'));
    expect(c.thresholds, [25, 50, 100, 200, 300, 400]);
    expect(c.prestige.base, 150);
    expect(c.offline.baseCapHours, 4);
    expect(c.offline.maxCapHours, 24);
  });

  test('los costos de negocios crecen y los coeficientes bajan', () {
    final c = EconomyConfig.fromJsonString(source);
    for (var i = 1; i < c.businesses.length; i++) {
      expect(c.businesses[i].baseCost > c.businesses[i - 1].baseCost, isTrue);
      expect(
        c.businesses[i].baseCycleSeconds >=
            c.businesses[i - 1].baseCycleSeconds,
        isTrue,
      );
      // El negocio 1 (1.07) es la excepción, igual que Lemonade en AdCap.
      if (i > 1) {
        expect(
          c.businesses[i].coefficient <= c.businesses[i - 1].coefficient,
          isTrue,
        );
      }
    }
  });

  test(
    'todos los upgrades apuntan a un negocio válido y no hay ids repetidos',
    () {
      final c = EconomyConfig.fromJsonString(source);
      final ids = c.businesses.map((b) => b.id).toSet();
      for (final u in c.upgrades) {
        expect(
          u.target == 'all' || ids.contains(u.target),
          isTrue,
          reason: u.id,
        );
      }
      expect(c.upgrades.map((u) => u.id).toSet().length, c.upgrades.length);
    },
  );

  Map<String, dynamic> mutated(void Function(Map<String, dynamic>) f) {
    final m = jsonDecode(source) as Map<String, dynamic>;
    f(m);
    return m;
  }

  test('rechaza configuraciones inválidas', () {
    expect(
      () => EconomyConfig.fromJson(
        mutated((m) => (m['businesses'] as List)[0]['coefficient'] = 1.0),
      ),
      throwsFormatException,
    );
    expect(
      () => EconomyConfig.fromJson(
        mutated((m) => (m['businesses'] as List)[1]['id'] = 'tendedero'),
      ),
      throwsFormatException,
    );
    expect(
      () => EconomyConfig.fromJson(
        mutated((m) => (m['upgrades'] as List)[0]['target'] = 'nada'),
      ),
      throwsFormatException,
    );
    expect(
      () =>
          EconomyConfig.fromJson(mutated((m) => m['prestige']['scale'] = '0')),
      throwsFormatException,
    );
    expect(
      () => EconomyConfig.fromJson(
        mutated((m) => m['unlocks']['speed_thresholds'] = [50, 25]),
      ),
      throwsFormatException,
    );
  });
}
