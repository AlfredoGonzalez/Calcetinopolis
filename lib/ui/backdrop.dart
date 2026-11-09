import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fondo de un menú: una imagen atenuada y burbujas dibujadas en código,
/// para que las pantallas no se vean planas. No se anima (no gasta batería).
class MenuBackdrop extends StatelessWidget {
  const MenuBackdrop({
    super.key,
    required this.child,
    this.image,
    this.opacity = 0.2,
  });

  final Widget child;

  /// Ruta del asset (por ejemplo `assets/art/bg_cuarto_lavado.jpg`).
  final String? image;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (image != null)
          Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: Image.asset(
                image!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: BubblesPainter(seed: 7)),
          ),
        ),
        child,
      ],
    );
  }
}

/// Burbujas de jabón repartidas con una semilla fija (siempre iguales).
class BubblesPainter extends CustomPainter {
  const BubblesPainter({
    this.seed = 1,
    this.count = 16,
    this.maxRadius = 26,
    this.alpha = 0.5,
  });

  final int seed;
  final int count;
  final double maxRadius;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.22 * alpha);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.7 * alpha);
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.85 * alpha);
    for (var i = 0; i < count; i++) {
      final r = 5 + rnd.nextDouble() * (maxRadius - 5);
      final c = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height,
      );
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, edge);
      canvas.drawCircle(c + Offset(-r * 0.35, -r * 0.35), r * 0.16, shine);
    }
  }

  @override
  bool shouldRepaint(BubblesPainter old) =>
      old.seed != seed ||
      old.count != count ||
      old.maxRadius != maxRadius ||
      old.alpha != alpha;
}

/// Espuma: una orilla de burbujas encimadas, para el borde superior de la
/// barra inferior.
class FoamPainter extends CustomPainter {
  const FoamPainter({required this.color, required this.edge});

  final Color color;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    final fill = Paint()..color = color;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = edge;
    var x = -6.0;
    final base = size.height;
    final blobs = <(Offset, double)>[];
    while (x < size.width + 12) {
      final r = 9 + rnd.nextDouble() * 9;
      blobs.add((Offset(x + r, base - r * 0.55), r));
      x += r * 1.35;
    }
    // Primero los contornos, luego los rellenos: se ve una sola espuma.
    for (final b in blobs) {
      canvas.drawCircle(b.$1, b.$2, line);
    }
    for (final b in blobs) {
      canvas.drawCircle(b.$1, b.$2 - 0.8, fill);
    }
    canvas.drawRect(Rect.fromLTWH(0, base - 2, size.width, 2), fill);
  }

  @override
  bool shouldRepaint(FoamPainter old) => old.color != color || old.edge != edge;
}
