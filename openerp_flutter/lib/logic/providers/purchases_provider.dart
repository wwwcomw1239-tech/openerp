import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/drift/database.dart';
import 'database_provider.dart';
import 'products_provider.dart';
import 'suppliers_provider.dart';

part 'purchases_provider.g.dart';

/// UUID generator
final _uuid = const Uuid();

// ==================== PURCHASE ITEM MODEL ====================

class PurchaseItemModel {
  final String id;
  final String purchaseId;
  final String productId;
  final String? description;
  final double quantity;
  final double quantityReceived;
  final double unitPrice;
  final double total;
  final DateTime createdAt;

  PurchaseItemModel({
    required this.id,
    required this.purchaseId,
    required this.productId,
    this.description,
    this.quantity = 1.0,
    this.quantityReceived = 0.0,
    this.unitPrice = 0.0,
    this.total = 0.0,
    required this.createdAt,
  });

  factory PurchaseItemModel.fromDrift(PurchaseItem item) {
    return PurchaseItemModel(
      id: item.id,
      purchaseId: item.purchaseId,
      productId: item.productId,
      description: item.description,
      quantity: item.quantity,
      quantityReceived: item.quantityReceived,
      unitPrice: item.unitPrice,
      total: item.total,
      createdAt: item.createdAt,
    );
  }

  double get lineTotal => quantity * unitPrice;
  double get pendingQuantity => quantity - quantityReceived;
  bool get isFullyReceived => quantityReceived >= quantity;
}

class PurchaseItemFormData {
  String productId;
  String? description;
  double quantity;
  double unitPrice;

  PurchaseItemFormData({
    this.productId = '',
    this.description,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
  });

  double get lineTotal => quantity * unitPrice;
}

// ==================== PURCHASE MODEL ====================

class PurchaseModel {
  final String id;
  final String purchaseNumber;
  final String supplierId;
  final String userId;
  final DateTime date;
  final DateTime? expectedDate;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double shippingCost;
  final double total;
  final double paidAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PurchaseModel({
    required this.id,
    required this.purchaseNumber,
    required this.supplierId,
    required this.userId,
    required this.date,
    this.expectedDate,
    this.status = 'draft',
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.shippingCost = 0.0,
    this.total = 0.0,
    this.paidAmount = 0.0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PurchaseModel.fromDrift(Purchase purchase) {
    return PurchaseModel(
      id: purchase.id,
      purchaseNumber: purchase.purchaseNumber,
      supplierId: purchase.supplierId,
      userId: purchase.userId,
      date: purchase.date,
      expectedDate: purchase.expectedDate,
      status: purchase.status,
      subtotal: purchase.subtotal,
      taxAmount: purchase.taxAmount,
      shippingCost: purchase.shippingCost,
      total: purchase.total,
      paidAmount: purchase.paidAmount,
      notes: purchase.notes,
      createdAt: purchase.createdAt,
      updatedAt: purchase.updatedAt,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isConfirmed => status == 'confirmed';
  bool get isReceived => status == 'received';
  bool get isCancelled => status == 'cancelled';
  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < total;
  bool get isFullyPaid => paidAmount >= total && total > 0;
  double get balanceDue => total - paidAmount;
}

/// Purchase with items for detailed view
class PurchaseWithItems {
  final PurchaseModel purchase;
  final List<PurchaseItemModel> items;
  final SupplierModel? supplier;

  PurchaseWithItems({
    required this.purchase,
    required this.items,
    this.supplier,
  });
}

class PurchaseFormData {
  String supplierId;
  DateTime date;
  DateTime? expectedDate;
  String status;
  double shippingCost;
  String? notes;
  List<PurchaseItemFormData> items;

  PurchaseFormData({
    this.supplierId = '',
    DateTime? date,
    this.expectedDate,
    this.status = 'draft',
    this.shippingCost = 0.0,
    this.notes,
    List<PurchaseItemFormData>? items,
  })  : date = date ?? DateTime.now(),
        items = items ?? [];

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get total => subtotal + shippingCost;
}

// ==================== PURCHASE PROVIDERS ====================

@riverpod
Stream<List<PurchaseModel>> purchases(PurchasesRef ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.purchases)
      .watch()
      .map((rows) => rows.map(PurchaseModel.fromDrift).toList());
}

@riverpod
Future<PurchaseWithItems?> purchaseWithItems(PurchaseWithItemsRef ref, String id) async {
  final db = ref.watch(databaseProvider);

  final purchase = await (db.select(db.purchases)..where((t) => t.id.equals(id)))
      .getSingleOrNull();

  if (purchase == null) return null;

  final items = await (db.select(db.purchaseItems)..where((t) => t.purchaseId.equals(id)))
      .get();

  final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals(purchase.supplierId)))
      .getSingleOrNull();

  return PurchaseWithItems(
    purchase: PurchaseModel.fromDrift(purchase),
    items: items.map(PurchaseItemModel.fromDrift).toList(),
    supplier: supplier != null ? SupplierModel.fromDrift(supplier) : null,
  );
}

@riverpod
Stream<List<PurchaseItemModel>> purchaseItems(PurchaseItemsRef ref, String purchaseId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.purchaseItems)..where((t) => t.purchaseId.equals(purchaseId)))
      .watch()
      .map((rows) => rows.map(PurchaseItemModel.fromDrift).toList());
}

