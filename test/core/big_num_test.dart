import 'package:calcetinopolis/core/big_num.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BigNum', () {
    test('normaliza mantisa y exponente', () {
      final n = BigNum.fromDouble(12345);
      expect(n.exponent, 4);
      expect(n.mantissa, closeTo(1.2345, 1e-12));
      expect(BigNum.fromDouble(0.05).exponent, -2);
      expect(BigNum.fromDouble(0).isZero, isTrue);
    });

    test('parse y JSON van y vienen', () {
      for (final s in [
        '0',
        '4',
        '1.07',
        '2.15e10',
        '9e-3',
        '1e400',
        '3.5e1000',
      ]) {
        final n = BigNum.parse(s);
        expect(BigNum.parse(n.toJson()), n, reason: s);
      }
      expect(() => BigNum.parse('abc'), throwsFormatException);
    });

    test('supera el límite de double (1.8e308)', () {
      final big = BigNum.parse('1e400') * BigNum.parse('1e400');
      expect(big.exponent, 800);
      expect((big / BigNum.parse('1e400')), BigNum.parse('1e400'));
    });

    test('suma, resta, producto y cociente', () {
      expect(BigNum.fromInt(2) + BigNum.fromInt(3), BigNum.fromInt(5));
      expect(BigNum.fromInt(5) - BigNum.fromInt(3), BigNum.fromInt(2));
      expect(BigNum.fromInt(6) * BigNum.fromInt(7), BigNum.fromInt(42));
      expect(BigNum.fromInt(42) / BigNum.fromInt(6), BigNum.fromInt(7));
      expect(BigNum.fromInt(3) - BigNum.fromInt(3), BigNum.zero);
      expect((BigNum.fromInt(3) - BigNum.fromInt(5)).isNegative, isTrue);
    });

    test('sumar magnitudes muy distintas conserva la mayor', () {
      final a = BigNum.parse('1e100');
      expect(a + BigNum.one, a);
      expect(BigNum.one + a, a);
    });

    test('comparaciones', () {
      expect(BigNum.parse('1e10') > BigNum.parse('9e9'), isTrue);
      expect(BigNum.parse('2e5') < BigNum.parse('3e5'), isTrue);
      expect(BigNum.zero < BigNum.one, isTrue);
      expect(BigNum.parse('-5') < BigNum.zero, isTrue);
      expect(BigNum.parse('-5') < BigNum.parse('-2'), isTrue);
      expect(BigNum.parse('4e3').compareTo(BigNum.parse('4e3')), 0);
    });

    test('sqrt con exponente par e impar', () {
      expect(BigNum.parse('1e20').sqrt(), BigNum.parse('1e10'));
      expect(
        BigNum.parse('1e21').sqrt().toDouble(),
        closeTo(3.1622776601683795e10, 1),
      );
      expect(BigNum.parse('16').sqrt(), BigNum.fromInt(4));
      expect(BigNum.zero.sqrt(), BigNum.zero);
    });

    test('pow, log10 y pow10', () {
      expect(BigNum.fromInt(2).pow(10).toDouble(), closeTo(1024, 1e-9));
      expect(BigNum.parse('1e100').log10(), closeTo(100, 1e-12));
      expect(BigNum.pow10(2.5).toDouble(), closeTo(316.227766, 1e-5));
      expect(BigNum.fromInt(5).pow(0), BigNum.one);
    });

    test('floor', () {
      expect(BigNum.fromDouble(4.99).floor(), BigNum.fromInt(4));
      expect(BigNum.fromDouble(0.4).floor(), BigNum.zero);
      expect(BigNum.parse('1.5e30').floor(), BigNum.parse('1.5e30'));
    });

    test('toDouble satura y toInt', () {
      expect(BigNum.parse('1e400').toDouble(), double.maxFinite);
      expect(BigNum.parse('1e-400').toDouble(), 0);
      expect(BigNum.fromInt(1234).toInt(), 1234);
    });

    test('división entre cero lanza error', () {
      expect(() => BigNum.one / BigNum.zero, throwsArgumentError);
    });
  });
}
