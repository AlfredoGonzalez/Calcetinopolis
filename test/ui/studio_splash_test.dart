import 'package:calcetinopolis/ui/studio_splash.dart';
import 'package:calcetinopolis/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({bool reduce = false}) => MaterialApp(
    theme: buildTheme(),
    builder: reduce
        ? (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          )
        : null,
    home: const StudioSplash(child: Scaffold(body: Text('juego'))),
  );

  testWidgets('muestra el estudio y a los 3 s pasa al juego', (t) async {
    await t.pumpWidget(app());
    expect(find.byKey(const Key('studio-splash')), findsOneWidget);
    expect(find.text('juego'), findsNothing);
    await t.pump(const Duration(milliseconds: 2900));
    expect(find.byKey(const Key('studio-splash')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 200));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('studio-splash')), findsNothing);
    expect(find.text('juego'), findsOneWidget);
  });

  testWidgets('un toque la salta', (t) async {
    await t.pumpWidget(app());
    await t.tap(find.byKey(const Key('studio-splash')));
    await t.pumpAndSettle();
    expect(find.text('juego'), findsOneWidget);
  });

  testWidgets('con reducir animaciones se salta sola', (t) async {
    await t.pumpWidget(app(reduce: true));
    await t.pumpAndSettle();
    expect(find.text('juego'), findsOneWidget);
  });
}
