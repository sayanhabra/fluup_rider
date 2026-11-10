import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Needed because background handler runs in a separate isolate.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  debugPrint('Background message: ${message.messageId}');
}

class FirebaseHelper {
  FirebaseHelper._();

  static final FirebaseHelper instance = FirebaseHelper._();

  // ============================================================
  // FIREBASE SERVICES
  // ============================================================

  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  FirebaseRemoteConfig get remoteConfig => FirebaseRemoteConfig.instance;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize({FirebaseOptions? options}) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }

      await _initializeCrashlytics();

      debugPrint('Firebase initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Firebase initialization failed: $e');

      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }
  }

  // ============================================================
  // CRASHLYTICS
  // ============================================================

  Future<void> _initializeCrashlytics() async {
    // Catch Flutter framework errors.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);

      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Catch asynchronous errors outside
    // Flutter framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);

      return true;
    };
  }

  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    await crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      reason: reason,
    );
  }

  Future<void> logCrashlytics(String message) async {
    await crashlytics.log(message);
  }

  Future<void> setCrashlyticsUserId(String userId) async {
    await crashlytics.setUserIdentifier(userId);
  }

  Future<void> setCrashlyticsKey(String key, Object value) async {
    await crashlytics.setCustomKey(key, value);
  }

  Future<void> enableCrashlytics(bool enabled) async {
    await crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  Future<void> testCrash() async {
    crashlytics.crash();
  }

  // ============================================================
  // FIREBASE ANALYTICS
  // ============================================================

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  Future<void> logLogin({String? loginMethod}) async {
    await analytics.logLogin(loginMethod: loginMethod ?? 'unknown');
  }

  Future<void> logSignUp({String? signUpMethod}) async {
    await analytics.logSignUp(signUpMethod: signUpMethod ?? 'unknown');
  }

  Future<void> setAnalyticsUserId({String? userId}) async {
    await analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await analytics.setUserProperty(name: name, value: value);
  }

  Future<void> resetAnalyticsData() async {
    await analytics.resetAnalyticsData();
  }

  // ============================================================
  // FIREBASE CLOUD MESSAGING
  // ============================================================

  Future<NotificationSettings> requestNotificationPermission() async {
    return messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
  }

  // ============================================================
  // FCM TOKEN
  // ============================================================

  Future<String?> getFCMToken() async {
    try {
      return await messaging.getToken();
    } catch (e, stackTrace) {
      await recordError(e, stackTrace, reason: 'Failed to get FCM token');

      return null;
    }
  }

  Future<void> deleteFCMToken() async {
    await messaging.deleteToken();
  }

  Stream<String> get onTokenRefresh {
    return messaging.onTokenRefresh;
  }

  // ============================================================
  // FCM TOPICS
  // ============================================================

  Future<void> subscribeToTopic(String topic) async {
    await messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await messaging.unsubscribeFromTopic(topic);
  }

  // ============================================================
  // FOREGROUND MESSAGE
  // ============================================================

  StreamSubscription<RemoteMessage> listenToForegroundMessages(
    void Function(RemoteMessage message) onMessage,
  ) {
    return FirebaseMessaging.onMessage.listen(onMessage);
  }

  // ============================================================
  // NOTIFICATION CLICK
  // ============================================================

  StreamSubscription<RemoteMessage> listenToNotificationTap(
    void Function(RemoteMessage message) onTap,
  ) {
    return FirebaseMessaging.onMessageOpenedApp.listen(onTap);
  }

  // ============================================================
  // TERMINATED STATE NOTIFICATION
  // ============================================================

  Future<RemoteMessage?> getInitialNotification() async {
    return messaging.getInitialMessage();
  }

  // ============================================================
  // NOTIFICATION DATA HELPERS
  // ============================================================

  String? getNotificationTitle(RemoteMessage message) {
    return message.notification?.title;
  }

  String? getNotificationBody(RemoteMessage message) {
    return message.notification?.body;
  }

  Map<String, dynamic> getNotificationData(RemoteMessage message) {
    return message.data;
  }

  // ============================================================
  // REMOTE CONFIG
  // ============================================================

  Future<void> initializeRemoteConfig({
    Duration fetchTimeout = const Duration(minutes: 1),
    Duration minimumFetchInterval = const Duration(hours: 1),
    Map<String, dynamic>? defaults,
  }) async {
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: minimumFetchInterval,
      ),
    );

    if (defaults != null) {
      await remoteConfig.setDefaults(defaults);
    }

    await remoteConfig.fetchAndActivate();
  }

  Future<bool> fetchAndActivateRemoteConfig() {
    return remoteConfig.fetchAndActivate();
  }

  String getRemoteString(String key) {
    return remoteConfig.getString(key);
  }

  bool getRemoteBool(String key) {
    return remoteConfig.getBool(key);
  }

  int getRemoteInt(String key) {
    return remoteConfig.getInt(key);
  }

  double getRemoteDouble(String key) {
    return remoteConfig.getDouble(key);
  }

  RemoteConfigValue getRemoteValue(String key) {
    return remoteConfig.getValue(key);
  }

  Map<String, RemoteConfigValue> getAllRemoteConfig() {
    return remoteConfig.getAll();
  }

  // ============================================================
  // USER SETUP
  //
  // Call after successful login.
  // ============================================================

  Future<void> setUser({
    required String userId,
    Map<String, String?> properties = const {},
  }) async {
    await Future.wait([setAnalyticsUserId(), setCrashlyticsUserId(userId)]);

    for (final entry in properties.entries) {
      await setUserProperty(name: entry.key, value: entry.value);
    }
  }

  // ============================================================
  // LOGOUT CLEANUP
  // ============================================================

  Future<void> clearUser() async {
    await Future.wait([setAnalyticsUserId(), setCrashlyticsUserId('')]);
  }
}



// later add============================
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await FirebaseHelper.instance.initialize(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   FirebaseMessaging.onBackgroundMessage(
//     firebaseMessagingBackgroundHandler,
//   );