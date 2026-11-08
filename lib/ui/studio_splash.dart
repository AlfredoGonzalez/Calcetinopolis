import 'package:flutter/material.dart';

import 'theme.dart';

/// Pantalla del estudio que se ve al abrir la app, como las de los motores de
/// juego: aparece, se queda un momento y se desvanece a los 3 segundos. Un
/// toque la salta. Mientras no haya logo definitivo muestra "AM"; para
/// reemplazarlo basta con dejar la imagen en `assets/art/studio_logo.png`.
class StudioSplash extends StatefulWidget {
  const StudioSplash({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
  });

  /// Lo que se muestra cuando la pantalla termina.
  final Widget child;
  final Duration duration;

  @override
  State<StudioSplash> createState() => _StudioSplashState();
}

class _StudioSplashState extends State<StudioSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done || !mounted) return;
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) && !_done) {
      // Sin animaciones: se salta la pantalla.
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _done
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : GestureDetector(
              key: const ValueKey('studio-splash'),
              behavior: HitTestBehavior.opaque,
              onTap: _finish,
              child: _SplashBody(animation: _anim),
            ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [Ui.navy2, Ui.navy1, Color(0xFF0E1628)],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = animation.value;
            // Entra en el primer 20%, se queda y sale en el último 25%.
            final opacity = t < 0.2
                ? Curves.easeOut.transform(t / 0.2)
                : (t > 0.75
                      ? 1 - Curves.easeIn.transform((t - 0.75) / 0.25)
                      : 1.0);
            final scale = 0.94 + 0.06 * Curves.easeOut.transform(t.clamp(0, 1));
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: const _StudioMark(),
        ),
      ),
    );
  }
}

class _StudioMark extends StatelessWidget {
  const _StudioMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/art/studio_logo.png',
          width: 220,
          errorBuilder: (_, _, _) => const Text(
            'AM',
            key: Key('studio-wordmark'),
            style: TextStyle(
              fontFamily: Ui.fontFamily,
              fontSize: 96,
              height: 1,
              fontWeight: FontWeight.w700,
              color: Ui.headerText,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'ESTUDIO',
          style: TextStyle(
            fontFamily: Ui.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Ui.headerSub,
            letterSpacing: 8,
          ),
        ),
      ],
    );
  }
}
