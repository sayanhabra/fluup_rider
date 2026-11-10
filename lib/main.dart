import 'package:adm_rider/core/config/app_router.dart';
import 'package:adm_rider/core/config/app_theme.dart';
import 'package:adm_rider/firebase_options.dart';
import 'package:adm_rider/modules/notifications/services/fcm_service.dart';
import 'package:adm_rider/modules/notifications/services/local_notification_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp error: $e');
  }

  try {
    await FcmService.instance.initialize();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('FcmService initialize error: $e');
  }

  try {
    await LocalNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('LocalNotificationService initialize error: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optional: Set initial user type for testing
    // ref.read(userTypeProvider.notifier).state = USER_TYPE_USER;
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // GoRouter
      routerConfig: router, // Use the appRouter from app_router.dart
      // BotToast
      builder: (context, child) {
        return BotToastInit()(context, child);
      },
    );
  }
}
