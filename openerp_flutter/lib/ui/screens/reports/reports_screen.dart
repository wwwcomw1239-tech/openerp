import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../logic/providers/financial_reports_provider.dart';
import '../../../services/pdf_export_service.dart';
import '../../../core/theme/app_theme.dart';

/// Financial Reports Screen - Trial Balance, Income Statement, Balance Sheet
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTrialBalanceTab(),
                  _buildIncomeStatementTab(),
                  _buildBalanceSheetTab(),
                  _buildFinancialSummaryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('التقارير المالية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('ميزان المراجعة وقائمة الدخل والميزانية العمومية', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text('من ${DateFormat('yyyy-MM-dd').format(_fromDate)}'),
                onPressed: () async {
                  final date = await showDatePicker(context: context, initialDate: _fromDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (date != null) setState(() => _fromDate = date);
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text('إلى ${DateFormat('yyyy-MM-dd').format(_toDate)}'),
                onPressed: () async {
                  final date = await showDatePicker(context: context, initialDate: _toDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (date != null) setState(() => _toDate = date);
                },
              ),
            ],
          ),
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
        tabs: const [
          Tab(text: 'ميزان المراجعة'),
          Tab(text: 'قائمة الدخل'),
          Tab(text: 'الميزانية العمومية'),
          Tab(text: 'ملخص مالي'),
        ],
      ),
    );
  }

  Widget _buildTrialBalanceTab() {
    final trialBalanceAsync = ref.watch(trialBalanceProvider);

    return trialBalanceAsync.when(
      data: (tb) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ميزان المراجعة', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('تصدير PDF'),
                  onPressed: () => _exportTrialBalancePdf(tb),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
                columns: const [
                  DataColumn(label: Text('رقم الحساب')),
                  DataColumn(label: Text('اسم الحساب')),
                  DataColumn(label: Text('مدين')),
                  DataColumn(label: Text('دائن')),
                ],
                rows: [
                  ...tb.items.map((item) => DataRow(cells: [
                    DataCell(Text(item.accountCode)),
                    DataCell(Text(item.accountName)),
                    DataCell(Text(item.debit > 0 ? _formatCurrency(item.debit) : '-', style: TextStyle(color: AppTheme.primaryColor))),
                    DataCell(Text(item.credit > 0 ? _formatCurrency(item.credit) : '-', style: TextStyle(color: AppTheme.successColor))),
                  ])),
                  DataRow(
                    color: WidgetStateProperty.all(Colors.grey[200]),
                    cells: [
                      const DataCell(Text('')),
                      const DataCell(Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatCurrency(tb.totalDebit), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatCurrency(tb.totalCredit), style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: tb.isBalanced ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tb.isBalanced ? Icons.check_circle : Icons.warning, color: tb.isBalanced ? AppTheme.successColor : AppTheme.errorColor),
                  const SizedBox(width: 8),
                  Text(tb.isBalanced ? 'ميزان المراجعة متوازن ✓' : 'ميزان المراجعة غير متوازن', style: TextStyle(color: tb.isBalanced ? AppTheme.successColor : AppTheme.errorColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildIncomeStatementTab() {
    final incomeStatementAsync = ref.watch(incomeStatementProvider);

    return incomeStatementAsync.when(
      data: (incomeStmt) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('قائمة الدخل', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('تصدير PDF'),
                  onPressed: () => _exportIncomeStatementPdf(incomeStmt),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard('الإيرادات', incomeStmt.revenue.items.map((i) => {'name': i.accountName, 'amount': i.amount}).toList(), incomeStmt.revenue.total, Colors.green),
            const SizedBox(height: 16),
            _buildSectionCard('المصروفات', incomeStmt.expenses.items.map((i) => {'name': i.accountName, 'amount': i.amount}).toList(), incomeStmt.expenses.total, Colors.red),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: incomeStmt.netIncome >= 0 ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: incomeStmt.netIncome >= 0 ? AppTheme.successColor : AppTheme.errorColor, width: 2)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(incomeStmt.netIncome >= 0 ? 'صافي الربح' : 'صافي الخسارة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_formatCurrency(incomeStmt.netIncome.abs()), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: incomeStmt.netIncome >= 0 ? AppTheme.successColor : AppTheme.errorColor)),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildBalanceSheetTab() {
    final balanceSheetAsync = ref.watch(balanceSheetProvider);

    return balanceSheetAsync.when(
      data: (bs) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الميزانية العمومية', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('تصدير PDF'),
                  onPressed: () => _exportBalanceSheetPdf(bs),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSectionCard('الأصول', bs.assets.items.map((i) => {'name': i.accountName, 'amount': i.amount}).toList(), bs.assets.total, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildSectionCard('الخصوم', bs.liabilities.items.map((i) => {'name': i.accountName, 'amount': i.amount}).toList(), bs.liabilities.total, Colors.orange),
                      const SizedBox(height: 16),
                      _buildSectionCard('حقوق الملكية', bs.equity.items.map((i) => {'name': i.accountName, 'amount': i.amount}).toList(), bs.equity.total, Colors.purple),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bs.isBalanced ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(bs.isBalanced ? Icons.check_circle : Icons.warning, color: bs.isBalanced ? AppTheme.successColor : AppTheme.errorColor),
                  const SizedBox(width: 8),
                  Text(bs.isBalanced ? 'الميزانية متوازنة ✓' : 'الميزانية غير متوازنة', style: TextStyle(color: bs.isBalanced ? AppTheme.successColor : AppTheme.errorColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildFinancialSummaryTab() {
    final summaryAsync = ref.watch(financialSummaryProvider);

    return summaryAsync.when(
      data: (summary) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryCard('إجمالي الأصول', summary.totalAssets, Colors.blue, Icons.account_balance_wallet),
                _buildSummaryCard('إجمالي الخصوم', summary.totalLiabilities, Colors.orange, Icons.credit_card),
                _buildSummaryCard('حقوق الملكية', summary.totalEquity, Colors.purple, Icons.pie_chart),
                _buildSummaryCard('الإيرادات', summary.totalRevenue, Colors.green, Icons.trending_up),
                _buildSummaryCard('المصروفات', summary.totalExpenses, Colors.red, Icons.trending_down),
                _buildSummaryCard('صافي الربح', summary.netIncome, summary.netIncome >= 0 ? Colors.green : Colors.red, Icons.attach_money),
                _buildSummaryCard('الذمم المدينة', summary.accountsReceivable, Colors.blue, Icons.receipt_long),
                _buildSummaryCard('الذمم الدائنة', summary.accountsPayable, Colors.orange, Icons.payment),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)))]),
          const Spacer(),
          Text(_formatCurrency(value), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Map<String, dynamic>> items, double total, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
            child: Row(children: [Icon(Icons.folder, color: color), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]),
          ),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item['name'] ?? ''), Text(_formatCurrency(item['amount'] ?? 0))]),
          )),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('الإجمالي', style: const TextStyle(fontWeight: FontWeight.bold)), Text(_formatCurrency(total), style: TextStyle(fontWeight: FontWeight.bold, color: color))]),
          ),
        ],
      ),
    );
  }

  // PDF Export Methods
  Future<void> _exportTrialBalancePdf(TrialBalance tb) async {
    final pdfData = await PdfExportService.generateTrialBalancePdf(
      asOfDate: tb.asOfDate,
      items: tb.items.map((i) => {'code': i.accountCode, 'name': i.accountName, 'debit': i.debit, 'credit': i.credit}).toList(),
      totalDebit: tb.totalDebit,
      totalCredit: tb.totalCredit,
    );
    await PdfExportService.printPdf(pdfData);
  }

  Future<void> _exportIncomeStatementPdf(IncomeStatement incomeStmt) async {
    final pdfData = await PdfExportService.generateIncomeStatementPdf(
      fromDate: incomeStmt.fromDate,
      toDate: incomeStmt.toDate,
      revenue: incomeStmt.revenue.items.map((i) => {'name': i.accountName, 'amount': i.amount}).toList(),
      totalRevenue: incomeStmt.revenue.total,
      expenses: incomeStmt.expenses.items.map((i) => {'name': i.accountName, 'amount': i.amount}).toList(),
      totalExpenses: incomeStmt.expenses.total,
      netIncome: incomeStmt.netIncome,
    );
    await PdfExportService.printPdf(pdfData);
  }

  Future<void> _exportBalanceSheetPdf(BalanceSheet bs) async {
    final pdfData = await PdfExportService.generateBalanceSheetPdf(
      asOfDate: bs.asOfDate,
      assets: bs.assets.items.map((i) => {'name': i.accountName, 'amount': i.amount}).toList(),
      totalAssets: bs.totalAssets,
      liabilities: bs.liabilities.items.map((i) => {'name': i.accountName, 'amount': i.amount}).toList(),
      totalLiabilities: bs.totalLiabilities,
      equity: bs.equity.items.map((i) => {'name': i.accountName, 'amount': i.amount}).toList(),
      totalEquity: bs.totalEquity,
    );
    await PdfExportService.printPdf(pdfData);
  }

  String _formatCurrency(double amount) => NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س', decimalDigits: 2).format(amount);
}
