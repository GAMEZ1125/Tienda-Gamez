# Plan de Implementación Detallado para Sistema POS con Flutter

Este plan está diseñado para guiar a un agente de IA en el desarrollo de una aplicación POS estilo Treinta/Tiendatek utilizando **Flutter**. El enfoque de "vibe coding" permitirá describir en lenguaje natural las funcionalidades y la IA generará el código correspondiente.

---

## 1. Visión General del Proyecto

### 1.1. Objetivo
Crear una aplicación POS multiplataforma (Android/iOS) para pequeños comercios que permita gestionar ventas, inventario, clientes, gastos, proveedores, cobranza de deudas y estadísticas. La aplicación debe ser fácil de usar y funcionar sin necesidad de hardware especializado .

### 1.2. Tecnologías a Utilizar
- **Framework**: Flutter (SDK 3.19+)
- **Lenguaje**: Dart
- **Arquitectura**: Clean Architecture con BLoC (Business Logic Component)
- **Inyección de Dependencias**: GetIt o Provider
- **Base de datos local**: SQLite (sqflite) o Floor
- **Escaneo de códigos de barras**: mobile_scanner
- **Impresión Bluetooth**: esc_pos_bluetooth / esc_pos_utils
- **Navegación**: go_router o auto_route
- **Mínimo SDK**: Android 5.0 (API 21) / iOS 12.0

### 1.3. Estructura del Proyecto
```
lib/
├── core/
│   ├── constants/         # Constantes de la app
│   ├── theme/             # Tema y estilos
│   ├── utils/             # Utilidades generales
│   └── widgets/           # Widgets reutilizables
├── data/
│   ├── datasources/       # Fuentes de datos (local/remoto)
│   ├── models/            # Modelos de datos (DTO)
│   ├── repositories/      # Implementación de repositorios
│   └── database/          # Configuración de base de datos
├── domain/
│   ├── entities/          # Entidades de negocio
│   ├── repositories/      # Interfaces de repositorios
│   └── usecases/          # Casos de uso
├── presentation/
│   ├── blocs/             # BLoCs para cada pantalla
│   ├── screens/           # Pantallas de la aplicación
│   └── navigation/        # Configuración de navegación
└── main.dart
```

---

## 2. Fase 1: Configuración del Proyecto (Sesión 1)

### 2.1. Creación del Proyecto
**Prompt para el agente:**
> "Crea un nuevo proyecto Flutter llamado 'tienda_pos'. Configura la estructura de carpetas siguiendo Clean Architecture con BLoC. Incluye las dependencias necesarias para: sqflite, bloc, go_router, get_it, equatable, y intl. El proyecto debe usar null safety y tener un tema Material 3."

### 2.2. Dependencias Principales
Agregar al `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.4
  sqflite: ^2.3.2
  path_provider: ^2.1.2
  go_router: ^13.2.0
  get_it: ^7.6.7
  equatable: ^2.0.5
  intl: ^0.18.1
  mobile_scanner: ^4.0.0
  esc_pos_bluetooth: ^0.6.1
  esc_pos_utils: ^1.1.0
  permission_handler: ^11.3.0
  share_plus: ^7.2.1
  image_picker: ^1.0.7
  pdf: ^3.10.7
  printing: ^5.11.1
  floor: ^1.4.2
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  floor_generator: ^1.4.2
```

### 2.3. Configuración Inicial
**Prompt:**
> "Crea la clase App con GoRouter para la navegación principal. Define las rutas: '/home' (HomeScreen), '/pos' (POSScreen), '/inventory' (InventoryScreen), '/expenses' (ExpensesScreen), '/customers' (CustomersScreen), '/suppliers' (SuppliersScreen), '/debts' (DebtsScreen), '/stats' (StatsScreen). Configura un BottomNavigationBar con 5 ítems principales."

---

## 3. Fase 2: Modelado de Datos y Base de Datos (Sesión 2)

