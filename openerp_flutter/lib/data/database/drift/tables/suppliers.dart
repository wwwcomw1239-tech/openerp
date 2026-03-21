import 'package:drift/drift.dart';

/// Suppliers table - mirrors Prisma Supplier model
/// Stores supplier/vendor information
class Suppliers extends Table {
  /// Unique identifier (CUID format)
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Supplier name (required)
  TextColumn get name => text().withLength(min: 1, max: 255)();
  
  /// Email address
  TextColumn get email => text().nullable().withLength(max: 255)();
  
  /// Phone number
  TextColumn get phone => text().nullable().withLength(max: 50)();
  
  /// Mobile number
  TextColumn get mobile => text().nullable().withLength(max: 50)();
  
  /// Street address
  TextColumn get address => text().nullable()();
  
  /// City name
  TextColumn get city => text().nullable().withLength(max: 100)();
  
  /// Country name
  TextColumn get country => text().nullable().withLength(max: 100)();
  
  /// Tax identification number
  TextColumn get taxNumber => text().nullable().withLength(max: 50)();
  
  /// Current balance (payable)
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  
  /// Additional notes
  TextColumn get notes => text().nullable()();
  
  /// Is supplier active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
