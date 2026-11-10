// modules/dashboard/screens/dashboard_screen.dart

import 'package:adm_rider/core/config/brand.dart';
import 'package:flutter/material.dart';

class AvailabilityCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const AvailabilityCard({
    super.key,
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAvailable ? 'You are Available' : 'You are Offline',
                style: const TextStyle(
                  color: Brand.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAvailable
                    ? 'You will receive delivery requests'
                    : 'Go online to receive requests',
                style: const TextStyle(color: Brand.subtext, fontSize: 12),
              ),
            ],
          ),
          Switch(
            value: isAvailable,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Brand.green, // Changed to Brand.red
            inactiveThumbColor: Brand.red,
            inactiveTrackColor: Brand.greyLight,
          ),
        ],
      ),
    );
  }
}
