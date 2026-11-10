// core/config/navigation_config.dart

import 'package:adm_rider/core/config/app_icons.dart';
import 'package:adm_rider/core/config/app_router.dart';
import 'package:adm_rider/core/shared/const/role_enum.dart';
// import 'package:adm_rider/features/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/dashboard/screens/dashboard_screen.dart';
import 'package:adm_rider/modules/dashboard/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Orders Screen'));
}

class SellerProductsScreen extends StatelessWidget {
  const SellerProductsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Products Screen'));
}

class AllCategoryScreen extends StatelessWidget {
  const AllCategoryScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile Screen'));
}

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile Screen'));
}

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile Screen'));
}

class RiderDashboardScreen extends StatelessWidget {
  const RiderDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile Screen'));
}

class RiderDeliveriesScreen extends StatelessWidget {
  const RiderDeliveriesScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile Screen'));
}

class RiderEarningsScreen extends StatelessWidget {
  const RiderEarningsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profile Screen'));
}
// ============================================================
// NAVIGATION ITEM MODEL
// ============================================================

class NavigationItem {
  final String label;
  final String iconPath;
  final String activeIconPath;
  final String route;
  final Widget screen;
  final List<RoleEnum> allowedRoles;

  NavigationItem({
    required this.label,
    required this.iconPath,
    required this.activeIconPath,
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
    return role?.displayName ?? 'User';
  }

  // ============================================================
  // SELLER NAVIGATION
  // ============================================================

  static final List<NavigationItem> sellerItems = [
    NavigationItem(
      label: 'Home',
      iconPath: AppIcons.home,
      activeIconPath: AppIcons.home,
      route: AppRoutes.dashboard,
      screen: const DashboardScreen(),
      allowedRoles: [RoleEnum.seller],
    ),

    NavigationItem(
      label: 'Orders',
      iconPath: AppIcons.cart,
      activeIconPath: AppIcons.cart,
      route: AppRoutes.orders,
      screen: const OrdersScreen(),
      allowedRoles: [RoleEnum.seller],
    ),

    NavigationItem(
      label: 'Products',
      iconPath: AppIcons.all,
      activeIconPath: AppIcons.all,
      route: AppRoutes.products,
      screen: const SellerProductsScreen(),
      allowedRoles: [RoleEnum.seller],
    ),

    NavigationItem(
      label: 'Profile',
      iconPath: AppIcons.profile,
      activeIconPath: AppIcons.profile,
      route: AppRoutes.profile,
      screen: const ProfileScreen(),
      allowedRoles: [RoleEnum.seller],
    ),
  ];

  // ============================================================
  // USER NAVIGATION
  // ============================================================

  static final List<NavigationItem> userItems = [
    NavigationItem(
      label: 'Home',
      iconPath: AppIcons.home,
      activeIconPath: AppIcons.home,
      route: AppRoutes.dashboard,
      screen: const DashboardScreen(),
      allowedRoles: [RoleEnum.user],
    ),

    NavigationItem(
      label: 'Orders',
      iconPath: AppIcons.cart,
      activeIconPath: AppIcons.cart,
      route: AppRoutes.orders,
      screen: const OrdersScreen(),
      allowedRoles: [RoleEnum.user],
    ),

    NavigationItem(
      label: 'Profile',
      iconPath: AppIcons.profile,
      activeIconPath: AppIcons.profile,
      route: AppRoutes.profile,
      screen: const ProfileScreen(),
      allowedRoles: [RoleEnum.user],
    ),
  ];

  // ============================================================
  // RIDER NAVIGATION
  // ============================================================

  static final List<NavigationItem> riderItems = [
    NavigationItem(
      label: 'Home',
      iconPath: AppIcons.home,
      activeIconPath: AppIcons.home,
      route: AppRoutes.dashboard,
      screen: const RiderDashboardScreen(),
      allowedRoles: [RoleEnum.rider],
    ),

    NavigationItem(
      label: 'Deliveries',
      iconPath: AppIcons.cart,
      activeIconPath: AppIcons.cart,
      route: AppRoutes.orders,
      screen: const RiderDeliveriesScreen(),
      allowedRoles: [RoleEnum.rider],
    ),

    NavigationItem(
      label: 'Earnings',
      iconPath: AppIcons.all,
      activeIconPath: AppIcons.all,
      route: AppRoutes.products,
      screen: const RiderEarningsScreen(),
      allowedRoles: [RoleEnum.rider],
    ),

    NavigationItem(
      label: 'Profile',
      iconPath: AppIcons.profile,
      activeIconPath: AppIcons.profile,
      route: AppRoutes.profile,
      screen: const ProfileScreen(),
      allowedRoles: [RoleEnum.rider],
    ),
  ];

  // ============================================================
  // ADMIN NAVIGATION
  // ============================================================

  static final List<NavigationItem> adminItems = [
    NavigationItem(
      label: 'Dashboard',
      iconPath: AppIcons.home,
      activeIconPath: AppIcons.home,
      route: AppRoutes.dashboard,
      screen: const DashboardScreen(),
      allowedRoles: [RoleEnum.admin],
    ),

    NavigationItem(
      label: 'Orders',
      iconPath: AppIcons.cart,
      activeIconPath: AppIcons.cart,
      route: AppRoutes.orders,
      screen: const OrdersScreen(),
      allowedRoles: [RoleEnum.admin],
    ),

    NavigationItem(
      label: 'Profile',
      iconPath: AppIcons.profile,
      activeIconPath: AppIcons.profile,
      route: AppRoutes.profile,
      screen: const ProfileScreen(),
      allowedRoles: [RoleEnum.admin],
    ),
  ];

  // ============================================================
  // GET NAVIGATION BY ROLE
  // ============================================================

  static List<NavigationItem> getItemsForRole(RoleEnum? role) {
    switch (role) {
      case RoleEnum.user:
        return userItems;

      case RoleEnum.seller:
        return sellerItems;

      case RoleEnum.rider:
        return riderItems;

      case RoleEnum.admin:
        return adminItems;

      case null:
        return [];
    }
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

  return null;
});

final navigationItemsProvider = Provider<List<NavigationItem>>((ref) {
  final role = ref.watch(userRoleProvider);

  return NavigationConfig.getItemsForRole(role);
});
