import 'dart:math' as math;

/// Número grande: valor = mantisa * 10^exponente, con 1 <= |mantisa| < 10
/// (o cero). El exponente es un `int`, así que no hay techo de ~1.8e308
/// como con `double` (spec 3.3 y 9.6).
class BigNum implements Comparable<BigNum> {
  const BigNum._(this.mantissa, this.exponent);

  final double mantissa;
  final int exponent;

  static const BigNum zero = BigNum._(0, 0);
  static const BigNum one = BigNum._(1, 0);

  factory BigNum.fromParts(double mantissa, int exponent) {
    if (mantissa == 0 || mantissa.isNaN) return zero;
    if (mantissa.isInfinite) {
      throw ArgumentError('Mantisa infinita');
    }
    final shift = (math.log(mantissa.abs()) / math.ln10).floor();
    var m = mantissa / math.pow(10, shift);
    var e = exponent + shift;
    // Corrige errores de redondeo en el borde.
    if (m.abs() >= 10) {
      m /= 10;
      e += 1;
    } else if (m.abs() < 1) {
      m *= 10;
      e -= 1;
    }
    return BigNum._(m, e);
  }

  factory BigNum.fromDouble(double value) {
    if (value.isNaN || value.isInfinite) {
      throw ArgumentError('Valor no finito: $value');
    }
    return BigNum.fromParts(value, 0);
  }

  factory BigNum.fromInt(int value) => BigNum.fromDouble(value.toDouble());

  /// Acepta "123", "1.5", "2.15e10", "-3e-4".
  factory BigNum.parse(String text) {
    final t = text.trim().toLowerCase();
    final match = RegExp(r'^(-?\d+(?:\.\d+)?|-?\.\d+)(?:e([+-]?\d+))?$')
        .firstMatch(t);
    if (match == null) throw FormatException('Número inválido: "$text"');
    final m = double.parse(match.group(1)!);
    final e = match.group(2) == null ? 0 : int.parse(match.group(2)!);
    return BigNum.fromParts(m, e);
  }

  /// 10^x para x real (puede ser enorme).
  factory BigNum.pow10(double x) {
    final intPart = x.floor();
    final frac = x - intPart;
    return BigNum.fromParts(math.pow(10, frac).toDouble(), intPart);
  }

  bool get isZero => mantissa == 0;
  bool get isNegative => mantissa < 0;
  bool get isPositive => mantissa > 0;

  BigNum operator -() => isZero ? this : BigNum._(-mantissa, exponent);

  BigNum operator +(BigNum o) {
    if (isZero) return o;
    if (o.isZero) return this;
    BigNum big = this, small = o;
    if (exponent < o.exponent ||
        (exponent == o.exponent && mantissa.abs() < o.mantissa.abs())) {
      big = o;
      small = this;
    }
    final diff = big.exponent - small.exponent;
    if (diff > 17) return big;
    return BigNum.fromParts(
      big.mantissa + small.mantissa / math.pow(10, diff),
      big.exponent,
    );
  }

  BigNum operator -(BigNum o) => this + (-o);

  BigNum operator *(BigNum o) {
    if (isZero || o.isZero) return zero;
    return BigNum.fromParts(mantissa * o.mantissa, exponent + o.exponent);
  }

  BigNum operator /(BigNum o) {
    if (o.isZero) throw ArgumentError('División entre cero');
    if (isZero) return zero;
    return BigNum.fromParts(mantissa / o.mantissa, exponent - o.exponent);
  }

  BigNum mulDouble(double d) => this * BigNum.fromDouble(d);

  /// this^p para base positiva y p real.
  BigNum pow(double p) {
    if (p == 0) return one;
    if (isZero) return zero;
    if (isNegative) throw ArgumentError('Potencia de negativo no soportada');
    return BigNum.pow10(log10() * p);
  }

  BigNum sqrt() {
    if (isNegative) throw ArgumentError('Raíz de negativo');
    if (isZero) return zero;
    if (exponent.isEven) {
      return BigNum.fromParts(math.sqrt(mantissa), exponent ~/ 2);
    }
    return BigNum.fromParts(math.sqrt(mantissa * 10), (exponent - 1) ~/ 2);
  }

  double log10() {
    if (mantissa <= 0) throw ArgumentError('log de no positivo');
    return exponent + math.log(mantissa) / math.ln10;
  }

  double ln() => log10() * math.ln10;

  /// Parte entera hacia -infinito. Por encima de 1e15 todo `double` ya es
  /// entero, así que el valor se devuelve igual.
  BigNum floor() {
    if (isZero) return this;
    if (exponent >= 15) return this;
    if (exponent < 0) return isNegative ? BigNum.fromInt(-1) : zero;
    return BigNum.fromDouble(toDouble().floorToDouble());
  }

  /// Convierte a double; satura en ±double.maxFinite.
  double toDouble() {
    if (isZero) return 0;
    if (exponent > 308) {
      return isNegative ? -double.maxFinite : double.maxFinite;
    }
    if (exponent < -320) return 0;
    return mantissa * math.pow(10, exponent);
  }

  /// Entero si cabe; si no, satura.
  int toInt() {
    final d = toDouble();
    if (d >= 9.0e18) return 9000000000000000000;
    if (d <= -9.0e18) return -9000000000000000000;
    return d.floor();
  }

  BigNum max(BigNum o) => this >= o ? this : o;
  BigNum min(BigNum o) => this <= o ? this : o;

  @override
  int compareTo(BigNum o) {
    if (isZero && o.isZero) return 0;
    if (isNegative != o.isNegative || isZero || o.isZero) {
      final a = isZero ? 0 : (isNegative ? -1 : 1);
      final b = o.isZero ? 0 : (o.isNegative ? -1 : 1);
      return a.compareTo(b);
    }
    final sign = isNegative ? -1 : 1;
    if (exponent != o.exponent) return exponent.compareTo(o.exponent) * sign;
    return mantissa.compareTo(o.mantissa);
  }

  bool operator <(BigNum o) => compareTo(o) < 0;
  bool operator <=(BigNum o) => compareTo(o) <= 0;
  bool operator >(BigNum o) => compareTo(o) > 0;
  bool operator >=(BigNum o) => compareTo(o) >= 0;

  @override
  bool operator ==(Object other) =>
      other is BigNum &&
      mantissa == other.mantissa &&
      exponent == other.exponent;

  @override
  int get hashCode => Object.hash(mantissa, exponent);

  /// Forma para JSON/guardado: string en notación científica (spec 9.6).
  String toJson() {
    if (isZero) return '0';
    return '${mantissa.toString()}e$exponent';
  }

  @override
  String toString() => toJson();
}
