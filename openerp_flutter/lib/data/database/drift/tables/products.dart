import 'package:drift/drift.dart';

/// Corrected Products table for foreign key references
class Products extends Table {
  /// Unique identifier (CUID format)
  TextColumn get id => text()();
  
  /// Stock Keeping Unit (unique)
  TextColumn get sku => text().unique()();
  
  /// Product name (required)
  TextColumn get name => text()();
  
  /// Product description
  TextColumn get description => text().nullable()();
  
  /// Category ID (foreign key)
  TextColumn get categoryId => text().nullable()();
  
  /// Unit of measurement: piece, kg, liter, meter, box
  TextColumn get unit => text().withDefault(const Constant('piece'))();
  
  /// Cost price (purchase price)
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  
  /// Sale price (selling price)
  RealColumn get salePrice => real().withDefault(const Constant(0.0))();
  
  /// Current quantity in stock
  RealColumn get quantity => real().withDefault(const Constant(0.0))();
  
  /// Minimum quantity threshold (reorder point)
  RealColumn get minQuantity => real().withDefault(const Constant(0.0))();
  
  /// Maximum quantity threshold
  RealColumn get maxQuantity => real().withDefault(const Constant(0.0))();
  
  /// Barcode (EAN/UPC)
  TextColumn get barcode => text().nullable()();
  
  /// Product image URL or path
  TextColumn get image => text().nullable()();
  
  /// Is product active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
