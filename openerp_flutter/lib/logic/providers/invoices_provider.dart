import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/drift/database.dart';
import 'database_provider.dart';
import 'products_provider.dart';
import 'customers_provider.dart';

part 'invoices_provider.g.dart';

/// UUID generator
final _uuid = const Uuid();

// ==================== INVOICE ITEM MODEL ====================

class InvoiceItemModel {
  final String id;
  final String invoiceId;
  final String productId;
  final String? description;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double taxRate;
  final double total;
  final DateTime createdAt;

  InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.productId,
    this.description,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.discount = 0.0,
    this.taxRate = 0.0,
    this.total = 0.0,
    required this.createdAt,
  });

  factory InvoiceItemModel.fromDrift(InvoiceItem item) {
    return InvoiceItemModel(
      id: item.id,
      invoiceId: item.invoiceId,
      productId: item.productId,
      description: item.description,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      discount: item.discount,
      taxRate: item.taxRate,
      total: item.total,
      createdAt: item.createdAt,
    );
  }

  double get lineTotal => (quantity * unitPrice) - discount;
  double get taxAmount => lineTotal * (taxRate / 100);
  double get totalWithTax => lineTotal + taxAmount;
}

class InvoiceItemFormData {
  String productId;
  String? description;
  double quantity;
  double unitPrice;
  double discount;
  double taxRate;

  InvoiceItemFormData({
    this.productId = '',
    this.description,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.discount = 0.0,
    this.taxRate = 15.0, // Default VAT
  });

  double get lineTotal => (quantity * unitPrice) - discount;
  double get taxAmount => lineTotal * (taxRate / 100);
  double get totalWithTax => lineTotal + taxAmount;
}

// ==================== INVOICE MODEL ====================

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String userId;
  final DateTime date;
  final DateTime? dueDate;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double discount;
  final double total;
  final double paidAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.userId,
    required this.date,
    this.dueDate,
    this.status = 'draft',
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.paidAmount = 0.0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvoiceModel.fromDrift(Invoice invoice) {
    return InvoiceModel(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      customerId: invoice.customerId,
      userId: invoice.userId,
      date: invoice.date,
      dueDate: invoice.dueDate,
      status: invoice.status,
      subtotal: invoice.subtotal,
      taxAmount: invoice.taxAmount,
      discount: invoice.discount,
      total: invoice.total,
      paidAmount: invoice.paidAmount,
      notes: invoice.notes,
      createdAt: invoice.createdAt,
      updatedAt: invoice.updatedAt,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isConfirmed => status == 'confirmed';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';
  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < total;
  bool get isFullyPaid => paidAmount >= total && total > 0;
  double get balanceDue => total - paidAmount;
}

/// Invoice with items for detailed view
class InvoiceWithItems {
  final InvoiceModel invoice;
  final List<InvoiceItemModel> items;
  final CustomerModel? customer;

  InvoiceWithItems({
    required this.invoice,
    required this.items,
    this.customer,
  });
}

class InvoiceFormData {
  String customerId;
  DateTime date;
  DateTime? dueDate;
  String status;
  double discount;
  String? notes;
  List<InvoiceItemFormData> items;

  InvoiceFormData({
    this.customerId = '',
    DateTime? date,
    this.dueDate,
    this.status = 'draft',
    this.discount = 0.0,
    this.notes,
    List<InvoiceItemFormData>? items,
  })  : date = date ?? DateTime.now(),
        items = items ?? [];

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get taxAmount => items.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get total => subtotal + taxAmount - discount;
}

// ==================== INVOICE PROVIDERS ====================

@riverpod
Stream<List<InvoiceModel>> invoices(InvoicesRef ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.invoices)
      .watch()
      .map((rows) => rows.map(InvoiceModel.fromDrift).toList());
}

@riverpod
Future<InvoiceWithItems?> invoiceWithItems(InvoiceWithItemsRef ref, String id) async {
  final db = ref.watch(databaseProvider);
  
  final invoice = await (db.select(db.invoices)..where((t) => t.id.equals(id)))
      .getSingleOrNull();
  
  if (invoice == null) return null;
  
  final items = await (db.select(db.invoiceItems)..where((t) => t.invoiceId.equals(id)))
      .get();
  
  final customer = await (db.select(db.customers)..where((t) => t.id.equals(invoice.customerId)))
      .getSingleOrNull();
  
  return InvoiceWithItems(
    invoice: InvoiceModel.fromDrift(invoice),
    items: items.map(InvoiceItemModel.fromDrift).toList(),
    customer: customer != null ? CustomerModel.fromDrift(customer) : null,
  );
}

