import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_badge.dart';
import '../../../services/subscription_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = false;
  bool _isRestoring = false;

  final _features = const [
    _Feature(Icons.analytics_rounded, 'Estadísticas avanzadas', 'PDF de reportes y utilidades por categoría'),
    _Feature(Icons.inventory_2_rounded, 'Movimientos de inventario', 'Historial completo de entradas y salidas'),
    _Feature(Icons.style_rounded, 'Variaciones y presentaciones', 'Gestiona packs, tamaños y presentaciones'),
    _Feature(Icons.cloud_upload_rounded, 'Respaldo en Google Drive', 'Copia automática diaria en la nube'),
    _Feature(Icons.backup_rounded, 'Exportar respaldos locales', 'Más de 2 exportaciones mensuales'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    await SubscriptionService.instance.getAvailableProducts();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = SubscriptionService.instance.isPremium;
    final product = SubscriptionService.instance.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        actions: [
          if (!isPremium)
            TextButton(
              onPressed: _isRestoring ? null : _restore,
              child: _isRestoring
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Restaurar', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          const Center(child: PremiumBadge(size: 48, showLabel: true)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              isPremium ? 'Tu Cuenta es Premium' : 'Desbloquea Todo el Potencial',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isPremium
                  ? 'Tienes acceso a todas las funciones avanzadas'
                  : 'Accede a funciones exclusivas para llevar tu negocio al siguiente nivel',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          ..._features.map((f) => _FeatureTile(feature: f, isPremium: isPremium)),
          const SizedBox(height: 32),
          if (!isPremium) ...[
            if (product != null)
              Card(
                margin: EdgeInsets.zero,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Suscripción Mensual',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.price,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      Text(
                        '/ mes',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _subscribe,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Suscribirme Ahora',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cancela cuando quieras. Vinculado a tu cuenta de Google.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Cargando planes...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    try {
      final success = await SubscriptionService.instance.subscribe();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo iniciar la suscripción. Verifica tu conexión.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isRestoring = true);
    try {
      await SubscriptionService.instance.restorePurchases();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              SubscriptionService.instance.isPremium
                  ? '¡Suscripción restaurada exitosamente!'
                  : 'No se encontró una suscripción activa',
            ),
            backgroundColor: SubscriptionService.instance.isPremium
                ? AppTheme.successColor
                : AppTheme.warningColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  const _Feature(this.icon, this.title, this.description);
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  final bool isPremium;

  const _FeatureTile({required this.feature, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        child: Icon(feature.icon, color: const Color(0xFFF59E0B), size: 20),
      ),
      title: Text(feature.title, style: AppTextStyles.bodyBold),
      subtitle: Text(feature.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: isPremium
          ? const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20)
          : Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
    );
  }
}
