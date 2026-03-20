import 'package:drift/drift.dart';

/// Purchases table - mirrors Prisma Purchase model
/// Purchase orders from suppliers
class Purchases extends Table {
  /// Unique identifier (CUID format)
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Purchase order number (unique, auto-generated: PO-000001)
  TextColumn get purchaseNumber => text().unique().withLength(min: 1, max: 20)();
  
  /// Supplier ID (foreign key)
  TextColumn get supplierId => text().withLength(min: 1, max: 50)();
  
  /// User ID who created the purchase
  TextColumn get userId => text().withLength(min: 1, max: 50)();
  
  /// Purchase date
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  
  /// Expected delivery date
  DateTimeColumn get expectedDate => dateTime().nullable()();
  
  /// Purchase status: draft, confirmed, received, cancelled
  TextColumn get status => text().withDefault(const Constant('draft'))();
  
  /// Subtotal (sum of line items)
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  
  /// Tax amount
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  
  /// Shipping cost
  RealColumn get shippingCost => real().withDefault(const Constant(0.0))();
  
  /// Total amount
  RealColumn get total => real().withDefault(const Constant(0.0))();
  
  /// Amount paid so far
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  
  /// Additional notes
  TextColumn get notes => text().nullable()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT',
    'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT',
  ];
}

/// Purchase Items table - mirrors Prisma PurchaseItem model
/// Line items for purchase orders
class PurchaseItems extends Table {
  /// Unique identifier
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Purchase ID (foreign key)
  TextColumn get purchaseId => text().withLength(min: 1, max: 50)();
  
  /// Product ID (foreign key)
  TextColumn get productId => text().withLength(min: 1, max: 50)();
  
  /// Line item description
  TextColumn get description => text().nullable()();
  
  /// Quantity ordered
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  
  /// Quantity received
  RealColumn get quantityReceived => real().withDefault(const Constant(0.0))();
  
  /// Unit price
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  
  /// Line total
  RealColumn get total => real().withDefault(const Constant(0.0))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE',
    'FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT',
  ];
}

/// Supplier Payments table - mirrors Prisma SupplierPayment model
/// Payments made to suppliers
class SupplierPayments extends Table {
  /// Unique identifier
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Payment number (unique, auto-generated)
  TextColumn get paymentNumber => text().unique().withLength(min: 1, max: 20)();
  
  /// Purchase ID (optional - can be advance payment)
  TextColumn get purchaseId => text().nullable().withLength(max: 50)();
  
  /// Supplier ID (foreign key)
  TextColumn get supplierId => text().withLength(min: 1, max: 50)();
  
  /// Payment amount
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  
  /// Payment method: cash, bank, check, card
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  
  /// Reference number
  TextColumn get reference => text().nullable().withLength(max: 100)();
  
  /// Payment date
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  
  /// Additional notes
  TextColumn get notes => text().nullable()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE SET NULL',
    'FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT',
  ];
}
