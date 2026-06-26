import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  static const _keyPremiumStatus = 'premium_active';
  static const _keyPurchaseToken = 'purchase_token';
  static const _keyProductId = 'premium_monthly';
  static const _keyPdfExportCount = 'pdf_export_count';
  static const _keyPdfExportMonth = 'pdf_export_month';
  static const _keyBackupExportCount = 'backup_export_count';
  static const _keyBackupExportMonth = 'backup_export_month';
  static const _keyLastVerification = 'last_premium_verification';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isStoreAvailable = false;
  ProductDetails? _product;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  static const int maxPdfExportsPerMonth = 2;
  static const int maxBackupExportsPerMonth = 2;

  bool get canExportPdf {
    if (_isPremium) return true;
    return _pdfExportCount < maxPdfExportsPerMonth;
  }

  int get pdfExportCount => _pdfExportCount;

  bool get canExportBackup {
    if (_isPremium) return true;
    return _backupExportCount < maxBackupExportsPerMonth;
  }

  int get backupExportCount => _backupExportCount;

  int _pdfExportCount = 0;
  int _backupExportCount = 0;

  ProductDetails? get product => _product;

  Future<void> init() async {
    _isPremium = false;

    _isStoreAvailable = await _iap.isAvailable();
    if (!_isStoreAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('IAP stream error: $error'),
    );

    await _loadLocalState();
    await _verifyWithStore();
    await _loadCounters();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_keyPremiumStatus) ?? false;
  }

  Future<void> _saveLocalState(bool active, {String? token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPremiumStatus, active);
    if (token != null) {
      await prefs.setString(_keyPurchaseToken, token);
    }
    _isPremium = active;
  }

  Future<void> _verifyWithStore() async {
    if (!_isStoreAvailable) return;

    try {
      final completer = Completer<bool>();
      late StreamSubscription<List<PurchaseDetails>> sub;

      sub = _iap.purchaseStream.listen(
        (purchases) {
          for (final purchase in purchases) {
            if (purchase.productID == _keyProductId &&
                (purchase.status == PurchaseStatus.purchased ||
                 purchase.status == PurchaseStatus.restored)) {
              _saveLocalState(true, token: purchase.purchaseID);
              if (!completer.isCompleted) completer.complete(true);
              sub.cancel();
              return;
            }
          }
          if (!completer.isCompleted) completer.complete(false);
          sub.cancel();
        },
        onError: (e) {
          if (!completer.isCompleted) completer.complete(false);
          sub.cancel();
        },
      );

      await _iap.restorePurchases();
      final found = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          sub.cancel();
          return false;
        },
      );

      if (!found && _isPremium) {
        await _saveLocalState(false);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastVerification, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Store verification error: $e');
    }
  }

  Future<void> _periodicReVerification() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_keyLastVerification);
    if (lastStr != null) {
      final last = DateTime.parse(lastStr);
      if (DateTime.now().difference(last).inHours < 24) return;
    }
    await _verifyWithStore();
  }

  Future<void> _loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month}';

    final pdfMonth = prefs.getString(_keyPdfExportMonth) ?? '';
    if (pdfMonth == currentMonth) {
      _pdfExportCount = prefs.getInt(_keyPdfExportCount) ?? 0;
    } else {
      _pdfExportCount = 0;
      await prefs.setInt(_keyPdfExportCount, 0);
      await prefs.setString(_keyPdfExportMonth, currentMonth);
    }

    final backupMonth = prefs.getString(_keyBackupExportMonth) ?? '';
    if (backupMonth == currentMonth) {
      _backupExportCount = prefs.getInt(_keyBackupExportCount) ?? 0;
    } else {
      _backupExportCount = 0;
      await prefs.setInt(_keyBackupExportCount, 0);
      await prefs.setString(_keyBackupExportMonth, currentMonth);
    }
  }

  Future<void> incrementPdfExport() async {
    if (_isPremium) return;
    _pdfExportCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPdfExportCount, _pdfExportCount);
  }

  Future<void> incrementBackupExport() async {
    if (_isPremium) return;
    _backupExportCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBackupExportCount, _backupExportCount);
  }

  int get remainingPdfExports {
    if (_isPremium) return 999;
    return maxPdfExportsPerMonth - _pdfExportCount;
  }

  int get remainingBackupExports {
    if (_isPremium) return 999;
    return maxBackupExportsPerMonth - _backupExportCount;
  }

  Future<List<ProductDetails>> getAvailableProducts() async {
    if (!_isStoreAvailable) return [];
    try {
      final response = await _iap.queryProductDetails({_keyProductId});
      if (response.error != null) {
        debugPrint('Query error: ${response.error}');
        return [];
      }
      _product = response.productDetails.isNotEmpty
          ? response.productDetails.first
          : null;
      return response.productDetails;
    } catch (e) {
      debugPrint('Get products error: $e');
      return [];
    }
  }

  Future<bool> subscribe() async {
    if (!_isStoreAvailable || _product == null) return false;
    try {
      final param = PurchaseParam(productDetails: _product!);
      final pending = _iap.buyNonConsumable(purchaseParam: param);
      return pending;
    } catch (e) {
      debugPrint('Subscribe error: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    await _verifyWithStore();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != _keyProductId) continue;

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _saveLocalState(true, token: purchase.purchaseID);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.canceled) {
        debugPrint('Purchase canceled');
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> checkPremiumStatus() async {
    await _periodicReVerification();
  }
}
