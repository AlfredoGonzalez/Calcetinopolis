import 'big_num.dart';

enum NumberFormatMode { shortSuffix, names, scientific }

/// Formato de números (spec 9.6).
///
/// Sufijos cortos: K, M, B, T y luego aa, ab, ac... az, ba, bb...
/// ("B" es 10^9; en México "billón" es 10^12, por eso existe el modo nombres).
class NumberFormatter {
  const NumberFormatter({this.mode = NumberFormatMode.shortSuffix});

  final NumberFormatMode mode;

  static const _fixed = ['', 'K', 'M', 'B', 'T'];

  /// Sufijo para el grupo de 3 cifras `group` (1 = K, 2 = M, ...).
  static String suffixFor(int group) {
    if (group < _fixed.length) return _fixed[group];
    var n = group - _fixed.length; // 0 -> aa
    final first = n ~/ 26;
    final second = n % 26;
    String letter(int i) => String.fromCharCode(97 + i);
    return '${letter(first % 26)}${letter(second)}';
  }

  static const _names = <int, String>{
    6: 'millón',
    9: 'mil millones',
    12: 'billón',
    15: 'mil billones',
    18: 'trillón',
    21: 'mil trillones',
    24: 'cuatrillón',
  };

  String format(BigNum value, {int decimals = 2}) {
    if (value.isZero) return '0';
    final sign = value.isNegative ? '-' : '';
    final v = value.isNegative ? -value : value;
    final e = v.exponent;

    if (e < 3) {
      // Números pequeños: se muestran tal cual, con decimales útiles.
      final d = v.toDouble();
      final text = e < 0 || d < 100
          ? _trim(d.toStringAsFixed(decimals))
          : d.floor().toString();
      return '$sign$text';
    }
    if (mode == NumberFormatMode.scientific) {
      return '$sign${_trim(v.mantissa.toStringAsFixed(decimals))}e$e';
    }
    if (mode == NumberFormatMode.names && e < 27) {
      final step = _names.keys
          .where((k) => k <= e)
          .fold<int>(-1, (a, b) => b > a ? b : a);
      if (step >= 0) {
        final scaled = v.mantissa * _pow10(e - step);
        return '$sign${_trim(scaled.toStringAsFixed(decimals))} ${_plural(_names[step]!, scaled)}';
      }
      return '$sign${_group(v)}';
    }
    if (mode == NumberFormatMode.names) {
      return '$sign${_trim(v.mantissa.toStringAsFixed(decimals))}e$e';
    }
    final group = e ~/ 3;
    final scaled = v.mantissa * _pow10(e - group * 3);
    return '$sign${_trim(scaled.toStringAsFixed(decimals))}${suffixFor(group)}';
  }

  static double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  static String _trim(String s) {
    if (!s.contains('.')) return s;
    var t = s.replaceFirst(RegExp(r'0+$'), '');
    if (t.endsWith('.')) t = t.substring(0, t.length - 1);
    return t;
  }

  static String _plural(String name, double scaled) {
    if (scaled < 2) return name;
    // "mil millones", "mil billones"... ya vienen en plural.
    if (name.startsWith('mil ')) return name;
    // millón -> millones, billón -> billones, trillón -> trillones.
    return name.replaceFirst('ón', 'ones');
  }

  static String _group(BigNum v) {
    final s = v.toDouble().floor().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
