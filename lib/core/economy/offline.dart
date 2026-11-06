import '../big_num.dart';
import '../state/game_state.dart';
import 'engine.dart';

/// Resultado de calcular lo ganado con la app cerrada.
class OfflineReport {
  const OfflineReport({
    required this.gain,
    required this.secondsAway,
    required this.secondsCounted,
    required this.clockWentBack,
  });

  final BigNum gain;

  /// Tiempo real fuera (0 si el reloj retrocedió).
  final double secondsAway;

  /// Tiempo que sí cuenta, ya limitado por el tope.
  final double secondsCounted;
  final bool clockWentBack;

  bool get capped => secondsCounted < secondsAway;
  static const none = OfflineReport(
    gain: BigNum.zero,
    secondsAway: 0,
    secondsCounted: 0,
    clockWentBack: false,
  );
}

/// Anti-trampa de reloj (spec 9.5): si el reloj retrocede no hay ganancia, y
/// el exceso sobre el tope se ignora, así que adelantar el reloj no sirve de
/// más de [capHours].
OfflineReport computeOffline(
  Economy eco,
  GameState s, {
  required DateTime lastSeen,
  required DateTime now,
  double? capHours,
}) {
  final raw = now.difference(lastSeen).inMilliseconds / 1000.0;
  if (raw < 0) {
    return const OfflineReport(
      gain: BigNum.zero,
      secondsAway: 0,
      secondsCounted: 0,
      clockWentBack: true,
    );
  }
  final cap = eco.offlineCapSeconds(
    capHours ?? eco.config.offline.baseCapHours,
  );
  final counted = raw < cap ? raw : cap;
  return OfflineReport(
    gain: eco.offlineGain(s, raw, capHours: capHours),
    secondsAway: raw,
    secondsCounted: counted,
    clockWentBack: false,
  );
}
