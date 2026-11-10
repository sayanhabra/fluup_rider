// core/shared/helpers/location_helper.dart

import 'dart:async';
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

      if (position != null) {
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
  // GET LOCATION WITH FALLBACK
  // ============================================================

  Future<LocationResult> getLocationWithFallback() async {
    // First try to get current location
    final result = await getCurrentLocation();

    if (result.isSuccess) {
      return result;
    }

    // If failed, try last known location
    debugPrint('🔄 Falling back to last known location');
    final lastKnown = await getLastKnownLocation();

    if (lastKnown.isSuccess) {
      return LocationResult(
        type: LocationResultType.success,
        position: lastKnown.position,
        message: 'Using last known location (current location unavailable)',
      );
    }

    // If both fail, return the original error
    return result;
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
