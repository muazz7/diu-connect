import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm, grounded palette — no blue, no purple, no teal.
/// Stone neutrals + rich forest green accent.
class AppTheme {
  // ── Warm Charcoal — headers, own chat bubbles ──
  static const Color charcoal = Color(0xFF292524);
  static const Color charcoalLight = Color(0xFF44403C);

  // ── Accent — warm forest green (natural, educational, soothing) ──
  static const Color accent = Color(0xFF15803D);
  static const Color accentSoft = Color(0xFFDCFCE7);

  // ── Surfaces — warm whites, never cold gray ──
  static const Color bg = Color(0xFFFAFAF8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color warm = Color(0xFFF5F5F0);

  // ── Text — warm stone tones ──
  static const Color textDark = Color(0xFF1C1917);
  static const Color textMid = Color(0xFF57534E);
  static const Color textLight = Color(0xFFA8A29E);

  // ── Borders ──
  static const Color border = Color(0xFFE7E5E4);
  static const Color borderStrong = Color(0xFFD6D3D1);

  // ── Semantic ──
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);

  // ── Shadows — warm, never blue-tinted ──
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: const Color(0xFF1C1917).withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: const Color(0xFF1C1917).withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        secondary: charcoal,
        surface: bg,
        error: error,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: GoogleFonts.inter(color: textMid, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: textLight, fontSize: 14),
      ),
    );
  }
}
