import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/drift/app_database.dart';
import '../../data/database/drift/database.dart';
import 'database_provider.dart';

part 'accounts_provider.g.dart';

/// UUID generator
final _uuid = const Uuid();

// ==================== ACCOUNT TYPE ENUM ====================

enum AccountType {
  asset('asset', 'الأصول', '1000-1999'),
  liability('liability', 'الخصوم', '2000-2999'),
  equity('equity', 'حقوق الملكية', '3000-3999'),
  income('income', 'الإيرادات', '4000-4999'),
  expense('expense', 'المصروفات', '5000-5999');

  final String value;
  final String arabicName;
  final String codeRange;

  const AccountType(this.value, this.arabicName, this.codeRange);
}

// ==================== ACCOUNT MODEL ====================

class AccountModel {
  final String id;
  final String code;
  final String name;
  final String type;
  final String? parentId;
  final double balance;
  final String normalBalance;
  final String? description;
  final bool isActive;
  final bool isHeader;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties for tree view
  List<AccountModel> children = [];
  int level = 0;

  AccountModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.parentId,
    this.balance = 0.0,
    this.normalBalance = 'debit',
    this.description,
    this.isActive = true,
    this.isHeader = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountModel.fromDrift(Account account) {
    return AccountModel(
      id: account.id,
      code: account.code,
      name: account.name,
      type: account.type,
      parentId: account.parentId,
      balance: account.balance,
      normalBalance: account.normalBalance,
      description: account.description,
      isActive: account.isActive,
      isHeader: account.isHeader,
      sortOrder: account.sortOrder,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
    );
  }

  bool get isDebitNormal => normalBalance == 'debit';
  bool get isCreditNormal => normalBalance == 'credit';
  
  AccountType get accountType => AccountType.values.firstWhere(
    (t) => t.value == type,
    orElse: () => AccountType.asset,
  );

  /// Calculate actual balance based on normal balance type
  double get displayBalance => isDebitNormal ? balance : -balance;
}

class AccountFormData {
  String code;
  String name;
  String type;
  String? parentId;
  String normalBalance;
  String? description;
  bool isActive;
  bool isHeader;
  int sortOrder;

  AccountFormData({
    this.code = '',
    this.name = '',
    this.type = 'asset',
    this.parentId,
    this.normalBalance = 'debit',
    this.description,
    this.isActive = true,
    this.isHeader = false,
    this.sortOrder = 0,
  });

  factory AccountFormData.fromModel(AccountModel? model) {
    return AccountFormData(
      code: model?.code ?? '',
      name: model?.name ?? '',
      type: model?.type ?? 'asset',
      parentId: model?.parentId,
      normalBalance: model?.normalBalance ?? 'debit',
      description: model?.description,
      isActive: model?.isActive ?? true,
      isHeader: model?.isHeader ?? false,
      sortOrder: model?.sortOrder ?? 0,
    );
  }
}

// ==================== ACCOUNT PROVIDERS ====================

@riverpod
Stream<List<AccountModel>> accounts(AccountsRef ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.accounts)
      .watch()
      .map((rows) => rows.map(AccountModel.fromDrift).toList());
}

@riverpod
Stream<List<AccountModel>> activeAccounts(ActiveAccountsRef ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.accounts)..where((t) => t.isActive.equals(true)))
      .watch()
      .map((rows) => rows.map(AccountModel.fromDrift).toList());
}

@riverpod
Stream<List<AccountModel>> accountsByType(AccountsByTypeRef ref, String type) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.accounts)..where((t) => t.type.equals(type)))
      .watch()
      .map((rows) => rows.map(AccountModel.fromDrift).toList());
}

/// Hierarchical accounts tree provider
@riverpod
Future<List<AccountModel>> accountsTree(AccountsTreeRef ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  return _buildAccountTree(accounts);
}

/// Build hierarchical tree from flat list
List<AccountModel> _buildAccountTree(List<AccountModel> accounts) {
  final accountMap = <String, AccountModel>{};
  final rootAccounts = <AccountModel>[];

  // Create map of all accounts
  for (final account in accounts) {
    accountMap[account.id] = account;
    account.children = [];
  }

  // Build tree structure
  for (final account in accounts) {
    if (account.parentId == null || !accountMap.containsKey(account.parentId)) {
      account.level = 0;
      rootAccounts.add(account);
    } else {
      final parent = accountMap[account.parentId]!;
      account.level = parent.level + 1;
      parent.children.add(account);
    }
  }

  // Sort by code
  rootAccounts.sort((a, b) => a.code.compareTo(b.code));
  for (final account in accountMap.values) {
    account.children.sort((a, b) => a.code.compareTo(b.code));
  }

  return rootAccounts;
}

/// Get account by ID
@riverpod
Future<AccountModel?> account(AccountRef ref, String id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.accounts)..where((t) => t.id.equals(id)))
      .getSingleOrNull()
      .then((row) => row != null ? AccountModel.fromDrift(row) : null);
}

