import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  DeviceInfoService._();
  static final DeviceInfoService instance = DeviceInfoService._();

  static const _deviceIdKey = 'device_id';

  // ─── Device ID (persistent, generated once) ───
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);

    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }

    return id;
  }

  // ─── FCM Token ───
  Future<String?> getFcmToken() async {
    try {
      // iOS requires APNs token first
      if (Platform.isIOS) {
        String? apnsToken;
        for (int i = 0; i < 10; i++) {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(milliseconds: 500));
        }
        if (apnsToken == null) {
          debugPrint('⚠️ APNs token not available yet');
        }
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
      return null;
    }
  }

  // ─── Convenience: fetch both ───
  Future<({String deviceId, String? deviceToken})> getDeviceInfo() async {
    final deviceId = await getDeviceId();
    final deviceToken = await getFcmToken();
    return (deviceId: deviceId, deviceToken: deviceToken);
  }
}