### 3.1. Entidades de Negocio (Domain)
**Prompt para cada entidad:**
> "Crea una entidad de dominio llamada [Nombre] que represente... Usa 'equatable' para comparación y 'freezed' para inmutabilidad."

#### Producto (Product)
```dart
class Product extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final double cost;
  final int stock;
  final int minStock;
  final String? category;
  final String? barcode;
  final String? imagePath;
  final List<ProductVariant>? variants; // JSON almacenado
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### Venta (Sale)
```dart
class Sale extends Equatable {
  final int? id;
  final DateTime date;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String paymentMethod; // cash, card, transfer, etc.
  final int? customerId;
  final String? customerName;
  final String? notes;
  final List<SaleItem> items;
  final String status; // completed, pending, cancelled
}
```

#### Cliente (Customer)
```dart
class Customer extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double totalSpent;
  final DateTime? lastPurchase;
  final DateTime createdAt;
}
```

#### Gasto (Expense)
```dart
class Expense extends Equatable {
  final int? id;
  final String concept;
  final String category;
  final double amount;
  final DateTime date;
  final int? supplierId;
  final String? supplierName;
  final String? notes;
}
```

#### Proveedor (Supplier)
```dart
class Supplier extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? contactPerson;
  final DateTime createdAt;
}
```

#### Deuda (Debt)
```dart
class Debt extends Equatable {
  final int? id;
  final int customerId;
  final String customerName;
  final double amount;
  final double? paidAmount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status; // pending, partial, paid
  final String? notes;
  final List<Payment>? payments;
}
```

### 3.2. Configuración de SQLite con Floor
**Prompt:**
> "Configura Floor como ORM para SQLite. Crea las tablas: products, sales, sale_items, customers, expenses, suppliers, debts, payments. Define las relaciones y crea los DAOs con operaciones CRUD básicas y consultas avanzadas."

### 3.3. DAOs Específicos
**Prompt:**
> "Crea un DAO para [entidad] con los siguientes métodos..."

#### ProductDao
```dart
@dao
abstract class ProductDao {
  @Query('SELECT * FROM products WHERE isActive = 1 ORDER BY name')
  Future<List<Product>> getAll();

  @Query('SELECT * FROM products WHERE barcode = :barcode')
  Future<Product?> getByBarcode(String barcode);

  @Query('SELECT * FROM products WHERE name LIKE :query OR category LIKE :query')
  Future<List<Product>> search(String query);

  @Query('SELECT * FROM products WHERE stock <= minStock AND isActive = 1')
  Future<List<Product>> getLowStock();

  @Insert()
  Future<void> insert(Product product);

  @Update()
  Future<void> update(Product product);

  @Query('UPDATE products SET stock = stock - :quantity WHERE id = :id')
  Future<void> reduceStock(int id, int quantity);

