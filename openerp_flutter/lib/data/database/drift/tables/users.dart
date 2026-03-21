import 'package:drift/drift.dart';

/// Users table - mirrors Prisma User model
/// Stores system users with authentication data
class Users extends Table {
  /// Unique identifier (CUID format)
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// User email (unique)
  TextColumn get email => text().unique().withLength(min: 1, max: 255)();
  
  /// User full name
  TextColumn get name => text().withLength(min: 1, max: 255)();
  
  /// Hashed password
  TextColumn get password => text().withLength(min: 1, max: 255)();
  
  /// User role: admin, manager, user
  TextColumn get role => text().withDefault(const Constant('user'))();
  
  /// Avatar URL or base64
  TextColumn get avatar => text().nullable()();
  
  /// Is user active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
