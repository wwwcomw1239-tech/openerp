import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../logic/providers/journal_entries_provider.dart';
import '../../../logic/providers/accounts_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Journal Entries screen with double-entry accounting enforcement
class JournalEntriesScreen extends ConsumerStatefulWidget {
  const JournalEntriesScreen({super.key});

  @override
  ConsumerState<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends ConsumerState<JournalEntriesScreen> {
  String? _statusFilter;
  String _searchQuery = '';
  String? _selectedEntryId;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(journalEntriesProvider);
    final statsAsync = ref.watch(journalStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            _buildHeader(statsAsync, isDesktop),
            Expanded(
              child: entriesAsync.when(
                data: (entries) {
                  final filtered = _filterEntries(entries);
                  if (isDesktop) {
                    return _buildMasterDetailLayout(filtered);
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
          onPressed: () => _showJournalEntryDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('قيد جديد'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<JournalStats> statsAsync, bool isDesktop) {
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
                  Text('القيود اليومية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('نظام القيد المزدوج - يجب تساوي المدين والدائن', style: TextStyle(color: Colors.grey)),
                ],
              ),
              statsAsync.when(
                data: (stats) => isDesktop
                    ? Row(
                        children: [
                          _buildStatChip('القيود', stats.total.toString(), Colors.blue),
                          const SizedBox(width: 12),
                          _buildStatChip('المدين', _formatCurrency(stats.totalDebit), AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          _buildStatChip('الدائن', _formatCurrency(stats.totalCredit), AppTheme.successColor),
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
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
        hintText: 'البحث برقم القيد...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: DropdownButton<String?>(
        value: _statusFilter,
        underline: const SizedBox.shrink(),
        hint: const Text('جميع الحالات'),
        items: const [
          DropdownMenuItem(value: null, child: Text('جميع الحالات')),
          DropdownMenuItem(value: 'draft', child: Text('مسودة')),
          DropdownMenuItem(value: 'posted', child: Text('مرحل')),
          DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
        ],
        onChanged: (value) => setState(() => _statusFilter = value),
      ),
    );
  }

  List<JournalEntryModel> _filterEntries(List<JournalEntryModel> entries) {
    var filtered = entries;
    if (_statusFilter != null) {
      filtered = filtered.where((e) => e.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) => e.entryNumber.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return filtered..sort((a, b) => b.date.compareTo(a.date));
  }

  Widget _buildMasterDetailLayout(List<JournalEntryModel> entries) {
    return Row(
      children: [
        SizedBox(width: 400, child: _buildEntriesList(entries)),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedEntryId != null
              ? _buildEntryDetail(_selectedEntryId!)
              : _buildEmptyDetail(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<JournalEntryModel> entries) {
    return _buildEntriesList(entries);
  }

  Widget _buildEntriesList(List<JournalEntryModel> entries) {
    if (entries.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = _selectedEntryId == entry.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected ? BorderSide(color: AppTheme.primaryColor, width: 2) : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => setState(() => _selectedEntryId = entry.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.entryNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      _buildStatusBadge(entry.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(entry.description ?? '', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(entry.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Row(
                        children: [
                          Text('م: ', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                          Text(_formatCurrency(entry.totalDebit),
                              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text('د: ', style: TextStyle(color: AppTheme.successColor, fontSize: 12)),
                          Text(_formatCurrency(entry.totalCredit),
                              style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  // Balance indicator
                  if (entry.isBalanced)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successColor, size: 14),
                        SizedBox(width: 4),
                        Text('متوازن', style: TextStyle(color: AppTheme.successColor, fontSize: 10)),
                      ],
                    )
                  else
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.warning, color: AppTheme.errorColor, size: 14),
                        SizedBox(width: 4),
                        Text('غير متوازن', style: TextStyle(color: AppTheme.errorColor, fontSize: 10)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntryDetail(String entryId) {
    final entryAsync = ref.watch(journalEntryWithLinesProvider(entryId));
    final accountsAsync = ref.watch(accountsProvider);

    return entryAsync.when(
      data: (data) {
        if (data == null) return _buildEmptyDetail();
        return accountsAsync.when(
          data: (accounts) {
            final accountsMap = {for (var a in accounts) a.id: a};
            return _buildEntryDetailContent(data, accountsMap);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => _buildError(e),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => _buildError(e),
    );
  }

  Widget _buildEntryDetailContent(JournalEntryWithLines data, Map<String, AccountModel> accountsMap) {
    final entry = data.entry;

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
                  Text(entry.entryNumber, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_formatDate(entry.date), style: const TextStyle(color: Colors.grey)),
                ],
              ),
              _buildStatusBadge(entry.status),
            ],
          ),
          const SizedBox(height: 16),
          if (entry.description != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.description, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.description!)),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Lines table
          const Text('بنود القيد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                DataColumn(label: Text('الحساب')),
                DataColumn(label: Text('البيان')),
                DataColumn(label: Text('مدين')),
                DataColumn(label: Text('دائن')),
              ],
              rows: data.lines.map((line) {
                final account = accountsMap[line.accountId];
                return DataRow(cells: [
                  DataCell(Text(account?.name ?? 'غير معروف')),
                  DataCell(Text(line.description ?? '-')),
                  DataCell(Text(
                    line.debit > 0 ? _formatCurrency(line.debit) : '-',
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(
                    line.credit > 0 ? _formatCurrency(line.credit) : '-',
                    style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold),
                  )),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Totals with balance verification
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: entry.isBalanced ? AppTheme.successColor.withOpacity(0.05) : AppTheme.errorColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: entry.isBalanced ? AppTheme.successColor : AppTheme.errorColor,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي المدين'),
                    Text(_formatCurrency(entry.totalDebit),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي الدائن'),
                    Text(_formatCurrency(entry.totalCredit),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.isBalanced ? '✓ القيد متوازن' : '✗ القيد غير متوازن',
                        style: TextStyle(
                          color: entry.isBalanced ? AppTheme.successColor : AppTheme.errorColor,
                          fontWeight: FontWeight.bold,
                        )),
                    Text(
                      _formatCurrency((entry.totalDebit - entry.totalCredit).abs()),
                      style: TextStyle(color: entry.isBalanced ? AppTheme.successColor : AppTheme.errorColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (entry.isDraft)
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('ترحيل'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                  onPressed: () => _postEntry(entry.id),
                ),
              if (entry.isPosted)
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('إلغاء'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                  onPressed: () => _cancelEntry(entry.id),
                ),
              if (entry.isDraft)
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('تعديل'),
                  onPressed: () => _showJournalEntryDialog(context, entry: entry),
                ),
              if (entry.isDraft)
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('حذف'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                  onPressed: () => _deleteEntry(entry.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (color, text) = switch (status) {
      'draft' => (Colors.grey, 'مسودة'),
      'posted' => (AppTheme.successColor, 'مرحل'),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('اختر قيداً لعرض التفاصيل', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text('لا توجد قيود', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('اضغط على زر "قيد جديد" للإضافة', style: TextStyle(color: Colors.grey)),
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
            onPressed: () => ref.invalidate(journalEntriesProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  // Actions
  void _showJournalEntryDialog(BuildContext context, {JournalEntryModel? entry}) {
    showDialog(
      context: context,
      builder: (context) => JournalEntryFormDialog(
        entry: entry,
        onSave: (data) async {
          const defaultUserId = 'user-001';
          await ref.read(journalEntriesNotifierProvider.notifier).create(data, defaultUserId);
        },
      ),
    );
  }

  Future<void> _postEntry(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ترحيل القيد'),
        content: const Text('هل أنت متأكد من ترحيل القيد؟ سيتم تحديث أرصدة الحسابات.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ترحيل')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(journalEntriesNotifierProvider.notifier).post(id);
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  Future<void> _cancelEntry(String id) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء القيد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('سيتم إنشاء قيد عكسي. أدخل سبب الإلغاء:'),
            const SizedBox(height: 12),
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'السبب')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('إلغاء القيد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(journalEntriesNotifierProvider.notifier).cancel(id, reasonController.text);
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  Future<void> _deleteEntry(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القيد'),
        content: const Text('هل أنت متأكد من حذف القيد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(journalEntriesNotifierProvider.notifier).delete(id);
        setState(() => _selectedEntryId = null);
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س', decimalDigits: 2).format(amount);
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}

// Journal Entry Form Dialog
class JournalEntryFormDialog extends StatefulWidget {
  final JournalEntryModel? entry;
  final Future<void> Function(JournalEntryFormData) onSave;

  const JournalEntryFormDialog({super.key, this.entry, required this.onSave});

  @override
  State<JournalEntryFormDialog> createState() => _JournalEntryFormDialogState();
}

class _JournalEntryFormDialogState extends State<JournalEntryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late JournalEntryFormData _formData;
  List<JournalLineFormData> _lines = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formData = JournalEntryFormData();
    _lines = [JournalLineFormData(), JournalLineFormData()];
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(activeAccountsProvider);

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
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.book, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text('قيد يومية جديد', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    // Balance indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _formData.isBalanced
                            ? AppTheme.successColor.withOpacity(0.8)
                            : AppTheme.errorColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formData.isBalanced ? 'متوازن ✓' : 'غير متوازن ✗',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'المرجع',
                                  prefixIcon: Icon(Icons.link),
                                ),
                                onSaved: (v) => _formData.reference = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'البيان',
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 2,
                          onSaved: (v) => _formData.description = v,
                        ),
                        const SizedBox(height: 24),

                        // Lines
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('بنود القيد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              'مدين: ${_formatCurrency(_formData.totalDebit)} | دائن: ${_formatCurrency(_formData.totalCredit)}',
                              style: TextStyle(
                                color: _formData.isBalanced ? AppTheme.successColor : AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        accountsAsync.when(
                          data: (accounts) => Column(
                            children: _lines.asMap().entries.map((e) => _buildLineCard(e.key, e.value, accounts)).toList(),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('خطأ في تحميل الحسابات'),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة بند'),
                          onPressed: () => setState(() => _lines.add(JournalLineFormData())),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Validation error
              if (!_formData.isBalanced && _formData.totalDebit > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.errorColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'القيد غير متوازن! الفرق: ${_formatCurrency((_formData.totalDebit - _formData.totalCredit).abs())}',
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
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
                      onPressed: _isLoading || !_formData.isBalanced ? null : _handleSave,
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

  Widget _buildLineCard(int index, JournalLineFormData line, List<AccountModel> accounts) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: line.accountId.isEmpty ? null : line.accountId,
                decoration: const InputDecoration(labelText: 'الحساب', isDense: true),
                items: accounts.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.code} - ${a.name}', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setState(() => line.accountId = v ?? ''),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: TextFormField(
                initialValue: line.debit > 0 ? line.debit.toString() : '',
                decoration: const InputDecoration(labelText: 'مدين', isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  line.debit = double.tryParse(v) ?? 0;
                  if (line.debit > 0) line.credit = 0;
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: TextFormField(
                initialValue: line.credit > 0 ? line.credit.toString() : '',
                decoration: const InputDecoration(labelText: 'دائن', isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  line.credit = double.tryParse(v) ?? 0;
                  if (line.credit > 0) line.debit = 0;
                  setState(() {});
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: () => setState(() => _lines.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final validation = _formData.validate();
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    _formKey.currentState!.save();
    _formData.lines = _lines.where((l) => l.hasValue).toList();

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

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'ar_SA', symbol: '', decimalDigits: 2).format(amount);
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}
