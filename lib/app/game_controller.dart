import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/big_num.dart';
import '../core/economy/engine.dart';
import '../core/economy/offline.dart';
import '../core/number_format.dart';
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
    this.iap,
    this.analytics,
    this.testMode = false,
    this.cutscenes = false,
    this.lastSeen,
  }) : state = initial ?? economy.newGame(),
       time = time ?? DeviceTimeService();

  final Economy economy;
  GameState state;
  final SaveManager? saveManager;
  final TimeService time;

  /// Si es null, no se ofrecen anuncios (salvo el x2 offline para VIP).
  final AdService? ads;
  final IapService? iap;

  /// Anuncios y compras simulados (versión web de prueba): se avisa en la Tienda.
  final bool testMode;

  /// Si las cutscenes en video se muestran (la app real sí; las pruebas no).
  final bool cutscenes;
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
    analytics?.log('session_start');
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

  /// Segundos de juego transcurridos en esta sesión; mueve los efectos de fondo.
  double fxTime = 0;

  /// Avanza [dt] segundos (separado de [step] para poder probarlo).
  void advance(double dt) {
    final step = dt.clamp(0.0, 1.0);
    fxTime += step;
    economy.tick(state, step);
    _trackTutorial();
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
    if (doubled && canDoubleOffline) {
      if (state.vip || await _showAd('offline_x2')) mult = 2;
    }
    state.firstReturnDone = true;
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

  // ------------------------------------------------------------ anuncios y compras

  bool get adsUnlocked => economy.adsUnlocked(state);

  /// El x2 offline se ofrece con anuncios disponibles o con el Pase VIP.
  bool get canDoubleOffline => state.vip || ads != null;

  /// Los anuncios solo se muestran si el jugador los pide con un botón
  /// (spec 10.1). Con VIP la recompensa se da sin verlos.
  Future<bool> _showAd(String placement) async {
    final service = ads;
    if (service == null) return false;
    analytics?.log('ad_offer_accepted', {'placement': placement});
    final ok = await service.showRewarded(placement);
    if (ok) analytics?.log('ad_completed', {'placement': placement});
    return ok;
  }

  Future<bool> _earnReward(String placement) async {
    if (state.vip) {
      analytics?.log('ad_skipped_vip', {'placement': placement});
      return true;
    }
    return _showAd(placement);
  }

  /// Registra que se mostró la oferta de un anuncio (para medir aceptación).
  void logAdOfferShown(String placement) =>
      analytics?.log('ad_offer_shown', {'placement': placement});

  bool get canWatchBoost =>
      adsUnlocked && economy.canAddBoost(state) && (state.vip || ads != null);

  /// +4 h de x2 (máximo 12 h acumuladas).
  Future<bool> watchBoostAd() async {
    if (!canWatchBoost || !await _earnReward('boost')) return false;
    economy.addBoostView(state);
    notifyListeners();
    await save();
    return true;
  }

  int get warpAdsLeft => economy.warpAdsLeft(state, time.now());

  bool get canWatchWarp =>
      adsUnlocked && warpAdsLeft > 0 && (state.vip || ads != null);

  /// Devuelve lo ganado, o null si no se completó el anuncio.
  Future<BigNum?> watchWarpAd() async {
    if (!canWatchWarp || !await _earnReward('warp')) return null;
    final gain = economy.claimWarpAd(state, time.now());
    notifyListeners();
    await save();
    return gain;
  }

  bool get canWatchDailyGoldAd =>
      economy.dailyGoldAdAvailable(state, time.now()) &&
      (state.vip || ads != null);

  Future<int?> watchDailyGoldAd() async {
    if (!canWatchDailyGoldAd || !await _earnReward('daily_gold')) return null;
    final gold = economy.claimDailyGoldAd(state, time.now());
    notifyListeners();
    await save();
    return gold;
  }

  bool canBuyWarpWithGold(String id) {
    final w = economy.config.monetization!.warpGold.firstWhere(
      (w) => w.id == id,
    );
    return state.goldButtons >= BigNum.fromInt(w.gold);
  }

  BigNum? buyWarpWithGold(String id) {
    final gain = economy.buyWarpWithGold(state, id);
    if (gain != null) {
      analytics?.log('warp_gold', {'id': id});
      notifyListeners();
      save();
    }
    return gain;
  }

  /// Precio mostrado: el de la tienda; si no lo tiene, el de referencia.
  String priceOf(String productId) =>
      iap?.priceOf(productId) ??
      '\$${economy.product(productId).priceMxn.toStringAsFixed(0)} MXN';

  void logIapView() => analytics?.log('iap_view');

  /// Compra un producto. La tienda cobra primero; el juego solo lo aplica
  /// si el cobro se completó y la regla de compra lo permite.
  Future<bool> purchase(String productId) async {
    final store = iap;
    if (store == null || !economy.canBuyProduct(state, productId)) return false;
    if (!await store.purchase(productId)) return false;
    economy.applyProduct(state, productId);
    analytics?.log('iap_purchase', {'id': productId});
    notifyListeners();
    await save();
    return true;
  }

  /// Restaura las compras permanentes. Devuelve cuántas se recuperaron.
  Future<int> restorePurchases() async {
    final store = iap;
    if (store == null) return 0;
    final restored = economy.restoreProducts(state, await store.restore());
    if (restored > 0) {
      notifyListeners();
      await save();
    }
    return restored;
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

  // ------------------------------------------------------------ metas y regalo

  bool canClaimGoal(String id) => economy.canClaimGoal(state, id);

  void claimGoal(String id) {
    if (economy.claimGoal(state, id)) {
      analytics?.log('goal_claim', {'id': id});
      notifyListeners();
      save();
    }
  }

  bool get canClaimDaily => economy.canClaimDaily(state, time.now());

  DailyReward? claimDaily() {
    final r = economy.claimDaily(state, time.now());
    if (r != null) {
      analytics?.log('daily_claim', {'streak': r.streak});
      notifyListeners();
      save();
    }
    return r;
  }

  /// Punto de aviso en la pestaña Metas.
  bool get hasGoalNotice => economy.hasClaimableGoal(state) || canClaimDaily;

  // ------------------------------------------------------------ cutscenes

  bool hasSeenCutscene(String id) => state.cutscenesSeen.contains(id);

  /// Una cutscene que toca mostrar ahora: activas y todavía no vistas.
  bool shouldShowCutscene(String id) => cutscenes && !hasSeenCutscene(id);

  Future<void> markCutsceneSeen(String id) async {
    if (!state.cutscenesSeen.add(id)) return;
    analytics?.log('cutscene_seen', {'id': id});
    notifyListeners();
    await save();
  }

  // ------------------------------------------------------------ tutorial

  /// Paso actual del tutorial (0 a 2), o null si ya terminó o se saltó (spec 9.12).
  int? get tutorialStep {
    if (state.tutorialDone) return null;
    if (state.lifetimeEarnings.isZero) return 0; // toca el Tendedero
    if (state.businesses[0].owned < 2) return 1; // compra el siguiente
    if (!state.businesses.any((b) => b.hasManager)) {
      return 2; // contrata un manager
    }
    return null;
  }

  int? _lastTutorialStep;

  void _trackTutorial() {
    final step = tutorialStep;
    if (step == _lastTutorialStep) return;
    _lastTutorialStep = step;
    if (step == null) {
      if (!state.tutorialDone) state.tutorialDone = true;
      analytics?.log('tutorial_step', {'step': 'done'});
      save();
    } else {
      analytics?.log('tutorial_step', {'step': step});
    }
  }

  void skipTutorial() {
    if (state.tutorialDone) return;
    state.tutorialDone = true;
    analytics?.log('tutorial_step', {'step': 'skipped'});
    notifyListeners();
    save();
  }

  // ------------------------------------------------------------ ajustes

  NumberFormatter get formatter => NumberFormatter(
    mode: NumberFormatMode.values.firstWhere(
      (m) => m.name == state.settings.numberFormat,
      orElse: () => NumberFormatMode.shortSuffix,
    ),
  );

  void setNumberFormat(NumberFormatMode mode) {
    state.settings.numberFormat = mode.name;
    notifyListeners();
    save();
  }

  void setFontScale(double v) {
    state.settings.fontScale = v.clamp(0.85, 1.6);
    notifyListeners();
    save();
  }

  void setSound(bool v) {
    state.settings.sound = v;
    notifyListeners();
    save();
  }

  void setVibration(bool v) {
    state.settings.vibration = v;
    notifyListeners();
    save();
  }

  /// Texto de la partida para copiar (soporte).
  String? exportSave() => saveManager?.export(state, time.now());

  /// Reemplaza la partida con un texto exportado. Lanza [SaveFormatException]
  /// si el texto no sirve y en ese caso no cambia nada.
  Future<void> importSave(String text) async {
    final m = saveManager;
    if (m == null) throw SaveFormatException('guardado no disponible');
    final data = m.import(text);
    state = data.state;
    pendingOffline = null;
    lastSeen = time.now();
    notifyListeners();
    await save();
  }

  /// Borra la partida pero conserva los ajustes.
  Future<void> resetGame() async {
    final settings = state.settings.copy();
    state = economy.newGame()
      ..settings.numberFormat = settings.numberFormat
      ..settings.fontScale = settings.fontScale
      ..settings.sound = settings.sound
      ..settings.vibration = settings.vibration;
    pendingOffline = null;
    _lastTutorialStep = null;
    analytics?.log('game_reset');
    notifyListeners();
    await save();
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
