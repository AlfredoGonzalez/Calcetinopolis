import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/number_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const f = NumberFormatter();
  String s(String n) => f.format(BigNum.parse(n));

  test('números pequeños', () {
    expect(s('0'), '0');
    expect(s('4.28'), '4.28');
    expect(s('1'), '1');
    expect(s('999'), '999');
  });

  test('sufijos K, M, B, T', () {
    expect(s('1500'), '1.5K');
    expect(s('2.15e6'), '2.15M');
    expect(s('3e9'), '3B');
    expect(s('7.77e12'), '7.77T');
  });

  test('después de T siguen aa, ab, ac...', () {
    expect(s('1e15'), '1aa');
    expect(s('1e18'), '1ab');
    expect(s('2.5e21'), '2.5ac');
    expect(NumberFormatter.suffixFor(5), 'aa');
    expect(NumberFormatter.suffixFor(5 + 25), 'az');
    expect(NumberFormatter.suffixFor(5 + 26), 'ba');
  });

  test('notación científica', () {
    const sci = NumberFormatter(mode: NumberFormatMode.scientific);
    expect(sci.format(BigNum.parse('1.5e12')), '1.5e12');
    expect(sci.format(BigNum.parse('999')), '999');
  });

  test('nombres en español: billón es 10^12', () {
    const n = NumberFormatter(mode: NumberFormatMode.names);
    expect(n.format(BigNum.parse('3e6')), '3 millones');
    expect(n.format(BigNum.parse('2e9')), '2 mil millones');
    expect(n.format(BigNum.parse('1e12')), '1 billón');
    expect(n.format(BigNum.parse('4e12')), '4 billones');
    expect(n.format(BigNum.parse('1e40')), '1e40');
  });

  test('negativos', () {
    expect(f.format(BigNum.parse('-2500')), '-2.5K');
  });
}
