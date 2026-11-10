import 'package:flutter/material.dart';
import 'package:adm_rider/core/shared/styles/app_colors.dart';

enum ButtonState { enabled, disabled, loading }

// ============================================================
// BASE APP BUTTON
// ============================================================

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.child,
    required this.onPressed,
    this.radius = 9,
    this.color,
    this.disabledColor = ColorName.grey,
    this.elevation = 0,
    this.height = 48,
    this.minWidth,
    this.hoverColor,
    this.horizontalMargin = 0,
    this.verticalMargin = 0,
    this.horizontalPadding = 16,
    this.verticalPadding = 8,
    this.borderSide = BorderSide.none,
    this.isLoading = false,
  });

  final Widget? child;
  final VoidCallback? onPressed;

  final double radius;
  final Color? color;
  final Color? disabledColor;
  final Color? hoverColor;
  final double elevation;

  final double? height;
  final double? minWidth;

  final double horizontalMargin;
  final double verticalMargin;
  final double horizontalPadding;
  final double verticalPadding;

  final BorderSide borderSide;

  final bool isLoading;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: verticalMargin,
      ),
      child: Material(
        color: _isDisabled ? disabledColor : color,
        elevation: elevation,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: _isDisabled ? null : onPressed,
          hoverColor: hoverColor,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            height: height,
            constraints: BoxConstraints(minWidth: minWidth ?? 0),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.fromBorderSide(borderSide),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECONDARY BUTTON
// ============================================================

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.text,
    this.horizontalMargin = 16,
    this.onPressed,
    this.state = ButtonState.enabled,
    this.height = 54,
    this.icon,
  });

  final String text;
  final double horizontalMargin;
  final VoidCallback? onPressed;
  final ButtonState state;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDisabled = state == ButtonState.disabled;

    final isLoading = state == ButtonState.loading;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppButton(
      horizontalMargin: horizontalMargin,
      minWidth: double.infinity,
      radius: 100,
      height: height,
      color: ColorName.primary,
      disabledColor: isDark ? ColorName.inputFillDark : ColorName.disabledGray,
      isLoading: isLoading,
      onPressed: isDisabled ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              color: isDisabled
                  ? (isDark ? Colors.white30 : Colors.black54)
                  : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GRADIENT BUTTON
// ============================================================

class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.state = ButtonState.enabled,
    this.gradient,
    this.disabledGradient,
    this.height = 54,
    this.width = double.infinity,
    this.radius = 12,
    this.horizontalMargin = 0,
    this.verticalMargin = 0,
    this.textStyle,
    this.loadingColor = Colors.white,
  });

  final String text;
  final VoidCallback? onPressed;

  final IconData? icon;

  final ButtonState state;

  final Gradient? gradient;
  final Gradient? disabledGradient;

  final double height;
  final double? width;
  final double radius;

  final double horizontalMargin;
  final double verticalMargin;

  final TextStyle? textStyle;

  final Color loadingColor;

  bool get _isDisabled => state == ButtonState.disabled;

  bool get _isLoading => state == ButtonState.loading;

  @override
  Widget build(BuildContext context) {
    final activeGradient =
        gradient ??
        const LinearGradient(
          colors: [Color(0xFFF9A825), Color(0xFFFFB300)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );

    final inactiveGradient =
        disabledGradient ??
        LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: verticalMargin,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: _isDisabled ? inactiveGradient : activeGradient,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: InkWell(
            onTap: _isDisabled || _isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(radius),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? SizedBox(
                        key: const ValueKey('loader'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: loadingColor,
                        ),
                      )
                    : Row(
                        key: const ValueKey('content'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            text,
                            style:
                                textStyle ??
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GREY BUTTON
// ============================================================

class GreyButton extends StatelessWidget {
  const GreyButton({
    super.key,
    required this.text,
    this.horizontalMargin = 16,
    this.onPressed,
    this.icon,
    this.height = 50,
  });

  final String text;
  final double horizontalMargin;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white70 : ColorName.grayButtonText;

    return AppButton(
      onPressed: onPressed,
      horizontalMargin: horizontalMargin,
      minWidth: double.infinity,
      radius: 100,
      height: height,
      color: isDark ? ColorName.inputFillDark : ColorName.disabledGray,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19, color: fgColor),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              color: fgColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BORDER BUTTON
// ============================================================

class BorderButton extends StatelessWidget {
  const BorderButton({
    super.key,
    this.onPressed,
    this.child,
    this.text,
    this.textStyle,
    this.width,
    this.height = 46,
    this.radius = 100,
    this.borderColor = ColorName.greyDark,
    this.icon,
  });

  final VoidCallback? onPressed;

  /// If child is provided, text and icon are ignored.
  final Widget? child;

  final String? text;
  final TextStyle? textStyle;

  final double? width;
  final double height;
  final double radius;

  final Color borderColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppButton(
      onPressed: onPressed,
      minWidth: width,
      height: height,
      radius: radius,
      color: Colors.transparent,
      borderSide: BorderSide(color: borderColor),
      child:
          child ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: ColorName.secondary),
                const SizedBox(width: 7),
              ],
              Text(
                text ?? 'Button',
                style:
                    textStyle ??
                    TextStyle(
                      color: isDark ? Colors.white70 : ColorName.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
    );
  }
}

// ============================================================
// VIEW ALL BUTTON
// ============================================================

class ViewAllButton extends StatelessWidget {
  const ViewAllButton({
    super.key,
    this.text = 'View All',
    this.onPressed,
    this.textStyle,
  });

  final String text;
  final TextStyle? textStyle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BorderButton(
      text: text,
      onPressed: onPressed,
      height: 40,
      textStyle:
          textStyle ??
          const TextStyle(
            color: ColorName.secondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
    );
  }
}
