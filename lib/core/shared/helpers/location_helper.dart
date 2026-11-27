// core/shared/helpers/location_helper.dart

import 'dart:async';
import 'package:adm_rider/core/config/location_tracking_config.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum LocationResultType {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  error,
}

class LocationResult {
  final LocationResultType type;
  final Position? position;
  final String? message;

  const LocationResult({required this.type, this.position, this.message});

  bool get isSuccess => type == LocationResultType.success && position != null;
}

class LocationHelper {
  LocationHelper._();

  static final LocationHelper instance = LocationHelper._();

  // ============================================================
  // GET CURRENT LOCATION WITH BETTER TIMEOUT HANDLING
  // ============================================================

  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    try {
      // Check location service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return const LocationResult(
          type: LocationResultType.serviceDisabled,
          message: 'Location service is disabled.',
        );
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      // Request permission
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Permission denied
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          type: LocationResultType.permissionDenied,
          message: 'Location permission was denied.',
        );
      }

      // Permanently denied
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          type: LocationResultType.permissionDeniedForever,
          message: 'Location permission is permanently denied.',
        );
      }

      // ============================================================
      // GET POSITION WITH RETRY LOGIC
      // ============================================================

      Position? position;
      int retryCount = 0;
      final maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: accuracy,
              timeLimit: timeout,
              distanceFilter: 0,
            ),
          ).timeout(timeout);

          // If we got a position, break the loop
          // ignore: unnecessary_null_comparison
          if (position != null) {
            break;
          }
        } on TimeoutException {
          retryCount++;
          debugPrint('⏱️ Location timeout attempt $retryCount of $maxRetries');

          if (retryCount >= maxRetries) {
            return const LocationResult(
              type: LocationResultType.timeout,
              message: 'Location request timed out after multiple attempts.',
            );
          }

          // Wait before retrying
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          // If it's not a timeout, break and handle the error
          rethrow;
        }
      }

      if (position == null) {
        return const LocationResult(
          type: LocationResultType.timeout,
          message: 'Unable to get location.',
        );
      }

      // Check if position is valid
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        return const LocationResult(
          type: LocationResultType.error,
          message: 'Invalid location coordinates received.',
        );
      }

      return LocationResult(
        type: LocationResultType.success,
        position: position,
      );
    } on TimeoutException {
      return const LocationResult(
        type: LocationResultType.timeout,
        message: 'Location request timed out. Please try again.',
      );
    } catch (e) {
      return LocationResult(
        type: LocationResultType.error,
        message: e.toString(),
      );
    }
  }

  // ============================================================
  // GET LAST KNOWN LOCATION (Faster, but might be stale)
  // ============================================================

  Future<LocationResult> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();

      if (position != null && position.latitude != 0.0 && position.longitude != 0.0) {
        return LocationResult(
          type: LocationResultType.success,
          position: position,
          message: 'Using last known location',
        );
      }

      return const LocationResult(
        type: LocationResultType.error,
        message: 'No last known location available.',
      );
    } catch (e) {
      return LocationResult(
        type: LocationResultType.error,
        message: e.toString(),
      );
    }
  }

  // ============================================================
  // GET FAST POSITION (Instant cached fix or quick query)
  // ============================================================

  Future<Position?> getFastPosition() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && lastKnown.latitude != 0.0 && lastKnown.longitude != 0.0) {
        return lastKnown;
      }
    } catch (_) {}

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return null;
  }

  // ============================================================
  // GET LOCATION WITH FAST FALLBACK (Checks cached first for instant startup)
  // ============================================================

  Future<LocationResult> getLocationWithFastFallback({
    Duration timeout = LocationTrackingConfig.fastLocationTimeout,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          type: LocationResultType.serviceDisabled,
          message: 'Location service is disabled.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          type: LocationResultType.permissionDenied,
          message: 'Location permission was denied.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          type: LocationResultType.permissionDeniedForever,
          message: 'Location permission is permanently denied.',
        );
      }

      // 1. Try last known location first (typically < 10ms response)
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && lastKnown.latitude != 0.0 && lastKnown.longitude != 0.0) {
          // Trigger background refresh of fresh GPS fix
          unawaited(getCurrentLocation(timeout: timeout, accuracy: accuracy).catchError((_) => const LocationResult(type: LocationResultType.error)));
          return LocationResult(
            type: LocationResultType.success,
            position: lastKnown,
            message: 'Using fast cached location',
          );
        }
      } catch (_) {}

      // 2. Query current position
      return await getCurrentLocation(timeout: timeout, accuracy: accuracy);
    } catch (e) {
      return LocationResult(
        type: LocationResultType.error,
        message: e.toString(),
      );
    }
  }

  // ============================================================
  // GET LOCATION WITH FALLBACK
  // ============================================================

  Future<LocationResult> getLocationWithFallback() async {
    // Check fast fallback first
    return getLocationWithFastFallback();
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }
}
