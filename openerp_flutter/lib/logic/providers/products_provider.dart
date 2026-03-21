import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/drift/database.dart';
import '../../data/database/drift/database.dart';
import 'database_provider.dart';

part 'products_provider.g.dart';

/// UUID generator
final _uuid = const Uuid();

// ==================== CATEGORY MODEL ====================

class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final String? color;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.color,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromDrift(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      description: category.description,
      parentId: category.parentId,
      color: category.color,
      sortOrder: category.sortOrder,
      isActive: category.isActive,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }
}

class CategoryFormData {
  String name;
  String? description;
  String? parentId;
  String? color;
  int sortOrder;
  bool isActive;

  CategoryFormData({
    this.name = '',
    this.description,
    this.parentId,
    this.color = '#10B981',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory CategoryFormData.fromModel(CategoryModel? model) {
    return CategoryFormData(
      name: model?.name ?? '',
      description: model?.description,
      parentId: model?.parentId,
      color: model?.color ?? '#10B981',
      sortOrder: model?.sortOrder ?? 0,
      isActive: model?.isActive ?? true,
    );
  }
}

// ==================== PRODUCT MODEL ====================

class ProductModel {
  final String id;
  final String sku;
  final String name;
  final String? description;
  final String? categoryId;
  final String unit;
  final double costPrice;
  final double salePrice;
  final double quantity;
  final double minQuantity;
  final double maxQuantity;
  final String? barcode;
  final String? image;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.sku,
    required this.name,
    this.description,
    this.categoryId,
    this.unit = 'piece',
    this.costPrice = 0.0,
    this.salePrice = 0.0,
    this.quantity = 0.0,
    this.minQuantity = 0.0,
    this.maxQuantity = 0.0,
    this.barcode,
    this.image,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromDrift(Product product) {
    return ProductModel(
      id: product.id,
      sku: product.sku,
      name: product.name,
      description: product.description,
      categoryId: product.categoryId,
      unit: product.unit,
      costPrice: product.costPrice,
      salePrice: product.salePrice,
      quantity: product.quantity,
      minQuantity: product.minQuantity,
      maxQuantity: product.maxQuantity,
      barcode: product.barcode,
      image: product.image,
      isActive: product.isActive,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  bool get isLowStock => quantity <= minQuantity && quantity > 0;
  bool get isOutOfStock => quantity <= 0;
  double get profitMargin => salePrice > 0 ? ((salePrice - costPrice) / salePrice) * 100 : 0;
}

class ProductFormData {
  String sku;
  String name;
  String? description;
  String? categoryId;
  String unit;
  double costPrice;
  double salePrice;
  double quantity;
  double minQuantity;
  double maxQuantity;
  String? barcode;
  bool isActive;

  ProductFormData({
    this.sku = '',
    this.name = '',
    this.description,
    this.categoryId,
    this.unit = 'piece',
    this.costPrice = 0.0,
    this.salePrice = 0.0,
    this.quantity = 0.0,
    this.minQuantity = 0.0,
    this.maxQuantity = 0.0,
    this.barcode,
    this.isActive = true,
  });

  factory ProductFormData.fromModel(ProductModel? model) {
    return ProductFormData(
      sku: model?.sku ?? '',
      name: model?.name ?? '',
      description: model?.description,
      categoryId: model?.categoryId,
      unit: model?.unit ?? 'piece',
      costPrice: model?.costPrice ?? 0.0,
      salePrice: model?.salePrice ?? 0.0,
      quantity: model?.quantity ?? 0.0,
      minQuantity: model?.minQuantity ?? 0.0,
      maxQuantity: model?.maxQuantity ?? 0.0,
      barcode: model?.barcode,
      isActive: model?.isActive ?? true,
    );
  }
}

// ==================== CATEGORY PROVIDERS ====================

@riverpod
Stream<List<CategoryModel>> categories(CategoriesRef ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.categories)
      .watch()
      .map((rows) => rows.map(CategoryModel.fromDrift).toList());
}

@riverpod
Stream<List<CategoryModel>> activeCategories(ActiveCategoriesRef ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)..where((t) => t.isActive.equals(true)))
      .watch()
      .map((rows) => rows.map(CategoryModel.fromDrift).toList());
}

@riverpod
class CategoriesNotifier extends _$CategoriesNotifier {
  @override
  Stream<List<CategoryModel>> build() {
    final db = ref.watch(databaseProvider);
    return db
        .select(db.categories)
        .watch()
        .map((rows) => rows.map(CategoryModel.fromDrift).toList());
  }

