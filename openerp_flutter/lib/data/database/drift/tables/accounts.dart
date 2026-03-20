import 'package:drift/drift.dart';

/// Accounts table - mirrors Prisma Account model
/// Chart of accounts for double-entry accounting
class Accounts extends Table {
  /// Unique identifier (CUID format)
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Account code (unique, e.g., 1000, 2000, etc.)
  TextColumn get code => text().unique().withLength(min: 1, max: 20)();
  
  /// Account name
  TextColumn get name => text().withLength(min: 1, max: 255)();
  
  /// Account type: asset, liability, equity, income, expense
  TextColumn get type => text().withLength(min: 1, max: 20)();
  
  /// Parent account ID (for hierarchical accounts)
  TextColumn get parentId => text().nullable().withLength(max: 50)();
  
  /// Current balance
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  
  /// Normal balance type: debit, credit
  TextColumn get normalBalance => text().withDefault(const Constant('debit'))();
  
  /// Account description
  TextColumn get description => text().nullable()();
  
  /// Is account active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Is this a header account (grouping)
  BoolColumn get isHeader => boolean().withDefault(const Constant(false))();
  
  /// Sort order for display
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Journal Entries table - mirrors Prisma JournalEntry model
/// Double-entry journal entries
class JournalEntries extends Table {
  /// Unique identifier (CUID format)
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Entry number (unique, auto-generated: JE-000001)
  TextColumn get entryNumber => text().unique().withLength(min: 1, max: 20)();
  
  /// Entry date
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  
  /// Entry description/memo
  TextColumn get description => text().nullable()();
  
  /// Reference (invoice number, PO number, etc.)
  TextColumn get reference => text().nullable().withLength(max: 100)();
  
  /// Source module: invoice, purchase, payment, manual
  TextColumn get sourceModule => text().nullable().withLength(max: 50)();
  
  /// Source record ID
  TextColumn get sourceId => text().nullable().withLength(max: 50)();
  
  /// User ID who created the entry
  TextColumn get userId => text().withLength(min: 1, max: 50)();
  
  /// Entry status: draft, posted, cancelled
  TextColumn get status => text().withDefault(const Constant('draft'))();
  
  /// Total debit amount (must equal total credit)
  RealColumn get totalDebit => real().withDefault(const Constant(0.0))();
  
  /// Total credit amount (must equal total debit)
  RealColumn get totalCredit => real().withDefault(const Constant(0.0))();
  
  /// Is entry balanced (totalDebit == totalCredit)
  BoolColumn get isBalanced => boolean().withDefault(const Constant(true))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT',
  ];
}

/// Journal Lines table - mirrors Prisma JournalLine model
/// Individual lines of journal entries
class JournalLines extends Table {
  /// Unique identifier
  TextColumn get id => text().withLength(min: 1, max: 50)();
  
  /// Journal entry ID (foreign key)
  TextColumn get journalEntryId => text().withLength(min: 1, max: 50)();
  
  /// Account ID (foreign key)
  TextColumn get accountId => text().withLength(min: 1, max: 50)();
  
  /// Line description
  TextColumn get description => text().nullable()();
  
  /// Debit amount
  RealColumn get debit => real().withDefault(const Constant(0.0))();
  
  /// Credit amount
  RealColumn get credit => real().withDefault(const Constant(0.0))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON DELETE CASCADE',
    'FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE RESTRICT',
  ];
}
