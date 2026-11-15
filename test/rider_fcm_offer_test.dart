import 'package:adm_rider/core/shared/helpers/notification_sound_helper.dart';
import 'package:adm_rider/modules/fulfillment/models/delivery_order.dart';
import 'package:adm_rider/modules/fulfillment/providers/fulfillment_provider.dart';
import 'package:adm_rider/modules/fulfillment/screens/new_order_request_modal.dart';
import 'package:adm_rider/modules/notifications/services/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FCM RIDER_OFFER & Soundlink Tests', () {
    test('1. DeliveryOrder.fromNotificationData correctly parses FCM payload', () {
      final payload = {
        'type': 'ORDER',
        'entityId': '98412',
        'orderNumber': '#ORD98412',
        'event': 'RIDER_OFFER',
        'sound': 'https://api.fluup.online/sounds/rider_alert.mp3',
        'storeName': 'Star Liquor Store',
        'storeAddress': 'Park Street, Kolkata',
        'storeLatitude': '22.5532',
        'storeLongitude': '88.3512',
        'customerName': 'Aakash Verma',
        'customerAddress': 'Salt Lake Sector 5, Kolkata',
        'customerLatitude': '22.5800',
        'customerLongitude': '88.4200',
        'earningsPaisa': '15000',
        'incentivePaisa': '3000',
        'orderValuePaisa': '350000',
        'storeOtp': '1234',
        'customerOtp': '5678',
      };

      final order = DeliveryOrder.fromNotificationData(payload);

      expect(order.orderId, equals(98412));
      expect(order.orderNumber, equals('#ORD98412'));
      expect(order.storeName, equals('Star Liquor Store'));
      expect(order.storeAddress, equals('Park Street, Kolkata'));
      expect(order.storeLocation.latitude, equals(22.5532));
      expect(order.storeLocation.longitude, equals(88.3512));
      expect(order.customerAddress, equals('Salt Lake Sector 5, Kolkata'));
      expect(order.earningsPaisa, equals(15000));
      expect(order.incentivePaisa, equals(3000));
      expect(order.formattedTotalEarnings, equals('₹180'));
      expect(order.formattedOrderValue, equals('₹3500'));
    });

    test('2. NotificationSoundHelper plays from soundlink and stops on command', () async {
      final soundHelper = NotificationSoundHelper.instance;
      const testSoundUrl = 'https://api.fluup.online/audio/rider_new_delivery.mp3';

      // Initially stopped
      soundHelper.stop();
      expect(soundHelper.isPlaying, isFalse);

      // Play sound
      await soundHelper.play(testSoundUrl);
      expect(soundHelper.isPlaying, isTrue);
      expect(soundHelper.lastPlayedSource, equals(testSoundUrl));

      // Stop sound
      soundHelper.stop();
      expect(soundHelper.isPlaying, isFalse);
    });

    test('3. FcmService handles RIDER_OFFER and activates sound from soundlink', () async {
      final soundHelper = NotificationSoundHelper.instance;
      soundHelper.stop();

      final fcmPayload = {
        'type': 'ORDER',
        'entityId': '78216',
        'event': 'RIDER_OFFER',
        'sound': 'https://storage.googleapis.com/fluup-assets/rider_offer_alert.mp3',
        'storeName': 'Royal Liquor Store',
        'customerAddress': 'Salt Lake, Kolkata',
      };

      await FcmService.instance.handleNotificationPayload(fcmPayload);

      expect(soundHelper.isPlaying, isTrue);
      expect(soundHelper.lastPlayedSource, equals('https://storage.googleapis.com/fluup-assets/rider_offer_alert.mp3'));

      // Clean up sound
      soundHelper.stop();
      expect(soundHelper.isPlaying, isFalse);
    });

    testWidgets('4. NewOrderRequestModal displays order info, countdown badge, and stops sound on Accept', (tester) async {
      final soundHelper = NotificationSoundHelper.instance;
      await soundHelper.play('https://api.fluup.online/audio/test_alert.mp3');
      expect(soundHelper.isPlaying, isTrue);

      final sampleOrder = DeliveryOrder.sample();
      bool acceptedTriggered = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NewOrderRequestModal(
              order: sampleOrder,
              onAccepted: () {
                acceptedTriggered = true;
              },
              onRejected: () {},
            ),
          ),
        ),
      );

      // Verify UI elements
      expect(find.text('New Order Request'), findsOneWidget);
      expect(find.text('Order #ORD78216'), findsOneWidget);
      expect(find.textContaining('Royal Liquor Store'), findsWidgets);
      expect(find.text('45s'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Accept (45s)'), findsOneWidget);

      // Tap Accept
      await tester.tap(find.text('Accept (45s)'));
      await tester.pump();

      expect(acceptedTriggered, isTrue);
      // Sound must be stopped
      expect(soundHelper.isPlaying, isFalse);
    });

    testWidgets('5. NewOrderRequestModal stops sound on Reject', (tester) async {
      final soundHelper = NotificationSoundHelper.instance;
      await soundHelper.play('https://api.fluup.online/audio/test_alert.mp3');
      expect(soundHelper.isPlaying, isTrue);

      final sampleOrder = DeliveryOrder.sample();
      bool rejectedTriggered = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NewOrderRequestModal(
              order: sampleOrder,
              onAccepted: () {},
              onRejected: () {
                rejectedTriggered = true;
              },
            ),
          ),
        ),
      );

      // Tap Reject
      await tester.tap(find.text('Reject'));
      await tester.pump();

      expect(rejectedTriggered, isTrue);
      // Sound must be stopped
      expect(soundHelper.isPlaying, isFalse);
    });
  });
}
