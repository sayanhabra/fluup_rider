// modules/profile/screens/profile_screen.dart

import 'dart:io';
import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/modules/auth/models/user_model.dart';
import 'package:adm_rider/modules/auth/providers/auth_provider.dart';
import 'package:adm_rider/modules/profile/screens/bank_payout_details_screen.dart';
import 'package:adm_rider/modules/profile/screens/settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
      Future.microtask(() {
        ref.read(authNotifierProvider.notifier).refreshProfile();
      });
    }
  }

  // ─── Logout Logic ───
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Brand.subtext)),
          ),
          ElevatedButton(
            onPressed: () {
              // Just close the dialog with a result.
              // Do NOT pop the GoRouter stack here.
              Navigator.of(ctx).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Brand.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    // If the user confirmed, trigger the logout.
    // The GoRouter redirect will automatically catch this and navigate to /login.
    if (shouldLogout == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    final userName = user != null
        ? (user.name?.isNotEmpty == true
              ? user.name!
              : (user.phone.isNotEmpty ? user.phone : 'Rider'))
        : 'Vikash Mondal';

    final userId = user != null && user.id > 0 ? 'RID${user.id}' : 'RID4587';
    final isVerified = user == null || user.verificationStatus.isVerified;
    final statusLabel = user != null
        ? (user.verificationStatus.isVerified
              ? 'Verified'
              : (user.verificationStatus.isRejected
                    ? 'Rejected'
                    : (user.verificationStatus.isUnderReview
                          ? 'Under Review'
                          : 'Pending')))
        : 'Verified';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Brand.red,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(authNotifierProvider.notifier).refreshProfile(),
        color: Brand.red,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Rider Avatar & Info Card
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Brand.red, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Brand.red.withValues(alpha: 0.15),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                user?.riderDetails?.selfieUrl != null &&
                                    user!.riderDetails!.selfieUrl!.isNotEmpty
                                ? Image.network(
                                    user.riderDetails!.selfieUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(
                                        Icons.person,
                                        size: 52,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFE2E8F0),
                                    child: const Icon(
                                      Icons.person,
                                      size: 52,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rider ID: $userId',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? Brand.green.withValues(alpha: 0.12)
                            : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVerified ? Icons.check : Icons.access_time,
                            color: isVerified
                                ? Brand.green
                                : Colors.amber.shade800,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isVerified
                                  ? Brand.green
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Profile Menu Items Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Personal Information',
                        onTap: () {
                          _showPersonalInfoDialog(context, user);
                        },
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: Color(0xFFF1F5F9),
                      ),
                      _buildMenuItem(
                        icon: Icons.account_balance_outlined,
                        title: 'Bank & Payout Details',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BankPayoutDetailsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: Color(0xFFF1F5F9),
                      ),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Documents',
                        badge: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? Brand.green.withValues(alpha: 0.12)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isVerified
                                  ? Brand.green
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isVerified
                                    ? 'All rider documents are approved & verified.'
                                    : 'Document verification status: $statusLabel',
                              ),
                            ),
                          );
                        },
                      ),
                      // const Divider(
                      //   height: 1,
                      //   indent: 56,
                      //   color: Color(0xFFF1F5F9),
                      // ),
                      // _buildMenuItem(
                      //   icon: Icons.settings_outlined,
                      //   title: 'App Settings',
                      //   onTap: () {
                      //     Navigator.of(context).push(
                      //       MaterialPageRoute(
                      //         builder: (_) => const SettingsScreen(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: Color(0xFFF1F5F9),
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Support helpline: support@fluup.online',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── LOGOUT BUTTON ───
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, color: Brand.red, size: 20),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Brand.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Brand.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Brand.red.withValues(alpha: 0.05),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF475569), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[badge, const SizedBox(width: 8)],
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
        ],
      ),
    );
  }

  void _showPersonalInfoDialog(BuildContext context, UserModel? user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full Name: ${user?.name ?? "Vikash Mondal"}'),
            const SizedBox(height: 8),
            Text('Phone: ${user?.phone ?? "+91 9999999999"}'),
            const SizedBox(height: 8),
            Text('Email: ${user?.email ?? "Not provided"}'),
            const SizedBox(height: 8),
            Text('Role: ${user?.role ?? "RIDER"}'),
            const SizedBox(height: 8),
            if (user?.gender != null) ...[
              Text('Gender: ${user!.gender}'),
              const SizedBox(height: 8),
            ],
            if (user?.documentNumber != null) ...[
              Text(
                'ID (${user!.documentType ?? "Document"}): ${user.documentNumber}',
              ),
              const SizedBox(height: 8),
            ],
            const Text('City: Kolkata, West Bengal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
