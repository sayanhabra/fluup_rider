// lib/core/config/location_tracking_config.dart

/// Configuration for Rider GPS Location Tracking & Telemetry.
/// Adjust the timings and distance thresholds here as needed.
class LocationTrackingConfig {
  LocationTrackingConfig._();

  // =========================================================================
  // DISTANCE & MOVEMENT THRESHOLDS
  // =========================================================================

  /// Minimum distance in meters the rider must move to be considered "moved".
  /// If the rider moves less than this distance from the last synced location,
  /// the location is treated as "unchanged" (stationary).
  ///
  /// Default: 30.0 meters.
  static const double minMovementDistanceMeters = 30.0;

  /// Hardware GPS stream distance filter in meters.
  /// The GPS stream fires events whenever the device moves by this amount.
  ///
  /// Default: 5 meters.
  static const int gpsStreamDistanceFilterMeters = 5;

  // =========================================================================
  // UPDATE INTERVALS & TIMINGS
  // =========================================================================

  /// How often the location update API is called when the rider is moving.
  ///
  /// Default: 30 seconds.
  static const Duration movingUpdateInterval = Duration(seconds: 30);

  /// How often the location update API is called when rider location is UNCHANGED (stationary).
  /// If the rider stays in the same place, this heartbeat interval triggers 1 time every 5 minutes.
  ///
  /// Default: 5 minutes.
  static const Duration stationaryUpdateInterval = Duration(minutes: 5);

  /// Internal background check evaluation frequency.
  /// Used by the periodic timer to evaluate whether moving or stationary interval has elapsed.
  ///
  /// Default: 15 seconds.
  static const Duration periodicCheckInterval = Duration(seconds: 15);

  /// Timeout for retrieving fresh satellite GPS coordinates before falling back to cached coordinates.
  ///
  /// Default: 5 seconds.
  static const Duration fastLocationTimeout = Duration(seconds: 5);
}
