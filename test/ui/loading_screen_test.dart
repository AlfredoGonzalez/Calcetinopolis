import 'dart:async';

import 'package:calcetinopolis/ui/loading_screen.dart';
import 'package:calcetinopolis/ui/sock_pile.dart';
import 'package:calcetinopolis/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SockPileModel', () {
    SockPileModel make({double w = 390, double h = 400}) => SockPileModel(
      width: w,
      height: h,
      assets: ['a', 'b', 'c'],
      bigAssets: {'c'},
    );

    test('arranca con 22 personajes dentro del área', () {
      final m = make();
      expect(m.socks.length, 22);
      for (final s in m.socks) {
        expect(s.x, inInclusiveRange(m.radius, m.width - m.radius));
        expect(s.y, inInclusiveRange(0, m.height));
      }
      expect(m.socks.where((s) => s.scale > 1).isNotEmpty, isTrue);
    });

    test('con gravedad hacia abajo se asienta sin salirse del área', () {
      final m = make();
      for (var i = 0; i < 1200; i++) {
        m.step();
      }
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
      // En reposo: casi no se mueven (el temblor visible es de unos pocos px).
      final before = [for (final s in m.socks) Offset(s.x, s.y)];
      for (var i = 0; i < 30; i++) {
        m.step();
      }
      for (var k = 0; k < m.socks.length; k++) {
        final moved = (Offset(m.socks[k].x, m.socks[k].y) - before[k]).distance;
        expect(moved, lessThan(4));
      }
    });

    test('al inclinar a la derecha se van hacia la derecha', () {
      final m = make();
      for (var i = 0; i < 300; i++) {
        m.step();
      }
      final before = m.socks.map((s) => s.x).reduce((a, b) => a + b);
      m.gx = 1;
      m.gy = 0;
      for (var i = 0; i < 300; i++) {
        m.step();
      }
      final after = m.socks.map((s) => s.x).reduce((a, b) => a + b);
      expect(after, greaterThan(before));
    });

    test('los personajes no se encimaron después de asentarse', () {
      final m = make();
      for (var i = 0; i < 600; i++) {
        m.step();
      }
      for (var i = 0; i < m.socks.length; i++) {
        for (var j = i + 1; j < m.socks.length; j++) {
          final a = m.socks[i];
          final b = m.socks[j];
          final d = Offset(a.x - b.x, a.y - b.y).distance;
          expect(d, greaterThan(m.radius * 1.5));
        }
      }
    });

    test('arrastrar mueve el personaje agarrado y lo suelta', () {
      final m = make();
      final target = m.socks.first;
      expect(m.grab(Offset(target.x, target.y)), isTrue);
      expect(m.dragId, target.id);
      final x0 = target.x;
      m.drag(20, 0);
      expect(target.x, greaterThan(x0));
      m.release();
      expect(m.dragId, isNull);
    });

    test('agarrar lejos de todos no agarra nada', () {
      final m = make();
      expect(m.grab(const Offset(-500, -500)), isFalse);
      expect(m.dragId, isNull);
    });

    test('arrastrar no saca al personaje del área', () {
      final m = make();
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
            duration: const Duration(seconds: 6),
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

    testWidgets('muestra el logo, la primera frase y la pila', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(app());
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('loading-logo')), findsOneWidget);
      expect(find.text(loadingMessages.first), findsOneWidget);
      expect(find.byKey(const ValueKey('pile-0')), findsOneWidget);
      expect(find.byKey(const Key('loading-continue')), findsNothing);
    });

    testWidgets('las frases avanzan y al terminar pide tocar para continuar', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(app());
      await run(t, const Duration(seconds: 3));
      expect(find.text(loadingMessages.first), findsNothing);
      await run(t, const Duration(milliseconds: 3200));
      expect(find.text(loadingMessages.last), findsOneWidget);
      expect(find.byKey(const Key('loading-continue')), findsOneWidget);
      expect(find.text('juego'), findsNothing);

      await t.tap(find.byKey(const Key('loading-continue')));
      await run(t, const Duration(seconds: 1));
      expect(find.text('juego'), findsOneWidget);
    });

    testWidgets('la inclinación mueve la pila', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final tilt = StreamController<Offset>();
      addTearDown(tilt.close);
      await t.pumpWidget(app(tilt: tilt));
      await run(t, const Duration(seconds: 1));
      final before = t.getCenter(find.byKey(const ValueKey('pile-0'))).dx;
      tilt.add(const Offset(1, 0));
      await run(t, const Duration(seconds: 2));
      final after = t.getCenter(find.byKey(const ValueKey('pile-0'))).dx;
      expect(after, isNot(closeTo(before, 1)));
    });

    testWidgets('con reducir animaciones se salta', (t) async {
      await t.pumpWidget(app(reduce: true));
      await run(t, const Duration(seconds: 1));
      expect(find.text('juego'), findsOneWidget);
    });
  });
}
