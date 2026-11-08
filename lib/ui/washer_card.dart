import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/game_controller.dart';
import 'art.dart';
import 'theme.dart';
import 'ui_kit.dart';

/// La lavadora que se toca: cada toque suma un bono temporal de velocidad que
/// se consume solo en cuanto se deja de tocar, como la batería de la lavadora.
class WasherCard extends StatefulWidget {
  const WasherCard({super.key, required this.controller});

  final GameController controller;

  @override
  State<WasherCard> createState() => _WasherCardState();
}

class _WasherCardState extends State<WasherCard>
    with SingleTickerProviderStateMixin {
  /// Rebote y burbujas de cada toque (una sola vez, sin repetirse).
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  int _taps = 0;

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _tap() {
    widget.controller.tapWasher();
    _taps++;
    if (widget.controller.state.settings.vibration) {
      HapticFeedback.selectionClick();
    }
    if (!MediaQuery.disableAnimationsOf(context)) _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final fill = c.washerFill;
    final pct = (c.washerBonus * 100).round();
    final maxPct = (c.washerMax * 100).round();
    final reduce = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      key: const Key('washer'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _tap(),
      child: UiCard(
        edge: Ui.tealSoft,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: AnimatedBuilder(
                animation: _pop,
                builder: (context, child) {
                  final t = _pop.value;
                  final bounce = t == 0 || t == 1 ? 0.0 : math.sin(math.pi * t);
                  // Tiembla más cuanto más energía tiene.
                  final shake = reduce
                      ? 0.0
                      : math.sin(c.fxTime * 38) * 0.05 * fill;
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: shake,
                        child: Transform.scale(
                          scale: 1 - 0.1 * bounce,
                          child: child,
                        ),
                      ),
                      if (t > 0 && t < 1)
                        for (var i = 0; i < 3; i++)
                          Positioned(
                            left: 18.0 + ((_taps * 37 + i * 53) % 48),
                            top: 36 - 54 * t - i * 6,
                            child: Opacity(
                              opacity: 1 - t,
                              child: Container(
                                width: 9 + (i * 3).toDouble(),
                                height: 9 + (i * 3).toDouble(),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  border: Border.all(
                                    color: Ui.blue,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  );
                },
                child: const Art(
                  'anim_centrifugado_lavadora',
                  size: 78,
                  fallback: Icons.local_laundry_service,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lavadora',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '+$pct%',
                        key: const Key('washer-bonus'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: pct > 0 ? Ui.tealEdge : Ui.ink2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      height: 14,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Ui.track),
                          FractionallySizedBox(
                            key: const Key('washer-bar'),
                            alignment: Alignment.centerLeft,
                            widthFactor: fill,
                            heightFactor: 1,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Ui.teal, Ui.yellow, Ui.orange],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pct > 0
                        ? 'Se consume si dejas de tocar (máx. +$maxPct%)'
                        : '¡Toca para lavar! Hasta +$maxPct% de velocidad',
                    key: const Key('washer-hint'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Ui.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
