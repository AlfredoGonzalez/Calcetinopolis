import 'package:calcetinopolis/ui/studio_splash.dart';
import 'package:calcetinopolis/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fake_video_player.dart';

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

  group('con video', () {
    late VideoPlayerPlatform original;
    setUp(() => original = VideoPlayerPlatform.instance);
    tearDown(() => VideoPlayerPlatform.instance = original);

    Widget videoApp({Duration timeout = const Duration(seconds: 3)}) =>
        MaterialApp(
          theme: buildTheme(),
          home: StudioSplash(
            videoAsset: 'assets/video/studio_logo.mp4',
            videoTimeout: timeout,
            child: const Scaffold(body: Text('juego')),
          ),
        );

    testWidgets('reproduce el video y un toque lo salta', (t) async {
      final fake = FakeVideoPlayer();
      VideoPlayerPlatform.instance = fake;
      await t.pumpWidget(videoApp());
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('studio-video')), findsOneWidget);
      expect(fake.calls, contains('play'));
      expect(find.text('juego'), findsNothing);
      await t.tap(find.byKey(const Key('studio-splash')));
      await t.pumpAndSettle();
      expect(find.text('juego'), findsOneWidget);
    });

    testWidgets('si el video falla cae a la pantalla de 3 s', (t) async {
      VideoPlayerPlatform.instance = FakeVideoPlayer(failOnCreate: true);
      await t.pumpWidget(videoApp());
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('studio-wordmark')), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
      await t.pumpAndSettle();
      expect(find.text('juego'), findsOneWidget);
    });

    testWidgets('si tarda en cargar cae a la pantalla de 3 s', (t) async {
      VideoPlayerPlatform.instance = FakeVideoPlayer(neverReady: true);
      await t.pumpWidget(videoApp(timeout: const Duration(milliseconds: 500)));
      await t.pump(const Duration(milliseconds: 600));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('studio-wordmark')), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
      await t.pumpAndSettle();
      expect(find.text('juego'), findsOneWidget);
    });
  });
}
