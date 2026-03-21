import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../logic/providers/accounts_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Chart of Accounts screen with hierarchical tree view
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  String? _selectedType;
  String _searchQuery = '';
  final _expandedNodes = <String>{};
  
  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsTreeProvider);
    final statsAsync = ref.watch(accountStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 1000;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            _buildHeader(statsAsync, isDesktop),
            Expanded(
              child: accountsAsync.when(
                data: (accounts) => _buildContent(accounts, isDesktop),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => _buildError(e),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAccountDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('حساب جديد'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<AccountStats> statsAsync, bool isDesktop) {
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
                  Text('شجرة الحسابات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('الدليل المحاسبي والقيود المزدوجة', style: TextStyle(color: Colors.grey)),
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
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 16),
              _buildTypeFilter(),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.unfold_more),
                label: const Text('توسيع الكل'),
                onPressed: () => _expandAll(),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.unfold_less),
                label: const Text('طي الكل'),
                onPressed: () => _collapseAll(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChips(AccountStats stats) {
    return Row(
      children: [
        _buildStatChip('الحسابات', stats.total.toString(), Colors.blue),
        const SizedBox(width: 12),
        _buildStatChip('صافي الربح', _formatCurrency(stats.netIncome), 
          stats.netIncome >= 0 ? AppTheme.successColor : AppTheme.errorColor),
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

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'البحث في الحسابات...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : null,
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String?>(
        value: _selectedType,
        underline: const SizedBox.shrink(),
        hint: const Text('جميع الأنواع'),
        items: const [
          DropdownMenuItem(value: null, child: Text('جميع الأنواع')),
          DropdownMenuItem(value: 'asset', child: Text('الأصول')),
          DropdownMenuItem(value: 'liability', child: Text('الخصوم')),
          DropdownMenuItem(value: 'equity', child: Text('حقوق الملكية')),
          DropdownMenuItem(value: 'income', child: Text('الإيرادات')),
          DropdownMenuItem(value: 'expense', child: Text('المصروفات')),
        ],
        onChanged: (value) => setState(() => _selectedType = value),
      ),
    );
  }

  void _expandAll() {
    setState(() {
      // Add all account IDs to expanded set
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedNodes.clear();
    });
  }

  Widget _buildContent(List<AccountModel> accounts, bool isDesktop) {
    final filteredAccounts = _filterAccounts(accounts);
    
    if (filteredAccounts.isEmpty) {
      return _buildEmptyState();
    }

    // Group by type
    final groupedAccounts = _groupByType(filteredAccounts);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AccountType.values.map((type) {
          final typeAccounts = groupedAccounts[type.value] ?? [];
          if (typeAccounts.isEmpty && _selectedType != null && _selectedType != type.value) {
            return const SizedBox.shrink();
          }
          return _buildTypeSection(type, typeAccounts, isDesktop);
        }).toList(),
      ),
    );
  }

  List<AccountModel> _filterAccounts(List<AccountModel> accounts) {
    var filtered = accounts;
    
    if (_selectedType != null) {
      filtered = filtered.where((a) => a.type == _selectedType).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.name.toLowerCase().contains(query) ||
               a.code.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
  }

  Map<String, List<AccountModel>> _groupByType(List<AccountModel> accounts) {
    final grouped = <String, List<AccountModel>>{};
    for (final account in accounts) {
      grouped.putIfAbsent(account.type, () => []).add(account);
    }
    return grouped;
  }

  Widget _buildTypeSection(AccountType type, List<AccountModel> accounts, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTypeColor(type.value).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(_getTypeIcon(type.value), color: _getTypeColor(type.value)),
                const SizedBox(width: 12),
                Text(
                  type.arabicName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(type.value),
                  ),
                ),
                const Spacer(),
                Text(
                  '(${type.codeRange})',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          // Account tree
          if (accounts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: accounts.map((account) => _buildAccountNode(account, 0)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountNode(AccountModel account, int level) {
    final hasChildren = account.children.isNotEmpty;
    final isExpanded = _expandedNodes.contains(account.id);
    final indent = level * 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account row
        InkWell(
          onTap: () => _showAccountDetails(account),
          child: Padding(
            padding: EdgeInsets.only(right: indent),
            child: Row(
              children: [
                // Expand/collapse button
                SizedBox(
                  width: 32,
                  child: hasChildren
                      ? IconButton(
                          icon: Icon(
                            isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_left,
                            size: 20,
                          ),
                          onPressed: () => _toggleNode(account.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      : null,
                ),
                
                // Account icon
                Icon(
                  account.isHeader ? Icons.folder : Icons.account_balance,
                  size: 20,
                  color: account.isHeader ? _getTypeColor(account.type) : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                
                // Account code
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    account.code,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Account name
                Expanded(
                  child: Text(
                    account.name,
                    style: TextStyle(
                      fontWeight: account.isHeader ? FontWeight.bold : FontWeight.normal,
                      color: account.isActive ? null : Colors.grey,
                    ),
                  ),
                ),
                
                // Balance
                if (!account.isHeader)
                  Text(
                    _formatCurrency(account.displayBalance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: account.balance >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  ),
                
                // Status badge
                if (!account.isActive)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('غير نشط', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                
                // Actions
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => _showAccountDialog(context, parentId: account.id, type: account.type),
                  tooltip: 'إضافة حساب فرعي',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: AppTheme.warningColor),
                  onPressed: () => _showAccountDialog(context, account: account),
                  tooltip: 'تعديل',
                ),
              ],
            ),
          ),
        ),
        
        // Children
        if (hasChildren && isExpanded)
          ...account.children.map((child) => _buildAccountNode(child, level + 1)),
      ],
    );
  }

  void _toggleNode(String id) {
    setState(() {
      if (_expandedNodes.contains(id)) {
        _expandedNodes.remove(id);
      } else {
        _expandedNodes.add(id);
      }
    });
  }

  Color _getTypeColor(String type) {
    return switch (type) {
      'asset' => Colors.blue,
      'liability' => Colors.orange,
      'equity' => Colors.purple,
      'income' => AppTheme.successColor,
      'expense' => AppTheme.errorColor,
      _ => Colors.grey,
    };
  }

  IconData _getTypeIcon(String type) {
    return switch (type) {
      'asset' => Icons.account_balance_wallet,
      'liability' => Icons.credit_card,
      'equity' => Icons.pie_chart,
      'income' => Icons.trending_up,
      'expense' => Icons.trending_down,
      _ => Icons.book,
    };
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text('لا توجد حسابات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('اضغط على زر "حساب جديد" للإضافة', style: TextStyle(color: Colors.grey)),
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
            onPressed: () => ref.invalidate(accountsTreeProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _showAccountDialog(BuildContext context, {AccountModel? account, String? parentId, String? type}) {
    showDialog(
      context: context,
      builder: (context) => AccountFormDialog(
        account: account,
        parentId: parentId,
        defaultType: type,
        onSave: (data) async {
          final notifier = ref.read(accountsNotifierProvider.notifier);
          if (account != null) {
            await notifier.update(account.id, data);
          } else {
            await notifier.create(data);
          }
        },
      ),
    );
  }

  void _showAccountDetails(AccountModel account) {
    showDialog(
      context: context,
      builder: (context) => AccountDetailsDialog(account: account),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س', decimalDigits: 2).format(amount);
  }
}

// Account Form Dialog
class AccountFormDialog extends StatefulWidget {
  final AccountModel? account;
  final String? parentId;
  final String? defaultType;
  final Future<void> Function(AccountFormData) onSave;

  const AccountFormDialog({
    super.key,
    this.account,
    this.parentId,
    this.defaultType,
    required this.onSave,
  });

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late AccountFormData _formData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formData = AccountFormData.fromModel(widget.account);
    if (widget.parentId != null) {
      _formData.parentId = widget.parentId;
    }
    if (widget.defaultType != null) {
      _formData.type = widget.defaultType!;
    }
  }

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
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getTypeColor(_formData.type),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(widget.account != null ? Icons.edit : Icons.add, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      widget.account != null ? 'تعديل الحساب' : 'إضافة حساب جديد',
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
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: _formData.code,
                              decoration: const InputDecoration(labelText: 'الرقم'),
                              keyboardType: TextInputType.number,
                              onSaved: (v) => _formData.code = v ?? '',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _formData.name,
                              decoration: const InputDecoration(labelText: 'اسم الحساب *'),
                              validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                              onSaved: (v) => _formData.name = v ?? '',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _formData.type,
                        decoration: const InputDecoration(labelText: 'نوع الحساب'),
                        items: const [
                          DropdownMenuItem(value: 'asset', child: Text('الأصول')),
                          DropdownMenuItem(value: 'liability', child: Text('الخصوم')),
                          DropdownMenuItem(value: 'equity', child: Text('حقوق الملكية')),
                          DropdownMenuItem(value: 'income', child: Text('الإيرادات')),
                          DropdownMenuItem(value: 'expense', child: Text('المصروفات')),
                        ],
                        onChanged: (v) => setState(() => _formData.type = v ?? 'asset'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _formData.normalBalance,
                        decoration: const InputDecoration(labelText: 'طبيعة الحساب'),
                        items: const [
                          DropdownMenuItem(value: 'debit', child: Text('مدين')),
                          DropdownMenuItem(value: 'credit', child: Text('دائن')),
                        ],
                        onChanged: (v) => setState(() => _formData.normalBalance = v ?? 'debit'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _formData.description,
                        decoration: const InputDecoration(labelText: 'الوصف'),
                        maxLines: 2,
                        onSaved: (v) => _formData.description = v,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('نشط'),
                              value: _formData.isActive,
                              onChanged: (v) => setState(() => _formData.isActive = v),
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('حساب رئيسي'),
                              value: _formData.isHeader,
                              onChanged: (v) => setState(() => _formData.isHeader = v),
                            ),
                          ),
                        ],
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
                          : Text(widget.account != null ? 'تحديث' : 'حفظ'),
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

  Color _getTypeColor(String type) {
    return switch (type) {
      'asset' => Colors.blue,
      'liability' => Colors.orange,
      'equity' => Colors.purple,
      'income' => AppTheme.successColor,
      'expense' => AppTheme.errorColor,
      _ => Colors.grey,
    };
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

// Account Details Dialog
class AccountDetailsDialog extends StatelessWidget {
  final AccountModel account;

  const AccountDetailsDialog({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getTypeColor(account.type),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: Colors.white),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          account.code,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDetailRow('النوع', account.accountType.arabicName),
                    _buildDetailRow('طبيعة الحساب', account.isDebitNormal ? 'مدين' : 'دائن'),
                    const Divider(),
                    _buildDetailRow(
                      'الرصيد',
                      NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س').format(account.displayBalance),
                      isBold: true,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: account.isActive ? AppTheme.successColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(account.isActive ? Icons.check_circle : Icons.cancel, 
                               color: account.isActive ? AppTheme.successColor : Colors.grey, size: 16),
                          const SizedBox(width: 8),
                          Text(account.isActive ? 'نشط' : 'غير نشط',
                               style: TextStyle(color: account.isActive ? AppTheme.successColor : Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    return switch (type) {
      'asset' => Colors.blue,
      'liability' => Colors.orange,
      'equity' => Colors.purple,
      'income' => AppTheme.successColor,
      'expense' => AppTheme.errorColor,
      _ => Colors.grey,
    };
  }
}
