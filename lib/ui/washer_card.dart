import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/game_controller.dart';
import 'art.dart';
import 'theme.dart';

/// La lavadora que se toca, protagonista de Negocios pero compacta (para que
/// quepan 2 o 3 negocios debajo): la lavadora con dos mascotas asomándose, y a
/// su lado la energía. Cada toque suma un bono temporal de velocidad que se
/// consume solo en cuanto se deja de tocar, como la batería de la lavadora.
class WasherCard extends StatefulWidget {
  const WasherCard({super.key, required this.controller});

  final GameController controller;

  @override
  State<WasherCard> createState() => _WasherCardState();
}

class _WasherCardState extends State<WasherCard>
    with SingleTickerProviderStateMixin {
  /// Rebote, burbujas y salto de las mascotas en cada toque (una sola vez).
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
    final reduce = MediaQuery.disableAnimationsOf(context);
    // Compacta; en pantallas bajas se encoge un poco más.
    final h = MediaQuery.sizeOf(context).height;
    final k = h < 720 ? 0.44 : (h < 800 ? 0.5 : 0.58);
    final washer = 205 * k;
    final mascot = 112 * k;
    return GestureDetector(
      key: const Key('washer'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _tap(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pop,
            builder: (context, _) {
              final t = _pop.value;
              final bounce = t == 0 || t == 1 ? 0.0 : math.sin(math.pi * t);
              final time = c.fxTime;
              // Las mascotas se asoman y se mecen; con cada toque saltan.
              double bob(double phase) => reduce
                  ? 0
                  : -3 * math.sin(time * 2.2 + phase).abs() - 16 * bounce;
              // La lavadora tiembla más cuanto más energía tiene.
              final shake = reduce ? 0.0 : math.sin(time * 38) * 0.04 * fill;
              return SizedBox(
                width: washer + 24,
                height: washer + 34 * k,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    for (final (dx, tilt, flip, phase) in const [
                      (-38.0, -0.14, false, 0.0),
                      (38.0, 0.14, true, 1.7),
                    ])
                      Positioned(
                        top: -2 * k,
                        left: 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Transform.translate(
                            offset: Offset(dx * k, bob(phase)),
                            child: Transform.rotate(
                              angle: tilt,
                              child: Transform.flip(
                                flipX: flip,
                                child: Art(
                                  'mascota_reposo',
                                  size: mascot,
                                  fallback: Icons.emoji_emotions,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    for (final (x, y, size, phase) in const [
                      (-110.0, 24.0, 22.0, 0.0),
                      (112.0, 60.0, 16.0, 2.1),
                      (-96.0, 108.0, 14.0, 4.0),
                    ])
                      Positioned(
                        top: y * k,
                        left: 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Transform.translate(
                            offset: Offset(x * k, 0),
                            child: Opacity(
                              opacity: reduce
                                  ? 0.8
                                  : 0.35 +
                                        0.65 *
                                            (0.5 +
                                                0.5 *
                                                    math.sin(time * 3 + phase)),
                              child: Icon(
                                Icons.star_rounded,
                                size: size,
                                color: Ui.yellow,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 34 * k,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Transform.rotate(
                          angle: shake,
                          child: Transform.scale(
                            scale: 1 - 0.08 * bounce,
                            child: Art(
                              'anim_centrifugado_lavadora',
                              size: washer,
                              fallback: Icons.local_laundry_service,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (t > 0 && t < 1)
                      for (var i = 0; i < 3; i++)
                        Positioned(
                          top: (60 - 70 * t - i * 8) * k + 28 * k,
                          left: 0,
                          right: 0,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Transform.translate(
                              offset: Offset(
                                (((_taps * 37 + i * 53) % 90) - 45) * k,
                                0,
                              ),
                              child: Opacity(
                                opacity: 1 - t,
                                child: Container(
                                  width: 10 + (i * 4).toDouble(),
                                  height: 10 + (i * 4).toDouble(),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    border: Border.all(
                                      color: Ui.blue,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          // La energía, a un lado de la lavadora.
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Ui.ink, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Ui.tealSoft, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '+$pct%',
                          key: const Key('washer-bonus'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: pct > 0 ? Ui.tealEdge : Ui.ink2,
                          ),
                        ),
                        const Text(
                          ' velocidad',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 12,
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
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      pct > 0
                          ? 'Se consume si dejas de tocar'
                          : '¡Toca para lavar!',
                      key: const Key('washer-hint'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Ui.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
