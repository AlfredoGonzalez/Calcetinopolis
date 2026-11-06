import 'package:flutter/material.dart';

import 'theme.dart';

/// Imagen de assets/art por nombre (sin extensión). Los PNG con transparencia
/// vienen de tool/process_art.py. `cacheWidth` evita decodificar 512 px para
/// un ícono de 40 dp.
///
/// Si el archivo falta se prueba con [fallbackName] (otro arte que sí exista)
/// y, al final, con un ícono de Material. Así la app sigue viéndose bien
/// mientras llega el arte definitivo.
class Art extends StatelessWidget {
  const Art(
    this.name, {
    super.key,
    this.size = 40,
    this.fallback,
    this.fallbackName,
  });

  final String? name;
  final double size;

  /// Se muestra si no hay ni [name] ni [fallbackName].
  final IconData? fallback;

  /// Arte alterno por nombre, si [name] no existe.
  final String? fallbackName;

  static const bgRoom = 'assets/art/bg_cuarto_lavado.jpg';

  @override
  Widget build(BuildContext context) {
    final n = name;
    if (n == null) return _icon();
    return _image(
      context,
      n,
      onMissing: () {
        final alt = fallbackName;
        if (alt == null) return _icon();
        return _image(context, alt, onMissing: _icon);
      },
    );
  }

  Widget _image(
    BuildContext context,
    String file, {
    required Widget Function() onMissing,
  }) {
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.asset(
      'assets/art/$file.png',
      width: size,
      height: size,
      cacheWidth: px,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => onMissing(),
    );
  }

  Widget _icon() => SizedBox(
    width: size,
    height: size,
    child: fallback == null
        ? null
        : Icon(fallback, size: size * 0.8, color: Palette.gold),
  );
}