@riverpod
Stream<List<InvoiceItemModel>> invoiceItems(InvoiceItemsRef ref, String invoiceId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.invoiceItems)..where((t) => t.invoiceId.equals(invoiceId)))
      .watch()
      .map((rows) => rows.map(InvoiceItemModel.fromDrift).toList());
}

@riverpod
Stream<List<InvoiceModel>> invoicesByStatus(InvoicesByStatusRef ref, String status) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.invoices)..where((t) => t.status.equals(status)))
      .watch()
      .map((rows) => rows.map(InvoiceModel.fromDrift).toList());
}

@riverpod
Stream<List<InvoiceModel>> invoicesByCustomer(InvoicesByCustomerRef ref, String customerId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.invoices)..where((t) => t.customerId.equals(customerId)))
      .watch()
      .map((rows) => rows.map(InvoiceModel.fromDrift).toList());
}

@riverpod
class InvoicesNotifier extends _$InvoicesNotifier {
  @override
  Stream<List<InvoiceModel>> build() {
    final db = ref.watch(databaseProvider);
    return db
        .select(db.invoices)
        .watch()
        .map((rows) => rows.map(InvoiceModel.fromDrift).toList());
  }

  /// Generate next invoice number
  Future<String> _generateInvoiceNumber() async {
    final db = ref.read(databaseProvider);
    final count = await db.invoices.count().getSingle();
    return 'INV-${(count + 1).toString().padLeft(6, '0')}';
  }

