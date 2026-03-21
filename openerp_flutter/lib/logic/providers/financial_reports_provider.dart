import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/drift/app_database.dart';
import 'database_provider.dart';
import 'accounts_provider.dart';
import 'journal_entries_provider.dart';

part 'financial_reports_provider.g.dart';

// ==================== TRIAL BALANCE ====================

class TrialBalanceItem {
  final String accountId;
  final String accountCode;
  final String accountName;
  final String accountType;
  final double debit;
  final double credit;

  TrialBalanceItem({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    this.debit = 0.0,
    this.credit = 0.0,
  });
}

class TrialBalance {
  final List<TrialBalanceItem> items;
  final double totalDebit;
  final double totalCredit;
  final DateTime asOfDate;
  final bool isBalanced;

  TrialBalance({
    required this.items,
    required this.totalDebit,
    required this.totalCredit,
    required this.asOfDate,
    required this.isBalanced,
  });
}

@riverpod
Future<TrialBalance> trialBalance(TrialBalanceRef ref) async {
  final db = ref.watch(databaseProvider);

  final accounts = await db.select(db.accounts).get();
  final postedEntries = await (db.select(db.journalEntries)
        ..where((t) => t.status.equals('posted')))
      .get();

  // Get all journal lines for posted entries
  final postedEntryIds = postedEntries.map((e) => e.id).toList();
  final allLines = await (db.select(db.journalLines)
          ..where((t) => t.journalEntryId.isIn(postedEntryIds)))
      .get();

  // Group lines by account
  final accountLines = <String, List<JournalLine>>{};
  for (final line in allLines) {
    accountLines.putIfAbsent(line.accountId, () => []).add(line);
  }

  final items = <TrialBalanceItem>[];
  double totalDebit = 0;
  double totalCredit = 0;

  for (final account in accounts) {
    if (account.isHeader) continue;

    final lines = accountLines[account.id] ?? [];
    final accountDebit = lines.fold<double>(0, (sum, l) => sum + l.debit);
    final accountCredit = lines.fold<double>(0, (sum, l) => sum + l.credit);

    if (accountDebit == 0 && accountCredit == 0) continue;

    items.add(TrialBalanceItem(
      accountId: account.id,
      accountCode: account.code,
      accountName: account.name,
      accountType: account.type,
      debit: accountDebit,
      credit: accountCredit,
    ));

    totalDebit += accountDebit;
    totalCredit += accountCredit;
  }

  // Sort by account code
  items.sort((a, b) => a.accountCode.compareTo(b.accountCode));

  return TrialBalance(
    items: items,
    totalDebit: totalDebit,
    totalCredit: totalCredit,
    asOfDate: DateTime.now(),
    isBalanced: (totalDebit - totalCredit).abs() < 0.01,
  );
}

// ==================== INCOME STATEMENT ====================

class IncomeStatementItem {
  final String accountId;
  final String accountCode;
  final String accountName;
  final double amount;

  IncomeStatementItem({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    this.amount = 0.0,
  });
}

class IncomeStatementSection {
  final String title;
  final List<IncomeStatementItem> items;
  final double total;

  IncomeStatementSection({
    required this.title,
    required this.items,
    required this.total,
  });
}

class IncomeStatement {
  final IncomeStatementSection revenue;
  final IncomeStatementSection expenses;
  final double grossProfit;
  final double netIncome;
  final DateTime fromDate;
  final DateTime toDate;

  IncomeStatement({
    required this.revenue,
    required this.expenses,
    required this.grossProfit,
    required this.netIncome,
    required this.fromDate,
    required this.toDate,
  });
}

