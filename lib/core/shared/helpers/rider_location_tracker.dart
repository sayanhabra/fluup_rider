import 'dart:async';
import 'package:adm_rider/core/api/api_service.dart';
import 'package:adm_rider/core/shared/helpers/location_helper.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Live coordinate notifier updated by [RiderLocationTracker] on every 30-second cycle.
/// Map markers and camera listening to this provider will automatically move.
class RiderLiveLocationNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  void updateLocation(LatLng location) {
    state = location;
  }

  void reset() {
    state = null;
  }
}

final riderLiveLocationProvider =
    NotifierProvider<RiderLiveLocationNotifier, LatLng?>(
  RiderLiveLocationNotifier.new,
);

/// Service that updates the rider's telemetry GPS coordinates every 30 seconds
/// to PATCH /api/v1/rider/order-fulfillment/location while the rider is online.
///
/// If the rider is logged out or offline, this service will NOT call the API.
class RiderLocationTracker {
  final Ref _ref;
  final LocationHelper _locationHelper = LocationHelper.instance;
  final Battery _battery = Battery();

  Timer? _timer;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  LatLng? _lastKnownLocation;
  LatLng? get lastKnownLocation => _lastKnownLocation;

  RiderLocationTracker(this._ref);

  void start() {
    // 1. Guard: rider must be authenticated
    final isAuth = _ref.read(isAuthenticatedProvider);
    if (!isAuth) {
      debugPrint('🛑 [RiderLocationTracker] Cannot start tracking: Rider is not logged in.');
      stop();
      return;
    }

    // 2. Guard: rider must be explicitly online
    final isOnline = _ref.read(fulfillmentProvider).isOnline;
    if (!isOnline) {
      debugPrint('⏸️ [RiderLocationTracker] Cannot start tracking: Rider is offline.');
      stop();
      return;
    }

    if (_isRunning) return;
    _isRunning = true;
    debugPrint('🛰️ [RiderLocationTracker] Rider is online. Starting 30-second periodic GPS updates.');

    // Immediate initial sync
    _sendLocationUpdate();

    // Periodic sync every 30 seconds
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendLocationUpdate();
    });
  }

  void stop() {
    if (!_isRunning && _timer == null) return;
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    debugPrint('🛑 [RiderLocationTracker] Stopped periodic GPS updates.');
  }

  Future<void> _sendLocationUpdate() async {
    // 1. Guard: must still be running
    if (!_isRunning) return;

    // 2. Guard: if rider is logged out, stop immediately and do NOT call location API
    final isAuth = _ref.read(isAuthenticatedProvider);
    if (!isAuth) {
      debugPrint('🛑 [RiderLocationTracker] Rider is logged out. Aborting location telemetry.');
      stop();
      return;
    }

    // 3. Guard: if rider is offline, stop immediately and do NOT call location API
    final isOnline = _ref.read(fulfillmentProvider).isOnline;
    if (!isOnline) {
      debugPrint('⏸️ [RiderLocationTracker] Rider is offline. Aborting location telemetry.');
      stop();
      return;
    }

    try {
      final locResult = await _locationHelper.getLocationWithFallback();
      if (!locResult.isSuccess || locResult.position == null) {
        debugPrint('⚠️ [RiderLocationTracker] Unable to retrieve GPS position.');
        return;
      }

      int? batteryLevel;
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (_) {}

      final pos = locResult.position!;
      final newLatLng = LatLng(pos.latitude, pos.longitude);
      _lastKnownLocation = newLatLng;

      // Update provider so listening UI (e.g. Dashboard, Active Delivery) moves the rider marker
      _ref.read(riderLiveLocationProvider.notifier).updateLocation(newLatLng);

      final apiService = _ref.read(apiServiceProvider);
      await apiService.updateRiderLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        batteryLevel: batteryLevel,
      );
      debugPrint(
        '📍 [RiderLocationTracker] Synced location: (${pos.latitude}, ${pos.longitude}), battery: $batteryLevel%',
      );

      // Periodically sync single source of truth active ride state (IDLE, ACTIVE_OFFER, ACTIVE_DELIVERY)
      await _ref.read(fulfillmentProvider.notifier).checkAndSyncActiveState();
    } catch (e) {
      debugPrint('⚠️ [RiderLocationTracker] Error updating location telemetry: $e');
    }
  }

  void dispose() {
    stop();
  }
}

final riderLocationTrackerProvider = Provider<RiderLocationTracker>((ref) {
  final tracker = RiderLocationTracker(ref);

  // Auto-listen to auth state: if rider logs out, immediately stop location tracking
  ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
    if (!next) {
      tracker.stop();
    }
  });

  ref.onDispose(() => tracker.dispose());
  return tracker;
});
