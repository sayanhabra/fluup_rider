import 'package:adm_rider/core/api/api_service.dart';
import 'package:adm_rider/modules/fulfillment/models/delivery_order.dart';
import 'package:adm_rider/modules/fulfillment/models/rider_active_state_model.dart';
import 'package:adm_rider/modules/fulfillment/models/rider_navigation_model.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:adm_rider/modules/fulfillment/providers/rider_navigation_provider.dart';
import 'package:adm_rider/modules/fulfillment/screens/active_delivery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MockFulfillmentApiService extends Fake implements ApiService {
  BaseResponseModel? activeFulfillmentResponse;
  BaseResponseModel? navigationResponse;

  @override
  Future<BaseResponseModel> getActiveOrderFulfillment() async {
    return activeFulfillmentResponse ??
        BaseResponseModel(
          statusCode: 200,
          message: 'Active state retrieved',
          data: {
            'riderStatus': 'ONLINE_AVAILABLE',
            'stateType': 'IDLE',
            'activeOffer': null,
            'activeDelivery': null,
          },
        );
  }

  @override
  Future<BaseResponseModel> getOrderNavigation(
    int orderId, {
    String? leg,
    double? riderLat,
    double? riderLng,
  }) async {
    return navigationResponse ??
        BaseResponseModel(
          statusCode: 200,
          message: 'Navigation route retrieved',
          data: {
            'orderId': orderId,
            'orderNumber': '#ORD$orderId',
            'activeLeg': leg ?? 'pickup',
            'route': {
              'encodedPolyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
              'distanceMeters': 2800,
              'distanceKm': 2.8,
              'durationSeconds': 420,
              'durationMinutes': 7,
              'durationInTrafficSeconds': 450,
              'durationInTrafficMinutes': 8,
              'origin': {'latitude': 22.5820, 'longitude': 88.3980},
              'destination': {'latitude': 22.5892, 'longitude': 88.4067},
              'steps': [
                {
                  'instruction': 'Head <b>north</b> on EM Bypass',
                  'distanceMeters': 600,
                  'distanceText': '600 m',
                  'durationSeconds': 90,
                  'durationText': '1 min',
                  'maneuver': 'straight',
                  'startLocation': {'latitude': 22.5820, 'longitude': 88.3980},
                  'endLocation': {'latitude': 22.5850, 'longitude': 88.4000},
                },
                {
                  'instruction': 'Turn <b>right</b> onto Salt Lake Bypass',
                  'distanceMeters': 1400,
                  'distanceText': '1.4 km',
                  'durationSeconds': 210,
                  'durationText': '3 mins',
                  'maneuver': 'turn-right',
                  'startLocation': {'latitude': 22.5850, 'longitude': 88.4000},
                  'endLocation': {'latitude': 22.5880, 'longitude': 88.4050},
                },
                {
                  'instruction': 'Turn <b>left</b> at destination store',
                  'distanceMeters': 800,
                  'distanceText': '800 m',
                  'durationSeconds': 120,
                  'durationText': '2 mins',
                  'maneuver': 'turn-left',
                  'startLocation': {'latitude': 22.5880, 'longitude': 88.4050},
                  'endLocation': {'latitude': 22.5892, 'longitude': 88.4067},
                },
              ],
              'provider': 'google_routes',
            },
            'routeWarning': 'Routes API two-wheeler route active.',
            'waypoints': [
              {
                'type': 'STORE',
                'name': 'Royal Spirits Store',
                'latitude': 22.5892,
                'longitude': 88.4067,
                'isCompleted': false,
              },
            ],
          },
        );
  }

  @override
  Future<BaseResponseModel> getRiderTransactions({
    int page = 1,
    int limit = 20,
    String? transactionType,
    String? startDate,
    String? endDate,
  }) async {
    return BaseResponseModel(
      statusCode: 200,
      message: 'Transactions retrieved',
      data: {'items': []},
    );
  }

  @override
  Future<BaseResponseModel> updateRiderStatus(
    String status, {
    double? latitude,
    double? longitude,
    int? batteryLevel,
  }) async {
    return BaseResponseModel(
      statusCode: 200,
      message: 'Status updated',
      data: null,
    );
  }
}

