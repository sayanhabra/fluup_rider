import 'dart:convert';
import 'dart:io';
import 'package:adm_rider/core/config/app_router.dart';
import 'package:adm_rider/core/shared/helpers/notification_sound_helper.dart';
import 'package:adm_rider/firebase_options.dart';
import 'package:adm_rider/modules/fulfillment/models/delivery_order.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:adm_rider/modules/fulfillment/screens/new_order_request_modal.dart';
import 'package:adm_rider/modules/notifications/services/local_notification_service.dart';
import 'package:adm_rider/modules/notifications/services/notification_navigation_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('🔔 Background FCM message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  FirebaseMessaging? _messagingInstance;
  FirebaseMessaging get _messaging => _messagingInstance ??= FirebaseMessaging.instance;

  int? _activeModalOrderId;

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

    // 4. Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM TOKEN REFRESHED: $newToken');
    });

    // 5. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM foreground message received');

      final title = message.notification?.title;
      final body = message.notification?.body;

      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Data: ${message.data}');

      // Process event payload (e.g. RIDER_OFFER, play sound, open modal)
      await handleNotificationPayload(message.data);

      if (title != null || body != null) {
        await LocalNotificationService.instance.showNotification(
          title: title ?? 'Fluup',
          body: body ?? '',
          payload: jsonEncode(message.data),
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
      debugPrint('App opened from notification: ${initialMessage.data}');
      _handleNotificationTap(initialMessage);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    if (data.isNotEmpty) {
      final event = data['event']?.toString().toUpperCase();
      final type = data['type']?.toString().toUpperCase();
      if (event == 'RIDER_OFFER' || type == 'RIDER_OFFER') {
        handleNotificationPayload(data);
      }
      NotificationNavigationHandler.handleDataTap(data);
    }
  }

  /// Processes notification data payload.
  /// When event == "RIDER_OFFER":
  /// 1. Plays sound from data['sound']
  /// 2. Parses DeliveryOrder
  /// 3. Shows NewOrderRequestModal
  Future<void> handleNotificationPayload(Map<String, dynamic> data) async {
    debugPrint('🔔 [FcmService] Handling payload: $data');

    final event = data['event']?.toString().toUpperCase();
    final type = data['type']?.toString().toUpperCase();

    if (event == 'RIDER_OFFER' || type == 'RIDER_OFFER') {
      final sound = data['sound']?.toString() ??
          data['soundlink']?.toString() ??
          data['sound_link']?.toString() ??
          data['audio']?.toString();

      // 1. Play sound
      if (sound != null && sound.isNotEmpty) {
        await NotificationSoundHelper.instance.play(sound);
      }

      // 2. Parse delivery order from notification data
      final order = DeliveryOrder.fromNotificationData(data);

      // 3. Show Accept / Reject screen
      showOfferModal(order);
    }
  }

  /// Helper to display NewOrderRequestModal over the current top screen
  void showOfferModal(DeliveryOrder order) {
    if (_activeModalOrderId == order.orderId) {
      debugPrint('⚠️ [FcmService] Offer modal already active for order #${order.orderId}');
      return;
    }

    void present() {
      final context = rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_activeModalOrderId != order.orderId) {
            present();
          }
        });
        return;
      }

      _activeModalOrderId = order.orderId;

      try {
        final container = ProviderScope.containerOf(context, listen: false);
        container.read(fulfillmentProvider.notifier).setIncomingOffer(order);
      } catch (e) {
        debugPrint('Provider container sync notice: $e');
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NewOrderRequestModal(
            order: order,
          ),
        ),
      ).then((_) {
        if (_activeModalOrderId == order.orderId) {
          _activeModalOrderId = null;
        }
      });
    }

    present();
  }
}
