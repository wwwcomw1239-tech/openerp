import 'package:drift/drift.dart';

/// Activity Logs table - mirrors Prisma ActivityLog model
/// Tracks all system activities for audit and dashboard
class ActivityLogs extends Table {
  /// Unique identifier
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Activity type: create, update, delete, view, print, export
  TextColumn get type => text().withLength(min: 1, max: 20)();
  
  /// Module name: invoice, purchase, customer, supplier, product, account, etc.
  TextColumn get module => text().withLength(min: 1, max: 50)();
  
  /// Record ID that was affected
  TextColumn get recordId => text().withLength(min: 1, max: 50)();
  
  /// Activity description
  TextColumn get description => text()();
  
  /// User ID who performed the action
  TextColumn get userId => text().nullable().withLength(max: 50)();
  
  /// IP address (optional)
  TextColumn get ipAddress => text().nullable().withLength(max: 45)();
  
  /// User agent (optional)
  TextColumn get userAgent => text().nullable()();
  
  /// Additional data as JSON string
  TextColumn get metadata => text().nullable()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}
