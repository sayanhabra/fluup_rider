import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum NavigationLegEnum {
  pickup('pickup', 'To Store (Pickup)', Icons.storefront_rounded),
  delivery('delivery', 'To Customer (Delivery)', Icons.person_pin_circle_rounded),
  returnLeg('return', 'Return to Store', Icons.replay_rounded),
  full('full', 'Full Route', Icons.alt_route_rounded);

  final String value;
  final String label;
  final IconData icon;

  const NavigationLegEnum(this.value, this.label, this.icon);

  static NavigationLegEnum fromString(String? val) {
    if (val == null) return NavigationLegEnum.pickup;
    for (final leg in NavigationLegEnum.values) {
      if (leg.value.toLowerCase() == val.toLowerCase()) {
        return leg;
      }
    }
    return NavigationLegEnum.pickup;
  }
}

class MapCoordinates {
  final double latitude;
  final double longitude;
  final String? title;
  final String? address;

  const MapCoordinates({
    required this.latitude,
    required this.longitude,
    this.title,
    this.address,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  factory MapCoordinates.fromJson(Map<String, dynamic> json) {
    return MapCoordinates(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      title: json['title']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (title != null) 'title': title,
        if (address != null) 'address': address,
      };
}

class RouteStep {
  final String instruction;
  final int distanceMeters;
  final String distanceText;
  final int durationSeconds;
  final String durationText;
  final String maneuver;
  final MapCoordinates startLocation;
  final MapCoordinates endLocation;

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.distanceText,
    required this.durationSeconds,
    required this.durationText,
    required this.maneuver,
    required this.startLocation,
    required this.endLocation,
  });

  /// Strips any residual HTML tags from instruction strings
  String get cleanInstruction {
    return instruction
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  IconData getManeuverIcon() {
    final m = maneuver.toLowerCase();
    if (m.contains('uturn')) return Icons.u_turn_left_rounded;
    if (m.contains('roundabout')) return Icons.roundabout_right_rounded;
    if (m.contains('turn-sharp-right')) return Icons.turn_sharp_right_rounded;
    if (m.contains('turn-sharp-left')) return Icons.turn_sharp_left_rounded;
    if (m.contains('turn-right') || m.contains('ramp-right') || m.contains('fork-right')) {
      return Icons.turn_right_rounded;
    }
    if (m.contains('turn-left') || m.contains('ramp-left') || m.contains('fork-left')) {
      return Icons.turn_left_rounded;
    }
    if (m.contains('destination') || m.contains('arrive')) return Icons.flag_rounded;
    return Icons.straight_rounded;
  }

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: json['instruction']?.toString() ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      distanceText: json['distanceText']?.toString() ?? '',
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      durationText: json['durationText']?.toString() ?? '',
      maneuver: json['maneuver']?.toString() ?? 'straight',
      startLocation: MapCoordinates.fromJson(
        (json['startLocation'] as Map<String, dynamic>?) ?? {},
      ),
      endLocation: MapCoordinates.fromJson(
        (json['endLocation'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'instruction': instruction,
        'distanceMeters': distanceMeters,
        'distanceText': distanceText,
        'durationSeconds': durationSeconds,
        'durationText': durationText,
        'maneuver': maneuver,
        'startLocation': startLocation.toJson(),
        'endLocation': endLocation.toJson(),
      };
}

class RouteDetails {
  final String encodedPolyline;
  final int distanceMeters;
  final double distanceKm;
  final int durationSeconds;
  final int durationMinutes;
  final int durationInTrafficSeconds;
  final int durationInTrafficMinutes;
  final MapCoordinates origin;
  final MapCoordinates destination;
  final List<RouteStep> steps;
  final String provider;
  final List<LatLng> points;

  const RouteDetails({
    required this.encodedPolyline,
    required this.distanceMeters,
    required this.distanceKm,
    required this.durationSeconds,
    required this.durationMinutes,
    required this.durationInTrafficSeconds,
    required this.durationInTrafficMinutes,
    required this.origin,
    required this.destination,
    required this.steps,
    required this.provider,
    required this.points,
  });

  factory RouteDetails.fromJson(Map<String, dynamic> json) {
    final encoded = json['encodedPolyline']?.toString() ?? '';
    final rawSteps = json['steps'] as List<dynamic>? ?? [];

    return RouteDetails(
      encodedPolyline: encoded,
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      durationInTrafficSeconds:
          (json['durationInTrafficSeconds'] as num?)?.toInt() ?? 0,
      durationInTrafficMinutes:
          (json['durationInTrafficMinutes'] as num?)?.toInt() ?? 0,
      origin: MapCoordinates.fromJson(
        json['origin'] is Map
            ? Map<String, dynamic>.from(json['origin'] as Map)
            : {},
      ),
      destination: MapCoordinates.fromJson(
        json['destination'] is Map
            ? Map<String, dynamic>.from(json['destination'] as Map)
            : {},
      ),
      steps: rawSteps
          .map((s) => RouteStep.fromJson(
              s is Map ? Map<String, dynamic>.from(s) : {}))
          .toList(),
      provider: json['provider']?.toString() ?? 'google_routes',
      points: PolylineDecoder.decodePolyline(encoded),
    );
  }

  Map<String, dynamic> toJson() => {
        'encodedPolyline': encodedPolyline,
        'distanceMeters': distanceMeters,
        'distanceKm': distanceKm,
        'durationSeconds': durationSeconds,
        'durationMinutes': durationMinutes,
        'durationInTrafficSeconds': durationInTrafficSeconds,
        'durationInTrafficMinutes': durationInTrafficMinutes,
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'steps': steps.map((s) => s.toJson()).toList(),
        'provider': provider,
      };
}

class NavigationWaypoint {
  final String type; // 'STORE' | 'CUSTOMER'
  final String name;
  final double latitude;
  final double longitude;
  final bool isCompleted;

  const NavigationWaypoint({
    required this.type,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isCompleted,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  factory NavigationWaypoint.fromJson(Map<String, dynamic> json) {
    return NavigationWaypoint(
      type: json['type']?.toString() ?? 'STORE',
      name: json['name']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'isCompleted': isCompleted,
      };
}

class RiderNavigationResponse {
  final int orderId;
  final String orderNumber;
  final NavigationLegEnum activeLeg;
  final RouteDetails route;
  final String routeWarning;
  final List<NavigationWaypoint> waypoints;

  const RiderNavigationResponse({
    required this.orderId,
    required this.orderNumber,
    required this.activeLeg,
    required this.route,
    required this.routeWarning,
    required this.waypoints,
  });

  factory RiderNavigationResponse.fromJson(Map<String, dynamic> json) {
    final legStr = json['activeLeg']?.toString();
    final rawWaypoints = json['waypoints'] as List<dynamic>? ?? [];

    return RiderNavigationResponse(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderNumber: json['orderNumber']?.toString() ?? '',
      activeLeg: NavigationLegEnum.fromString(legStr),
      route: RouteDetails.fromJson(
        json['route'] is Map
            ? Map<String, dynamic>.from(json['route'] as Map)
            : {},
      ),
      routeWarning: json['routeWarning']?.toString() ?? '',
      waypoints: rawWaypoints
          .map((w) => NavigationWaypoint.fromJson(
              w is Map ? Map<String, dynamic>.from(w) : {}))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'activeLeg': activeLeg.value,
        'route': route.toJson(),
        'routeWarning': routeWarning,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
      };
}

/// Robust Google Encoded Polyline algorithm decoder & encoder
class PolylineDecoder {
  /// Decodes an encoded path string into a [List<LatLng>].
  static List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) return const [];
    final List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      if (index >= len) break;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  /// Encodes a list of [LatLng] coordinates into Google's polyline format.
  static String encodePolyline(List<LatLng> points) {
    if (points.isEmpty) return '';
    final StringBuffer str = StringBuffer();

    void encodeValue(int value) {
      int v = value < 0 ? ~(value << 1) : (value << 1);
      while (v >= 0x20) {
        str.writeCharCode((0x20 | (v & 0x1f)) + 63);
        v >>= 5;
      }
      str.writeCharCode(v + 63);
    }

    int prevLat = 0;
    int prevLng = 0;

    for (final point in points) {
      final int lat = (point.latitude * 1E5).round();
      final int lng = (point.longitude * 1E5).round();

      encodeValue(lat - prevLat);
      encodeValue(lng - prevLng);

      prevLat = lat;
      prevLng = lng;
    }

    return str.toString();
  }
}
