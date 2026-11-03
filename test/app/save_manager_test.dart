import 'dart:convert';
import 'dart:io';

import 'package:calcetinopolis/app/save_manager.dart';
import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/state/game_state.dart';
import 'package:calcetinopolis/services/file_save_service.dart';
import 'package:calcetinopolis/services/services.dart';
import 'package:flutter_test/flutter_test.dart';

GameState sample() {
  final s = GameState.initial(10)
    ..money = BigNum.parse('1.5e40')
    ..lifetimeEarnings = BigNum.parse('3e45')
    ..pairsClaimed = BigNum.fromInt(120)
    ..hilvanes = BigNum.fromInt(70)
    ..boostSeconds = 1234.5
    ..upgrades.addAll(['all_x3_1', 'tendedero_x3_1']);
  s.businesses[0]
    ..owned = 321
    ..hasManager = true
    ..progress = 0.25;
  s.businesses[3]
    ..owned = 7
    ..running = true
    ..progress = 0.5;
  return s;
}

void expectSame(GameState a, GameState b) {
  expect(b.money, a.money);
  expect(b.lifetimeEarnings, a.lifetimeEarnings);
  expect(b.pairsClaimed, a.pairsClaimed);
  expect(b.hilvanes, a.hilvanes);
  expect(b.boostSeconds, a.boostSeconds);
  expect(b.upgrades, a.upgrades);
  for (var i = 0; i < a.businesses.length; i++) {
    expect(b.businesses[i].owned, a.businesses[i].owned, reason: '$i');
    expect(b.businesses[i].hasManager, a.businesses[i].hasManager);
    expect(b.businesses[i].running, a.businesses[i].running);
    expect(b.businesses[i].progress, a.businesses[i].progress);
  }
}

