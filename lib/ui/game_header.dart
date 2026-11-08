import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import 'art.dart';
import 'effects.dart';
import 'offline_dialog.dart';
import 'theme.dart';

/// Encabezado del juego: Pelusitas con su ritmo por segundo, boost, Botones
/// Dorados, Parejas y Ajustes, sobre una barra azul con esquinas redondeadas.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.controller,
    required this.onSettings,
  });

  final GameController controller;
  final VoidCallback onSettings;

  /// Alto del contenido, sin la barra de estado.
  static const contentHeight = 84.0;

  static double heightFor(BuildContext context) =>
      MediaQuery.paddingOf(context).top + contentHeight;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final f = c.formatter;
    final rate = c.economy.managedIncomePerSecond(c.state);
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Ui.navy1, Ui.navy2],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
        child: Row(
          children: [
            GainPulse(
              value: c.state.money,
              minRatio: 1.5,
              child: const Art('icon_pelusitas', size: 38),
            ),
            const SizedBox(width: 8),
            // Izquierda: las pelusas, su ritmo y los bonos temporales. Lo que
            // aparece o desaparece aquí nunca mueve los botones de la derecha.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      f.format(c.state.money),
                      key: const Key('money'),
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: Ui.headerText,
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      rate.isPositive ? '+${f.format(rate)} pelusas/seg' : ' ',
                      key: const Key('income-rate'),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                        color: Ui.headerSub,
                      ),
                    ),
                  ),
                  // Los bonos temporales tienen su renglón reservado: al
                  // aparecer o desaparecer no mueven nada.
                  SizedBox(
                    height: 22,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.washerBonus >= 0.005)
                            _Tag(
                              key: const Key('washer-chip'),
                              color: Ui.teal,
                              text: '+${(c.washerBonus * 100).round()}%',
                            ),
                          if (c.washerBonus >= 0.005 &&
                              c.state.boostSeconds > 0)
                            const SizedBox(width: 6),
                          if (c.state.boostSeconds > 0)
                            _Tag(
                              key: const Key('boost-chip'),
                              color: Ui.orange,
                              textColor: Colors.white,
                              text:
                                  'x2 ${formatDuration(c.state.boostSeconds)}',
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Derecha: siempre en el mismo lugar.
            _Pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GainPulse(
                    value: c.state.goldButtons,
                    child: const Art('icon_botones_dorados', size: 22),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    f.format(c.state.goldButtons),
                    key: const Key('gold-top'),
                    style: _pillText,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _Pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GainPulse(
                    value: c.state.pairsClaimed,
                    child: const Art('icon_pareja_reunida', size: 24),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    f.format(c.state.pairsClaimed),
                    key: const Key('pairs-top'),
                    style: _pillText,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              key: const Key('settings'),
              tooltip: 'Ajustes',
              onPressed: onSettings,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x29FFFFFF),
                fixedSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Art(
                'icon_ui_ajustes',
                size: 28,
                fallback: Icons.settings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _pillText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Ui.headerText,
);

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0x29FFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

/// Etiqueta pequeña de un bono temporal bajo la cifra de pelusas.
class _Tag extends StatelessWidget {
  const _Tag({
    super.key,
    required this.color,
    required this.text,
    this.textColor = Ui.ink,
  });

  final Color color;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
