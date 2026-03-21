import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../logic/providers/products_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Products screen - Inventory management with categories
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _showInactive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final statsAsync = ref.watch(productStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 1000;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            _buildHeader(statsAsync, isDesktop),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Products Tab
                  productsAsync.when(
                    data: (products) {
                      final filtered = _filterProducts(products);
                      return _buildProductsContent(filtered, categoriesAsync, isDesktop);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => _buildError(e),
                  ),
                  // Categories Tab
                  categoriesAsync.when(
                    data: (categories) => _buildCategoriesContent(categories, isDesktop),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => _buildError(e),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _tabController.index == 0 
              ? _showProductDialog(context)
              : _showCategoryDialog(context),
          icon: Icon(_tabController.index == 0 ? Icons.inventory_2 : Icons.category),
          label: Text(_tabController.index == 0 ? 'منتج جديد' : 'تصنيف جديد'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<ProductStats> statsAsync, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المنتجات والمخزون', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('إدارة المنتجات والتصنيفات ومتابعة المخزون', style: TextStyle(color: Colors.grey)),
                ],
              ),
              statsAsync.when(
                data: (stats) => isDesktop ? _buildStatsChips(stats) : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_tabController.index == 0) _buildSearchAndFilter(isDesktop),
        ],
      ),
    );
  }

  Widget _buildStatsChips(ProductStats stats) {
    return Row(
      children: [
        _buildStatChip('المنتجات', stats.total.toString(), Colors.blue),
        const SizedBox(width: 12),
        _buildStatChip('منخفض المخزون', stats.lowStock.toString(), AppTheme.warningColor),
        const SizedBox(width: 12),
        _buildStatChip('نفذ', stats.outOfStock.toString(), AppTheme.errorColor),
        const SizedBox(width: 12),
        _buildStatChip('قيمة المخزون', _formatCurrency(stats.totalValue), AppTheme.successColor),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: color, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
        onTap: (_) => setState(() {}),
        tabs: const [
          Tab(icon: Icon(Icons.inventory_2), text: 'المنتجات'),
          Tab(icon: Icon(Icons.category), text: 'التصنيفات'),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDesktop) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    
    return isDesktop
        ? Row(
            children: [
              Expanded(flex: 2, child: _buildSearchField()),
              const SizedBox(width: 16),
              categoriesAsync.when(
                data: (categories) => _buildCategoryDropdown(categories),
                loading: () => const SizedBox(width: 200, child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 16),
              _buildInactiveToggle(),
            ],
          )
        : Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: categoriesAsync.when(
                      data: (categories) => _buildCategoryDropdown(categories),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildInactiveToggle(),
                ],
              ),
            ],
          );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'البحث بالاسم، SKU، أو الباركود...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<CategoryModel> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String?>(
        value: _selectedCategoryId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: const Text('جميع التصنيفات'),
        items: [
          const DropdownMenuItem(value: null, child: Text('جميع التصنيفات')),
          ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
        ],
        onChanged: (value) => setState(() => _selectedCategoryId = value),
      ),
    );
  }

  Widget _buildInactiveToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('إظهار غير النشطين'),
        const SizedBox(width: 8),
        Switch(
          value: _showInactive,
          onChanged: (value) => setState(() => _showInactive = value),
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var filtered = products;
    
    if (!_showInactive) {
      filtered = filtered.where((p) => p.isActive).toList();
    }
    
    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            (p.barcode?.contains(query) ?? false);
      }).toList();
    }
    
    return filtered;
  }

  Widget _buildProductsContent(
    List<ProductModel> products,
    AsyncValue<List<CategoryModel>> categoriesAsync,
    bool isDesktop,
  ) {
    if (products.isEmpty) {
      return _buildEmptyState('لا توجد منتجات', 'اضغط على زر "منتج جديد" للإضافة');
    }

    return isDesktop
        ? _buildProductsTable(products, categoriesAsync)
        : _buildProductsList(products, categoriesAsync);
  }

  Widget _buildProductsTable(List<ProductModel> products, AsyncValue<List<CategoryModel>> categoriesAsync) {
    final categoriesMap = categoriesAsync.whenOrNull(
      data: (cats) => {for (var c in cats) c.id: c.name},
    ) ?? {};

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('سعر التكلفة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('سعر البيع', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: products.map((product) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getStockColor(product).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2, color: _getStockColor(product), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(product.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                DataCell(Text(product.sku, style: const TextStyle(fontFamily: 'monospace'))),
                DataCell(Text(categoriesMap[product.categoryId] ?? '-')),
                DataCell(Text(_formatCurrency(product.costPrice))),
                DataCell(Text(_formatCurrency(product.salePrice))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStockColor(product).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${product.quantity.toStringAsFixed(0)} ${_getUnitText(product.unit)}',
                      style: TextStyle(color: _getStockColor(product), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataCell(_buildStatusBadge(product)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.warningColor),
                        onPressed: () => _showProductDialog(context, product: product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                        onPressed: () => _confirmDeleteProduct(product),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductsList(List<ProductModel> products, AsyncValue<List<CategoryModel>> categoriesAsync) {
    final categoriesMap = categoriesAsync.whenOrNull(
      data: (cats) => {for (var c in cats) c.id: c.name},
    ) ?? {};

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getStockColor(product).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.inventory_2, color: _getStockColor(product)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${product.sku} • ${categoriesMap[product.categoryId] ?? 'بدون تصنيف'}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(product),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('سعر التكلفة', _formatCurrency(product.costPrice)),
                    _buildInfoColumn('سعر البيع', _formatCurrency(product.salePrice)),
                    _buildInfoColumn(
                      'الكمية',
                      '${product.quantity.toStringAsFixed(0)} ${_getUnitText(product.unit)}',
                      color: _getStockColor(product),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('تعديل'),
                      onPressed: () => _showProductDialog(context, product: product),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                      label: const Text('حذف', style: TextStyle(color: AppTheme.errorColor)),
                      onPressed: () => _confirmDeleteProduct(product),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildStatusBadge(ProductModel product) {
    if (!product.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('غير نشط', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }
    if (product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('نفذ المخزون', style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
      );
    }
    if (product.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('مخزون منخفض', style: TextStyle(color: AppTheme.warningColor, fontSize: 12)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('متوفر', style: TextStyle(color: AppTheme.successColor, fontSize: 12)),
    );
  }

  Color _getStockColor(ProductModel product) {
    if (!product.isActive) return Colors.grey;
    if (product.isOutOfStock) return AppTheme.errorColor;
    if (product.isLowStock) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  String _getUnitText(String unit) {
    const units = {
      'piece': 'قطعة',
      'kg': 'كجم',
      'liter': 'لتر',
      'meter': 'متر',
      'box': 'صندوق',
    };
    return units[unit] ?? unit;
  }

  // Categories Content
  Widget _buildCategoriesContent(List<CategoryModel> categories, bool isDesktop) {
    if (categories.isEmpty) {
      return _buildEmptyState('لا توجد تصنيفات', 'اضغط على زر "تصنيف جديد" للإضافة');
    }

    return isDesktop
        ? _buildCategoriesTable(categories)
        : _buildCategoriesList(categories);
  }

  Widget _buildCategoriesTable(List<CategoryModel> categories) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
        columns: const [
          DataColumn(label: Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الوصف', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الترتيب', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: categories.map((category) {
          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _parseColor(category.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(category.name),
                  ],
                ),
              ),
              DataCell(Text(category.description ?? '-')),
              DataCell(Text(category.sortOrder.toString())),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: category.isActive
                        ? AppTheme.successColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category.isActive ? 'نشط' : 'غير نشط',
                    style: TextStyle(color: category.isActive ? AppTheme.successColor : Colors.grey, fontSize: 12),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.warningColor),
                      onPressed: () => _showCategoryDialog(context, category: category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                      onPressed: () => _confirmDeleteCategory(category),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoriesList(List<CategoryModel> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _parseColor(category.color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.category, color: _parseColor(category.color)),
            ),
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(category.description ?? 'بدون وصف'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.warningColor),
                  onPressed: () => _showCategoryDialog(context, category: category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                  onPressed: () => _confirmDeleteCategory(category),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return AppTheme.primaryColor;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('خطأ: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(productsProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  // Dialogs
  void _showProductDialog(BuildContext context, {ProductModel? product}) {
    final categoriesAsync = ref.read(activeCategoriesProvider);
    
    showDialog(
      context: context,
      builder: (context) => categoriesAsync.when(
        data: (categories) => ProductFormDialog(
          product: product,
          categories: categories,
          onSave: (data) async {
            final notifier = ref.read(productsNotifierProvider.notifier);
            if (product != null) {
              await notifier.update(product.id, data);
            } else {
              await notifier.create(data);
            }
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AlertDialog(
          title: const Text('خطأ'),
          content: const Text('فشل تحميل التصنيفات'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {CategoryModel? category}) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        category: category,
        onSave: (data) async {
          final notifier = ref.read(categoriesNotifierProvider.notifier);
          if (category != null) {
            await notifier.update(category.id, data);
          } else {
            await notifier.create(data);
          }
        },
      ),
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المنتج "${product.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(productsNotifierProvider.notifier).delete(product.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف التصنيف "${category.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(categoriesNotifierProvider.notifier).delete(category.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س', decimalDigits: 2).format(amount);
  }
}

// Product Form Dialog
class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final List<CategoryModel> categories;
  final Future<void> Function(ProductFormData) onSave;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.categories,
    required this.onSave,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late ProductFormData _formData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formData = ProductFormData.fromModel(widget.product);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(widget.product != null ? Icons.edit : Icons.inventory_2, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      widget.product != null ? 'تعديل المنتج' : 'إضافة منتج جديد',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _formData.sku,
                                decoration: const InputDecoration(
                                  labelText: 'SKU',
                                  prefixIcon: Icon(Icons.qr_code),
                                ),
                                onSaved: (v) => _formData.sku = v ?? '',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: _formData.name,
                                decoration: const InputDecoration(
                                  labelText: 'اسم المنتج *',
                                  prefixIcon: Icon(Icons.inventory_2),
                                ),
                                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                                onSaved: (v) => _formData.name = v ?? '',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _formData.categoryId?.isEmpty == true ? null : _formData.categoryId,
                          decoration: const InputDecoration(
                            labelText: 'التصنيف',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('بدون تصنيف')),
                            ...widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) => setState(() => _formData.categoryId = v),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _formData.description,
                          decoration: const InputDecoration(
                            labelText: 'الوصف',
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 2,
                          onSaved: (v) => _formData.description = v,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _formData.costPrice.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'سعر التكلفة',
                                  prefixIcon: Icon(Icons.money),
                                  suffixText: 'ر.س',
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (v) => _formData.costPrice = double.tryParse(v ?? '0') ?? 0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _formData.salePrice.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'سعر البيع',
                                  prefixIcon: Icon(Icons.sell),
                                  suffixText: 'ر.س',
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (v) => _formData.salePrice = double.tryParse(v ?? '0') ?? 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _formData.quantity.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'الكمية الحالية',
                                  prefixIcon: Icon(Icons.inventory),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (v) => _formData.quantity = double.tryParse(v ?? '0') ?? 0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _formData.minQuantity.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'الحد الأدنى',
                                  prefixIcon: Icon(Icons.warning_amber),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (v) => _formData.minQuantity = double.tryParse(v ?? '0') ?? 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _formData.unit,
                                decoration: const InputDecoration(
                                  labelText: 'الوحدة',
                                  prefixIcon: Icon(Icons.straighten),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'piece', child: Text('قطعة')),
                                  DropdownMenuItem(value: 'kg', child: Text('كجم')),
                                  DropdownMenuItem(value: 'liter', child: Text('لتر')),
                                  DropdownMenuItem(value: 'meter', child: Text('متر')),
                                  DropdownMenuItem(value: 'box', child: Text('صندوق')),
                                ],
                                onChanged: (v) => setState(() => _formData.unit = v ?? 'piece'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _formData.barcode,
                                decoration: const InputDecoration(
                                  labelText: 'الباركود',
                                  prefixIcon: Icon(Icons.qr_code_2),
                                ),
                                onSaved: (v) => _formData.barcode = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('نشط'),
                          value: _formData.isActive,
                          onChanged: (v) => setState(() => _formData.isActive = v),
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(widget.product != null ? 'تحديث' : 'حفظ'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        await widget.onSave(_formData);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.errorColor),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Category Form Dialog
class CategoryFormDialog extends StatefulWidget {
  final CategoryModel? category;
  final Future<void> Function(CategoryFormData) onSave;

  const CategoryFormDialog({super.key, this.category, required this.onSave});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late CategoryFormData _formData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formData = CategoryFormData.fromModel(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(widget.category != null ? Icons.edit : Icons.category, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      widget.category != null ? 'تعديل التصنيف' : 'إضافة تصنيف جديد',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: _formData.name,
                        decoration: const InputDecoration(
                          labelText: 'اسم التصنيف *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                        onSaved: (v) => _formData.name = v ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _formData.description,
                        decoration: const InputDecoration(
                          labelText: 'الوصف',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                        onSaved: (v) => _formData.description = v,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('اللون: '),
                          const SizedBox(width: 12),
                          ...['#10B981', '#3B82F6', '#8B5CF6', '#F59E0B', '#EF4444'].map((color) {
                            return GestureDetector(
                              onTap: () => setState(() => _formData.color = color),
                              child: Container(
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                                  shape: BoxShape.circle,
                                  border: _formData.color == color
                                      ? Border.all(color: Colors.black, width: 2)
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('نشط'),
                        value: _formData.isActive,
                        onChanged: (v) => setState(() => _formData.isActive = v),
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(widget.category != null ? 'تحديث' : 'حفظ'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        await widget.onSave(_formData);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.errorColor),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
