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
  static const contentHeight = 74.0;

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
        padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
        child: Row(
          children: [
            GainPulse(
              value: c.state.money,
              minRatio: 1.5,
              child: const Art('icon_pelusitas', size: 38),
            ),
            const SizedBox(width: 8),
            // El dinero cede espacio antes de que algo se desborde.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.format(c.state.money),
                      key: const Key('money'),
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: Ui.headerText,
                      ),
                    ),
                    if (rate.isPositive)
                      Text(
                        '+${f.format(rate)} pelusas/seg',
                        key: const Key('income-rate'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Ui.headerSub,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.washerBonus >= 0.005) ...[
                      _Pill(
                        key: const Key('washer-chip'),
                        color: Ui.teal,
                        child: Text(
                          '+${(c.washerBonus * 100).round()}%',
                          style: const TextStyle(
                            color: Ui.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (c.state.boostSeconds > 0) ...[
                      _Pill(
                        key: const Key('boost-chip'),
                        color: Ui.orange,
                        child: Text(
                          'x2 ${formatDuration(c.state.boostSeconds)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (c.state.goldButtons.isPositive) ...[
                      _Pill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GainPulse(
                              value: c.state.goldButtons,
                              child: const Art(
                                'icon_botones_dorados',
                                size: 22,
                              ),
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
                    ],
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
                  ],
                ),
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
  const _Pill({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? const Color(0x29FFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
