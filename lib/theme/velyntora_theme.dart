import 'package:flutter/material.dart';

abstract final class VelyntoraColors {
  static const background = Color(0xFF080A18);
  static const surface = Color(0xFF111426);
  static const surfaceRaised = Color(0xFF191D34);
  static const border = Color(0xFF2B3150);
  static const violet = Color(0xFF9A4DFF);
  static const magenta = Color(0xFFF05CE7);
  static const cyan = Color(0xFF21D4F7);
  static const muted = Color(0xFF9AA3C2);
}

abstract final class VelyntoraTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: VelyntoraColors.violet,
      brightness: Brightness.dark,
      surface: VelyntoraColors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: VelyntoraColors.violet,
        secondary: VelyntoraColors.cyan,
        surface: VelyntoraColors.surface,
      ),
      scaffoldBackgroundColor: VelyntoraColors.background,
      dividerColor: VelyntoraColors.border,
      dialogTheme: const DialogThemeData(
        backgroundColor: VelyntoraColors.surfaceRaised,
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 350),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VelyntoraColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VelyntoraColors.border),
        ),
      ),
    );
  }
}
