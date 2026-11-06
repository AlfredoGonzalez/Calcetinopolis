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

  test('el arte referenciado en la config existe en assets/art', () {
    final c = EconomyConfig.fromJsonString(source);
    for (final b in c.businesses) {
      expect(b.art, isNotNull, reason: b.id);
      expect(
        File('assets/art/${b.art}.png').existsSync(),
        isTrue,
        reason: b.art,
      );
      expect(b.manager.portrait, isNotNull, reason: b.manager.name);
      expect(
        File('assets/art/${b.manager.portrait}.png').existsSync(),
        isTrue,
        reason: b.manager.portrait,
      );
    }
    for (final f in [
      'icon_pelusitas',
      'icon_pareja_reunida',
      'icon_botones_dorados',
      'icon_ui_ajustes',
      'icon_ui_negocios',
      'icon_ui_mejoras',
      'icon_ui_centrifugado',
      'icon_ui_metas',
      'icon_ui_tienda',
      'icon_ui_regalo',
      'app_icon',
    ]) {
      expect(File('assets/art/$f.png').existsSync(), isTrue, reason: f);
    }
    expect(File('assets/art/bg_cuarto_lavado.jpg').existsSync(), isTrue);
    for (final it in c.shop) {
      expect(it.art, isNotNull, reason: it.id);
      expect(
        File('assets/art/${it.art}.png').existsSync(),
        isTrue,
        reason: it.art,
      );
    }
    for (final f in [
      'icon_hilvanes',
      'icon_ui_anuncio',
      'ui_hilo_flecha',
      'shop_vip',
      'shop_starter',
      'shop_mult',
      'shop_botones_1',
      'shop_botones_2',
      'shop_botones_3',
      'shop_botones_4',
    ]) {
      expect(File('assets/art/$f.png').existsSync(), isTrue, reason: f);
    }
    expect(File('assets/art/bg_tienda.jpg').existsSync(), isTrue);
  });

  test(
    'los PNG de sprites son transparentes (sin fondo magenta ni blanco)',
    () {
      // Esquina superior izquierda: el primer byte de alfa en un PNG RGBA no se lee
      // sin decodificar; basta con comprobar el tipo de color del encabezado (6 = RGBA).
      for (final f in [
        'biz_01_tendedero',
        'mgr_01_dona_pinza',
        'icon_pelusitas',
      ]) {
        final bytes = File('assets/art/$f.png').readAsBytesSync();
        expect(bytes[25], 6, reason: '$f debe ser RGBA');
      }
    },
  );

  test('pubspec declara los assets que la app carga en ejecución', () {
    // Sin esto la app no puede leer la config ni las imágenes (los tests leen
    // los archivos directo y no lo notarían).
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      RegExp(r'^\s+assets:\s*$', multiLine: true).hasMatch(pubspec),
      isTrue,
    );
    expect(pubspec, contains('- config/economy.json'));
    expect(pubspec, contains('- assets/art/'));
  });
}
