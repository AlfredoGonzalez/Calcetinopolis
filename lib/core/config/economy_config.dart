import 'dart:convert';

import '../big_num.dart';

class ManagerConfig {
  const ManagerConfig({
    required this.name,
    required this.pattern,
    required this.cost,
  });
  final String name;
  final String pattern;
  final BigNum cost;
}

class BusinessConfig {
  const BusinessConfig({
    required this.id,
    required this.name,
    required this.baseCost,
    required this.coefficient,
    required this.baseCycleSeconds,
    required this.baseIncome,
    required this.manager,
    required this.maxOwned,
  });

  final String id;
  final String name;
  final BigNum baseCost;
  final double coefficient;
  final double baseCycleSeconds;
  final BigNum baseIncome;
  final ManagerConfig manager;
  final int maxOwned;
}

class UpgradeConfig {
  const UpgradeConfig({
    required this.id,
    required this.name,
    required this.target,
    required this.multiplier,
    required this.cost,
  });
  final String id;
  final String name;

  /// id de negocio, o "all" para todos.
  final String target;
  final double multiplier;
  final BigNum cost;
}

class PrestigeConfig {
  const PrestigeConfig({
    required this.scale,
    required this.base,
    required this.pairBonus,
    required this.hilvanesPerPair,
    required this.firstTargetPairs,
  });

  /// S de la fórmula P = floor(base * sqrt(E_vida / S)).
  final BigNum scale;
  final double base;
  final double pairBonus;
  final double hilvanesPerPair;

  /// Parejas por cobrar con las que el simulador considera "primer prestigio".
  final int firstTargetPairs;
}

class OfflineConfig {
  const OfflineConfig({required this.baseCapHours, required this.maxCapHours});
  final double baseCapHours;
  final double maxCapHours;
}

class BoostConfig {
  const BoostConfig({
    required this.multiplier,
    required this.hoursPerView,
    required this.maxHours,
  });
  final double multiplier;
  final double hoursPerView;
  final double maxHours;
}

class ShopLevel {
  const ShopLevel({required this.cost, required this.value});

  /// Costo en Hilvanes.
  final BigNum cost;
  final double value;
}

/// Tipos de mejora permanente de la tienda de Hilvanes.
class ShopType {
  static const globalMult = 'global_mult';
  static const startMoney = 'start_money';
  static const freeManagers = 'free_managers';
  static const offlineCapHours = 'offline_cap_hours';
  static const all = {globalMult, startMoney, freeManagers, offlineCapHours};
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.levels,
  });
  final String id;
  final String name;
  final String description;
  final String type;
  final List<ShopLevel> levels;
}

class GoalType {
  static const own = 'own';
  static const managers = 'managers';
  static const businesses = 'businesses';
  static const allOwned = 'all_owned';
  static const lifetime = 'lifetime';
  static const pairs = 'pairs';
  static const upgrades = 'upgrades';
  static const all = {
    own,
    managers,
    businesses,
    allOwned,
    lifetime,
    pairs,
    upgrades,
  };
}

/// Meta guiada (spec 9.8 / 9.12): una recompensa gratis al cumplirla.
class GoalConfig {
  const GoalConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    required this.rewardMoney,
    required this.rewardHilvanes,
    this.business,
  });
  final String id;
  final String name;
  final String type;
  final BigNum target;
  final BigNum rewardMoney;
  final BigNum rewardHilvanes;

  /// id del negocio, solo para el tipo `own`.
  final String? business;
}

class DailyConfig {
  const DailyConfig({
    required this.baseMoney,
    required this.minutes,
    required this.bonusMinutesPerDay,
    required this.hilvanesEvery,
    required this.hilvanes,
  });

  /// Mínimo de Pelusitas del regalo (para el inicio, cuando aún no hay ingreso).
  final BigNum baseMoney;

  /// Minutos de producción que vale el regalo del día 1; sube cada día de la racha.
  final double minutes;
  final double bonusMinutesPerDay;

