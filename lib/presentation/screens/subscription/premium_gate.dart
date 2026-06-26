import 'package:flutter/material.dart';
import '../../../core/widgets/premium_badge.dart';
import '../../../services/subscription_service.dart';
import 'premium_screen.dart';

class PremiumGate extends StatelessWidget {
  final Widget child;
  final String featureName;
  final bool showBadge;

  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
    this.showBadge = true,
  });

  static void showPremiumDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.workspace_premium_rounded, size: 48, color: Color(0xFFF59E0B)),
        title: Text(featureName),
        content: const Text(
          'Esta función es exclusiva para usuarios Premium. '
          'Suscríbete para desbloquear todas las funciones avanzadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (SubscriptionService.instance.isPremium) return child;

    return Stack(
      children: [
        Opacity(opacity: 0.3, child: AbsorbPointer(child: child)),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showPremiumDialog(context, featureName),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PremiumBadge(size: 20),
                      const SizedBox(width: 8),
                      Text(
                        featureName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
