/// Interfaces de servicios (spec 11.2). La UI y los tests usan los mocks
/// hasta la fase de monetización (F7) y nube (F8).
/// Almacén por ranuras (0 = la más reciente). Las implementaciones deben
/// escribir de forma atómica para no dejar archivos a medias.
abstract class SaveService {
  static const slots = 3;
  Future<String?> read(int slot);
  Future<void> write(int slot, String data);
}

abstract class AdService {
  /// Muestra un anuncio recompensado; true si el jugador lo completó.
  Future<bool> showRewarded(String placement);
}

abstract class IapService {
  Future<bool> purchase(String productId);
  Future<void> restore();
}

abstract class AnalyticsService {
  void log(String event, [Map<String, Object?> params = const {}]);
}

abstract class TimeService {
  /// Hora confiable (servidor si hay red; si no, reloj del dispositivo).
  DateTime now();
}

class MemorySaveService implements SaveService {
  final data = <int, String>{};
  @override
  Future<String?> read(int slot) async => data[slot];
  @override
  Future<void> write(int slot, String value) async => data[slot] = value;
}

class MockAdService implements AdService {
  MockAdService({this.completes = true});
  final bool completes;
  final shown = <String>[];
  @override
  Future<bool> showRewarded(String placement) async {
    shown.add(placement);
    return completes;
  }
}

class MockIapService implements IapService {
  final purchased = <String>{};
  @override
  Future<bool> purchase(String productId) async => purchased.add(productId);
  @override
  Future<void> restore() async {}
}

class MemoryAnalyticsService implements AnalyticsService {
  final events = <(String, Map<String, Object?>)>[];
  @override
  void log(String event, [Map<String, Object?> params = const {}]) =>
      events.add((event, params));
}

class DeviceTimeService implements TimeService {
  @override
  DateTime now() => DateTime.now();
}

class FakeTimeService implements TimeService {
  FakeTimeService(this._now);
  DateTime _now;
  void advance(Duration d) => _now = _now.add(d);
  @override
  DateTime now() => _now;
}
