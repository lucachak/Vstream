import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ─── Semantic Tokens ────────────────────────────────────────────────────────

  static Color bg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF050505) : const Color(0xFFF8F8F8);

  static Color bgCard(BuildContext context) =>
      _isDark(context) ? const Color(0xFF111111) : const Color(0xFFFFFFFF);

  static Color bgSurface(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);

  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? const Color(0xFFF5F5F5) : const Color(0xFF111111);

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? const Color(0xFFAAAAAA) : const Color(0xFF666666);

  static Color border(BuildContext context) =>
      _isDark(context) ? const Color(0xFF222222) : const Color(0xFFE0E0E0);

  static Color warning(BuildContext context) => const Color(0xFFFFB74D);

  static Color star(BuildContext context) => const Color(0xFFFFC107);

  static Color error(BuildContext context) =>
      _isDark(context) ? const Color(0xFFCF6679) : const Color(0xFFB00020);

  static Color success(BuildContext context) =>
      _isDark(context) ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ─── Constants ──────────────────────────────────────────────────────────────

  static const Color red = Color(0xFFE50914);
  static const Color redDark = Color(0xFFB20710);
  static const Color redGlow = Color(0x44E50914);
  static const Color textMuted = Color(0xFF888888);

  // Gradients
  static LinearGradient heroGradient(BuildContext context) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          _isDark(context)
              ? const Color(0xFF050505).withAlpha(150)
              : Colors.white.withAlpha(150),
          bg(context),
        ],
      );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE50914), Color(0xFF8B0000)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black87],
  );
}

class AppTheme {
  AppTheme._();

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static ThemeData get light => _build(false);
  static ThemeData get dark => _build(true);

  static ThemeData _build(bool isDark) {
    final primaryBg = isDark ? const Color(0xFF050505) : const Color(0xFFF8F8F8);
    final cardBg = isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
    final txtPrimary = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF111111);
    final txtSecondary = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666);
    final borderColor = isDark ? const Color(0xFF222222) : const Color(0xFFE0E0E0);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: AppColors.red,
      scaffoldBackgroundColor: primaryBg,
      cardColor: cardBg,
      dividerColor: borderColor,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
            color: txtPrimary, fontSize: 32, fontWeight: FontWeight.w900),
        displayMedium: GoogleFonts.inter(
            color: txtPrimary, fontSize: 24, fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.inter(
            color: txtPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        bodyLarge: GoogleFonts.inter(color: txtPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: txtSecondary, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: txtPrimary),
        titleTextStyle: GoogleFonts.inter(
            color: txtPrimary, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryBg,
        selectedItemColor: AppColors.red,
        unselectedItemColor: txtSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: txtPrimary,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),
    );
  }

  /// Cinematic Page Transition
  static Page customTransition(BuildContext context, GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }
}
