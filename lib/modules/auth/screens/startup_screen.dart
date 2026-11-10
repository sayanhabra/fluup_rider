// import 'package:adm_rider/core/config/app_router.dart';
// import 'package:adm_rider/core/config/app_theme.dart';
// import 'package:adm_rider/core/shared/styles/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:lottie/lottie.dart';

// class StartupScreen extends StatefulWidget {
//   const StartupScreen({super.key});

//   @override
//   State<StartupScreen> createState() => _StartupScreenState();
// }

// class _StartupScreenState extends State<StartupScreen> {
//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkStartup();
//     });
//   }

//   Future<void> _checkStartup() async {
//     final prefs = await SharedPreferences.getInstance();

//     final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

//     if (!mounted) return;

//     if (onboardingCompleted) {
//       context.go(AppRoutes.login);
//     } else {
//       context.go(AppRoutes.splash);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = context.isDarkMode;

//     return Scaffold(
//       backgroundColor: isDark ? ColorName.primaryBackgroundDark : Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Image.asset('assets/png/logobanner.png', height: 100, width: 100),
//             Lottie.asset(
//               'assets/animation/alcohol.json',
//               height: 200,
//               width: 200,
//             ),

//             // const SizedBox(height: AppStyle.spaceXLarge),
//             // const SizedBox(
//             //   width: 42,
//             //   height: 42,
//             //   child: CircularProgressIndicator(
//             //     strokeWidth: 3,
//             //     color: ColorName.primaryBrandRed,
//             //   ),
//             // ),
//             const SizedBox(height: 20),

//             Text(
//               'Loading...',
//               style: TextStyle(
//                 fontSize: 15,
//                 color: isDark ? Colors.white70 : Colors.black54,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