  /// Create invoice with items and update stock
  Future<InvoiceModel> create(InvoiceFormData data, String userId) async {
    final db = ref.read(databaseProvider);
    final id = _uuid.v4();
    final invoiceNumber = await _generateInvoiceNumber();
    final now = DateTime.now();

    // Calculate totals
    final subtotal = data.subtotal;
    final taxAmount = data.taxAmount;
    final total = data.total;

    await db.transaction(() async {
      // Insert invoice
      await db.into(db.invoices).insert(
        InvoicesCompanion(
          id: drift.Value(id),
          invoiceNumber: drift.Value(invoiceNumber),
          customerId: drift.Value(data.customerId),
          userId: drift.Value(userId),
          date: drift.Value(data.date),
          dueDate: drift.Value(data.dueDate),
          status: drift.Value(data.status),
          subtotal: drift.Value(subtotal),
          taxAmount: drift.Value(taxAmount),
          discount: drift.Value(data.discount),
          total: drift.Value(total),
          paidAmount: const drift.Value(0.0),
          notes: drift.Value(data.notes),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Insert items and update stock
      for (final item in data.items) {
        final itemId = _uuid.v4();
        
        await db.into(db.invoiceItems).insert(
          InvoiceItemsCompanion(
            id: drift.Value(itemId),
            invoiceId: drift.Value(id),
            productId: drift.Value(item.productId),
            description: drift.Value(item.description),
            quantity: drift.Value(item.quantity),
            unitPrice: drift.Value(item.unitPrice),
            discount: drift.Value(item.discount),
            taxRate: drift.Value(item.taxRate),
            total: drift.Value(item.totalWithTax),
            createdAt: drift.Value(now),
          ),
        );

        // Deduct stock if invoice is confirmed
        if (data.status == 'confirmed' || data.status == 'paid') {
          await _adjustProductStock(item.productId, -item.quantity);
        }
      }

      // Update customer balance if confirmed
      if (data.status == 'confirmed' || data.status == 'paid') {
        await _updateCustomerBalance(data.customerId, total);
      }
    });

    return InvoiceModel(
      id: id,
      invoiceNumber: invoiceNumber,
      customerId: data.customerId,
      userId: userId,
      date: data.date,
      dueDate: data.dueDate,
      status: data.status,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discount: data.discount,
      total: total,
      paidAmount: 0.0,
      notes: data.notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update invoice status
  Future<void> updateStatus(String id, String newStatus) async {
    final db = ref.read(databaseProvider);
    final invoice = await (db.select(db.invoices)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    
    if (invoice == null) return;

    final oldStatus = invoice.status;
    
    await db.transaction(() async {
      await (db.update(db.invoices)..where((t) => t.id.equals(id))).write(
        InvoicesCompanion(
          status: drift.Value(newStatus),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // If confirming draft, deduct stock and update customer balance
      if (oldStatus == 'draft' && (newStatus == 'confirmed' || newStatus == 'paid')) {
        final items = await (db.select(db.invoiceItems)..where((t) => t.invoiceId.equals(id))).get();
        
        for (final item in items) {
          await _adjustProductStock(item.productId, -item.quantity);
        }
        
        await _updateCustomerBalance(invoice.customerId, invoice.total);
      }

      // If cancelling confirmed invoice, restore stock and reverse customer balance
      if ((oldStatus == 'confirmed' || oldStatus == 'paid') && newStatus == 'cancelled') {
        final items = await (db.select(db.invoiceItems)..where((t) => t.invoiceId.equals(id))).get();
        
        for (final item in items) {
          await _adjustProductStock(item.productId, item.quantity);
        }
        
        await _updateCustomerBalance(invoice.customerId, -invoice.total);
      }
    });
  }

  /// Add payment to invoice
  Future<void> addPayment(String invoiceId, double amount) async {
    final db = ref.read(databaseProvider);
    final invoice = await (db.select(db.invoices)..where((t) => t.id.equals(invoiceId)))
        .getSingleOrNull();
    
    if (invoice == null) return;

    final newPaidAmount = invoice.paidAmount + amount;
    final newStatus = newPaidAmount >= invoice.total ? 'paid' : invoice.status;

    await db.transaction(() async {
      await (db.update(db.invoices)..where((t) => t.id.equals(invoiceId))).write(
        InvoicesCompanion(
          paidAmount: drift.Value(newPaidAmount),
          status: drift.Value(newStatus),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // Update customer balance (reduce receivables)
      await _updateCustomerBalance(invoice.customerId, -amount);
    });
  }

  /// Delete invoice (only drafts)
  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    final invoice = await (db.select(db.invoices)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    
    if (invoice == null) return;
    
    if (invoice.status != 'draft') {
      throw Exception('Cannot delete confirmed or paid invoices');
    }

    // Delete items first (cascade)
    await (db.delete(db.invoiceItems)..where((t) => t.invoiceId.equals(id))).go();
    // Delete invoice
    await (db.delete(db.invoices)..where((t) => t.id.equals(id))).go();
  }

  /// Helper: Adjust product stock
  Future<void> _adjustProductStock(String productId, double delta) async {
    final db = ref.read(databaseProvider);
    final product = await (db.select(db.products)..where((t) => t.id.equals(productId)))
        .getSingleOrNull();
    
    if (product != null) {
      final newQuantity = product.quantity + delta;
      await (db.update(db.products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
          quantity: drift.Value(newQuantity),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  /// Helper: Update customer balance
  Future<void> _updateCustomerBalance(String customerId, double delta) async {
    final db = ref.read(databaseProvider);
    final customer = await (db.select(db.customers)..where((t) => t.id.equals(customerId)))
        .getSingleOrNull();
    
    if (customer != null) {
      final newBalance = customer.balance + delta;
      await (db.update(db.customers)..where((t) => t.id.equals(customerId))).write(
        CustomersCompanion(
          balance: drift.Value(newBalance),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }
}

// ==================== INVOICE STATISTICS ====================

@riverpod
Future<InvoiceStats> invoiceStats(InvoiceStatsRef ref) async {
  final db = ref.watch(databaseProvider);

  final allInvoices = await db.select(db.invoices).get();
  final draftCount = allInvoices.where((i) => i.status == 'draft').length;
  final confirmedCount = allInvoices.where((i) => i.status == 'confirmed').length;
  final paidCount = allInvoices.where((i) => i.status == 'paid').length;
  final cancelledCount = allInvoices.where((i) => i.status == 'cancelled').length;
  
  final totalSales = allInvoices.fold<double>(0, (sum, i) => sum + i.total);
  final totalPaid = allInvoices.fold<double>(0, (sum, i) => sum + i.paidAmount);
  final totalReceivables = totalSales - totalPaid;

  return InvoiceStats(
    total: allInvoices.length,
    draft: draftCount,
    confirmed: confirmedCount,
    paid: paidCount,
    cancelled: cancelledCount,
    totalSales: totalSales,
    totalPaid: totalPaid,
    totalReceivables: totalReceivables,
  );
}

class InvoiceStats {
  final int total;
  final int draft;
  final int confirmed;
  final int paid;
  final int cancelled;
  final double totalSales;
  final double totalPaid;
  final double totalReceivables;

  InvoiceStats({
    required this.total,
    required this.draft,
    required this.confirmed,
    required this.paid,
    required this.cancelled,
    required this.totalSales,
    required this.totalPaid,
    required this.totalReceivables,
  });
}
