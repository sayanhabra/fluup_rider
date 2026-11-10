import 'package:flutter/material.dart';

class CommonEmptyListMessage extends StatelessWidget {
  const CommonEmptyListMessage({
    super.key,
    this.padding,
    this.text,
    this.textStyle,
    this.child,
    this.alignment,
  });
  final EdgeInsets? padding;
  final String? text;
  final Widget? child;
  final TextStyle? textStyle;
  final AlignmentGeometry? alignment;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        alignment: alignment,
        child: child ??
            Text(
              text ?? 'No Items found',
              style: textStyle ?? const TextStyle(fontSize: 16),
            ),
      ),
    );
  }
}
