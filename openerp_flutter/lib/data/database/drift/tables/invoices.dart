import 'package:drift/drift.dart';

/// Invoices table - mirrors Prisma Invoice model
/// Sales invoices/bills
class Invoices extends Table {
  /// Unique identifier (CUID format)
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Invoice number (unique, auto-generated: INV-000001)
  TextColumn get invoiceNumber => text().unique().withLength(min: 1, max: 20)();
  
  /// Customer ID (foreign key)
  TextColumn get customerId => text().withLength(min: 1, max: 50)();
  
  /// User ID who created the invoice
  TextColumn get userId => text().withLength(min: 1, max: 50)();
  
  /// Invoice date
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  
  /// Due date for payment
  DateTimeColumn get dueDate => dateTime().nullable()();
  
  /// Invoice status: draft, confirmed, paid, cancelled
  TextColumn get status => text().withDefault(const Constant('draft'))();
  
  /// Subtotal (sum of line items)
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  
  /// Tax amount
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  
  /// Discount amount
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  
  /// Total amount (subtotal + tax - discount)
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
    'FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT',
    'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT',
  ];
}

/// Invoice Items table - mirrors Prisma InvoiceItem model
/// Line items for sales invoices
class InvoiceItems extends Table {
  /// Unique identifier
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Invoice ID (foreign key)
  TextColumn get invoiceId => text().withLength(min: 1, max: 50)();
  
  /// Product ID (foreign key)
  TextColumn get productId => text().withLength(min: 1, max: 50)();
  
  /// Line item description
  TextColumn get description => text().nullable()();
  
  /// Quantity
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  
  /// Unit price
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  
  /// Discount amount for this line
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  
  /// Tax rate percentage
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  
  /// Line total (quantity * unitPrice - discount)
  RealColumn get total => real().withDefault(const Constant(0.0))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE',
    'FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT',
  ];
}

/// Payments table - mirrors Prisma Payment model
/// Customer payment records
class Payments extends Table {
  /// Unique identifier
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Payment number (unique, auto-generated)
  TextColumn get paymentNumber => text().unique().withLength(min: 1, max: 20)();
  
  /// Invoice ID (optional - can be advance payment)
  TextColumn get invoiceId => text().nullable().withLength(max: 50)();
  
  /// Customer ID (foreign key)
  TextColumn get customerId => text().withLength(min: 1, max: 50)();
  
  /// Payment amount
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  
  /// Payment method: cash, bank, check, card
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  
  /// Reference number (check number, transaction ID)
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
    'FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL',
    'FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT',
  ];
}