  @Query('UPDATE products SET stock = stock + :quantity WHERE id = :id')
  Future<void> increaseStock(int id, int quantity);
}
```

### 3.4. Repositorios
**Prompt:**
> "Crea repositorios que implementen la lógica de negocio para cada entidad. Cada repositorio debe tener métodos para CRUD y consultas específicas. Usa 'get_it' para la inyección de dependencias."

---

## 4. Fase 3: Registro de Ventas (POS) (Sesión 3)

### 4.1. Pantalla Principal de Ventas (POSScreen)
**Prompt:**
> "Crea una pantalla POS con el siguiente diseño:
> - **Barra superior**: Título 'Punto de Venta', botón para histórico de ventas, botón de cierre de caja
> - **Búsqueda**: Campo de texto con ícono de búsqueda y botón de escáner de código de barras
> - **Lista de productos**: Grid o lista con productos encontrados, mostrando nombre, precio y stock
> - **Carrito de compras**: Área inferior con lista de productos agregados, cantidades, subtotales
> - **Resumen**: Subtotal, descuento, IVA (si aplica), total
> - **Acciones**: Botón 'Agregar Cliente', 'Aplicar Descuento', 'Finalizar Venta'"

### 4.2. Lógica de Carrito con BLoC
**Prompt:**
> "Crea un BLoC para manejar el estado del carrito de compras:
> - Agregar producto al carrito (incrementar cantidad si ya existe)
> - Quitar producto o reducir cantidad
> - Limpiar carrito
> - Calcular subtotal, descuento, IVA y total
> - Aplicar descuento porcentual o fijo
> - Asignar cliente a la venta
> - Seleccionar método de pago"

### 4.3. Escáner de Código de Barras
**Prompt:**
> "Implementa la funcionalidad de escaneo de código de barras usando el paquete mobile_scanner. Al escanear un código, busca el producto en la base de datos y lo agrega automáticamente al carrito. Muestra un indicador visual durante el escaneo."

### 4.4. Finalización de Venta
**Prompt:**
> "Al presionar 'Finalizar Venta':
> - Validar que el carrito no esté vacío
> - Mostrar un diálogo con el resumen de la venta
> - Guardar la venta en la base de datos
> - Actualizar el stock de los productos
> - Generar un número de factura/recibo
> - Mostrar el comprobante (ticket) en un diálogo
> - Opciones: 'Imprimir', 'Compartir por WhatsApp', 'Enviar por Email'"

---

## 5. Fase 4: Control de Inventario (Sesión 4)

### 5.1. Pantalla de Gestión de Inventario
**Prompt:**
> "Crea una pantalla de inventario con:
> - **AppBar**: Título 'Inventario', botón de búsqueda, botón de agregar producto
> - **Filtros**: Dropdown de categorías, toggle 'Mostrar solo stock bajo'
> - **Lista de productos**: Tarjetas con imagen, nombre, precio, stock actual (color verde/rojo según nivel)
> - **Acciones rápidas**: Deslizar para editar o eliminar
> - **Botón flotante**: Para agregar nuevo producto"

### 5.2. Formulario de Producto
**Prompt:**
> "Crea un formulario para agregar/editar productos con:
> - Nombre (requerido)
> - Descripción (textarea)
> - Código de barras (campo + botón escanear)
> - Categoría (selector con opciones predefinidas + crear nueva)
> - Precio de venta
> - Precio de costo
> - Stock inicial
> - Stock mínimo
> - Imagen del producto (selector desde galería o cámara)
> - Variantes (tallas, colores, presentaciones) con opción de agregar/eliminar
> - Estado (activo/inactivo)"

### 5.3. Carga Masiva de Productos
**Prompt:**
> "Implementa la importación de productos desde archivo CSV o Excel. El usuario selecciona el archivo, el sistema muestra una vista previa de los datos y permite confirmar la importación. Maneja errores de formato y duplicados."

### 5.4. Alertas de Stock Bajo
**Prompt:**
> "Crea un sistema de alertas:
> - Al iniciar la app, verifica productos con stock bajo
> - Muestra un badge con el número de productos críticos en el ícono de inventario
> - Al entrar a la pantalla de inventario, muestra una tarjeta de advertencia con el listado de productos a reabastecer"

---

## 6. Fase 5: Registro de Gastos (Sesión 5)

### 6.1. Pantalla de Gastos
**Prompt:**
> "Crea una pantalla de gestión de gastos con:
> - **AppBar**: Título 'Gastos', botón de filtros
> - **Resumen**: Tarjeta con total de gastos del mes actual
> - **Gráfico**: Gráfico de pastel de gastos por categoría
> - **Lista**: Gastos del mes, ordenados por fecha (más reciente primero)
> - **Botón flotante**: Para agregar nuevo gasto"

### 6.2. Formulario de Gasto
**Prompt:**
> "Crea un formulario para registrar gastos con:
> - Concepto (requerido)
> - Categoría (selector predefinido: servicios, mercancía, mantenimiento, transporte, etc.)
> - Monto (requerido)
> - Fecha (selector de calendario)
> - Proveedor (búsqueda/selector o crear nuevo desde aquí)
> - Notas (opcional)"

### 6.3. Categorías de Gastos Personalizables
**Prompt:**
> "Permite al usuario gestionar categorías de gastos: agregar nuevas categorías, editar o eliminar existentes. Muestra un listado de categorías en una pantalla secundaria."

---

## 7. Fase 6: Manejo de Clientes (Sesión 6)

### 7.1. Pantalla de Clientes
**Prompt:**
> "Crea una pantalla de gestión de clientes con:
> - **AppBar**: Título 'Clientes', botón de búsqueda, botón de agregar cliente
> - **Lista de clientes**: Tarjetas con nombre, teléfono, total gastado y fecha de última compra
> - **Buscar por**: nombre, teléfono o email
> - **Botón flotante**: Para agregar nuevo cliente"

### 7.2. Perfil de Cliente
**Prompt:**
> "Crea una pantalla de perfil de cliente que muestre:
> - Foto de perfil (opcional)
> - Datos de contacto (nombre, teléfono, email, dirección)
> - Resumen: total gastado, número de compras, última compra
> - Historial de compras (lista con fecha, total, productos)
> - Deudas pendientes (si tiene)
> - Botones: 'Editar Cliente', 'Eliminar Cliente', 'Registrar Venta para este Cliente'"

### 7.3. Historial de Cliente en POS
**Prompt:**
> "En la pantalla POS, al seleccionar un cliente, muestra su información y permite:
> - Ver su historial rápido de compras
> - Aplicar descuentos personalizados basados en su historial
> - Registrar deudas si paga a crédito"

---

## 8. Fase 7: Manejo de Proveedores (Sesión 7)

### 8.1. Pantalla de Proveedores
**Prompt:**
> "Crea una pantalla de gestión de proveedores con:
> - **AppBar**: Título 'Proveedores', botón de búsqueda
> - **Lista de proveedores**: Tarjetas con nombre, teléfono, email
> - **Botón flotante**: Para agregar nuevo proveedor"

### 8.2. Perfil de Proveedor
**Prompt:**
> "Crea una pantalla de perfil de proveedor que muestre:
> - Datos del proveedor (nombre, teléfono, email, dirección, persona de contacto)
> - Historial de compras realizadas a este proveedor
> - Total gastado en compras
> - Botones: 'Editar Proveedor', 'Registrar Compra'"

### 8.3. Registro de Compras
**Prompt:**
> "Crea una pantalla para registrar compras a proveedores:
> - Seleccionar proveedor
> - Agregar productos con cantidades y precios de compra
> - Mostrar subtotal y total de la compra
> - Guardar la compra y actualizar automáticamente el inventario
> - Generar historial de compras por proveedor"

---

## 9. Fase 8: Cobranza de Deudas (Sesión 8)

### 9.1. Pantalla de Deudas
**Prompt:**
> "Crea una pantalla de gestión de deudas con:
> - **AppBar**: Título 'Deudas', filtros por estado (pendiente/pagada)
> - **Resumen**: Total de deudas pendientes, total pagado
> - **Lista**: Deudas con cliente, monto, fecha de vencimiento, estado
> - **Indicadores**: Color rojo para vencidas, amarillo para próximas a vencer
> - **Botón flotante**: Para registrar nueva deuda"

### 9.2. Registro de Deuda
**Prompt:**
> "Crea un formulario para registrar deudas con:
> - Cliente (búsqueda/selector)
> - Monto total de la deuda
> - Fecha de vencimiento
> - Notas (opcional)
> - Opción de registrar pago parcial"

### 9.3. Registro de Pagos
**Prompt:**
> "Permite registrar pagos de deudas:
> - Seleccionar deuda
> - Ingresar monto a pagar
> - Fecha de pago
> - Método de pago
> - Actualizar el estado de la deuda (pendiente, parcial, pagada)
> - Mostrar historial de pagos de cada deuda"

### 9.4. Recordatorios de Pago
**Prompt:**
> "Implementa un sistema de recordatorios:
> - Al iniciar la app, revisa deudas próximas a vencer (en los próximos 3 días)
> - Muestra una notificación local con las deudas próximas
> - Al entrar a la pantalla de deudas, muestra una advertencia destacada"

---

## 10. Fase 9: Análisis y Estadísticas (Sesión 9)

### 10.1. Dashboard Principal
**Prompt:**
> "Crea un dashboard de estadísticas con:
> - **Tarjetas de resumen**: Ventas hoy, ventas del mes, gastos del mes, ganancia neta
> - **Gráfico de ventas**: Gráfico de barras de ventas de los últimos 7 días
> - **Gráfico de comparación**: Línea de ventas vs gastos del mes
> - **Productos más vendidos**: Top 5 productos con gráfico de barras
> - **Selector de período**: Hoy, Esta semana, Este mes, Este año"

### 10.2. Pantalla de Reportes
**Prompt:**
> "Crea una pantalla de reportes con:
> - Selector de tipo de reporte: Ventas, Gastos, Inventario, Deudas
> - Selector de período: Fechas personalizadas
> - Botón 'Generar Reporte'
> - Vista previa del reporte (tabla resumen)
> - Botones de exportación: PDF, Excel (CSV)"

### 10.3. Generación de PDF
**Prompt:**
> "Implementa la generación de reportes en PDF usando los paquetes pdf y printing. El PDF debe incluir:
> - Encabezado con nombre del negocio y logo
> - Título del reporte y período
> - Tablas de datos
> - Resumen final
> - Pie de página con fecha de generación"

### 10.4. Exportación a Excel/CSV
**Prompt:**
> "Permite exportar datos a CSV usando el paquete csv. El usuario puede elegir qué datos exportar y el archivo se guarda en el dispositivo."

---

## 11. Fase 10: Funcionalidades Adicionales (Sesión 10)

### 11.1. Gestión de Caja (Cierre de Caja)
**Prompt:**
> "Crea un módulo de cierre de caja:
> - Apertura de caja: registrar monto inicial y usuario
> - Durante el día: registrar ingresos y egresos adicionales
> - Cierre de caja: mostrar balance total, diferenciar por método de pago
> - Comparar ventas registradas vs efectivo esperado
> - Generar reporte de cierre de caja"

### 11.2. Gestión de Empleados/Usuarios
**Prompt:**
> "Implementa un sistema de gestión de usuarios:
> - Registro de usuarios: nombre, email, contraseña, rol (admin, vendedor, cajero)
> - Inicio de sesión (si se activa)
> - Permisos por rol:
>   - Admin: acceso total
>   - Vendedor: solo POS, clientes
>   - Cajero: POS, deudas, reportes básicos"

### 11.3. Configuración del Negocio
**Prompt:**
> "Crea una pantalla de configuración con:
> - Datos del negocio: nombre, teléfono, dirección, email, logo
> - Configuración de impresión: tamaño de papel, tipo de impresora (80mm/58mm)
> - Configuración fiscal: impuesto (IVA), incluir impuesto en precios
> - Moneda, formato de fecha/hora
> - Respaldo y restauración de base de datos"

### 11.4. Respaldos y Restauración
**Prompt:**
> "Permite al usuario:
> - Hacer respaldo de la base de datos a un archivo (SQLite export)
> - Restaurar desde un archivo de respaldo
> - Exportar/Importar configuración en formato JSON"

---

## 12. Fase 11: Integraciones (Sesión 11)

### 12.1. Impresión de Tickets con Bluetooth
**Prompt:**
> "Implementa la impresión de tickets usando una impresora térmica Bluetooth:
> - Escanear dispositivos Bluetooth cercanos
> - Conectar a la impresora
> - Guardar la impresora seleccionada para futuros usos
> - Formato del ticket: logo (opcional), nombre de negocio, fecha, lista de productos, totales, agradecimiento
> - Usar los paquetes 'esc_pos_bluetooth' y 'esc_pos_utils'"

### 12.2. Compartir Comprobantes por WhatsApp
**Prompt:**
> "Permite compartir comprobantes por WhatsApp:
> - Generar imagen del ticket
> - Usar share_plus para abrir WhatsApp con la imagen
> - Opción de compartir texto del comprobante"

### 12.3. Envío de Comprobantes por Email
**Prompt:**
> "Permite enviar comprobantes por email:
> - Enviar el PDF del comprobante
> - Usar mailto: intent o paquete mailer
> - Opción de guardar email del cliente para futuros envíos"

### 12.4. Escaneo con Cámara
**Prompt:**
> "Usa el paquete mobile_scanner para escaneo de códigos de barras. Configura:
> - Overlay con línea de guía
> - Flash toggle
> - Auto-focus continuo
> - Soporte para códigos EAN, UPC, QR"

---

## 13. Fase 12: Pruebas y Optimización (Sesión 12)

### 13.1. Pruebas Unitarias
**Prompt:**
> "Escribe pruebas unitarias para:
> - BLoCs (usando bloc_test)
> - Repositorios (usando mockito o mocktail)
> - Casos de uso
> - Modelos (usando equatable y copyWith)"

### 13.2. Pruebas de Widgets
**Prompt:**
> "Escribe pruebas de widgets para:
> - Pantalla POS (interacciones básicas)
> - Pantalla de inventario (listado y búsqueda)
> - Formularios (validaciones)"

### 13.3. Optimización de Rendimiento
**Prompt:**
> "Optimiza el rendimiento:
> - Usar ListView.builder para listas largas
> - Cachear imágenes con cached_network_image o hive
> - Usar const widgets donde sea posible
> - Minimizar rebuilds usando selectors en BLoC"

### 13.4. Prueba en Dispositivos
**Prompt:**
> "Genera APK para Android y el build para iOS. Prueba en:
> - Android 5.0+ (mínimo)
> - iOS 12+ (mínimo)
> - Diferentes resoluciones de pantalla"

---

## 14. Fase 13: Publicación (Sesión 13)

### 14.1. Preparación para Google Play Store
**Prompt:**
> "Prepara el proyecto para publicación en Google Play Store:
> - Configurar firma de la app (keystore)
> - Generar APK/AAB firmado
> - Crear íconos y splash screen
> - Escribir descripción de la app y políticas de privacidad"

### 14.2. Preparación para iOS App Store
**Prompt:**
> "Prepara el proyecto para publicación en iOS App Store:
> - Configurar certificados y perfiles de aprovisionamiento
> - Generar IPA
> - Crear capturas de pantalla para iOS
> - Escribir descripción para App Store"

### 14.3. Documentación del Proyecto
**Prompt:**
> "Genera documentación completa:
> - README.md con instrucciones de instalación y uso
> - Guía de usuario con screenshots
> - Guía de administración
> - Documentación técnica (arquitectura, dependencias)"

---

## 15. Flujo de Trabajo para Vibe Coding con Flutter

### 15.1. Sesiones de Trabajo Recomendadas
1. **Sesión 1**: Configuración del proyecto y estructura base
2. **Sesión 2**: Modelado de datos y base de datos
3. **Sesión 3**: POS y ventas (funcionalidad principal)
4. **Sesión 4**: Inventario
5. **Sesión 5**: Gastos
6. **Sesión 6**: Clientes
7. **Sesión 7**: Proveedores
8. **Sesión 8**: Deudas
9. **Sesión 9**: Estadísticas y reportes
10. **Sesión 10**: Funciones adicionales (caja, usuarios, configuración)
11. **Sesión 11**: Integraciones (impresión, WhatsApp, email)
12. **Sesión 12**: Pruebas y optimización
13. **Sesión 13**: Publicación y documentación

### 15.2. Prompting Efectivo para Flutter
- Especifica si usar `StatelessWidget` o `StatefulWidget`
- Define el estado del BLoC claramente
- Describe la interfaz con detalles visuales específicos
- Menciona las interacciones de usuario (scroll, tap, etc.)
- Pide el código con `flutter_bloc` para manejo de estado

### 15.3. Manejo de Errores
**Prompt de debugging:**
> "El código que generaste tiene el siguiente error: [pegar error]. Arregla este problema manteniendo la misma funcionalidad."

### 15.4. Iteración Rápida
- Prueba cada pantalla inmediatamente después de crearla
- Usa `flutter run` para ver cambios en tiempo real
- Si algo no se ve bien, describe visualmente lo que quieres

---

## 16. Estructura de Base de Datos (Floor)

```
database/
├── app_database.dart
├── dao/
│   ├── product_dao.dart
│   ├── sale_dao.dart
│   ├── sale_item_dao.dart
│   ├── customer_dao.dart
│   ├── expense_dao.dart
│   ├── supplier_dao.dart
│   ├── debt_dao.dart
│   └── payment_dao.dart
└── entities/
    ├── product_entity.dart
    ├── sale_entity.dart
    ├── sale_item_entity.dart
    ├── customer_entity.dart
    ├── expense_entity.dart
    ├── supplier_entity.dart
    ├── debt_entity.dart
    └── payment_entity.dart
