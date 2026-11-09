import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Plataforma de video falsa: "carga" al instante y nunca avanza sola.
class FakeVideoPlayer extends VideoPlayerPlatform {
  FakeVideoPlayer({this.failOnCreate = false, this.neverReady = false});

  final bool failOnCreate;

  /// El video nunca termina de cargar.
  final bool neverReady;
  final List<String> calls = [];

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    if (failOnCreate) throw PlatformException(code: 'no-video');
    calls.add('create');
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => neverReady
      ? const Stream<VideoEvent>.empty()
      : Stream.value(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(seconds: 10),
            size: const Size(540, 960),
          ),
        );

  @override
  Future<void> play(int playerId) async => calls.add('play');

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> setVolume(int playerId, double volume) async =>
      calls.add('volume $volume');

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> dispose(int playerId) async => calls.add('dispose');

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Colors.blueGrey);

  @override
  Widget buildView(int playerId) => const ColoredBox(color: Colors.blueGrey);

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}
