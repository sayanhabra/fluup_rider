import 'package:adm_rider/core/api/api_service.dart';
import 'package:adm_rider/core/shared/helpers/rider_location_tracker.dart';
import 'package:adm_rider/core/shared/helpers/two_wheeler_route_helper.dart';
import 'package:adm_rider/modules/dashboard/screens/dashboard_screen.dart';
import 'package:adm_rider/modules/fulfillment/models/delivery_order.dart';
import 'package:adm_rider/modules/fulfillment/models/rider_active_state_model.dart';
import 'package:adm_rider/modules/fulfillment/models/rider_navigation_model.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:adm_rider/modules/fulfillment/providers/rider_navigation_provider.dart';
import 'package:adm_rider/modules/fulfillment/screens/active_delivery_screen.dart';
import 'package:adm_rider/modules/fulfillment/screens/new_order_request_modal.dart';
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
  Future<BaseResponseModel?> getOrderNavigation(
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

  @override
  Future<BaseResponseModel> arriveAtStore({
    required int orderId,
    double? latitude,
    double? longitude,
  }) async {
    return BaseResponseModel(statusCode: 200, message: 'Arrived at store', data: null);
  }

  @override
  Future<BaseResponseModel> verifyPickup({
    required int orderId,
    required String otp,
    double? latitude,
    double? longitude,
  }) async {
    return BaseResponseModel(statusCode: 200, message: 'Pickup verified', data: null);
  }

  @override
  Future<BaseResponseModel> arriveAtCustomer({
    required int orderId,
    double? latitude,
    double? longitude,
  }) async {
    return BaseResponseModel(statusCode: 200, message: 'Arrived at customer', data: null);
  }

  @override
  Future<BaseResponseModel> completeDelivery({
    required int orderId,
    required String deliveryOtp,
    required bool isAgeVerified,
    String verificationMethod = 'OTP_ONLY',
    String? verifiedDocumentType,
  }) async {
    return BaseResponseModel(statusCode: 200, message: 'Delivery completed', data: null);
  }
}

class MockRiderLiveLocationNotifier extends RiderLiveLocationNotifier {
  final LatLng? initial;
  MockRiderLiveLocationNotifier([this.initial]);

  @override
  LatLng? build() => initial;
}

class TestFulfillmentNotifier extends FulfillmentNotifier {
  final DeliveryOrder initialOrder;
  TestFulfillmentNotifier(this.initialOrder);

