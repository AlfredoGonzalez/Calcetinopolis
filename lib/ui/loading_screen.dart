import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'sock_pile.dart';
import 'washer_zoom.dart';
import 'theme.dart';

/// Textos de estado de la pantalla de carga, del primero al último.
const loadingMessages = [
  'Despertando a las lavadoras...',
  'Buscando el par de cada calcetín...',
  'Sacudiendo la pelusa...',
  'Negociando con la secadora...',
  'Contando calcetines (faltan dos, como siempre)...',
  'Perdiendo un calcetín a propósito...',
  '¡Listo para lavar!',
];

/// Pantalla de carga: el logo, una pila de personajes que se puede arrastrar o
/// inclinar con el celular, una barra con textos graciosos y "Toca para
/// continuar" al terminar. Con "reducir animaciones" se salta.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    required this.child,
    required this.characters,
    this.duration = const Duration(seconds: 6),
    this.tilt,
    this.useSensors = true,
  });

  /// Lo que se muestra al continuar.
  final Widget child;

  /// Arte de los personajes de la pila (nombres en assets/art).
  final List<String> characters;
  final Duration duration;

  /// Gravedad de inclinación (x, y de -1 a 1) para pruebas; si es nulo se usa
  /// el acelerómetro.
  final Stream<Offset>? tilt;
  final bool useSensors;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// Giro del tambor, una vuelta cada 22 s.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  );
  bool _continued = false;

  @override
  void initState() {
    super.initState();
    _progress.forward();
    _spin.repeat();
  }

  @override
  void dispose() {
    _progress.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _continue() {
    if (_continued || !mounted) return;
    setState(() => _continued = true);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) && !_continued) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _continue());
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _continued
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : _Body(
              key: const ValueKey('loading'),
              progress: _progress,
              spin: _spin,
              characters: widget.characters,
              tilt: widget.tilt,
              useSensors: widget.useSensors,
              onContinue: _continue,
            ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    super.key,
    required this.progress,
    required this.spin,
    required this.characters,
    required this.tilt,
    required this.useSensors,
    required this.onContinue,
  });

  final Animation<double> progress;
  final Animation<double> spin;
  final List<String> characters;
  final Stream<Offset>? tilt;
  final bool useSensors;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Ui.navy1,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Ui.navy1, Ui.navy2],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            WasherZoomBackdrop(progress: progress, spin: spin),
            SafeArea(
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) {
                  final t = progress.value;
                  final done = t >= 1;
                  final pct = (t * 100).floor();
                  final msg =
                      loadingMessages[math.min(
                        loadingMessages.length - 1,
                        (t * (loadingMessages.length - 1)).floor(),
                      )];
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Image.asset(
                        'assets/art/logo_carga.png',
                        key: const Key('loading-logo'),
                        // 75% del tamaño anterior.
                        height:
                            0.75 *
                            math.min(
                              310,
                              MediaQuery.sizeOf(context).height * 0.34,
                            ),
                        errorBuilder: (_, _, _) => const Text(
                          'Calcetinópolis',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: Ui.headerText,
                          ),
                        ),
                      ),
                      const Text(
                        'Inclina tu cel o arrastra los calcetines',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Ui.headerSub,
                        ),
                      ),
                      Expanded(
                        child: _PileArea(
                          characters: characters,
                          tilt: tilt,
                          useSensors: useSensors,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 4, 28, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              label: 'Progreso de carga',
                              value: '$pct%',
                              child: Container(
                                height: 24,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0x8C140632),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: t.clamp(0.0, 1.0),
                                    heightFactor: 1,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: const LinearGradient(
                                          colors: [Ui.orange, Ui.yellow],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    msg,
                                    key: const Key('loading-status'),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Ui.headerText,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Ui.yellow,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Consejo: los calcetines solitarios también sienten.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Ui.headerSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 52,
                        child: done
                            ? TextButton(
                                key: const Key('loading-continue'),
                                onPressed: onContinue,
                                style: TextButton.styleFrom(
                                  foregroundColor: Ui.headerText,
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: const _Blink(
                                  child: Text(
                                    'TOCA PARA CONTINUAR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2.2,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parpadeo suave del "Toca para continuar".
class _Blink extends StatefulWidget {
  const _Blink({required this.child});
  final Widget child;

  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.55, end: 1.0).animate(_c),
    child: widget.child,
  );
}

/// La pila de personajes: física a 30 pasos por segundo, arrastre con el dedo
/// e inclinación con el acelerómetro.
class _PileArea extends StatefulWidget {
  const _PileArea({
    required this.characters,
    required this.tilt,
    required this.useSensors,
  });

  final List<String> characters;
  final Stream<Offset>? tilt;
  final bool useSensors;

  @override
  State<_PileArea> createState() => _PileAreaState();
}

class _PileAreaState extends State<_PileArea>
    with SingleTickerProviderStateMixin {
  static const _stepMs = 33.0;

  SockPileModel? _model;
  Size _size = Size.zero;
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  double _acc = 0;
  StreamSubscription<Object?>? _tiltSub;
  Offset _gravity = const Offset(0, 1);
  int? _pointer;
  Offset? _lastPos;

  @override
  void initState() {
    super.initState();
    _ticker.start();
    _listenTilt();
  }

  void _listenTilt() {
    final custom = widget.tilt;
    if (custom != null) {
      _tiltSub = custom.listen((g) => _gravity = g, onError: (_) {});
      return;
    }
    if (!widget.useSensors) return;
    try {
      _tiltSub =
          accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
              .listen(
                (e) {
                  // Pantalla vertical: arriba es +y; gravedad en pantalla = (-x, +y).
                  final gx = (-e.x / 9.81).clamp(-1.0, 1.0);
                  final gy = (e.y / 9.81).clamp(-1.0, 1.0);
                  // Suaviza para que no tiemble.
                  _gravity = Offset(
                    _gravity.dx + (gx - _gravity.dx) * 0.2,
                    _gravity.dy + (gy - _gravity.dy) * 0.2,
                  );
                },
                onError: (_) {},
                cancelOnError: false,
              );
    } catch (_) {
      // Sin sensores se queda con la gravedad hacia abajo.
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tiltSub?.cancel();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final m = _model;
    if (m == null) return;
    _acc += (elapsed - _last).inMicroseconds / 1000;
    _last = elapsed;
    if (_acc > 200) _acc = 200; // no se acumula si la app estuvo detenida
    var stepped = false;
    while (_acc >= _stepMs) {
      m.gx = _gravity.dx;
      m.gy = _gravity.dy;
      m.step();
      _acc -= _stepMs;
      stepped = true;
    }
    if (stepped) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        if (_model == null || size != _size) {
          _size = size;
          _model = SockPileModel(
            width: size.width,
            height: size.height,
            assets: widget.characters,
            bigAssets: {
              for (final a in widget.characters)
                if (a.startsWith('mascota')) a,
            },
          );
        }
        final m = _model!;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            if (_pointer != null) return;
            if (m.grab(e.localPosition)) {
              _pointer = e.pointer;
              _lastPos = e.localPosition;
            }
          },
          onPointerMove: (e) {
            if (e.pointer != _pointer) return;
            final last = _lastPos;
            if (last == null) return;
            m.drag(e.localPosition.dx - last.dx, e.localPosition.dy - last.dy);
            _lastPos = e.localPosition;
          },
          onPointerUp: (e) {
            if (e.pointer != _pointer) return;
            m.release();
            _pointer = null;
          },
          onPointerCancel: (e) {
            if (e.pointer != _pointer) return;
            m.release();
            _pointer = null;
          },
          child: ClipRect(
            child: Stack(
              children: [
                for (final s in m.socks)
                  Positioned(
                    key: ValueKey('pile-${s.id}'),
                    left: s.x - m.radius * 1.15 * s.scale,
                    top: s.y - m.radius * 1.15 * s.scale,
                    width: m.radius * 2.3 * s.scale,
                    height: m.radius * 2.3 * s.scale,
                    child: Transform.rotate(
                      angle: s.rot * math.pi / 180,
                      child: Image.asset(
                        'assets/art/${s.asset}.png',
                        cacheWidth: 160,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