  /// Cada cuántos días de racha se suman Hilvanes.
  final int hilvanesEvery;
  final BigNum hilvanes;
}

class EconomyConfig {
  const EconomyConfig({
    required this.businesses,
    required this.thresholds,
    required this.profitStepStart,
    required this.profitStepEvery,
    required this.profitStepMultiplier,
    required this.upgrades,
    required this.prestige,
    required this.offline,
    required this.boost,
    this.shop = const [],
    this.goals = const [],
    this.daily,
  });

  final List<BusinessConfig> businesses;

  /// Umbrales que reducen el ciclo a la mitad (25, 50, 100, ...).
  final List<int> thresholds;
  final int profitStepStart;
  final int profitStepEvery;
  final double profitStepMultiplier;
  final List<UpgradeConfig> upgrades;
  final PrestigeConfig prestige;
  final OfflineConfig offline;
  final BoostConfig boost;
  final List<ShopItem> shop;
  final List<GoalConfig> goals;
  final DailyConfig? daily;

  factory EconomyConfig.fromJsonString(String source) =>
      EconomyConfig.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory EconomyConfig.fromJson(Map<String, dynamic> j) {
    BigNum big(Object? v) => BigNum.parse(v.toString());

    final businesses = (j['businesses'] as List).map((raw) {
      final b = raw as Map<String, dynamic>;
      final m = b['manager'] as Map<String, dynamic>;
      return BusinessConfig(
        id: b['id'] as String,
        name: b['name'] as String,
        baseCost: big(b['base_cost']),
        coefficient: (b['coefficient'] as num).toDouble(),
        baseCycleSeconds: (b['base_cycle_seconds'] as num).toDouble(),
        baseIncome: big(b['base_income']),
        manager: ManagerConfig(
          name: m['name'] as String,
          pattern: m['pattern'] as String,
          cost: big(m['cost']),
        ),
        maxOwned: (b['max_owned'] as num?)?.toInt() ?? 2000,
      );
    }).toList();

    final unlocks = j['unlocks'] as Map<String, dynamic>;
    final p = j['prestige'] as Map<String, dynamic>;
    final o = j['offline'] as Map<String, dynamic>;
    final bo = j['boost'] as Map<String, dynamic>;

    final config = EconomyConfig(
      businesses: businesses,
      thresholds: (unlocks['speed_thresholds'] as List)
          .map((e) => (e as num).toInt())
          .toList(),
      profitStepStart: (unlocks['profit_step_start'] as num).toInt(),
      profitStepEvery: (unlocks['profit_step_every'] as num).toInt(),
      profitStepMultiplier: (unlocks['profit_step_multiplier'] as num)
          .toDouble(),
      upgrades: (j['upgrades'] as List).map((raw) {
        final u = raw as Map<String, dynamic>;
        return UpgradeConfig(
          id: u['id'] as String,
          name: u['name'] as String,
          target: u['target'] as String,
          multiplier: (u['multiplier'] as num).toDouble(),
          cost: big(u['cost']),
        );
      }).toList(),
      prestige: PrestigeConfig(
        scale: big(p['scale']),
        base: (p['base'] as num).toDouble(),
        pairBonus: (p['pair_bonus'] as num).toDouble(),
        hilvanesPerPair: (p['hilvanes_per_pair'] as num).toDouble(),
        firstTargetPairs: (p['first_target_pairs'] as num).toInt(),
      ),
      offline: OfflineConfig(
        baseCapHours: (o['base_cap_hours'] as num).toDouble(),
        maxCapHours: (o['max_cap_hours'] as num).toDouble(),
      ),
      shop: ((j['prestige_shop'] as List?) ?? const []).map((raw) {
        final it = raw as Map<String, dynamic>;
        return ShopItem(
          id: it['id'] as String,
          name: it['name'] as String,
          description: it['description'] as String,
          type: it['type'] as String,
          levels: (it['levels'] as List).map((l) {
            final m = l as Map<String, dynamic>;
            return ShopLevel(
              cost: big(m['cost']),
              value: (m['value'] as num).toDouble(),
            );
          }).toList(),
        );
      }).toList(),
      goals: ((j['goals'] as List?) ?? const []).map((raw) {
        final m = raw as Map<String, dynamic>;
        return GoalConfig(
          id: m['id'] as String,
          name: m['name'] as String,
          type: m['type'] as String,
          target: big(m['target']),
          rewardMoney: big(m['reward_money'] ?? 0),
          rewardHilvanes: big(m['reward_hilvanes'] ?? 0),
          business: m['business'] as String?,
        );
      }).toList(),
      daily: j['daily'] == null
          ? null
          : DailyConfig(
              baseMoney: big((j['daily'] as Map)['base_money']),
              minutes: ((j['daily'] as Map)['minutes'] as num).toDouble(),
              bonusMinutesPerDay:
                  ((j['daily'] as Map)['bonus_minutes_per_day'] as num)
                      .toDouble(),
              hilvanesEvery: ((j['daily'] as Map)['hilvanes_every'] as num)
                  .toInt(),
              hilvanes: big((j['daily'] as Map)['hilvanes']),
            ),
      boost: BoostConfig(
        multiplier: (bo['multiplier'] as num).toDouble(),
        hoursPerView: (bo['hours_per_view'] as num).toDouble(),
        maxHours: (bo['max_hours'] as num).toDouble(),
      ),
    );
    config.validate();
    return config;
  }

