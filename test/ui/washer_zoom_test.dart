import 'package:calcetinopolis/ui/washer_zoom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AnimationController progress;

  setUp(() => progress = AnimationController(vsync: const TestVSync()));
  tearDown(() => progress.dispose());

  Future<void> show(WidgetTester t, double p) async {
    progress.value = p;
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: WasherZoomBackdrop(
          progress: progress,
          center: const Offset(195, 422),
        ),
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
      await show(t, 0.45);
      expect(find.byKey(const Key('backdrop-washer')), findsOneWidget);
      expect(find.byKey(const Key('backdrop-interior')), findsOneWidget);
      expect(find.byType(ClipPath), findsWidgets);
    },
  );

  testWidgets('al final solo queda el tambor, ya sin recorte', (t) async {
    await show(t, 1);
    expect(find.byKey(const Key('backdrop-washer')), findsNothing);
    final interior = find.byKey(const Key('backdrop-interior'));
    expect(interior, findsOneWidget);
    expect(
      find.descendant(of: interior, matching: find.byType(ClipPath)),
      findsNothing,
    );
    expect(
      find.descendant(of: interior, matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('el tambor queda quieto: no hay ninguna rotación', (t) async {
    await show(t, 1);
    expect(
      find.descendant(
        of: find.byKey(const Key('backdrop-interior')),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });
}
