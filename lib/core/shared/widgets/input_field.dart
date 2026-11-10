import 'package:adm_rider/core/shared/widgets/gap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:adm_rider/core/shared/styles/app_colors.dart';

/// ============================================================
/// COMMON INPUT DECORATION
/// ============================================================

class AppInputDecoration {
  AppInputDecoration._();

  static InputDecoration build({
    BuildContext? context,
    String? hint,
    Widget? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    double borderRadius = 9,
    EdgeInsetsGeometry? contentPadding,
    Color? fillColor,
    Color? borderColor,
    Color? focusedBorderColor,
    Color? errorBorderColor,
    bool filled = true,
    BoxConstraints? prefixIconConstraints,
    BoxConstraints? suffixIconConstraints,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final bool isDark =
        context != null && Theme.of(context).brightness == Brightness.dark;

    final resolvedFillColor =
        fillColor ??
        (isDark ? ColorName.inputFillDark : ColorName.inputFillLight);
    final resolvedBorderColor =
        borderColor ?? (isDark ? Colors.white24 : ColorName.inputBorderLight);
    final resolvedFocusedBorderColor =
        focusedBorderColor ??
        (isDark ? ColorName.secondary : ColorName.greyDark);
    final resolvedErrorBorderColor =
        errorBorderColor ?? (isDark ? Colors.redAccent : Colors.red);

    return InputDecoration(
      hintText: hint,
      label: label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,

      filled: filled,
      fillColor: resolvedFillColor,

      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

      prefixIconConstraints: prefixIconConstraints,
      suffixIconConstraints: suffixIconConstraints,

      counterText: '',

      enabledBorder: border(resolvedBorderColor),

      focusedBorder: border(resolvedFocusedBorderColor, width: 1.5),

      disabledBorder: border(resolvedBorderColor.withValues(alpha: 0.5)),

      errorBorder: border(resolvedErrorBorderColor),

      focusedErrorBorder: border(resolvedErrorBorderColor, width: 1.5),

      border: border(resolvedBorderColor),

      floatingLabelStyle: TextStyle(color: resolvedFocusedBorderColor),

      alignLabelWithHint: true,
    );
  }
}

/// ============================================================
/// APP TEXT FIELD
/// ============================================================

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.borderRadius = 9,
    this.enabled = true,
    this.hint,
    this.label,
    this.suffix,
    this.errorText,
    this.prefixIcon,
    this.keyboardType,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.onSaved,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.decoration,
    this.inputFormatters,
    this.onTap,
    this.obscureText = false,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.contentPadding,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.style,
    this.hintStyle,
    this.cursorColor,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.onEditingComplete,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  final double borderRadius;

  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final bool enableSuggestions;
  final bool autocorrect;

  final String? hint;
  final String? errorText;

  final Widget? label;
  final Widget? suffix;
  final Widget? prefixIcon;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  final int? maxLength;
  final int? minLines;
  final int? maxLines;

  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;

  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;

  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;

  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;

  final TextCapitalization textCapitalization;

  final InputDecoration? decoration;

  final List<TextInputFormatter>? inputFormatters;

  final EdgeInsetsGeometry? contentPadding;

  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;

  final TextStyle? style;
  final TextStyle? hintStyle;

  final Color? cursorColor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,

      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,

      keyboardType: keyboardType,
      textInputAction: textInputAction,

      textCapitalization: textCapitalization,

      obscureText: obscureText,
      enableSuggestions: obscureText ? false : enableSuggestions,
      autocorrect: obscureText ? false : autocorrect,

      maxLength: maxLength,

      minLines: obscureText ? 1 : minLines,

      maxLines: obscureText ? 1 : maxLines,

      textAlign: textAlign,
      textAlignVertical: textAlignVertical,

      style: style,

      cursorColor: cursorColor,

      inputFormatters: inputFormatters,

      validator: validator,

      onTap: onTap,
      onChanged: onChanged,
      onSaved: onSaved,

      onFieldSubmitted: onFieldSubmitted,

