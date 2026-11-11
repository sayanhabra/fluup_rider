import 'dart:async';

import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/helpers/google_map_helper.dart';
import 'package:adm_rider/core/shared/helpers/location_helper.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/dashboard/widgets/availability_card.dart';
import 'package:adm_rider/modules/dashboard/widgets/dashboard_header.dart';
import 'package:adm_rider/modules/dashboard/widgets/dashboard_loading_screen.dart';
import 'package:adm_rider/modules/dashboard/widgets/dashboard_map_view.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final LocationHelper _locationHelper = LocationHelper.instance;
  final GoogleMapHelper _mapHelper = GoogleMapHelper.instance;

  bool _isLocationReady = false;
  String? _locationError;
  bool _isAvailable = true;

  // Current location
  LatLng _currentLocation = GoogleMapHelper.defaultCameraPosition.target;

  // Battery tracking
  final Battery _battery = Battery();

  int _batteryLevel = 100;

  StreamSubscription<BatteryState>? _batteryStateSubscription;

  @override
  void initState() {
    super.initState();

    _checkLocationPermission();
    _initBatteryTracking();
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Forces a layout pass for the Map
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isLocationReady) {
        _mapHelper.moveCamera(
          _currentLocation,
          zoom: GoogleMapHelper.defaultZoom,
        );
      }
    });
  }

  // ============================================================
  // BATTERY TRACKING
  // ============================================================

  Future<void> _initBatteryTracking() async {
    try {
      final level = await _battery.batteryLevel;

      if (mounted) {
        setState(() => _batteryLevel = level);
      }

      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
        state,
      ) async {
        try {
          final newLevel = await _battery.batteryLevel;

          if (mounted) {
            setState(() => _batteryLevel = newLevel);
          }
        } catch (e) {
          debugPrint('Battery update error: $e');
        }
      });
    } catch (e) {
      debugPrint('Error reading battery: $e');
    }
  }

  // ============================================================
  // LOCATION PERMISSION AND CURRENT LOCATION
  // ============================================================

  Future<void> _checkLocationPermission() async {
    if (!mounted) return;

    setState(() {
      _isLocationReady = false;
      _locationError = null;
    });

    try {
      final result = await _locationHelper.getLocationWithFallback();

      if (!mounted) return;

      if (result.isSuccess && result.position != null) {
        final position = result.position!;

        final location = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLocation = location;
          _isLocationReady = true;
        });

        // Move camera after Google Map is rendered.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _mapHelper.moveCamera(location, zoom: GoogleMapHelper.defaultZoom);
        });
      } else {
        setState(() {
          _locationError = result.message ?? 'Unable to fetch location.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _locationError = 'Unable to fetch your current location.';
      });

      debugPrint('Location error: $e');
    }
  }

  // ============================================================
  // OPEN APP SETTINGS
  // ============================================================

  Future<void> _openSettings() async {
    await _locationHelper.openAppSettings();

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      _checkLocationPermission();
    }
  }

  // ============================================================
  // RECENTER MAP
  // ============================================================

  Future<void> _recenterMap() async {
    if (!_isLocationReady) {
      await _checkLocationPermission();
      return;
    }

    await _mapHelper.moveCamera(
      _currentLocation,
      zoom: GoogleMapHelper.defaultZoom,
    );
  }

  // ============================================================
  // AVAILABILITY
  // ============================================================

  void _onAvailabilityChanged(bool value) {
    setState(() {
      _isAvailable = value;
    });

    // TODO: Update rider availability through your backend API.
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_locationError != null) {
      return _buildErrorState();
    }

    if (!_isLocationReady) {
      return const DashboardLoadingScreen(
        message: 'Fetching your location... 📍',
      );
    }

    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      // Use Brand.bgApp as base background
      backgroundColor: Brand.bgApp,

      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen map background
          Positioned.fill(
            child: DashboardMapView(currentLocation: _currentLocation),
          ),

          // Header and availability card
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DashboardHeader(
                  userName: currentUser?.name ?? 'Vikash',
                  userId: currentUser?.id.toString() ?? 'RID4587',
                  batteryLevel: _batteryLevel,
                ),
                AvailabilityCard(
                  isAvailable: _isAvailable,
                  onChanged: _onAvailabilityChanged,
                ),
              ],
            ),
          ),

          // Recenter button
          Positioned(
            right: 20,
            bottom: 120,
            child: FloatingActionButton(
              heroTag: 'locate_me',
              backgroundColor: Colors.white,
              elevation: 3,
              onPressed: _recenterMap,
              child: const Icon(Icons.my_location, color: Brand.textDark),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Brand.bgApp,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 80, color: Brand.red),

              const SizedBox(height: 24),

              Text(
                'Location Required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Brand.textDark,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _locationError ?? 'Unable to fetch location.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Brand.subtext),
              ),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Brand.textDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _checkLocationPermission,
                child: Text('Retry', style: TextStyle(color: Brand.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
