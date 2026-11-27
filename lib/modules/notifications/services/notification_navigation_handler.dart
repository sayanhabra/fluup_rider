// lib/modules/notifications/services/notification_navigation_handler.dart

import 'dart:async';
import 'package:adm_rider/core/api/api_service.dart';
import 'package:adm_rider/core/config/app_router.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:adm_rider/modules/notifications/models/notification_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationNavigationHandler {
  NotificationNavigationHandler._();

  /// Handle tap on an in-app notification item (from NotificationScreen)
  static void handleNotificationItemTap(
    BuildContext context,
    NotificationItem notification, {
    WidgetRef? ref,
  }) {
    final type = notification.data?.type.isNotEmpty == true
        ? notification.data!.type
        : notification.type;
    final entityId = notification.data?.entityId ?? '';
    final deepLink = notification.data?.deepLink ?? '';
    final webUrl = notification.data?.webUrl ?? '';
    final event = notification.data?.event ?? '';

    _logNotificationData(
      type: type,
      entityId: entityId,
      deepLink: deepLink,
      webUrl: webUrl,
      event: event,
    );

    // Call mark as read at backend in background if unread
    if (!notification.isRead && notification.id > 0) {
      unawaited(_markAsReadSilently(ApiService(), notification.id));
    }

    _navigate(
      context: context,
      type: type,
      entityId: entityId,
      deepLink: deepLink,
      webUrl: webUrl,
      event: event,
      ref: ref,
    );
  }

  /// Handle tap on push notification payload (from FCM or local notifications)
  static void handleDataTap(
    Map<String, dynamic> data, {
    ApiService? apiService,
    ProviderContainer? container,
  }) {
    final type = data['type']?.toString() ?? '';
    final entityId = data['entityId']?.toString() ?? '';
    final deepLink = data['deepLink']?.toString() ?? '';
    final webUrl = data['webUrl']?.toString() ?? '';
    final event = data['event']?.toString() ?? '';
    final notificationId = data['notificationId']?.toString() ?? data['id']?.toString();

    _logNotificationData(
      type: type,
      entityId: entityId,
      deepLink: deepLink,
      webUrl: webUrl,
      event: event,
    );

    // Call mark as read at backend in background if notification ID exists
    if (notificationId != null && notificationId.isNotEmpty) {
      final notifId = int.tryParse(notificationId);
      if (notifId != null && notifId > 0) {
        final api = apiService ?? ApiService();
        unawaited(_markAsReadSilently(api, notifId));
      }
    }

    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      _navigate(
        context: context,
        type: type,
        entityId: entityId,
        deepLink: deepLink,
        webUrl: webUrl,
        event: event,
        container: container,
      );
    }
  }

  static Future<void> _markAsReadSilently(ApiService api, int id) async {
    try {
      await api.markNotificationAsRead(id);
    } catch (e) {
      debugPrint('⚠️ [NotificationNavigationHandler] Failed to mark as read: $e');
    }
  }

  static void _logNotificationData({
    required String type,
    required String entityId,
    required String deepLink,
    required String webUrl,
    required String event,
  }) {
    debugPrint('🔔 [Notification Click]');
    debugPrint('   data: {');
    debugPrint('     type: \'$type\',');
    debugPrint('     entityId: \'$entityId\',');
    debugPrint('     deepLink: \'$deepLink\',');
    debugPrint('     webUrl: \'$webUrl\',');
    debugPrint('     event: \'$event\',');
    debugPrint('   }');
  }

  static void _navigate({
    required BuildContext context,
    required String type,
    required String entityId,
    required String deepLink,
    required String webUrl,
    required String event,
    WidgetRef? ref,
    ProviderContainer? container,
  }) {
    try {
      final upperType = type.toUpperCase().trim();
      final upperEvent = event.toUpperCase().trim();

      // ─── 1. ORDER & RIDER DISPATCH (OFFER, ASSIGNED, PICKUP, TRANSFER) ─
      if (upperType == 'ORDER' || deepLink.contains('/orders/')) {
        // Sync active state so that order modal / active delivery screen shows
        if (ref != null) {
          ref.read(fulfillmentProvider.notifier).checkAndSyncActiveState();
        } else if (container != null) {
          container.read(fulfillmentProvider.notifier).checkAndSyncActiveState();
        }

        if (upperEvent == 'RIDER_OFFER' || upperEvent == 'OFFER_CANCELLED') {
          // Go to rider home/dashboard where offer modal is automatically presented
          context.go(AppRoutes.dashboard);
          return;
        }

        // Active delivery or trip update
        context.go(AppRoutes.dashboard);
        return;
      }

      // ─── 2. EARNINGS & WALLET ────────────────────────────────────────
      if (upperType == 'EARNINGS' || upperType == 'WALLET') {
        context.push(AppRoutes.riderEarnings);
        return;
      }

      // ─── 3. PROFILE & SETTINGS ───────────────────────────────────────
      if (upperType == 'PROFILE') {
        context.push(AppRoutes.profile);
        return;
      }

      // ─── 4. RIDER STATUS (PAUSED / OFFLINE) ──────────────────────────
      if (upperType == 'RIDER' || deepLink.contains('/rider/status')) {
        context.go(AppRoutes.dashboard);
        return;
      }

      // ─── 5. FALLBACK / UNKNOWN / MISSING ────────────────────────────
      // If any one is missing or unrecognized, go to rider home page (dashboard)
      context.go(AppRoutes.dashboard);
    } catch (e) {
      debugPrint('⚠️ [NotificationNavigationHandler] Error navigating: $e');
      if (context.mounted) {
        context.go(AppRoutes.dashboard);
      }
    }
  }
}
