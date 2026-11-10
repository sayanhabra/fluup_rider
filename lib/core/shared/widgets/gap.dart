import 'package:flutter/widgets.dart';

class Gap extends StatelessWidget {
  const Gap(this.gap, {super.key,this.child});
  final double gap;
  final Widget?  child;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: gap,
      child: child,
    );
  }
}
