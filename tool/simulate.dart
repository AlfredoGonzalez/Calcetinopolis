// Simulador de balance sin interfaz.
// Uso: dart run tool/simulate.dart [config/economy.json] [corridas]
import 'dart:io';

import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/core/sim/simulator.dart';

void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : 'config/economy.json';
  final runs = args.length > 1 ? int.parse(args[1]) : 4;
  final config = EconomyConfig.fromJsonString(File(path).readAsStringSync());
  final report = Simulator(Economy(config)).run(maxRuns: runs);
  stdout.write(Simulator.format(report));
}
