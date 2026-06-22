import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/entities/supplier.dart';

class SupplierProfileScreen extends StatefulWidget {
  final int supplierId;

  const SupplierProfileScreen({super.key, required this.supplierId});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  Supplier? _supplier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final supplier = await DatabaseHelper.getSupplierById(widget.supplierId);
    setState(() {
      _supplier = supplier;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_supplier == null) return Scaffold(
      appBar: AppBar(title: const Text('Proveedor')),
      body: const Center(child: Text('Proveedor no encontrado')),
    );

    final supplier = _supplier!;

    return Scaffold(
      appBar: AppBar(title: Text(supplier.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(
                      supplier.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(supplier.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  if (supplier.phone != null)
                    Text(supplier.phone!, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            // Contact info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (supplier.contactPerson != null)
                        _infoRow(Icons.person, 'Contacto', supplier.contactPerson!),
                      if (supplier.email != null)
                        _infoRow(Icons.email, 'Email', supplier.email!),
                      if (supplier.address != null)
                        _infoRow(Icons.location_on, 'Dirección', supplier.address!),
                      _infoRow(Icons.date_range, 'Registrado', Formatters.formatDate(supplier.createdAt)),
                    ],
                  ),
                ),
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _statCard('Total Compras', Formatters.formatCurrency(supplier.totalPurchases), AppTheme.primaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
