import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;

class GoogleMapHelper {
  GoogleMapHelper._();

  static final GoogleMapHelper instance = GoogleMapHelper._();

  final geo.Geocoding _geocoding = geo.Geocoding();

  GoogleMapController? _mapController;

  GoogleMapController? get mapController => _mapController;

  // ============================================================
  // DEFAULT VALUES
  // ============================================================

  static const double defaultZoom = 16;

  static const CameraPosition defaultCameraPosition = CameraPosition(
    target: LatLng(22.5726, 88.3639),
    zoom: 12,
  );

  // ============================================================
  // SET MAP CONTROLLER
  // ============================================================

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  // ============================================================
  // LOCATION PERMISSION
  // ============================================================

  Future<bool> checkAndRequestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ============================================================
  // GET CURRENT POSITION
  // ============================================================

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestLocationPermission();

      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // GET CURRENT LAT LNG
  // ============================================================

  Future<LatLng?> getCurrentLatLng() async {
    final position = await getCurrentPosition();

    if (position == null) {
      return null;
    }

    return LatLng(position.latitude, position.longitude);
  }

  // ============================================================
  // MOVE CAMERA
  // ============================================================

  Future<void> moveCamera(LatLng position, {double zoom = defaultZoom}) async {
    if (_mapController == null) {
      return;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
    );
  }

  // ============================================================
  // MOVE CAMERA TO CURRENT LOCATION
  // ============================================================

  Future<LatLng?> moveToCurrentLocation({double zoom = defaultZoom}) async {
    final location = await getCurrentLatLng();

    if (location == null) {
      return null;
    }

    await moveCamera(location, zoom: zoom);

    return location;
  }

  // ============================================================
  // ZOOM IN
  // ============================================================

  Future<void> zoomIn() async {
    await _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  // ============================================================
  // ZOOM OUT
  // ============================================================

  Future<void> zoomOut() async {
    await _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  // ============================================================
  // CREATE MARKER
  // ============================================================

  Marker createMarker({
    required String id,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    bool draggable = false,
    void Function(LatLng)? onDragEnd,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: icon ?? BitmapDescriptor.defaultMarker,
      draggable: draggable,
      infoWindow: InfoWindow(title: title, snippet: snippet),
      onDragEnd: onDragEnd,
      onTap: onTap,
    );
  }

  // ============================================================
  // CREATE MULTIPLE MARKERS
  // ============================================================

  Set<Marker> createMarkers(List<MapLocationData> locations) {
    return locations.map((location) {
      return createMarker(
        id: location.id,
        position: location.position,
        title: location.title,
        snippet: location.snippet,
        icon: location.icon,
      );
    }).toSet();
  }

  // ============================================================
  // CREATE CIRCLE
  // ============================================================

  Circle createCircle({
    required String id,
    required LatLng center,
    double radius = 100,
    int fillColor = 0x336C63FF,
    int strokeColor = 0xFF6C63FF,
    int strokeWidth = 2,
  }) {
    return Circle(
      circleId: CircleId(id),
      center: center,
      radius: radius,
      fillColor: Color(fillColor),
      strokeColor: Color(strokeColor),
      strokeWidth: strokeWidth,
    );
  }

  // ============================================================
  // CREATE POLYLINE
  // ============================================================

  Polyline createPolyline({
    required String id,
    required List<LatLng> points,
    int color = 0xFF2196F3,
    int width = 5,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      points: points,
      color: Color(color),
      width: width,
    );
  }

  // ============================================================
  // FIT CAMERA TO MULTIPLE LOCATIONS
  // ============================================================

  Future<void> fitCameraToPoints(
    List<LatLng> points, {
    double padding = 70,
  }) async {
    if (_mapController == null || points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      await moveCamera(points.first);
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;

    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      }

      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  // ============================================================
  // LAT LNG -> ADDRESS
  // ============================================================

  Future<String?> getAddressFromLatLng(LatLng position) async {
    try {
      final List<geo.Placemark> placemarks = await _geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;

      final List<String?> addressParts = [
        place.name,
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
        place.country,
      ];

      return addressParts
          .whereType<String>()
          .where((item) => item.trim().isNotEmpty)
          .toSet()
          .join(', ');
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      return null;
    }
  }

  // ============================================================
  // ADDRESS -> LAT LNG
  // ============================================================

  Future<LatLng?> getLatLngFromAddress(String address) async {
    try {
      final List<geo.Location> locations = await _geocoding.locationFromAddress(
        address,
      );

      if (locations.isEmpty) return null;

      return LatLng(locations.first.latitude, locations.first.longitude);
    } catch (e) {
      debugPrint('Forward geocoding error: $e');
      return null;
    }
  }

  // ============================================================
  // DISTANCE BETWEEN TWO POINTS
  // ============================================================

  double getDistanceInMeters(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  double getDistanceInKilometers(LatLng start, LatLng end) {
    return getDistanceInMeters(start, end) / 1000;
  }

  // ============================================================
  // LIVE LOCATION STREAM
  // ============================================================

  Stream<Position> getLocationStream({int distanceFilter = 10}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  // ============================================================
  // OPEN LOCATION SETTINGS
  // ============================================================

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  // ============================================================
  // OPEN APP SETTINGS
  // ============================================================

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _mapController?.dispose();
    _mapController = null;
  }
}

// ============================================================
// MAP LOCATION MODEL
// ============================================================

class MapLocationData {
  final String id;
  final LatLng position;
  final String? title;
  final String? snippet;
  final BitmapDescriptor? icon;

  const MapLocationData({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.icon,
  });
}















// ===================================
// example uses
// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});

//   @override
//   State<MapScreen> createState() =>
//       _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   final GoogleMapHelper _mapHelper =
//       GoogleMapHelper.instance;

//   final Set<Marker> _markers = {};

//   LatLng? _currentLocation;

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback(
//       (_) {
//         _loadCurrentLocation();
//       },
//     );
//   }

//   Future<void> _loadCurrentLocation() async {
//     final location =
//         await _mapHelper.getCurrentLatLng();

//     if (location == null || !mounted) {
//       return;
//     }

//     setState(() {
//       _currentLocation = location;

//       _markers.add(
//         _mapHelper.createMarker(
//           id: 'current_location',
//           position: location,
//           title: 'My Location',
//         ),
//       );
//     });

//     await _mapHelper.moveCamera(location);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: GoogleMap(
//         initialCameraPosition:
//             GoogleMapHelper.defaultCameraPosition,

//         markers: _markers,

//         myLocationEnabled:
//             _currentLocation != null,

//         myLocationButtonEnabled: false,

//         zoomControlsEnabled: false,

//         onMapCreated: (controller) {
//           _mapHelper.setMapController(
//             controller,
//           );
//         },

//         onTap: (position) {
//           setState(() {
//             _markers.add(
//               _mapHelper.createMarker(
//                 id: 'selected_location',
//                 position: position,
//                 title: 'Selected Location',
//               ),
//             );
//           });
//         },
//       ),

//       floatingActionButton:
//           FloatingActionButton(
//         onPressed: () async {
//           await _mapHelper
//               .moveToCurrentLocation();
//         },
//         child: const Icon(
//           Icons.my_location,
//         ),
//       ),
//     );
//   }
// }