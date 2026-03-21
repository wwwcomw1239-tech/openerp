import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/drift/database.dart';
import '../../data/database/drift/database.dart';
import 'database_provider.dart';

part 'suppliers_provider.g.dart';

/// UUID generator
final _uuid = const Uuid();

/// Supplier model for UI
class SupplierModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? address;
  final String? city;
  final String? country;
  final String? taxNumber;
  final double balance;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.mobile,
    this.address,
    this.city,
    this.country,
    this.taxNumber,
    this.balance = 0.0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierModel.fromDrift(Supplier supplier) {
    return SupplierModel(
      id: supplier.id,
      name: supplier.name,
      email: supplier.email,
      phone: supplier.phone,
      mobile: supplier.mobile,
      address: supplier.address,
      city: supplier.city,
      country: supplier.country,
      taxNumber: supplier.taxNumber,
      balance: supplier.balance,
      notes: supplier.notes,
      isActive: supplier.isActive,
      createdAt: supplier.createdAt,
      updatedAt: supplier.updatedAt,
    );
  }

  SuppliersCompanion toCompanion() {
    return SuppliersCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      email: drift.Value(email),
      phone: drift.Value(phone),
      mobile: drift.Value(mobile),
      address: drift.Value(address),
      city: drift.Value(city),
      country: drift.Value(country),
      taxNumber: drift.Value(taxNumber),
      balance: drift.Value(balance),
      notes: drift.Value(notes),
      isActive: drift.Value(isActive),
      updatedAt: drift.Value(DateTime.now()),
    );
  }
}

/// Supplier form data for create/update
class SupplierFormData {
  String name;
  String? email;
  String? phone;
  String? mobile;
  String? address;
  String? city;
  String? country;
  String? taxNumber;
  String? notes;
  bool isActive;

  SupplierFormData({
    this.name = '',
    this.email,
    this.phone,
    this.mobile,
    this.address,
    this.city,
    this.country,
    this.taxNumber,
    this.notes,
    this.isActive = true,
  });

  factory SupplierFormData.fromModel(SupplierModel? model) {
    return SupplierFormData(
      name: model?.name ?? '',
      email: model?.email,
      phone: model?.phone,
      mobile: model?.mobile,
      address: model?.address,
      city: model?.city,
      country: model?.country,
      taxNumber: model?.taxNumber,
      notes: model?.notes,
      isActive: model?.isActive ?? true,
    );
  }
}

/// All suppliers stream provider
@riverpod
Stream<List<SupplierModel>> suppliers(SuppliersRef ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.suppliers)
      .watch()
      .map((rows) => rows.map(SupplierModel.fromDrift).toList());
}

/// Active suppliers stream provider
@riverpod
Stream<List<SupplierModel>> activeSuppliers(ActiveSuppliersRef ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.suppliers)..where((t) => t.isActive.equals(true)))
      .watch()
      .map((rows) => rows.map(SupplierModel.fromDrift).toList());
}

/// Single supplier provider
@riverpod
Future<SupplierModel?> supplier(SupplierRef ref, String id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.suppliers)..where((t) => t.id.equals(id)))
      .getSingleOrNull()
      .then((row) => row != null ? SupplierModel.fromDrift(row) : null);
}

/// Supplier search provider
@riverpod
Stream<List<SupplierModel>> supplierSearch(SupplierSearchRef ref, String query) {
  final db = ref.watch(databaseProvider);
  final searchQuery = '%$query%';
  
  return (db.select(db.suppliers)
        ..where((t) => 
          t.name.like(searchQuery) | 
          t.email.like(searchQuery) | 
          t.phone.like(searchQuery)))
      .watch()
      .map((rows) => rows.map(SupplierModel.fromDrift).toList());
}

/// Suppliers notifier for CRUD operations
@riverpod
class SuppliersNotifier extends _$SuppliersNotifier {
  @override
  Stream<List<SupplierModel>> build() {
    final db = ref.watch(databaseProvider);
    return db
        .select(db.suppliers)
        .watch()
        .map((rows) => rows.map(SupplierModel.fromDrift).toList());
  }

  /// Create new supplier
  Future<SupplierModel> create(SupplierFormData data) async {
    final db = ref.read(databaseProvider);
    final id = _uuid.v4();
    final now = DateTime.now();
    
    final companion = SuppliersCompanion(
      id: drift.Value(id),
      name: drift.Value(data.name),
      email: drift.Value(data.email),
      phone: drift.Value(data.phone),
      mobile: drift.Value(data.mobile),
      address: drift.Value(data.address),
      city: drift.Value(data.city),
      country: drift.Value(data.country),
      taxNumber: drift.Value(data.taxNumber),
      balance: const drift.Value(0.0),
      notes: drift.Value(data.notes),
      isActive: drift.Value(data.isActive),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    
    await db.into(db.suppliers).insert(companion);
    
    return SupplierModel(
      id: id,
      name: data.name,
      email: data.email,
      phone: data.phone,
      mobile: data.mobile,
      address: data.address,
      city: data.city,
      country: data.country,
      taxNumber: data.taxNumber,
      balance: 0.0,
      notes: data.notes,
      isActive: data.isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update existing supplier
  Future<void> updateItem(String id, SupplierFormData data) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    
    await (db.update(db.suppliers)..where((t) => t.id.equals(id))).write(
      SuppliersCompanion(
        name: drift.Value(data.name),
        email: drift.Value(data.email),
        phone: drift.Value(data.phone),
        mobile: drift.Value(data.mobile),
        address: drift.Value(data.address),
        city: drift.Value(data.city),
        country: drift.Value(data.country),
        taxNumber: drift.Value(data.taxNumber),
        notes: drift.Value(data.notes),
        isActive: drift.Value(data.isActive),
        updatedAt: drift.Value(now),
      ),
    );
  }

  /// Delete supplier
  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.suppliers)..where((t) => t.id.equals(id))).go();
  }

  /// Toggle supplier active status
  Future<void> toggleActive(String id, bool isActive) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.suppliers)..where((t) => t.id.equals(id))).write(
      SuppliersCompanion(
        isActive: drift.Value(isActive),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Update supplier balance
  Future<void> updateBalance(String id, double newBalance) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.suppliers)..where((t) => t.id.equals(id))).write(
      SuppliersCompanion(
        balance: drift.Value(newBalance),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Get supplier count
  Future<int> count() async {
    final db = ref.read(databaseProvider);
    return db.suppliers.count().getSingle();
  }
}

/// Supplier statistics provider
@riverpod
Future<SupplierStats> supplierStats(SupplierStatsRef ref) async {
  final db = ref.watch(databaseProvider);
  
  final allSuppliers = await db.select(db.suppliers).get();
  final activeCount = allSuppliers.where((s) => s.isActive).length;
  final totalPayables = allSuppliers.fold<double>(0, (sum, s) => sum + s.balance);
  
  return SupplierStats(
    total: allSuppliers.length,
    active: activeCount,
    inactive: allSuppliers.length - activeCount,
    totalPayables: totalPayables,
  );
}

/// Supplier statistics model
class SupplierStats {
  final int total;
  final int active;
  final int inactive;
  final double totalPayables;

  SupplierStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.totalPayables,
  });
}
