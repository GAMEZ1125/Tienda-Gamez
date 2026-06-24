import 'package:flutter/material.dart';

class AppTheme {
  // ─── Brand Palette ───────────────────────────────────────────────
  static const Color brandRed = Color(0xFFE8173E);
  static const Color brandGreen = Color(0xFF0F2318);
  static const Color brandWhite = Color(0xFFFFFFFF);

  // Light red tones
  static const Color redLight = Color(0xFFFDE8EC);
  static const Color redMain = Color(0xFFE8173E);
  static const Color redDark = Color(0xFFB81232);

  // Green tones
  static const Color greenDark = Color(0xFF0F2318);
  static const Color greenForest = Color(0xFF1A3A28);
  static const Color greenAccent = Color(0xFF2ECC71);

  // Neutrals
  static const Color pearl = Color(0xFFF8F6F3);
  static const Color greyLight = Color(0xFFE8E5E0);
  static const Color greyMedium = Color(0xFF9E9E9E);

  // Semantic (keep consistent across themes)
  static const Color successColor = Color(0xFF2ECC71);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color errorColor = Color(0xFFE53935);

  // Gradient colors
  static const Color gradientRedStart = Color(0xFFE8173E);
  static const Color gradientRedEnd = Color(0xFFD4145A);
  static const Color gradientGreenStart = Color(0xFF0F2318);
  static const Color gradientGreenEnd = Color(0xFF1A3A28);
  static const Color gradientBlueStart = Color(0xFF2196F3);
  static const Color gradientBlueEnd = Color(0xFF1976D2);
  static const Color gradientPurpleStart = Color(0xFF9C27B0);
  static const Color gradientPurpleEnd = Color(0xFF7B1FA2);
  static const Color gradientOrangeStart = Color(0xFFFF9800);
  static const Color gradientOrangeEnd = Color(0xFFF57C00);
  static const Color gradientTealStart = Color(0xFF009688);
  static const Color gradientTealEnd = Color(0xFF00796B);

  // Convenience aliases to not break existing code
  static Color get primaryColor => brandRed;
  static Color get secondaryColor => brandGreen;
  static Color get surfaceColor => pearl;

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientRedStart, gradientRedEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [gradientGreenStart, gradientGreenEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFAFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [pearl, Color(0xFFF0EDE8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Theme Data ──────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: brandRed,
        onPrimary: Colors.white,
        secondary: greenForest,
        onSecondary: Colors.white,
        tertiary: greenAccent,
        onTertiary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: const Color(0xFF1C1B1F),
        surfaceContainerHigh: pearl,
        surfaceContainerLow: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F3F0),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: brandRed.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: brandRed);
          }
          return TextStyle(fontSize: 12, color: Colors.grey[600]);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: brandRed, size: 24);
          }
          return IconThemeData(color: Colors.grey[500], size: 22);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: brandRed.withValues(alpha: 0.3),
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandRed,
          side: const BorderSide(color: brandRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: greyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: brandRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandRed;
          return Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandRed.withValues(alpha: 0.4);
          return Colors.grey[300];
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: pearl,
        selectedColor: brandRed.withValues(alpha: 0.15),
      ),
      dividerTheme: DividerThemeData(
        color: greyLight,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandRed,
      ),
    );
  }

  // ─── Dark Theme ─────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: brandRed,
        onPrimary: Colors.white,
        secondary: greenAccent,
        onSecondary: Colors.black,
        tertiary: const Color(0xFF55EFC4),
        onTertiary: Colors.black,
        error: const Color(0xFFEF5350),
        onError: Colors.white,
        surface: const Color(0xFF121212),
        onSurface: const Color(0xFFF5F0EB),
        surfaceContainerHigh: const Color(0xFF1E1E1E),
        surfaceContainerLow: const Color(0xFF1A1A1A),
      ),
      scaffoldBackgroundColor: const Color(0xFF0E0E0E),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Color(0xFFF5F0EB),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        indicatorColor: brandRed.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: brandRed);
          }
          return const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E));
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: brandRed, size: 24);
          }
          return const IconThemeData(color: Color(0xFF9E9E9E), size: 22);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: brandRed.withValues(alpha: 0.4),
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandRed,
          side: const BorderSide(color: brandRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: brandRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        hintStyle: const TextStyle(color: Color(0xFF757575)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandRed;
          return Colors.grey[600];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandRed.withValues(alpha: 0.4);
          return Colors.grey[800];
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: brandRed.withValues(alpha: 0.25),
        labelStyle: const TextStyle(color: Color(0xFFF5F0EB)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A3A3A),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandRed,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: brandRed,
        selectionColor: brandRed.withValues(alpha: 0.4),
        selectionHandleColor: brandRed,
      ),
    );
  }
}
