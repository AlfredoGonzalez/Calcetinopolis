import '../big_num.dart';

class BusinessState {
  BusinessState({
    this.owned = 0,
    this.hasManager = false,
    this.progress = 0,
    this.running = false,
  });

  int owned;
  bool hasManager;

  /// Avance del ciclo, 0..1 (solo visual si hay manager).
  double progress;

  /// Sin manager: el ciclo corre solo si el jugador tocó el negocio.
  bool running;

  Map<String, Object?> toJson() => {
    'owned': owned,
    'manager': hasManager,
    'progress': progress,
    'running': running,
  };

  factory BusinessState.fromJson(Map<String, dynamic> j) => BusinessState(
    owned: (j['owned'] as num?)?.toInt().clamp(0, 1 << 31) ?? 0,
    hasManager: j['manager'] as bool? ?? false,
    progress: ((j['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
    running: j['running'] as bool? ?? false,
  );

  BusinessState copy() => BusinessState(
    owned: owned,
    hasManager: hasManager,
    progress: progress,
    running: running,
  );
}

class GameState {
  GameState({
    required this.businesses,
    BigNum? money,
    BigNum? lifetimeEarnings,
    Set<String>? upgrades,
    BigNum? pairsClaimed,
    BigNum? hilvanes,
    Map<String, int>? shopLevels,
    this.boostSeconds = 0,
  }) : money = money ?? BigNum.zero,
       lifetimeEarnings = lifetimeEarnings ?? BigNum.zero,
       upgrades = upgrades ?? <String>{},
       pairsClaimed = pairsClaimed ?? BigNum.zero,
       hilvanes = hilvanes ?? BigNum.zero,
       shopLevels = shopLevels ?? <String, int>{};

  /// Partida nueva: el primer negocio viene gratis (spec 9.2).
  factory GameState.initial(int businessCount) => GameState(
    businesses: List.generate(
      businessCount,
      (i) => BusinessState(owned: i == 0 ? 1 : 0),
    ),
  );

  BigNum money;

  /// E_vida: todo lo ganado en la vida del jugador (nunca se reinicia).
  BigNum lifetimeEarnings;
  final List<BusinessState> businesses;
  final Set<String> upgrades;

  /// Parejas Reunidas ya cobradas: permanentes, nunca se gastan.
  BigNum pairsClaimed;

  /// Hilvanes: moneda gastable de la tienda de prestigio.
  BigNum hilvanes;

  /// Nivel comprado de cada mejora de la tienda de Hilvanes (permanente).
  final Map<String, int> shopLevels;

  /// Segundos restantes de boost por anuncio.
  double boostSeconds;

  Map<String, Object?> toJson() => {
    'money': money.toJson(),
    'lifetime': lifetimeEarnings.toJson(),
    'businesses': businesses.map((b) => b.toJson()).toList(),
    'upgrades': upgrades.toList()..sort(),
    'pairs': pairsClaimed.toJson(),
    'hilvanes': hilvanes.toJson(),
    'shop': shopLevels,
    'boostSeconds': boostSeconds,
  };

  /// Lee un estado guardado. Tolera campos faltantes y cambios en el número
  /// de negocios (se rellenan o se recortan).
  factory GameState.fromJson(Map<String, dynamic> j, int businessCount) {
    BigNum big(Object? v) {
      final n = BigNum.parse((v ?? '0').toString());
      return n.isNegative ? BigNum.zero : n;
    }

    final saved = (j['businesses'] as List? ?? const [])
        .map((e) => BusinessState.fromJson(e as Map<String, dynamic>))
        .toList();
    final list = List.generate(
      businessCount,
      (i) => i < saved.length ? saved[i] : BusinessState(),
    );
    if (list.first.owned == 0) list.first.owned = 1;
    final boost = (j['boostSeconds'] as num?)?.toDouble() ?? 0;
    return GameState(
      businesses: list,
      money: big(j['money']),
      lifetimeEarnings: big(j['lifetime']),
      upgrades: ((j['upgrades'] as List?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      pairsClaimed: big(j['pairs']),
      hilvanes: big(j['hilvanes']),
      shopLevels: {
        for (final e in ((j['shop'] as Map?) ?? const {}).entries)
          if ((e.value as num) > 0) e.key as String: (e.value as num).toInt(),
      },
      boostSeconds: boost.isNaN || boost < 0 ? 0 : boost,
    );
  }

  GameState copy() => GameState(
    businesses: businesses.map((b) => b.copy()).toList(),
    money: money,
    lifetimeEarnings: lifetimeEarnings,
    upgrades: {...upgrades},
    pairsClaimed: pairsClaimed,
    hilvanes: hilvanes,
    shopLevels: {...shopLevels},
    boostSeconds: boostSeconds,
  );
}
