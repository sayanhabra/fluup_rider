import 'package:adm_rider/modules/auth/screens/login_screen.dart';
import 'package:adm_rider/modules/auth/screens/splash_screen.dart';
import 'package:adm_rider/modules/dashboard/screens/profile_screen.dart';
import 'package:adm_rider/modules/earnings/models/earnings_model.dart';
import 'package:adm_rider/modules/earnings/providers/earnings_provider.dart';
import 'package:adm_rider/modules/earnings/screens/earnings_screen.dart';
import 'package:adm_rider/modules/fulfillment/models/trip_model.dart';
import 'package:adm_rider/modules/fulfillment/screens/trip_details_screen.dart';
import 'package:adm_rider/modules/fulfillment/screens/trips_screen.dart';
import 'package:adm_rider/modules/profile/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestEarningsNotifier extends EarningsNotifier {
  @override
  EarningsState build() {
    return EarningsState(
      filter: EarningsFilter.today,
      summary: EarningsSummary.sampleToday(),
    );
  }
}

void main() {
  testWidgets('Screen 1: Splash screen renders Fluup Rider logo and partner title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.text('Fluup'), findsOneWidget);
    expect(find.text('Rider'), findsOneWidget);
    expect(find.text('Alcohol Delivery Partner'), findsOneWidget);
  });

  testWidgets('Screen 2: Rider Login screen renders header, inputs, and continue button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Rider Login'), findsOneWidget);
    expect(find.text('Enter mobile number'), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Screen 12: Earnings screen renders hero earnings and filters', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          earningsProvider.overrideWith(() => _TestEarningsNotifier()),
        ],
        child: const MaterialApp(
          home: EarningsScreen(),
        ),
      ),
    );

    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('Trip Earnings'), findsOneWidget);
    expect(find.text('Incentives'), findsOneWidget);
    expect(find.text('Daily Earnings (Last 7 Days)'), findsOneWidget);
  });

  testWidgets('Screen 13: Trips screen renders filter tabs and trip list', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TripsScreen(),
        ),
      ),
    );

    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Cancelled'), findsWidgets);
  });

  testWidgets('Screen 14: Trip Details screen renders order milestone timeline & breakdown', (tester) async {
    final sampleTrip = TripItem.getSampleTrips().first;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TripDetailsScreen(trip: sampleTrip),
        ),
      ),
    );

    expect(find.text('Trip Details'), findsOneWidget);
    expect(find.text('Order ${sampleTrip.orderNumber}'), findsOneWidget);
    expect(find.text('Order Accepted'), findsOneWidget);
    expect(find.text('Delivery Completed'), findsOneWidget);
    expect(find.text('Earnings Details'), findsOneWidget);
    expect(find.text('Total Earned'), findsOneWidget);
  });

  testWidgets('Screen 15: Profile screen renders rider card, verified badge, and menu', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Vikash Mondal'), findsOneWidget);
    expect(find.text('Verified'), findsWidgets);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Bank & Payout Details'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('App Settings'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
  });

  testWidgets('Screen 16: Settings screen renders notification, vibration, and logout options', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Sound & Vibration'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Location Access'), findsOneWidget);
    expect(find.text('v2.8.2+27'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });
}
