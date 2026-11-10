// import 'package:adm_user/core/shared/widgets/gap.dart';
// import 'package:flutter_modular/flutter_modular.dart';
// import 'package:adm_user/core/shared/styles/app_colors.dart';
// import 'package:flutter/material.dart';

// formScreenAppBar(
//   BuildContext context, {
//   Widget? leading,
//   void Function()? onBackPressed,
//   Widget? title,
//   bool? centerTitle,
//   List<Widget>? actions,
//   Color? bgColor,
// }) {
//   onBackPressed = onBackPressed ??
//       () {
//         debugPrint("back pressed");
//         Modular.to.pop();
//         // if (context.canPop()) {
//         //   context.pop();
//         // } else {
//         //   context.pushReplacementNamed(RouteName.welcome);
//         // }
//       };
//   leading = leading ??
//       CommonBackButton(
//         onTap: onBackPressed,
//       );
//   centerTitle = centerTitle ?? true;
//   return AppBar(
//     leadingWidth: 70,
//     leading: leading,
//     title: title,
//     centerTitle: centerTitle,
//     elevation: 0, // default elevation
//     scrolledUnderElevation: 0, //elevation during scroll
//     backgroundColor: bgColor ?? ColorName.primaryBackgroundLight,
//     shadowColor: Colors.white,
//     surfaceTintColor: Colors.white,
//     actions: actions,
//   );
// }

// class CommonBackButton extends StatelessWidget {
//   const CommonBackButton({
//     super.key,
//     required this.onTap,
//     this.color = ColorName.blackLight,
//   });
//   final void Function()? onTap;
//   final Color? color;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Spacer(),
//           Icon(
//             Icons.arrow_back_ios,
//             size: 15,
//             color: color,
//           ),
//           Text(
//             'Back',
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.w700,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// commonAppBar(
//   BuildContext context, {
//   Widget? leading,
//   String? title,
//   Widget? titleWidget,
//   bool? centerTitle,
//   List<Widget>? actions,
//   double? leadingWidth,
//   double? elevation,
//   Color? backgroundColor,
//   PreferredSizeWidget? bottom,
// }) {
//   centerTitle = centerTitle ?? true;
//   return AppBar(
//     leadingWidth: leadingWidth,
//     leading: leading,
//     title: titleWidget ?? Text(title ?? 'AppBar Title'),
//     centerTitle: centerTitle,
//     elevation: elevation, // default elevation
//     scrolledUnderElevation: 0, // elevation during scroll
//     backgroundColor: backgroundColor ?? ColorName.primary, //ColorName.tertiary,
//     shadowColor: Colors.white,
//     foregroundColor: Colors.white,
//     surfaceTintColor: Colors.white,
//     actions: actions,
//     bottom: bottom,
//   );
// }

// class SecondaryAppBar extends StatelessWidget {
//   const SecondaryAppBar({super.key, this.icon, this.heading});
//   final Widget? icon;
//   final String? heading;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 130,
//       padding: const EdgeInsets.only(
//         left: 17,
//         bottom: 16,
//       ),
//       decoration: const BoxDecoration(color: Color(0xFFEFEFEF)),
//       alignment: Alignment.bottomLeft,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // -- Back Button --
//           GestureDetector(
//             // onTap: () => context.pop(),
//             child: const Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Gap(8),
//                 Icon(
//                   Icons.arrow_back_ios,
//                   size: 15,
//                   color: Color(0xFFCC3D10),
//                 ),
//                 Text(
//                   'Back',
//                   style: TextStyle(
//                     color: ColorName.blackLight,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Gap(8),
//           Row(
//             children: [
//               // -- Help Heading --
//               Gap(
//                 21,
//                 child: icon ?? Assets.icons.settingIcon.svg(),
//               ),
//               const Gap(14),
//               Text(
//                 heading ?? "Help",
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 20,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
