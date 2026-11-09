import 'dart:math' as math;

import '../big_num.dart';
import '../config/economy_config.dart';
import '../state/game_state.dart';
import 'formulas.dart';

/// Núcleo de economía: lógica pura y determinista, sin UI (spec 11.2).
class Economy {
  Economy(this.config);

  final EconomyConfig config;

  GameState newGame() => GameState.initial(config.businesses.length);

  // ---------------------------------------------------------------- consulta

  /// Cuántos umbrales de velocidad cumple [owned].
  int _thresholdsReached(int owned) =>
      config.thresholds.where((t) => owned >= t).length;

  /// Halvings del ciclo: propios + globales ("Everything").
  int halvings(GameState s, int i) {
    final own = _thresholdsReached(s.businesses[i].owned);
    final minOwned = s.businesses.map((b) => b.owned).reduce(math.min);
    return own + _thresholdsReached(minOwned);
  }

  double cycleSeconds(GameState s, int i) => Formulas.cycleSeconds(
    config.businesses[i].baseCycleSeconds,
    halvings(s, i),
  );

  /// Multiplicador de ganancia por pasos grandes de unidades (desde 500).
  double profitUnlockMultiplier(int owned) {
    if (owned < config.profitStepStart) return 1;
    final steps =
        (owned - config.profitStepStart) ~/ config.profitStepEvery + 1;
    return math.pow(config.profitStepMultiplier, steps).toDouble();
  }

  /// Producto de multiplicadores M (sin el boost de anuncio).
  BigNum multiplier(GameState s, int i) {
    final b = config.businesses[i];
    var m = BigNum.one;
    for (final u in config.upgrades) {
      if (!s.upgrades.contains(u.id)) continue;
      if (u.target == 'all' || u.target == b.id) m = m.mulDouble(u.multiplier);
    }
    m = m.mulDouble(profitUnlockMultiplier(s.businesses[i].owned));
    m = m * Formulas.pairsMultiplier(s.pairsClaimed, config.prestige.pairBonus);
    final shopMult = shopValue(s, ShopType.globalMult);
    if (shopMult != null) m = m.mulDouble(shopMult);
    m = m.mulDouble(purchasedMultiplier(s));
    return m;
  }

  // ------------------------------------------------------------ tienda de Hilvanes

  ShopItem shopItem(String id) => config.shop.firstWhere((it) => it.id == id);

  int shopLevel(GameState s, String id) => s.shopLevels[id] ?? 0;

  /// Valor actual de la mejora de ese tipo (nivel comprado más alto), o null.
  double? shopValue(GameState s, String type) {
    double? best;
    for (final it in config.shop) {
      if (it.type != type) continue;
      final lvl = shopLevel(s, it.id);
      if (lvl <= 0) continue;
      final v = it.levels[math.min(lvl, it.levels.length) - 1].value;
      if (best == null || v > best) best = v;
    }
    return best;
  }

  /// Siguiente nivel de la mejora, o null si ya está al máximo.
  ShopLevel? nextShopLevel(GameState s, String id) {
    final it = shopItem(id);
    final lvl = shopLevel(s, id);
    return lvl >= it.levels.length ? null : it.levels[lvl];
  }

  bool buyShop(GameState s, String id) {
    final next = nextShopLevel(s, id);
    if (next == null || next.cost > s.hilvanes) return false;
    final it = shopItem(id);
    final oldLevel = shopLevel(s, id);
    s.hilvanes -= next.cost;
    s.shopLevels[id] = oldLevel + 1;
    // Las mejoras de arranque también valen para la corrida en curso.
    if (it.type == ShopType.startMoney) {
      final before = oldLevel == 0 ? 0.0 : it.levels[oldLevel - 1].value;
      s.money += BigNum.fromDouble(next.value - before);
    } else if (it.type == ShopType.freeManagers) {
      _grantFreeManagers(s);
    }
    return true;
  }

