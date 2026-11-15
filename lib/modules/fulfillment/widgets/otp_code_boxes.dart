import 'package:flutter/material.dart';

class OtpCodeBoxes extends StatelessWidget {
  final String otp;
  final int length;

  const OtpCodeBoxes({
    super.key,
    required this.otp,
    this.length = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final char = index < otp.length ? otp[index] : '';
        final isFilled = char.isNotEmpty;

        return Container(
          width: 58,
          height: 62,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFilled ? const Color(0xFFE52535) : const Color(0xFFE2E8F0),
              width: isFilled ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            char,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        );
      }),
    );
  }
}

