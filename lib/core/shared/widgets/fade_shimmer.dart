import 'package:flutter/material.dart';

class FadeShimmer extends StatefulWidget {
  const FadeShimmer({
    super.key,
    this.height = 10,
    this.width = 100,
    this.child,
    this.color,
    this.begin,
    this.end,
    this.radius,
    this.shape,
  });
  final double? height;
  final double? width;
  final Widget? child;
  final Color? color;
  final double? begin;
  final double? end;
  final double? radius;
  final BoxShape? shape;

  @override
  State<FadeShimmer> createState() => _FadeShimmerState();
}

class _FadeShimmerState extends State<FadeShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Tween<double> _tween = Tween(begin: 0.3, end: 0.7);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _tween.animate(_animationController),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          shape: widget.shape ?? BoxShape.rectangle,
          color: widget.color ?? Colors.grey,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : BorderRadius.circular(widget.radius ?? 3),
        ),
        child: widget.child,
      ),
    );
  }
}