@riverpod
Future<IncomeStatement> incomeStatement(IncomeStatementRef ref) async {
  final db = ref.watch(databaseProvider);

  // Get revenue accounts
  final revenueAccounts = await (db.select(db.accounts)
          ..where((t) => t.type.equals('income')))
      .get();

  // Get expense accounts
  final expenseAccounts = await (db.select(db.accounts)
          ..where((t) => t.type.equals('expense')))
      .get();

  final revenueItems = <IncomeStatementItem>[];
  final expenseItems = <IncomeStatementItem>[];
  double totalRevenue = 0;
  double totalExpenses = 0;

  // Process revenue (credit normal)
  for (final account in revenueAccounts) {
    if (account.isHeader) continue;
    // For income accounts, display balance is positive (credit normal)
    final amount = account.balance.abs();
    if (amount > 0) {
      revenueItems.add(IncomeStatementItem(
        accountId: account.id,
        accountCode: account.code,
        accountName: account.name,
        amount: amount,
      ));
      totalRevenue += amount;
    }
  }

  // Process expenses (debit normal)
  for (final account in expenseAccounts) {
    if (account.isHeader) continue;
    final amount = account.balance.abs();
    if (amount > 0) {
      expenseItems.add(IncomeStatementItem(
        accountId: account.id,
        accountCode: account.code,
        accountName: account.name,
        amount: amount,
      ));
      totalExpenses += amount;
    }
  }

  // Sort by code
  revenueItems.sort((a, b) => a.accountCode.compareTo(b.accountCode));
  expenseItems.sort((a, b) => a.accountCode.compareTo(b.accountCode));

  final netIncome = totalRevenue - totalExpenses;

  return IncomeStatement(
    revenue: IncomeStatementSection(
      title: 'الإيرادات',
      items: revenueItems,
      total: totalRevenue,
    ),
    expenses: IncomeStatementSection(
      title: 'المصروفات',
      items: expenseItems,
      total: totalExpenses,
    ),
    grossProfit: totalRevenue,
    netIncome: netIncome,
    fromDate: DateTime(DateTime.now().year, 1, 1),
    toDate: DateTime.now(),
  );
}

// ==================== BALANCE SHEET ====================

class BalanceSheetItem {
  final String accountId;
  final String accountCode;
  final String accountName;
  final double amount;

  BalanceSheetItem({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    this.amount = 0.0,
  });
}

class BalanceSheetSection {
  final String title;
  final List<BalanceSheetItem> items;
  final double total;

  BalanceSheetSection({
    required this.title,
    required this.items,
    required this.total,
  });
}

class BalanceSheet {
  final BalanceSheetSection assets;
  final BalanceSheetSection liabilities;
  final BalanceSheetSection equity;
  final double totalAssets;
  final double totalLiabilitiesAndEquity;
  final bool isBalanced;
  final DateTime asOfDate;

  BalanceSheet({
    required this.assets,
    required this.liabilities,
    required this.equity,
    required this.totalAssets,
    required this.totalLiabilitiesAndEquity,
    required this.isBalanced,
    required this.asOfDate,
  });
}

