import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/drift/database.dart';
import '../../data/database/drift/database.dart';
import 'database_provider.dart';
import 'accounts_provider.dart';

part 'journal_entries_provider.g.dart';

/// UUID generator
final _uuid = const Uuid();

// ==================== JOURNAL LINE MODEL ====================

class JournalLineModel {
  final String id;
  final String journalEntryId;
  final String accountId;
  final String? description;
  final double debit;
  final double credit;
  final DateTime createdAt;

  JournalLineModel({
    required this.id,
    required this.journalEntryId,
    required this.accountId,
    this.description,
    this.debit = 0.0,
    this.credit = 0.0,
    required this.createdAt,
  });

  factory JournalLineModel.fromDrift(JournalLine line) {
    return JournalLineModel(
      id: line.id,
      journalEntryId: line.journalEntryId,
      accountId: line.accountId,
      description: line.description,
      debit: line.debit,
      credit: line.credit,
      createdAt: line.createdAt,
    );
  }
}

class JournalLineFormData {
  String accountId;
  String? description;
  double debit;
  double credit;

  JournalLineFormData({
    this.accountId = '',
    this.description,
    this.debit = 0.0,
    this.credit = 0.0,
  });

  bool get hasValue => debit > 0 || credit > 0;
  bool get isValid => accountId.isNotEmpty && hasValue && !(debit > 0 && credit > 0);
}

// ==================== JOURNAL ENTRY MODEL ====================

class JournalEntryModel {
  final String id;
  final String entryNumber;
  final DateTime date;
  final String? description;
  final String? reference;
  final String? sourceModule;
  final String? sourceId;
  final String userId;
  final String status;
  final double totalDebit;
  final double totalCredit;
  final bool isBalanced;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntryModel({
    required this.id,
    required this.entryNumber,
    required this.date,
    this.description,
    this.reference,
    this.sourceModule,
    this.sourceId,
    required this.userId,
    this.status = 'draft',
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.isBalanced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntryModel.fromDrift(JournalEntry entry) {
    return JournalEntryModel(
      id: entry.id,
      entryNumber: entry.entryNumber,
      date: entry.date,
      description: entry.description,
      reference: entry.reference,
      sourceModule: entry.sourceModule,
      sourceId: entry.sourceId,
      userId: entry.userId,
      status: entry.status,
      totalDebit: entry.totalDebit,
      totalCredit: entry.totalCredit,
      isBalanced: entry.isBalanced,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isPosted => status == 'posted';
  bool get isCancelled => status == 'cancelled';
}

/// Journal entry with lines
class JournalEntryWithLines {
  final JournalEntryModel entry;
  final List<JournalLineModel> lines;

  JournalEntryWithLines({required this.entry, required this.lines});
}

class JournalEntryFormData {
  DateTime date;
  String? description;
  String? reference;
  String status;
  List<JournalLineFormData> lines;

  JournalEntryFormData({
    DateTime? date,
    this.description,
    this.reference,
    this.status = 'draft',
    List<JournalLineFormData>? lines,
  })  : date = date ?? DateTime.now(),
        lines = lines ?? [];

  double get totalDebit => lines.fold(0.0, (sum, l) => sum + l.debit);
  double get totalCredit => lines.fold(0.0, (sum, l) => sum + l.credit);
  bool get isBalanced => totalDebit == totalCredit && totalDebit > 0;
  bool get isValid => isBalanced && lines.where((l) => l.isValid).length >= 2;
  
  String? validate() {
    if (lines.where((l) => l.hasValue).isEmpty) {
      return 'يجب إضافة بند واحد على الأقل';
    }
    if (lines.where((l) => l.isValid).length < 2) {
      return 'يجب أن يحتوي القيد على بندّين صالحين على الأقل';
    }
    if (!isBalanced) {
      return 'القيد غير متوازن: المدين ($totalDebit) لا يساوي الدائن ($totalCredit)';
    }
    return null;
  }
}

// ==================== JOURNAL ENTRY PROVIDERS ====================

@riverpod
Stream<List<JournalEntryModel>> journalEntries(JournalEntriesRef ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.journalEntries)
      .watch()
      .map((rows) => rows.map(JournalEntryModel.fromDrift).toList());
}

@riverpod
Stream<List<JournalEntryModel>> postedJournalEntries(PostedJournalEntriesRef ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.journalEntries)..where((t) => t.status.equals('posted')))
      .watch()
      .map((rows) => rows.map(JournalEntryModel.fromDrift).toList());
}

@riverpod
Future<JournalEntryWithLines?> journalEntryWithLines(JournalEntryWithLinesRef ref, String id) async {
  final db = ref.watch(databaseProvider);

  final entry = await (db.select(db.journalEntries)..where((t) => t.id.equals(id)))
      .getSingleOrNull();

  if (entry == null) return null;

  final lines = await (db.select(db.journalLines)..where((t) => t.journalEntryId.equals(id)))
      .get();

  return JournalEntryWithLines(
    entry: JournalEntryModel.fromDrift(entry),
    lines: lines.map(JournalLineModel.fromDrift).toList(),
  );
}

@riverpod
Stream<List<JournalLineModel>> journalLines(JournalLinesRef ref, String entryId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.journalLines)..where((t) => t.journalEntryId.equals(entryId)))
      .watch()
      .map((rows) => rows.map(JournalLineModel.fromDrift).toList());
}

