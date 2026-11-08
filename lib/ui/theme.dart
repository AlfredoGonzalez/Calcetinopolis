import 'package:flutter/material.dart';

/// Paleta del arte (docs/ART_STYLE.md). El texto y los trazos de la interfaz
/// usan [outline], que ahora es el azul marino de la paleta "Aventura".
class Palette {
  static const cream = Color(0xFFFFF4E0);
  static const pink = Color(0xFFFF9EB5);
  static const blue = Color(0xFF7EC8E3);
  static const mint = Color(0xFFA8E6CF);
  static const butter = Color(0xFFFFE29A);
  static const orange = Color(0xFFFFB36B);
  static const lavender = Color(0xFFC3A6E8);
  static const tomato = Color(0xFFE85D5D);
  static const outline = Ui.ink;
  static const lint = Color(0xFFD9D4CC);
  static const gold = Color(0xFFF2B93B);
}

/// Paleta "Aventura" del rediseño de la interfaz (Claude Design).
class Ui {
  static const bg1 = Color(0xFFFFF4E0);
  static const bg2 = Color(0xFFFFE3BD);
  static const ink = Color(0xFF1D2B4A);
  static const ink2 = Color(0xFF55627F);
  static const navy1 = Color(0xFF1D2B4A);
  static const navy2 = Color(0xFF2C4A7C);

  static const orange = Color(0xFFFF7A3D);
  static const orangeSoft = Color(0xFFFFC9A8);
  static const teal = Color(0xFF38C9B0);
  static const tealEdge = Color(0xFF1F9A86);
  static const tealSoft = Color(0xFFA8ECE0);
  static const yellow = Color(0xFFFFC933);
  static const blue = Color(0xFF5AA9FF);
  static const violet = Color(0xFF8F7DFF);
  static const coral = Color(0xFFFF9B9B);

  static const disabled = Color(0xFFEBE4D6);
  static const disabledInk = Color(0xFF5A5F6D);
  static const track = Color(0xFFF3E4CC);

  /// Texto claro sobre el encabezado azul.
  static const headerText = Color(0xFFFFF4D6);
  static const headerSub = Color(0xFFE5D9FF);

  /// Colores de acento que se reparten entre negocios y secciones.
  static const accents = [orange, teal, yellow, blue, violet, coral];

  static Color accent(int i) => accents[i % accents.length];

  /// Versión clara de un acento, para bordes inferiores y fondos suaves.
  static Color soft(Color c) => Color.lerp(c, Colors.white, 0.55)!;

  static const fontFamily = 'Fredoka';
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Ui.navy2,
    brightness: Brightness.light,
    surface: Ui.bg1,
    primary: Ui.navy2,
    secondary: Ui.orange,
  );
  final base = ThemeData.light().textTheme.apply(
    fontFamily: Ui.fontFamily,
    bodyColor: Ui.ink,
    displayColor: Ui.ink,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Ui.bg1,
    useMaterial3: true,
    fontFamily: Ui.fontFamily,
    textTheme: base,
    appBarTheme: const AppBarTheme(
      backgroundColor: Ui.navy2,
      foregroundColor: Ui.headerText,
      titleTextStyle: TextStyle(
        fontFamily: Ui.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Ui.headerText,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Ui.orange,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: Ui.fontFamily,
          fontWeight: FontWeight.w700,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Ui.ink,
        textStyle: const TextStyle(
          fontFamily: Ui.fontFamily,
          fontWeight: FontWeight.w700,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Ui.ink,
        side: const BorderSide(color: Ui.ink, width: 2),
        textStyle: const TextStyle(
          fontFamily: Ui.fontFamily,
          fontWeight: FontWeight.w700,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Ui.bg1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: const TextStyle(
        fontFamily: Ui.fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Ui.ink,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: Ui.fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Ui.ink,
        height: 1.35,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Ui.orangeSoft, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Ui.orangeSoft, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Ui.orange, width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : Ui.ink2,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Ui.teal : Ui.track,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Ui.tealEdge : Ui.disabled,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Ui.orange,
      inactiveTrackColor: Ui.track,
      thumbColor: Ui.orange,
      trackHeight: 8,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Ui.ink,
      contentTextStyle: const TextStyle(
        fontFamily: Ui.fontFamily,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
