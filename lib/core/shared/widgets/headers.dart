import 'package:adm_rider/core/config/app_theme.dart';
import 'package:adm_rider/core/shared/widgets/buttons.dart';
import 'package:flutter/material.dart';

class PrimaryHeader extends StatelessWidget {
  const PrimaryHeader({
    super.key,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.trailing,
    this.trailingText,
    this.title = 'No title',
    this.titleWidget,
    this.tooltip,
    this.onTapTrailing,
    this.titleStyle,
  });
  final EdgeInsetsGeometry padding;
  final void Function()? onTap;
  final String title;
  final Widget? titleWidget;
  final TextStyle? titleStyle;
  final String? tooltip;
  final Widget? trailing;
  final String? trailingText;
  final void Function()? onTapTrailing;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? title,
        triggerMode: TooltipTriggerMode.longPress,
        child: Container(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleWidget ??
                  Text(
                    title,
                    style:
                        titleStyle ??
                        TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: context.customColors.headerText,
                        ),
                  ),
              trailing ??
                  ViewAllButton(
                    text: trailingText ?? '',
                    onPressed: onTapTrailing,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
