import 'dart:math' as math;

import '../big_num.dart';
import '../config/economy_config.dart';
import '../economy/engine.dart';
import '../number_format.dart';
import '../state/game_state.dart';

/// Un hito medido dentro de una corrida (entre dos Centrifugados).
class RunReport {
  RunReport(this.index);
  final int index;
  double? buyBusiness2;
  double? firstManager;
  double? business10;
  double? prestigeSuggested;
  BigNum pairsAtEnd = BigNum.zero;
  BigNum multiplierAtStart = BigNum.one;
  BigNum earnedInRun = BigNum.zero;

  /// Tiempo para igualar lo ganado en la corrida anterior ("mismo punto").
  double? timeToPrevEnd;
  bool timedOut = false;
}

class SimReport {
  SimReport(this.runs);
  final List<RunReport> runs;
}

/// Compra candidata evaluada por el bot.
class _Candidate {
  _Candidate(this.cost, this.apply, this.label);
  final BigNum cost;
  final void Function(GameState) apply;
  final String label;
  double payback = double.infinity;
}

/// Simulador sin interfaz (spec 11.2): un bot que compra lo de mejor retorno.
class Simulator {
  Simulator(
    this.economy, {
    this.dt = 1.0,
    this.tapDelay = 2.0,
    this.useShop = true,
    this.washerTapsPerSecond = 0,
  });

  /// Toques por segundo a la lavadora de un jugador que la usa todo el tiempo
  /// (0 = el bot no la toca, como en la calibración base).
  final double washerTapsPerSecond;
  double _tapAcc = 0;

  /// El bot gasta Hilvanes en la tienda de prestigio (la mejora más barata primero).
  final bool useShop;

  final Economy economy;
  final double dt;

  /// Retraso humano entre ciclos de un negocio sin manager (segundos).
  final double tapDelay;

  double _rate(GameState s) {
    var total = BigNum.zero;
    for (var i = 0; i < s.businesses.length; i++) {
      final b = s.businesses[i];
      if (b.owned == 0) continue;
      final cycle = economy.cycleSeconds(s, i);
      final eff = b.hasManager ? cycle : cycle + tapDelay;
      total += economy.incomePerCycle(s, i) / BigNum.fromDouble(eff);
    }
    return total.toDouble();
  }

  List<_Candidate> _candidates(GameState s) {
    final out = <_Candidate>[];
    for (var i = 0; i < s.businesses.length; i++) {
      final b = s.businesses[i];
      final room = economy.config.businesses[i].maxOwned - b.owned;
      if (room <= 0) continue;
      // Un negocio nuevo solo se considera si el anterior ya existe.
      if (b.owned == 0 && i > 0 && s.businesses[i - 1].owned == 0) continue;
      final name = economy.config.businesses[i].name;
      out.add(
        _Candidate(
          economy.costOf(s, i, 1),
          (st) => economy.buy(st, i, 1),
          'x1 $name',
        ),
      );
      final toNext = economy.unitsToNextThreshold(s, i);
      if (toNext != null && toNext > 1 && toNext <= room) {
        out.add(
          _Candidate(
            economy.costOf(s, i, toNext),
            (st) => economy.buy(st, i, toNext),
            'umbral $name',
          ),
        );
      }
      if (b.owned > 0 && !b.hasManager) {
        out.add(
          _Candidate(
            economy.config.businesses[i].manager.cost,
            (st) => economy.buyManager(st, i),
            'manager $name',
          ),
        );
      }
    }
    for (final u in economy.config.upgrades) {
      if (s.upgrades.contains(u.id)) continue;
      if (u.target != 'all' &&
          s.businesses[economy.config.businessIndex(u.target)].owned == 0) {
        continue;
      }
      out.add(_Candidate(u.cost, (st) => economy.buyUpgrade(st, u.id), u.id));
    }
    return out;
  }

