// modules/dashboard/screens/dashboard_screen.dart

import 'package:adm_rider/core/config/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DashboardMapView extends StatelessWidget {
  final MapController mapController;
  final LatLng currentLocation;

  const DashboardMapView({
    super.key,
    required this.mapController,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentLocation,
        initialZoom: 16.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fluup.rider',
        ),
        // The highlighted radius area around the rider
        CircleLayer(
          circles: [
            CircleMarker(
              point: currentLocation,
              color: Brand.red.withValues(alpha: 0.10),
              borderColor: Brand.red.withValues(alpha: 0.3),
              borderStrokeWidth: 1.5,
              radius: 150, // in meters
            ),
          ],
        ),
        // The actual rider pin
        MarkerLayer(
          markers: [
            Marker(
              point: currentLocation,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Brand.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