  /// Tope de horas offline: la base o lo que dé la tienda (hasta el máximo).
  double offlineCapHours(GameState s) {
    final v = shopValue(s, ShopType.offlineCapHours) ?? 0;
    return math.min(
      math.max(v, config.offline.baseCapHours),
      config.offline.maxCapHours,
    );
  }

  /// Estado inicial de una corrida según la tienda (Pelusitas y managers).
  void _applyRunStart(GameState s) {
    final money = shopValue(s, ShopType.startMoney);
    if (money != null) s.money = BigNum.fromDouble(money);
    _grantFreeManagers(s);
  }

  void _grantFreeManagers(GameState s) {
    final managers = shopValue(s, ShopType.freeManagers)?.floor() ?? 0;
    for (var i = 0; i < math.min(managers, s.businesses.length); i++) {
      s.businesses[i].hasManager = true;
    }
  }

  BigNum incomePerCycle(GameState s, int i) => Formulas.cycleIncome(
    config.businesses[i].baseIncome,
    s.businesses[i].owned,
    multiplier(s, i),
  );

  BigNum incomePerSecond(GameState s, int i) =>
      incomePerCycle(s, i) / BigNum.fromDouble(cycleSeconds(s, i));

  /// $/s total de los negocios con manager (base de las ganancias offline).
  BigNum managedIncomePerSecond(GameState s) {
    var total = BigNum.zero;
    for (var i = 0; i < s.businesses.length; i++) {
      final b = s.businesses[i];
      if (b.owned > 0 && b.hasManager) total += incomePerSecond(s, i);
    }
    return total;
  }

  // ------------------------------------------------------------------ dinero

  void addMoney(GameState s, BigNum amount) {
    s.money += amount;
    s.lifetimeEarnings += amount;
  }

  // ------------------------------------------------------------------ tick

  /// Avanza el juego [dt] segundos. Determinista.
  ///
  /// Con manager la producción es continua: ingreso = I * dt / T, sin importar
  /// si el ciclo es largo o menor a 0.25 s (spec 9.3 regla 3). Sin manager,
  /// el negocio paga una vez al completar un ciclo iniciado con [tap].
  void tick(GameState s, double dt) {
    if (dt <= 0) return;
    final boosted = math.min(dt, s.boostSeconds);
    // El bono de la lavadora se SUMA al del boost de anuncios (no se multiplica).
    final washerStart = s.washerBonus;
    final washerEnd = math.max(
      0.0,
      washerStart - config.washer.decayPerSecond * dt,
    );
    final washerAvg = (washerStart + washerEnd) / 2;
    final boostFactor =
        (dt + (config.boost.multiplier - 1) * boosted) / dt + washerAvg;

    for (var i = 0; i < s.businesses.length; i++) {
      final b = s.businesses[i];
      if (b.owned == 0) continue;
      final t = cycleSeconds(s, i);
      if (b.hasManager) {
        final cycles = dt / t;
        addMoney(s, incomePerCycle(s, i).mulDouble(cycles * boostFactor));
        b.progress = (b.progress + cycles) % 1.0;
      } else if (b.running) {
        b.progress += dt / t;
        if (b.progress >= 1) {
          addMoney(s, incomePerCycle(s, i).mulDouble(boostFactor));
          b.progress = 0;
          b.running = false;
        }
      }
    }
    s.boostSeconds = math.max(0, s.boostSeconds - dt);
    s.washerBonus = washerEnd;
  }

  /// Factor de velocidad de ahora mismo: 1 + boost de anuncio + lavadora.
  /// Es el mismo que usa [tick], para que lo que se ve coincida con lo que se gana.
  double liveFactor(GameState s) =>
      1 +
      (s.boostSeconds > 0 ? config.boost.multiplier - 1 : 0) +
      s.washerBonus;

  // ------------------------------------------------------------ lavadora

  /// Lo que suma cada toque a la lavadora (la mejora de la tienda, si la hay).
  double washerTapBonus(GameState s) =>
      shopValue(s, ShopType.tapPower) ?? config.washer.tapBonus;

  /// Bono máximo de la lavadora (la mejora de la tienda, si la hay).
  double washerMaxBonus(GameState s) =>
      shopValue(s, ShopType.washerMax) ?? config.washer.maxBonus;

