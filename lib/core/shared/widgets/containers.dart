import 'package:flutter/material.dart';

import 'gap.dart';

class PointersContainer extends StatelessWidget {
  const PointersContainer(
      {super.key, required this.title, required this.points, this.titleStyle});
  final String title;
  final List<String> points;
  final TextStyle? titleStyle;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 42.5),
      padding: const EdgeInsets.fromLTRB(16, 15, 32, 25),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDCDCDC), width: 1),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(
            title,
            style: titleStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Gap(16),
          for (int i = 0; i < points.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ListPointContainer(index: i + 1),
                const Gap(14),
                Expanded(
                  child: Text(
                    points[i],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ListPointContainer extends StatelessWidget {
  const ListPointContainer({
    super.key,
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all()),
      alignment: Alignment.center,
      child: Text((index).toString()),
    );
  }
}

class AppPlaceholder extends StatelessWidget {
  const AppPlaceholder({
    super.key,
    this.height = 30,
    this.width = 30,
    this.shape = BoxShape.circle,
    this.color = const Color(0xFFE4E4E4),
    this.margin = const EdgeInsets.all(0),
    this.child,
  });
  final double? height, width;
  final EdgeInsets? margin;
  final Color? color;
  final BoxShape shape;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        shape: shape,
        color: color,
      ),
      child: FittedBox(
          child: child ??
              Icon(
                Icons.person_rounded,
                color: Colors.white,
              )),
    );
  }
}
