/// Interfaces de servicios (spec 11.2). La UI y los tests usan los mocks
/// hasta la fase de monetización (F7) y nube (F8).
abstract class SaveService {
  Future<String?> load();
  Future<void> save(String data);
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
  String? _data;
  @override
  Future<String?> load() async => _data;
  @override
  Future<void> save(String data) async => _data = data;
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

class FakeTimeService implements TimeService {
  FakeTimeService(this._now);
  DateTime _now;
  void advance(Duration d) => _now = _now.add(d);
  @override
  DateTime now() => _now;
}
