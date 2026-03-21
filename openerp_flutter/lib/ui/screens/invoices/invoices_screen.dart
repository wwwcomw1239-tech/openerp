import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../logic/providers/invoices_provider.dart';
import '../../../logic/providers/customers_provider.dart';
import '../../../logic/providers/products_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Invoices screen - Sales management with master-detail
class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter;
  String? _selectedInvoiceId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final statsAsync = ref.watch(invoiceStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final isTablet = MediaQuery.of(context).size.width > 800;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            _buildHeader(statsAsync, isDesktop),
            Expanded(
              child: invoicesAsync.when(
                data: (invoices) {
                  final filtered = _filterInvoices(invoices);
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
          onPressed: () => _showInvoiceDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('فاتورة جديدة'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<InvoiceStats> statsAsync, bool isDesktop) {
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
                  Text('فواتير المبيعات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('إدارة الفواتير والمدفوعات', style: TextStyle(color: Colors.grey)),
                ],
              ),
              statsAsync.when(
                data: (stats) => isDesktop
                    ? Row(
                        children: [
                          _buildStatChip('الإجمالي', stats.total.toString(), Colors.blue),
                          const SizedBox(width: 12),
                          _buildStatChip('المبيعات', _formatCurrency(stats.totalSales), AppTheme.successColor),
                          const SizedBox(width: 12),
                          _buildStatChip('المستحقات', _formatCurrency(stats.totalReceivables), AppTheme.warningColor),
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
        hintText: 'البحث برقم الفاتورة...',
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
          DropdownMenuItem(value: 'confirmed', child: Text('مؤكدة')),
          DropdownMenuItem(value: 'paid', child: Text('مدفوعة')),
          DropdownMenuItem(value: 'cancelled', child: Text('ملغاة')),
        ],
        onChanged: (value) => setState(() => _statusFilter = value),
      ),
    );
  }

  List<InvoiceModel> _filterInvoices(List<InvoiceModel> invoices) {
    var filtered = invoices;
    
    if (_statusFilter != null) {
      filtered = filtered.where((i) => i.status == _statusFilter).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((i) => i.invoiceNumber.toLowerCase().contains(query)).toList();
    }
    
    return filtered..sort((a, b) => b.date.compareTo(a.date));
  }

  Widget _buildMasterDetailLayout(List<InvoiceModel> invoices, bool isTablet) {
    return Row(
      children: [
        SizedBox(
          width: isTablet ? 400 : 350,
          child: _buildInvoicesList(invoices),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedInvoiceId != null
              ? _buildInvoiceDetail(_selectedInvoiceId!)
              : _buildEmptyDetail(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<InvoiceModel> invoices) {
    return _buildInvoicesList(invoices);
  }

  Widget _buildInvoicesList(List<InvoiceModel> invoices) {
    if (invoices.isEmpty) {
      return _buildEmptyState('لا توجد فواتير', 'اضغط على زر "فاتورة جديدة" للإضافة');
    }

    final customersAsync = ref.watch(customersProvider);

    return customersAsync.when(
      data: (customers) {
        final customersMap = {for (var c in customers) c.id: c};
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            final customer = customersMap[invoice.customerId];
            final isSelected = _selectedInvoiceId == invoice.id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected ? BorderSide(color: AppTheme.primaryColor, width: 2) : BorderSide.none,
              ),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedInvoiceId = invoice.id);
                  if (MediaQuery.of(context).size.width <= 1200) {
                    _showInvoiceDetailDialog(invoice.id);
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
                            invoice.invoiceNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          _buildStatusBadge(invoice.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customer?.name ?? 'عميل غير معروف',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(invoice.date),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _formatCurrency(invoice.total),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                      if (invoice.paidAmount > 0 && invoice.paidAmount < invoice.total) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: invoice.paidAmount / invoice.total,
                          backgroundColor: Colors.grey[200],
                          color: AppTheme.successColor,
                        ),
                      ],
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

  Widget _buildInvoiceDetail(String invoiceId) {
    final invoiceAsync = ref.watch(invoiceWithItemsProvider(invoiceId));

    return invoiceAsync.when(
      data: (data) {
        if (data == null) return _buildEmptyDetail();
        return _buildInvoiceDetailContent(data);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => _buildError(e),
    );
  }

  Widget _buildInvoiceDetailContent(InvoiceWithItems data) {
    final invoice = data.invoice;
    final items = data.items;
    final customer = data.customer;

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
                    invoice.invoiceNumber,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatDate(invoice.date),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              _buildStatusBadge(invoice.status),
            ],
          ),
          const SizedBox(height: 24),

          // Customer info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer?.name ?? 'عميل غير معروف', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(customer?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Items table
          const Text('بنود الفاتورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
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
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildTotalRow('المجموع الفرعي', invoice.subtotal),
                _buildTotalRow('الضريبة (15%)', invoice.taxAmount),
                if (invoice.discount > 0) _buildTotalRow('الخصم', -invoice.discount, isDiscount: true),
                const Divider(),
                _buildTotalRow('الإجمالي', invoice.total, isBold: true),
                if (invoice.paidAmount > 0) ...[
                  const SizedBox(height: 8),
                  _buildTotalRow('المدفوع', invoice.paidAmount, color: AppTheme.successColor),
                  _buildTotalRow('المتبقي', invoice.balanceDue, color: invoice.balanceDue > 0 ? AppTheme.errorColor : AppTheme.successColor),
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
              if (invoice.isDraft)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('تأكيد'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                  onPressed: () => _confirmInvoice(invoice.id),
                ),
              if (invoice.isConfirmed) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  label: const Text('تسجيل دفعة'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoColor),
                  onPressed: () => _showPaymentDialog(invoice),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('إلغاء'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                  onPressed: () => _cancelInvoice(invoice.id),
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

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, bool isDiscount = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${isDiscount && amount != 0 ? '-' : ''}${_formatCurrency(amount.abs())}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isDiscount ? AppTheme.successColor : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (color, text) = switch (status) {
      'draft' => (Colors.grey, 'مسودة'),
      'confirmed' => (AppTheme.warningColor, 'مؤكدة'),
      'paid' => (AppTheme.successColor, 'مدفوعة'),
      'cancelled' => (AppTheme.errorColor, 'ملغاة'),
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
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('اختر فاتورة لعرض التفاصيل', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[300]),
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
          ElevatedButton(onPressed: () => ref.invalidate(invoicesProvider), child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }

  // Actions
  void _showInvoiceDialog(BuildContext context, {InvoiceModel? invoice}) {
    showDialog(
      context: context,
      builder: (context) => InvoiceFormDialog(
        invoice: invoice,
        onSave: (data) async {
          // Get default user ID (in production, get from auth)
          const defaultUserId = 'user-001';
          await ref.read(invoicesNotifierProvider.notifier).create(data, defaultUserId);
        },
      ),
    );
  }

  void _showInvoiceDetailDialog(String invoiceId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 700,
          child: _buildInvoiceDetail(invoiceId),
        ),
      ),
    );
  }

  void _showPaymentDialog(InvoiceModel invoice) {
    final amountController = TextEditingController(text: invoice.balanceDue.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المستحق: ${_formatCurrency(invoice.balanceDue)}'),
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
              if (amount > 0 && amount <= invoice.balanceDue) {
                await ref.read(invoicesNotifierProvider.notifier).addPayment(invoice.id, amount);
                Navigator.pop(context);
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmInvoice(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الفاتورة'),
        content: const Text('هل أنت متأكد من تأكيد الفاتورة؟ سيتم خصم الكميات من المخزون.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(invoicesNotifierProvider.notifier).updateStatus(id, 'confirmed');
    }
  }

  Future<void> _cancelInvoice(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الفاتورة'),
        content: const Text('هل أنت متأكد من إلغاء الفاتورة؟ سيتم إعادة الكميات للمخزون.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('إلغاء الفاتورة'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(invoicesNotifierProvider.notifier).updateStatus(id, 'cancelled');
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س', decimalDigits: 2).format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

// Invoice Form Dialog with multi-item support
class InvoiceFormDialog extends ConsumerStatefulWidget {
  final InvoiceModel? invoice;
  final Future<void> Function(InvoiceFormData) onSave;

  const InvoiceFormDialog({super.key, this.invoice, required this.onSave});

  @override
  ConsumerState<InvoiceFormDialog> createState() => _InvoiceFormDialogState();
}

class _InvoiceFormDialogState extends ConsumerState<InvoiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late InvoiceFormData _formData;
  bool _isLoading = false;
  List<InvoiceItemFormData> _items = [];

  @override
  void initState() {
    super.initState();
    _formData = InvoiceFormData();
    _items = _formData.items;
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(activeCustomersProvider);
    final productsAsync = ref.watch(activeProductsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
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
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text('فاتورة مبيعات جديدة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                        // Customer and Date
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: customersAsync.when(
                                data: (customers) => DropdownButtonFormField<String>(
                                  value: _formData.customerId.isEmpty ? null : _formData.customerId,
                                  decoration: const InputDecoration(
                                    labelText: 'العميل *',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                  validator: (v) => v == null ? 'مطلوب' : null,
                                  onChanged: (v) => setState(() => _formData.customerId = v ?? ''),
                                ),
                                loading: () => const CircularProgressIndicator(),
                                error: (_, __) => const Text('خطأ في تحميل العملاء'),
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
                        const SizedBox(height: 24),

                        // Items section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('بنود الفاتورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            productsAsync.when(
                              data: (products) => ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة بند'),
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
                            color: AppTheme.primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildTotalRow('المجموع الفرعي', _formData.subtotal),
                              _buildTotalRow('الضريبة (15%)', _formData.taxAmount),
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
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: productsAsync.when(
                    data: (products) => DropdownButtonFormField<String>(
                      value: item.productId.isEmpty ? null : item.productId,
                      decoration: const InputDecoration(labelText: 'المنتج', isDense: true),
                      items: products.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} - ${_formatCurrency(p.salePrice)}'),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          final product = products.firstWhere((p) => p.id == v);
                          setState(() {
                            item.productId = v;
                            item.unitPrice = product.salePrice;
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
                    onChanged: (v) {
                      setState(() => item.quantity = double.tryParse(v) ?? 1);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
                    decoration: const InputDecoration(labelText: 'السعر', isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      setState(() => item.unitPrice = double.tryParse(v) ?? 0);
                    },
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
      _items.add(InvoiceItemFormData(taxRate: 15.0));
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
