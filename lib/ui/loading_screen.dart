import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'sock_pile.dart';
import 'theme.dart';
import 'washer_zoom.dart';

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

double _smooth(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Pantalla de carga. Se ve en este orden: la lavadora, el acercamiento a su
/// ventanita, el logo que aparece desvanecido y, al final, los calcetines que
/// se lavan en el tambor (giran en sentido horario y caen al llegar al borde
/// izquierdo, hasta formar una pila que se puede arrastrar o inclinar con el
/// celular). Abajo, una barra con textos graciosos y "Toca para continuar".
/// Con "reducir animaciones" se salta.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    required this.child,
    required this.characters,
    this.duration = const Duration(seconds: 8),
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _continued = false;

  @override
  void initState() {
    super.initState();
    _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
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
    required this.characters,
    required this.tilt,
    required this.useSensors,
    required this.onContinue,
  });

  final Animation<double> progress;
  final List<String> characters;
  final Stream<Offset>? tilt;
  final bool useSensors;
  final VoidCallback onContinue;

  /// Alto reservado abajo para la barra, los textos y el botón: la pila cae
  /// justo encima.
  static const _bottomPanel = 170.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Ui.navy1,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, box.maxHeight);
          final floorY =
              size.height - _bottomPanel - MediaQuery.paddingOf(context).bottom;
          // El remolino del tambor: al centro, sin pasar del piso de la pila.
          final center = Offset(
            size.width / 2,
            math.min(size.height * 0.5, floorY - 200),
          );
          return DecoratedBox(
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
                WasherZoomBackdrop(progress: progress, center: center),
                AnimatedBuilder(
                  animation: progress,
                  builder: (context, _) => _PileLayer(
                    characters: characters,
                    size: size,
                    floorY: floorY,
                    center: center,
                    reveal: _smooth(0.68, 0.78, progress.value),
                    tilt: tilt,
                    useSensors: useSensors,
                  ),
                ),
                SafeArea(
                  child: AnimatedBuilder(
                    animation: progress,
                    builder: (context, _) => _foreground(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _foreground(BuildContext context) {
    final t = progress.value;
    final done = t >= 1;
    final pct = (t * 100).floor();
    final msg =
        loadingMessages[math.min(
          loadingMessages.length - 1,
          (t * (loadingMessages.length - 1)).floor(),
        )];
    // El logo aparece desvanecido después del acercamiento; los calcetines
    // (y su frase) entran al final.
    final logoOpacity = _smooth(0.52, 0.70, t);
    final hintOpacity = _smooth(0.68, 0.8, t);
    return Column(
      children: [
        const SizedBox(height: 8),
        Opacity(
          opacity: logoOpacity,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - logoOpacity)),
            child: Image.asset(
              'assets/art/logo_carga.png',
              key: const Key('loading-logo'),
              // 75% del tamaño original.
              height:
                  0.75 *
                  math.min(310, MediaQuery.sizeOf(context).height * 0.34),
              errorBuilder: (_, _, _) => const Text(
                'Calcetinópolis',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Ui.headerText,
                ),
              ),
            ),
          ),
        ),
        Opacity(
          opacity: hintOpacity,
          child: const Text(
            'Inclina tu cel o arrastra los calcetines',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Ui.headerSub,
              shadows: [Shadow(color: Color(0xAA000000), blurRadius: 6)],
            ),
          ),
        ),
        const Spacer(),
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
                style: TextStyle(fontSize: 13, color: Ui.headerSub),
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

/// Los calcetines: se lavan en el tambor y caen a la pila. Física a 30 pasos
/// por segundo, arrastre con el dedo e inclinación con el acelerómetro.
class _PileLayer extends StatefulWidget {
  const _PileLayer({
    required this.characters,
    required this.size,
    required this.floorY,
    required this.center,
    required this.reveal,
    required this.tilt,
    required this.useSensors,
  });

  final List<String> characters;
  final Size size;

  /// Piso donde cae la pila.
  final double floorY;

  /// Centro del tambor.
  final Offset center;

  /// Qué tanto se ven los calcetines (0 a 1).
  final double reveal;
  final Stream<Offset>? tilt;
  final bool useSensors;

  @override
  State<_PileLayer> createState() => _PileLayerState();
}

class _PileLayerState extends State<_PileLayer>
    with SingleTickerProviderStateMixin {
  static const _stepMs = 33.0;

  SockPileModel? _model;
  Size _size = Size.zero;
  double _floorY = 0;
  Offset _center = Offset.zero;
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
    if (_model == null ||
        widget.size != _size ||
        widget.floorY != _floorY ||
        widget.center != _center) {
      _size = widget.size;
      _floorY = widget.floorY;
      _center = widget.center;
      _model = SockPileModel(
        width: widget.size.width,
        height: widget.floorY,
        drumCenter: widget.center,
        assets: widget.characters,
        bigAssets: {
          for (final a in widget.characters)
            if (a.startsWith('mascota')) a,
        },
      );
    }
    final m = _model!..reveal = widget.reveal;
    return LayoutBuilder(
      builder: (context, box) {
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
                    child: Opacity(
                      opacity: widget.reveal.clamp(0.0, 1.0),
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
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
