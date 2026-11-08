import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Un personaje de la pila.
class PileSock {
  PileSock({
    required this.id,
    required this.asset,
    required this.x,
    required this.y,
    this.rot = 0,
    this.scale = 1,
  });

  final int id;

  /// Nombre del arte en assets/art (sin extensión).
  final String asset;
  double x;
  double y;
  double vx = 0;
  double vy = 0;

  /// Rotación en grados.
  double rot;
  double vr = 0;

  /// Qué tan grande se dibuja respecto al círculo de choque.
  final double scale;
}

/// Física sencilla de círculos con gravedad, rebote, choques y arrastre.
///
/// Es una versión en Dart del prototipo del diseño: cada paso representa
/// 33 ms, así que se avanza con [step] a ritmo fijo.
class SockPileModel {
  SockPileModel({
    required this.width,
    required this.height,
    required List<String> assets,
    this.radius = 32,
    int seed = 11,
    List<int> rows = const [6, 6, 5, 5],
    Set<String> bigAssets = const {},
  }) {
    final rnd = math.Random(seed);
    // Arrancan repartidos arriba y caen para formar la pila.
    var n = 0;
    for (var ri = 0; ri < rows.length; ri++) {
      final count = rows[ri];
      final span = width - 2 * radius - 8;
      for (var i = 0; i < count; i++) {
        final asset = assets[n % assets.length];
        socks.add(
          PileSock(
            id: n,
            asset: asset,
            x:
                radius +
                4 +
                (count == 1 ? span / 2 : span * i / (count - 1)) +
                (rnd.nextDouble() - 0.5) * 6,
            y: radius + ri * radius * 2.2 + rnd.nextDouble() * 6,
            rot: rnd.nextDouble() * 80 - 40,
            scale: bigAssets.contains(asset) ? 1.55 : 1,
          ),
        );
        n++;
      }
    }
  }

  final double width;
  final double height;
  final double radius;
  final List<PileSock> socks = [];

  /// Gravedad en la pantalla: x a la derecha, y hacia abajo (de -1 a 1).
  double gx = 0;
  double gy = 1;

  int? dragId;

  /// Un paso de 33 ms.
  void step() {
    final r = radius;
    for (final s in socks) {
      if (s.id == dragId) continue;
      s.vx = (s.vx + gx * 0.9) * 0.985;
      s.vy = (s.vy + gy * 0.9) * 0.985;
      s.x += s.vx;
      s.y += s.vy;
      s.rot += s.vr;
      s.vr *= 0.96;
      if (s.x < r) {
        s.x = r;
        s.vx *= -0.45;
        s.vr -= s.vy * 0.3;
      }
      if (s.x > width - r) {
        s.x = width - r;
        s.vx *= -0.45;
        s.vr += s.vy * 0.3;
      }
      if (s.y < r) {
        s.y = r;
        s.vy *= -0.45;
      }
      if (s.y > height - r) {
        s.y = height - r;
        s.vy *= -0.4;
        s.vx *= 0.92;
        s.vr += s.vx * 0.5;
      }
    }
    for (var it = 0; it < 2; it++) {
      for (var i = 0; i < socks.length; i++) {
        for (var j = i + 1; j < socks.length; j++) {
          _collide(socks[i], socks[j]);
        }
      }
    }
    // Los choques pueden empujar a alguien contra la pared: se reubica.
    for (final s in socks) {
      s.x = s.x.clamp(r, width - r);
      s.y = s.y.clamp(r, height - r);
    }
  }

  void _collide(PileSock a, PileSock b) {
    final r = radius;
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final d = math.sqrt(dx * dx + dy * dy);
    final dist = d == 0 ? 0.01 : d;
    if (dist >= 2 * r) return;
    final nx = dx / dist;
    final ny = dy / dist;
    final overlap = 2 * r - dist;
    final ad = a.id == dragId;
    final bd = b.id == dragId;
    final wa = ad ? 0.0 : (bd ? 1.0 : 0.5);
    final wb = bd ? 0.0 : (ad ? 1.0 : 0.5);
    a.x -= nx * overlap * wa;
    a.y -= ny * overlap * wa;
    b.x += nx * overlap * wb;
    b.y += ny * overlap * wb;
    final rv = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
    if (rv < 0) {
      final imp = -rv * 0.6;
      if (!ad) {
        a.vx -= imp * nx * (bd ? 2 : 1);
        a.vy -= imp * ny * (bd ? 2 : 1);
        a.vr += imp * 0.2;
      }
      if (!bd) {
        b.vx += imp * nx * (ad ? 2 : 1);
        b.vy += imp * ny * (ad ? 2 : 1);
        b.vr -= imp * 0.2;
      }
    }
  }

  /// Agarra el personaje más cercano al punto [p], si hay uno cerca.
  bool grab(Offset p) {
    PileSock? best;
    var bestD = radius * 1.4;
    for (final s in socks) {
      final d = (Offset(s.x, s.y) - p).distance;
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
    if (best == null) return false;
    dragId = best.id;
    best.vx = 0;
    best.vy = 0;
    return true;
  }

  /// Mueve el personaje agarrado [dx], [dy] píxeles y le da impulso.
  void drag(double dx, double dy) {
    final id = dragId;
    if (id == null) return;
    final s = socks.firstWhere((k) => k.id == id);
    s.x = (s.x + dx).clamp(radius, width - radius);
    s.y = (s.y + dy).clamp(radius, height - radius);
    s.vx = dx * 0.9;
    s.vy = dy * 0.9;
    s.vr = dx * 0.4;
  }

  void release() => dragId = null;
}
