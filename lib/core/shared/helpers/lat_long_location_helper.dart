import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LatLongLocationHelper {
  final Geocoding _geocoding = Geocoding();

  /// Converts a [Position] into a user-friendly address string.
  Future<String> getAddressFromPosition(Position? position) async {
    if (position == null) {
      return 'Location not available';
    }

    try {
      final List<Placemark> placemarks = await _geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isEmpty) {
        return 'Address not found';
      }

      final Placemark place = placemarks.first;

      final addressParts = <String?>[
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
      ];

      final address = addressParts
          .where((item) => item != null && item.trim().isNotEmpty)
          .join(', ');

      return address.isNotEmpty ? address : 'Unknown location';
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      return 'Unable to get area location';
    }
  }
}
