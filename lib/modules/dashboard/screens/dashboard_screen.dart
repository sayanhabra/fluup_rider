// modules/dashboard/screens/dashboard_screen.dart

import 'dart:async';
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/helpers/location_helper.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/dashboard/widgets/availability_card.dart';
import 'package:adm_rider/modules/dashboard/widgets/dashboard_header.dart';
import 'package:adm_rider/modules/dashboard/widgets/dashboard_loading_screen.dart';
import 'package:adm_rider/modules/dashboard/widgets/dashboard_map_view.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final LocationHelper _locationHelper = LocationHelper.instance;

  bool _isLocationReady = false;
  String? _locationError;
  bool _isAvailable = true;

  // Dynamic Location State
  LatLng _currentLocation = const LatLng(20.5937, 78.9629);
  final MapController _mapController = MapController();

  // Battery State
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

  Future<void> _initBatteryTracking() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);

      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
        state,
      ) async {
        final newLevel = await _battery.batteryLevel;
        if (mounted) {
          setState(() => _batteryLevel = newLevel);
        }
      });
    } catch (e) {
      debugPrint('Error reading battery: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLocationReady = false;
      _locationError = null;
    });

    final result = await _locationHelper.getLocationWithFallback();

    if (result.isSuccess && result.position != null) {
      setState(() {
        _currentLocation = LatLng(
          result.position!.latitude,
          result.position!.longitude,
        );
        _isLocationReady = true;
      });

      // Move map to current location once ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentLocation, 16.0);
      });
    } else {
      setState(() {
        _locationError = result.message ?? 'Unable to fetch location.';
      });
    }
  }

  Future<void> _openSettings() async {
    await _locationHelper.openAppSettings();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkLocationPermission();
    });
  }

  void _recenterMap() {
    if (_isLocationReady) {
      _mapController.move(_currentLocation, 16.0);
    } else {
      _checkLocationPermission();
    }
  }

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

    return Scaffold(
      backgroundColor: Brand.bgApp,
      body: Stack(
        children: [
          // ─── 1. Full Screen Map ───
          DashboardMapView(
            mapController: _mapController,
            currentLocation: _currentLocation,
          ),

          // ─── 2. Top Header (Red Area & Availability Card) ───
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DashboardHeader(
                  userName: ref.watch(currentUserProvider)?.name ?? 'Vikash',
                  userId:
                      ref.watch(currentUserProvider)?.id.toString() ??
                      'RID4587',
                  batteryLevel: _batteryLevel, // Pass battery level here
                ),
                AvailabilityCard(
                  isAvailable: _isAvailable,
                  onChanged: (val) {
                    setState(() => _isAvailable = val);
                  },
                ),
              ],
            ),
          ),

          // ─── 3. Floating Action Button (Locate Me) ───
          Positioned(
            right: 20,
            bottom: 100, // Adjusted to fit better on screen
            child: FloatingActionButton(
              heroTag: 'locate_me',
              backgroundColor: Colors.white,
              elevation: 2,
              onPressed: _recenterMap,
              child: const Icon(Icons.my_location, color: Brand.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
              _locationError!,
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
    );
  }
}