void main() {
  final codec = SaveCodec(10);
  final t0 = DateTime.utc(2026, 11, 3, 12);

  group('SaveCodec', () {
    test('ida y vuelta conserva todo, incluso números > 1e308', () {
      final d = codec.decode(codec.encode(sample(), t0));
      expectSame(sample(), d.state);
      expect(d.savedAt, t0);
    });

    test('detecta corrupción con el checksum', () {
      final text = codec.encode(sample(), t0);
      final env = jsonDecode(text) as Map<String, dynamic>;
      env['d'] = (env['d'] as String).replaceFirst('321', '999');
      expect(
        () => codec.decode(jsonEncode(env)),
        throwsA(isA<SaveFormatException>()),
      );
      expect(
        () => codec.decode(text.substring(0, 20)),
        throwsA(isA<SaveFormatException>()),
      );
      expect(() => codec.decode('basura'), throwsA(isA<SaveFormatException>()));
      expect(() => codec.decode('{}'), throwsA(isA<SaveFormatException>()));
    });

    test('migra una v0 (sin Hilvanes ni boost) a la versión actual', () {
      final d = jsonEncode({
        'money': '5e3',
        'lifetime': '9e9',
        'businesses': [
          {'owned': 12, 'manager': true, 'progress': 0.1, 'running': false},
        ],
        'upgrades': <String>[],
        'pairs': '10',
      });
      final v0 = jsonEncode({
        'v': 0,
        't': t0.millisecondsSinceEpoch,
        'h': SaveCodec.checksum(d),
        'd': d,
      });
      final s = codec.decode(v0).state;
      expect(s.money, BigNum.parse('5e3'));
      expect(s.hilvanes, BigNum.zero);
      expect(s.boostSeconds, 0);
      expect(s.businesses[0].owned, 12);
      expect(s.businesses.length, 10, reason: 'rellena negocios nuevos');
    });

    test('rechaza guardados de una versión más nueva', () {
      final d = jsonEncode(sample().toJson());
      final fut = jsonEncode({
        'v': kSaveVersion + 1,
        't': 0,
        'h': SaveCodec.checksum(d),
        'd': d,
      });
      expect(() => codec.decode(fut), throwsA(isA<SaveFormatException>()));
    });

    test('saneo: negativos y NaN no entran al juego', () {
      final d = jsonEncode({
        'money': '-5e3',
        'lifetime': '0',
        'businesses': [
          {'owned': -4, 'progress': 7.0},
        ],
        'boostSeconds': -10,
      });
      final env = jsonEncode({
        'v': kSaveVersion,
        't': 0,
        'h': SaveCodec.checksum(d),
        'd': d,
      });
      final s = codec.decode(env).state;
      expect(s.money, BigNum.zero);
      expect(
        s.businesses[0].owned,
        1,
        reason: 'el primer negocio siempre existe',
      );
      expect(s.businesses[0].progress, 1.0);
      expect(s.boostSeconds, 0);
    });

    test('si el juego tiene menos negocios que el guardado, recorta', () {
      final small = SaveCodec(4).decode(codec.encode(sample(), t0));
      expect(small.state.businesses.length, 4);
    });
  });

  group('SaveManager', () {
    late MemorySaveService store;
    late SaveManager m;
    setUp(() {
      store = MemorySaveService();
      m = SaveManager(store, codec);
    });

    test('sin guardado devuelve null', () async {
      expect((await m.load()).data, isNull);
    });

    test('mantiene 3 copias rotativas, la más nueva en la ranura 0', () async {
      for (var i = 1; i <= 4; i++) {
        final s = GameState.initial(10)..money = BigNum.fromInt(i);
        await m.save(s, t0.add(Duration(minutes: i)));
      }
      expect(store.data.length, 3);
      BigNum money(int slot) => codec.decode(store.data[slot]!).state.money;
      expect(money(0), BigNum.fromInt(4));
      expect(money(1), BigNum.fromInt(3));
      expect(money(2), BigNum.fromInt(2));
    });

    test('si la copia nueva está dañada, restaura la anterior', () async {
      await m.save(GameState.initial(10)..money = BigNum.fromInt(1), t0);
      await m.save(GameState.initial(10)..money = BigNum.fromInt(2), t0);
      store.data[0] = '{"v":1,"corrupto';
      final r = await m.load();
      expect(r.recovered, isTrue);
      expect(r.slotUsed, 1);
      expect(r.data!.state.money, BigNum.fromInt(1));
    });

    test('no rota una copia dañada encima de una sana', () async {
      await m.save(GameState.initial(10)..money = BigNum.fromInt(1), t0);
      await m.save(GameState.initial(10)..money = BigNum.fromInt(2), t0);
      store.data[0] = 'dañada';
      await m.save(GameState.initial(10)..money = BigNum.fromInt(3), t0);
      expect(codec.decode(store.data[0]!).state.money, BigNum.fromInt(3));
      expect(
        codec.decode(store.data[1]!).state.money,
        BigNum.fromInt(1),
        reason: 'la sana no se pisó con la dañada',
      );
    });

    test('todas dañadas: no truena, devuelve null', () async {
      for (var i = 0; i < 3; i++) {
        store.data[i] = 'x$i';
      }
      expect((await m.load()).data, isNull);
    });

    test('exportar e importar como texto', () {
      final text = m.export(sample(), t0);
      expectSame(sample(), m.import(text).state);
      expect(
        () => m.import('esto no es base64!!'),
        throwsA(isA<SaveFormatException>()),
      );
      expect(
        () => m.import(base64Encode(utf8.encode('hola'))),
        throwsA(isA<SaveFormatException>()),
      );
    });
  });

  test('FileSaveService escribe y lee, y sobrescribe', () async {
    final dir = await Directory.systemTemp.createTemp('calcetin_test');
    addTearDown(() => dir.delete(recursive: true));
    final f = FileSaveService(Directory('${dir.path}/sub'));
    expect(await f.read(0), isNull);
    await f.write(0, 'uno');
    await f.write(0, 'dos');
    expect(await f.read(0), 'dos');
    expect(
      Directory('${dir.path}/sub')
          .listSync()
          .where((e) => e.path.endsWith('.tmp')),
      isEmpty,
    );
  });
}
