import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class AppPermissionHelper {
  AppPermissionHelper._();

  static bool _hasRequested = false;

  /// Requests notification and location permissions in a batch request.
  static Future<void> requestInitialPermissions() async {
    if (_hasRequested) return;
    _hasRequested = true;

    try {
      debugPrint('🛡️ Requesting notification and location permissions...');

      // Sync settings with Firebase Messaging
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: false,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
        );
        debugPrint('🔔 Notification permission requested');
      } catch (e) {
        debugPrint('FCM requestPermission error: $e');
      }

      // Location permission check and request
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          final res = await Geolocator.requestPermission();
          debugPrint('📍 Location permission result: $res');
        } else {
          debugPrint('📍 Location permission status: $permission');
        }
      } catch (e) {
        debugPrint('Geolocator requestPermission error: $e');
      }
    } catch (e) {
      debugPrint('⚠️ Error requesting permissions: $e');
    }
  }
}

