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

/// Compras dentro de la app. El precio visible lo da la tienda (spec 10.2).
abstract class IapService {
  /// Consulta los productos a la tienda. Debe llamarse antes de [priceOf].
  Future<void> load(Set<String> productIds);

  /// Precio con formato de la tienda (por ejemplo "$149.00 MXN"), o null si
  /// la tienda no lo conoce.
  String? priceOf(String productId);

  /// true si la compra se completó y ya se cobró.
  Future<bool> purchase(String productId);

  /// Productos permanentes que el jugador ya compró en la tienda.
  Future<Set<String>> restore();
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
  MockIapService({Map<String, String>? prices, this.succeeds = true})
    : _prices = prices ?? {};

  final Map<String, String> _prices;
  final bool succeeds;

  /// Compras realizadas (consumibles incluidos, en orden).
  final purchases = <String>[];

  /// Lo que la tienda devolvería al restaurar (productos permanentes).
  final owned = <String>{};
  var loaded = <String>{};

  @override
  Future<void> load(Set<String> productIds) async => loaded = productIds;

  @override
  String? priceOf(String productId) => _prices[productId];

  @override
  Future<bool> purchase(String productId) async {
    if (!succeeds) return false;
    purchases.add(productId);
    return true;
  }

  @override
  Future<Set<String>> restore() async => {...owned};
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
