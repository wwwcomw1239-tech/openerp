import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/drift/database.dart';
import 'database_provider.dart';

part 'dashboard_provider.g.dart';

/// Dashboard statistics model
class DashboardStats {
  final double totalSales;
  final double totalPurchases;
  final double netProfit;
  final int customersCount;
  final int suppliersCount;
  final int productsCount;
  final int invoicesCount;
  final double totalReceivables;
  final double totalPayables;
  final List<MonthlyData> salesTrend;
  final List<MonthlyData> purchasesTrend;

  DashboardStats({
    this.totalSales = 0,
    this.totalPurchases = 0,
    this.netProfit = 0,
    this.customersCount = 0,
    this.suppliersCount = 0,
    this.productsCount = 0,
    this.invoicesCount = 0,
    this.totalReceivables = 0,
    this.totalPayables = 0,
    this.salesTrend = const [],
    this.purchasesTrend = const [],
  });
}

/// Monthly data for charts
class MonthlyData {
  final String month;
  final double amount;

  MonthlyData({required this.month, required this.amount});
}

/// Dashboard statistics provider
@riverpod
Future<DashboardStats> dashboardStats(DashboardStatsRef ref) async {
  final db = ref.watch(databaseProvider);
  
  // Get all data
  final customers = await db.select(db.customers).get();
  final suppliers = await db.select(db.suppliers).get();
  final products = await db.select(db.products).get();
  final invoices = await db.select(db.invoices).get();
  final purchases = await db.select(db.purchases).get();
  
  // Calculate totals
  final totalSales = invoices.fold<double>(0, (sum, inv) => sum + inv.total);
  final totalPurchases = purchases.fold<double>(0, (sum, pur) => sum + pur.total);
  final netProfit = totalSales - totalPurchases;
  
  // Calculate receivables and payables
  final totalReceivables = customers.fold<double>(0, (sum, c) => sum + c.balance);
  final totalPayables = suppliers.fold<double>(0, (sum, s) => sum + s.balance);
  
  // Generate monthly trend data (last 6 months)
  final salesTrend = _generateMonthlyTrend(invoices, (inv) => inv.date, (inv) => inv.total);
  final purchasesTrend = _generateMonthlyTrend(purchases, (pur) => pur.date, (pur) => pur.total);
  
  return DashboardStats(
    totalSales: totalSales,
    totalPurchases: totalPurchases,
    netProfit: netProfit,
    customersCount: customers.length,
    suppliersCount: suppliers.length,
    productsCount: products.length,
    invoicesCount: invoices.length,
    totalReceivables: totalReceivables,
    totalPayables: totalPayables,
    salesTrend: salesTrend,
    purchasesTrend: purchasesTrend,
  );
}

/// Generate monthly trend data
List<MonthlyData> _generateMonthlyTrend<T>(
  List<T> items,
  DateTime Function(T) getDate,
  double Function(T) getAmount,
) {
  final now = DateTime.now();
  final monthlyData = <String, double>{};
  
  // Initialize last 6 months with 0
  for (int i = 5; i >= 0; i--) {
    final date = DateTime(now.year, now.month - i, 1);
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    monthlyData[key] = 0;
  }
  
  // Aggregate data
  for (final item in items) {
    final date = getDate(item);
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    if (monthlyData.containsKey(key)) {
      monthlyData[key] = (monthlyData[key] ?? 0) + getAmount(item);
    }
  }
  
  // Convert to list
  final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
                  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  
  return monthlyData.entries.map((e) {
    final parts = e.key.split('-');
    final monthIndex = int.parse(parts[1]) - 1;
    return MonthlyData(
      month: months[monthIndex],
      amount: e.value,
    );
  }).toList();
}

/// Recent invoices provider
@riverpod
Future<List<InvoiceSummary>> recentInvoices(RecentInvoicesRef ref) async {
  final db = ref.watch(databaseProvider);
  
  final query = db.select(db.invoices)
    ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
    ..limit(5);
  final invoices = await query.get();
  
  final summaries = <InvoiceSummary>[];
  for (final invoice in invoices) {
    final customer = await (db.select(db.customers)
          ..where((t) => t.id.equals(invoice.customerId)))
        .getSingleOrNull();
    
    summaries.add(InvoiceSummary(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      customerName: customer?.name ?? 'غير معروف',
      total: invoice.total,
      status: invoice.status,
      date: invoice.date,
    ));
  }
  
  return summaries;
}

/// Invoice summary model
class InvoiceSummary {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final double total;
  final String status;
  final DateTime date;

  InvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.total,
    required this.status,
    required this.date,
  });
}

/// Recent purchases provider
@riverpod
Future<List<PurchaseSummary>> recentPurchases(RecentPurchasesRef ref) async {
  final db = ref.watch(databaseProvider);
  
  final query = db.select(db.purchases)
    ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
    ..limit(5);
  final purchases = await query.get();
  
  final summaries = <PurchaseSummary>[];
  for (final purchase in purchases) {
    final supplier = await (db.select(db.suppliers)
          ..where((t) => t.id.equals(purchase.supplierId)))
        .getSingleOrNull();
    
    summaries.add(PurchaseSummary(
      id: purchase.id,
      purchaseNumber: purchase.purchaseNumber,
      supplierName: supplier?.name ?? 'غير معروف',
      total: purchase.total,
      status: purchase.status,
      date: purchase.date,
    ));
  }
  
  return summaries;
}

/// Purchase summary model
class PurchaseSummary {
  final String id;
  final String purchaseNumber;
  final String supplierName;
  final double total;
  final String status;
  final DateTime date;

  PurchaseSummary({
    required this.id,
    required this.purchaseNumber,
    required this.supplierName,
    required this.total,
    required this.status,
    required this.date,
  });
}

/// Top customers provider
@riverpod
Future<List<TopCustomer>> topCustomers(TopCustomersRef ref) async {
  final db = ref.watch(databaseProvider);
  
  final customers = await db.select(db.customers).get();
  
  final topCustomers = customers.map((c) {
    return TopCustomer(
      id: c.id,
      name: c.name,
      balance: c.balance,
      creditLimit: c.creditLimit,
    );
  }).toList()
    ..sort((a, b) => b.balance.compareTo(a.balance));
  
  return topCustomers.take(5).toList();
}

/// Top customer model
class TopCustomer {
  final String id;
  final String name;
  final double balance;
  final double creditLimit;

  TopCustomer({
    required this.id,
    required this.name,
    required this.balance,
    required this.creditLimit,
  });
}

/// Inventory alerts provider
@riverpod
Future<List<InventoryAlert>> inventoryAlerts(InventoryAlertsRef ref) async {
  final db = ref.watch(databaseProvider);
  
  final products = await db.select(db.products).get();
  final alerts = <InventoryAlert>[];
  
  for (final product in products) {
    if (product.quantity <= product.minQuantity) {
      alerts.add(InventoryAlert(
        productId: product.id,
        productName: product.name,
        currentQuantity: product.quantity,
        minQuantity: product.minQuantity,
        alertType: product.quantity == 0 
            ? InventoryAlertType.outOfStock 
            : InventoryAlertType.lowStock,
      ));
    }
  }
  
  return alerts;
}

/// Inventory alert model
class InventoryAlert {
  final String productId;
  final String productName;
  final double currentQuantity;
  final double minQuantity;
  final InventoryAlertType alertType;

  InventoryAlert({
    required this.productId,
    required this.productName,
    required this.currentQuantity,
    required this.minQuantity,
    required this.alertType,
  });
}

enum InventoryAlertType { lowStock, outOfStock }
