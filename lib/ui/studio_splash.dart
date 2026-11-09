import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'theme.dart';

/// Pantalla del estudio que se ve al abrir la app, como las de los motores de
/// juego: aparece, se queda un momento y se desvanece a los 3 segundos. Un
/// toque la salta.
///
/// Con [videoAsset] reproduce el video del estudio (el "logo reveal"); si el
/// video no se puede reproducir, o tarda en cargar, cae a la versión de 3 s
/// con el nombre del estudio, para que el juego nunca se quede esperando.
class StudioSplash extends StatefulWidget {
  const StudioSplash({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.videoAsset,
    this.sound = true,
    this.videoTimeout = const Duration(seconds: 3),
  });

  /// Lo que se muestra cuando la pantalla termina.
  final Widget child;
  final Duration duration;

  /// Video del estudio (vertical). Si es null, se usa la pantalla de 3 s.
  final String? videoAsset;
  final bool sound;

  /// Si el video no está listo en este tiempo, se usa la pantalla de 3 s.
  final Duration videoTimeout;

  @override
  State<StudioSplash> createState() => _StudioSplashState();
}

class _StudioSplashState extends State<StudioSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _done = false;
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _useAnimation = true;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
    if (widget.videoAsset == null) {
      _anim.forward();
    } else {
      _useAnimation = false;
      unawaited(_startVideo());
    }
  }

  Future<void> _startVideo() async {
    _timeout = Timer(widget.videoTimeout, () {
      if (!_videoReady) _fallback();
    });
    try {
      final v = VideoPlayerController.asset(
        widget.videoAsset!,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _video = v;
      await v.initialize();
      if (!mounted || _done || _useAnimation) return;
      // En la web el navegador bloquea el audio sin un toque previo.
      await v.setVolume(widget.sound && !kIsWeb ? 1 : 0);
      v.addListener(_onVideoTick);
      setState(() => _videoReady = true);
      _timeout?.cancel();
      try {
        await v.play();
      } catch (_) {
        await v.setVolume(0);
        await v.play();
      }
    } catch (e) {
      debugPrint('Video del estudio: no se pudo reproducir ($e)');
      _fallback();
    }
  }

  void _onVideoTick() {
    final v = _video?.value;
    if (v == null) return;
    if (v.hasError) return _fallback();
    if (v.isInitialized &&
        v.duration > Duration.zero &&
        v.position >= v.duration - const Duration(milliseconds: 80)) {
      _finish();
    }
  }

  /// El video no sirvió: se muestra la pantalla de 3 s.
  void _fallback() {
    if (_done || _useAnimation || !mounted) return;
    _timeout?.cancel();
    setState(() {
      _useAnimation = true;
      _videoReady = false;
    });
    _anim.forward();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done || !mounted) return;
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) && !_done) {
      // Sin animaciones: se salta la pantalla.
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _done
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : GestureDetector(
              key: const ValueKey('studio-splash'),
              behavior: HitTestBehavior.opaque,
              onTap: _finish,
              child: _useAnimation
                  ? _SplashBody(animation: _anim)
                  : _VideoBody(video: _videoReady ? _video : null),
            ),
    );
  }
}

/// El video del estudio sobre negro (mientras carga, solo negro).
class _VideoBody extends StatelessWidget {
  const _VideoBody({required this.video});

  final VideoPlayerController? video;

  @override
  Widget build(BuildContext context) {
    final v = video;
    return ColoredBox(
      key: const Key('studio-video'),
      color: const Color(0xFF0B0D14),
      child: v == null
          ? const SizedBox.expand()
          : SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: v.value.size.width,
                  height: v.value.size.height,
                  child: VideoPlayer(v),
                ),
              ),
            ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [Ui.navy2, Ui.navy1, Color(0xFF0E1628)],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = animation.value;
            // Entra en el primer 20%, se queda y sale en el último 25%.
            final opacity = t < 0.2
                ? Curves.easeOut.transform(t / 0.2)
                : (t > 0.75
                      ? 1 - Curves.easeIn.transform((t - 0.75) / 0.25)
                      : 1.0);
            final scale = 0.94 + 0.06 * Curves.easeOut.transform(t.clamp(0, 1));
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: const _StudioMark(),
        ),
      ),
    );
  }
}

class _StudioMark extends StatelessWidget {
  const _StudioMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/art/studio_logo.png',
          width: 220,
          errorBuilder: (_, _, _) => const Text(
            'AM',
            key: Key('studio-wordmark'),
            style: TextStyle(
              fontFamily: Ui.fontFamily,
              fontSize: 96,
              height: 1,
              fontWeight: FontWeight.w700,
              color: Ui.headerText,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'ESTUDIO',
          style: TextStyle(
            fontFamily: Ui.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Ui.headerSub,
            letterSpacing: 8,
          ),
        ),
      ],
    );
  }
}
