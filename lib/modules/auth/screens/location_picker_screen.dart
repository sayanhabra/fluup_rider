import 'dart:async';

import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;

  final String address;
  final String addressLine1;
  final String city;
  final String state;
  final String pincode;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;

  LatLng? _selectedLocation;

  String _selectedAddress = 'Getting location...';

  String _addressLine1 = '';
  String _city = '';
  String _state = '';
  String _pincode = '';

  bool _isLoadingLocation = true;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  final Geocoding _geocoding = Geocoding();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // INITIAL LOCATION
  // ============================================================

  Future<void> _initializeLocation() async {
    try {
      // If existing location is available, use it first.
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        final location = LatLng(
          widget.initialLatitude!,
          widget.initialLongitude!,
        );

        setState(() {
          _selectedLocation = location;
          _isLoadingLocation = false;
        });

        await _getAddress(location);
        return;
      }

      // Otherwise get current device location.
      final hasPermission = await _checkLocationPermission();

      if (!hasPermission) {
        setState(() {
          _isLoadingLocation = false;
          _selectedAddress = 'Location permission is required';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = location;
        _isLoadingLocation = false;
      });

      await _getAddress(location);
    } catch (e) {
      debugPrint('Location error: $e');

      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _selectedAddress = 'Unable to get current location';
        });
      }
    }
  }

  // ============================================================
  // LOCATION PERMISSION
  // ============================================================

  Future<bool> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        await _showLocationServiceDialog();
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> _showLocationServiceDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Location is disabled'),
          content: const Text(
            'Please enable location services to select your current location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openLocationSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MAP CREATED
  // ============================================================

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_selectedLocation != null) {
      _moveCamera(_selectedLocation!);
    }
  }

  // ============================================================
  // MAP CAMERA MOVED
  // ============================================================

  Future<void> _onCameraIdle() async {
    if (_mapController == null) return;

    final bounds = await _mapController!.getVisibleRegion();

    final center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    setState(() {
      _selectedLocation = center;
    });

    await _getAddress(center);
  }

  // ============================================================
  // MOVE CAMERA
  // ============================================================

  Future<void> _moveCamera(LatLng location) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 17),
      ),
    );
  }

  // ============================================================
  // GET ADDRESS
  // ============================================================

  Future<void> _getAddress(LatLng location) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) return;

      final place = placemarks.first;

      final name = place.name?.trim() ?? '';
      final street = place.street?.trim() ?? '';

      final addressLine1 = [
        if (name.isNotEmpty) name,
        if (street.isNotEmpty && street != name) street,
      ].join(', ');

      final city = place.locality?.trim().isNotEmpty == true
          ? place.locality!.trim()
          : place.subAdministrativeArea?.trim() ?? '';

      final state = place.administrativeArea?.trim() ?? '';

      final pincode = place.postalCode?.trim() ?? '';

      final fullAddress = [
        if (addressLine1.isNotEmpty) addressLine1,
        if (city.isNotEmpty) city,
        if (state.isNotEmpty) state,
        if (pincode.isNotEmpty) pincode,
      ].join(', ');

      if (!mounted) return;

      setState(() {
        _selectedAddress = fullAddress;

        _addressLine1 = addressLine1;
        _city = city;
        _state = state;
        _pincode = pincode;
      });

      debugPrint('========== SELECTED LOCATION ==========');
      debugPrint('Latitude: ${location.latitude}');
      debugPrint('Longitude: ${location.longitude}');
      debugPrint('Address: $addressLine1');
      debugPrint('City: $city');
      debugPrint('State: $state');
      debugPrint('Pincode: $pincode');
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
  }

  // ============================================================
  // CURRENT LOCATION BUTTON
  // ============================================================

  Future<void> _goToCurrentLocation() async {
    final hasPermission = await _checkLocationPermission();

    if (!hasPermission) return;

    try {
      setState(() {
        _isLoadingLocation = true;
      });

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = location;
        _isLoadingLocation = false;
      });

      await _moveCamera(location);
      await _getAddress(location);
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    if (value.trim().isEmpty) return;

    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      _searchLocation(value.trim());
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      setState(() {
        _isSearching = true;
      });

      final locations = await _geocoding.locationFromAddress(query);

      if (locations.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Location not found')));
        }
        return;
      }

      final location = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );

      setState(() {
        _selectedLocation = location;
      });

      await _moveCamera(location);
      await _getAddress(location);
    } catch (e) {
      debugPrint('Search error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to find this location')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // ============================================================
  // CONFIRM LOCATION
  // ============================================================

  void _confirmLocation() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a location')));
      return;
    }

    Navigator.pop(
      context,
      LocationPickerResult(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        address: _selectedAddress,
        addressLine1: _addressLine1,
        city: _city,
        state: _state,
        pincode: _pincode,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final initialLocation = _selectedLocation ?? const LatLng(22.5726, 88.3639);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Location'), centerTitle: true),
      body: Stack(
        children: [
          // ======================================================
          // MAP
          // ======================================================
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialLocation,
              zoom: 15,
            ),
            onMapCreated: _onMapCreated,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // ======================================================
          // SEARCH BAR
          // ======================================================
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(14),
              color: surfaceColor,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: _searchLocation,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search location',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // ======================================================
          // CENTER MARKER
          // ======================================================
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_pin,
                size: 50,
                color: ColorName.primaryBrandRed,
              ),
            ),
          ),

          // ======================================================
          // SELECTED ADDRESS
          // ======================================================
          Positioned(
            left: 16,
            right: 16,
            bottom: 95,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black38
                        : Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: ColorName.primaryBrandRed,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedAddress,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // CURRENT LOCATION BUTTON
          // ======================================================
          Positioned(
            right: 16,
            bottom: 175,
            child: FloatingActionButton(
              heroTag: 'current_location',
              backgroundColor: surfaceColor,
              foregroundColor: ColorName.primaryBrandRed,
              onPressed: _goToCurrentLocation,
              child: _isLoadingLocation
                  ? CircularProgressIndicator(color: Brand.red)
                  // ? Lottie.asset(
                  //     'assets/animation/alcohol.json',
                  //     height: 200,
                  //     width: 200,
                  //   )
                  : const Icon(Icons.my_location),
            ),
          ),

          // ======================================================
          // CONFIRM BUTTON
          // ======================================================
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorName.primaryBrandRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
