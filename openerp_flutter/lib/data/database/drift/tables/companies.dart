import 'package:drift/drift.dart';

/// Companies table - mirrors Prisma Company model
/// Stores company/organization settings
class Companies extends Table {
  /// Unique identifier
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Company name
  TextColumn get name => text().withLength(min: 1, max: 255)();
  
  /// Company logo URL or base64
  TextColumn get logo => text().nullable()();
  
  /// Company email
  TextColumn get email => text().nullable().withLength(max: 255)();
  
  /// Company phone
  TextColumn get phone => text().nullable().withLength(max: 50)();
  
  /// Street address
  TextColumn get address => text().nullable()();
  
  /// City name
  TextColumn get city => text().nullable().withLength(max: 100)();
  
  /// Country name
  TextColumn get country => text().nullable().withLength(max: 100)();
  
  /// Tax identification number
  TextColumn get taxNumber => text().nullable().withLength(max: 50)();
  
  /// Default currency code (USD, SAR, etc.)
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  
  /// Fiscal year setting
  TextColumn get fiscalYear => text().nullable()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