  /// Un toque a la lavadora: suma su bono, sin pasar del máximo.
  void tapWasher(GameState s) {
    s.washerBonus = math.min(
      washerMaxBonus(s),
      s.washerBonus + washerTapBonus(s),
    );
  }

  /// El jugador toca un negocio sin manager para iniciar su ciclo.
  bool tap(GameState s, int i) {
    final b = s.businesses[i];
    if (b.owned == 0 || b.hasManager || b.running) return false;
    b.running = true;
    b.progress = 0;
    return true;
  }

  // ------------------------------------------------------------------ compras

  bool isUnlocked(GameState s, int i) => s.businesses[i].owned > 0;

  int _room(GameState s, int i) =>
      config.businesses[i].maxOwned - s.businesses[i].owned;

  BigNum costOf(GameState s, int i, int n) {
    final c = config.businesses[i];
    return Formulas.costBulk(
      c.baseCost,
      c.coefficient,
      s.businesses[i].owned,
      n,
    );
  }

  int maxAffordable(GameState s, int i) {
    final c = config.businesses[i];
    return Formulas.maxAffordable(
      c.baseCost,
      c.coefficient,
      s.businesses[i].owned,
      s.money,
      limit: _room(s, i),
    );
  }

  /// Unidades que faltan para el siguiente umbral de velocidad; null si ya no hay.
  int? unitsToNextThreshold(GameState s, int i) {
    final owned = s.businesses[i].owned;
    for (final t in config.thresholds) {
      if (owned < t) return t - owned;
    }
    return null;
  }

  bool buy(GameState s, int i, int n) {
    if (n <= 0 || n > _room(s, i)) return false;
    final cost = costOf(s, i, n);
    if (cost > s.money) return false;
    s.money -= cost;
    s.businesses[i].owned += n;
    return true;
  }

  /// Compra hasta alcanzar el siguiente umbral (botón "Siguiente umbral").
  bool buyToNextThreshold(GameState s, int i) {
    final n = unitsToNextThreshold(s, i);
    return n != null && buy(s, i, n);
  }

  bool buyMax(GameState s, int i) {
    final n = maxAffordable(s, i);
    return n > 0 && buy(s, i, n);
  }

  bool buyManager(GameState s, int i) {
    final b = s.businesses[i];
    final cfg = config.businesses[i].manager;
    if (b.hasManager || b.owned == 0 || cfg.cost > s.money) return false;
    s.money -= cfg.cost;
    b.hasManager = true;
    b.running = false;
    return true;
  }

  bool buyUpgrade(GameState s, String id) {
    if (s.upgrades.contains(id)) return false;
    final u = config.upgrades.firstWhere((u) => u.id == id);
    if (u.cost > s.money) return false;
    s.money -= u.cost;
    s.upgrades.add(id);
    return true;
  }

  // ------------------------------------------------------------------ boost

  /// Una vista suma horas de boost, con tope (spec 10.1).
  void addBoostView(GameState s) {
    final add = config.boost.hoursPerView * 3600;
    s.boostSeconds = math.min(
      s.boostSeconds + add,
      config.boost.maxHours * 3600,
    );
  }

  // ------------------------------------------------------------------ offline

  double offlineCapSeconds(double capHours) =>
      math.min(capHours, config.offline.maxCapHours) * 3600;

  /// Ganancia offline: $/s de negocios con manager * tiempo, con tope.
  /// Tiempo negativo (reloj atrasado) cuenta como cero. No modifica el estado.
  BigNum offlineGain(GameState s, double secondsAway, {double? capHours}) {
    final cap = offlineCapSeconds(capHours ?? offlineCapHours(s));
    final secs = secondsAway.isNaN ? 0.0 : secondsAway.clamp(0.0, cap);
    if (secs <= 0) return BigNum.zero;
    return managedIncomePerSecond(s).mulDouble(secs);
  }

  // ------------------------------------------------------------------ prestigio

