import 'package:flutter/material.dart';

import 'sprite_sheet.dart';

/// Movimientos de la mascota que se pueden disparar sobre cualquier pantalla.
enum MascotMove {
  /// Manitas arriba y confeti: recompensas, metas y compras.
  celebrate(
    asset: 'assets/art/spr_mascota_celebra_5x5.png',
    frameSize: Size(336, 385),
    columns: 5,
    rows: 5,
    frames: 21,
    fps: 10,
    scale: 0.45,
  ),

  /// Salto con estiramiento: avanzar un paso del tutorial.
  jump(
    asset: 'assets/art/spr_mascota_salto_5x5.png',
    frameSize: Size(196, 661),
    columns: 5,
    rows: 5,
    frames: 23,
    fps: 12,
    scale: 0.3,
  );

  const MascotMove({
    required this.asset,
    required this.frameSize,
    required this.columns,
    required this.rows,
    required this.frames,
    required this.fps,
    required this.scale,
  });

  final String asset;
  final Size frameSize;
  final int columns;
  final int rows;
  final int frames;
  final double fps;
  final double scale;

  Duration get duration =>
      Duration(milliseconds: (frames / fps * 1000).round());
}

OverlayEntry? _current;

/// Muestra a la mascota un momento sobre la pantalla (no bloquea toques).
///
/// Si ya hay una en pantalla se reemplaza. Con "reducir animaciones" no se
/// muestra nada.
void playMascot(BuildContext context, MascotMove move) {
  if (MediaQuery.disableAnimationsOf(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _current?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _MascotBurst(
      move: move,
      onDone: () {
        if (_current == entry) _current = null;
        entry.remove();
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _MascotBurst extends StatefulWidget {
  const _MascotBurst({required this.move, required this.onDone});

  final MascotMove move;
  final VoidCallback onDone;

  @override
  State<_MascotBurst> createState() => _MascotBurstState();
}

class _MascotBurstState extends State<_MascotBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    // Un poco más que el sprite: el final es un fundido.
    duration: widget.move.duration + const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.move;
    final total = _anim.duration!.inMilliseconds;
    final fadeStart = m.duration.inMilliseconds / total;
    return Positioned(
      right: 12,
      bottom: 96,
      child: IgnorePointer(
        key: const Key('mascot-burst'),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            final t = _anim.value;
            final opacity = t < fadeStart
                ? 1.0
                : 1 - ((t - fadeStart) / (1 - fadeStart)).clamp(0.0, 1.0);
            return Opacity(opacity: opacity, child: child);
          },
          child: SpriteSheet(
            asset: m.asset,
            frameSize: m.frameSize,
            columns: m.columns,
            rows: m.rows,
            frames: m.frames,
            fps: m.fps,
            scale: m.scale,
            loop: false,
          ),
        ),
      ),
    );
  }
}