@riverpod
Future<BalanceSheet> balanceSheet(BalanceSheetRef ref) async {
  final db = ref.watch(databaseProvider);

  // Get accounts by type
  final assetAccounts = await (db.select(db.accounts)
          ..where((t) => t.type.equals('asset')))
      .get();

  final liabilityAccounts = await (db.select(db.accounts)
          ..where((t) => t.type.equals('liability')))
      .get();

  final equityAccounts = await (db.select(db.accounts)
          ..where((t) => t.type.equals('equity')))
      .get();

  // Also get net income to add to equity
  final incomeStatement = await ref.watch(incomeStatementProvider.future);

  final assetItems = <BalanceSheetItem>[];
  final liabilityItems = <BalanceSheetItem>[];
  final equityItems = <BalanceSheetItem>[];

  double totalAssets = 0;
  double totalLiabilities = 0;
  double totalEquity = 0;

  // Process assets (debit normal)
  for (final account in assetAccounts) {
    if (account.isHeader) continue;
    final amount = account.balance.abs();
    if (amount != 0) {
      assetItems.add(BalanceSheetItem(
        accountId: account.id,
        accountCode: account.code,
        accountName: account.name,
        amount: amount,
      ));
      totalAssets += amount;
    }
  }

  // Process liabilities (credit normal)
  for (final account in liabilityAccounts) {
    if (account.isHeader) continue;
    final amount = account.balance.abs();
    if (amount != 0) {
      liabilityItems.add(BalanceSheetItem(
        accountId: account.id,
        accountCode: account.code,
        accountName: account.name,
        amount: amount,
      ));
      totalLiabilities += amount;
    }
  }

  // Process equity (credit normal)
  for (final account in equityAccounts) {
    if (account.isHeader) continue;
    final amount = account.balance.abs();
    if (amount != 0) {
      equityItems.add(BalanceSheetItem(
        accountId: account.id,
        accountCode: account.code,
        accountName: account.name,
        amount: amount,
      ));
      totalEquity += amount;
    }
  }

  // Add retained earnings (net income) to equity
  if (incomeStatement.netIncome != 0) {
    equityItems.add(BalanceSheetItem(
      accountId: 'retained-earnings',
      accountCode: '3999',
      accountName: 'الأرباح المحتجزة',
      amount: incomeStatement.netIncome,
    ));
    totalEquity += incomeStatement.netIncome;
  }

  // Sort by code
  assetItems.sort((a, b) => a.accountCode.compareTo(b.accountCode));
  liabilityItems.sort((a, b) => a.accountCode.compareTo(b.accountCode));
  equityItems.sort((a, b) => a.accountCode.compareTo(b.accountCode));

  final totalLiabilitiesAndEquity = totalLiabilities + totalEquity;

  return BalanceSheet(
    assets: BalanceSheetSection(
      title: 'الأصول',
      items: assetItems,
      total: totalAssets,
    ),
    liabilities: BalanceSheetSection(
      title: 'الخصوم',
      items: liabilityItems,
      total: totalLiabilities,
    ),
    equity: BalanceSheetSection(
      title: 'حقوق الملكية',
      items: equityItems,
      total: totalEquity,
    ),
    totalAssets: totalAssets,
    totalLiabilitiesAndEquity: totalLiabilitiesAndEquity,
    isBalanced: (totalAssets - totalLiabilitiesAndEquity).abs() < 0.01,
    asOfDate: DateTime.now(),
  );
}

// ==================== DASHBOARD FINANCIAL SUMMARY ====================

class FinancialSummary {
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final double totalRevenue;
  final double totalExpenses;
  final double netIncome;
  final double accountsReceivable;
  final double accountsPayable;
  final double cashBalance;
  final int totalJournalEntries;

  FinancialSummary({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netIncome,
    required this.accountsReceivable,
    required this.accountsPayable,
    required this.cashBalance,
    required this.totalJournalEntries,
  });
}

@riverpod
Future<FinancialSummary> financialSummary(FinancialSummaryRef ref) async {
  final db = ref.watch(databaseProvider);

  final accounts = await db.select(db.accounts).get();
  final journalEntries = await (db.select(db.journalEntries)
          ..where((t) => t.status.equals('posted')))
      .get();

  double totalAssets = 0;
  double totalLiabilities = 0;
  double totalEquity = 0;
  double totalRevenue = 0;
  double totalExpenses = 0;
  double accountsReceivable = 0;
  double accountsPayable = 0;
  double cashBalance = 0;

  for (final account in accounts) {
    if (account.isHeader) continue;

    final balance = account.balance.abs();

    switch (account.type) {
      case 'asset':
        totalAssets += balance;
        // Check for specific accounts
        if (account.code.startsWith('1')) {
          // Could be cash, receivables, etc.
          if (account.name.contains('نقدية') || account.name.contains('Cash')) {
            cashBalance += balance;
          }
          if (account.name.contains('ذمم') || account.name.contains('Receivable')) {
            accountsReceivable += balance;
          }
        }
        break;
      case 'liability':
        totalLiabilities += balance;
        if (account.name.contains('ذمم') || account.name.contains('Payable')) {
          accountsPayable += balance;
        }
        break;
      case 'equity':
        totalEquity += balance;
        break;
      case 'income':
        totalRevenue += balance;
        break;
      case 'expense':
        totalExpenses += balance;
        break;
    }
  }

  return FinancialSummary(
    totalAssets: totalAssets,
    totalLiabilities: totalLiabilities,
    totalEquity: totalEquity,
    totalRevenue: totalRevenue,
    totalExpenses: totalExpenses,
    netIncome: totalRevenue - totalExpenses,
    accountsReceivable: accountsReceivable,
    accountsPayable: accountsPayable,
    cashBalance: cashBalance,
    totalJournalEntries: journalEntries.length,
  );
}
