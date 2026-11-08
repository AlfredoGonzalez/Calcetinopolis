import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Fondo de la pantalla de carga: aparece la lavadora, la cámara se acerca a
/// su ventanita y se va asomando el tambor, con los calcetines dando vueltas.
///
/// [progress] (0 a 1) lleva el acercamiento; [spin] (0 a 1, en bucle) gira el
/// tambor una vez dentro.
class WasherZoomBackdrop extends StatelessWidget {
  const WasherZoomBackdrop({
    super.key,
    required this.progress,
    required this.spin,
  });

  final Animation<double> progress;
  final Animation<double> spin;

  /// Centro y radio del cristal de la puerta dentro de la imagen de la lavadora
  /// (fracciones del lado de la imagen).
  static const doorCx = 0.499;
  static const doorCy = 0.512;
  static const doorR = 0.1665;

  /// Proporción de la imagen del tambor (572 x 1024).
  static const _interiorAspect = 1024 / 572;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return AnimatedBuilder(
          animation: Listenable.merge([progress, spin]),
          builder: (context, _) => _paint(size),
        );
      },
    );
  }

  static double _smooth(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// El tambor girando. Cuando ya llenó la pantalla no necesita opacidad ni
  /// recorte, que son las capas más caras.
  Widget _interior(
    Size size,
    Offset center,
    double windowR,
    double diag,
    double opacity,
    double iw,
    double ih,
    double angle,
  ) {
    Widget picture = Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Ui.bg1)),
        Positioned(
          left: center.dx - iw / 2,
          top: center.dy - ih / 2,
          width: iw,
          height: ih,
          child: Transform.rotate(
            angle: angle,
            child: Image.asset(
              'assets/art/bg_tambor.jpg',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
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
    final center = Offset(size.width / 2, size.height * 0.5);
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

    // El tambor crece con la ventana y después gira.
    // Los bordes de la imagen son crema, igual que el fondo, así que no se nota
    // aunque al girar queden esquinas descubiertas.
    final iw = size.width * 1.2 * (0.5 + 0.5 * _smooth(0, 1, z));
    final ih = iw * _interiorAspect;
    final angle = spin.value * 2 * math.pi;

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
          _interior(
            size,
            center,
            windowR,
            diag,
            interiorOpacity,
            iw,
            ih,
            angle,
          ),
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
