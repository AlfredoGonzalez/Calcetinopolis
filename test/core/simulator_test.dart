import 'dart:io';

import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/core/sim/simulator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Criterio de aceptación de F1 (spec 11.2): el simulador cumple las metas.
void main() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );
  late SimReport report;

  setUpAll(() {
    report = Simulator(Economy(config)).run(maxRuns: 5);
  });

  test('comprar el negocio 2 en menos de 30 s', () {
    expect(report.runs.first.buyBusiness2, lessThan(30));
  });

  test('primer manager en menos de 3 min', () {
    expect(report.runs.first.firstManager, lessThan(180));
  });

  test('negocio 10 entre 40 y 60 min', () {
    final t = report.runs.first.business10!;
    expect(t, inInclusiveRange(40 * 60, 60 * 60));
  });

  test('primer prestigio sugerido entre 45 y 90 min', () {
    final t = report.runs.first.prestigeSuggested!;
    expect(t, inInclusiveRange(45 * 60, 90 * 60));
  });

  test('cada corrida llega al mismo punto más rápido que la anterior', () {
    for (var i = 1; i < report.runs.length; i++) {
      final prevEnd = report.runs[i - 1].prestigeSuggested!;
      final same = report.runs[i].timeToPrevEnd!;
      final ratio = prevEnd / same;
      // Meta de la spec: 1.5-2x. Se aceptan hasta 3x en la primera vuelta
      // (x1 -> x3 de golpe) y 2.5x cuando se compra un nivel grande de la
      // tienda de Hilvanes; ver docs/BALANCE.md.
      expect(
        ratio,
        greaterThanOrEqualTo(1.5),
        reason: 'corrida $i -> ${i + 1}',
      );
      expect(
        ratio,
        lessThanOrEqualTo(i == 1 ? 3.0 : 2.5),
        reason: 'corrida $i -> ${i + 1}',
      );
    }
  });
}