@riverpod
Stream<List<PurchaseModel>> purchasesByStatus(PurchasesByStatusRef ref, String status) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.purchases)..where((t) => t.status.equals(status)))
      .watch()
      .map((rows) => rows.map(PurchaseModel.fromDrift).toList());
}

@riverpod
Stream<List<PurchaseModel>> purchasesBySupplier(PurchasesBySupplierRef ref, String supplierId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.purchases)..where((t) => t.supplierId.equals(supplierId)))
      .watch()
      .map((rows) => rows.map(PurchaseModel.fromDrift).toList());
}

@riverpod
class PurchasesNotifier extends _$PurchasesNotifier {
  @override
  Stream<List<PurchaseModel>> build() {
    final db = ref.watch(databaseProvider);
    return db
        .select(db.purchases)
        .watch()
        .map((rows) => rows.map(PurchaseModel.fromDrift).toList());
  }

  /// Generate next purchase number
  Future<String> _generatePurchaseNumber() async {
    final db = ref.read(databaseProvider);
    final count = await db.purchases.count().getSingle();
    return 'PO-${(count + 1).toString().padLeft(6, '0')}';
  }

  /// Create purchase with items
  Future<PurchaseModel> create(PurchaseFormData data, String userId) async {
    final db = ref.read(databaseProvider);
    final id = _uuid.v4();
    final purchaseNumber = await _generatePurchaseNumber();
    final now = DateTime.now();

    // Calculate totals
    final subtotal = data.subtotal;
    final total = data.total;

    await db.transaction(() async {
      // Insert purchase
      await db.into(db.purchases).insert(
        PurchasesCompanion(
          id: drift.Value(id),
          purchaseNumber: drift.Value(purchaseNumber),
          supplierId: drift.Value(data.supplierId),
          userId: drift.Value(userId),
          date: drift.Value(data.date),
          expectedDate: drift.Value(data.expectedDate),
          status: drift.Value(data.status),
          subtotal: drift.Value(subtotal),
          taxAmount: const drift.Value(0.0),
          shippingCost: drift.Value(data.shippingCost),
          total: drift.Value(total),
          paidAmount: const drift.Value(0.0),
          notes: drift.Value(data.notes),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Insert items
      for (final item in data.items) {
        final itemId = _uuid.v4();

        await db.into(db.purchaseItems).insert(
          PurchaseItemsCompanion(
            id: drift.Value(itemId),
            purchaseId: drift.Value(id),
            productId: drift.Value(item.productId),
            description: drift.Value(item.description),
            quantity: drift.Value(item.quantity),
            quantityReceived: const drift.Value(0.0),
            unitPrice: drift.Value(item.unitPrice),
            total: drift.Value(item.lineTotal),
            createdAt: drift.Value(now),
          ),
        );
      }

      // Update supplier balance if confirmed
      if (data.status == 'confirmed' || data.status == 'received') {
        await _updateSupplierBalance(data.supplierId, total);
      }
    });

    return PurchaseModel(
      id: id,
      purchaseNumber: purchaseNumber,
      supplierId: data.supplierId,
      userId: userId,
      date: data.date,
      expectedDate: data.expectedDate,
      status: data.status,
      subtotal: subtotal,
      taxAmount: 0.0,
      shippingCost: data.shippingCost,
      total: total,
      paidAmount: 0.0,
      notes: data.notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Mark purchase as received and update stock
  Future<void> markAsReceived(String id) async {
    final db = ref.read(databaseProvider);
    final purchase = await (db.select(db.purchases)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (purchase == null) return;
    if (purchase.status == 'received' || purchase.status == 'cancelled') return;

    await db.transaction(() async {
      // Update purchase status
      await (db.update(db.purchases)..where((t) => t.id.equals(id))).write(
        PurchasesCompanion(
          status: const drift.Value('received'),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // Update stock for each item
      final items = await (db.select(db.purchaseItems)..where((t) => t.purchaseId.equals(id))).get();

      for (final item in items) {
        // Update quantity received
        await (db.update(db.purchaseItems)..where((t) => t.id.equals(item.id))).write(
          PurchaseItemsCompanion(
            quantityReceived: drift.Value(item.quantity),
          ),
        );

        // Add to product stock
        await _adjustProductStock(item.productId, item.quantity);
      }
    });
  }

  /// Update purchase status
  Future<void> updateStatus(String id, String newStatus) async {
    final db = ref.read(databaseProvider);
    final purchase = await (db.select(db.purchases)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (purchase == null) return;

    final oldStatus = purchase.status;

    await db.transaction(() async {
      await (db.update(db.purchases)..where((t) => t.id.equals(id))).write(
        PurchasesCompanion(
          status: drift.Value(newStatus),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // If confirming draft, update supplier balance
      if (oldStatus == 'draft' && (newStatus == 'confirmed' || newStatus == 'received')) {
        await _updateSupplierBalance(purchase.supplierId, purchase.total);
      }

      // If cancelling, reverse supplier balance
      if ((oldStatus == 'confirmed' || oldStatus == 'received') && newStatus == 'cancelled') {
        await _updateSupplierBalance(purchase.supplierId, -purchase.total);
      }
    });
  }

  /// Add payment to purchase
  Future<void> addPayment(String purchaseId, double amount) async {
    final db = ref.read(databaseProvider);
    final purchase = await (db.select(db.purchases)..where((t) => t.id.equals(purchaseId)))
        .getSingleOrNull();

    if (purchase == null) return;

    final newPaidAmount = purchase.paidAmount + amount;

    await db.transaction(() async {
      await (db.update(db.purchases)..where((t) => t.id.equals(purchaseId))).write(
        PurchasesCompanion(
          paidAmount: drift.Value(newPaidAmount),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // Update supplier balance (reduce payables)
      await _updateSupplierBalance(purchase.supplierId, -amount);
    });
  }

  /// Delete purchase (only drafts)
  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    final purchase = await (db.select(db.purchases)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (purchase == null) return;

    if (purchase.status != 'draft') {
      throw Exception('Cannot delete confirmed or received purchases');
    }

    // Delete items first (cascade)
    await (db.delete(db.purchaseItems)..where((t) => t.purchaseId.equals(id))).go();
    // Delete purchase
    await (db.delete(db.purchases)..where((t) => t.id.equals(id))).go();
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

  /// Helper: Update supplier balance
  Future<void> _updateSupplierBalance(String supplierId, double delta) async {
    final db = ref.read(databaseProvider);
    final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals(supplierId)))
        .getSingleOrNull();

    if (supplier != null) {
      final newBalance = supplier.balance + delta;
      await (db.update(db.suppliers)..where((t) => t.id.equals(supplierId))).write(
        SuppliersCompanion(
          balance: drift.Value(newBalance),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }
}

// ==================== PURCHASE STATISTICS ====================

@riverpod
Future<PurchaseStats> purchaseStats(PurchaseStatsRef ref) async {
  final db = ref.watch(databaseProvider);

  final allPurchases = await db.select(db.purchases).get();
  final draftCount = allPurchases.where((p) => p.status == 'draft').length;
  final confirmedCount = allPurchases.where((p) => p.status == 'confirmed').length;
  final receivedCount = allPurchases.where((p) => p.status == 'received').length;
  final cancelledCount = allPurchases.where((p) => p.status == 'cancelled').length;

  final totalPurchases = allPurchases.fold<double>(0, (sum, p) => sum + p.total);
  final totalPaid = allPurchases.fold<double>(0, (sum, p) => sum + p.paidAmount);
  final totalPayables = totalPurchases - totalPaid;

  return PurchaseStats(
    total: allPurchases.length,
    draft: draftCount,
    confirmed: confirmedCount,
    received: receivedCount,
    cancelled: cancelledCount,
    totalPurchases: totalPurchases,
    totalPaid: totalPaid,
    totalPayables: totalPayables,
  );
}

class PurchaseStats {
  final int total;
  final int draft;
  final int confirmed;
  final int received;
  final int cancelled;
  final double totalPurchases;
  final double totalPaid;
  final double totalPayables;

  PurchaseStats({
    required this.total,
    required this.draft,
    required this.confirmed,
    required this.received,
    required this.cancelled,
    required this.totalPurchases,
    required this.totalPaid,
    required this.totalPayables,
  });
}
