import 'package:flutter/material.dart';

/// Imagen de assets/art por nombre (sin extensión). Los PNG con transparencia
/// vienen de tool/process_art.py. `cacheWidth` evita decodificar 512 px para
/// un ícono de 40 dp.
class Art extends StatelessWidget {
  const Art(this.name, {super.key, this.size = 40, this.fallback});

  final String? name;
  final double size;

  /// Se muestra si el archivo falta (por ejemplo, arte aún no generado).
  final IconData? fallback;

  static const bgRoom = 'assets/art/bg_cuarto_lavado.jpg';

  @override
  Widget build(BuildContext context) {
    final n = name;
    if (n == null) return _fallback();
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.asset(
      'assets/art/$n.png',
      width: size,
      height: size,
      cacheWidth: px,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => SizedBox(
    width: size,
    height: size,
    child: fallback == null ? null : Icon(fallback, size: size * 0.8),
  );
}
