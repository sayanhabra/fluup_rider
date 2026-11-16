import 'package:flutter/material.dart';

class OtpCodeBoxes extends StatelessWidget {
  final String otp;
  final int length;
  final VoidCallback? onTap;

  const OtpCodeBoxes({
    super.key,
    required this.otp,
    this.length = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(length, (index) {
          final char = index < otp.length ? otp[index] : '';
          final isFilled = char.isNotEmpty;
          final isActive = index == otp.length && otp.length < length;

          return Container(
            width: 58,
            height: 62,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFFF5F5) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isActive || isFilled)
                    ? const Color(0xFFE52535)
                    : const Color(0xFFE2E8F0),
                width: (isActive || isFilled) ? 2.0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? const Color(0xFFE52535).withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isActive ? 8 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isFilled
                ? Text(
                    char,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  )
                : (isActive
                    ? Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE52535),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      )
                    : const SizedBox.shrink()),
          );
        }),
      ),
    );
  }
}

