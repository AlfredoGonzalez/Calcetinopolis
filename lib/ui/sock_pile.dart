import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Un personaje de la pantalla de carga.
class PileSock {
  PileSock({
    required this.id,
    required this.asset,
    required this.angle,
    required this.ringRadius,
    required this.releaseAngle,
    required this.baseRot,
    this.scale = 1,
  }) : x = 0,
       y = 0,
       rot = baseRot;

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

  /// Mientras está dentro del tambor, gira en un anillo alrededor del centro.
  bool inDrum = true;
  double angle;
  final double ringRadius;

  /// Ángulo (sin dar la vuelta) al que se suelta del tambor.
  final double releaseAngle;
  final double baseRot;
}

/// Calcetines que se lavan en un tambor y caen a una pila.
///
/// Mientras están en el tambor giran en sentido horario (en pantalla) en varios
/// anillos. Al llegar al borde izquierdo, cuando el tambor los lleva hacia
/// arriba, se sueltan y caen con gravedad, rebote, choques y arrastre.
///
/// Cada paso representa 33 ms: se avanza con [step] a ritmo fijo.
class SockPileModel {
  SockPileModel({
    required this.width,
    required this.height,
    required List<String> assets,
    this.radius = 32,
    int seed = 11,
    Offset? drumCenter,
    this.ringRadii = const [70, 115, 160],
    List<int> ringCounts = const [5, 8, 9],
    this.drumSpeed = 0.035,
    Set<String> bigAssets = const {},
  }) : center = drumCenter ?? Offset(width / 2, height * 0.45) {
    final rnd = math.Random(seed);
    var n = 0;
    for (var ring = 0; ring < ringRadii.length; ring++) {
      final count = ringCounts[ring];
      for (var j = 0; j < count; j++) {
        final a = 2 * math.pi * j / count + ring * 0.7;
        final angle = a % (2 * math.pi);
        final asset = assets[n % assets.length];
        socks.add(
          PileSock(
            id: n,
            asset: asset,
            angle: angle,
            ringRadius: ringRadii[ring] + (rnd.nextDouble() - 0.5) * 8,
            // Se suelta en el borde izquierdo (ángulo pi): la primera vez que
            // lo cruza, que puede ser en esta vuelta o en la siguiente.
            releaseAngle: angle < math.pi ? math.pi : 3 * math.pi,
            baseRot: rnd.nextDouble() * 60 - 30,
            scale: bigAssets.contains(asset) ? 1.55 : 1,
          ),
        );
        n++;
      }
    }
    for (final s in socks) {
      _place(s);
    }
  }

  /// Ancho y alto del área; el alto es el piso donde cae la pila.
  final double width;
  final double height;
  final double radius;
  final Offset center;
  final List<double> ringRadii;

  /// Radianes por paso con los que gira el tambor.
  final double drumSpeed;
  final List<PileSock> socks = [];

  /// Gravedad en la pantalla: x a la derecha, y hacia abajo (de -1 a 1).
  double gx = 0;
  double gy = 1;

  /// Qué tanto se ve el tambor (0 a 1); no gira hasta que empieza a verse.
  double reveal = 0;

  int? dragId;

  bool get drumRunning => reveal > 0.02;

  void _place(PileSock s) {
    s.x = center.dx + s.ringRadius * math.cos(s.angle);
    s.y = center.dy + s.ringRadius * math.sin(s.angle);
    s.rot = s.baseRot + s.angle * 180 / math.pi;
  }

  void _release(PileSock s) {
    s.inDrum = false;
    // Sale con la velocidad del tambor en ese punto (hacia arriba) y un poco
    // hacia afuera.
    s.vx = -s.ringRadius * math.sin(s.angle) * drumSpeed - 1;
    s.vy = s.ringRadius * math.cos(s.angle) * drumSpeed;
    s.vr = -2;
  }

  /// Un paso de 33 ms.
  void step() {
    final r = radius;
    for (final s in socks) {
      if (s.id == dragId) continue;
      if (s.inDrum) {
        if (!drumRunning) continue;
        s.angle += drumSpeed;
        _place(s);
        if (s.angle >= s.releaseAngle) _release(s);
        continue;
      }
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
        if (socks[i].inDrum) continue;
        for (var j = i + 1; j < socks.length; j++) {
          if (socks[j].inDrum) continue;
          _collide(socks[i], socks[j]);
        }
      }
    }
    // Los choques pueden empujar a alguien contra la pared: se reubica.
    for (final s in socks) {
      if (s.inDrum) continue;
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

  /// Agarra el personaje más cercano al punto [p], si hay uno cerca. Si estaba
  /// en el tambor, lo saca de ahí.
  bool grab(Offset p) {
    if (reveal < 0.5) return false;
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
    best.inDrum = false;
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