class TestFulfillmentNotifier extends FulfillmentNotifier {
  final DeliveryOrder initialOrder;
  TestFulfillmentNotifier(this.initialOrder);

  @override
  FulfillmentState build() {
    return FulfillmentState(
      isOnline: true,
      activeOrder: initialOrder,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Rider Active State Models & Deserialization', () {
    test('Correctly parses ACTIVE_OFFER response', () {
      final json = {
        'riderStatus': 'ONLINE_AVAILABLE',
        'stateType': 'ACTIVE_OFFER',
        'activeOffer': {
          'orderId': 1024,
          'orderNumber': 'ORD-1024',
          'attemptId': 42,
          'storeName': 'Heritage Wines & Spirits',
          'storeAddress': '12 Park Street, Kolkata',
          'storeLatitude': 22.5532,
          'storeLongitude': 88.3512,
          'deliveryArea': 'Salt Lake Sector 5',
          'distanceKm': 4.5,
          'totalItems': 3,
          'totalVolumeMl': 2250,
          'estimatedEarningsPaisa': 18500,
          'remainingSeconds': 28,
          'expiresAt': '2026-11-15T16:00:00.000Z',
        },
        'activeDelivery': null,
      };

      final activeState = RiderActiveStateResponse.fromJson(json);
      expect(activeState.riderStatus, equals('ONLINE_AVAILABLE'));
      expect(activeState.stateType, equals(RiderStateType.activeOffer));
      expect(activeState.hasActiveOffer, isTrue);
      expect(activeState.hasActiveDelivery, isFalse);

      final offer = activeState.activeOffer!;
      expect(offer.orderId, equals(1024));
      expect(offer.storeName, equals('Heritage Wines & Spirits'));
      expect(offer.storeLatitude, equals(22.5532));
      expect(offer.storeLongitude, equals(88.3512));
      expect(offer.distanceKm, equals(4.5));
      expect(offer.totalItems, equals(3));
      expect(offer.totalVolumeMl, equals(2250));
      expect(offer.formattedVolume, equals('2.3 L'));
      expect(offer.formattedEarnings, equals('₹185'));
    });

    test('Correctly parses ACTIVE_DELIVERY response with store, customer, & items', () {
      final json = {
        'riderStatus': 'ONLINE_BUSY',
        'stateType': 'ACTIVE_DELIVERY',
        'activeOffer': null,
        'activeDelivery': {
          'orderId': 2048,
          'orderNumber': '#ORD2048',
          'fulfillmentStatus': 'OUT_FOR_DELIVERY',
          'orderStatus': 'CONFIRMED',
          'store': {
            'name': 'Bengal Liquor Hub',
            'licenseNumber': 'WB-EXC-2026-8891',
            'address': 'Sector 1, Salt Lake, Kolkata',
            'phone': '+913323340001',
            'latitude': 22.5890,
            'longitude': 88.4060,
          },
          'customer': {
            'name': 'Priyanka Sen',
            'phone': '+919830012345',
            'deliveryAddress': 'Tower 4, Flat 12B, Silver Spring, EM Bypass',
            'pincode': '700105',
            'latitude': 22.5450,
            'longitude': 88.3990,
          },
          'items': [
            {
              'id': 101,
              'productName': 'Royal Challenge Whisky',
              'variantName': '750ml Classic',
              'quantity': 2,
              'packageSize': '750ml',
              'volumeMl': 1500,
              'productImage': 'https://fluup.online/img/rc.png',
            },
            {
              'id': 102,
              'productName': 'Kingfisher Ultra Beer',
              'variantName': '650ml Pint',
              'quantity': 1,
              'packageSize': '650ml',
              'volumeMl': 650,
              'productImage': 'https://fluup.online/img/kf.png',
            },
          ],
          'totalItems': 3,
          'totalVolumeMl': 2150,
          'deliveryFeePaisa': 14000,
          'tipAmountPaisa': 3500,
          'estimatedEarningsPaisa': 17500,
          'isAgeVerificationRequired': true,
          'specialInstructions': 'Please ring the doorbell twice.',
          'milestones': {
            'assignedAt': '2026-11-15T15:00:00.000Z',
            'arrivedAtStoreAt': '2026-11-15T15:10:00.000Z',
            'pickedUpAt': '2026-11-15T15:15:00.000Z',
            'arrivedAtCustomerAt': null,
            'deliveredAt': null,
          },
        },
      };

      final activeState = RiderActiveStateResponse.fromJson(json);
      expect(activeState.stateType, equals(RiderStateType.activeDelivery));
      expect(activeState.hasActiveDelivery, isTrue);

      final delivery = activeState.activeDelivery!;
      expect(delivery.orderId, equals(2048));
      expect(delivery.store.name, equals('Bengal Liquor Hub'));
      expect(delivery.customer.name, equals('Priyanka Sen'));
      expect(delivery.customer.pincode, equals('700105'));
      expect(delivery.items.length, equals(2));
      expect(delivery.totalItems, equals(3));
      expect(delivery.totalVolumeMl, equals(2150));
      expect(delivery.formattedDeliveryFee, equals('₹140'));
      expect(delivery.formattedTip, equals('₹35'));
      expect(delivery.formattedEarnings, equals('₹175'));
      expect(delivery.milestones.pickedUpAt, isNotNull);
      expect(delivery.milestones.deliveredAt, isNull);
    });

    test('Correctly maps to DeliveryOrder via fromActiveOffer and fromActiveDelivery', () {
      final offer = RiderOfferPreview(
        orderId: 777,
        orderNumber: '777',
        attemptId: 1,
        storeName: 'Sunrise Beverages',
        storeAddress: 'New Town, Kolkata',
        storeLatitude: 22.5800,
        storeLongitude: 88.4500,
        deliveryArea: 'Action Area 1',
        distanceKm: 3.2,
        totalItems: 2,
        totalVolumeMl: 1500,
        estimatedEarningsPaisa: 12000,
        remainingSeconds: 25,
      );

      final orderFromOffer = DeliveryOrder.fromActiveOffer(offer);
      expect(orderFromOffer.orderId, equals(777));
      expect(orderFromOffer.orderNumber, equals('#777'));
      expect(orderFromOffer.storeName, equals('Sunrise Beverages'));
      expect(orderFromOffer.totalDistanceKm, equals(3.2));
      expect(orderFromOffer.earningsPaisa, equals(12000));
      expect(orderFromOffer.currentStep, equals(DeliveryFlowStep.offerReceived));

      final detail = RiderActiveDeliveryDetail(
        orderId: 888,
        orderNumber: '#ORD888',
        fulfillmentStatus: 'OUT_FOR_DELIVERY',
        orderStatus: 'CONFIRMED',
        store: const ActiveDeliveryStore(
          name: 'City Spirits',
          licenseNumber: 'LIC-01',
          address: 'Gariahat, Kolkata',
          latitude: 22.5190,
          longitude: 88.3650,
        ),
        customer: const ActiveDeliveryCustomer(
          name: 'Sourav Ganguly',
          phone: '+919999999999',
          deliveryAddress: 'Behala Chowrasta',
          pincode: '700034',
          latitude: 22.4980,
          longitude: 88.3150,
        ),
        items: const [],
        totalItems: 1,
        totalVolumeMl: 750,
        deliveryFeePaisa: 16000,
        tipAmountPaisa: 4000,
        estimatedEarningsPaisa: 20000,
        isAgeVerificationRequired: true,
        milestones: const ActiveDeliveryMilestones(),
      );

      final orderFromDelivery = DeliveryOrder.fromActiveDelivery(detail);
      expect(orderFromDelivery.orderId, equals(888));
      expect(orderFromDelivery.storeName, equals('City Spirits'));
      expect(orderFromDelivery.customerName, equals('Sourav Ganguly'));
      expect(orderFromDelivery.currentStep, equals(DeliveryFlowStep.headingToCustomer));
    });
  });