  /// P_total con la E_vida actual.
  BigNum pairsTotal(GameState s) => Formulas.prestigeTotal(
    s.lifetimeEarnings,
    config.prestige.scale,
    base: config.prestige.base,
  );

  /// Parejas por cobrar al centrifugar ahora.
  BigNum pairsPending(GameState s) {
    final d = pairsTotal(s) - s.pairsClaimed;
    return d.isPositive ? d : BigNum.zero;
  }

  /// E_vida necesaria para tener [pairs] parejas en total.
  BigNum lifetimeForPairs(BigNum pairs) => Formulas.lifetimeForPairs(
    pairs,
    config.prestige.scale,
    base: config.prestige.base,
  );

  /// Parejas por cobrar que se recomiendan antes de centrifugar: las que ya
  /// tienes (para al menos duplicar tu bono) y, en la primera vuelta,
  /// `first_target_pairs`.
  BigNum recommendedPairs(GameState s) {
    final first = BigNum.fromInt(config.prestige.firstTargetPairs);
    return s.pairsClaimed > first ? s.pairsClaimed : first;
  }

  /// E_vida con la que las Parejas por cobrar llegan a [recommendedPairs].
  BigNum lifetimeForRecommended(GameState s) =>
      lifetimeForPairs(s.pairsClaimed + recommendedPairs(s));

  /// "Buen momento": las Parejas por cobrar llegan a las recomendadas.
  bool isGoodTimeToPrestige(GameState s) {
    final pending = pairsPending(s);
    return pending.isPositive && pending >= recommendedPairs(s);
  }

  /// Multiplicador de ganancias después de centrifugar.
  BigNum multiplierAfterPrestige(GameState s) => Formulas.pairsMultiplier(
    s.pairsClaimed + pairsPending(s),
    config.prestige.pairBonus,
  );

  /// Centrifugado. Devuelve las Parejas nuevas (0 = no hace nada).
  /// Conserva Parejas, Hilvanes y E_vida; reinicia dinero, negocios,
  /// managers, upgrades y boost.
  BigNum prestige(GameState s) {
    final pending = pairsPending(s);
    if (!pending.isPositive) return BigNum.zero;
    s.pairsClaimed += pending;
    s.hilvanes += (pending.mulDouble(config.prestige.hilvanesPerPair)).floor();
    s.money = BigNum.zero;
    s.upgrades.clear();
    s.boostSeconds = 0;
    for (var i = 0; i < s.businesses.length; i++) {
      s.businesses[i]
        ..owned = i == 0 ? 1 : 0
        ..hasManager = false
        ..progress = 0
        ..running = false;
    }
    _applyRunStart(s);
    return pending;
  }

  // ------------------------------------------------------------------ metas

  GoalConfig goal(String id) => config.goals.firstWhere((g) => g.id == id);

  /// Valor actual de la meta, en las mismas unidades que su objetivo.
  BigNum goalCurrent(GameState s, GoalConfig g) {
    switch (g.type) {
      case GoalType.own:
        return BigNum.fromInt(
          s.businesses[config.businessIndex(g.business!)].owned,
        );
      case GoalType.managers:
        return BigNum.fromInt(s.businesses.where((b) => b.hasManager).length);
      case GoalType.businesses:
        return BigNum.fromInt(s.businesses.where((b) => b.owned > 0).length);
      case GoalType.allOwned:
        return BigNum.fromInt(
          s.businesses.map((b) => b.owned).reduce(math.min),
        );
      case GoalType.lifetime:
        return s.lifetimeEarnings;
      case GoalType.pairs:
        return s.pairsClaimed;
      case GoalType.upgrades:
        return BigNum.fromInt(s.upgrades.length);
    }
    return BigNum.zero;
  }

  bool goalMet(GameState s, GoalConfig g) => goalCurrent(s, g) >= g.target;

  /// Avance 0..1 para la barra de la meta.
  double goalProgress(GameState s, GoalConfig g) {
    if (goalMet(s, g)) return 1;
    return (goalCurrent(s, g) / g.target).toDouble().clamp(0.0, 1.0);
  }

  bool isGoalClaimed(GameState s, String id) => s.goalsClaimed.contains(id);

