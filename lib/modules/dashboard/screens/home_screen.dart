import 'package:adm_rider/core/config/app_theme.dart';
import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:adm_rider/core/shared/helpers/location_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final LocationHelper _locationHelper = LocationHelper.instance;

  Position? _position;
  bool _isLoading = true;
  String? _errorMessage;
  String? _locationSource;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    if (mounted) {
      _getCurrentLocation();
    }
  }

  // ============================================================
  // GET CURRENT LOCATION WITH FALLBACK
  // ============================================================

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _locationSource = null;
    });

    // Use the new method with fallback
    final result = await _locationHelper.getLocationWithFallback();

    if (!mounted) return;

    switch (result.type) {
      case LocationResultType.success:
        setState(() {
          _position = result.position;
          _isLoading = false;
          _locationSource = result.message ?? 'GPS';
          _retryCount = 0;
        });
        debugPrint(
          '✅ Location obtained: ${_position?.latitude}, ${_position?.longitude}',
        );
        debugPrint('📍 Source: $_locationSource');
        break;

      case LocationResultType.serviceDisabled:
        setState(() {
          _errorMessage =
              'Location service is disabled. Please enable it in settings.';
          _isLoading = false;
        });
        break;

      case LocationResultType.permissionDenied:
        setState(() {
          _errorMessage =
              'Location permission was denied. Please grant permission to continue.';
          _isLoading = false;
        });
        break;

      case LocationResultType.permissionDeniedForever:
        setState(() {
          _errorMessage =
              'Location permission is permanently denied. Please enable it from app settings.';
          _isLoading = false;
        });
        break;

      case LocationResultType.timeout:
        setState(() {
          _errorMessage =
              'Location request timed out. Please make sure GPS is enabled and you are in an open area.';
          _isLoading = false;
        });
        break;

      case LocationResultType.error:
        setState(() {
          _errorMessage =
              result.message ?? 'Unable to get your current location.';
          _isLoading = false;
        });
        break;
    }
  }

  // ============================================================
  // OPEN SETTINGS
  // ============================================================

  // Future<void> _openSettings() async {
  //   await _locationHelper.openAppSettings();
  //   // Check again after returning from settings
  //   Future.delayed(const Duration(milliseconds: 500), () {
  //     if (mounted) {
  //       _getCurrentLocation();
  //     }
  //   });
  // }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: isDark ? ColorName.surfaceDark : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _getCurrentLocation,
        child: Center(
          child: Text(
            "Home",
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }
}
