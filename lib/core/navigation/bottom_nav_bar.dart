// core/shared/widgets/bottom_nav_bar.dart

import 'package:adm_rider/core/navigation/navigation_config.dart';
import 'package:adm_rider/core/shared/widgets/svg_icon.dart';
import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(navigationItemsProvider);

    // Derive selected index from current route — always in sync with URL
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = items.indexWhere((item) => item.route == location);
    final effectiveIndex = selectedIndex == -1 ? 0 : selectedIndex;

    if (items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: effectiveIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: surfaceColor,
          selectedItemColor: ColorName.primaryBrandRed,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          elevation: 0,
          onTap: (index) {
            if (index == effectiveIndex) return;
            final route = items[index].route;
            context.go(route);
          },
          items: items.map((item) {
            final isSelected = items.indexOf(item) == effectiveIndex;
            return BottomNavigationBarItem(
              icon: SvgNavIcon(
                assetPath: item.iconPath,
                color: isSelected ? ColorName.primaryBrandRed : Colors.grey,
                size: 24,
              ),
              activeIcon: SvgNavIcon(
                assetPath: item.activeIconPath,
                color: ColorName.primaryBrandRed,
                size: 24,
                isActive: true,
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}
