import 'package:adm_rider/core/navigation/main_navigation_shell.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/dashboard/screens/dashboard_screen.dart';
import 'package:adm_rider/modules/dashboard/screens/profile_screen.dart';
import 'package:adm_rider/modules/earnings/screens/earnings_screen.dart';
import 'package:adm_rider/modules/fulfillment/screens/active_delivery_screen.dart';
import 'package:adm_rider/modules/fulfillment/screens/trips_screen.dart';
import 'package:adm_rider/modules/notifications/screens/notification_screen.dart';
import 'package:adm_rider/modules/profile/screens/bank_payout_details_screen.dart';
import 'package:adm_rider/modules/profile/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../modules/auth/screens/login_screen.dart';
import '../../modules/auth/screens/profile_setup_screen.dart';
import '../../modules/auth/screens/splash_screen.dart';
import '../../modules/auth/screens/verification_submission_screen.dart';

class AppRoutes {
  static const String startup = '/startup';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String profileSetup = '/auth/profile-setup';
  static const String verificationSubmission = '/auth/verification-submission';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String riderEarnings = '/rider/earnings';
  static const String riderDeliveries = '/rider/deliveries';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String bankPayout = '/bank-payout';
  static const String activeDelivery = '/active-delivery';
  static const String kycVerification = '/auth/kycVerification';
  static const String underReview = '/profile';
  static const String kycRetry = '/kyc-retry';
  static const String notificationList = '/notificationList';
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}

bool _isAppRoute(String path) {
  return path == AppRoutes.dashboard ||
      path == AppRoutes.riderEarnings ||
      path == AppRoutes.riderDeliveries ||
      path == AppRoutes.profile;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: _RouterRefresh(ref),

    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);
      final currentPath = state.matchedLocation;

      // ─── Loading State ──────────────────────────────────────────
      if (authAsync.isLoading && authAsync.value == null) {
        if (currentPath == AppRoutes.splash) {
          return null;
        }
        return AppRoutes.splash;
      }

      final authState = authAsync.value;

      // ─── Authenticated ──────────────────────────────────────────
      if (authState is AuthAuthenticated) {
        final nextStep = authState.user.nextStep;
        final verificationStatus = authState.user.verificationStatus;
        final isUnderReview =
            nextStep.isUnderReview || verificationStatus.isUnderReview;
        debugPrint('NEXT STEP: ${nextStep.value}');
        debugPrint('VERIFICATION STATUS: ${verificationStatus.value}');
        debugPrint('Current Path: $currentPath');

        // ─── UNDER REVIEW ────────────────────────────────────────
        if (isUnderReview) {
          if (currentPath == AppRoutes.profile ||
              currentPath == AppRoutes.settings ||
              currentPath == AppRoutes.bankPayout ||
              currentPath == AppRoutes.notificationList) {
            return null;
          }
          return AppRoutes.profile;
        }

        // ─── HOME ──────────────────────────────────────────────────
        if (nextStep.isHome) {
          return _isAppRoute(currentPath) ? null : AppRoutes.dashboard;
        }

        // ─── VERIFICATION SUBMISSION ─────────────────────────────
        if (nextStep.isVerificationSubmission) {
          if (currentPath == AppRoutes.kycVerification) return null;
          return AppRoutes.kycVerification;
        }

        // ─── PROFILE SETUP ────────────────────────────────────────
        if (nextStep.isProfileSetup) {
          if (currentPath == AppRoutes.profileSetup) return null;
          return AppRoutes.profileSetup;
        }

        // ─── REJECTED RETRY ──────────────────────────────────────
        if (nextStep.isRejectedRetry) {
          if (currentPath == AppRoutes.kycRetry) return null;
          return AppRoutes.kycRetry;
        }

        return _isAppRoute(currentPath) ? null : AppRoutes.dashboard;
      }

      // ─── OTP / LOGIN FLOW ──────────────────────────────────────
      if (authState is AuthPhoneChecked || authState is AuthOtpSent) {
        return currentPath == AppRoutes.login ? null : AppRoutes.login;
      }

      // ─── UNAUTHENTICATED ──────────────────────────────────────
      if (authState is AuthUnauthenticated || authState == null) {
        if (currentPath == AppRoutes.login || currentPath == AppRoutes.splash) {
          return null;
        }
        return AppRoutes.splash;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.bankPayout, builder: (_, __) => const BankPayoutDetailsScreen()),
      GoRoute(path: AppRoutes.activeDelivery, builder: (_, __) => const ActiveDeliveryScreen()),
      GoRoute(path: AppRoutes.notificationList, builder: (_, __) => const NotificationScreen()),
      GoRoute(path: '/under-review', redirect: (_, __) => AppRoutes.profile),

      // Post-auth status screens
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.verificationSubmission,
        builder: (_, __) => const VerificationSubmissionScreen(),
      ),

      // Main app shell (Bottom Nav Bar)
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationShell(navigationShell: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.riderEarnings,
            builder: (_, __) => const EarningsScreen(),
          ),
          GoRoute(
            path: AppRoutes.riderDeliveries,
            builder: (_, __) => const TripsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
