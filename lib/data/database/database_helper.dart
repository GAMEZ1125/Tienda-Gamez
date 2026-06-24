import 'dart:io' as io;
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/entities/purchase_order_item.dart';
import '../../domain/entities/supplier_payment.dart';
import '../../domain/entities/product_variation.dart';
import '../../domain/entities/supplier_debt.dart';
import '../../domain/entities/supplier_debt_payment.dart';
import '../../services/realtime_backup_service.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        cost REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        minStock INTEGER DEFAULT 5,
        category TEXT,
        barcode TEXT,
        imagePath TEXT,
        isActive INTEGER DEFAULT 1,
        taxRate REAL DEFAULT 0.18,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        discount REAL NOT NULL,
        total REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        customerId INTEGER,
        customerName TEXT,
        notes TEXT,
        status TEXT DEFAULT 'completed'
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        barcode TEXT,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        taxRate REAL DEFAULT 0.18,
        FOREIGN KEY (saleId) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        totalSpent REAL DEFAULT 0,
        purchaseCount INTEGER DEFAULT 0,
        lastPurchase TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        concept TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        supplierId INTEGER,
        supplierName TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        contactPerson TEXT,
        totalPurchases REAL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        customerName TEXT NOT NULL,
        amount REAL NOT NULL,
        paidAmount REAL DEFAULT 0,
        dueDate TEXT NOT NULL,
        paidDate TEXT,
        status TEXT DEFAULT 'pending',
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debtId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        method TEXT DEFAULT 'Efectivo',
        notes TEXT,
        FOREIGN KEY (debtId) REFERENCES debts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE product_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER NOT NULL,
        supplierName TEXT NOT NULL,
        date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        paymentType TEXT DEFAULT 'cash',
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitCost REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (orderId) REFERENCES purchase_orders(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE supplier_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER NOT NULL,
        supplierName TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        method TEXT DEFAULT 'Efectivo',
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE supplier_debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER NOT NULL,
        supplierName TEXT NOT NULL,
        purchaseOrderId INTEGER,
        amount REAL NOT NULL,
        paidAmount REAL DEFAULT 0,
        dueDate TEXT NOT NULL,
        paidDate TEXT,
        status TEXT DEFAULT 'pending',
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (supplierId) REFERENCES suppliers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE supplier_debt_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierDebtId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        method TEXT DEFAULT 'Efectivo',
        notes TEXT,
        FOREIGN KEY (supplierDebtId) REFERENCES supplier_debts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE product_variations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        name TEXT NOT NULL,
        barcode TEXT,
        price REAL NOT NULL,
        cost REAL NOT NULL DEFAULT 0,
        stock INTEGER DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    final defaultCategories = [
      'Videojuegos', 'Consolas', 'Accesorios',
      'Tarjetas de Regalo', 'Merchandising', 'Otros',
    ];
    for (final cat in defaultCategories) {
      await db.insert('product_categories', {
        'name': cat,
        'description': null,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN hasTax INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE sale_items ADD COLUMN taxRate REAL NOT NULL DEFAULT 0.18');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplierId INTEGER NOT NULL,
          supplierName TEXT NOT NULL,
          date TEXT NOT NULL,
          subtotal REAL NOT NULL,
          tax REAL NOT NULL,
          total REAL NOT NULL,
          status TEXT DEFAULT 'pending',
          notes TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          orderId INTEGER,
          productId INTEGER NOT NULL,
          productName TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          unitCost REAL NOT NULL,
          subtotal REAL NOT NULL,
          FOREIGN KEY (orderId) REFERENCES purchase_orders(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS supplier_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplierId INTEGER NOT NULL,
          supplierName TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          method TEXT DEFAULT 'Efectivo',
          notes TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
      // Insert default categories
      final existing = await db.query('product_categories');
      if (existing.isEmpty) {
        final defaultCategories = [
          'Videojuegos', 'Consolas', 'Accesorios',
          'Tarjetas de Regalo', 'Merchandising', 'Otros',
        ];
        for (final cat in defaultCategories) {
          await db.insert('product_categories', {
            'name': cat,
            'description': null,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE products ADD COLUMN taxRate REAL DEFAULT 0.0');
      await db.execute('UPDATE products SET taxRate = 0.18 WHERE hasTax = 1');
      await db.execute('UPDATE products SET taxRate = 0.0 WHERE hasTax = 0');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_variations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER NOT NULL,
          name TEXT NOT NULL,
          barcode TEXT,
          price REAL NOT NULL,
          cost REAL NOT NULL DEFAULT 0,
          stock INTEGER DEFAULT 0,
          isActive INTEGER DEFAULT 1,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (productId) REFERENCES products(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS supplier_debts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplierId INTEGER NOT NULL,
          supplierName TEXT NOT NULL,
          purchaseOrderId INTEGER,
          amount REAL NOT NULL,
          paidAmount REAL DEFAULT 0,
          dueDate TEXT NOT NULL,
          paidDate TEXT,
          status TEXT DEFAULT 'pending',
          notes TEXT,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (supplierId) REFERENCES suppliers(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS supplier_debt_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplierDebtId INTEGER NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          method TEXT DEFAULT 'Efectivo',
          notes TEXT,
          FOREIGN KEY (supplierDebtId) REFERENCES supplier_debts(id) ON DELETE CASCADE
        )
      ''');
      // Add paymentType to purchase_orders if not exists
      final columns = await db.rawQuery('PRAGMA table_info(purchase_orders)');
      final hasPaymentType = columns.any((c) => c['name'] == 'paymentType');
      if (!hasPaymentType) {
        await db.execute("ALTER TABLE purchase_orders ADD COLUMN paymentType TEXT DEFAULT 'cash'");
      }
    }
  }

  // ==================== PRODUCTS ====================

  static Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', where: 'isActive = 1', orderBy: 'name');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<List<Product>> getAllProductsIncludingInactive() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  static Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query('products', where: 'barcode = ? AND isActive = 1', whereArgs: [barcode]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  static Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: '(name LIKE ? OR category LIKE ? OR barcode LIKE ?) AND isActive = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'stock <= minStock AND isActive = 1',
      orderBy: 'stock ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'category = ? AND isActive = 1',
      whereArgs: [category],
      orderBy: 'name',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<int> insertProduct(Product product) async {
    final db = await database;
    final result = await db.insert('products', product.toMap());
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> updateProduct(Product product) async {
    final db = await database;
    final result = await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  /// Inserts multiple products in a single transaction (batch insert).
  ///
  /// Returns the number of products successfully inserted.
  static Future<int> insertProductsBatch(List<Product> products) async {
    final db = await database;
    var count = 0;
    await db.transaction((txn) async {
      for (final product in products) {
        await txn.insert('products', product.toMap());
        count++;
      }
    });
    RealtimeBackupService.instance.onDatabaseChanged();
    return count;
  }

  static Future<int> deleteProduct(int id) async {
    final db = await database;
    final result = await db.update('products', {'isActive': 0, 'updatedAt': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<void> reduceStock(int id, int quantity) async {
    final db = await database;
    await db.rawUpdate('UPDATE products SET stock = stock - ?, updatedAt = ? WHERE id = ?', [quantity, DateTime.now().toIso8601String(), id]);
  }

  static Future<void> increaseStock(int id, int quantity) async {
    final db = await database;
    await db.rawUpdate('UPDATE products SET stock = stock + ?, updatedAt = ? WHERE id = ?', [quantity, DateTime.now().toIso8601String(), id]);
  }

  // ==================== SALES ====================

  static Future<List<Sale>> getAllSales() async {
    final db = await database;
    final maps = await db.query('sales', orderBy: 'date DESC');
    return await _loadSaleItems(maps);
  }

  static Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'sales',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return await _loadSaleItems(maps);
  }

  static Future<List<Sale>> getTodaySales() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getSalesByDateRange(start, end);
  }

  static Future<List<Sale>> getSalesByCustomer(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'sales',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return await _loadSaleItems(maps);
  }

  static Future<Sale?> getSaleById(int id) async {
    final db = await database;
    final maps = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final sale = Sale.fromMap(maps.first);
    final items = await db.query('sale_items', where: 'saleId = ?', whereArgs: [id]);
    return sale.copyWith(items: items.map((item) => SaleItem.fromMap(item)).toList());
  }

  static Future<int> insertSale(Sale sale) async {
    final db = await database;
    final id = await db.insert('sales', sale.toMap());

    for (final item in sale.items) {
      await db.insert('sale_items', item.copyWith(saleId: id).toMap());
      await reduceStock(item.productId, item.quantity);
    }

    // Update customer stats
    if (sale.customerId != null) {
      final customer = await getCustomerById(sale.customerId!);
      if (customer != null) {
        await updateCustomer(customer.copyWith(
          totalSpent: customer.totalSpent + sale.total,
          purchaseCount: customer.purchaseCount + 1,
          lastPurchase: sale.date,
        ));
      }

      // Auto-create debt for credit sales with 30-day due date
      if (sale.paymentMethod == 'Crédito') {
        final debt = Debt(
          customerId: sale.customerId!,
          customerName: sale.customerName ?? 'Cliente #${sale.customerId}',
          amount: sale.total,
          dueDate: sale.date.add(const Duration(days: 30)),
          notes: 'Venta a crédito #$id — ${sale.items.length} producto(s)',
        );
        await db.insert('debts', debt.toMap());
      }
    }

    RealtimeBackupService.instance.onDatabaseChanged();
    return id;
  }

  static Future<double> getTotalSalesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total), 0) as total FROM sales WHERE date >= ? AND date <= ? AND status = ?',
      [start.toIso8601String(), end.toIso8601String(), 'completed'],
    );
    return (result.first['total'] as num).toDouble();
  }

  static Future<Map<String, double>> getSalesByPaymentMethod(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT paymentMethod, COALESCE(SUM(total), 0) as total FROM sales WHERE date >= ? AND date <= ? AND status = ? GROUP BY paymentMethod',
      [start.toIso8601String(), end.toIso8601String(), 'completed'],
    );
    final map = <String, double>{};
    for (final row in result) {
      map[row['paymentMethod'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  static Future<List<Map<String, dynamic>>> getTopProducts(DateTime start, DateTime end, {int limit = 5}) async {
    final db = await database;
    return await db.rawQuery(
      '''SELECT si.productId, si.productName, SUM(si.quantity) as totalQuantity, 
         SUM(si.subtotal) as totalAmount 
         FROM sale_items si 
         JOIN sales s ON si.saleId = s.id 
         WHERE s.date >= ? AND s.date <= ? AND s.status = ? 
         GROUP BY si.productId 
         ORDER BY totalQuantity DESC 
         LIMIT ?''',
      [start.toIso8601String(), end.toIso8601String(), 'completed', limit],
    );
  }

  static Future<List<Map<String, dynamic>>> getDailySales(DateTime start, DateTime end) async {
    final db = await database;
    return await db.rawQuery(
      '''SELECT DATE(date) as day, SUM(total) as total, COUNT(*) as count 
         FROM sales 
         WHERE date >= ? AND date <= ? AND status = ? 
         GROUP BY DATE(date) 
         ORDER BY day''',
      [start.toIso8601String(), end.toIso8601String(), 'completed'],
    );
  }

  static Future<List<Sale>> _loadSaleItems(List<Map<String, dynamic>> saleMaps) async {
    final db = await database;
    final sales = <Sale>[];
    for (final map in saleMaps) {
      final sale = Sale.fromMap(map);
      final items = await db.query('sale_items', where: 'saleId = ?', whereArgs: [sale.id]);
      sales.add(sale.copyWith(items: items.map((item) => SaleItem.fromMap(item)).toList()));
    }
    return sales;
  }

  // ==================== CUSTOMERS ====================

  static Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'name');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  static Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  static Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  static Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    final result = await db.insert('customers', customer.toMap());
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    final result = await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> deleteCustomer(int id) async {
    final db = await database;
    final result = await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  // ==================== EXPENSES ====================

  static Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'date DESC');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  static Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  static Future<List<Expense>> getExpensesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  static Future<double> getTotalExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date >= ? AND date <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num).toDouble();
  }

  static Future<Map<String, double>> getExpensesGroupedByCategory(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, COALESCE(SUM(amount), 0) as total FROM expenses WHERE date >= ? AND date <= ? GROUP BY category',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final map = <String, double>{};
    for (final row in result) {
      map[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  static Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final result = await db.insert('expenses', expense.toMap());
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> updateExpense(Expense expense) async {
    final db = await database;
    final result = await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> deleteExpense(int id) async {
    final db = await database;
    final result = await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  // ==================== SUPPLIERS ====================

  static Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final maps = await db.query('suppliers', orderBy: 'name');
    return maps.map((map) => Supplier.fromMap(map)).toList();
  }

  static Future<Supplier?> getSupplierById(int id) async {
    final db = await database;
    final maps = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Supplier.fromMap(maps.first);
  }

  static Future<List<Supplier>> searchSuppliers(String query) async {
    final db = await database;
    final maps = await db.query(
      'suppliers',
      where: 'name LIKE ? OR phone LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name',
    );
    return maps.map((map) => Supplier.fromMap(map)).toList();
  }

  static Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    final result = await db.insert('suppliers', supplier.toMap());
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    final result = await db.update('suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> deleteSupplier(int id) async {
    final db = await database;
    final result = await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  // ==================== DEBTS ====================

  static Future<List<Debt>> getAllDebts() async {
    final db = await database;
    final maps = await db.query('debts', orderBy: 'dueDate ASC');
    return await _loadDebtPayments(maps);
  }

  static Future<List<Debt>> getDebtsByStatus(String status) async {
    final db = await database;
    final maps = await db.query('debts', where: 'status = ?', whereArgs: [status], orderBy: 'dueDate ASC');
    return await _loadDebtPayments(maps);
  }

  static Future<List<Debt>> getDebtsByCustomer(int customerId) async {
    final db = await database;
    final maps = await db.query('debts', where: 'customerId = ?', whereArgs: [customerId], orderBy: 'dueDate ASC');
    return await _loadDebtPayments(maps);
  }

  static Future<List<Debt>> getPendingDebts() async {
    final db = await database;
    final maps = await db.query(
      'debts',
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'partial'],
      orderBy: 'dueDate ASC',
    );
    return await _loadDebtPayments(maps);
  }

  static Future<Debt?> getDebtById(int id) async {
    final db = await database;
    final maps = await db.query('debts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final debt = Debt.fromMap(maps.first);
    final payments = await db.query('payments', where: 'debtId = ?', whereArgs: [id], orderBy: 'date DESC');
    return debt.copyWith(payments: payments.map((p) => Payment.fromMap(p)).toList());
  }

  static Future<int> insertDebt(Debt debt) async {
    final db = await database;
    final result = await db.insert('debts', debt.toMap());
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> updateDebt(Debt debt) async {
    final db = await database;
    final result = await db.update('debts', debt.toMap(), where: 'id = ?', whereArgs: [debt.id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> deleteDebt(int id) async {
    final db = await database;
    final result = await db.delete('debts', where: 'id = ?', whereArgs: [id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<double> getTotalPendingDebts() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount - paidAmount), 0) as total FROM debts WHERE status IN (?, ?)',
      ['pending', 'partial'],
    );
    return (result.first['total'] as num).toDouble();
  }

  static Future<List<Debt>> getDebtsDueSoon(int days) async {
    final db = await database;
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    final maps = await db.query(
      'debts',
      where: 'dueDate >= ? AND dueDate <= ? AND status IN (?, ?)',
      whereArgs: [now.toIso8601String(), future.toIso8601String(), 'pending', 'partial'],
      orderBy: 'dueDate ASC',
    );
    return await _loadDebtPayments(maps);
  }

  static Future<List<Debt>> getOverdueDebts() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'debts',
      where: 'dueDate < ? AND status IN (?, ?)',
      whereArgs: [now, 'pending', 'partial'],
      orderBy: 'dueDate ASC',
    );
    return await _loadDebtPayments(maps);
  }

  static Future<List<Debt>> _loadDebtPayments(List<Map<String, dynamic>> debtMaps) async {
    final db = await database;
    final debts = <Debt>[];
    for (final map in debtMaps) {
      final debt = Debt.fromMap(map);
      final payments = await db.query('payments', where: 'debtId = ?', whereArgs: [debt.id], orderBy: 'date DESC');
      debts.add(debt.copyWith(payments: payments.map((p) => Payment.fromMap(p)).toList()));
    }
    return debts;
  }

  // ==================== PAYMENTS ====================

  static Future<int> insertPayment(Payment payment) async {
    final db = await database;
    final id = await db.insert('payments', payment.toMap());

    // Update debt paid amount and status
    final debtMaps = await db.query('debts', where: 'id = ?', whereArgs: [payment.debtId]);
    if (debtMaps.isNotEmpty) {
      final debt = Debt.fromMap(debtMaps.first);
      final newPaidAmount = debt.paidAmount + payment.amount;
      String newStatus;
      if (newPaidAmount >= debt.amount) {
        newStatus = 'paid';
      } else {
        newStatus = 'partial';
      }
      await db.update(
        'debts',
        {
          'paidAmount': newPaidAmount,
          'status': newStatus,
          if (newStatus == 'paid') 'paidDate': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [payment.debtId],
      );
    }

    RealtimeBackupService.instance.onDatabaseChanged();
    return id;
  }

  static Future<List<Payment>> getPaymentsByDebt(int debtId) async {
    final db = await database;
    final maps = await db.query('payments', where: 'debtId = ?', whereArgs: [debtId], orderBy: 'date DESC');
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  // ==================== BACKUP & RESTORE ====================

  /// Returns the full path to the current database file on disk.
  static Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, AppConstants.databaseName);
  }

  /// Closes the existing database connection (if open) so the file can be
  /// safely copied or replaced.
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Exports the current database to [destinationPath] by copying the live
  /// SQLite file.  The destination file must be writable (e.g. inside app
  /// documents or a temp directory).
  static Future<void> exportBackup(String destinationPath) async {
    // Flush any pending writes by closing and re-opening
    final db = await database;                // ensure it is open
    // Perform a checkpoint so WAL is written
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
    await closeDatabase();

    final sourcePath = await getDatabasePath();
    await copyFile(sourcePath, destinationPath);

    // Re-open so the rest of the app continues working
    _database = await _initDatabase();
  }

  /// Restores the database from a backup file located at [backupPath].
  ///
  /// The current database is closed, the backup file is copied over the
  /// existing database, and the connection is re-opened.  **All current data
  /// will be replaced** by the data in the backup file.
  static Future<void> importBackup(String backupPath) async {
    await closeDatabase();

    final targetPath = await getDatabasePath();
    await copyFile(backupPath, targetPath);

    // Re-open with the replaced database
    _database = await _initDatabase();
  }

  /// Returns the path to the product_images directory.
  static Future<String> getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return join(appDir.path, 'product_images');
  }

  /// Detects if a backup file is a ZIP (new format) or a raw .db (legacy).
  static Future<bool> isZipBackup(String path) async {
    final file = io.File(path);
    if (!await file.exists()) return false;
    final bytes = await file.openRead(0, 4).first;
    if (bytes.length < 4) return false;
    return bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04;
  }

  /// Creates a full backup (ZIP with DB + product images) at [destinationPath].
  static Future<void> exportFullBackup(String destinationPath) async {
    final db = await database;
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
    await closeDatabase();

    final archive = Archive();

    // Add database file
    final dbPath = await getDatabasePath();
    final dbBytes = await io.File(dbPath).readAsBytes();
    archive.addFile(ArchiveFile('tienda_gamez.db', dbBytes.length, dbBytes));

    // Add product images
    try {
      final imagesDir = io.Directory(await getImagesDirectory());
      if (await imagesDir.exists()) {
        await for (final entity in imagesDir.list()) {
          if (entity is io.File) {
            final fileName = basename(entity.path);
            final imgBytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile('product_images/$fileName', imgBytes.length, imgBytes));
          }
        }
      }
    } catch (_) {}

    final zipData = Uint8List.fromList(ZipEncoder().encode(archive)!);
    await io.File(destinationPath).writeAsBytes(zipData, flush: true);

    _database = await _initDatabase();
  }

  /// Restores a full backup (ZIP with DB + product images) from [backupPath].
  static Future<void> importFullBackup(String backupPath) async {
    await closeDatabase();

    final bytes = await io.File(backupPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Extract database
    final dbEntry = archive.findFile('tienda_gamez.db');
    if (dbEntry != null) {
      final targetPath = await getDatabasePath();
      await io.File(targetPath).writeAsBytes(dbEntry.content as List<int>, flush: true);
    }

    // Extract product images
    final imagesDir = io.Directory(await getImagesDirectory());
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    for (final file in archive) {
      if (file.name.startsWith('product_images/') && file.isFile) {
        final fileName = basename(file.name);
        final destPath = join(imagesDir.path, fileName);
        await io.File(destPath).writeAsBytes(file.content as List<int>, flush: true);
      }
    }

    // Re-open DB
    _database = await _initDatabase();

    // Normalize image paths in database
    await _normalizeImagePaths(imagesDir.path);
  }

  /// Updates imagePath references in the products table to point to the
  /// current local images directory.
  static Future<void> _normalizeImagePaths(String newImagesDir) async {
    final db = await database;
    final products = await db.query('products', columns: ['id', 'imagePath']);

    for (final row in products) {
      final oldPath = row['imagePath'] as String?;
      if (oldPath == null || oldPath.isEmpty) continue;

      final fileName = basename(oldPath);
      final newPath = join(newImagesDir, fileName);

      if (oldPath != newPath) {
        await db.update(
          'products',
          {'imagePath': newPath},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  /// Returns the number of product images on disk.
  static Future<int> getProductImageCount() async {
    try {
      final imagesDir = io.Directory(await getImagesDirectory());
      if (!await imagesDir.exists()) return 0;
      int count = 0;
      await for (final entity in imagesDir.list()) {
        if (entity is io.File) count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  // ==================== PRODUCT CATEGORIES ====================

  static Future<List<ProductCategory>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('product_categories', orderBy: 'name');
    return maps.map((map) => ProductCategory.fromMap(map)).toList();
  }

  static Future<ProductCategory?> getCategoryById(int id) async {
    final db = await database;
    final maps = await db.query('product_categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ProductCategory.fromMap(maps.first);
  }

  static Future<int> insertCategory(ProductCategory category) async {
    final db = await database;
    final result = await db.insert('product_categories', category.toMap());
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> updateCategory(ProductCategory category) async {
    final db = await database;
    final result = await db.update('product_categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> deleteCategory(int id) async {
    final db = await database;
    final result = await db.delete('product_categories', where: 'id = ?', whereArgs: [id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  // ==================== PURCHASE ORDERS ====================

  static Future<List<PurchaseOrder>> getAllPurchaseOrders() async {
    final db = await database;
    final maps = await db.query('purchase_orders', orderBy: 'date DESC');
    return await _loadPurchaseOrderItems(maps);
  }

  static Future<List<PurchaseOrder>> getPurchaseOrdersBySupplier(int supplierId) async {
    final db = await database;
    final maps = await db.query(
      'purchase_orders',
      where: 'supplierId = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC',
    );
    return await _loadPurchaseOrderItems(maps);
  }

  static Future<List<PurchaseOrder>> getPurchaseOrdersByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'purchase_orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'date DESC',
    );
    return await _loadPurchaseOrderItems(maps);
  }

  static Future<List<PurchaseOrder>> getPendingPurchaseOrders() async {
    return getPurchaseOrdersByStatus('pending');
  }

  static Future<double> getTotalPendingPurchaseOrders() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total), 0) as total FROM purchase_orders WHERE status = ?',
      ['pending'],
    );
    return (result.first['total'] as num).toDouble();
  }

  static Future<PurchaseOrder?> getPurchaseOrderById(int id) async {
    final db = await database;
    final maps = await db.query('purchase_orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final order = PurchaseOrder.fromMap(maps.first);
    final items = await db.query('purchase_order_items', where: 'orderId = ?', whereArgs: [id]);
    return order.copyWith(items: items.map((i) => PurchaseOrderItem.fromMap(i)).toList());
  }

  static Future<int> insertPurchaseOrder(PurchaseOrder order) async {
    final db = await database;
    final id = await db.insert('purchase_orders', order.toMap());

    for (final item in order.items) {
      await db.insert('purchase_order_items', item.copyWith(orderId: id).toMap());
    }

    // Update supplier totalPurchases
    final supplier = await getSupplierById(order.supplierId);
    if (supplier != null) {
      await updateSupplier(supplier.copyWith(
        totalPurchases: supplier.totalPurchases + order.total,
      ));
    }

    RealtimeBackupService.instance.onDatabaseChanged();
    return id;
  }

  static Future<void> updatePurchaseOrderStatus(int id, String status) async {
    final db = await database;
    await db.update('purchase_orders', {'status': status}, where: 'id = ?', whereArgs: [id]);

    // If received, add stock, update average cost, and create supplier debt if credit
    if (status == 'received') {
      final order = await getPurchaseOrderById(id);
      if (order != null) {
        for (final item in order.items) {
          await increaseStock(item.productId, item.quantity);
          await updateProductAverageCost(item.productId, item.quantity, item.unitCost);
        }

        // If order is credit, create supplier debt
        if (order.isCredit) {
          await insertSupplierDebt(SupplierDebt(
            supplierId: order.supplierId,
            supplierName: order.supplierName,
            purchaseOrderId: order.id,
            amount: order.total,
            dueDate: DateTime.now().add(const Duration(days: 30)),
            notes: 'Pedido #${order.id} a crédito',
          ));
        }
      }
    }

    RealtimeBackupService.instance.onDatabaseChanged();
  }

  static Future<void> updatePurchaseOrder(PurchaseOrder order) async {
    final db = await database;
    await db.update('purchase_orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
    // Delete old items and re-insert
    await db.delete('purchase_order_items', where: 'orderId = ?', whereArgs: [order.id]);
    for (final item in order.items) {
      await db.insert('purchase_order_items', item.copyWith(orderId: order.id).toMap());
    }
    RealtimeBackupService.instance.onDatabaseChanged();
  }

  static Future<int> deletePurchaseOrder(int id) async {
    final db = await database;
    final result = await db.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<List<PurchaseOrder>> _loadPurchaseOrderItems(List<Map<String, dynamic>> orderMaps) async {
    final db = await database;
    final orders = <PurchaseOrder>[];
    for (final map in orderMaps) {
      final order = PurchaseOrder.fromMap(map);
      final items = await db.query('purchase_order_items', where: 'orderId = ?', whereArgs: [order.id]);
      orders.add(order.copyWith(items: items.map((i) => PurchaseOrderItem.fromMap(i)).toList()));
    }
    return orders;
  }

  // ==================== SUPPLIER PAYMENTS ====================

  static Future<List<SupplierPayment>> getAllSupplierPayments() async {
    final db = await database;
    final maps = await db.query('supplier_payments', orderBy: 'date DESC');
    return maps.map((map) => SupplierPayment.fromMap(map)).toList();
  }

  static Future<List<SupplierPayment>> getSupplierPaymentsBySupplier(int supplierId) async {
    final db = await database;
    final maps = await db.query(
      'supplier_payments',
      where: 'supplierId = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => SupplierPayment.fromMap(map)).toList();
  }

  static Future<double> getTotalSupplierPayments() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COALESCE(SUM(amount), 0) as total FROM supplier_payments');
    return (result.first['total'] as num).toDouble();
  }

  static Future<double> getTotalSupplierPaymentsBySupplier(int supplierId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM supplier_payments WHERE supplierId = ?',
      [supplierId],
    );
    return (result.first['total'] as num).toDouble();
  }

  static Future<int> insertSupplierPayment(SupplierPayment payment) async {
    final db = await database;
    final result = await db.insert('supplier_payments', payment.toMap());
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> deleteSupplierPayment(int id) async {
    final db = await database;
    final result = await db.delete('supplier_payments', where: 'id = ?', whereArgs: [id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  // ==================== SUPPLIER DEBTS ====================

  static Future<List<SupplierDebt>> getAllSupplierDebts() async {
    final db = await database;
    final maps = await db.query('supplier_debts', orderBy: 'dueDate ASC');
    return await _loadSupplierDebtPayments(maps);
  }

  static Future<List<SupplierDebt>> getSupplierDebtsBySupplier(int supplierId) async {
    final db = await database;
    final maps = await db.query(
      'supplier_debts',
      where: 'supplierId = ?',
      whereArgs: [supplierId],
      orderBy: 'dueDate ASC',
    );
    return await _loadSupplierDebtPayments(maps);
  }

  static Future<SupplierDebt?> getSupplierDebtById(int id) async {
    final db = await database;
    final maps = await db.query('supplier_debts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final debt = SupplierDebt.fromMap(maps.first);
    final payments = await db.query(
      'supplier_debt_payments',
      where: 'supplierDebtId = ?',
      whereArgs: [id],
      orderBy: 'date DESC',
    );
    return debt.copyWith(payments: payments.map((p) => SupplierDebtPayment.fromMap(p)).toList());
  }

  static Future<int> insertSupplierDebt(SupplierDebt debt) async {
    final db = await database;
    final result = await db.insert('supplier_debts', debt.toMap());
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> updateSupplierDebt(SupplierDebt debt) async {
    final db = await database;
    final result = await db.update(
      'supplier_debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> insertSupplierDebtPayment(SupplierDebtPayment payment) async {
    final db = await database;
    final id = await db.insert('supplier_debt_payments', payment.toMap());

    // Update debt paid amount and status
    final debtMaps = await db.query('supplier_debts', where: 'id = ?', whereArgs: [payment.supplierDebtId]);
    if (debtMaps.isNotEmpty) {
      final debt = SupplierDebt.fromMap(debtMaps.first);
      final newPaidAmount = debt.paidAmount + payment.amount;
      String newStatus;
      if (newPaidAmount >= debt.amount) {
        newStatus = 'paid';
      } else {
        newStatus = 'partial';
      }
      await db.update(
        'supplier_debts',
        {
          'paidAmount': newPaidAmount,
          'status': newStatus,
          if (newStatus == 'paid') 'paidDate': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [payment.supplierDebtId],
      );
    }

    RealtimeBackupService.instance.onDatabaseChanged();
    return id;
  }

  static Future<List<SupplierDebtPayment>> getSupplierDebtPaymentsByDebt(int debtId) async {
    final db = await database;
    final maps = await db.query(
      'supplier_debt_payments',
      where: 'supplierDebtId = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => SupplierDebtPayment.fromMap(map)).toList();
  }

  static Future<List<SupplierDebt>> _loadSupplierDebtPayments(List<Map<String, dynamic>> debtMaps) async {
    final db = await database;
    final debts = <SupplierDebt>[];
    for (final map in debtMaps) {
      final debt = SupplierDebt.fromMap(map);
      final payments = await db.query(
        'supplier_debt_payments',
        where: 'supplierDebtId = ?',
        whereArgs: [debt.id],
        orderBy: 'date DESC',
      );
      debts.add(debt.copyWith(payments: payments.map((p) => SupplierDebtPayment.fromMap(p)).toList()));
    }
    return debts;
  }

  // ==================== PRODUCT VARIATIONS ====================

  static Future<List<ProductVariation>> getVariationsByProduct(int productId) async {
    final db = await database;
    final maps = await db.query(
      'product_variations',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'name',
    );
    return maps.map((map) => ProductVariation.fromMap(map)).toList();
  }

  static Future<ProductVariation?> getVariationById(int id) async {
    final db = await database;
    final maps = await db.query('product_variations', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ProductVariation.fromMap(maps.first);
  }

  static Future<ProductVariation?> getVariationByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'product_variations',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (maps.isEmpty) return null;
    return ProductVariation.fromMap(maps.first);
  }

  static Future<int> insertVariation(ProductVariation variation) async {
    final db = await database;
    final result = await db.insert('product_variations', variation.toMap());
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> updateVariation(ProductVariation variation) async {
    final db = await database;
    final result = await db.update(
      'product_variations',
      variation.toMap(),
      where: 'id = ?',
      whereArgs: [variation.id],
    );
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> deleteVariation(int id) async {
    final db = await database;
    final result = await db.delete('product_variations', where: 'id = ?', whereArgs: [id]);
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<int> updateVariationStock(int id, int newStock) async {
    final db = await database;
    final result = await db.update(
      'product_variations',
      {'stock': newStock, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    RealtimeBackupService.instance.onDatabaseChanged();
    return result;
  }

  static Future<void> increaseVariationStock(int id, int quantity) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE product_variations SET stock = stock + ?, updatedAt = ? WHERE id = ?',
      [quantity, DateTime.now().toIso8601String(), id],
    );
    RealtimeBackupService.instance.onDatabaseChanged();
  }

  static Future<void> reduceVariationStock(int id, int quantity) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE product_variations SET stock = stock - ?, updatedAt = ? WHERE id = ?',
      [quantity, DateTime.now().toIso8601String(), id],
    );
    RealtimeBackupService.instance.onDatabaseChanged();
  }

  /// Calculates weighted average cost for a product.
  static Future<void> updateProductAverageCost(int productId, int newQuantity, double newCost) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [productId]);
    if (maps.isEmpty) return;

    final currentStock = maps.first['stock'] as int? ?? 0;
    final currentCost = (maps.first['cost'] as num?)?.toDouble() ?? 0.0;

    double newAverageCost;
    if (currentStock == 0) {
      newAverageCost = newCost;
    } else {
      final totalValue = (currentStock * currentCost) + (newQuantity * newCost);
      final totalQuantity = currentStock + newQuantity;
      newAverageCost = totalValue / totalQuantity;
    }

    await db.update(
      'products',
      {'cost': newAverageCost, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [productId],
    );
    RealtimeBackupService.instance.onDatabaseChanged();
  }

  static Future<void> copyFile(String source, String destination) async {
    final sourceFile = io.File(source);
    final destFile = io.File(destination);
    await destFile.parent.create(recursive: true);
    await sourceFile.copy(destFile.path);
  }

  /// Returns the size of the database file in bytes.
  static Future<int> getDatabaseSizeBytes() async {
    final path = await getDatabasePath();
    final file = io.File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  // ==================== STATISTICS ====================

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final todaySales = await getTotalSalesByDateRange(todayStart, todayEnd);
    final monthSales = await getTotalSalesByDateRange(monthStart, monthEnd);
    final monthExpenses = await getTotalExpensesByDateRange(monthStart, monthEnd);
    final pendingDebts = await getTotalPendingDebts();
    final lowStockCount = (await getLowStockProducts()).length;
    final pendingDebtsCount = (await getPendingDebts()).length;

    return {
      'todaySales': todaySales,
      'monthSales': monthSales,
      'monthExpenses': monthExpenses,
      'netProfit': monthSales - monthExpenses,
      'pendingDebts': pendingDebts,
      'lowStockCount': lowStockCount,
      'pendingDebtsCount': pendingDebtsCount,
    };
  }

  /// Returns top products sold with profit (totalAmount - totalCost).
  static Future<List<Map<String, dynamic>>> getTopProductsWithProfit(DateTime start, DateTime end, {int limit = 5}) async {
    final db = await database;
    return await db.rawQuery(
      '''SELECT si.productId, si.productName,
         SUM(si.quantity) as totalQuantity,
         SUM(si.subtotal) as totalAmount,
         SUM(si.quantity * p.cost) as totalCost,
         SUM(si.subtotal - (si.quantity * p.cost)) as totalProfit
         FROM sale_items si
         JOIN sales s ON si.saleId = s.id
         JOIN products p ON si.productId = p.id
         WHERE s.date >= ? AND s.date <= ? AND s.status = ?
         GROUP BY si.productId
         ORDER BY totalProfit DESC
         LIMIT ?''',
      [start.toIso8601String(), end.toIso8601String(), 'completed', limit],
    );
  }

  /// Returns total profit (sales - cost of goods sold) for a date range.
  static Future<double> getTotalProfit(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''SELECT COALESCE(SUM(si.subtotal - (si.quantity * p.cost)), 0) as profit
         FROM sale_items si
         JOIN sales s ON si.saleId = s.id
         JOIN products p ON si.productId = p.id
         WHERE s.date >= ? AND s.date <= ? AND s.status = ?''',
      [start.toIso8601String(), end.toIso8601String(), 'completed'],
    );
    return (result.first['profit'] as num).toDouble();
  }

  /// Returns total cost of goods sold for a date range.
  static Future<double> getTotalCogs(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''SELECT COALESCE(SUM(si.quantity * p.cost), 0) as cogs
         FROM sale_items si
         JOIN sales s ON si.saleId = s.id
         JOIN products p ON si.productId = p.id
         WHERE s.date >= ? AND s.date <= ? AND s.status = ?''',
      [start.toIso8601String(), end.toIso8601String(), 'completed'],
    );
    return (result.first['cogs'] as num).toDouble();
  }
}
