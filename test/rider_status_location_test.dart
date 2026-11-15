import 'package:adm_rider/core/api/api_handler.dart';
import 'package:adm_rider/core/api/api_service.dart';
import 'package:adm_rider/core/shared/helpers/rider_location_tracker.dart';
import 'package:adm_rider/core/shared/helpers/two_wheeler_marker_helper.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rider Online/Offline & Location Telemetry Guards', () {
    test(
      '1. Initial rider status is OFFLINE by default (isOnline == false)',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final fulfillmentState = container.read(fulfillmentProvider);
        expect(
          fulfillmentState.isOnline,
          isFalse,
          reason: 'Initial status of rider must be offline',
        );
      },
    );

    test(
      '2. RiderLocationTracker will not start if rider is logged out or offline',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final tracker = container.read(riderLocationTrackerProvider);
        expect(tracker.isRunning, isFalse);

        // Attempt to start while unauthenticated and offline
        tracker.start();

        expect(
          tracker.isRunning,
          isFalse,
          reason:
              'Location tracker must not run if rider is not authenticated or offline',
        );
      },
    );

    test(
      '3. Toggling online sets isOnline to true, toggling offline sets it to false',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(fulfillmentProvider).isOnline, isFalse);

        await container.read(fulfillmentProvider.notifier).toggleOnline(true);
        expect(container.read(fulfillmentProvider).isOnline, isTrue);

        await container.read(fulfillmentProvider.notifier).toggleOnline(false);
        expect(container.read(fulfillmentProvider).isOnline, isFalse);
      },
    );

    test(
      '4. resetOnLogout ensures rider status is offline and stops tracker',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(fulfillmentProvider.notifier).toggleOnline(true);
        expect(container.read(fulfillmentProvider).isOnline, isTrue);

        container.read(fulfillmentProvider.notifier).resetOnLogout();
        expect(container.read(fulfillmentProvider).isOnline, isFalse);

        final tracker = container.read(riderLocationTrackerProvider);
        expect(tracker.isRunning, isFalse);
      },
    );

    test(
      '5. riderLiveLocationProvider updates location coordinates for moving map marker',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(riderLiveLocationProvider), isNull);

        // Simulate 30-second location update
        const pos1 = LatLng(22.5726, 88.3639);
        container.read(riderLiveLocationProvider.notifier).updateLocation(pos1);
        expect(container.read(riderLiveLocationProvider), equals(pos1));

        // Next 30-second location update (rider moves)
        const pos2 = LatLng(22.5800, 88.3700);
        container.read(riderLiveLocationProvider.notifier).updateLocation(pos2);
        expect(container.read(riderLiveLocationProvider), equals(pos2));
      },
    );

    test(
      '6. TwoWheelerMarkerHelper provides marker icon and supports custom asset configuration',
      () async {
        final helper = TwoWheelerMarkerHelper.instance;

        // Verify default delivery car asset and small marker size
        expect(TwoWheelerMarkerHelper.defaultAssetPath, equals('assets/png/delivery_car.png'));
        expect(TwoWheelerMarkerHelper.defaultMarkerSize, equals(48.0));

        // Retrieve two-wheeler icon marker
        final markerIcon = await helper.getTwoWheelerMarker();
        expect(markerIcon, isNotNull);

        // Verify custom asset path property exists and can be set for custom asset images
        TwoWheelerMarkerHelper.customAssetPath = 'assets/png/custom_bike.png';
        expect(TwoWheelerMarkerHelper.customAssetPath, equals('assets/png/custom_bike.png'));

        // Reset
        TwoWheelerMarkerHelper.customAssetPath = null;
      },
    );

    test(
      '7. updateRiderStatus sends status, latitude, longitude, and batteryLevel in request body',
      () async {
        Map<String, dynamic>? capturedData;
        String? capturedEndpoint;

        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedEndpoint = options.path;
              capturedData = options.data as Map<String, dynamic>?;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'statusCode': 200,
                    'message': 'Status updated to ONLINE_AVAILABLE',
                    'response': null,
                  },
                ),
              );
            },
          ),
        );

        final apiHandler = ApiHandler(dio: dio);
        final apiService = ApiService(apiHandler: apiHandler);

        final response = await apiService.updateRiderStatus(
          'ONLINE_AVAILABLE',
          latitude: 12.9716,
          longitude: 77.5946,
          batteryLevel: 85,
        );

        expect(capturedEndpoint, contains('/order-fulfillment/status'));
        expect(capturedData, isNotNull);
        expect(capturedData!['status'], equals('ONLINE_AVAILABLE'));
        expect(capturedData!['latitude'], equals(12.9716));
        expect(capturedData!['longitude'], equals(77.5946));
        expect(capturedData!['batteryLevel'], equals(85));
        expect(response.statusCode, equals(200));
      },
    );
  });
}
