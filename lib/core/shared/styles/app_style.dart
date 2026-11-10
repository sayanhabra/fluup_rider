import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:flutter/material.dart';

class AppStyle {
  AppStyle._();

  // ============================================================
  // BORDER RADIUS
  // ============================================================

  static const double radiusSmall = 6;
  static const double radiusMedium = 10;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusCircular = 100;

  static BorderRadius get borderRadiusSmall =>
      BorderRadius.circular(radiusSmall);

  static BorderRadius get borderRadiusMedium =>
      BorderRadius.circular(radiusMedium);

  static BorderRadius get borderRadiusLarge =>
      BorderRadius.circular(radiusLarge);

  static BorderRadius get borderRadiusXLarge =>
      BorderRadius.circular(radiusXLarge);

  static BorderRadius get borderRadiusCircular =>
      BorderRadius.circular(radiusCircular);

  // ============================================================
  // SPACING
  // ============================================================

  static const double spaceXS = 4;
  static const double spaceSmall = 8;
  static const double spaceMedium = 12;
  static const double spaceLarge = 16;
  static const double spaceXLarge = 24;
  static const double spaceXXLarge = 32;

  // ============================================================
  // PADDING
  // ============================================================

  static const EdgeInsets paddingXS = EdgeInsets.all(4);

  static const EdgeInsets paddingSmall = EdgeInsets.all(8);

  static const EdgeInsets paddingMedium = EdgeInsets.all(12);

  static const EdgeInsets paddingLarge = EdgeInsets.all(16);

  static const EdgeInsets paddingXLarge = EdgeInsets.all(24);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  );

  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: 16,
  );

  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 16);

  // ============================================================
  // TEXT STYLES
  // ============================================================

  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle errorText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.red,
  );

  static const buttonPreviousTextStyle = TextStyle(
    color: ColorName.primarybackground,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static const buttonNextTextStyle = TextStyle(
    color: ColorName.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // ============================================================
  // COMMON COLORS
  // Prefer AppColors/ColorName for project-specific colors.
  // ============================================================

  static const Color primaryColor = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF42A5F5);

  static const Color successColor = Color(0xFF28A745);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFDC3545);
  static const Color infoColor = Color(0xFF17A2B8);

  static const Color backgroundColor = Color(0xFFF6F7F9);
  static const Color cardColor = Colors.white;

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color borderColor = Color(0xFFE5E7EB);

  // ============================================================
  // SHADOWS
  // ============================================================

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ============================================================
  // BORDERS
  // ============================================================

  static const BorderSide defaultBorder = BorderSide(color: borderColor);

  static const BorderSide focusedBorder = BorderSide(
    color: primaryColor,
    width: 1.5,
  );

  static const BorderSide errorBorder = BorderSide(color: errorColor);

  static OutlineInputBorder inputBorder({
    Color color = borderColor,
    double width = 1,
    double radius = radiusMedium,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // ============================================================
  // BOX DECORATIONS
  // ============================================================

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: borderRadiusLarge,
    boxShadow: softShadow,
  );

  static BoxDecoration get borderedCardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: borderRadiusLarge,
    border: Border.all(color: borderColor),
  );

  static BoxDecoration get roundedDecoration =>
      BoxDecoration(color: cardColor, borderRadius: borderRadiusCircular);

  static BoxDecoration coloredDecoration(
    Color color, {
    double radius = radiusMedium,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration gradientDecoration({
    required List<Color> colors,
    double radius = radiusMedium,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(colors: colors, begin: begin, end: end),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  static InputDecoration inputDecoration({
    String? hint,
    String? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,

      filled: true,
      fillColor: const Color(0xFFF8F8F8),

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      enabledBorder: inputBorder(),

      focusedBorder: inputBorder(color: primaryColor, width: 1.5),

      errorBorder: inputBorder(color: errorColor),

      focusedErrorBorder: inputBorder(color: errorColor, width: 1.5),
    );
  }

  // ============================================================
  // BUTTON STYLES
  // ============================================================

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
  );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    minimumSize: const Size(double.infinity, 52),
    side: const BorderSide(color: primaryColor),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
  );

  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
    foregroundColor: primaryColor,
    textStyle: buttonText,
  );

  // ============================================================
  // DIVIDER
  // ============================================================

  static const Divider divider = Divider(
    height: 1,
    thickness: 1,
    color: borderColor,
  );

  // ============================================================
  // GRADIENTS
  // ============================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  // ============================================================
  // ICON STYLES
  // ============================================================

  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
  static const double iconXLarge = 48;
}
