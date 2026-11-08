import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Las cutscenes en video del juego (vertical 9:16).
enum Cutscene {
  /// Primera vez que se abre el juego: la pareja se separa en la lavadora.
  intro(
    'intro',
    'El calcetín que se quedó solo',
    'assets/video/cutscene_intro.mp4',
  ),

  /// Primer Centrifugado: los dos calcetines se reencuentran.
  reunion('reunion', 'El reencuentro', 'assets/video/cutscene_reunion.mp4'),

  /// Primer regreso tras mucho tiempo fuera.
  welcome(
    'welcome',
    'Bienvenida de vuelta',
    'assets/video/cutscene_welcome.mp4',
  );

  const Cutscene(this.id, this.title, this.asset);

  /// Identificador que se guarda en la partida al verla.
  final String id;
  final String title;
  final String asset;
}

/// Muestra una cutscene a pantalla completa. Se puede saltar en cualquier
/// momento y, si el video no se puede reproducir, se cierra sola para que el
/// juego siga. Devuelve cuando termina o se salta.
Future<void> showCutscene(
  BuildContext context,
  Cutscene scene, {
  bool sound = true,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => CutscenePlayer(scene: scene, sound: sound),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class CutscenePlayer extends StatefulWidget {
  const CutscenePlayer({super.key, required this.scene, this.sound = true});

  final Cutscene scene;
  final bool sound;

  @override
  State<CutscenePlayer> createState() => _CutscenePlayerState();
}

class _CutscenePlayerState extends State<CutscenePlayer> {
  late final VideoPlayerController _video = VideoPlayerController.asset(
    widget.scene.asset,
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
  bool _ready = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await _video.initialize();
      // En la web el navegador bloquea el audio sin un toque previo.
      await _video.setVolume(widget.sound && !kIsWeb ? 1 : 0);
      _video.addListener(_onTick);
      if (!mounted) return;
      setState(() => _ready = true);
      try {
        await _video.play();
      } catch (_) {
        await _video.setVolume(0);
        await _video.play();
      }
    } catch (e) {
      debugPrint('Cutscene ${widget.scene.id}: no se pudo reproducir ($e)');
      _close();
    }
  }

  void _onTick() {
    final v = _video.value;
    if (v.hasError) return _close();
    if (v.isInitialized &&
        v.duration > Duration.zero &&
        v.position >= v.duration - const Duration(milliseconds: 80)) {
      _close();
    }
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _video.removeListener(_onTick);
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('cutscene-${widget.scene.id}'),
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _video.value.size.width,
                height: _video.value.size.height,
                child: VideoPlayer(_video),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  key: const Key('cutscene-skip'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black38,
                  ),
                  onPressed: _close,
                  child: const Text('Saltar'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