  Future<CategoryModel> create(CategoryFormData data) async {
    final db = ref.read(databaseProvider);
    final id = _uuid.v4();
    final now = DateTime.now();

    final companion = CategoriesCompanion(
      id: drift.Value(id),
      name: drift.Value(data.name),
      description: drift.Value(data.description),
      parentId: drift.Value(data.parentId),
      color: drift.Value(data.color),
      sortOrder: drift.Value(data.sortOrder),
      isActive: drift.Value(data.isActive),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await db.into(db.categories).insert(companion);

    return CategoryModel(
      id: id,
      name: data.name,
      description: data.description,
      parentId: data.parentId,
      color: data.color,
      sortOrder: data.sortOrder,
      isActive: data.isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateItem(String id, CategoryFormData data) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: drift.Value(data.name),
        description: drift.Value(data.description),
        parentId: drift.Value(data.parentId),
        color: drift.Value(data.color),
        sortOrder: drift.Value(data.sortOrder),
        isActive: drift.Value(data.isActive),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
  }
}

// ==================== PRODUCT PROVIDERS ====================

@riverpod
Stream<List<ProductModel>> products(ProductsRef ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.products)
      .watch()
      .map((rows) => rows.map(ProductModel.fromDrift).toList());
}

@riverpod
Stream<List<ProductModel>> activeProducts(ActiveProductsRef ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.products)..where((t) => t.isActive.equals(true)))
      .watch()
      .map((rows) => rows.map(ProductModel.fromDrift).toList());
}

@riverpod
Future<ProductModel?> product(ProductRef ref, String id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.products)..where((t) => t.id.equals(id)))
      .getSingleOrNull()
      .then((row) => row != null ? ProductModel.fromDrift(row) : null);
}

@riverpod
Stream<List<ProductModel>> productSearch(ProductSearchRef ref, String query) {
  final db = ref.watch(databaseProvider);
  final searchQuery = '%$query%';

  return (db.select(db.products)
        ..where((t) =>
            t.name.like(searchQuery) |
            t.sku.like(searchQuery) |
            t.barcode.like(searchQuery)))
      .watch()
      .map((rows) => rows.map(ProductModel.fromDrift).toList());
}

@riverpod
Stream<List<ProductModel>> productsByCategory(ProductsByCategoryRef ref, String? categoryId) {
  final db = ref.watch(databaseProvider);
  if (categoryId == null) {
    return db.select(db.products).watch().map((rows) => rows.map(ProductModel.fromDrift).toList());
  }
  return (db.select(db.products)..where((t) => t.categoryId.equals(categoryId)))
      .watch()
      .map((rows) => rows.map(ProductModel.fromDrift).toList());
}

@riverpod
Stream<List<ProductModel>> lowStockProducts(LowStockProductsRef ref) {
  final db = ref.watch(databaseProvider);
  // Get all products and filter in Dart due to Drift limitations with column comparisons
  return db.select(db.products).watch().map((rows) {
    return rows
        .map(ProductModel.fromDrift)
        .where((p) => p.quantity <= p.minQuantity)
        .toList();
  });
}

