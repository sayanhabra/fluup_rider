import 'package:adm_rider/core/config/app_router.dart';
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/navigation/navigation_config.dart';
import 'package:adm_rider/core/shared/widgets/toast.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(navigationItemsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isUnderReview = currentUser != null &&
        (currentUser.verificationStatus.isUnderReview ||
            currentUser.nextStep.isUnderReview);

    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = items.indexWhere((item) => item.route == location);
    final effectiveIndex = selectedIndex == -1 ? 0 : selectedIndex;

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == effectiveIndex;
              final isTabEnabled =
                  !isUnderReview || item.route == AppRoutes.profile;

              final Color activeColor =
                  isSelected ? Brand.red : const Color(0xFF64748B);
              final Color tabColor =
                  isTabEnabled ? activeColor : const Color(0xFFCBD5E1);

              return InkWell(
                onTap: () {
                  if (!isTabEnabled) {
                    AppToast.info(
                      title: 'Account Under Review',
                      message:
                          'Verification is in progress. Other tabs will unlock once approved.',
                    );
                    return;
                  }
                  if (!isSelected) {
                    context.go(item.route);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: tabColor,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: tabColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
