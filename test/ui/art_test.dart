import 'package:calcetinopolis/ui/art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpArt(WidgetTester t, Widget w) => t.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: w)),
    ),
  );

  testWidgets('usa el arte pedido si existe', (t) async {
    await pumpArt(t, const Art('icon_pelusitas'));
    await t.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('si falta, usa el arte alterno', (t) async {
    await pumpArt(t, const Art('no_existe', fallbackName: 'icon_pelusitas'));
    await t.pump();
    await t.pump();
    // La imagen que falla queda en el árbol y su errorBuilder dibuja la alterna.
    expect(find.byType(Image), findsWidgets);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('si faltan ambos, muestra el ícono de respaldo', (t) async {
    await pumpArt(
      t,
      const Art('no_existe', fallbackName: 'tampoco', fallback: Icons.star),
    );
    await t.pump();
    await t.pump();
    await t.pump();
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('sin nombre ni respaldo no truena', (t) async {
    await pumpArt(t, const Art(null, size: 20));
    expect(find.byType(SizedBox), findsWidgets);
  });
}