      onEditingComplete: onEditingComplete,

      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
      },

      decoration:
          decoration ??
          AppInputDecoration.build(
            context: context,
            hint: hint,
            label: label,
            prefixIcon: prefixIcon,
            suffixIcon: suffix,
            errorText: errorText,
            borderRadius: borderRadius,
            contentPadding: contentPadding,
            prefixIconConstraints: prefixIconConstraints,
            suffixIconConstraints: suffixIconConstraints,
          ).copyWith(
            hintStyle:
                hintStyle ??
                TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white30
                      : Colors.black38,
                ),
          ),
    );
  }
}

/// ============================================================
/// TEXT FIELD WITH EXTERNAL LABEL
/// ============================================================

class AppTextFieldWithLabel extends StatelessWidget {
  const AppTextFieldWithLabel({
    super.key,
    required this.textField,
    this.gap = 8,
    this.padding = EdgeInsets.zero,
    this.labelText,
    this.labelStyle,
    this.label,
    this.isRequired = false,
  });

  final String? labelText;
  final TextStyle? labelStyle;

  final Widget? label;

  final double gap;

  final EdgeInsetsGeometry padding;

  final Widget textField;

  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            label!
          else if (labelText != null)
            InputLabel(
              text: labelText!,
              labelStyle: labelStyle,
              isRequired: isRequired,
            ),

          if (label != null || labelText != null) Gap(gap),

          textField,
        ],
      ),
    );
  }
}

/// ============================================================
/// INPUT LABEL
/// ============================================================

class InputLabel extends ConsumerWidget {
  const InputLabel({
    super.key,
    required this.text,
    this.labelStyle,
    this.provider,
    this.isRequired = false,
    this.showSuccessIcon = true,
  });

  final String text;

  final ProviderListenable<bool>? provider;

  final TextStyle? labelStyle;

  final bool isRequired;
  final bool showSuccessIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isValid = provider != null ? ref.watch(provider!) : false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style:
              labelStyle ??
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
        ),

        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),

        if (showSuccessIcon && provider != null && isValid) ...[
          const SizedBox(width: 5),

          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 17),
        ],
      ],
    );
  }
}

/// ============================================================
/// APP DROPDOWN
/// ============================================================

class AppDropDown<T> extends StatelessWidget {
  const AppDropDown({
    super.key,
    required this.items,
    this.onChanged,
    this.value,
    this.decoration,
    this.borderRadius = 9,
    this.enabled = true,
    this.hint,
    this.hintWidget,
    this.label,
    this.suffix,
    this.errorText,
    this.prefixIcon,
    this.validator,
    this.onSaved,
    this.isExpanded = true,
    this.menuMaxHeight,
    this.dropdownColor,
    this.icon,
  });

  final List<DropdownMenuItem<T>> items;

  final T? value;

  final ValueChanged<T?>? onChanged;

  final FormFieldValidator<T>? validator;

  final FormFieldSetter<T>? onSaved;

  final InputDecoration? decoration;

  final double borderRadius;

  final bool enabled;
  final bool isExpanded;

  final String? hint;
  final Widget? hintWidget;

  final Widget? label;
  final Widget? suffix;
  final Widget? prefixIcon;
  final Widget? icon;

  final String? errorText;

  final double? menuMaxHeight;

  final Color? dropdownColor;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,

      items: items,

      onChanged: enabled ? onChanged : null,

      validator: validator,

      onSaved: onSaved,

      isExpanded: isExpanded,

      menuMaxHeight: menuMaxHeight,

      dropdownColor: dropdownColor,

      icon: icon ?? const Icon(Icons.keyboard_arrow_down_rounded),

      hint: hintWidget ?? (hint != null ? Text(hint!) : null),

      decoration:
          decoration ??
          AppInputDecoration.build(
            context: context,
            label: label,
            prefixIcon: prefixIcon,
            suffixIcon: suffix,
            errorText: errorText,
            borderRadius: borderRadius,
          ),
    );
  }
}
