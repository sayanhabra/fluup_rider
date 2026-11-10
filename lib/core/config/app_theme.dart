import 'package:adm_rider/core/config/app_fonts.dart';
import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:flutter/material.dart';

/// ============================================================
/// BUILD CONTEXT THEME EXTENSIONS
/// ============================================================

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colorScheme => theme.colorScheme;

  CustomColors get customColors => theme.extension<CustomColors>()!;

  bool get isDarkMode => theme.brightness == Brightness.dark;
}

/// ============================================================
/// APP THEME
/// ============================================================

class AppTheme {
  AppTheme._();

  static const String primary = 'Poppins';

  /// ==========================================================
  /// LIGHT THEME
  /// ==========================================================

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ColorName.primary,
      brightness: Brightness.light,
      surface: Colors.white,
      primary: ColorName.primary,
    );

    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      colorScheme: colorScheme,

      fontFamily: AppFonts.primary,

      scaffoldBackgroundColor: ColorName.primaryBackgroundLight,

      extensions: const [CustomColors.light],

      // ================= APP BAR =================
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorName.primaryBackgroundLight,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: AppFonts.primary,
        ),
      ),

      // ================= CARD =================
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ================= INPUT =================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorName.inputFillLight.withValues(alpha: 0.58),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _inputBorder(ColorName.inputBorderLight),
        enabledBorder: _inputBorder(ColorName.inputBorderLight),
        focusedBorder: _inputBorder(ColorName.primary, width: 1.5),
        errorBorder: _inputBorder(Colors.red),
        focusedErrorBorder: _inputBorder(Colors.red, width: 1.5),
      ),

      // ================= DIVIDER =================
      dividerTheme: const DividerThemeData(
        color: ColorName.dividerLight,
        thickness: 1,
        space: 1,
      ),

      // ================= TEXT =================
      textTheme: _textTheme(Colors.black),

      // ================= ICON =================
      iconTheme: const IconThemeData(color: ColorName.iconLight),

      // ================= BOTTOM SHEET =================
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ================= DIALOG =================
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  /// ==========================================================
  /// DARK THEME
  /// ==========================================================

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ColorName.primary,
      brightness: Brightness.dark,
      surface: ColorName.surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      colorScheme: colorScheme,

      fontFamily: AppFonts.primary,

      scaffoldBackgroundColor: ColorName.primaryBackgroundDark,

      extensions: const [CustomColors.dark],

      // ================= APP BAR =================
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorName.primaryBackgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ================= CARD =================
      cardTheme: CardThemeData(
        color: ColorName.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ================= INPUT =================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorName.inputFillDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _inputBorder(Colors.white24),
        enabledBorder: _inputBorder(Colors.white24),
        focusedBorder: _inputBorder(ColorName.secondary, width: 1.5),
        errorBorder: _inputBorder(Colors.redAccent),
        focusedErrorBorder: _inputBorder(Colors.redAccent, width: 1.5),
      ),

      // ================= DIVIDER =================
      dividerTheme: const DividerThemeData(
        color: Colors.white12,
        thickness: 1,
        space: 1,
      ),

      // ================= TEXT =================
      textTheme: _textTheme(Colors.white),

      // ================= ICON =================
      iconTheme: const IconThemeData(color: Colors.white),

      // ================= BOTTOM SHEET =================
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorName.primaryBackgroundDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ================= DIALOG =================
      dialogTheme: DialogThemeData(
        backgroundColor: ColorName.primaryBackgroundDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  /// ==========================================================
  /// COMMON TEXT THEME
  /// ==========================================================

  static TextTheme _textTheme(Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(color: textColor),
      displayMedium: TextStyle(color: textColor),
      displaySmall: TextStyle(color: textColor),
      headlineLarge: TextStyle(color: textColor),
      headlineMedium: TextStyle(color: textColor),
      headlineSmall: TextStyle(color: textColor),
      titleLarge: TextStyle(color: textColor),
      titleMedium: TextStyle(color: textColor),
      titleSmall: TextStyle(color: textColor),
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor),
      bodySmall: TextStyle(color: textColor),
      labelLarge: TextStyle(color: textColor),
      labelMedium: TextStyle(color: textColor),
      labelSmall: TextStyle(color: textColor),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// ============================================================
/// CUSTOM COLORS
/// ============================================================

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.success,
    required this.info,
    required this.warning,
    required this.danger,
    required this.cardBackground,
    required this.headerText,
    required this.primaryBackground,
    required this.secondaryText,
    required this.border,
  });

  final Color success;
  final Color info;
  final Color warning;
  final Color danger;

  final Color cardBackground;
  final Color headerText;
  final Color primaryBackground;

  final Color secondaryText;
  final Color border;

  /// ==========================================================
  /// LIGHT COLORS
  /// ==========================================================

  static const light = CustomColors(
    success: ColorName.successLight,
    info: ColorName.infoLight,
    warning: ColorName.warningLight,
    danger: ColorName.dangerLight,

    cardBackground: Colors.white,

    headerText: ColorName.secondary,

    primaryBackground: ColorName.primaryBackgroundLight,

    secondaryText: ColorName.secondaryTextLight,

    border: ColorName.borderLightGray,
  );

  /// ==========================================================
  /// DARK COLORS
  /// ==========================================================

  static const dark = CustomColors(
    success: ColorName.successDark,
    info: ColorName.infoDark,
    warning: ColorName.warningDark,
    danger: ColorName.dangerDark,

    cardBackground: ColorName.primary,

    headerText: Colors.white,

    primaryBackground: ColorName.primaryBackgroundDark,

    secondaryText: ColorName.secondaryTextDark,

    border: ColorName.borderDark,
  );

  @override
  CustomColors copyWith({
    Color? success,
    Color? info,
    Color? warning,
    Color? danger,
    Color? cardBackground,
    Color? headerText,
    Color? primaryBackground,
    Color? secondaryText,
    Color? border,
  }) {
    return CustomColors(
      success: success ?? this.success,
      info: info ?? this.info,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      cardBackground: cardBackground ?? this.cardBackground,
      headerText: headerText ?? this.headerText,
      primaryBackground: primaryBackground ?? this.primaryBackground,
      secondaryText: secondaryText ?? this.secondaryText,
      border: border ?? this.border,
    );
  }

  @override
  CustomColors lerp(covariant CustomColors? other, double t) {
    if (other == null) {
      return this;
    }

    return CustomColors(
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      headerText: Color.lerp(headerText, other.headerText, t)!,
      primaryBackground: Color.lerp(
        primaryBackground,
        other.primaryBackground,
        t,
      )!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
