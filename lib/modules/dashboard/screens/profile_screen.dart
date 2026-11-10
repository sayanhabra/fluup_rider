// modules/dashboard/screens/profile_screen.dart

import 'package:adm_rider/core/config/app_theme.dart';
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/core/shared/const/verification_status_enum.dart';
import 'package:adm_rider/core/shared/styles/app_colors.dart';
import 'package:adm_rider/core/shared/styles/app_style.dart';
import 'package:adm_rider/core/shared/widgets/buttons.dart';
import 'package:adm_rider/modules/auth/models/user_model.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final status = user?.verificationStatus ?? VerificationStatus.unknown;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? ColorName.primaryBackgroundDark
          : ColorName.primaryBackgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyle.spaceLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Status Banner ───
              _StatusBanner(status: status),
              const SizedBox(height: AppStyle.spaceXLarge),

              // ─── Profile Header ───
              _ProfileHeader(user: user),
              const SizedBox(height: AppStyle.spaceXLarge),

              // ─── Store / Account Info ───
              _InfoCard(
                title: 'Account Info',
                items: [
                  _InfoRow(label: 'Name', value: user?.name ?? '-'),
                  _InfoRow(label: 'Phone', value: user?.phone ?? '-'),
                  _InfoRow(label: 'Role', value: user?.role ?? '-'),
                ],
              ),
              const SizedBox(height: AppStyle.spaceLarge),

              // ─── Verification Status Detail ───
              _InfoCard(
                title: 'Verification Status',
                items: [
                  _InfoRow(
                    label: 'Status',
                    value: status.name,
                    valueColor: _statusColor(status),
                  ),
                ],
              ),
              const SizedBox(height: AppStyle.spaceXXLarge),

              // ─── Logout ───
              SecondaryButton(
                text: 'Logout',
                horizontalMargin: 0,
                height: 52,
                state: ButtonState.enabled,
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pendingProfile => Brand.grey,
      VerificationStatus.pendingVerification => Brand.warning,
      VerificationStatus.underReview => Brand.warning,
      VerificationStatus.verified => Brand.green,
      VerificationStatus.rejected => Brand.red,
      VerificationStatus.blocked => Brand.greyDark,
      VerificationStatus.unknown => Brand.muted,
    };
  }
}

// ==================== STATUS BANNER ====================

class _StatusBanner extends StatelessWidget {
  final VerificationStatus status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    // VERIFIED → no banner needed
    if (status.isVerified) return const SizedBox.shrink();

