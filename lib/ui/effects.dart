import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/big_num.dart';
import 'theme.dart';

/// Pulso con destello cuando [value] sube.
///
/// Con [minRatio] solo se dispara si el valor crece al menos esa proporción
/// de golpe (para que las Pelusitas solo brillen con premios grandes y no con
/// el ingreso continuo). Con "reducir animaciones" no hace nada.
class GainPulse extends StatefulWidget {
  const GainPulse({
    super.key,
    required this.value,
    required this.child,
    this.minRatio,
  });

  final BigNum value;
  final Widget child;
  final double? minRatio;

  @override
  State<GainPulse> createState() => _GainPulseState();
}

class _GainPulseState extends State<GainPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool _gained(BigNum old, BigNum now) {
    if (now <= old) return false;
    final r = widget.minRatio;
    if (r == null) return true;
    return old.isPositive && now >= old.mulDouble(r);
  }

  @override
  void didUpdateWidget(GainPulse old) {
    super.didUpdateWidget(old);
    if (_gained(old.value, widget.value) &&
        !MediaQuery.disableAnimationsOf(context)) {
      _anim.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      child: widget.child,
      builder: (context, child) {
        final t = _anim.value;
        if (t == 0 || t == 1) return child!;
        final k = math.sin(math.pi * t);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + 0.3 * k,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Palette.gold.withValues(alpha: 0.7 * k),
                      blurRadius: 14 * k,
                      spreadRadius: 2 * k,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
            Positioned(
              top: -6 - 8 * t,
              right: -6,
              child: Opacity(
                opacity: 1 - t,
                child: const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Palette.gold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Capa de pelusas que suben despacio detrás de las tarjetas.
///
/// El desplazamiento depende de [time] (segundos de juego), así que no usa
/// animaciones propias: se mueve al ritmo del ciclo del juego.
class FloatingLint extends StatelessWidget {
  const FloatingLint({super.key, required this.time, this.speed = 14});

  final double time;

  /// Píxeles por segundo.
  final double speed;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          // La imagen mide 572x1024.
          final h = w * 1024 / 572;
          final dy = (time * speed) % h;
          Widget tile(double top) => Positioned(
            left: 0,
            top: top,
            width: w,
            height: h,
            child: Image.asset(
              'assets/art/bg_pelusas_flotando.png',
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          );
          return ClipRect(
            child: Opacity(
              opacity: 0.45,
              child: Stack(
                children: [
                  for (var k = -1; k * h - dy < box.maxHeight; k++)
                    tile(k * h - dy + h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Destello y rebote de una tarjeta de negocio al cruzar un umbral.
class ThresholdFx extends StatefulWidget {
  const ThresholdFx({super.key, required this.level, required this.child});

  /// Cuántos umbrales de velocidad lleva superados el negocio.
  final int level;
  final Widget child;

  @override
  State<ThresholdFx> createState() => _ThresholdFxState();
}

class _ThresholdFxState extends State<ThresholdFx>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ThresholdFx old) {
    super.didUpdateWidget(old);
    if (widget.level > old.level && !MediaQuery.disableAnimationsOf(context)) {
      _anim.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      child: widget.child,
      builder: (context, child) {
        final t = _anim.value;
        if (t == 0 || t == 1) return child!;
        // Rebote rápido al inicio y destello que se apaga.
        final pop = math.sin(math.pi * (t * 2).clamp(0.0, 1.0));
        final glow = 1 - t;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1 + 0.04 * pop,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Palette.gold.withValues(alpha: 0.8 * glow),
                      blurRadius: 18 * glow,
                      spreadRadius: 3 * glow,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
            Positioned(
              top: 40 - 14 * t,
              right: 12,
              child: Opacity(
                key: const Key('threshold-fx'),
                opacity: glow,
                child: const Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Palette.gold,
                  label: Text(
                    '¡El doble de velocidad!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Respiración suave de un ícono mientras su negocio produce.
///
/// Se calcula a partir del avance del ciclo ([progress], de 0 a 1), así que
/// no usa animaciones propias: late una vez por ciclo.
class WorkingBob extends StatelessWidget {
  const WorkingBob({
    super.key,
    required this.active,
    required this.progress,
    required this.child,
  });

  final bool active;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active || MediaQuery.disableAnimationsOf(context)) return child;
    final sy = 1 + 0.05 * math.sin(progress * 2 * math.pi);
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.diagonal3Values(1 / sy, sy, 1),
      child: child,
    );
  }
}
