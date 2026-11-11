import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/helpers/google_map_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardMapView extends StatelessWidget {
  final LatLng currentLocation;

  const DashboardMapView({super.key, required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    final mapHelper = GoogleMapHelper.instance;

    return SizedBox.expand(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentLocation,
          zoom: 16,
        ),

        onMapCreated: (controller) {
          mapHelper.setMapController(controller);
        },

        mapType: MapType.normal,
        compassEnabled: false,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        indoorViewEnabled: false,
        buildingsEnabled: true,
        trafficEnabled: false,

        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        myLocationEnabled: false,

        markers: {
          mapHelper.createMarker(
            id: 'rider_location',
            position: currentLocation,
            title: 'Your Location',
            snippet: 'Fluup Rider',
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        },

        circles: {
          mapHelper.createCircle(
            id: 'rider_radius',
            center: currentLocation,
            radius: 150,
            fillColor: Brand.red.withValues(alpha: 0.10).toARGB32(),
            strokeColor: Brand.red.withValues(alpha: 0.35).toARGB32(),
            strokeWidth: 2,
          ),
        },
      ),
    );
  }
}