  /// Juega [maxRuns] corridas; cada una termina al centrifugar o al agotar
  /// [maxRunSeconds].
  SimReport run({int maxRuns = 4, double maxRunSeconds = 6 * 3600}) {
    final s = economy.newGame();
    final runs = <RunReport>[];
    final firstTarget = BigNum.fromInt(
      economy.config.prestige.firstTargetPairs,
    );

    for (var r = 0; r < maxRuns; r++) {
      final report = RunReport(r)
        ..multiplierAtStart =
            BigNum.one +
            s.pairsClaimed.mulDouble(economy.config.prestige.pairBonus);
      runs.add(report);
      var t = 0.0;
      var cheapest = BigNum.zero;
      final lifetimeAtStart = s.lifetimeEarnings;
      final prevEarned = r > 0 ? runs[r - 1].earnedInRun : null;

      while (t < maxRunSeconds) {
        // Tocar negocios sin manager.
        for (var i = 0; i < s.businesses.length; i++) {
          economy.tap(s, i);
        }
        if (washerTapsPerSecond > 0) {
          _tapAcc += washerTapsPerSecond * dt;
          while (_tapAcc >= 1) {
            economy.tapWasher(s);
            _tapAcc -= 1;
          }
        }
        economy.tick(s, dt);
        t += dt;

        if (s.money >= cheapest) {
          cheapest = _shop(s);
        }

        report.buyBusiness2 ??= s.businesses[1].owned > 0 ? t : null;
        report.firstManager ??= s.businesses.any((b) => b.hasManager)
            ? t
            : null;
        report.business10 ??= s.businesses.last.owned > 0 ? t : null;

        if (prevEarned != null &&
            report.timeToPrevEnd == null &&
            s.lifetimeEarnings - lifetimeAtStart >= prevEarned) {
          report.timeToPrevEnd = t;
        }

        final pending = economy.pairsPending(s);
        final trigger = s.pairsClaimed > firstTarget
            ? s.pairsClaimed
            : firstTarget;
        if (pending >= trigger) {
          report.prestigeSuggested = t;
          break;
        }
      }
      if (report.prestigeSuggested == null) {
        report.timedOut = true;
        break;
      }
      report.pairsAtEnd = economy.pairsPending(s);
      report.earnedInRun = s.lifetimeEarnings - lifetimeAtStart;
      economy.prestige(s);
      if (useShop) _spendHilvanes(s);
    }
    return SimReport(runs);
  }

  void _spendHilvanes(GameState s) {
    while (true) {
      String? pick;
      BigNum? best;
      for (final it in economy.config.shop) {
        // Sin tocar la lavadora, sus mejoras no sirven.
        if (washerTapsPerSecond <= 0 &&
            (it.type == ShopType.tapPower || it.type == ShopType.washerMax)) {
          continue;
        }
        final next = economy.nextShopLevel(s, it.id);
        if (next == null || next.cost > s.hilvanes) continue;
        if (best == null || next.cost < best) {
          best = next.cost;
          pick = it.id;
        }
      }
      if (pick == null) return;
      economy.buyShop(s, pick);
    }
  }

  /// Compra mientras convenga. Devuelve el costo de la compra más barata
  /// (el bot no vuelve a evaluar hasta tener ese dinero).
  BigNum _shop(GameState s) {
    for (var guard = 0; guard < 500; guard++) {
      final cands = _candidates(s);
      if (cands.isEmpty) return BigNum.fromParts(1, 400);
      final base = _rate(s);
      for (final c in cands) {
        final probe = s.copy()..money = c.cost + BigNum.one;
        c.apply(probe);
        final gain = _rate(probe) - base;
        c.payback = gain > 0 ? c.cost.toDouble() / gain : double.infinity;
      }
      final useful = cands.where((c) => c.payback.isFinite).toList();
      if (useful.isEmpty) return BigNum.fromParts(1, 400);
      useful.sort((a, b) => a.payback.compareTo(b.payback));
      final best = useful.first;
      final minCost = useful.map((c) => c.cost).reduce((a, b) => a < b ? a : b);

      if (best.cost <= s.money) {
        best.apply(s);
        continue;
      }
      // El mejor aún no alcanza: compra algo más barato solo si se paga
      // antes de que juntemos para el mejor.
      final rate = math.max(base, 1e-9);
      final timeToBest = (best.cost - s.money).toDouble() / rate;
      final alt = useful
          .where((c) => c.cost <= s.money && c.payback <= timeToBest)
          .toList();
      if (alt.isNotEmpty) {
        alt.first.apply(s);
        continue;
      }
      return minCost;
    }
    return BigNum.zero;
  }

  static String format(SimReport report) {
    final f = const NumberFormatter();
    String t(double? v) {
      if (v == null) return '—';
      final m = (v / 60);
      return m < 120
          ? '${m.toStringAsFixed(1)} min'
          : '${(m / 60).toStringAsFixed(2)} h';
    }

    final b = StringBuffer()
      ..writeln(
        'Corrida | negocio 2 | 1er manager | negocio 10 | prestigio sugerido | Parejas | mult. inicial',
      )
      ..writeln(
        '--------|-----------|-------------|------------|--------------------|---------|--------------',
      );
    for (final r in report.runs) {
      b.writeln(
        '${r.index + 1} | ${t(r.buyBusiness2)} | ${t(r.firstManager)} | ${t(r.business10)} | '
        '${t(r.prestigeSuggested)}${r.timedOut ? " (tiempo agotado)" : ""} | ${f.format(r.pairsAtEnd)} | x${f.format(r.multiplierAtStart)}',
      );
    }
    for (var i = 1; i < report.runs.length; i++) {
      final prevEnd = report.runs[i - 1].prestigeSuggested;
      final same = report.runs[i].timeToPrevEnd;
      if (prevEnd != null && same != null && same > 0) {
        b.writeln(
          'Corrida $i → ${i + 1}: mismo punto ${(prevEnd / same).toStringAsFixed(2)}× más rápido',
        );
      }
    }
    return b.toString();
  }
}
