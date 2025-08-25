import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvColors {
  static const primary = Color(0xFF0EA5E9); // ajusta a tu paleta
  static const surface = Color(0xFFF8FAFC);
  static const textDark = Color(0xFF0F172A);
  static const textMute = Color(0xFF64748B);
}

ThemeData buildTheme() => _base(Brightness.light);
ThemeData buildDarkTheme() => _base(Brightness.dark);

ThemeData _base(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AvColors.primary,
    brightness: brightness,
  );

  final textTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF0B1220) : AvColors.surface,
    textTheme: textTheme.copyWith(
      displayLarge:
          textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium:
          textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      titleLarge:
          textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: isDark ? Colors.white : AvColors.textDark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
        ),
      ),
      hintStyle: const TextStyle(color: AvColors.textMute),
    ),
    // 🔧 En Flutter 3.35, ThemeData.cardTheme espera CardThemeData
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AvColors.primary,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: TextStyle(
        color: isDark ? Colors.white : AvColors.textDark,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor:
          isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
      selectedColor: colorScheme.primaryContainer,
      secondarySelectedColor: colorScheme.primaryContainer,
    ),
  );
}
