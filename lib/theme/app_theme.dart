import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Material 3 Blue Dark Theme Colors
  static const Color primaryBlue = Color(0xFF4285F4); // Material Blue 500
  static const Color primaryBlueDark = Color(0xFF1A73E8); // Material Blue 700
  static const Color secondaryBlue = Color(0xFF34A853); // Material Green 500
  static const Color surfaceDark = Color(0xFF121212); // Dark surface
  static const Color surfaceDarker = Color(0xFF0A0A0A); // Even darker surface
  static const Color surfaceContainer = Color(0xFF1E1E1E); // Container surface
  static const Color surfaceCard = Color(0xFF252525); // Card surface

  // Status colors
  static const Color connectedGreen = Color(0xFF34A853); // Material Green 500
  static const Color disconnectedRed = Color(0xFFEA4335); // Material Red 500
  static const Color connectingBlue = Color(0xFF4285F4); // Material Blue 500

  // Text colors
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFAAAAAA);
  static const Color textSecondary = Color(0xFFBDC1C6);

  // Backward compatibility - old color names mapped to new colors
  static const Color primaryGreen = connectedGreen;
  static const Color primaryDark = surfaceDark;
  static const Color secondaryDark = surfaceContainer;
  static const Color cardDark = surfaceCard;
  static const Color primaryDarker = surfaceDarker;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueDark],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceDark, surfaceContainer],
  );

  // Theme data with conditional font support
  static ThemeData darkTheme([String languageCode = 'en']) {
    final isRtlLanguage = languageCode == 'fa' || languageCode == 'ar';

    // Use Vazirmatn font for Persian and Arabic, Poppins for others
    final baseTextTheme = isRtlLanguage
        ? GoogleFonts.vazirmatnTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    final baseAppBarTextStyle = isRtlLanguage
        ? GoogleFonts.vazirmatn(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textLight,
          )
        : GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textLight,
          );

    final baseButtonTextStyle = isRtlLanguage
        ? GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.w600)
        : GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600);

    return ThemeData(
      useMaterial3: true, // Enable Material 3
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceDark,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlue,
        onPrimary: textLight,
        secondary: secondaryBlue,
        onSecondary: textLight,
        surface: surfaceDark,
        onSurface: textLight,
        surfaceContainerHighest: surfaceContainer,
        error: disconnectedRed,
        onError: textLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainer,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: baseAppBarTextStyle,
        iconTheme: const IconThemeData(color: textLight),
        actionsIconTheme: const IconThemeData(color: textLight),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: textLight,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: baseButtonTextStyle,
        ),
      ),
      textTheme: baseTextTheme,
      dividerTheme: const DividerThemeData(
        color: Color(0xFF323232),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue;
          }
          return textGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue.withValues(alpha: 0.5);
          }
          return textGrey.withValues(alpha: 0.5);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: textGrey.withValues(alpha: 0.3),
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withValues(alpha: 0.2),
      ),
    );
  }
}
