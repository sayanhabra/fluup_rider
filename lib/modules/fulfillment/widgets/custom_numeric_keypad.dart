import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomNumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;

  const CustomNumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
  });

  Widget _buildKey(String label, {VoidCallback? onTap, Widget? customChild}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (onTap != null) {
                onTap();
              } else {
                onDigitPressed(label);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: customChild ??
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          Row(
            children: [
              const Expanded(child: SizedBox(height: 52)),
              _buildKey('0'),
              _buildKey(
                'backspace',
                onTap: onBackspacePressed,
                customChild: const Icon(
                  Icons.backspace_outlined,
                  size: 24,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

