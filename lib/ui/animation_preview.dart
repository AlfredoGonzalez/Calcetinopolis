import 'package:flutter/material.dart';

import 'art.dart';
import 'sprite_sheet.dart';
import 'theme.dart';

/// Vista previa de la mascota (solo en modo de prueba): recorre las tres poses
/// con un rebote de estiramiento y encogimiento hecho en código, para decidir
/// si vale la pena dibujarla cuadro por cuadro.
Future<void> showMascotPreview(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _MascotPreview(),
  );
}

class _MascotPreview extends StatefulWidget {
  const _MascotPreview();

  @override
  State<_MascotPreview> createState() => _MascotPreviewState();
}

class _MascotPreviewState extends State<_MascotPreview>
    with SingleTickerProviderStateMixin {
  static const _poses = ['mascota_reposo', 'mascota_salto', 'mascota_celebra'];
  static const _labels = ['Reposo', 'Salto', 'Celebra'];

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Palette.cream,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mascota',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Sprites (idle, 16 cuadros)'),
              const SizedBox(height: 4),
              const SpriteSheet(
                asset: 'assets/art/spr_mascota_idle.png',
                frameSize: Size(108, 157),
                columns: 7,
                rows: 7,
                fps: 12,
                scale: 1.1,
              ),
              const Divider(height: 24),
              const Text('Una imagen + rebote en código'),
              SizedBox(
                height: 220,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    final t = _anim.value;
                    final i = (t * 3).floor().clamp(0, 2);
                    final local = (t * 3) - i;
                    // Rebote: sube y baja una vez por pose, con estiramiento.
                    final hop = (local < 0.5 ? local : 1 - local) * 2;
                    final lift = i == 0 ? 0.0 : hop * 28;
                    final sy = 1 + (i == 1 ? hop * 0.12 : hop * 0.05);
                    final sx = 1 / sy;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Transform.translate(
                          offset: Offset(0, -lift),
                          child: Transform.scale(
                            scaleX: sx,
                            scaleY: sy,
                            alignment: Alignment.bottomCenter,
                            child: Art(
                              _poses[i],
                              size: 160,
                              fallback: Icons.face,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_labels[i]),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
