import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Fondo de la pantalla de carga: aparece la lavadora, la cámara se acerca a
/// su ventanita y se va asomando el tambor, con los calcetines dando vueltas.
///
/// [progress] (0 a 1) lleva el acercamiento. [center] es el punto de la
/// pantalla al que se acerca la cámara: ahí queda el cristal de la lavadora y,
/// después, el remolino del tambor. El tambor queda quieto; los calcetines se
/// lavan encima, en otra capa.
class WasherZoomBackdrop extends StatelessWidget {
  const WasherZoomBackdrop({
    super.key,
    required this.progress,
    required this.center,
  });

  final Animation<double> progress;
  final Offset center;

  /// Centro y radio del cristal de la puerta dentro de la imagen de la lavadora
  /// (fracciones del lado de la imagen).
  static const doorCx = 0.499;
  static const doorCy = 0.512;
  static const doorR = 0.1665;

  /// Tamaño de la imagen del tambor (572 x 1024) y dónde queda su remolino.
  static const interiorW = 572.0;
  static const interiorH = 1024.0;
  static const swirlX = 0.493;
  static const swirlY = 0.498;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return AnimatedBuilder(
          animation: progress,
          builder: (context, _) => _paint(size),
        );
      },
    );
  }

  static double _smooth(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// El tambor. Cuando ya llenó la pantalla no necesita opacidad ni recorte,
  /// que son las capas más caras.
  Widget _interior(
    Offset center,
    double windowR,
    double diag,
    double opacity,
    double iw,
    double ih,
  ) {
    Widget picture = Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Ui.bg1)),
        Positioned(
          left: center.dx - swirlX * iw,
          top: center.dy - swirlY * ih,
          width: iw,
          height: ih,
          child: Image.asset(
            'assets/art/bg_tambor.jpg',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
    final full = windowR * 0.97 > diag / 2 + 4;
    if (!full) {
      picture = ClipPath(
        clipper: _WindowClipper(center, windowR * 0.97),
        child: picture,
      );
    }
    if (opacity < 0.999) {
      picture = Opacity(opacity: opacity.clamp(0.0, 1.0), child: picture);
    }
    return KeyedSubtree(
      key: const Key('backdrop-interior'),
      child: RepaintBoundary(child: picture),
    );
  }

  Widget _paint(Size size) {
    final t = progress.value;
    final washerW = math.min(size.width * 0.7, 300.0);
    final diag = math.sqrt(size.width * size.width + size.height * size.height);
    final r0 = doorR * washerW;
    final sMax = (diag / 2 * 1.08) / r0;

    // La lavadora entra en el primer 10%, se queda un momento y luego la
    // cámara se acerca de forma constante (zoom exponencial).
    final enter = _smooth(0, 0.1, t);
    final z = Curves.easeInOutCubic.transform(_smooth(0.2, 0.85, t));
    final scale = math.pow(sMax, z).toDouble();
    final windowR = r0 * scale;

    final interiorOpacity = _smooth(0.12, 0.5, z);
    final washerOpacity = enter * (1 - _smooth(0.7, 0.92, z));

    // El tambor cubre la pantalla; mientras la ventana crece, él también.
    final cover = math.max(size.width / interiorW, size.height / interiorH);
    final f = 0.6 + 0.4 * _smooth(0, 1, z);
    final iw = interiorW * cover * f;
    final ih = interiorH * cover * f;

    // Oscurece arriba y abajo para que se lea el texto, y deja el centro claro
    // para que se vean los calcetines del tambor.
    final k = _smooth(0.3, 1, z);
    final scrimTop = 0.25 + 0.3 * k;
    final scrimMid = 0.2 - 0.1 * k;
    final scrimBottom = 0.35 + 0.35 * k;

    final matrix = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (washerOpacity > 0)
          Opacity(
            key: const Key('backdrop-washer'),
            opacity: washerOpacity.clamp(0.0, 1.0),
            child: Transform(
              transform: matrix,
              child: Stack(
                children: [
                  Positioned(
                    left: center.dx - doorCx * washerW,
                    top: center.dy - doorCy * washerW,
                    width: washerW,
                    height: washerW,
                    child: Image.asset(
                      'assets/art/anim_centrifugado_lavadora.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (interiorOpacity > 0)
          _interior(center, windowR, diag, interiorOpacity, iw, ih),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Ui.navy1.withValues(alpha: scrimTop),
                  Ui.navy1.withValues(alpha: scrimMid),
                  Ui.navy2.withValues(alpha: scrimBottom),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Recorta un círculo: la ventana de la lavadora.
class _WindowClipper extends CustomClipper<Path> {
  _WindowClipper(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_WindowClipper old) =>
      old.center != center || old.radius != radius;
}