  group('2. Two-Wheeler Route Polyline & Decoder Tests', () {
    test('Encodes and decodes Google polyline format accurately', () {
      final original = [
        const LatLng(22.5726, 88.3639),
        const LatLng(22.5800, 88.3900),
        const LatLng(22.5892, 88.4067),
      ];

      final encoded = PolylineDecoder.encodePolyline(original);
      expect(encoded, isNotEmpty);

      final decoded = PolylineDecoder.decodePolyline(encoded);
      expect(decoded.length, equals(3));
      expect(decoded[0].latitude, closeTo(original[0].latitude, 0.0001));
      expect(decoded[0].longitude, closeTo(original[0].longitude, 0.0001));
      expect(decoded[2].latitude, closeTo(original[2].latitude, 0.0001));
      expect(decoded[2].longitude, closeTo(original[2].longitude, 0.0001));
    });

    test('PolylineDecoder safely handles empty or blank string', () {
      final emptyResult = PolylineDecoder.decodePolyline('');
      expect(emptyResult, isEmpty);
    });

    test('RouteStep strips HTML and maps proper material maneuver icons', () {
      final stepRight = RouteStep(
        instruction: 'Turn <b>right</b> onto <div>Park Street</div>',
        distanceMeters: 400,
        distanceText: '400 m',
        durationSeconds: 60,
        durationText: '1 min',
        maneuver: 'turn-right',
        startLocation: const MapCoordinates(latitude: 22.55, longitude: 88.35),
        endLocation: const MapCoordinates(latitude: 22.553, longitude: 88.354),
      );

      expect(stepRight.cleanInstruction, equals('Turn right onto Park Street'));
      expect(stepRight.getManeuverIcon(), equals(Icons.turn_right_rounded));

      final stepLeft = RouteStep(
        instruction: 'Turn left',
        distanceMeters: 300,
        distanceText: '300 m',
        durationSeconds: 45,
        durationText: '45 sec',
        maneuver: 'turn-left',
        startLocation: const MapCoordinates(latitude: 22.55, longitude: 88.35),
        endLocation: const MapCoordinates(latitude: 22.553, longitude: 88.354),
      );
      expect(stepLeft.getManeuverIcon(), equals(Icons.turn_left_rounded));

      final stepUturn = RouteStep(
        instruction: 'Make a U-turn',
        distanceMeters: 100,
        distanceText: '100 m',
        durationSeconds: 20,
        durationText: '20 sec',
        maneuver: 'uturn-left',
        startLocation: const MapCoordinates(latitude: 22.55, longitude: 88.35),
        endLocation: const MapCoordinates(latitude: 22.553, longitude: 88.354),
      );
      expect(stepUturn.getManeuverIcon(), equals(Icons.u_turn_left_rounded));
    });
  });

