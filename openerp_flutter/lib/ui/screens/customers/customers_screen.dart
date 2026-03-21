import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../logic/providers/customers_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Customers screen - CRM management with full CRUD
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
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
    final customersAsync = ref.watch(customersProvider);
    final statsAsync = ref.watch(customerStatsProvider);
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
              child: customersAsync.when(
                data: (customers) {
                  final filteredCustomers = _filterCustomers(customers);
                  return _buildContent(filteredCustomers, isDesktop);
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
                        onPressed: () => ref.invalidate(customersProvider),
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
          onPressed: () => _showCustomerDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('عميل جديد'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<CustomerStats> statsAsync, bool isDesktop) {
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
                    'العملاء',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'إدارة بيانات العملاء والديون',
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

  Widget _buildStatsRow(CustomerStats stats, bool isDesktop) {
    if (isDesktop) {
      return Row(
        children: [
          _buildStatChip('الإجمالي', stats.total.toString(), Colors.blue),
          const SizedBox(width: 12),
          _buildStatChip('النشطين', stats.active.toString(), AppTheme.successColor),
          const SizedBox(width: 12),
          _buildStatChip('المستحقات', _formatCurrency(stats.totalReceivables), AppTheme.warningColor),
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
        hintText: 'البحث عن عميل...',
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

  List<CustomerModel> _filterCustomers(List<CustomerModel> customers) {
    var filtered = customers;
    
    // Filter by active status
    if (!_showInactive) {
      filtered = filtered.where((c) => c.isActive).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query) ||
            (c.email?.toLowerCase().contains(query) ?? false) ||
            (c.phone?.contains(query) ?? false) ||
            (c.mobile?.contains(query) ?? false);
      }).toList();
    }
    
    return filtered;
  }

  Widget _buildContent(List<CustomerModel> customers, bool isDesktop) {
    if (customers.isEmpty) {
      return _buildEmptyState();
    }
    
    if (isDesktop) {
      return _buildDataTable(customers);
    } else {
      return _buildMobileList(customers);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'لا يوجد عملاء' : 'لا توجد نتائج بحث',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'اضغط على زر "عميل جديد" لإضافة عميل'
                : 'جرب البحث بكلمات مختلفة',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<CustomerModel> customers) {
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
          headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المدينة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الرصيد', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: customers.map((customer) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          customer.name.substring(0, 1),
                          style: const TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(customer.name),
                    ],
                  ),
                ),
                DataCell(Text(customer.email ?? '-')),
                DataCell(Text(customer.phone ?? customer.mobile ?? '-')),
                DataCell(Text(customer.city ?? '-')),
                DataCell(
                  Text(
                    _formatCurrency(customer.balance),
                    style: TextStyle(
                      color: customer.balance > 0 ? AppTheme.errorColor : AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: customer.isActive 
                          ? AppTheme.successColor.withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      customer.isActive ? 'نشط' : 'غير نشط',
                      style: TextStyle(
                        color: customer.isActive ? AppTheme.successColor : Colors.grey,
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
                        onPressed: () => _showCustomerDetails(context, customer),
                        tooltip: 'عرض التفاصيل',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.warningColor),
                        onPressed: () => _showCustomerDialog(context, customer: customer),
                        tooltip: 'تعديل',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                        onPressed: () => _confirmDelete(context, customer),
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

  Widget _buildMobileList(List<CustomerModel> customers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildMobileCustomerCard(customer);
      },
    );
  }

  Widget _buildMobileCustomerCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showCustomerDetails(context, customer),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      customer.name.substring(0, 1),
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          customer.email ?? customer.phone ?? 'لا توجد معلومات',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: customer.isActive 
                          ? AppTheme.successColor.withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      customer.isActive ? 'نشط' : 'غير نشط',
                      style: TextStyle(
                        color: customer.isActive ? AppTheme.successColor : Colors.grey,
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
                        _formatCurrency(customer.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: customer.balance > 0 ? AppTheme.errorColor : AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.warningColor),
                        onPressed: () => _showCustomerDialog(context, customer: customer),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                        onPressed: () => _confirmDelete(context, customer),
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

  void _showCustomerDialog(BuildContext context, {CustomerModel? customer}) {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        customer: customer,
        onSave: (data) async {
          final notifier = ref.read(customersNotifierProvider.notifier);
          if (customer != null) {
            await notifier.updateItem(customer.id, data);
          } else {
            await notifier.create(data);
          }
        },
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerDetailsDialog(customer: customer),
    );
  }

  void _confirmDelete(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف العميل "${customer.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(customersNotifierProvider.notifier).delete(customer.id);
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

/// Customer form dialog for create/edit
class CustomerFormDialog extends StatefulWidget {
  final CustomerModel? customer;
  final Future<void> Function(CustomerFormData) onSave;

  const CustomerFormDialog({
    super.key,
    this.customer,
    required this.onSave,
  });

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late CustomerFormData _formData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formData = CustomerFormData.fromModel(widget.customer);
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
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.customer != null ? Icons.edit : Icons.person_add,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.customer != null ? 'تعديل العميل' : 'إضافة عميل جديد',
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
                            labelText: 'اسم العميل *',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال اسم العميل';
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
                        
                        // Credit limit
                        TextFormField(
                          initialValue: _formData.creditLimit.toString(),
                          decoration: const InputDecoration(
                            labelText: 'حد الائتمان',
                            prefixIcon: Icon(Icons.account_balance_wallet),
                            suffixText: 'ر.س',
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (value) => _formData.creditLimit = double.tryParse(value ?? '0') ?? 0,
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
                          subtitle: Text(_formData.isActive ? 'العميل نشط' : 'العميل غير نشط'),
                          value: _formData.isActive,
                          onChanged: (value) {
                            setState(() {
                              _formData.isActive = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.customer != null ? 'تحديث' : 'حفظ'),
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

/// Customer details dialog
class CustomerDetailsDialog extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailsDialog({super.key, required this.customer});

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
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        customer.name.substring(0, 1),
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            customer.isActive ? 'نشط' : 'غير نشط',
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
                    _buildDetailRow(Icons.email, 'البريد الإلكتروني', customer.email ?? 'غير محدد'),
                    _buildDetailRow(Icons.phone, 'الهاتف', customer.phone ?? 'غير محدد'),
                    _buildDetailRow(Icons.phone_android, 'الجوال', customer.mobile ?? 'غير محدد'),
                    _buildDetailRow(Icons.location_on, 'العنوان', customer.address ?? 'غير محدد'),
                    _buildDetailRow(Icons.location_city, 'المدينة', customer.city ?? 'غير محدد'),
                    _buildDetailRow(Icons.public, 'الدولة', customer.country ?? 'غير محدد'),
                    _buildDetailRow(Icons.receipt, 'الرقم الضريبي', customer.taxNumber ?? 'غير محدد'),
                    const Divider(),
                    _buildDetailRow(
                      Icons.account_balance_wallet,
                      'الرصيد',
                      NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س').format(customer.balance),
                      isHighlighted: true,
                    ),
                    _buildDetailRow(
                      Icons.account_balance_wallet,
                      'حد الائتمان',
                      NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س').format(customer.creditLimit),
                    ),
                    if (customer.notes != null && customer.notes!.isNotEmpty)
                      _buildDetailRow(Icons.notes, 'ملاحظات', customer.notes!),
                  ],
                ),
              ),
              
              // Close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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
              color: isHighlighted ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