@riverpod
class ProductsNotifier extends _$ProductsNotifier {
  @override
  Stream<List<ProductModel>> build() {
    final db = ref.watch(databaseProvider);
    return db
        .select(db.products)
        .watch()
        .map((rows) => rows.map(ProductModel.fromDrift).toList());
  }

  /// Generate next SKU
  Future<String> _generateSku() async {
    final db = ref.read(databaseProvider);
    final count = await db.products.count().getSingle();
    return 'SKU-${(count + 1).toString().padLeft(6, '0')}';
  }

  Future<ProductModel> create(ProductFormData data) async {
    final db = ref.read(databaseProvider);
    final id = _uuid.v4();
    final now = DateTime.now();
    
    // Generate SKU if not provided
    final sku = data.sku.isEmpty ? await _generateSku() : data.sku;

    final companion = ProductsCompanion(
      id: drift.Value(id),
      sku: drift.Value(sku),
      name: drift.Value(data.name),
      description: drift.Value(data.description),
      categoryId: drift.Value(data.categoryId),
      unit: drift.Value(data.unit),
      costPrice: drift.Value(data.costPrice),
      salePrice: drift.Value(data.salePrice),
      quantity: drift.Value(data.quantity),
      minQuantity: drift.Value(data.minQuantity),
      maxQuantity: drift.Value(data.maxQuantity),
      barcode: drift.Value(data.barcode),
      isActive: drift.Value(data.isActive),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await db.into(db.products).insert(companion);

    return ProductModel(
      id: id,
      sku: sku,
      name: data.name,
      description: data.description,
      categoryId: data.categoryId,
      unit: data.unit,
      costPrice: data.costPrice,
      salePrice: data.salePrice,
      quantity: data.quantity,
      minQuantity: data.minQuantity,
      maxQuantity: data.maxQuantity,
      barcode: data.barcode,
      isActive: data.isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateItem(String id, ProductFormData data) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        sku: drift.Value(data.sku),
        name: drift.Value(data.name),
        description: drift.Value(data.description),
        categoryId: drift.Value(data.categoryId),
        unit: drift.Value(data.unit),
        costPrice: drift.Value(data.costPrice),
        salePrice: drift.Value(data.salePrice),
        quantity: drift.Value(data.quantity),
        minQuantity: drift.Value(data.minQuantity),
        maxQuantity: drift.Value(data.maxQuantity),
        barcode: drift.Value(data.barcode),
        isActive: drift.Value(data.isActive),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.products)..where((t) => t.id.equals(id))).go();
  }

  /// Update stock quantity
  Future<void> updateStock(String id, double newQuantity) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        quantity: drift.Value(newQuantity),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Adjust stock by delta (positive for additions, negative for deductions)
  Future<void> adjustStock(String id, double delta) async {
    final db = ref.read(databaseProvider);
    final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (product != null) {
      final newQuantity = product.quantity + delta;
      await updateStock(id, newQuantity);
    }
  }
}

// ==================== PRODUCT STATISTICS ====================

@riverpod
Future<ProductStats> productStats(ProductStatsRef ref) async {
  final db = ref.watch(databaseProvider);

  final allProducts = await db.select(db.products).get();
  final activeCount = allProducts.where((p) => p.isActive).length;
  final lowStockCount = allProducts.where((p) => p.quantity <= p.minQuantity && p.quantity > 0).length;
  final outOfStockCount = allProducts.where((p) => p.quantity <= 0).length;
  final totalValue = allProducts.fold<double>(0, (sum, p) => sum + (p.quantity * p.costPrice));

  return ProductStats(
    total: allProducts.length,
    active: activeCount,
    inactive: allProducts.length - activeCount,
    lowStock: lowStockCount,
    outOfStock: outOfStockCount,
    totalValue: totalValue,
  );
}

class ProductStats {
  final int total;
  final int active;
  final int inactive;
  final int lowStock;
  final int outOfStock;
  final double totalValue;

  ProductStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.lowStock,
    required this.outOfStock,
    required this.totalValue,
  });
}
