import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// core/shared/widgets/svg_icon.dart

class SvgNavIcon extends StatelessWidget {
  const SvgNavIcon({
    super.key,
    required this.assetPath,
    required this.color,
    this.size = 20,
    this.isActive = false,
  });

  final String assetPath;
  final Color color;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      width: size,
      height: size,
    );
  }
}