@riverpod
class AccountsNotifier extends _$AccountsNotifier {
  @override
  Stream<List<AccountModel>> build() {
    final db = ref.watch(databaseProvider);
    return db
        .select(db.accounts)
        .watch()
        .map((rows) => rows.map(AccountModel.fromDrift).toList());
  }

  /// Generate next account code based on type
  Future<String> _generateCode(String type) async {
    final db = ref.read(databaseProvider);
    final accounts = await (db.select(db.accounts)
          ..where((t) => t.type.equals(type)))
        .get();
    
    final prefix = switch (type) {
      'asset' => 1000,
      'liability' => 2000,
      'equity' => 3000,
      'income' => 4000,
      'expense' => 5000,
      _ => 1000,
    };

    final maxCode = accounts.isEmpty
        ? prefix
        : accounts.map((a) => int.tryParse(a.code) ?? prefix).reduce((a, b) => a > b ? a : b);

    return (maxCode + 1).toString();
  }

  Future<AccountModel> create(AccountFormData data) async {
    final db = ref.read(databaseProvider);
    final id = _uuid.v4();
    final now = DateTime.now();

    final code = data.code.isEmpty ? await _generateCode(data.type) : data.code;

    final companion = AccountsCompanion(
      id: drift.Value(id),
      code: drift.Value(code),
      name: drift.Value(data.name),
      type: drift.Value(data.type),
      parentId: drift.Value(data.parentId),
      balance: const drift.Value(0.0),
      normalBalance: drift.Value(data.normalBalance),
      description: drift.Value(data.description),
      isActive: drift.Value(data.isActive),
      isHeader: drift.Value(data.isHeader),
      sortOrder: drift.Value(data.sortOrder),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await db.into(db.accounts).insert(companion);

    return AccountModel(
      id: id,
      code: code,
      name: data.name,
      type: data.type,
      parentId: data.parentId,
      normalBalance: data.normalBalance,
      description: data.description,
      isActive: data.isActive,
      isHeader: data.isHeader,
      sortOrder: data.sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> update(String id, AccountFormData data) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        code: drift.Value(data.code),
        name: drift.Value(data.name),
        type: drift.Value(data.type),
        parentId: drift.Value(data.parentId),
        normalBalance: drift.Value(data.normalBalance),
        description: drift.Value(data.description),
        isActive: drift.Value(data.isActive),
        isHeader: drift.Value(data.isHeader),
        sortOrder: drift.Value(data.sortOrder),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    // Check if account has children
    final children = await (db.select(db.accounts)
          ..where((t) => t.parentId.equals(id)))
        .get();
    if (children.isNotEmpty) {
      throw Exception('لا يمكن حذف الحساب لأنه يحتوي على حسابات فرعية');
    }
    await (db.delete(db.accounts)..where((t) => t.id.equals(id))).go();
  }

  /// Update account balance
  Future<void> updateBalance(String id, double delta) async {
    final db = ref.read(databaseProvider);
    final account = await (db.select(db.accounts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    
    if (account != null) {
      final newBalance = account.balance + delta;
      await (db.update(db.accounts)..where((t) => t.id.equals(id))).write(
        AccountsCompanion(
          balance: drift.Value(newBalance),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }
}

// ==================== ACCOUNT STATISTICS ====================

@riverpod
Future<AccountStats> accountStats(AccountStatsRef ref) async {
  final db = ref.watch(databaseProvider);

  final allAccounts = await db.select(db.accounts).get();
  
  final totalAssets = allAccounts
      .where((a) => a.type == 'asset')
      .fold<double>(0, (sum, a) => sum + a.balance);
  
  final totalLiabilities = allAccounts
      .where((a) => a.type == 'liability')
      .fold<double>(0, (sum, a) => sum + a.balance);
  
  final totalEquity = allAccounts
      .where((a) => a.type == 'equity')
      .fold<double>(0, (sum, a) => sum + a.balance);
  
  final totalIncome = allAccounts
      .where((a) => a.type == 'income')
      .fold<double>(0, (sum, a) => sum + a.balance);
  
  final totalExpenses = allAccounts
      .where((a) => a.type == 'expense')
      .fold<double>(0, (sum, a) => sum + a.balance);

  return AccountStats(
    total: allAccounts.length,
    assets: allAccounts.where((a) => a.type == 'asset').length,
    liabilities: allAccounts.where((a) => a.type == 'liability').length,
    equity: allAccounts.where((a) => a.type == 'equity').length,
    income: allAccounts.where((a) => a.type == 'income').length,
    expenses: allAccounts.where((a) => a.type == 'expense').length,
    totalAssets: totalAssets,
    totalLiabilities: totalLiabilities,
    totalEquity: totalEquity,
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    netIncome: totalIncome - totalExpenses,
  );
}

class AccountStats {
  final int total;
  final int assets;
  final int liabilities;
  final int equity;
  final int income;
  final int expenses;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;

  AccountStats({
    required this.total,
    required this.assets,
    required this.liabilities,
    required this.equity,
    required this.income,
    required this.expenses,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
  });
}
