import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Primary Palette ──
  static const Color primaryGold = Color(0xFFF5C542);
  static const Color secondaryGreen = Color(0xFF66BB6A);
  static const Color surfaceWhite = Color(0xFFFAFAFA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color dangerRed = Color(0xFFE53935);
  static const Color trainingBarDark = Color(0xFF1A1A1A);
  static const Color accentBlue = Color(0xFF42A5F5);

  // ── Glass Effect Constants ──
  static const double glassOpacity = 0.85;
  static const double cardBorderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double chipBorderRadius = 20.0;

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  // ── Glass Decoration ──
  static BoxDecoration glassDecoration({
    Color? color,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: (color ?? cardWhite).withValues(alpha: glassOpacity),
      borderRadius: BorderRadius.circular(borderRadius ?? cardBorderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.6),
        width: 0.5,
      ),
      boxShadow: cardShadow,
    );
  }

  // ── Typography ──
  static const String _fontFamily = '.SF Pro Text';

  static TextTheme get _textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.2,
          height: 1.3,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textTertiary,
          letterSpacing: 0.3,
          height: 1.3,
        ),
      );

  // ── Theme Data ──
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: _fontFamily,
        colorScheme: ColorScheme.light(
          primary: primaryGold,
          onPrimary: textPrimary,
          primaryContainer: primaryGold.withValues(alpha: 0.15),
          onPrimaryContainer: textPrimary,
          secondary: secondaryGreen,
          onSecondary: Colors.white,
          secondaryContainer: secondaryGreen.withValues(alpha: 0.15),
          onSecondaryContainer: textPrimary,
          tertiary: accentBlue,
          onTertiary: Colors.white,
          tertiaryContainer: accentBlue.withValues(alpha: 0.12),
          onTertiaryContainer: textPrimary,
          surface: surfaceWhite,
          onSurface: textPrimary,
          surfaceContainerHighest: cardWhite,
          error: dangerRed,
          onError: Colors.white,
          outline: const Color(0xFFE0E0E0),
          outlineVariant: const Color(0xFFF0F0F0),
        ),
        scaffoldBackgroundColor: surfaceWhite,
        textTheme: _textTheme,

        // AppBar
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          backgroundColor: surfaceWhite.withValues(alpha: 0.92),
          foregroundColor: textPrimary,
          titleTextStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            fontFamily: _fontFamily,
          ),
          iconTheme: const IconThemeData(color: textPrimary, size: 22),
        ),

        // Card
        cardTheme: CardThemeData(
          elevation: 0,
          color: cardWhite.withValues(alpha: glassOpacity),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardBorderRadius),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),

        // Bottom Navigation Bar
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 0,
          backgroundColor: cardWhite.withValues(alpha: 0.95),
          selectedItemColor: primaryGold,
          unselectedItemColor: textTertiary,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),

        // NavigationBar (Material 3)
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: cardWhite.withValues(alpha: 0.95),
          indicatorColor: primaryGold.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              );
            }
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: textTertiary,
            );
          }),
        ),

        // FloatingActionButton
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryGold,
          foregroundColor: textPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Elevated Button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGold,
            foregroundColor: textPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Text Button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryGold,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Outlined Button
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: cardWhite,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),

        // Input Decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            borderSide: const BorderSide(color: primaryGold, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dangerRed, width: 1),
          ),
          hintStyle: const TextStyle(
            fontSize: 14,
            color: textTertiary,
          ),
          labelStyle: const TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF5F5F5),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(chipBorderRadius),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: Color(0xFFF0F0F0),
          thickness: 0.5,
          space: 0,
        ),

        // SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: trainingBarDark,
          contentTextStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // BottomSheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),

        // Progress Indicator
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primaryGold,
          linearTrackColor: Color(0xFFEEEEEE),
        ),
      );

  // ── Utility ──

  /// Category color mapping for exercise types.
  static Color categoryColor(String category) {
    switch (category) {
      case 'main' || '主项':
        return primaryGold;
      case 'main_variant' || '主项变式':
        return const Color(0xFFFFB74D);
      case 'accessory' || '辅助项':
        return accentBlue;
      case 'cardio' || '有氧运动':
        return secondaryGreen;
      default:
        return textTertiary;
    }
  }

  /// State color mapping for training sets / records.
  static Color stateColor(String state) {
    switch (state) {
      case 'completed':
        return secondaryGreen;
      case 'in_progress' || 'pending':
        return primaryGold;
      case 'skipped':
        return textTertiary;
      case 'planning' || 'planned':
        return accentBlue;
      default:
        return textSecondary;
    }
  }
}