@riverpod
class JournalEntriesNotifier extends _$JournalEntriesNotifier {
  @override
  Stream<List<JournalEntryModel>> build() {
    final db = ref.watch(databaseProvider);
    return db
        .select(db.journalEntries)
        .watch()
        .map((rows) => rows.map(JournalEntryModel.fromDrift).toList());
  }

  /// Generate next entry number
  Future<String> _generateEntryNumber() async {
    final db = ref.read(databaseProvider);
    final count = await db.journalEntries.count().getSingle();
    return 'JE-${(count + 1).toString().padLeft(6, '0')}';
  }

  /// Create journal entry with double-entry enforcement
  Future<JournalEntryModel> create(JournalEntryFormData data, String userId) async {
    // Validate double-entry
    final validationError = data.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    final db = ref.read(databaseProvider);
    final id = _uuid.v4();
    final entryNumber = await _generateEntryNumber();
    final now = DateTime.now();

    await db.transaction(() async {
      // Insert journal entry
      await db.into(db.journalEntries).insert(
        JournalEntriesCompanion(
          id: drift.Value(id),
          entryNumber: drift.Value(entryNumber),
          date: drift.Value(data.date),
          description: drift.Value(data.description),
          reference: drift.Value(data.reference),
          sourceModule: const drift.Value('manual'),
          userId: drift.Value(userId),
          status: drift.Value(data.status),
          totalDebit: drift.Value(data.totalDebit),
          totalCredit: drift.Value(data.totalCredit),
          isBalanced: drift.Value(data.isBalanced),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Insert lines
      for (final line in data.lines.where((l) => l.hasValue)) {
        final lineId = _uuid.v4();
        await db.into(db.journalLines).insert(
          JournalLinesCompanion(
            id: drift.Value(lineId),
            journalEntryId: drift.Value(id),
            accountId: drift.Value(line.accountId),
            description: drift.Value(line.description),
            debit: drift.Value(line.debit),
            credit: drift.Value(line.credit),
            createdAt: drift.Value(now),
          ),
        );

        // Update account balance if posting
        if (data.status == 'posted') {
          await _updateAccountBalance(line.accountId, line.debit, line.credit);
        }
      }
    });

    return JournalEntryModel(
      id: id,
      entryNumber: entryNumber,
      date: data.date,
      description: data.description,
      reference: data.reference,
      sourceModule: 'manual',
      userId: userId,
      status: data.status,
      totalDebit: data.totalDebit,
      totalCredit: data.totalCredit,
      isBalanced: data.isBalanced,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Post a draft journal entry
  Future<void> post(String id) async {
    final db = ref.read(databaseProvider);
    final entry = await (db.select(db.journalEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (entry == null) throw Exception('القيد غير موجود');
    if (entry.status != 'draft') throw Exception('يمكن ترحيل المسودات فقط');
    if (!entry.isBalanced) throw Exception('القيد غير متوازن');

    await db.transaction(() async {
      // Update entry status
      await (db.update(db.journalEntries)..where((t) => t.id.equals(id))).write(
        JournalEntriesCompanion(
          status: const drift.Value('posted'),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // Get lines and update account balances
      final lines = await (db.select(db.journalLines)..where((t) => t.journalEntryId.equals(id)))
          .get();

      for (final line in lines) {
        await _updateAccountBalance(line.accountId, line.debit, line.credit);
      }
    });
  }

  /// Cancel a posted journal entry (creates reversing entry)
  Future<void> cancel(String id, String reason) async {
    final db = ref.read(databaseProvider);
    final entry = await (db.select(db.journalEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (entry == null) throw Exception('القيد غير موجود');
    if (entry.status != 'posted') throw Exception('يمكن إلغاء القيود المرحلة فقط');

    await db.transaction(() async {
      // Get original lines
      final lines = await (db.select(db.journalLines)..where((t) => t.journalEntryId.equals(id)))
          .get();

      // Create reversing entry
      final reversingId = _uuid.v4();
      final reversingNumber = await _generateEntryNumber();
      final now = DateTime.now();

      await db.into(db.journalEntries).insert(
        JournalEntriesCompanion(
          id: drift.Value(reversingId),
          entryNumber: drift.Value(reversingNumber),
          date: drift.Value(now),
          description: drift.Value('إلغاء: ${entry.description ?? ''} - $reason'),
          reference: drift.Value(entry.entryNumber),
          sourceModule: const drift.Value('reversal'),
          sourceId: drift.Value(id),
          userId: drift.Value(entry.userId),
          status: const drift.Value('posted'),
          totalDebit: drift.Value(entry.totalCredit), // Swapped
          totalCredit: drift.Value(entry.totalDebit), // Swapped
          isBalanced: const drift.Value(true),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Create reversing lines (swap debit/credit)
      for (final line in lines) {
        await db.into(db.journalLines).insert(
          JournalLinesCompanion(
            id: drift.Value(_uuid.v4()),
            journalEntryId: drift.Value(reversingId),
            accountId: drift.Value(line.accountId),
            description: drift.Value(line.description),
            debit: drift.Value(line.credit), // Swapped
            credit: drift.Value(line.debit), // Swapped
            createdAt: drift.Value(now),
          ),
        );

        // Reverse account balance
        await _updateAccountBalance(line.accountId, line.credit, line.debit);
      }

      // Mark original as cancelled
      await (db.update(db.journalEntries)..where((t) => t.id.equals(id))).write(
        JournalEntriesCompanion(
          status: const drift.Value('cancelled'),
          updatedAt: drift.Value(now),
        ),
      );
    });
  }

  /// Delete a draft journal entry
  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    final entry = await (db.select(db.journalEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (entry == null) return;
    if (entry.status != 'draft') {
      throw Exception('لا يمكن حذف القيود المرحلة');
    }

    await (db.delete(db.journalLines)..where((t) => t.journalEntryId.equals(id))).go();
    await (db.delete(db.journalEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Update account balance based on debit/credit
  Future<void> _updateAccountBalance(String accountId, double debit, double credit) async {
    final db = ref.read(databaseProvider);
    final account = await (db.select(db.accounts)..where((t) => t.id.equals(accountId)))
        .getSingleOrNull();

    if (account == null) return;

    // For debit normal accounts: debit increases, credit decreases
    // For credit normal accounts: credit increases, debit decreases
    double delta;
    if (account.normalBalance == 'debit') {
      delta = debit - credit;
    } else {
      delta = credit - debit;
    }

    final newBalance = account.balance + delta;
    await (db.update(db.accounts)..where((t) => t.id.equals(accountId))).write(
      AccountsCompanion(
        balance: drift.Value(newBalance),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }
}

// ==================== JOURNAL STATISTICS ====================

@riverpod
Future<JournalStats> journalStats(JournalStatsRef ref) async {
  final db = ref.watch(databaseProvider);

  final allEntries = await db.select(db.journalEntries).get();
  final draftCount = allEntries.where((e) => e.status == 'draft').length;
  final postedCount = allEntries.where((e) => e.status == 'posted').length;
  final cancelledCount = allEntries.where((e) => e.status == 'cancelled').length;

  final totalDebit = allEntries.fold<double>(0, (sum, e) => sum + e.totalDebit);
  final totalCredit = allEntries.fold<double>(0, (sum, e) => sum + e.totalCredit);

  return JournalStats(
    total: allEntries.length,
    draft: draftCount,
    posted: postedCount,
    cancelled: cancelledCount,
    totalDebit: totalDebit,
    totalCredit: totalCredit,
  );
}

class JournalStats {
  final int total;
  final int draft;
  final int posted;
  final int cancelled;
  final double totalDebit;
  final double totalCredit;

  JournalStats({
    required this.total,
    required this.draft,
    required this.posted,
    required this.cancelled,
    required this.totalDebit,
    required this.totalCredit,
  });
}
