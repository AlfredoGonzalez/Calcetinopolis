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
    ..shopLevels.addAll({'detergente': 2, 'suerte': 1})
    ..goalsClaimed.addAll(['own10', 'first_manager'])
    ..dailyDay = '2026-11-03'
    ..dailyStreak = 4
    ..tutorialDone = true
    ..goldButtons = BigNum.fromInt(77)
    ..vip = true
    ..starterBought = true
    ..multLevel = 2
    ..warpDay = '2026-11-03'
    ..warpCount = 2
    ..dailyAdDay = '2026-11-03'
    ..firstReturnDone = true
    ..settings.numberFormat = 'scientific'
    ..settings.fontScale = 1.3
    ..settings.sound = false
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
  expect(b.shopLevels, a.shopLevels);
  expect(b.goalsClaimed, a.goalsClaimed);
  expect(b.dailyDay, a.dailyDay);
  expect(b.dailyStreak, a.dailyStreak);
  expect(b.tutorialDone, a.tutorialDone);
  expect(b.goldButtons, a.goldButtons);
  expect(b.vip, a.vip);
  expect(b.starterBought, a.starterBought);
  expect(b.multLevel, a.multLevel);
  expect(b.warpDay, a.warpDay);
  expect(b.warpCount, a.warpCount);
  expect(b.dailyAdDay, a.dailyAdDay);
  expect(b.firstReturnDone, a.firstReturnDone);
  expect(b.settings.numberFormat, a.settings.numberFormat);
  expect(b.settings.fontScale, a.settings.fontScale);
  expect(b.settings.sound, a.settings.sound);
  expect(b.settings.vibration, a.settings.vibration);
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
      expect(s.shopLevels, isEmpty, reason: 'v0 -> v1 -> v2 encadenadas');
      expect(s.boostSeconds, 0);
      expect(s.businesses[0].owned, 12);
      expect(s.businesses.length, 10, reason: 'rellena negocios nuevos');
    });

    test('migra una v1 (sin tienda) a v2', () {
      final d = jsonEncode({
        'money': '1e3',
        'lifetime': '1e5',
        'businesses': [
          {'owned': 3},
        ],
        'hilvanes': '9',
        'boostSeconds': 0,
      });
      final v1 = jsonEncode({
        'v': 1,
        't': 0,
        'h': SaveCodec.checksum(d),
        'd': d,
      });
      final s = codec.decode(v1).state;
      expect(s.hilvanes, BigNum.fromInt(9));
      expect(s.shopLevels, isEmpty);
    });

    test(
      'migra una v3 (sin monetización) a v4: ya vivió su primer regreso',
      () {
        final d = jsonEncode({
          'money': '1e3',
          'businesses': [
            {'owned': 3},
          ],
          'tutorialDone': true,
        });
        final v3 = jsonEncode({
          'v': 3,
          't': 0,
          'h': SaveCodec.checksum(d),
          'd': d,
        });
        final s = codec.decode(v3).state;
        expect(s.firstReturnDone, isTrue);
        expect(s.vip, isFalse);
        expect(s.multLevel, 0);
        expect(s.goldButtons, BigNum.zero);
      },
    );

    test('migra una v4 a v5: la intro cuenta como vista', () {
      String save(Map<String, dynamic> data) {
        final d = jsonEncode(data);
        return jsonEncode({'v': 4, 't': 0, 'h': SaveCodec.checksum(d), 'd': d});
      }

      final fresh = codec.decode(save({'money': '10'})).state;
      expect(fresh.cutscenesSeen, {'intro'});
      final veteran = codec
          .decode(save({'money': '10', 'pairsClaimed': '5'}))
          .state;
      expect(veteran.cutscenesSeen, {'intro', 'reunion'});
    });

    test('migra una v5 a v6: sin pasos de tutorial vistos', () {
      final d = jsonEncode({'money': '10', 'tutorialDone': true});
      final s = codec
          .decode(
            jsonEncode({'v': 5, 't': 0, 'h': SaveCodec.checksum(d), 'd': d}),
          )
          .state;
      expect(s.tutorialSeen, isEmpty);
      expect(s.tutorialDone, isTrue);
    });

    test('las cutscenes vistas se guardan y se recuperan', () {
      final st = GameState.initial(10)
        ..cutscenesSeen.addAll(['welcome', 'intro']);
      final back = codec.decode(codec.encode(st, DateTime.utc(2026))).state;
      expect(back.cutscenesSeen, {'intro', 'welcome'});
      expect(st.copy().cutscenesSeen, {'intro', 'welcome'});
    });

    test('v0 llega hasta la versión actual encadenando migraciones', () {
      final d = jsonEncode({
        'money': '5',
        'businesses': [
          {'owned': 1},
        ],
      });
      final v0 = jsonEncode({
        'v': 0,
        't': 0,
        'h': SaveCodec.checksum(d),
        'd': d,
      });
      final s = codec.decode(v0).state;
      expect(s.firstReturnDone, isTrue);
      expect(s.tutorialDone, isTrue);
    });

    test('un multiplicador de compra inválido se acota', () {
      final d = jsonEncode({
        'businesses': [
          {'owned': 1},
        ],
        'multLevel': -4,
        'warpCount': -1,
      });
      final env = jsonEncode({
        'v': kSaveVersion,
        't': 0,
        'h': SaveCodec.checksum(d),
        'd': d,
      });
      final s = codec.decode(env).state;
      expect(s.multLevel, 0);
      expect(s.warpCount, 0);
    });

    test('migra una v2 (sin metas ni ajustes) a v3: sin tutorial para quien ya jugaba', () {
      final d = jsonEncode({
        'money': '1e3',
        'lifetime': '1e5',
        'businesses': [
          {'owned': 3},
        ],
        'shop': {'detergente': 1},
      });
      final v2 = jsonEncode({
        'v': 2,
        't': 0,
        'h': SaveCodec.checksum(d),
        'd': d,
      });
      final s = codec.decode(v2).state;
      expect(s.tutorialDone, isTrue);
      expect(s.goalsClaimed, isEmpty);
      expect(s.dailyDay, isNull);
      expect(s.settings.numberFormat, 'shortSuffix');
      expect(s.settings.fontScale, 1.0);
      expect(s.shopLevels, {'detergente': 1});
    });

    test('ajustes inválidos se sanean', () {
      final d = jsonEncode({
        'businesses': [
          {'owned': 1},
        ],
        'settings': {'numberFormat': 'raro', 'fontScale': 99},
        'dailyStreak': -5,
      });
      final env = jsonEncode({
        'v': kSaveVersion,
        't': 0,
        'h': SaveCodec.checksum(d),
        'd': d,
      });
      final s = codec.decode(env).state;
      expect(s.settings.numberFormat, 'shortSuffix');
      expect(s.settings.fontScale, 1.6);
      expect(s.dailyStreak, 0);
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