```

---

## 17. Diagrama de Navegación (GoRouter)

```
/home (HomeScreen)
  ├── /pos (POSScreen)
  │   ├── /pos/scan (ScannerScreen)
  │   └── /pos/checkout (CheckoutScreen)
  ├── /inventory (InventoryScreen)
  │   ├── /inventory/add (ProductFormScreen)
  │   └── /inventory/edit/:id (ProductFormScreen)
  ├── /expenses (ExpensesScreen)
  │   └── /expenses/add (ExpenseFormScreen)
  ├── /customers (CustomersScreen)
  │   ├── /customers/add (CustomerFormScreen)
  │   └── /customers/:id (CustomerProfileScreen)
  ├── /suppliers (SuppliersScreen)
  │   ├── /suppliers/add (SupplierFormScreen)
  │   └── /suppliers/:id (SupplierProfileScreen)
  ├── /debts (DebtsScreen)
  │   ├── /debts/add (DebtFormScreen)
  │   └── /debts/:id (DebtDetailScreen)
  ├── /stats (StatsScreen)
  │   └── /stats/reports (ReportsScreen)
  └── /settings (SettingsScreen)
```

---

## 18. Resumen de Dependencias Clave

| Dependencia | Propósito |
|-------------|-----------|
| `flutter_bloc` | Gestión de estado (BLoC) |
| `sqflite` / `floor` | Base de datos SQLite |
| `go_router` | Navegación declarativa |
| `get_it` | Inyección de dependencias |
| `equatable` | Comparación de objetos |
| `intl` | Formato de fechas y números |
| `mobile_scanner` | Escaneo de códigos de barras |
| `esc_pos_bluetooth` | Impresión Bluetooth |
| `share_plus` | Compartir contenido |
| `pdf` / `printing` | Generación de PDF |
| `permission_handler` | Gestión de permisos |
| `image_picker` | Selección de imágenes |
| `cached_network_image` | Caching de imágenes |

---

Este plan proporciona un roadmap completo para construir un sistema POS profesional con Flutter utilizando "vibe coding". Cada fase está diseñada para ser ejecutada secuencialmente, construyendo sobre la base de la anterior, permitiendo pruebas continuas y ajustes a medida que avanza el desarrollo.