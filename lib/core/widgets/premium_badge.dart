import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final double size;
  final bool showLabel;

  const PremiumBadge({super.key, this.size = 16, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.workspace_premium_rounded, size: size, color: const Color(0xFFF59E0B)),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: TextStyle(
              fontSize: size * 0.65,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ],
    );
  }
}
