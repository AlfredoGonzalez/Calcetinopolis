import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art.dart';
import 'backdrop.dart';
import 'theme.dart';

/// Una pestaña de la barra inferior.
class NavTab {
  const NavTab({
    required this.label,
    required this.art,
    required this.fallback,
    this.badgeKey,
    this.showBadge = false,
  });

  final String label;
  final String art;
  final IconData fallback;

  /// Si se da, el ícono lleva un puntito de aviso con esta llave.
  final Key? badgeKey;
  final bool showBadge;
}

/// Barra inferior con vida: la pestaña elegida se agranda al doble, sube sobre
/// la barra y se sacude tres veces. Respeta "reducir animaciones".
class AnimatedBottomNav extends StatelessWidget {
  const AnimatedBottomNav({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  final List<NavTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  static const double height = 66;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          elevation: 10,
          shadowColor: Colors.black38,
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Ui.navy2, Ui.navy1],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: BubblesPainter(
                        seed: 3,
                        count: 9,
                        maxRadius: 10,
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: SizedBox(
                    height: height,
                    child: Row(
                      children: [
                        for (var i = 0; i < tabs.length; i++)
                          Expanded(
                            child: _NavButton(
                              tab: tabs[i],
                              selected: i == selected,
                              onTap: () => onSelect(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Espuma sobre el borde de la barra.
        const Positioned(
          left: 0,
          right: 0,
          top: -14,
          height: 16,
          child: IgnorePointer(
            child: CustomPaint(
              painter: FoamPainter(color: Ui.bg1, edge: Color(0xFF9FD7EE)),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  static const _iconSize = 28.0;
  static const _bigScale = 2.0;
  static const _rise = 30.0;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_NavButton old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      if (!MediaQuery.disableAnimationsOf(context)) _shake.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final reduce = MediaQuery.disableAnimationsOf(context);
    Widget icon = Art(tab.art, size: _iconSize, fallback: tab.fallback);
    if (tab.badgeKey != null) {
      icon = Badge(
        key: tab.badgeKey,
        isLabelVisible: tab.showBadge,
        smallSize: 8,
        backgroundColor: Palette.tomato,
        child: icon,
      );
    }
    return Semantics(
      button: true,
      selected: widget.selected,
      label: tab.label,
      child: GestureDetector(
        key: Key('nav-${tab.label}'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 6,
              child: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: widget.selected ? Ui.yellow : Ui.headerSub,
                ),
              ),
            ),
            Positioned(
              top: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: widget.selected ? 1.0 : 0.0),
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                builder: (context, k, child) {
                  return AnimatedBuilder(
                    animation: _shake,
                    builder: (context, _) {
                      final t = _shake.value;
                      // Tres sacudidas que se apagan.
                      final angle = t == 0 || t == 1
                          ? 0.0
                          : math.sin(t * math.pi * 6) * 0.3 * (1 - t);
                      return Transform.translate(
                        offset: Offset(0, -_rise * k),
                        child: Transform.rotate(
                          angle: angle,
                          child: Transform.scale(
                            scale: 1 + (_bigScale - 1) * k,
                            child: child,
                          ),
                        ),
                      );
                    },
                  );
                },
                child: icon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