  bool canClaimGoal(GameState s, String id) =>
      !isGoalClaimed(s, id) && goalMet(s, goal(id));

  bool get _hasGoals => config.goals.isNotEmpty;

  bool hasClaimableGoal(GameState s) =>
      _hasGoals && config.goals.any((g) => canClaimGoal(s, g.id));

  /// Cobra la recompensa. Las Pelusitas no cuentan para E_vida (no inflan el prestigio).
  bool claimGoal(GameState s, String id) {
    if (!canClaimGoal(s, id)) return false;
    final g = goal(id);
    s.money += g.rewardMoney;
    s.hilvanes += g.rewardHilvanes;
    s.goalsClaimed.add(id);
    return true;
  }

  // ------------------------------------------------------------ regalo diario

  /// Clave de día en hora local: "2026-11-03".
  static String dayKey(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year.toString().padLeft(4, '0')}-${two(l.month)}-${two(l.day)}';
  }

  /// Un regalo por día. Si el reloj está atrasado respecto al último cobro, no hay regalo.
  bool canClaimDaily(GameState s, DateTime now) {
    if (config.daily == null) return false;
    final last = s.dailyDay;
    return last == null || dayKey(now).compareTo(last) > 0;
  }

  /// Recompensa del siguiente regalo (la racha se pausa si faltas, no se reinicia).
  DailyReward dailyPreview(GameState s) {
    final d = config.daily!;
    final streak = s.dailyStreak + 1;
    final minutes = d.minutes + d.bonusMinutesPerDay * ((streak - 1) % 7);
    var money = managedIncomePerSecond(s).mulDouble(60 * minutes);
    if (money < d.baseMoney) money = d.baseMoney;
    final bonus = d.hilvanesEvery > 0 && streak % d.hilvanesEvery == 0
        ? d.hilvanes
        : BigNum.zero;
    return DailyReward(money: money, hilvanes: bonus, streak: streak);
  }

  DailyReward? claimDaily(GameState s, DateTime now) {
    if (!canClaimDaily(s, now)) return null;
    final r = dailyPreview(s);
    s.money += r.money;
    s.hilvanes += r.hilvanes;
    s.dailyStreak = r.streak;
    s.dailyDay = dayKey(now);
    return r;
  }
}

extension MonetizationRules on Economy {
  MonetizationConfig get _mon => config.monetization!;

  ProductConfig product(String id) =>
      _mon.products.firstWhere((p) => p.id == id);

  /// Multiplicador de compras reales: niveles permanentes y paquete de inicio.
  double purchasedMultiplier(GameState s) {
    final mon = config.monetization;
    if (mon == null) return 1;
    var m = 1.0;
    for (final p in mon.products) {
      if (p.kind == ProductKind.multiplier && p.level <= s.multLevel) {
        m *= p.factor;
      }
      if (p.kind == ProductKind.starter && s.starterBought) m *= p.factor;
    }
    return m;
  }

  /// Los anuncios no aparecen antes del primer regreso (spec 9.10). Quien ya
  /// centrifugó también pasó esa etapa.
  bool adsUnlocked(GameState s) =>
      s.firstReturnDone || s.pairsClaimed.isPositive;

  /// Paquete de inicio: una sola vez y nunca antes del primer Centrifugado.
  bool starterAvailable(GameState s) =>
      config.monetization != null &&
      !s.starterBought &&
      s.pairsClaimed.isPositive &&
      _mon.products.any((p) => p.kind == ProductKind.starter);

  /// ¿Se puede comprar este producto ahora?
  bool canBuyProduct(GameState s, String id) {
    final p = product(id);
    switch (p.kind) {
      case ProductKind.vip:
        return !s.vip;
      case ProductKind.starter:
        return starterAvailable(s);
      case ProductKind.multiplier:
        return p.level == s.multLevel + 1;
      default:
        return true;
    }
  }

