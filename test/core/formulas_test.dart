import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/economy/formulas.dart';
import 'package:flutter_test/flutter_test.dart';

BigNum n(String s) => BigNum.parse(s);

void main() {
  group('Costo (3.2)', () {
    test('costNext = b * r^k', () {
      expect(Formulas.costNext(n('4'), 1.07, 0).toDouble(), closeTo(4, 1e-9));
      expect(
        Formulas.costNext(n('60'), 1.15, 10).toDouble(),
        closeTo(60 * 4.0455577357, 1e-6),
      );
    });

    test('costBulk(n) es la suma de comprar uno por uno (sin descuento)', () {
      for (final (b, r, k, count) in [
        (4.0, 1.07, 0, 10),
        (50.0, 1.14, 25, 100),
        (600.0, 1.13, 7, 33),
        (21.5e9, 1.07, 400, 100),
      ]) {
        var sum = BigNum.zero;
        for (var i = 0; i < count; i++) {
          sum += Formulas.costNext(BigNum.fromDouble(b), r, k + i);
        }
        final bulk = Formulas.costBulk(BigNum.fromDouble(b), r, k, count);
        expect(
          (bulk / sum).toDouble(),
          closeTo(1, 1e-9),
          reason: '$b $r $k $count',
        );
      }
      expect(Formulas.costBulk(n('4'), 1.07, 0, 0), BigNum.zero);
    });

    test('maxAffordable: n unidades alcanzan y n+1 no', () {
      final cases = [
        (n('4'), 1.07, 1, n('100')),
        (n('50'), 1.14, 3, n('1e6')),
        (n('600'), 1.13, 0, n('599')),
        (n('600'), 1.13, 0, n('600')),
        (n('7200'), 1.12, 40, n('1e15')),
        (n('21.5e9'), 1.07, 10, n('1e30')),
      ];
      for (final (b, r, k, c) in cases) {
        final m = Formulas.maxAffordable(b, r, k, c);
        if (m > 0) expect(Formulas.costBulk(b, r, k, m) <= c, isTrue);
        expect(Formulas.costBulk(b, r, k, m + 1) > c, isTrue);
      }
    });

    test('maxAffordable con 0 dinero y con límite', () {
      expect(Formulas.maxAffordable(n('4'), 1.07, 1, BigNum.zero), 0);
      expect(Formulas.maxAffordable(n('4'), 1.07, 0, n('1e30'), limit: 50), 50);
    });
  });

  group('Ciclo e ingreso', () {
    test('T = T_base / 2^h', () {
      expect(Formulas.cycleSeconds(10800, 0), 10800);
      expect(Formulas.cycleSeconds(10800, 12), closeTo(10800 / 4096, 1e-12));
    });

    test('ingreso por ciclo = p * k * M', () {
      expect(Formulas.cycleIncome(n('40'), 10, n('3')), n('1200'));
    });
  });

  group('Prestigio (9.4 y tabla 5.1 con S = 1e15)', () {
    final s = n('1e15');
    test('tabla de referencia', () {
      expect(Formulas.prestigeTotal(n('1e12'), s), BigNum.fromInt(4));
      expect(Formulas.prestigeTotal(n('1e15'), s), BigNum.fromInt(150));
      expect(Formulas.prestigeTotal(n('1e18'), s), BigNum.fromInt(4743));
      expect(Formulas.prestigeTotal(n('1e21'), s), BigNum.fromInt(150000));
      expect(Formulas.prestigeTotal(n('1e24'), s), BigNum.fromInt(4743416));
      expect(Formulas.prestigeTotal(n('44444444445'), s), BigNum.one);
    });

    test('debajo de la primera pareja da cero', () {
      expect(Formulas.prestigeTotal(n('1e10'), s), BigNum.zero);
      expect(Formulas.prestigeTotal(BigNum.zero, s), BigNum.zero);
    });

    test('la inversa recupera E', () {
      expect(Formulas.lifetimeForPairs(n('150'), s), n('1e15'));
      final e = Formulas.lifetimeForPairs(n('4743'), s);
      expect(Formulas.prestigeTotal(e, s), BigNum.fromInt(4743));
    });

    test('S escala la fórmula', () {
      expect(Formulas.prestigeTotal(n('1e14'), n('1e14')), BigNum.fromInt(150));
    });

    test('multiplicador aditivo: 50 parejas = x2, 1000 = x21', () {
      expect(
        Formulas.pairsMultiplier(n('50'), 0.02).toDouble(),
        closeTo(2, 1e-12),
      );
      expect(
        Formulas.pairsMultiplier(n('1000'), 0.02).toDouble(),
        closeTo(21, 1e-12),
      );
      expect(Formulas.pairsMultiplier(BigNum.zero, 0.02), BigNum.one);
    });
  });
}
