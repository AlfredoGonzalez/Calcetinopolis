import 'package:flutter/material.dart';

import 'theme.dart';

/// Tarjeta blanca con esquinas redondas y un borde inferior de color, el
/// bloque base de las pantallas rediseñadas.
class UiCard extends StatelessWidget {
  const UiCard({
    super.key,
    required this.child,
    this.edge = Ui.orangeSoft,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(12),
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  final Widget child;
  final Color edge;
  final Color color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// Botón grueso con borde inferior: verde si se puede pulsar, gris si no.
class ChunkyButton extends StatelessWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.detail,
    this.leading,
    this.width,
    this.height = 54,
    this.color = Ui.teal,
    this.edge = Ui.tealEdge,
  });

  final String label;
  final String? detail;

  /// Se muestra a la izquierda del detalle (por ejemplo una moneda).
  final Widget? leading;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Color color;
  final Color edge;

  @override
  Widget build(BuildContext context) {
    final on = onPressed != null;
    final ink = on ? Ui.ink : Ui.disabledInk;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: on ? color : Ui.disabled,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: on ? edge : Ui.disabledInk.withValues(alpha: 0.5),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                  if (detail != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            detail!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Círculo de color con un ícono o una imagen dentro.
class AccentBadge extends StatelessWidget {
  const AccentBadge({
    super.key,
    required this.color,
    required this.child,
    this.size = 56,
    this.shape = BoxShape.circle,
  });

  final Color color;
  final Widget child;
  final double size;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Ui.soft(color).withValues(alpha: 0.7),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Pestañas en píldora blanca; la elegida va en azul marino. Debe ir dentro
/// de un `DefaultTabController`.
class PillTabBar extends StatelessWidget {
  const PillTabBar({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(color: Ui.orangeSoft, offset: Offset(0, 3)),
        ],
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Ui.ink,
          borderRadius: BorderRadius.circular(19),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Ui.ink,
        labelStyle: const TextStyle(
          fontFamily: Ui.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: Ui.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        splashBorderRadius: BorderRadius.circular(19),
        tabs: [for (final l in labels) Tab(text: l, height: 38)],
      ),
    );
  }
}

/// Título de sección pequeño y redondeado.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Ui.ink2,
              ),
            ),
        ],
      ),
    );
  }
}
