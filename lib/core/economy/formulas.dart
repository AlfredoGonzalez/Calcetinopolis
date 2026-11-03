import 'dart:math' as math;

import '../big_num.dart';

/// Fórmulas puras de la sección 3.2 y 9.4 del spec.
class Formulas {
  Formulas._();

  /// r^k
  static BigNum _rPow(double r, int k) =>
      BigNum.pow10(k * (math.log(r) / math.ln10));

  /// Costo de la siguiente unidad: C = b * r^k, con k = unidades que ya tienes.
  static BigNum costNext(BigNum b, double r, int k) => b * _rPow(r, k);

  /// Costo de comprar n unidades de golpe: b * r^k * (r^n - 1) / (r - 1).
  static BigNum costBulk(BigNum b, double r, int k, int n) {
    if (n <= 0) return BigNum.zero;
    final rn = _rPow(r, n) - BigNum.one;
    return b * _rPow(r, k) * rn / BigNum.fromDouble(r - 1);
  }

  /// Máximo de unidades que alcanzas con [c] de dinero (botón Max):
  /// floor( ln(c (r-1) / (b r^k) + 1) / ln r ), corregido con la suma exacta
  /// para absorber errores de redondeo.
  static int maxAffordable(
    BigNum b,
    double r,
    int k,
    BigNum c, {
    int limit = 1 << 30,
  }) {
    if (c <= BigNum.zero || limit <= 0) return 0;
    final x = c * BigNum.fromDouble(r - 1) / (b * _rPow(r, k)) + BigNum.one;
    final raw = (x.ln() / math.log(r)).floor();
    var n = raw.clamp(0, limit);
    while (n > 0 && costBulk(b, r, k, n) > c) {
      n--;
    }
    while (n < limit && costBulk(b, r, k, n + 1) <= c) {
      n++;
    }
    return n;
  }

  /// Duración del ciclo: T = T_base / 2^h.
  static double cycleSeconds(double base, int halvings) =>
      base / math.pow(2, halvings);

  /// Ingreso de un ciclo: p * k * M.
  static BigNum cycleIncome(BigNum p, int k, BigNum multiplier) =>
      p * BigNum.fromInt(k) * multiplier;

  /// Parejas totales: P = floor(base * sqrt(E_vida / S)).
  static BigNum prestigeTotal(
    BigNum lifetime,
    BigNum scale, {
    double base = 150,
  }) {
    if (lifetime <= BigNum.zero) return BigNum.zero;
    return (BigNum.fromDouble(base) * (lifetime / scale).sqrt()).floor();
  }

  /// Inversa: E = S * (P / base)^2.
  static BigNum lifetimeForPairs(
    BigNum pairs,
    BigNum scale, {
    double base = 150,
  }) {
    final q = pairs / BigNum.fromDouble(base);
    return scale * q * q;
  }

  /// Multiplicador por Parejas: 1 + P * e (aditivo).
  static BigNum pairsMultiplier(BigNum pairs, double bonus) =>
      BigNum.one + pairs * BigNum.fromDouble(bonus);
}
