import 'dart:async';
import 'dart:math' as math;

import 'package:calcetinopolis/ui/loading_screen.dart';
import 'package:calcetinopolis/ui/sock_pile.dart';
import 'package:calcetinopolis/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SockPileModel (tambor)', () {
    const cx = 195.0;
    const cy = 330.0;
    SockPileModel make({double w = 390, double h = 640}) => SockPileModel(
      width: w,
      height: h,
      assets: ['a', 'b', 'c'],
      bigAssets: {'c'},
      drumCenter: const Offset(cx, cy),
    );

    test(
      'arranca con 22 personajes, todos en el tambor y sobre sus anillos',
      () {
        final m = make();
        expect(m.socks.length, 22);
        for (final s in m.socks) {
          expect(s.inDrum, isTrue);
          final d = (Offset(s.x, s.y) - const Offset(cx, cy)).distance;
          expect(d, closeTo(s.ringRadius, 0.01));
        }
        expect(m.socks.where((s) => s.scale > 1), isNotEmpty);
      },
    );

    test('no giran hasta que se empieza a ver el tambor', () {
      final m = make();
      final before = [for (final s in m.socks) Offset(s.x, s.y)];
      for (var i = 0; i < 30; i++) {
        m.step();
      }
      for (var k = 0; k < m.socks.length; k++) {
        expect(Offset(m.socks[k].x, m.socks[k].y), before[k]);
      }
    });

    test('giran en sentido horario (en pantalla)', () {
      final m = make()..reveal = 1;
      // El primero está a la derecha del centro (ángulo 0): al girar en
      // sentido horario baja.
      final s = m.socks.first;
      expect(s.angle, 0);
      final y0 = s.y;
      for (var i = 0; i < 5; i++) {
        m.step();
      }
      expect(s.y, greaterThan(y0));
      expect(s.x, lessThan(cx + s.ringRadius));
    });

    test('se sueltan en el borde izquierdo mientras suben', () {
      final m = make()..reveal = 1;
      final target = m.socks.firstWhere((s) => s.releaseAngle == math.pi);
      var guard = 0;
      while (target.inDrum && guard++ < 400) {
        m.step();
      }
      expect(target.inDrum, isFalse);
      // Salió por la izquierda del tambor y con velocidad hacia arriba.
      expect(target.x, lessThan(cx - target.ringRadius + 6));
      expect(target.vy, lessThan(0));
    });

    test('se sueltan escalonados: no caen todos a la vez', () {
      final m = make()..reveal = 1;
      final releasedAt = <int, int>{};
      for (var step = 1; step <= 250; step++) {
        m.step();
        for (final s in m.socks) {
          if (!s.inDrum) releasedAt.putIfAbsent(s.id, () => step);
        }
      }
      expect(releasedAt.length, 22, reason: 'en una vuelta caen todos');
      expect(releasedAt.values.toSet().length, greaterThan(10));
      // Una vuelta completa es 2*pi / velocidad pasos.
      expect(
        releasedAt.values.reduce(math.max),
        lessThan(2 * math.pi / m.drumSpeed + 5),
      );
    });

    test('al final todos caen, se asientan dentro del área y no se encima', () {
      final m = make()..reveal = 1;
      for (var i = 0; i < 1800; i++) {
        m.step();
      }
      expect(m.socks.every((s) => !s.inDrum), isTrue);
      for (final s in m.socks) {
        expect(
          s.x,
          inInclusiveRange(m.radius - 0.01, m.width - m.radius + 0.01),
        );
        expect(
          s.y,
          inInclusiveRange(m.radius - 0.01, m.height - m.radius + 0.01),
        );
      }
      for (var i = 0; i < m.socks.length; i++) {
        for (var j = i + 1; j < m.socks.length; j++) {
          final d = Offset(
            m.socks[i].x - m.socks[j].x,
            m.socks[i].y - m.socks[j].y,
          ).distance;
          // Con 22 apilados se amontonan un poco (mínimo ~42 px de 64).
          expect(d, greaterThan(m.radius * 1.2));
        }
      }
      // En reposo casi no se mueven.
      final before = [for (final s in m.socks) Offset(s.x, s.y)];
      for (var i = 0; i < 30; i++) {
        m.step();
      }
      for (var k = 0; k < m.socks.length; k++) {
        final moved = (Offset(m.socks[k].x, m.socks[k].y) - before[k]).distance;
        expect(moved, lessThan(4));
      }
    });

    test(
      'al inclinar a la derecha los que cayeron se van hacia la derecha',
      () {
        final m = make()..reveal = 1;
        for (var i = 0; i < 1800; i++) {
          m.step();
        }
        final before = m.socks.map((s) => s.x).reduce((a, b) => a + b);
        m.gx = 1;
        m.gy = 0;
        for (var i = 0; i < 300; i++) {
          m.step();
        }
        expect(
          m.socks.map((s) => s.x).reduce((a, b) => a + b),
          greaterThan(before),
        );
      },
    );

    test('agarrar un calcetín del tambor lo saca de ahí', () {
      final m = make()..reveal = 1;
      final target = m.socks.first;
      expect(m.grab(Offset(target.x, target.y)), isTrue);
      expect(target.inDrum, isFalse);
      expect(m.dragId, target.id);
      final x0 = target.x;
      m.drag(20, 0);
      expect(target.x, greaterThan(x0));
      m.release();
      expect(m.dragId, isNull);
    });

    test(
      'no se agarra nada mientras el tambor no se ve, ni lejos de todos',
      () {
        final m = make();
        expect(m.grab(Offset(m.socks.first.x, m.socks.first.y)), isFalse);
        m.reveal = 1;
        expect(m.grab(const Offset(-500, -500)), isFalse);
        expect(m.dragId, isNull);
      },
    );

    test('arrastrar no saca al personaje del área', () {
      final m = make()..reveal = 1;
      m.grab(Offset(m.socks.first.x, m.socks.first.y));
      m.drag(5000, -5000);
      expect(m.socks.first.x, m.width - m.radius);
      expect(m.socks.first.y, m.radius);
    });
  });

  group('LoadingScreen', () {
    Widget app({bool reduce = false, StreamController<Offset>? tilt}) =>
        MaterialApp(
          theme: buildTheme(),
          builder: reduce
              ? (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: true),
                  child: child!,
                )
              : null,
          home: LoadingScreen(
            characters: const ['mascota_reposo', 'mgr_01_dona_pinza'],
            duration: const Duration(seconds: 8),
            useSensors: false,
            tilt: tilt?.stream,
            child: const Scaffold(body: Text('juego')),
          ),
        );

    Future<void> run(WidgetTester t, Duration d) async {
      // Hay un Ticker de física: no se puede usar pumpAndSettle.
      for (var i = 0; i < d.inMilliseconds ~/ 100; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    /// Opacidad del logo (un Opacity lo envuelve).
    double logoOpacity(WidgetTester t) => t
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byKey(const Key('loading-logo')),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    /// Opacidad de un calcetín de la pila (un Opacity va dentro de su Positioned).
    double sockOpacity(WidgetTester t, int id) => t
        .widget<Opacity>(
          find
              .descendant(
                of: find.byKey(ValueKey('pile-$id')),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    Future<void> setUpSurface(WidgetTester t) async {
      await t.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => t.binding.setSurfaceSize(null));
    }

    testWidgets('al inicio solo hay lavadora: ni logo ni calcetines se ven', (
      t,
    ) async {
      await setUpSurface(t);
      await t.pumpWidget(app());
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text(loadingMessages.first), findsOneWidget);
      expect(logoOpacity(t), 0);
      expect(sockOpacity(t, 0), 0);
      expect(find.byKey(const Key('loading-continue')), findsNothing);
    });

    testWidgets(
      'después del acercamiento aparece el logo y al final los calcetines',
      (t) async {
        await setUpSurface(t);
        await t.pumpWidget(app());
        await run(t, const Duration(milliseconds: 4900)); // 61 %
        expect(logoOpacity(t), greaterThan(0.2));
        expect(sockOpacity(t, 0), 0);
        await run(t, const Duration(milliseconds: 1900)); // 85 %
        expect(logoOpacity(t), 1);
        expect(sockOpacity(t, 0), 1);
      },
    );

    testWidgets('las frases avanzan y al terminar pide tocar para continuar', (
      t,
    ) async {
      await setUpSurface(t);
      await t.pumpWidget(app());
      await run(t, const Duration(seconds: 4));
      expect(find.text(loadingMessages.first), findsNothing);
      await run(t, const Duration(milliseconds: 4200));
      expect(find.text(loadingMessages.last), findsOneWidget);
      expect(find.byKey(const Key('loading-continue')), findsOneWidget);
      expect(find.text('juego'), findsNothing);

      await t.tap(find.byKey(const Key('loading-continue')));
      await run(t, const Duration(seconds: 1));
      expect(find.text('juego'), findsOneWidget);
    });

    testWidgets('la inclinación mueve los calcetines que ya cayeron', (
      t,
    ) async {
      await setUpSurface(t);
      final tilt = StreamController<Offset>();
      addTearDown(tilt.close);
      await t.pumpWidget(app(tilt: tilt));
      await run(t, const Duration(seconds: 16));
      double sumX() => [
        for (var i = 0; i < 22; i++)
          t.getCenter(find.byKey(ValueKey('pile-$i'))).dx,
      ].reduce((a, b) => a + b);
      final before = sumX();
      tilt.add(const Offset(1, 0));
      await run(t, const Duration(seconds: 3));
      expect(sumX(), greaterThan(before));
    });

    testWidgets('con reducir animaciones se salta', (t) async {
      await t.pumpWidget(app(reduce: true));
      await run(t, const Duration(seconds: 1));
      expect(find.text('juego'), findsOneWidget);
    });
  });
}
