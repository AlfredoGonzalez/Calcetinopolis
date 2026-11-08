import 'dart:convert';

import '../core/state/game_state.dart';
import '../services/services.dart';

/// Versión actual del esquema de guardado. Sube al cambiar el formato y
/// agrega una migración en [SaveCodec._migrations].
const int kSaveVersion = 5;

class SaveData {
  SaveData(this.state, this.savedAt);
  final GameState state;
  final DateTime savedAt;
}

class SaveFormatException implements Exception {
  SaveFormatException(this.message);
  final String message;
  @override
  String toString() => 'SaveFormatException: $message';
}

/// Sobre del guardado: {v, t, h, d}. `h` es un checksum del contenido `d`
/// para detectar archivos corruptos o editados a medias.
class SaveCodec {
  SaveCodec(this.businessCount);
  final int businessCount;

  /// migración[n] convierte un `d` de la versión n a la n+1.
  static final Map<int, Map<String, dynamic> Function(Map<String, dynamic>)>
  _migrations = {
    // v0 -> v1: la v0 no tenía Hilvanes ni boost.
    0: (d) => {
      ...d,
      'hilvanes': d['hilvanes'] ?? '0',
      'boostSeconds': d['boostSeconds'] ?? 0,
    },
    // v1 -> v2: tienda de Hilvanes.
    1: (d) => {...d, 'shop': d['shop'] ?? <String, dynamic>{}},
    // v2 -> v3: metas, regalo diario, tutorial y ajustes. Quien ya jugaba en
    // v2 no necesita el tutorial.
    2: (d) => {...d, 'tutorialDone': d['tutorialDone'] ?? true},
    // v3 -> v4: monetización. Quien ya jugaba en v3 ya vivió su primer regreso.
    3: (d) => {...d, 'firstReturnDone': d['firstReturnDone'] ?? true},
    // v4 -> v5: cutscenes. Quien ya jugaba vio el inicio; el reencuentro solo
    // cuenta como visto si ya había reunido parejas.
    4: (d) {
      final pairs = d['pairsClaimed'];
      final hadPairs = pairs != null && pairs != '0';
      return {
        ...d,
        'cutscenesSeen':
            d['cutscenesSeen'] ?? ['intro', if (hadPairs) 'reunion'],
      };
    },
  };

  static int checksum(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  String encode(
    GameState state,
    DateTime savedAt, {
    int version = kSaveVersion,
  }) {
    final d = jsonEncode(state.toJson());
    return jsonEncode({
      'v': version,
      't': savedAt.millisecondsSinceEpoch,
      'h': checksum(d),
      'd': d,
    });
  }

  SaveData decode(String text) {
    try {
      final env = jsonDecode(text) as Map<String, dynamic>;
      var version = env['v'] as int;
      final d = env['d'] as String;
      if (env['h'] != checksum(d)) {
        throw SaveFormatException('checksum no coincide');
      }
      if (version > kSaveVersion) {
        throw SaveFormatException(
          'guardado de una versión más nueva ($version)',
        );
      }
      var data = jsonDecode(d) as Map<String, dynamic>;
      while (version < kSaveVersion) {
        final m = _migrations[version];
        if (m == null) {
          throw SaveFormatException('sin migración desde v$version');
        }
        data = m(data);
        version++;
      }
      return SaveData(
        GameState.fromJson(data, businessCount),
        DateTime.fromMillisecondsSinceEpoch(env["t"] as int, isUtc: true),
      );
    } on SaveFormatException {
      rethrow;
    } catch (e) {
      throw SaveFormatException('ilegible: $e');
    }
  }
}

class LoadResult {
  LoadResult(this.data, {this.slotUsed, this.recovered = false});
  final SaveData? data;
  final int? slotUsed;

  /// true si la copia más reciente estaba dañada y se restauró una anterior.
  final bool recovered;
}

/// Tres copias rotativas (spec 9.7) + exportar/importar como texto.
class SaveManager {
  SaveManager(this.service, this.codec);
  final SaveService service;
  final SaveCodec codec;

  Future<void> save(GameState state, DateTime now) async {
    final text = codec.encode(state, now);
    // Rotar solo copias sanas: nunca pisar una buena con una dañada.
    final s1 = await service.read(1);
    final s0 = await service.read(0);
    if (s1 != null) await service.write(2, s1);
    if (s0 != null && _valid(s0)) await service.write(1, s0);
    await service.write(0, text);
  }

  bool _valid(String t) {
    try {
      codec.decode(t);
      return true;
    } on SaveFormatException {
      return false;
    }
  }

  Future<LoadResult> load() async {
    var failedBefore = false;
    for (var slot = 0; slot < SaveService.slots; slot++) {
      final text = await service.read(slot);
      if (text == null) continue;
      try {
        return LoadResult(
          codec.decode(text),
          slotUsed: slot,
          recovered: failedBefore,
        );
      } on SaveFormatException {
        failedBefore = true;
      }
    }
    return LoadResult(null);
  }

  /// Texto para copiar y pegar (soporte).
  String export(GameState state, DateTime now) =>
      base64Encode(utf8.encode(codec.encode(state, now)));

  SaveData import(String text) {
    try {
      return codec.decode(utf8.decode(base64Decode(text.trim())));
    } on FormatException catch (e) {
      throw SaveFormatException('texto inválido: ${e.message}');
    }
  }
}
