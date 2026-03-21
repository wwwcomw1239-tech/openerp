import 'package:drift/drift.dart';

/// Categories table - mirrors Prisma Category model
/// Product categories with hierarchical support
class Categories extends Table {
  /// Unique identifier (CUID format)
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Category name
  TextColumn get name => text().withLength(min: 1, max: 255)();
  
  /// Category description
  TextColumn get description => text().nullable()();
  
  /// Parent category ID (for hierarchical categories)
  TextColumn get parentId => text().nullable().withLength(max: 50)();
  
  /// Category color (hex code)
  TextColumn get color => text().nullable().withLength(max: 10)();
  
  /// Sort order
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  
  /// Is category active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
