class AppConstants {
  static const String appName = 'Tienda Gamez';
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  static const String appBuildNumber = String.fromEnvironment('APP_BUILD_NUMBER', defaultValue: '1');
  static const bool enableSubscriptions = false;

  // Database
  static const String databaseName = 'tienda_gamez.db';
  static const int databaseVersion = 11;

  // Pagination
  static const int pageSize = 20;

  // Categories for products
  static const List<String> productCategories = [
    'Videojuegos',
    'Consolas',
    'Accesorios',
    'Tarjetas de Regalo',
    'Merchandising',
    'Otros',
  ];

  // Categories for expenses
  static const List<String> expenseCategories = [
    'Servicios',
    'Mercancía',
    'Mantenimiento',
    'Transporte',
    'Alquiler',
    'Publicidad',
    'Sueldos',
    'Impuestos',
    'Otros',
  ];

  // Payment methods
  static const List<String> paymentMethods = [
    'Efectivo',
    'Tarjeta Débito',
    'Tarjeta Crédito',
    'Transferencia',
    'Yape/Plin',
    'Crédito',
  ];
}
