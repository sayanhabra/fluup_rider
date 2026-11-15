import 'package:adm_rider/core/config/app_router.dart';
import 'package:adm_rider/core/shared/const/role_enum.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/dashboard/screens/dashboard_screen.dart';
import 'package:adm_rider/modules/dashboard/screens/profile_screen.dart';
import 'package:adm_rider/modules/earnings/screens/earnings_screen.dart';
import 'package:adm_rider/modules/fulfillment/screens/trips_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// NAVIGATION ITEM MODEL
// ============================================================

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final Widget screen;
  final List<RoleEnum> allowedRoles;

  NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    required this.screen,
    required this.allowedRoles,
  });
}

// ============================================================
// NAVIGATION CONFIG
// ============================================================

class NavigationConfig {
  static String getRoleName(RoleEnum? role) {
    return role?.displayName ?? 'Rider';
  }

  // ============================================================
  // RIDER NAVIGATION (Mockup 4 Tabs: Home, Earnings, Trips, Profile)
  // ============================================================

  static final List<NavigationItem> riderItems = [
    NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: AppRoutes.dashboard,
      screen: const DashboardScreen(),
      allowedRoles: [RoleEnum.rider],
    ),
    NavigationItem(
      label: 'Earnings',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      route: AppRoutes.riderEarnings,
      screen: const EarningsScreen(),
      allowedRoles: [RoleEnum.rider],
    ),
    NavigationItem(
      label: 'Trips',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      route: AppRoutes.riderDeliveries,
      screen: const TripsScreen(),
      allowedRoles: [RoleEnum.rider],
    ),
    NavigationItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: AppRoutes.profile,
      screen: const ProfileScreen(),
      allowedRoles: [RoleEnum.rider],
    ),
  ];

  static List<NavigationItem> getItemsForRole(RoleEnum? role) {
    return riderItems;
  }
}

// ============================================================
// RIVERPOD PROVIDERS
// ============================================================

final userRoleProvider = Provider<RoleEnum?>((ref) {
  final auth = ref.watch(authNotifierProvider);
  final state = auth.asData?.value;
  if (state is AuthAuthenticated) {
    return RoleEnum.fromString(state.user.role);
  }
  return RoleEnum.rider;
});

final navigationItemsProvider = Provider<List<NavigationItem>>((ref) {
  return NavigationConfig.riderItems;
});
