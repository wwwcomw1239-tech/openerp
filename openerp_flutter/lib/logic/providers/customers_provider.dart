import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/drift/app_database.dart';
import '../../data/database/drift/database.dart';
import 'database_provider.dart';

part 'customers_provider.g.dart';

/// UUID generator
final _uuid = const Uuid();

/// Customer model for UI
class CustomerModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? address;
  final String? city;
  final String? country;
  final String? taxNumber;
  final double creditLimit;
  final double balance;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.mobile,
    this.address,
    this.city,
    this.country,
    this.taxNumber,
    this.creditLimit = 0.0,
    this.balance = 0.0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromDrift(Customer customer) {
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      mobile: customer.mobile,
      address: customer.address,
      city: customer.city,
      country: customer.country,
      taxNumber: customer.taxNumber,
      creditLimit: customer.creditLimit,
      balance: customer.balance,
      notes: customer.notes,
      isActive: customer.isActive,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
    );
  }

  CustomersCompanion toCompanion() {
    return CustomersCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      email: drift.Value(email),
      phone: drift.Value(phone),
      mobile: drift.Value(mobile),
      address: drift.Value(address),
      city: drift.Value(city),
      country: drift.Value(country),
      taxNumber: drift.Value(taxNumber),
      creditLimit: drift.Value(creditLimit),
      balance: drift.Value(balance),
      notes: drift.Value(notes),
      isActive: drift.Value(isActive),
      updatedAt: drift.Value(DateTime.now()),
    );
  }
}

/// Customer form data for create/update
class CustomerFormData {
  String name;
  String? email;
  String? phone;
  String? mobile;
  String? address;
  String? city;
  String? country;
  String? taxNumber;
  double creditLimit;
  String? notes;
  bool isActive;

  CustomerFormData({
    this.name = '',
    this.email,
    this.phone,
    this.mobile,
    this.address,
    this.city,
    this.country,
    this.taxNumber,
    this.creditLimit = 0.0,
    this.notes,
    this.isActive = true,
  });

  factory CustomerFormData.fromModel(CustomerModel? model) {
    return CustomerFormData(
      name: model?.name ?? '',
      email: model?.email,
      phone: model?.phone,
      mobile: model?.mobile,
      address: model?.address,
      city: model?.city,
      country: model?.country,
      taxNumber: model?.taxNumber,
      creditLimit: model?.creditLimit ?? 0.0,
      notes: model?.notes,
      isActive: model?.isActive ?? true,
    );
  }
}

/// All customers stream provider
@riverpod
Stream<List<CustomerModel>> customers(CustomersRef ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.customers)
      .watch()
      .map((rows) => rows.map(CustomerModel.fromDrift).toList());
}

/// Active customers stream provider
@riverpod
Stream<List<CustomerModel>> activeCustomers(ActiveCustomersRef ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.customers)..where((t) => t.isActive.equals(true)))
      .watch()
      .map((rows) => rows.map(CustomerModel.fromDrift).toList());
}

/// Single customer provider
@riverpod
Future<CustomerModel?> customer(CustomerRef ref, String id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.customers)..where((t) => t.id.equals(id)))
      .getSingleOrNull()
      .then((row) => row != null ? CustomerModel.fromDrift(row) : null);
}

/// Customer search provider
@riverpod
Stream<List<CustomerModel>> customerSearch(CustomerSearchRef ref, String query) {
  final db = ref.watch(databaseProvider);
  final searchQuery = '%$query%';
  
  return (db.select(db.customers)
        ..where((t) => 
          t.name.like(searchQuery) | 
          t.email.like(searchQuery) | 
          t.phone.like(searchQuery)))
      .watch()
      .map((rows) => rows.map(CustomerModel.fromDrift).toList());
}

/// Customers notifier for CRUD operations
@riverpod
class CustomersNotifier extends _$CustomersNotifier {
  @override
  Stream<List<CustomerModel>> build() {
    final db = ref.watch(databaseProvider);
    return db
        .select(db.customers)
        .watch()
        .map((rows) => rows.map(CustomerModel.fromDrift).toList());
  }

  /// Create new customer
  Future<CustomerModel> create(CustomerFormData data) async {
    final db = ref.read(databaseProvider);
    final id = _uuid.v4();
    final now = DateTime.now();
    
    final companion = CustomersCompanion(
      id: drift.Value(id),
      name: drift.Value(data.name),
      email: drift.Value(data.email),
      phone: drift.Value(data.phone),
      mobile: drift.Value(data.mobile),
      address: drift.Value(data.address),
      city: drift.Value(data.city),
      country: drift.Value(data.country),
      taxNumber: drift.Value(data.taxNumber),
      creditLimit: drift.Value(data.creditLimit),
      balance: const drift.Value(0.0),
      notes: drift.Value(data.notes),
      isActive: drift.Value(data.isActive),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    
    await db.into(db.customers).insert(companion);
    
    return CustomerModel(
      id: id,
      name: data.name,
      email: data.email,
      phone: data.phone,
      mobile: data.mobile,
      address: data.address,
      city: data.city,
      country: data.country,
      taxNumber: data.taxNumber,
      creditLimit: data.creditLimit,
      balance: 0.0,
      notes: data.notes,
      isActive: data.isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update existing customer
  Future<void> update(String id, CustomerFormData data) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    
    await (db.update(db.customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        name: drift.Value(data.name),
        email: drift.Value(data.email),
        phone: drift.Value(data.phone),
        mobile: drift.Value(data.mobile),
        address: drift.Value(data.address),
        city: drift.Value(data.city),
        country: drift.Value(data.country),
        taxNumber: drift.Value(data.taxNumber),
        creditLimit: drift.Value(data.creditLimit),
        notes: drift.Value(data.notes),
        isActive: drift.Value(data.isActive),
        updatedAt: drift.Value(now),
      ),
    );
  }

  /// Delete customer
  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.customers)..where((t) => t.id.equals(id))).go();
  }

  /// Toggle customer active status
  Future<void> toggleActive(String id, bool isActive) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        isActive: drift.Value(isActive),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Update customer balance
  Future<void> updateBalance(String id, double newBalance) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        balance: drift.Value(newBalance),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Get customer count
  Future<int> count() async {
    final db = ref.read(databaseProvider);
    return db.customers.count().getSingle();
  }
}

/// Customer statistics provider
@riverpod
Future<CustomerStats> customerStats(CustomerStatsRef ref) async {
  final db = ref.watch(databaseProvider);
  
  final allCustomers = await db.select(db.customers).get();
  final activeCount = allCustomers.where((c) => c.isActive).length;
  final totalReceivables = allCustomers.fold<double>(0, (sum, c) => sum + c.balance);
  final totalCreditLimit = allCustomers.fold<double>(0, (sum, c) => sum + c.creditLimit);
  
  return CustomerStats(
    total: allCustomers.length,
    active: activeCount,
    inactive: allCustomers.length - activeCount,
    totalReceivables: totalReceivables,
    totalCreditLimit: totalCreditLimit,
  );
}

/// Customer statistics model
class CustomerStats {
  final int total;
  final int active;
  final int inactive;
  final double totalReceivables;
  final double totalCreditLimit;

  CustomerStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.totalReceivables,
    required this.totalCreditLimit,
  });
}
