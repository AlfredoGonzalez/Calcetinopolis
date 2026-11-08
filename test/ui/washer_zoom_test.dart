import 'package:calcetinopolis/ui/washer_zoom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AnimationController progress;
  late AnimationController spin;

  setUp(() {
    progress = AnimationController(vsync: const TestVSync());
    spin = AnimationController(vsync: const TestVSync());
  });
  tearDown(() {
    progress.dispose();
    spin.dispose();
  });

  Future<void> show(WidgetTester t, double p, {double s = 0}) async {
    progress.value = p;
    spin.value = s;
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: WasherZoomBackdrop(progress: progress, spin: spin),
      ),
    );
  }

  testWidgets('al inicio no hay nada y la lavadora entra', (t) async {
    await show(t, 0);
    expect(find.byKey(const Key('backdrop-washer')), findsNothing);
    expect(find.byKey(const Key('backdrop-interior')), findsNothing);
    progress.value = 0.1;
    await t.pump();
    expect(find.byKey(const Key('backdrop-washer')), findsOneWidget);
    expect(find.byKey(const Key('backdrop-interior')), findsNothing);
  });

  testWidgets(
    'a mitad del acercamiento se asoma el tambor dentro de la ventana',
    (t) async {
      await show(t, 0.55);
      expect(find.byKey(const Key('backdrop-washer')), findsOneWidget);
      expect(find.byKey(const Key('backdrop-interior')), findsOneWidget);
      // Sigue recortado por la ventana.
      expect(find.byType(ClipPath), findsWidgets);
    },
  );

  testWidgets('al final solo queda el tambor, ya sin recorte', (t) async {
    await show(t, 1);
    expect(find.byKey(const Key('backdrop-washer')), findsNothing);
    expect(find.byKey(const Key('backdrop-interior')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('backdrop-interior')),
        matching: find.byType(ClipPath),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('backdrop-interior')),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  testWidgets('el tambor gira con el tiempo', (t) async {
    await show(t, 1, s: 0);
    double angleOf() {
      final rot = t.widget<Transform>(
        find.descendant(
          of: find.byKey(const Key('backdrop-interior')),
          matching: find.byType(Transform),
        ),
      );
      return rot.transform.entry(0, 1);
    }

    final a0 = angleOf();
    spin.value = 0.1;
    await t.pump();
    expect(angleOf(), isNot(closeTo(a0, 1e-3)));
  });
}
