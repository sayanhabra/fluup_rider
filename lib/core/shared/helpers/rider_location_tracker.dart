import 'dart:async';
import 'package:adm_rider/core/api/api_service.dart';
import 'package:adm_rider/core/config/location_tracking_config.dart';
import 'package:adm_rider/core/shared/helpers/location_helper.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Live coordinate notifier updated by [RiderLocationTracker] in real-time.
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

/// Service that updates the rider's telemetry GPS coordinates to
/// PATCH /api/v1/rider/order-fulfillment/location while the rider is online:
/// - If rider is moving: updates every 30s (or immediately on >= 30m movement).
/// - If rider location is unchanged (stationary): updates 1 time in every 5 minutes.
/// All timings and distance thresholds are read from [LocationTrackingConfig].
///
/// If the rider is logged out or offline, this service will NOT call the API.
class RiderLocationTracker {
  final Ref _ref;
  final LocationHelper _locationHelper = LocationHelper.instance;
  final Battery _battery = Battery();

  Timer? _timer;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isRunning = false;
  bool _isSyncing = false;
  bool get isRunning => _isRunning;

  LatLng? _lastKnownLocation;
  LatLng? get lastKnownLocation => _lastKnownLocation;

  LatLng? _lastSyncedLocation;
  LatLng? get lastSyncedLocation => _lastSyncedLocation;

  DateTime? _lastSyncedTime;
  DateTime? get lastSyncedTime => _lastSyncedTime;

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
    debugPrint(
      '🛰️ [RiderLocationTracker] Rider is online. Starting tracking '
      '(Moving: ${LocationTrackingConfig.movingUpdateInterval.inSeconds}s / >=${LocationTrackingConfig.minMovementDistanceMeters}m, '
      'Unchanged: ${LocationTrackingConfig.stationaryUpdateInterval.inMinutes}m).',
    );

    // Immediate initial sync
    _sendLocationUpdate();

    // Periodic evaluation timer to handle 30s moving and 5m unchanged intervals
    _timer?.cancel();
    _timer = Timer.periodic(LocationTrackingConfig.periodicCheckInterval, (_) {
      _evaluatePeriodicUpdate();
    });

    // Distance-based sync: check if rider moved >= minMovementDistanceMeters
    _startPositionStream();
  }

  void stop() {
    if (!_isRunning && _timer == null && _positionStreamSubscription == null) return;
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _lastSyncedLocation = null;
    _lastSyncedTime = null;
    debugPrint('🛑 [RiderLocationTracker] Stopped GPS tracking.');
  }

  void _startPositionStream() {
    _positionStreamSubscription?.cancel();
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: LocationTrackingConfig.gpsStreamDistanceFilterMeters,
      );
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          _onPositionReceived(position);
        },
        onError: (e) {
          debugPrint('⚠️ [RiderLocationTracker] Error in position stream: $e');
        },
      );
    } catch (e) {
      debugPrint('⚠️ [RiderLocationTracker] Could not start position stream: $e');
    }
  }

  void _onPositionReceived(Position pos) {
    if (!_isRunning) return;
    final newLatLng = LatLng(pos.latitude, pos.longitude);
    _lastKnownLocation = newLatLng;

    // Immediately update live provider for smooth marker updates in UI
    _ref.read(riderLiveLocationProvider.notifier).updateLocation(newLatLng);

    // Initial sync if not yet synced
    if (_lastSyncedLocation == null || _lastSyncedTime == null) {
      _sendLocationUpdate(explicitPosition: pos);
      return;
    }

    // Distance calculation: check if rider moved at least minMovementDistanceMeters from last synced coordinate
    final distanceMeters = Geolocator.distanceBetween(
      _lastSyncedLocation!.latitude,
      _lastSyncedLocation!.longitude,
      pos.latitude,
      pos.longitude,
    );

    if (distanceMeters >= LocationTrackingConfig.minMovementDistanceMeters) {
      debugPrint(
        '🚴 [RiderLocationTracker] Rider moved ${distanceMeters.toStringAsFixed(1)}m (>= ${LocationTrackingConfig.minMovementDistanceMeters}m). Triggering location update.',
      );
      _sendLocationUpdate(explicitPosition: pos);
    }
  }

  Future<void> _evaluatePeriodicUpdate() async {
    if (!_isRunning || _isSyncing) return;

    Position? pos;
    final locResult = await _locationHelper.getLocationWithFastFallback();
    if (locResult.isSuccess && locResult.position != null) {
      pos = locResult.position;
    }

    if (pos == null) return;

    final currentLatLng = LatLng(pos.latitude, pos.longitude);
    _lastKnownLocation = currentLatLng;
    _ref.read(riderLiveLocationProvider.notifier).updateLocation(currentLatLng);

    // If never synced yet, perform initial sync
    if (_lastSyncedLocation == null || _lastSyncedTime == null) {
      await _sendLocationUpdate(explicitPosition: pos);
      return;
    }

    final distanceMoved = Geolocator.distanceBetween(
      _lastSyncedLocation!.latitude,
      _lastSyncedLocation!.longitude,
      pos.latitude,
      pos.longitude,
    );

    final isLocationChanged = distanceMoved >= LocationTrackingConfig.minMovementDistanceMeters;
    final timeSinceLastSync = DateTime.now().difference(_lastSyncedTime!);

    if (isLocationChanged) {
      // Rider has moved >= minMovementDistanceMeters:
      // If movingUpdateInterval (30s) has passed, sync to API
      if (timeSinceLastSync >= LocationTrackingConfig.movingUpdateInterval) {
        debugPrint(
          '🚴 [RiderLocationTracker] Rider is moving (moved ${distanceMoved.toStringAsFixed(1)}m >= ${LocationTrackingConfig.minMovementDistanceMeters}m). Calling location API.',
        );
        await _sendLocationUpdate(explicitPosition: pos);
      }
    } else {
      // Rider location is UNCHANGED (stationary / < minMovementDistanceMeters):
      // Only call location update API 1 time in every 5 min (stationaryUpdateInterval)
      if (timeSinceLastSync >= LocationTrackingConfig.stationaryUpdateInterval) {
        debugPrint(
          '⏱️ [RiderLocationTracker] Location unchanged for ${timeSinceLastSync.inMinutes}m (>= ${LocationTrackingConfig.stationaryUpdateInterval.inMinutes}m). Calling location API heartbeat.',
        );
        await _sendLocationUpdate(explicitPosition: pos);
      }
    }
  }

  Future<void> _sendLocationUpdate({Position? explicitPosition}) async {
    // 1. Guard: must still be running and not already syncing
    if (!_isRunning || _isSyncing) return;

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

    _isSyncing = true;
    try {
      Position? pos = explicitPosition;
      if (pos == null) {
        final locResult = await _locationHelper.getLocationWithFastFallback();
        if (locResult.isSuccess && locResult.position != null) {
          pos = locResult.position!;
        }
      }

      if (pos == null) {
        debugPrint('⚠️ [RiderLocationTracker] Unable to retrieve GPS position.');
        return;
      }

      final newLatLng = LatLng(pos.latitude, pos.longitude);
      _lastKnownLocation = newLatLng;
      _lastSyncedLocation = newLatLng;
      _lastSyncedTime = DateTime.now();

      // Update provider so listening UI (e.g. Dashboard, Active Delivery) moves the rider marker
      _ref.read(riderLiveLocationProvider.notifier).updateLocation(newLatLng);

      int? batteryLevel;
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (_) {}

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
    } finally {
      _isSyncing = false;
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
