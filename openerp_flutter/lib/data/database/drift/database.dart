import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import all table definitions
import 'tables/users.dart';
import 'tables/companies.dart';
import 'tables/customers.dart';
import 'tables/suppliers.dart';
import 'tables/categories.dart';
import 'tables/products.dart';
import 'tables/invoices.dart';
import 'tables/purchases.dart';
import 'tables/accounts.dart';
import 'tables/activity_logs.dart';

part 'database.g.dart';

/// Main database class - OpenERP SQLite Database
/// Contains all 17 tables mirroring the Prisma schema
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
  
  /// Constructor with custom executor
  AppDatabase(super.e);
  
  /// Database schema version
  @override
  int get schemaVersion => 1;
  
  /// Migration strategy
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
        // Example:
        // if (from < 2) {
        //   await m.addColumn(users, users.avatar);
        // }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
        
        // Enable WAL mode for better performance
        await customStatement('PRAGMA journal_mode = WAL');
        
        // Set busy timeout
        await customStatement('PRAGMA busy_timeout = 5000');
      },
    );
  }
  
  /// Close database connection
  @override
  Future<void> close() async {
    await executor.close();
    _instance = null;
  }
  
  /// Clear all data (useful for testing)
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