  void validate() {
    if (businesses.isEmpty) {
      throw const FormatException('Sin negocios');
    }
    final ids = <String>{};
    for (final b in businesses) {
      if (!ids.add(b.id)) {
        throw FormatException('Negocio duplicado: ${b.id}');
      }
      if (b.coefficient <= 1) {
        throw FormatException('Coeficiente <= 1 en ${b.id}');
      }
      if (b.baseCycleSeconds <= 0) {
        throw FormatException('Ciclo <= 0 en ${b.id}');
      }
    }
    final upgradeIds = <String>{};
    for (final u in upgrades) {
      if (!upgradeIds.add(u.id)) {
        throw FormatException('Upgrade duplicado: ${u.id}');
      }
      if (u.target != 'all' && !ids.contains(u.target)) {
        throw FormatException('Upgrade ${u.id} apunta a negocio inexistente');
      }
    }
    for (var i = 1; i < thresholds.length; i++) {
      if (thresholds[i] <= thresholds[i - 1]) {
        throw const FormatException('Umbrales no crecientes');
      }
    }
    final shopIds = <String>{};
    for (final it in shop) {
      if (!shopIds.add(it.id)) {
        throw FormatException('Mejora duplicada: ${it.id}');
      }
      if (!ShopType.all.contains(it.type)) {
        throw FormatException('Tipo de mejora desconocido: ${it.type}');
      }
      if (it.levels.isEmpty) {
        throw FormatException('Mejora sin niveles: ${it.id}');
      }
    }
    final goalIds = <String>{};
    for (final g in goals) {
      if (!goalIds.add(g.id)) {
        throw FormatException('Meta duplicada: ${g.id}');
      }
      if (!GoalType.all.contains(g.type)) {
        throw FormatException('Tipo de meta desconocido: ${g.type}');
      }
      if (g.type == GoalType.own &&
          (g.business == null || !ids.contains(g.business))) {
        throw FormatException('Meta ${g.id} apunta a un negocio inexistente');
      }
      if (g.target <= BigNum.zero) {
        throw FormatException('Meta ${g.id} con objetivo <= 0');
      }
    }
    if (prestige.scale <= BigNum.zero) {
      throw const FormatException('S <= 0');
    }
  }

  int businessIndex(String id) => businesses.indexWhere((b) => b.id == id);
}
