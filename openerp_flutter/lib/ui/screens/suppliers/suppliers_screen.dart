import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../logic/providers/suppliers_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Suppliers screen - Supplier management with full CRUD
class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showInactive = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final statsAsync = ref.watch(supplierStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            // Header and actions
            _buildHeader(statsAsync, isDesktop),
            
            // Content
            Expanded(
              child: suppliersAsync.when(
                data: (suppliers) {
                  final filteredSuppliers = _filterSuppliers(suppliers);
                  return _buildContent(filteredSuppliers, isDesktop);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('خطأ: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(suppliersProvider),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showSupplierDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('مورد جديد'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<SupplierStats> statsAsync, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الموردين',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'إدارة بيانات الموردين والمدفوعات',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              statsAsync.when(
                data: (stats) => _buildStatsRow(stats, isDesktop),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Search and filter row
          isDesktop
              ? Row(
                  children: [
                    Expanded(flex: 2, child: _buildSearchField()),
                    const SizedBox(width: 16),
                    _buildFilterToggle(),
                  ],
                )
              : Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    _buildFilterToggle(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(SupplierStats stats, bool isDesktop) {
    if (isDesktop) {
      return Row(
        children: [
          _buildStatChip('الإجمالي', stats.total.toString(), Colors.blue),
          const SizedBox(width: 12),
          _buildStatChip('النشطين', stats.active.toString(), AppTheme.successColor),
          const SizedBox(width: 12),
          _buildStatChip('المستحقات', _formatCurrency(stats.totalPayables), AppTheme.errorColor),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
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
          Text(
            '$label: ',
            style: TextStyle(color: color, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'البحث عن مورد...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
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

  Widget _buildFilterToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('إظهار غير النشطين'),
        const SizedBox(width: 8),
        Switch(
          value: _showInactive,
          onChanged: (value) {
            setState(() {
              _showInactive = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  List<SupplierModel> _filterSuppliers(List<SupplierModel> suppliers) {
    var filtered = suppliers;
    
    // Filter by active status
    if (!_showInactive) {
      filtered = filtered.where((s) => s.isActive).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(query) ||
            (s.email?.toLowerCase().contains(query) ?? false) ||
            (s.phone?.contains(query) ?? false) ||
            (s.mobile?.contains(query) ?? false);
      }).toList();
    }
    
    return filtered;
  }

  Widget _buildContent(List<SupplierModel> suppliers, bool isDesktop) {
    if (suppliers.isEmpty) {
      return _buildEmptyState();
    }
    
    if (isDesktop) {
      return _buildDataTable(suppliers);
    } else {
      return _buildMobileList(suppliers);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'لا يوجد موردين' : 'لا توجد نتائج بحث',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'اضغط على زر "مورد جديد" لإضافة مورد'
                : 'جرب البحث بكلمات مختلفة',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<SupplierModel> suppliers) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.warningColor.withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المدينة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الرصيد', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: suppliers.map((supplier) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                        child: Text(
                          supplier.name.substring(0, 1),
                          style: const TextStyle(color: AppTheme.warningColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(supplier.name),
                    ],
                  ),
                ),
                DataCell(Text(supplier.email ?? '-')),
                DataCell(Text(supplier.phone ?? supplier.mobile ?? '-')),
                DataCell(Text(supplier.city ?? '-')),
                DataCell(
                  Text(
                    _formatCurrency(supplier.balance),
                    style: TextStyle(
                      color: supplier.balance > 0 ? AppTheme.errorColor : AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: supplier.isActive 
                          ? AppTheme.successColor.withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      supplier.isActive ? 'نشط' : 'غير نشط',
                      style: TextStyle(
                        color: supplier.isActive ? AppTheme.successColor : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => _showSupplierDetails(context, supplier),
                        tooltip: 'عرض التفاصيل',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.warningColor),
                        onPressed: () => _showSupplierDialog(context, supplier: supplier),
                        tooltip: 'تعديل',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                        onPressed: () => _confirmDelete(context, supplier),
                        tooltip: 'حذف',
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

  Widget _buildMobileList(List<SupplierModel> suppliers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return _buildMobileSupplierCard(supplier);
      },
    );
  }

  Widget _buildMobileSupplierCard(SupplierModel supplier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showSupplierDetails(context, supplier),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                    child: Text(
                      supplier.name.substring(0, 1),
                      style: const TextStyle(color: AppTheme.warningColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          supplier.email ?? supplier.phone ?? 'لا توجد معلومات',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: supplier.isActive 
                          ? AppTheme.successColor.withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      supplier.isActive ? 'نشط' : 'غير نشط',
                      style: TextStyle(
                        color: supplier.isActive ? AppTheme.successColor : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الرصيد', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        _formatCurrency(supplier.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: supplier.balance > 0 ? AppTheme.errorColor : AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.warningColor),
                        onPressed: () => _showSupplierDialog(context, supplier: supplier),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                        onPressed: () => _confirmDelete(context, supplier),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupplierDialog(BuildContext context, {SupplierModel? supplier}) {
    showDialog(
      context: context,
      builder: (context) => SupplierFormDialog(
        supplier: supplier,
        onSave: (data) async {
          final notifier = ref.read(suppliersNotifierProvider.notifier);
          if (supplier != null) {
            await notifier.update(supplier.id, data);
          } else {
            await notifier.create(data);
          }
        },
      ),
    );
  }

  void _showSupplierDetails(BuildContext context, SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (context) => SupplierDetailsDialog(supplier: supplier),
    );
  }

  void _confirmDelete(BuildContext context, SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المورد "${supplier.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(suppliersNotifierProvider.notifier).delete(supplier.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}

/// Supplier form dialog for create/edit
class SupplierFormDialog extends StatefulWidget {
  final SupplierModel? supplier;
  final Future<void> Function(SupplierFormData) onSave;

  const SupplierFormDialog({
    super.key,
    this.supplier,
    required this.onSave,
  });

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late SupplierFormData _formData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formData = SupplierFormData.fromModel(widget.supplier);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isDesktop ? 600 : null,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.warningColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.supplier != null ? Icons.edit : Icons.local_shipping,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.supplier != null ? 'تعديل المورد' : 'إضافة مورد جديد',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name field (required)
                        TextFormField(
                          initialValue: _formData.name,
                          decoration: const InputDecoration(
                            labelText: 'اسم المورد *',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال اسم المورد';
                            }
                            return null;
                          },
                          onSaved: (value) => _formData.name = value ?? '',
                        ),
                        const SizedBox(height: 16),
                        
                        // Contact info row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _formData.email,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onSaved: (value) => _formData.email = value,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _formData.phone,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الهاتف',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.phone,
                                onSaved: (value) => _formData.phone = value,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Mobile field
                        TextFormField(
                          initialValue: _formData.mobile,
                          decoration: const InputDecoration(
                            labelText: 'رقم الجوال',
                            prefixIcon: Icon(Icons.phone_android),
                          ),
                          keyboardType: TextInputType.phone,
                          onSaved: (value) => _formData.mobile = value,
                        ),
                        const SizedBox(height: 16),
                        
                        // Address
                        TextFormField(
                          initialValue: _formData.address,
                          decoration: const InputDecoration(
                            labelText: 'العنوان',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 2,
                          onSaved: (value) => _formData.address = value,
                        ),
                        const SizedBox(height: 16),
                        
                        // City and Country
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _formData.city,
                                decoration: const InputDecoration(
                                  labelText: 'المدينة',
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                onSaved: (value) => _formData.city = value,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _formData.country,
                                decoration: const InputDecoration(
                                  labelText: 'الدولة',
                                  prefixIcon: Icon(Icons.public),
                                ),
                                onSaved: (value) => _formData.country = value,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Tax number
                        TextFormField(
                          initialValue: _formData.taxNumber,
                          decoration: const InputDecoration(
                            labelText: 'الرقم الضريبي',
                            prefixIcon: Icon(Icons.receipt),
                          ),
                          onSaved: (value) => _formData.taxNumber = value,
                        ),
                        const SizedBox(height: 16),
                        
                        // Notes
                        TextFormField(
                          initialValue: _formData.notes,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات',
                            prefixIcon: Icon(Icons.notes),
                          ),
                          maxLines: 3,
                          onSaved: (value) => _formData.notes = value,
                        ),
                        const SizedBox(height: 16),
                        
                        // Active status
                        SwitchListTile(
                          title: const Text('نشط'),
                          subtitle: Text(_formData.isActive ? 'المورد نشط' : 'المورد غير نشط'),
                          value: _formData.isActive,
                          onChanged: (value) {
                            setState(() {
                              _formData.isActive = value;
                            });
                          },
                          activeColor: AppTheme.warningColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Actions
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningColor,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.supplier != null ? 'تحديث' : 'حفظ'),
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

/// Supplier details dialog
class SupplierDetailsDialog extends StatelessWidget {
  final SupplierModel supplier;

  const SupplierDetailsDialog({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.warningColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        supplier.name.substring(0, 1),
                        style: const TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            supplier.isActive ? 'نشط' : 'غير نشط',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.email, 'البريد الإلكتروني', supplier.email ?? 'غير محدد'),
                    _buildDetailRow(Icons.phone, 'الهاتف', supplier.phone ?? 'غير محدد'),
                    _buildDetailRow(Icons.phone_android, 'الجوال', supplier.mobile ?? 'غير محدد'),
                    _buildDetailRow(Icons.location_on, 'العنوان', supplier.address ?? 'غير محدد'),
                    _buildDetailRow(Icons.location_city, 'المدينة', supplier.city ?? 'غير محدد'),
                    _buildDetailRow(Icons.public, 'الدولة', supplier.country ?? 'غير محدد'),
                    _buildDetailRow(Icons.receipt, 'الرقم الضريبي', supplier.taxNumber ?? 'غير محدد'),
                    const Divider(),
                    _buildDetailRow(
                      Icons.account_balance_wallet,
                      'الرصيد المستحق',
                      NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س').format(supplier.balance),
                      isHighlighted: true,
                    ),
                    if (supplier.notes != null && supplier.notes!.isNotEmpty)
                      _buildDetailRow(Icons.notes, 'ملاحظات', supplier.notes!),
                  ],
                ),
              ),
              
              // Close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                  ),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? AppTheme.warningColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
