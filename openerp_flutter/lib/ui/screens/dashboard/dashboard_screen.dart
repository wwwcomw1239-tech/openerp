import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../logic/providers/dashboard_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Safe currency formatter that works in release mode
class SafeCurrencyFormatter {
  static String format(double amount) {
    try {
      // Try Arabic locale first
      final formatter = NumberFormat.currency(
        locale: 'ar_SA',
        symbol: 'ر.س ',
        decimalDigits: 2,
      );
      return formatter.format(amount);
    } catch (e) {
      // Fallback to simple formatting if locale fails
      return '${amount.toStringAsFixed(2)} ر.س';
    }
  }
}

/// Dashboard screen - Main analytics and overview with fl_chart
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentInvoicesAsync = ref.watch(recentInvoicesProvider);
    final recentPurchasesAsync = ref.watch(recentPurchasesProvider);
    final topCustomersAsync = ref.watch(topCustomersProvider);
    final inventoryAlertsAsync = ref.watch(inventoryAlertsProvider);
    
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final isTablet = MediaQuery.of(context).size.width > 800;
    
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),
                
                // Stats cards row
                _buildResponsiveRow(
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                  children: [
                    _buildStatCard(
                      context: context,
                      title: 'إجمالي المبيعات',
                      value: _formatCurrency(stats.totalSales),
                      icon: Icons.trending_up,
                      color: AppTheme.successColor,
                      trend: stats.totalSales > 0 ? '+12%' : null,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'إجمالي المشتريات',
                      value: _formatCurrency(stats.totalPurchases),
                      icon: Icons.trending_down,
                      color: AppTheme.warningColor,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'صافي الربح',
                      value: _formatCurrency(stats.netProfit),
                      icon: Icons.account_balance_wallet,
                      color: stats.netProfit >= 0 ? AppTheme.infoColor : AppTheme.errorColor,
                      trend: stats.netProfit > 0 ? '+8%' : null,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'عدد العملاء',
                      value: stats.customersCount.toString(),
                      icon: Icons.people,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Charts row
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildSalesChart(context, stats)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildProfitCard(context, stats)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildSalesChart(context, stats),
                      const SizedBox(height: 16),
                      _buildProfitCard(context, stats),
                    ],
                  ),
                const SizedBox(height: 24),
                
                // Bottom section - Recent activity and alerts
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRecentInvoices(context, recentInvoicesAsync)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildRecentPurchases(context, recentPurchasesAsync)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInventoryAlerts(context, inventoryAlertsAsync)),
                    ],
                  )
                else if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRecentInvoices(context, recentInvoicesAsync)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildRecentPurchases(context, recentPurchasesAsync)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildRecentInvoices(context, recentInvoicesAsync),
                      const SizedBox(height: 16),
                      _buildRecentPurchases(context, recentPurchasesAsync),
                    ],
                  ),
                const SizedBox(height: 24),
                
                // Top customers
                _buildTopCustomers(context, topCustomersAsync),
              ],
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البيانات: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(dashboardStatsProvider),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'لوحة التحكم',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'مرحباً بك في نظام OpenERP - ${DateTime.now().toString().split(' ')[0]}',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveRow({
    required bool isDesktop,
    required bool isTablet,
    required List<Widget> children,
  }) {
    if (isDesktop) {
      return Row(children: children.map((c) => Expanded(child: c)).toList());
    } else if (isTablet) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: children.map((c) => SizedBox(width: 200, child: c)).toList(),
      );
    } else {
      return Column(children: children);
    }
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اتجاه المبيعات والمشتريات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'آخر 6 أشهر',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final months = stats.salesTrend;
                        if (value.toInt() < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              months[value.toInt()].month.substring(0, 3),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCompactCurrency(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (stats.salesTrend.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxY(stats),
                lineBarsData: [
                  // Sales line
                  LineChartBarData(
                    spots: stats.salesTrend.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.amount);
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.successColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.successColor.withOpacity(0.1),
                    ),
                  ),
                  // Purchases line
                  LineChartBarData(
                    spots: stats.purchasesTrend.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.amount);
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.warningColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.warningColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isSales = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isSales ? 'مبيعات' : 'مشتريات'}: ${_formatCurrency(spot.y)}',
                          TextStyle(
                            color: isSales ? AppTheme.successColor : AppTheme.warningColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend('المبيعات', AppTheme.successColor),
              const SizedBox(width: 24),
              _buildChartLegend('المشتريات', AppTheme.warningColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  double _getMaxY(DashboardStats stats) {
    final maxSales = stats.salesTrend.isEmpty 
        ? 0.0 
        : stats.salesTrend.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final maxPurchases = stats.purchasesTrend.isEmpty 
        ? 0.0 
        : stats.purchasesTrend.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final maxVal = maxSales > maxPurchases ? maxSales : maxPurchases;
    return maxVal * 1.2; // Add 20% padding
  }

  Widget _buildProfitCard(BuildContext context, DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الأرباح',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildProfitItem(
            'المبيعات',
            stats.totalSales,
            AppTheme.successColor,
          ),
          const SizedBox(height: 12),
          _buildProfitItem(
            'المشتريات',
            stats.totalPurchases,
            AppTheme.errorColor,
          ),
          const Divider(height: 32),
          _buildProfitItem(
            'صافي الربح',
            stats.netProfit,
            stats.netProfit >= 0 ? AppTheme.infoColor : AppTheme.errorColor,
            isBold: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: stats.totalSales,
                    title: 'مبيعات',
                    color: AppTheme.successColor,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: stats.totalPurchases,
                    title: 'مشتريات',
                    color: AppTheme.warningColor,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitItem(String label, double amount, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentInvoices(BuildContext context, AsyncValue<List<InvoiceSummary>> invoicesAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'آخر الفواتير',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          invoicesAsync.when(
            data: (invoices) => invoices.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('لا توجد فواتير', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : Column(
                    children: invoices.map((inv) => _buildInvoiceItem(inv)).toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('خطأ: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(InvoiceSummary invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(invoice.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt_long,
              color: _getStatusColor(invoice.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  invoice.customerName,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(invoice.total),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(invoice.status),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(invoice.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPurchases(BuildContext context, AsyncValue<List<PurchaseSummary>> purchasesAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'آخر المشتريات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          purchasesAsync.when(
            data: (purchases) => purchases.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('لا توجد مشتريات', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : Column(
                    children: purchases.map((pur) => _buildPurchaseItem(pur)).toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('خطأ: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseItem(PurchaseSummary purchase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: AppTheme.warningColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.purchaseNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  purchase.supplierName,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(purchase.total),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(purchase.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(purchase.status),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(purchase.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryAlerts(BuildContext context, AsyncValue<List<InventoryAlert>> alertsAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تنبيهات المخزون',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          alertsAsync.when(
            data: (alerts) => alerts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.successColor),
                          SizedBox(width: 8),
                          Text('لا توجد تنبيهات', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: alerts.take(5).map((alert) => _buildAlertItem(alert)).toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('خطأ: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(InventoryAlert alert) {
    final isOutOfStock = alert.alertType == InventoryAlertType.outOfStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isOutOfStock ? AppTheme.errorColor : AppTheme.warningColor).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOutOfStock ? AppTheme.errorColor : AppTheme.warningColor).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOutOfStock ? Icons.error : Icons.warning,
            color: isOutOfStock ? AppTheme.errorColor : AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  isOutOfStock 
                      ? 'نفذ من المخزون' 
                      : 'الكمية: ${alert.currentQuantity.toStringAsFixed(0)} / الحد الأدنى: ${alert.minQuantity.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCustomers(BuildContext context, AsyncValue<List<TopCustomer>> customersAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أكبر العملاء (حسب الرصيد)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          customersAsync.when(
            data: (customers) => customers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: customers.isEmpty 
                            ? 1000 
                            : customers.map((c) => c.balance).reduce((a, b) => a > b ? a : b) * 1.2,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                _formatCurrency(customers[groupIndex].balance),
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < customers.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      customers[value.toInt()].name.substring(0, 
                                        customers[value.toInt()].name.length > 8 ? 8 : null),
                                      style: const TextStyle(fontSize: 10),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  _formatCompactCurrency(value),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        barGroups: customers.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.balance,
                                color: AppTheme.primaryColor,
                                width: 32,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('خطأ: $e'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'received':
      case 'confirmed':
        return AppTheme.successColor;
      case 'draft':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'مدفوع';
      case 'received':
        return 'مستلم';
      case 'confirmed':
        return 'مؤكد';
      case 'draft':
        return 'مسودة';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String _formatCurrency(double amount) {
    return SafeCurrencyFormatter.format(amount);
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