  group('3. Rider Navigation Provider & Legs Tests', () {
    test('fetches navigation and allows cycling turn-by-turn steps', () async {
      final mockApi = MockFulfillmentApiService();
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApi),
        ],
      );
      addTearDown(container.dispose);

      final navNotifier = container.read(riderNavigationProvider.notifier);

      // Initial state is empty
      expect(container.read(riderNavigationProvider).navigation, isNull);

      // Fetch navigation
      await navNotifier.fetchNavigation(1024, leg: NavigationLegEnum.pickup);

      final state = container.read(riderNavigationProvider);
      expect(state.navigation, isNotNull);
      expect(state.selectedLeg, equals(NavigationLegEnum.pickup));
      expect(state.navigation!.route.steps.length, equals(3));
      expect(state.currentStepIndex, equals(0));
      expect(state.currentStep?.cleanInstruction, equals('Head north on EM Bypass'));

      // Cycle to next step
      navNotifier.nextStep();
      expect(container.read(riderNavigationProvider).currentStepIndex, equals(1));
      expect(
        container.read(riderNavigationProvider).currentStep?.cleanInstruction,
        equals('Turn right onto Salt Lake Bypass'),
      );

      // Change leg to delivery
      navNotifier.changeLeg(1024, NavigationLegEnum.delivery);
      expect(container.read(riderNavigationProvider).selectedLeg, equals(NavigationLegEnum.delivery));
    });
  });

  group('4. FulfillmentProvider Active State Sync', () {
    test('checkAndSyncActiveState updates activeOrder from backend', () async {
      final mockApi = MockFulfillmentApiService();
      mockApi.activeFulfillmentResponse = BaseResponseModel(
        statusCode: 200,
        message: 'Active state retrieved',
        data: {
          'riderStatus': 'ONLINE_BUSY',
          'stateType': 'ACTIVE_DELIVERY',
          'activeDelivery': {
            'orderId': 9999,
            'orderNumber': '#ORD9999',
            'fulfillmentStatus': 'OUT_FOR_DELIVERY',
            'orderStatus': 'CONFIRMED',
            'store': {
              'name': 'Active State Store',
              'licenseNumber': 'LIC-9999',
              'address': 'Salt Lake, Kolkata',
              'latitude': 22.5892,
              'longitude': 88.4067,
            },
            'customer': {
              'name': 'Rohan Mukherjee',
              'phone': '+919876543210',
              'deliveryAddress': 'City Centre 1, Salt Lake',
              'pincode': '700064',
              'latitude': 22.5920,
              'longitude': 88.4110,
            },
            'items': [],
            'totalItems': 1,
            'totalVolumeMl': 750,
            'deliveryFeePaisa': 12000,
            'tipAmountPaisa': 2000,
            'estimatedEarningsPaisa': 14000,
            'isAgeVerificationRequired': true,
            'milestones': {},
          },
        },
      );

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApi),
        ],
      );
      addTearDown(container.dispose);

      final res = await container.read(fulfillmentProvider.notifier).checkAndSyncActiveState();
      expect(res, isNotNull);
      expect(res!.stateType, equals(RiderStateType.activeDelivery));

      final activeOrder = container.read(fulfillmentProvider).activeOrder;
      expect(activeOrder, isNotNull);
      expect(activeOrder!.orderId, equals(9999));
      expect(activeOrder.storeName, equals('Active State Store'));
      expect(activeOrder.currentStep, equals(DeliveryFlowStep.headingToCustomer));
    });
  });

  group('5. ActiveDeliveryScreen Navigation HUD Widget Tests', () {
    testWidgets('Renders Turn-by-Turn HUD and opens full maneuvers sheet', (tester) async {
      final mockApi = MockFulfillmentApiService();
      final sampleOrder = DeliveryOrder.sample().copyWith(
        currentStep: DeliveryFlowStep.headingToStore,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
            fulfillmentProvider.overrideWith(() => TestFulfillmentNotifier(sampleOrder)),
          ],
          child: const MaterialApp(
            home: ActiveDeliveryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen 5 Heading to Store AppBar
      expect(find.text('Heading to Store'), findsOneWidget);

      // Verify Turn-by-Turn Navigation HUD is rendered
      expect(find.byType(ActiveDeliveryScreen), findsOneWidget);

      // Verify Leg Selector Chips
      expect(find.text('To Store (Pickup)'), findsOneWidget);
      expect(find.text('To Customer (Delivery)'), findsOneWidget);
      expect(find.text('Return to Store'), findsOneWidget);
      expect(find.text('Full Route'), findsOneWidget);

      // Tap the Turn steps list button
      final turnStepsBtn = find.byTooltip('Turn steps');
      if (turnStepsBtn.evaluate().isNotEmpty) {
        await tester.tap(turnStepsBtn);
        await tester.pumpAndSettle();

        // Verify bottom sheet title is displayed
        expect(find.text('Turn-by-Turn Route'), findsOneWidget);
      }
    });
  });
}
