import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../logic/providers/purchases_provider.dart';
import '../../../logic/providers/suppliers_provider.dart';
import '../../../logic/providers/products_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Purchases screen - Purchasing management with master-detail
class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter;
  String? _selectedPurchaseId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final statsAsync = ref.watch(purchaseStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final isTablet = MediaQuery.of(context).size.width > 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            _buildHeader(statsAsync, isDesktop),
            Expanded(
              child: purchasesAsync.when(
                data: (purchases) {
                  final filtered = _filterPurchases(purchases);
                  if (isDesktop) {
                    return _buildMasterDetailLayout(filtered, isTablet);
                  }
                  return _buildMobileLayout(filtered);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => _buildError(e),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showPurchaseDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('أمر شراء جديد'),
          backgroundColor: AppTheme.warningColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<PurchaseStats> statsAsync, bool isDesktop) {
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
                  Text('أوامر الشراء', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('إدارة المشتريات والمدفوعات للموردين', style: TextStyle(color: Colors.grey)),
                ],
              ),
              statsAsync.when(
                data: (stats) => isDesktop
                    ? Row(
                        children: [
                          _buildStatChip('الإجمالي', stats.total.toString(), Colors.blue),
                          const SizedBox(width: 12),
                          _buildStatChip('المشتريات', _formatCurrency(stats.totalPurchases), AppTheme.warningColor),
                          const SizedBox(width: 12),
                          _buildStatChip('المستحقات', _formatCurrency(stats.totalPayables), AppTheme.errorColor),
                        ],
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 16),
              _buildStatusFilter(),
            ],
          ),
        ],
      ),
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'البحث برقم أمر الشراء...',
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String?>(
        value: _statusFilter,
        underline: const SizedBox.shrink(),
        hint: const Text('جميع الحالات'),
        items: const [
          DropdownMenuItem(value: null, child: Text('جميع الحالات')),
          DropdownMenuItem(value: 'draft', child: Text('مسودة')),
          DropdownMenuItem(value: 'confirmed', child: Text('مؤكد')),
          DropdownMenuItem(value: 'received', child: Text('مستلم')),
          DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
        ],
        onChanged: (value) => setState(() => _statusFilter = value),
      ),
    );
  }

  List<PurchaseModel> _filterPurchases(List<PurchaseModel> purchases) {
    var filtered = purchases;
    
    if (_statusFilter != null) {
      filtered = filtered.where((p) => p.status == _statusFilter).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) => p.purchaseNumber.toLowerCase().contains(query)).toList();
    }
    
    return filtered..sort((a, b) => b.date.compareTo(a.date));
  }

  Widget _buildMasterDetailLayout(List<PurchaseModel> purchases, bool isTablet) {
    return Row(
      children: [
        SizedBox(
          width: isTablet ? 400 : 350,
          child: _buildPurchasesList(purchases),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedPurchaseId != null
              ? _buildPurchaseDetail(_selectedPurchaseId!)
              : _buildEmptyDetail(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<PurchaseModel> purchases) {
    return _buildPurchasesList(purchases);
  }

  Widget _buildPurchasesList(List<PurchaseModel> purchases) {
    if (purchases.isEmpty) {
      return _buildEmptyState('لا توجد أوامر شراء', 'اضغط على زر "أمر شراء جديد" للإضافة');
    }

    final suppliersAsync = ref.watch(suppliersProvider);

    return suppliersAsync.when(
      data: (suppliers) {
        final suppliersMap = {for (var s in suppliers) s.id: s};
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final purchase = purchases[index];
            final supplier = suppliersMap[purchase.supplierId];
            final isSelected = _selectedPurchaseId == purchase.id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isSelected ? AppTheme.warningColor.withOpacity(0.1) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected ? BorderSide(color: AppTheme.warningColor, width: 2) : BorderSide.none,
              ),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedPurchaseId = purchase.id);
                  if (MediaQuery.of(context).size.width <= 1200) {
                    _showPurchaseDetailDialog(purchase.id);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            purchase.purchaseNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          _buildStatusBadge(purchase.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        supplier?.name ?? 'مورد غير معروف',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(purchase.date),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _formatCurrency(purchase.total),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => _buildError(e),
    );
  }

  Widget _buildPurchaseDetail(String purchaseId) {
    final purchaseAsync = ref.watch(purchaseWithItemsProvider(purchaseId));

    return purchaseAsync.when(
      data: (data) {
        if (data == null) return _buildEmptyDetail();
        return _buildPurchaseDetailContent(data);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => _buildError(e),
    );
  }

  Widget _buildPurchaseDetailContent(PurchaseWithItems data) {
    final purchase = data.purchase;
    final items = data.items;
    final supplier = data.supplier;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.purchaseNumber,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatDate(purchase.date),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              _buildStatusBadge(purchase.status),
            ],
          ),
          const SizedBox(height: 24),

          // Supplier info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                  child: const Icon(Icons.local_shipping, color: AppTheme.warningColor),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplier?.name ?? 'مورد غير معروف', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(supplier?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Items table
          const Text('بنود أمر الشراء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(AppTheme.warningColor.withOpacity(0.1)),
              columns: const [
                DataColumn(label: Text('المنتج')),
                DataColumn(label: Text('الكمية')),
                DataColumn(label: Text('السعر')),
                DataColumn(label: Text('الإجمالي')),
              ],
              rows: items.map((item) {
                return DataRow(cells: [
                  DataCell(Text(item.description ?? 'منتج')),
                  DataCell(Text(item.quantity.toStringAsFixed(0))),
                  DataCell(Text(_formatCurrency(item.unitPrice))),
                  DataCell(Text(_formatCurrency(item.total), style: const TextStyle(fontWeight: FontWeight.bold))),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildTotalRow('المجموع الفرعي', purchase.subtotal),
                if (purchase.shippingCost > 0) _buildTotalRow('الشحن', purchase.shippingCost),
                const Divider(),
                _buildTotalRow('الإجمالي', purchase.total, isBold: true),
                if (purchase.paidAmount > 0) ...[
                  const SizedBox(height: 8),
                  _buildTotalRow('المدفوع', purchase.paidAmount, color: AppTheme.successColor),
                  _buildTotalRow('المتبقي', purchase.balanceDue, color: purchase.balanceDue > 0 ? AppTheme.errorColor : AppTheme.successColor),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (purchase.isDraft)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('تأكيد'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                  onPressed: () => _confirmPurchase(purchase.id),
                ),
              if (purchase.isConfirmed)
                ElevatedButton.icon(
                  icon: const Icon(Icons.inventory),
                  label: const Text('استلام البضاعة'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoColor),
                  onPressed: () => _receivePurchase(purchase.id),
                ),
              if (purchase.isConfirmed || purchase.isReceived) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  label: const Text('تسجيل دفعة'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                  onPressed: () => _showPaymentDialog(purchase),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('إلغاء'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                  onPressed: () => _cancelPurchase(purchase.id),
                ),
              ],
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('طباعة'),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (color, text) = switch (status) {
      'draft' => (Colors.grey, 'مسودة'),
      'confirmed' => (AppTheme.warningColor, 'مؤكد'),
      'received' => (AppTheme.successColor, 'مستلم'),
      'cancelled' => (AppTheme.errorColor, 'ملغي'),
      _ => (Colors.grey, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyDetail() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('اختر أمر شراء لعرض التفاصيل', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
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
          ElevatedButton(onPressed: () => ref.invalidate(purchasesProvider), child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }

  // Actions
  void _showPurchaseDialog(BuildContext context, {PurchaseModel? purchase}) {
    showDialog(
      context: context,
      builder: (context) => PurchaseFormDialog(
        purchase: purchase,
        onSave: (data) async {
          const defaultUserId = 'user-001';
          await ref.read(purchasesNotifierProvider.notifier).create(data, defaultUserId);
        },
      ),
    );
  }

  void _showPurchaseDetailDialog(String purchaseId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 700,
          child: _buildPurchaseDetail(purchaseId),
        ),
      ),
    );
  }

  void _showPaymentDialog(PurchaseModel purchase) {
    final amountController = TextEditingController(text: purchase.balanceDue.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المستحق: ${_formatCurrency(purchase.balanceDue)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'مبلغ الدفعة',
                suffixText: 'ر.س',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0 && amount <= purchase.balanceDue) {
                await ref.read(purchasesNotifierProvider.notifier).addPayment(purchase.id, amount);
                Navigator.pop(context);
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPurchase(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد أمر الشراء'),
        content: const Text('هل أنت متأكد من تأكيد أمر الشراء؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(purchasesNotifierProvider.notifier).updateStatus(id, 'confirmed');
    }
  }

  Future<void> _receivePurchase(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استلام البضاعة'),
        content: const Text('هل تريد استلام البضاعة؟ سيتم إضافة الكميات للمخزون.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('استلام')),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(purchasesNotifierProvider.notifier).markAsReceived(id);
    }
  }

  Future<void> _cancelPurchase(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء أمر الشراء'),
        content: const Text('هل أنت متأكد من إلغاء أمر الشراء؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('إلغاء الأمر'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(purchasesNotifierProvider.notifier).updateStatus(id, 'cancelled');
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س', decimalDigits: 2).format(amount);
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}

// Purchase Form Dialog with multi-item support
class PurchaseFormDialog extends ConsumerStatefulWidget {
  final PurchaseModel? purchase;
  final Future<void> Function(PurchaseFormData) onSave;

  const PurchaseFormDialog({super.key, this.purchase, required this.onSave});

  @override
  ConsumerState<PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends ConsumerState<PurchaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late PurchaseFormData _formData;
  bool _isLoading = false;
  List<PurchaseItemFormData> _items = [];

  @override
  void initState() {
    super.initState();
    _formData = PurchaseFormData();
    _items = _formData.items;
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(activeSuppliersProvider);
    final productsAsync = ref.watch(activeProductsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.warningColor,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text('أمر شراء جديد', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(_formatCurrency(_formData.total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        // Supplier and Date
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: suppliersAsync.when(
                                data: (suppliers) => DropdownButtonFormField<String>(
                                  value: _formData.supplierId.isEmpty ? null : _formData.supplierId,
                                  decoration: const InputDecoration(
                                    labelText: 'المورد *',
                                    prefixIcon: Icon(Icons.local_shipping),
                                  ),
                                  items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                                  validator: (v) => v == null ? 'مطلوب' : null,
                                  onChanged: (v) => setState(() => _formData.supplierId = v ?? ''),
                                ),
                                loading: () => const CircularProgressIndicator(),
                                error: (_, __) => const Text('خطأ في تحميل الموردين'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _formatDate(_formData.date),
                                decoration: const InputDecoration(
                                  labelText: 'التاريخ',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _formData.date,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (date != null) setState(() => _formData.date = date);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Shipping cost
                        TextFormField(
                          initialValue: _formData.shippingCost.toString(),
                          decoration: const InputDecoration(
                            labelText: 'تكلفة الشحن',
                            prefixIcon: Icon(Icons.local_shipping),
                            suffixText: 'ر.س',
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => _formData.shippingCost = double.tryParse(v ?? '0') ?? 0,
                          onChanged: (v) => setState(() => _formData.shippingCost = double.tryParse(v ?? '0') ?? 0),
                        ),
                        const SizedBox(height: 24),

                        // Items section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('بنود أمر الشراء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            productsAsync.when(
                              data: (products) => ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة بند'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
                                onPressed: () => _addItem(products),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Items list
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: _items.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: Text('لا توجد بنود', style: TextStyle(color: Colors.grey))),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _items.length,
                                  itemBuilder: (context, index) => _buildItemCard(index, productsAsync),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Totals
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildTotalRow('المجموع الفرعي', _formData.subtotal),
                              _buildTotalRow('الشحن', _formData.shippingCost),
                              const Divider(),
                              _buildTotalRow('الإجمالي', _formData.total, isBold: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          initialValue: _formData.notes,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات',
                            prefixIcon: Icon(Icons.notes),
                          ),
                          maxLines: 2,
                          onSaved: (v) => _formData.notes = v,
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
                    TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('حفظ كمسودة'),
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

  Widget _buildItemCard(int index, AsyncValue<List<ProductModel>> productsAsync) {
    final item = _items[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: productsAsync.when(
                data: (products) => DropdownButtonFormField<String>(
                  value: item.productId.isEmpty ? null : item.productId,
                  decoration: const InputDecoration(labelText: 'المنتج', isDense: true),
                  items: products.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} - ${_formatCurrency(p.costPrice)}'),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      final product = products.firstWhere((p) => p.id == v);
                      setState(() {
                        item.productId = v;
                        item.unitPrice = product.costPrice;
                      });
                    }
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('خطأ'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: item.quantity.toString(),
                decoration: const InputDecoration(labelText: 'الكمية', isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => item.quantity = double.tryParse(v) ?? 1),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: item.unitPrice.toString(),
                decoration: const InputDecoration(labelText: 'السعر', isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => item.unitPrice = double.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: Text(_formatCurrency(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: () => setState(() => _items.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(_formatCurrency(amount), style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _addItem(List<ProductModel> products) {
    setState(() {
      _items.add(PurchaseItemFormData());
    });
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب إضافة بند واحد على الأقل'), backgroundColor: AppTheme.errorColor),
        );
        return;
      }

      _formKey.currentState!.save();
      _formData.items = _items;
      
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

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س', decimalDigits: 2).format(amount);
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}
