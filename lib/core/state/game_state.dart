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
    this.boostSeconds = 0,
  }) : money = money ?? BigNum.zero,
       lifetimeEarnings = lifetimeEarnings ?? BigNum.zero,
       upgrades = upgrades ?? <String>{},
       pairsClaimed = pairsClaimed ?? BigNum.zero,
       hilvanes = hilvanes ?? BigNum.zero;

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

  /// Segundos restantes de boost por anuncio.
  double boostSeconds;

  GameState copy() => GameState(
    businesses: businesses.map((b) => b.copy()).toList(),
    money: money,
    lifetimeEarnings: lifetimeEarnings,
    upgrades: {...upgrades},
    pairsClaimed: pairsClaimed,
    hilvanes: hilvanes,
    boostSeconds: boostSeconds,
  );
}
