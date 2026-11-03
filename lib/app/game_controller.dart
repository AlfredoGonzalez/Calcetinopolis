import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/big_num.dart';
import '../core/economy/engine.dart';
import '../core/state/game_state.dart';

/// Cantidad elegida en el selector de compra (un solo selector para toda la lista).
enum BuyAmount { one, ten, hundred, nextThreshold, max }

/// Une el núcleo puro con la UI: corre el reloj y expone acciones.
/// La UI solo lee [state] y llama estas acciones; nunca calcula economía.
class GameController extends ChangeNotifier {
  GameController(this.economy, {GameState? initial})
    : state = initial ?? economy.newGame();

  final Economy economy;
  final GameState state;

  BuyAmount amount = BuyAmount.one;
  Timer? _timer;
  final Stopwatch _clock = Stopwatch();

  void start({Duration every = const Duration(milliseconds: 50)}) {
    _clock.start();
    _timer ??= Timer.periodic(every, (_) => step());
  }

  /// Avanza el juego con el tiempo real transcurrido.
  void step() {
    final dt = _clock.elapsedMicroseconds / 1e6;
    _clock
      ..reset()
      ..start();
    advance(dt);
  }

  /// Avanza [dt] segundos (separado de [step] para poder probarlo).
  void advance(double dt) {
    economy.tick(state, dt.clamp(0.0, 1.0));
    notifyListeners();
  }

  void setAmount(BuyAmount a) {
    amount = a;
    notifyListeners();
  }

  /// Unidades que compraría el botón del negocio [i] con la cantidad elegida.
  int unitsFor(int i) {
    switch (amount) {
      case BuyAmount.one:
        return 1;
      case BuyAmount.ten:
        return 10;
      case BuyAmount.hundred:
        return 100;
      case BuyAmount.nextThreshold:
        return economy.unitsToNextThreshold(state, i) ?? 1;
      case BuyAmount.max:
        final m = economy.maxAffordable(state, i);
        return m > 0 ? m : 1;
    }
  }

  int _room(int i) =>
      economy.config.businesses[i].maxOwned - state.businesses[i].owned;

  BigNum costFor(int i) => economy.costOf(state, i, unitsFor(i));

  bool canBuy(int i) {
    final n = unitsFor(i);
    return n > 0 && n <= _room(i) && costFor(i) <= state.money;
  }

  /// Lo que falta para poder comprar (0 si ya alcanza).
  BigNum missing(int i) {
    final d = costFor(i) - state.money;
    return d.isPositive ? d : BigNum.zero;
  }

  void buy(int i) {
    if (economy.buy(state, i, unitsFor(i))) notifyListeners();
  }

  void tap(int i) {
    if (economy.tap(state, i)) notifyListeners();
  }

  void buyManager(int i) {
    if (economy.buyManager(state, i)) notifyListeners();
  }

  void buyUpgrade(String id) {
    if (economy.buyUpgrade(state, id)) notifyListeners();
  }

  /// Compra todos los upgrades asequibles, del más barato al más caro.
  int buyAllAffordableUpgrades() {
    final list =
        economy.config.upgrades
            .where((u) => !state.upgrades.contains(u.id))
            .toList()
          ..sort((a, b) => a.cost.compareTo(b.cost));
    var bought = 0;
    for (final u in list) {
      if (economy.buyUpgrade(state, u.id)) bought++;
    }
    if (bought > 0) notifyListeners();
    return bought;
  }

  /// ¿Hay algo asequible en Mejoras? (punto de aviso en la pestaña)
  bool get hasAffordableUpgrade {
    for (final u in economy.config.upgrades) {
      if (!state.upgrades.contains(u.id) &&
          u.cost <= state.money &&
          _upgradeVisible(u.target)) {
        return true;
      }
    }
    for (var i = 0; i < state.businesses.length; i++) {
      final b = state.businesses[i];
      if (b.owned > 0 &&
          !b.hasManager &&
          economy.config.businesses[i].manager.cost <= state.money) {
        return true;
      }
    }
    return false;
  }

  bool _upgradeVisible(String target) {
    if (target == 'all') return true;
    final i = economy.config.businessIndex(target);
    return state.businesses[i].owned > 0;
  }

  /// El negocio se muestra completo si ya tienes uno o si es el siguiente a desbloquear.
  bool isRevealed(int i) => state.businesses[i].owned > 0;

  bool isNextToUnlock(int i) =>
      !isRevealed(i) && (i == 0 || state.businesses[i - 1].owned > 0);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
