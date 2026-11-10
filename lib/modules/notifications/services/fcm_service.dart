import 'dart:io';
import 'package:adm_rider/firebase_options.dart';
import 'package:adm_rider/modules/notifications/services/local_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('🔔 Background FCM message received: ${message.messageId}');

  debugPrint('Title: ${message.notification?.title}');

  debugPrint('Body: ${message.notification?.body}');

  debugPrint('Data: ${message.data}');

  // Later we can process data here if required.
}

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. iOS: wait until APNs token is available
    if (Platform.isIOS) {
      String? apnsToken;

      for (int i = 0; i < 10; i++) {
        apnsToken = await _messaging.getAPNSToken();

        if (apnsToken != null) {
          break;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      debugPrint('APNs token: $apnsToken');
    }

    // 3. Get FCM token
    try {
      final fcmToken = await _messaging.getToken();
      debugPrint('FCM TOKEN: $fcmToken');
    } catch (e) {
      debugPrint('FCM getToken error: $e');
    }

    // TODO:
    // Send this token to your Fluup backend
    // after the user logs in.

    // 4. Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM TOKEN REFRESHED: $newToken');

      // TODO:
      // Send updated token to your backend
    });

    // 5. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM foreground message received');

      final title = message.notification?.title;
      final body = message.notification?.body;

      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Data: ${message.data}');

      if (title != null || body != null) {
        await LocalNotificationService.instance.showNotification(
          title: title ?? 'Fluup',
          body: body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // 6. User taps notification while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened: ${message.data}');

      _handleNotificationTap(message);
    });

    // 7. User taps notification when app was terminated
    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint(
        'App opened from notification: '
        '${initialMessage.data}',
      );

      _handleNotificationTap(initialMessage);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    debugPrint('Notification data: $data');

    // Later we will navigate using your GoRouter.
    //
    // Example:
    //
    // if (data['type'] == 'order') {
    //   final orderId = data['orderId'];
    //
    //   appRouter.go(
    //     '/order/$orderId',
    //   );
    // }
  }
}
