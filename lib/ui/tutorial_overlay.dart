import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app/game_controller.dart';
import '../app/tutorial.dart';
import 'sprite_sheet.dart';
import 'theme.dart';

/// Registro de los widgets que el tutorial puede iluminar, por id.
class TutorialScope extends InheritedWidget {
  const TutorialScope({super.key, required this.keys, required super.child});

  final Map<String, GlobalKey> keys;

  GlobalKey keyFor(String id) => keys.putIfAbsent(id, GlobalKey.new);

  static TutorialScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TutorialScope>();

  @override
  bool updateShouldNotify(TutorialScope old) => keys != old.keys;
}

/// Marca un widget como destino posible del tutorial. Sin [TutorialScope]
/// (por ejemplo en pruebas de un widget suelto) no hace nada.
class TutorialTarget extends StatelessWidget {
  const TutorialTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = TutorialScope.maybeOf(context);
    if (scope == null) return child;
    return KeyedSubtree(key: scope.keyFor(id), child: child);
  }
}

/// Oscurece toda la pantalla salvo el widget que toca usar. Lo de afuera no
/// recibe toques: solo el hueco, los botones del globo y nada más.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({
    super.key,
    required this.controller,
    required this.keys,
    this.onStepShown,
  });

  final GameController controller;
  final Map<String, GlobalKey> keys;

  /// Se llama una vez al aparecer cada paso (para abrir la pestaña correcta).
  final void Function(TutorialStep step)? onStepShown;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  String? _shownId;
  String? _scrolledFor;
  Rect? _rect;
  double _pulse = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _ticker.dispose();
    super.dispose();
  }

  /// El ticker solo corre mientras hay un paso en pantalla (si no, las
  /// pruebas con pumpAndSettle y la batería lo pagarían).
  void _sync() {
    final active = widget.controller.activeTutorial != null;
    if (active && !_ticker.isActive) {
      _ticker.start();
    } else if (!active && _ticker.isActive) {
      _ticker.stop();
      if (mounted && (_rect != null || _shownId != null)) {
        setState(() {
          _rect = null;
          _shownId = null;
        });
      }
    }
  }

  Rect? _measure(String targetId) {
    final key = widget.keys[targetId];
    final ctx = key?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final mine = context.findRenderObject();
    if (mine is! RenderBox || !mine.hasSize) return null;
    final topLeft = mine.globalToLocal(box.localToGlobal(Offset.zero));
    return topLeft & box.size;
  }

  void _onTick(Duration elapsed) {
    final step = widget.controller.activeTutorial;
    if (step == null) {
      _sync();
      return;
    }
    if (_shownId != step.id) {
      _shownId = step.id;
      widget.onStepShown?.call(step);
    }
    final targetId = step.target(widget.controller);
    final rect = _measure(targetId);
    // Si el destino queda fuera de la lista, se desplaza hasta verlo (una vez).
    final ctx = widget.keys[targetId]?.currentContext;
    if (ctx != null && _scrolledFor != '${step.id}:$targetId') {
      _scrolledFor = '${step.id}:$targetId';
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: const Duration(milliseconds: 250),
      );
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _rect = rect;
      _pulse = reduce ? 0.5 : (elapsed.inMilliseconds % 1400) / 1400;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final step = c.activeTutorial;
    final rect = _rect;
    if (step == null || rect == null) return const SizedBox.shrink();
    // El tamaño sale del propio espacio de la capa, no de MediaQuery.
    final size =
        (context.findRenderObject() as RenderBox?)?.size ??
        MediaQuery.sizeOf(context);
    final hole = RRect.fromRectAndRadius(
      rect.inflate(8),
      const Radius.circular(20),
    );
    final bounds = hole.outerRect;
    final index =
        kTutorialSteps.indexWhere((s) => s.id == step.id).clamp(0, 99) + 1;

    Widget blocker(Rect r) => Positioned.fromRect(
      rect: r,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        onPanStart: (_) {},
        child: const SizedBox.expand(),
      ),
    );

    // El globo va del lado que tenga más lugar.
    final below = bounds.center.dy < size.height * 0.5;
    final bubble = Positioned(
      left: 12,
      right: 12,
      top: below ? bounds.bottom + 10 : null,
      bottom: below ? null : size.height - bounds.top + 10,
      child: _Bubble(
        key: const Key('tutorial'),
        text: step.text,
        label: 'Paso $index de ${c.tutorialTotal}',
        onLater: c.dismissTutorialStep,
        onSkip: c.skipTutorial,
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: CustomPaint(
            painter: _DimPainter(hole: hole, pulse: _pulse),
          ),
        ),
        // Cuatro bloques alrededor del hueco: el hueco deja pasar los toques.
        blocker(Rect.fromLTRB(0, 0, size.width, bounds.top)),
        blocker(Rect.fromLTRB(0, bounds.bottom, size.width, size.height)),
        blocker(Rect.fromLTRB(0, bounds.top, bounds.left, bounds.bottom)),
        blocker(
          Rect.fromLTRB(bounds.right, bounds.top, size.width, bounds.bottom),
        ),
        bubble,
      ],
    );
  }
}

class _DimPainter extends CustomPainter {
  const _DimPainter({required this.hole, required this.pulse});

  final RRect hole;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(hole),
    );
    canvas.drawPath(dim, Paint()..color = const Color(0xCC0E1730));
    final k = (1 - (2 * pulse - 1).abs());
    canvas.drawRRect(
      hole.inflate(2 + 4 * k),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Ui.yellow.withValues(alpha: 0.55 + 0.45 * k),
    );
  }

  @override
  bool shouldRepaint(_DimPainter old) => old.hole != hole || old.pulse != pulse;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.text,
    required this.label,
    required this.onLater,
    required this.onSkip,
  });

  final String text;
  final String label;
  final VoidCallback onLater;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Ui.yellow, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SpriteSheet(
                  asset: 'assets/art/spr_mascota_idle_4x4.png',
                  frameSize: Size(209, 309),
                  columns: 4,
                  rows: 4,
                  fps: 8,
                  scale: 0.2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Ui.ink2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        key: const Key('tutorial-text'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: Ui.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  key: const Key('tutorial-later'),
                  onPressed: onLater,
                  child: const Text('Ahora no'),
                ),
                TextButton(
                  key: const Key('tutorial-skip'),
                  onPressed: onSkip,
                  child: const Text('Saltar tutorial'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
