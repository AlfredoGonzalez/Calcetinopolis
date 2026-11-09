import 'dart:io';

import 'package:calcetinopolis/app/game_controller.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/ui/cutscene_player.dart';
import 'package:calcetinopolis/ui/home_shell.dart';
import 'package:calcetinopolis/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fake_video_player.dart';

void main() {
  final config = EconomyConfig.fromJsonString(
    File('config/economy.json').readAsStringSync(),
  );
  late VideoPlayerPlatform original;

  setUp(() => original = VideoPlayerPlatform.instance);
  tearDown(() => VideoPlayerPlatform.instance = original);

  Future<void> pumpHome(WidgetTester t, GameController c) async {
    await t.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: HomeShell(controller: c),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('la intro sale en una partida nueva y se salta', (t) async {
    final fake = FakeVideoPlayer();
    VideoPlayerPlatform.instance = fake;
    final c = GameController(Economy(config), cutscenes: true)
      ..state.tutorialDone = true;
    await pumpHome(t, c);
    expect(find.byKey(const Key('cutscene-intro')), findsOneWidget);
    expect(fake.calls, contains('play'));
    expect(c.hasSeenCutscene('intro'), isFalse);

    await t.tap(find.byKey(const Key('cutscene-skip')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cutscene-intro')), findsNothing);
    expect(c.hasSeenCutscene('intro'), isTrue);
  });

  testWidgets('la intro no vuelve a salir una vez vista', (t) async {
    VideoPlayerPlatform.instance = FakeVideoPlayer();
    final c = GameController(Economy(config), cutscenes: true);
    c.state.cutscenesSeen.add('intro');
    await pumpHome(t, c);
    expect(find.byKey(const Key('cutscene-intro')), findsNothing);
  });

  testWidgets('sin cutscenes activas no sale nada', (t) async {
    VideoPlayerPlatform.instance = FakeVideoPlayer();
    final c = GameController(Economy(config));
    await pumpHome(t, c);
    expect(find.byKey(const Key('cutscene-intro')), findsNothing);
  });

  testWidgets('con el sonido apagado el video va en silencio', (t) async {
    final fake = FakeVideoPlayer();
    VideoPlayerPlatform.instance = fake;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showCutscene(context, Cutscene.welcome, sound: false),
            child: const Text('ver'),
          ),
        ),
      ),
    );
    await t.tap(find.text('ver'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(fake.calls, contains('volume 0.0'));
    await t.tap(find.byKey(const Key('cutscene-skip')));
    await t.pumpAndSettle();
  });

  testWidgets('si el video falla se cierra sola y el juego sigue', (t) async {
    VideoPlayerPlatform.instance = FakeVideoPlayer(failOnCreate: true);
    final c = GameController(Economy(config), cutscenes: true)
      ..state.tutorialDone = true;
    await pumpHome(t, c);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cutscene-intro')), findsNothing);
    expect(find.text('Negocios'), findsWidgets);
  });
}
