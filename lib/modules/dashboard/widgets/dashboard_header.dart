// modules/dashboard/widgets/dashboard_header.dart

import 'package:adm_rider/core/config/brand.dart';
import 'package:adm_rider/modules/notifications/screens/notification_bell.dart';
import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final String userId;
  final int batteryLevel;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.userId,
    required this.batteryLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Brand.red,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── Left Side: User Info ───
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Greeting Line
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Hello, $userName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 6),

                // ─── Rider ID & Battery Row ───
                Row(
                  children: [
                    Text(
                      'Rider ID: $userId',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Divider dot
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _BatteryIndicator(level: batteryLevel),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ─── Right Side: Notifications ───
          NotificationBell(),
        ],
      ),
    );
  }
}

class _BatteryIndicator extends StatelessWidget {
  final int level;

  const _BatteryIndicator({required this.level});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color = Colors.white70; // Match the Rider ID text color

    if (level >= 80) {
      icon = Icons.battery_full;
    } else if (level >= 50) {
      icon = Icons.battery_5_bar;
    } else if (level >= 30) {
      icon = Icons.battery_3_bar;
    } else if (level >= 15) {
      icon = Icons.battery_2_bar;
      color = Colors.amberAccent; // Warning color
    } else {
      icon = Icons.battery_alert;
      color = Colors.white; // Or a distinct red/white
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$level%',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          icon,
          color: color,
          size: 20,
        ), // Slightly smaller icon to match text
      ],
    );
  }
}