    final config = _bannerConfig(context, status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyle.spaceLarge),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: AppStyle.borderRadiusMedium,
        border: Border.all(color: config.borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, color: config.iconColor, size: 28),
              const SizedBox(width: AppStyle.spaceMedium),
              Expanded(
                child: Text(
                  config.title,
                  style: AppStyle.titleMedium.copyWith(
                    color: config.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (config.subtitle != null) ...[
            const SizedBox(height: AppStyle.spaceSmall),
            Text(
              config.subtitle!,
              style: AppStyle.bodySmall.copyWith(color: config.subtitleColor),
            ),
          ],
          if (config.actionLabel != null) ...[
            const SizedBox(height: AppStyle.spaceMedium),
            TextButton(
              onPressed: config.onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                config.actionLabel!,
                style: AppStyle.label.copyWith(
                  color: ColorName.primaryBrandRed,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _BannerConfig _bannerConfig(BuildContext context, VerificationStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (status) {
      VerificationStatus.pendingProfile => _BannerConfig(
        title: 'Complete Your Profile',
        subtitle:
            'Your profile is still pending. Please complete all required information and submit your application.',
        icon: Icons.edit_note_rounded,
        bgColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.08),
        borderColor: isDark
            ? Colors.white24
            : Colors.grey.withValues(alpha: 0.3),
        iconColor: isDark ? Colors.white70 : Colors.grey.shade700,
        textColor: isDark ? Colors.white : Colors.grey.shade800,
        subtitleColor: isDark ? Colors.white70 : Colors.grey.shade600,
        actionLabel: 'Complete Profile →',
        onAction: () {
          // Navigate to profile completion
        },
      ),

      VerificationStatus.pendingVerification => _BannerConfig(
        title: 'Pending Verification',
        subtitle:
            'Your application has been submitted and is waiting for verification.',
        icon: Icons.hourglass_top_rounded,
        bgColor: Colors.orange.withValues(alpha: 0.08),
        borderColor: Colors.orange.withValues(alpha: 0.3),
        iconColor: Colors.orange,
        textColor: isDark ? Colors.orangeAccent : Colors.orange.shade900,
        subtitleColor: isDark ? Colors.orange.shade200 : Colors.orange.shade700,
      ),

      VerificationStatus.underReview => _BannerConfig(
        title: 'Account Under Review',
        subtitle:
            'Our team is reviewing your application. You will be notified once the review is complete.',
        icon: Icons.visibility_rounded,
        bgColor: Colors.orange.withValues(alpha: 0.08),
        borderColor: Colors.orange.withValues(alpha: 0.3),
        iconColor: Colors.orange,
        textColor: isDark ? Colors.orangeAccent : Colors.orange.shade900,
        subtitleColor: isDark ? Colors.orange.shade200 : Colors.orange.shade700,
      ),

      VerificationStatus.verified => _BannerConfig(
        title: 'Account Verified',
        subtitle: 'Your seller account has been verified successfully.',
        icon: Icons.verified_rounded,
        bgColor: Colors.green.withValues(alpha: 0.08),
        borderColor: Colors.green.withValues(alpha: 0.3),
        iconColor: Colors.green,
        textColor: isDark ? Colors.greenAccent : Colors.green.shade900,
        subtitleColor: isDark ? Colors.green.shade200 : Colors.green.shade700,
      ),

      VerificationStatus.rejected => _BannerConfig(
        title: 'Verification Rejected',
        subtitle:
            'Your verification was rejected. Please check the reason and re-submit your documents.',
        icon: Icons.cancel_outlined,
        bgColor: isDark
            ? Colors.redAccent.withValues(alpha: 0.08)
            : ColorName.primaryBrandRed.withValues(alpha: 0.06),
        borderColor: isDark
            ? Colors.redAccent.withValues(alpha: 0.3)
            : ColorName.primaryBrandRed.withValues(alpha: 0.2),
        iconColor: isDark ? Colors.redAccent : ColorName.primaryBrandRed,
        textColor: isDark ? Colors.redAccent : ColorName.primaryBrandRed,
        subtitleColor: isDark ? Colors.red.shade200 : Colors.red.shade700,
        actionLabel: 'Re-upload Documents →',
        onAction: () {
          // Navigate to verification submission
        },
      ),

      VerificationStatus.blocked => _BannerConfig(
        title: 'Account Blocked',
        subtitle:
            'Your seller account has been blocked. Please contact support for assistance.',
        icon: Icons.block_flipped,
        bgColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.08),
        borderColor: isDark
            ? Colors.white24
            : Colors.grey.withValues(alpha: 0.3),
        iconColor: isDark ? Colors.white70 : Colors.grey.shade700,
        textColor: isDark ? Colors.white : Colors.grey.shade800,
        subtitleColor: isDark ? Colors.white70 : Colors.grey.shade600,
        actionLabel: 'Contact Support',
        onAction: () {
          // Open support
        },
      ),

      VerificationStatus.unknown => _BannerConfig(
        title: 'Unknown Status',
        subtitle:
            'We could not determine the current status of your seller account.',
        icon: Icons.help_outline,
        bgColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.08),
        borderColor: isDark
            ? Colors.white24
            : Colors.grey.withValues(alpha: 0.3),
        iconColor: isDark ? Colors.white70 : Colors.grey,
        textColor: isDark ? Colors.white : Colors.black87,
        subtitleColor: isDark ? Colors.white70 : Colors.grey,
      ),
    };
  }
}

class _BannerConfig {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final Color subtitleColor;

  _BannerConfig({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.subtitleColor,
  });
}

// ==================== PROFILE HEADER ====================

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;

  const _ProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: ColorName.primaryBrandRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: user?.profileImage != null
                ? ClipOval(
                    child: Image.network(
                      user!.profileImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.storefront,
                    size: 40,
                    color: ColorName.primaryBrandRed,
                  ),
          ),
          const SizedBox(height: AppStyle.spaceMedium),
          Text(
            user?.name ?? 'Seller',
            style: AppStyle.heading4.copyWith(
              color: Theme.of(context).textTheme.displayLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+91 ${user?.phone ?? ''}',
            style: AppStyle.bodyMedium.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== INFO CARD ====================

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyle.spaceLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppStyle.borderRadiusMedium,
        border: Border.all(color: context.customColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyle.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppStyle.spaceMedium),
          const Divider(height: 1),
          const SizedBox(height: AppStyle.spaceMedium),
          ...items,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyle.spaceSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppStyle.bodyMedium.copyWith(
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: AppStyle.bodyMedium.copyWith(
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
