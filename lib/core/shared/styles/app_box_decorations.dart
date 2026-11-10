import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:flutter/material.dart';

class AppDecorations {
  AppDecorations._();

  // ============================================================
  // PRIMARY SHADOW
  // ============================================================

  static BoxDecoration primaryShadow({
    Color color = Colors.white,
    double borderRadius = 16,
    Border? border,
    Gradient? gradient,
    DecorationImage? image,
  }) {
    return BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      border: border,
      image: image,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: ColorName.black.withValues(alpha: 0.10),
          blurRadius: 15,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ============================================================
  // LIGHT CARD SHADOW
  // ============================================================

  static BoxDecoration card({
    Color color = Colors.white,
    double borderRadius = 16,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ============================================================
  // NEUMORPHIC SHADOW
  // ============================================================

  static BoxDecoration neumorphic({
    Color backgroundColor = Colors.white,
    double borderRadius = 16,
    Border? border,
    DecorationImage? image,
    Gradient? gradient,
    bool isDarkMode = false,
    List<BoxShadow>? boxShadow,
    BlendMode? backgroundBlendMode,
  }) {
    final shadows =
        boxShadow ??
        [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.grey.withValues(alpha: 0.35),
            offset: const Offset(8, 8),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white,
            offset: const Offset(-8, -8),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ];

    return BoxDecoration(
      color: gradient == null ? backgroundColor : null,
      gradient: gradient,
      border: border,
      borderRadius: BorderRadius.circular(borderRadius),
      image: image,
      boxShadow: shadows,
      backgroundBlendMode: backgroundBlendMode,
    );
  }

  // ============================================================
  // INSET-LIKE NEUMORPHIC DECORATION
  //
  // Flutter BoxShadow does not support true inset shadows.
  // This provides a pressed-style appearance.
  // ============================================================

  static BoxDecoration neumorphicPressed({
    Color backgroundColor = const Color(0xFFF0F0F3),
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          offset: const Offset(2, 2),
          blurRadius: 5,
        ),
      ],
    );
  }

  // ============================================================
  // BORDER DECORATION
  // ============================================================

  static BoxDecoration bordered({
    Color backgroundColor = Colors.white,
    Color borderColor = const Color(0xFFE5E5E5),
    double borderWidth = 1,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
    );
  }

  // ============================================================
  // GRADIENT DECORATION
  // ============================================================

  static BoxDecoration gradient({
    required Gradient gradient,
    double borderRadius = 16,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: boxShadow,
    );
  }

  // ============================================================
  // CIRCULAR DECORATION
  // ============================================================

  static BoxDecoration circle({
    Color color = Colors.white,
    Gradient? gradient,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      shape: BoxShape.circle,
      border: border,
      boxShadow: boxShadow,
    );
  }

  // ============================================================
  // CUSTOM DECORATION
  // ============================================================

  static BoxDecoration custom({
    Color? color = Colors.white,
    double borderRadius = 16,
    Border? border,
    DecorationImage? image,
    BoxShape shape = BoxShape.rectangle,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
    BlendMode? backgroundBlendMode,
  }) {
    return BoxDecoration(
      // BoxDecoration should not normally have both
      // color and gradient.
      color: gradient == null ? color : null,

      gradient: gradient,

      border: border,

      // Circle cannot use borderRadius.
      borderRadius: shape == BoxShape.rectangle
          ? BorderRadius.circular(borderRadius)
          : null,

      shape: shape,

      image: image,

      boxShadow: boxShadow,

      backgroundBlendMode: backgroundBlendMode,
    );
  }
}




// Container(
//   padding: const EdgeInsets.all(16),
//   decoration: AppDecorations.card(),
//   child: const Text('Card'),
// )
// Container(
//   decoration: AppDecorations.neumorphic(
//     backgroundColor:
//         const Color(0xFFF0F0F3),
//     borderRadius: 20,
//   ),
// )
// Container(
//   decoration: AppDecorations.gradient(
//     gradient: const LinearGradient(
//       colors: [
//         Color(0xFFF9A825),
//         Color(0xFFFFB300),
//       ],
//     ),
//     borderRadius: 16,
//   ),
// )
// Container(
//   width: 50,
//   height: 50,
//   decoration: AppDecorations.circle(
//     color: Colors.orange,
//   ),
//   child: const Icon(
//     Icons.person,
//     color: Colors.white,
//   ),
// )