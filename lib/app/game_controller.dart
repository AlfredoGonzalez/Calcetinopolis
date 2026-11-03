import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/big_num.dart';
import '../core/economy/engine.dart';
import '../core/economy/offline.dart';
import '../core/state/game_state.dart';
import '../services/services.dart';
import 'save_manager.dart';

/// Cantidad elegida en el selector de compra (un solo selector para toda la lista).
enum BuyAmount { one, ten, hundred, nextThreshold, max }

/// Une el núcleo puro con la UI: corre el reloj y expone acciones.
/// La UI solo lee [state] y llama estas acciones; nunca calcula economía.
class GameController extends ChangeNotifier {
  GameController(
    this.economy, {
    GameState? initial,
    this.saveManager,
    TimeService? time,
    this.ads,
    this.analytics,
    this.lastSeen,
  }) : state = initial ?? economy.newGame(),
       time = time ?? DeviceTimeService();

  final Economy economy;
  final GameState state;
  final SaveManager? saveManager;
  final TimeService time;

  /// Si es null, el botón "x2 viendo un anuncio" no se ofrece (llega en F7).
  final AdService? ads;
  final AnalyticsService? analytics;

  /// Última vez que se guardó o se pausó la app; base de la ganancia offline.
  DateTime? lastSeen;

  /// Ganancia offline pendiente de recoger (ventana de bienvenida).
  OfflineReport? pendingOffline;

  /// Segundos mínimos fuera para mostrar la ventana de bienvenida.
  static const minAwaySeconds = 60.0;
  static const autosaveEvery = 30.0;
  double _sinceSave = 0;

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
    final step = dt.clamp(0.0, 1.0);
    economy.tick(state, step);
    _sinceSave += step;
    if (_sinceSave >= autosaveEvery) save();
    notifyListeners();
  }

  // ------------------------------------------------------------ guardado

  /// Guarda ya. Nunca lanza: un fallo de disco no debe tumbar el juego.
  Future<void> save() async {
    _sinceSave = 0;
    final m = saveManager;
    if (m == null) return;
    final now = time.now();
    lastSeen = now;
    try {
      await m.save(state, now);
    } catch (e) {
      debugPrint('No se pudo guardar: $e');
    }
  }

  /// La app pasa a segundo plano.
  Future<void> onPaused() => save();

  /// La app vuelve: calcula lo ganado mientras estuvo fuera.
  void onResumed() {
    final seen = lastSeen;
    if (seen == null || pendingOffline != null) return;
    checkOffline(seen);
    notifyListeners();
  }

  /// Calcula la ganancia offline desde [since]; si vale la pena la deja
  /// pendiente. Lo ganado nunca se pierde por reloj atrasado: solo se ignora.
  OfflineReport checkOffline(DateTime since) {
    final r = computeOffline(economy, state, lastSeen: since, now: time.now());
    if (r.gain.isPositive && r.secondsAway >= minAwaySeconds) {
      pendingOffline = r;
    }
    return r;
  }

  /// Recoge la ganancia offline. [doubled] pide el x2 viendo un anuncio.
  Future<void> claimOffline({bool doubled = false}) async {
    final r = pendingOffline;
    if (r == null) return;
    var mult = 1.0;
    if (doubled && ads != null && await ads!.showRewarded('offline_x2')) {
      mult = 2;
    }
    economy.addMoney(state, r.gain.mulDouble(mult));
    analytics?.log('offline_claim', {
      'seconds': r.secondsCounted,
      'doubled': mult == 2,
    });
    pendingOffline = null;
    lastSeen = time.now();
    notifyListeners();
    await save();
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
    if (economy.buyManager(state, i)) {
      notifyListeners();
      save();
    }
  }

  void buyUpgrade(String id) {
    if (economy.buyUpgrade(state, id)) {
      notifyListeners();
      save();
    }
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
    if (bought > 0) {
      notifyListeners();
      save();
    }
    return bought;
  }

  // ------------------------------------------------------------ prestigio

  BigNum get pairsPending => economy.pairsPending(state);

  /// Centrifuga. Devuelve las Parejas nuevas (0 si no había nada que cobrar).
  Future<BigNum> centrifuge() async {
    final got = economy.prestige(state);
    if (!got.isPositive) return got;
    analytics?.log('prestige', {
      'pairs': got.toJson(),
      'total': state.pairsClaimed.toJson(),
    });
    notifyListeners();
    await save();
    return got;
  }

  bool canBuyShop(String id) {
    final next = economy.nextShopLevel(state, id);
    return next != null && next.cost <= state.hilvanes;
  }

  void buyShop(String id) {
    if (economy.buyShop(state, id)) {
      notifyListeners();
      save();
    }
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