  /// Aplica un producto ya cobrado por la tienda. Es idempotente para los
  /// productos permanentes (sirve también para restaurar compras).
  bool applyProduct(GameState s, String id) {
    final p = product(id);
    switch (p.kind) {
      case ProductKind.vip:
        if (s.vip) return false;
        s.vip = true;
        return true;
      case ProductKind.starter:
        if (s.starterBought) return false;
        s.starterBought = true;
        s.goldButtons += BigNum.fromInt(p.gold);
        return true;
      case ProductKind.multiplier:
        if (p.level <= s.multLevel) return false;
        s.multLevel = p.level;
        return true;
      default:
        s.goldButtons += BigNum.fromInt(p.gold);
        return true;
    }
  }

  /// Restaura lo que la tienda dice que el jugador ya tiene. No regala el oro
  /// del paquete de inicio de nuevo si ya estaba marcado como comprado.
  int restoreProducts(GameState s, Set<String> ownedIds) {
    var restored = 0;
    final byLevel = ownedIds
        .where((id) => product(id).kind == ProductKind.multiplier)
        .map((id) => product(id).level);
    final maxLevel = byLevel.isEmpty ? 0 : byLevel.reduce(math.max);
    if (maxLevel > s.multLevel) {
      s.multLevel = maxLevel;
      restored++;
    }
    for (final id in ownedIds) {
      final p = product(id);
      if (p.kind == ProductKind.vip && !s.vip) {
        s.vip = true;
        restored++;
      } else if (p.kind == ProductKind.starter && !s.starterBought) {
        s.starterBought = true; // el oro no se vuelve a dar
        restored++;
      }
    }
    return restored;
  }

  // ------------------------------------------------------------------ anuncios

  /// ¿Se puede sumar otra vista? Con la reserva a medias la vista suma lo que
  /// quepa hasta el tope; solo se bloquea cuando ya está llena.
  bool canAddBoost(GameState s) =>
      s.boostSeconds < config.boost.maxHours * 3600 - 1;

  int warpAdsLeft(GameState s, DateTime now) {
    final used = s.warpDay == Economy.dayKey(now) ? s.warpCount : 0;
    return math.max(0, _mon.warpPerDay - used);
  }

  void _noteWarpAd(GameState s, DateTime now) {
    final key = Economy.dayKey(now);
    if (s.warpDay != key) {
      s.warpDay = key;
      s.warpCount = 0;
    }
    s.warpCount++;
  }

  /// Salta [seconds] de producción de los negocios con manager.
  BigNum timeWarp(GameState s, double seconds) {
    final gain = managedIncomePerSecond(s).mulDouble(seconds);
    if (gain.isPositive) addMoney(s, gain);
    return gain;
  }

  /// Recompensa del anuncio "saltar espera" (15 min). No cobra nada si no quedan.
  BigNum? claimWarpAd(GameState s, DateTime now) {
    if (!adsUnlocked(s) || warpAdsLeft(s, now) <= 0) return null;
    _noteWarpAd(s, now);
    return timeWarp(s, _mon.warpMinutes * 60);
  }

  /// Compra un salto con Botones Dorados.
  BigNum? buyWarpWithGold(GameState s, String id) {
    final w = _mon.warpGold.firstWhere((w) => w.id == id);
    final cost = BigNum.fromInt(w.gold);
    if (cost > s.goldButtons) return null;
    s.goldButtons -= cost;
    return timeWarp(s, w.hours * 3600);
  }

  bool dailyGoldAdAvailable(GameState s, DateTime now) =>
      adsUnlocked(s) && s.dailyAdDay != Economy.dayKey(now);

  /// Bono de Botones Dorados del regalo diario (una vez al día).
  int? claimDailyGoldAd(GameState s, DateTime now) {
    if (!dailyGoldAdAvailable(s, now)) return null;
    s.dailyAdDay = Economy.dayKey(now);
    final g = _mon.dailyGiftGold;
    s.goldButtons += BigNum.fromInt(g);
    return g;
  }
}

class DailyReward {
  const DailyReward({
    required this.money,
    required this.hilvanes,
    required this.streak,
  });
  final BigNum money;
  final BigNum hilvanes;
  final int streak;
}
