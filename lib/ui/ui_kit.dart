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
      // Superficie transparente: las filas de lista y los switches de adentro
      // pintan sus efectos de toque aquí y no debajo del fondo de la tarjeta.
      child: Material(type: MaterialType.transparency, child: child),
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

/// Barra superior de las pantallas secundarias: azul con esquinas redondeadas,
/// flecha de regreso y título.
class UiTopBar extends StatelessWidget implements PreferredSizeWidget {
  const UiTopBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Ui.navy1, Ui.navy2],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: preferredSize.height,
        child: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Regresar',
              onPressed: () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x29FFFFFF),
                fixedSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.arrow_back, color: Ui.headerText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Ui.headerText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selector de opciones en píldora blanca; la elegida va en azul marino.
class PillSelector<T> extends StatelessWidget {
  const PillSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onPick,
  });

  /// Valor, texto y llave opcional del texto de cada opción.
  final List<({T value, String label, Key? key})> options;
  final T selected;
  final ValueChanged<T> onPick;

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
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(o.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o.value == selected ? Ui.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    o.label,
                    key: o.key,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: o.value == selected ? Colors.white : Ui.ink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
