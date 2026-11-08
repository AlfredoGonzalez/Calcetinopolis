import 'package:flutter/material.dart';

/// Reproduce una hoja de sprites (cuadrícula de [columns]×[rows] cuadros del
/// mismo tamaño, de izquierda a derecha y de arriba abajo) en bucle.
///
/// [frameSize] es el tamaño de un cuadro en la imagen original; [scale] lo
/// agranda o reduce al dibujarlo.
class SpriteSheet extends StatefulWidget {
  const SpriteSheet({
    super.key,
    required this.asset,
    required this.frameSize,
    required this.columns,
    required this.rows,
    this.frames,
    this.fps = 12,
    this.scale = 1,
    this.loop = true,
  });

  final String asset;
  final Size frameSize;
  final int columns;
  final int rows;

  /// Cuántos cuadros se usan (por defecto, todos los de la cuadrícula).
  final int? frames;
  final double fps;
  final double scale;

  /// Si es falso se reproduce una vez y se queda en el último cuadro.
  final bool loop;

  @override
  State<SpriteSheet> createState() => _SpriteSheetState();
}

class _SpriteSheetState extends State<SpriteSheet>
    with SingleTickerProviderStateMixin {
  late final int _count = widget.frames ?? widget.columns * widget.rows;
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_count / widget.fps * 1000).round()),
  );

  @override
  void initState() {
    super.initState();
    widget.loop ? _anim.repeat() : _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Con "reducir animaciones" se queda quieto: el primer cuadro en bucle, el último si es de una sola vez.
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim
        ..stop()
        ..value = widget.loop ? 0 : 1;
    } else if (widget.loop && !_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fw = widget.frameSize.width * widget.scale;
    final fh = widget.frameSize.height * widget.scale;
    return SizedBox(
      width: fw,
      height: fh,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            final i = (_anim.value * _count).floor().clamp(0, _count - 1);
            return OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 0,
              minHeight: 0,
              maxWidth: fw * widget.columns,
              maxHeight: fh * widget.rows,
              child: Transform.translate(
                offset: Offset(
                  -(i % widget.columns) * fw,
                  -(i ~/ widget.columns) * fh,
                ),
                child: child,
              ),
            );
          },
          child: Image.asset(
            widget.asset,
            width: fw * widget.columns,
            height: fh * widget.rows,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
