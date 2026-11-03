import 'package:flutter/material.dart';

/// Paleta de docs/ART_STYLE.md.
class Palette {
  static const cream = Color(0xFFFFF4E0);
  static const pink = Color(0xFFFF9EB5);
  static const blue = Color(0xFF7EC8E3);
  static const mint = Color(0xFFA8E6CF);
  static const butter = Color(0xFFFFE29A);
  static const orange = Color(0xFFFFB36B);
  static const lavender = Color(0xFFC3A6E8);
  static const tomato = Color(0xFFE85D5D);
  static const outline = Color(0xFF5A3E36);
  static const lint = Color(0xFFD9D4CC);
  static const gold = Color(0xFFF2B93B);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.blue,
    brightness: Brightness.light,
    surface: Palette.cream,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.cream,
    useMaterial3: true,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: Palette.outline,
      displayColor: Palette.outline,
    ),
  );
}
