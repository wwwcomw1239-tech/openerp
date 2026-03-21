// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ==================== CORE TABLES ====================

/// Users table - mirrors Prisma User model
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().unique()();
  TextColumn get name => text()();
  TextColumn get password => text()();
  TextColumn get role => text().withDefault(const Constant('user'))();
  TextColumn get avatar => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Companies table - mirrors Prisma Company model
class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get logo => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get taxNumber => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('SAR'))();
  TextColumn get fiscalYear => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ==================== CRM TABLES ====================

/// Customers table - mirrors Prisma Customer model
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get taxNumber => text().nullable()();
  RealColumn get creditLimit => real().withDefault(const Constant(0.0))();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Suppliers table - mirrors Prisma Supplier model
class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get taxNumber => text().nullable()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ==================== INVENTORY TABLES ====================

/// Categories table - mirrors Prisma Category model
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get parentId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Products table - mirrors Prisma Product model
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get sku => text().unique()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('piece'))();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  RealColumn get salePrice => real().withDefault(const Constant(0.0))();
  RealColumn get quantity => real().withDefault(const Constant(0.0))();
  RealColumn get minQuantity => real().withDefault(const Constant(0.0))();
  RealColumn get maxQuantity => real().withDefault(const Constant(0.0))();
  TextColumn get barcode => text().nullable()();
  TextColumn get image => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ==================== SALES TABLES ====================

/// Invoices table - mirrors Prisma Invoice model
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNumber => text().unique()();
  TextColumn get customerId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Invoice Items table - mirrors Prisma InvoiceItem model
class InvoiceItems extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text()();
  TextColumn get productId => text()();
  TextColumn get description => text().nullable()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Payments table - mirrors Prisma Payment model
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get paymentNumber => text().unique()();
  TextColumn get invoiceId => text().nullable()();
  TextColumn get customerId => text()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get reference => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ==================== PURCHASE TABLES ====================

/// Purchases table - mirrors Prisma Purchase model
class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseNumber => text().unique()();
  TextColumn get supplierId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Purchase Items table - mirrors Prisma PurchaseItem model
class PurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text()();
  TextColumn get productId => text()();
  TextColumn get description => text().nullable()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Supplier Payments table - mirrors Prisma SupplierPayment model
class SupplierPayments extends Table {
  TextColumn get id => text()();
  TextColumn get paymentNumber => text().unique()();
  TextColumn get purchaseId => text().nullable()();
  TextColumn get supplierId => text()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get reference => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ==================== ACCOUNTING TABLES ====================

/// Accounts table - mirrors Prisma Account model
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get parentId => text().nullable()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Journal Entries table - mirrors Prisma JournalEntry model
class JournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get entryNumber => text().unique()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get description => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Journal Lines table - mirrors Prisma JournalLine model
class JournalLines extends Table {
  TextColumn get id => text()();
  TextColumn get journalEntryId => text()();
  TextColumn get accountId => text()();
  TextColumn get description => text().nullable()();
  RealColumn get debit => real().withDefault(const Constant(0.0))();
  RealColumn get credit => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ==================== ANALYTICS TABLES ====================

/// Activity Logs table - mirrors Prisma ActivityLog model
class ActivityLogs extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get module => text()();
  TextColumn get recordId => text()();
  TextColumn get description => text()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

// ==================== DATABASE CLASS ====================

/// Main database class - OpenERP SQLite Database
/// Contains all 17 tables mirroring the Prisma schema exactly
@DriftDatabase(
  tables: [
    Users,
    Companies,
    Customers,
    Suppliers,
    Categories,
    Products,
    Invoices,
    InvoiceItems,
    Payments,
    Purchases,
    PurchaseItems,
    SupplierPayments,
    Accounts,
    JournalEntries,
    JournalLines,
    ActivityLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Singleton instance
  static AppDatabase? _instance;
  
  /// Get singleton instance
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }
  
  /// Private constructor
  AppDatabase._() : super(_openConnection());
  
  /// Constructor with custom executor (for testing)
  AppDatabase.withExecutor(super.e);
  
  /// Database schema version
  @override
  int get schemaVersion => 1;
  
  /// Migration strategy
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
        
        // Enable WAL mode for better performance
        await customStatement('PRAGMA journal_mode = WAL');
        
        // Set busy timeout
        await customStatement('PRAGMA busy_timeout = 5000');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
      },
      beforeOpen: (details) async {
        // Enable foreign keys on every connection
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
  
  /// Close database connection
  Future<void> close() async {
    await executor.close();
    _instance = null;
  }
  
  /// Clear all data (useful for testing/reset)
  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
  
  /// Get database file path
  static Future<String> get databasePath async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'openerp.db');
  }
  
  /// Check if database exists
  static Future<bool> get databaseExists async {
    final path = await databasePath;
    return File(path).exists();
  }
  
  /// Delete database file
  static Future<void> deleteDatabase() async {
    final path = await databasePath;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    // Also delete WAL and SHM files
    final walFile = File('$path-wal');
    final shmFile = File('$path-shm');
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();
  }
}

/// Open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'openerp.db'));
    return NativeDatabase.createInBackground(file);
  });
}