  @override
  FulfillmentState build() {
    super.build();
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

      // Verify Leg Selector Chips are NOT shown (clean UI without tabs)
      expect(find.text('To Store (Pickup)'), findsNothing);
      expect(find.text('To Customer (Delivery)'), findsNothing);

      // Verify Info icon is rendered for Order Details
      final infoBtn = find.byTooltip('Order Details');
      expect(infoBtn, findsOneWidget);

      // Tap the Order Details info button to open the modal
      await tester.tap(infoBtn);
      await tester.pumpAndSettle();

      // Verify Order Details bottom sheet modal is displayed
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('Store Information'), findsOneWidget);
      expect(find.text('Delivery Information'), findsOneWidget);
    });

    testWidgets('30-meter proximity shows Arrived at Store, transitions to OTP and to Customer UI', (tester) async {
      final mockApi = MockFulfillmentApiService();
      const storeLoc = LatLng(22.5892, 88.4067);
      // Rider is 10 meters away from store (within 30m)
      const riderNearStore = LatLng(22.58925, 88.4067);
      final sampleOrder = DeliveryOrder.sample().copyWith(
        storeLocation: storeLoc,
        currentStep: DeliveryFlowStep.headingToStore,
      );

      final notifier = TestFulfillmentNotifier(sampleOrder);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
            fulfillmentProvider.overrideWith(() => notifier),
            riderLiveLocationProvider.overrideWith(() => MockRiderLiveLocationNotifier(riderNearStore)),
          ],
          child: const MaterialApp(
            home: ActiveDeliveryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Within 30m: "Arrived at Store" button MUST be visible
      final arrivedAtStoreBtn = find.text('Arrived at Store');
      expect(arrivedAtStoreBtn, findsOneWidget);

      // Tap "Arrived at Store"
      await tester.tap(arrivedAtStoreBtn);
      await tester.pumpAndSettle();

      // Should transition to Enter Store OTP page
      expect(find.text('Enter Store OTP'), findsOneWidget);
    });

    testWidgets('Heading to Customer within 30m shows Arrived at Delivery Location and transitions to Customer OTP', (tester) async {
      final mockApi = MockFulfillmentApiService();
      const customerLoc = LatLng(22.5726, 88.4337);
      // Rider is within 30m of customer
      const riderNearCustomer = LatLng(22.57265, 88.4337);
      final sampleOrder = DeliveryOrder.sample().copyWith(
        customerLocation: customerLoc,
        currentStep: DeliveryFlowStep.headingToCustomer,
      );

      final notifier = TestFulfillmentNotifier(sampleOrder);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
            fulfillmentProvider.overrideWith(() => notifier),
            riderLiveLocationProvider.overrideWith(() => MockRiderLiveLocationNotifier(riderNearCustomer)),
          ],
          child: const MaterialApp(
            home: ActiveDeliveryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Heading to Customer should have clean UI (no leg selector chips, no navigate button)
      expect(find.text('To Store (Pickup)'), findsNothing);
      expect(find.text('To Customer (Delivery)'), findsNothing);
      expect(find.text('Navigate'), findsNothing);

      // Within 30m: "Arrived at Delivery Location" button MUST be visible
      final arrivedAtCustBtn = find.text('Arrived at Delivery Location');
      expect(arrivedAtCustBtn, findsOneWidget);

      // Tap "Arrived at Delivery Location"
      await tester.tap(arrivedAtCustBtn);
      await tester.pumpAndSettle();

      // Should transition to Enter Customer OTP page
      expect(find.text('Enter Customer OTP'), findsOneWidget);
    });
  });

  group('6. TwoWheelerRouteHelper & Curved Polyline Generation Tests', () {
    test('generateTwoWheelerRoute generates multi-point curved route, never a 2-point straight line', () {
      const origin = LatLng(22.5820, 88.3980);
      const destination = LatLng(22.5892, 88.4067);

      final points = TwoWheelerRouteHelper.generateTwoWheelerRoute(
        origin: origin,
        destination: destination,
      );

      // Must have many curved road points, never just [origin, destination]
      expect(points.length, greaterThan(15));
      expect(points.first, equals(origin));
      expect(points.last, equals(destination));

      // Test with waypoints (e.g. Rider -> Store -> Customer)
      const storeWaypoint = LatLng(22.5850, 88.4020);
      final fullRoutePoints = TwoWheelerRouteHelper.generateTwoWheelerRoute(
        origin: origin,
        destination: destination,
        waypoints: [storeWaypoint],
      );
      expect(fullRoutePoints.length, greaterThan(30));
    });

    test('createTwoWheelerPolyline configures rounded caps, joints, and width', () {
      final polyline = TwoWheelerRouteHelper.createTwoWheelerPolyline(
        polylineId: 'testTwoWheeler',
        points: const [
          LatLng(22.5820, 88.3980),
          LatLng(22.5850, 88.4020),
          LatLng(22.5892, 88.4067),
        ],
        width: 6,
      );

      expect(polyline.polylineId.value, equals('testTwoWheeler'));
      expect(polyline.width, equals(6));
      expect(polyline.startCap, equals(Cap.roundCap));
      expect(polyline.endCap, equals(Cap.roundCap));
      expect(polyline.jointType, equals(JointType.round));
    });

    test('calculateBounds computes valid LatLngBounds bounding all route coordinates', () {
      final points = [
        const LatLng(22.5820, 88.3980),
        const LatLng(22.5850, 88.4020),
        const LatLng(22.5892, 88.4067),
      ];

      final bounds = TwoWheelerRouteHelper.calculateBounds(points);
      expect(bounds, isNotNull);
      expect(bounds!.southwest.latitude, lessThan(22.5820));
      expect(bounds.northeast.latitude, greaterThan(22.5892));
    });
  });

  group('7. NewOrderRequestModal & Dashboard Map Route Integration Tests', () {
    testWidgets('NewOrderRequestModal renders Rider marker, Store marker, Customer marker and curved route', (tester) async {
      final mockApi = MockFulfillmentApiService();
      final sampleOrder = DeliveryOrder.sample();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
            riderLiveLocationProvider.overrideWith(
              () => _TestRiderLiveLocationNotifier(const LatLng(22.5750, 88.3700)),
            ),
          ],
          child: MaterialApp(
            home: NewOrderRequestModal(order: sampleOrder),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Modal renders
      expect(find.text('New Order Request'), findsOneWidget);
      expect(find.textContaining('Royal Liquor Store'), findsWidgets);
      expect(find.textContaining('Accept'), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);

      // Verify GoogleMap has markers and polylines configured
      final mapFinder = find.byType(GoogleMap);
      final GoogleMap mapWidget = tester.widget(mapFinder);

      // Check markers: must include rider_bike, store, and customer
      final markerIds = mapWidget.markers.map((m) => m.markerId.value).toSet();
      expect(markerIds.contains('rider_bike'), isTrue);
      expect(markerIds.contains('store'), isTrue);
      expect(markerIds.contains('customer'), isTrue);

      // Check polylines: must include offerTwoWheelerRoute with curved points (not a 2-point straight line)
      expect(mapWidget.polylines.isNotEmpty, isTrue);
      final polyline = mapWidget.polylines.first;
      expect(polyline.polylineId.value, equals('offerTwoWheelerRoute'));
      expect(polyline.points.length, greaterThan(2));
    });

    testWidgets('DashboardScreen in ACTIVE_OFFER renders offer card, map markers & two-wheeler route', (tester) async {
      final mockApi = MockFulfillmentApiService();
      mockApi.activeFulfillmentResponse = BaseResponseModel(
        statusCode: 200,
        message: 'Active offer available',
        data: {
          'riderStatus': 'ONLINE_AVAILABLE',
          'stateType': 'ACTIVE_OFFER',
          'activeOffer': {
            'orderId': 78216,
            'orderNumber': '#ORD78216',
            'attemptId': 1,
            'storeName': 'Royal Liquor Store',
            'storeAddress': 'Lake Town, Kolkata',
            'storeLatitude': 22.5892,
            'storeLongitude': 88.4067,
            'deliveryArea': 'Salt Lake, Kolkata',
            'distanceKm': 2.6,
            'totalItems': 2,
            'totalVolumeMl': 1500,
            'estimatedEarningsPaisa': 6500,
            'remainingSeconds': 42,
          },
          'activeDelivery': null,
        },
      );

      final offerOrder = DeliveryOrder.sample().copyWith(
        currentStep: DeliveryFlowStep.offerReceived,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
            fulfillmentProvider.overrideWith(() => TestFulfillmentNotifier(offerOrder)),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Offer Card is visible on Dashboard
      expect(find.text('⚡ NEW OFFER'), findsOneWidget);
      expect(find.text('Review & Accept'), findsOneWidget);

      // Verify GoogleMap has markers (rider, store, customer) and two-wheeler polyline
      final mapFinder = find.byType(GoogleMap);
      expect(mapFinder, findsOneWidget);
      final GoogleMap mapWidget = tester.widget(mapFinder);

      final markerIds = mapWidget.markers.map((m) => m.markerId.value).toSet();
      expect(markerIds.contains('rider_loc'), isTrue);
      expect(markerIds.contains('store_loc'), isTrue);
      expect(markerIds.contains('customer_loc'), isTrue);

      expect(mapWidget.polylines.isNotEmpty, isTrue);
      final polyline = mapWidget.polylines.first;
      expect(polyline.polylineId.value, equals('dashboardTwoWheelerRoute'));
      expect(polyline.points.length, greaterThan(10));
    });

    testWidgets('8. Live API Order #26: Dynamic Store & Customer Coordinates and Two-Wheeler Route on ActiveDeliveryScreen & Dashboard', (tester) async {
      final order26ActiveState = {
        'statusCode': 200,
        'message': 'Active state retrieved successfully',
        'response': {
          'riderStatus': 'ONLINE_BUSY',
          'stateType': 'ACTIVE_DELIVERY',
          'activeOffer': null,
          'activeDelivery': {
            'orderId': 26,
            'orderNumber': 'ORD-1794805222757-2722',
            'fulfillmentStatus': 'RIDER_ACCEPTED',
            'orderStatus': 'RIDER_ASSIGNED',
            'store': {
              'name': 'Royal Liquor Palace',
              'licenseNumber': 'EXCISE/KA/2026/99812',
              'address': 'D2/2, EP Block, Sector V, Salt Lake, Kolkata, 700091',
              'phone': '9733951500',
              'latitude': 22.5727464,
              'longitude': 88.4367467,
            },
            'customer': {
              'name': 'Test case',
              'phone': '8741147085',
              'deliveryAddress': 'Tcs Gitobitan, DN Block, Sector V, Kolkata, 700091',
              'pincode': '700091',
              'latitude': 22.57855177,
              'longitude': 88.43050992,
            },
            'items': [
              {
                'id': 27,
                'name': 'Kingfisher Premium 650ml',
                'quantity': 2,
                'volumeMl': 650,
                'pricePaisa': 32000,
              }
            ],
            'totalItems': 2,
            'totalVolumeMl': 1300,
            'deliveryFeePaisa': 6000,
            'tipAmountPaisa': 2000,
          },
        },
      };

      // 1. Verify model parsing of Order #26
      final activeResponse = RiderActiveStateResponse.fromJson(order26ActiveState);
      expect(activeResponse.stateType, equals(RiderStateType.activeDelivery));
      final detail = activeResponse.activeDelivery!;
      expect(detail.store.name, equals('Royal Liquor Palace'));
      expect(detail.store.latitude, closeTo(22.5727464, 0.0001));
      expect(detail.store.longitude, closeTo(88.4367467, 0.0001));
      expect(detail.customer.name, equals('Test case'));
      expect(detail.customer.latitude, closeTo(22.57855177, 0.0001));
      expect(detail.customer.longitude, closeTo(88.43050992, 0.0001));

      // 2. Map to DeliveryOrder and verify dynamic distance calculation
      final order26 = DeliveryOrder.fromActiveDelivery(detail);
      expect(order26.storeName, equals('Royal Liquor Palace'));
      expect(order26.storeLocation.latitude, closeTo(22.5727464, 0.0001));
      expect(order26.storeLocation.longitude, closeTo(88.4367467, 0.0001));
      expect(order26.customerName, equals('Test case'));
      expect(order26.customerLocation.latitude, closeTo(22.57855177, 0.0001));
      expect(order26.customerLocation.longitude, closeTo(88.43050992, 0.0001));

      // Dynamic distance between store and customer is ~1.1 km
      expect(order26.customerDistanceText, contains('km'));
      expect(order26.totalDistanceKm, lessThan(3.0)); // Not hardcoded 6.3 km
      expect(order26.totalDistanceKm, greaterThan(0.5));

      // 3. Verify two-wheeler route generation produces multi-point road curves (not straight line)
      final routePoints = TwoWheelerRouteHelper.generateTwoWheelerRoute(
        origin: LatLng(22.5720, 88.4350),
        destination: order26.storeLocation,
      );
      expect(routePoints.length, greaterThan(20)); // Realistic street vertices + curves

      // 4. Test rendering on ActiveDeliveryScreen
      final mockApi = MockFulfillmentApiService();
      mockApi.activeFulfillmentResponse = BaseResponseModel(
        statusCode: 200,
        message: 'Success',
        data: order26ActiveState['response'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
            fulfillmentProvider.overrideWith(() => TestFulfillmentNotifier(order26)),
          ],
          child: const MaterialApp(
            home: ActiveDeliveryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify ActiveDeliveryScreen displays dynamic store info
      expect(find.text('Royal Liquor Palace'), findsOneWidget);
      expect(find.text('Order #ORD-1794805222757-2722'), findsOneWidget);

      // Verify map markers on ActiveDeliveryScreen
      final activeMapFinder = find.byType(GoogleMap);
      expect(activeMapFinder, findsOneWidget);
      final GoogleMap activeMapWidget = tester.widget(activeMapFinder);

      final storeMarker = activeMapWidget.markers.firstWhere((m) => m.markerId.value == 'store');
      expect(storeMarker.position.latitude, closeTo(22.5727464, 0.0001));
      expect(storeMarker.position.longitude, closeTo(88.4367467, 0.0001));
      expect(storeMarker.infoWindow.title, equals('Royal Liquor Palace'));

      // Verify two-wheeler polyline is rendered
      expect(activeMapWidget.polylines.isNotEmpty, isTrue);
      final activePolyline = activeMapWidget.polylines.first;
      expect(activePolyline.points.length, greaterThan(15));
    });
  });
}

class _TestRiderLiveLocationNotifier extends RiderLiveLocationNotifier {
  final LatLng initialLoc;
  _TestRiderLiveLocationNotifier(this.initialLoc);

  @override
  LatLng? build() => initialLoc;
}
