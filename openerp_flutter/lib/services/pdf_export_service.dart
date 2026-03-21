import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter/services.dart';

/// PDF Export Service with Arabic RTL support
class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  static pw.Font? _arabicFont;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      _arabicFont = pw.Font.ttf(fontData);
      _initialized = true;
    } catch (e) {
      _initialized = true;
    }
  }

  static pw.TextStyle get arabicStyle => pw.TextStyle(font: _arabicFont, fontSize: 12);
  static pw.TextStyle get arabicBoldStyle => pw.TextStyle(font: _arabicFont, fontSize: 12, fontWeight: pw.FontWeight.bold);

  static String formatCurrency(double amount) =>
      NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س', decimalDigits: 2).format(amount);

  static String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Generate Invoice PDF
  static Future<Uint8List> generateInvoicePdf({
    required String invoiceNumber,
    required DateTime date,
    required String customerName,
    String? customerAddress,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double taxAmount,
    required double discount,
    required double total,
    required double paidAmount,
    String? notes,
  }) async {
    await initialize();
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Directionality(textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('فاتورة ضريبية', style: arabicBoldStyle.copyWith(fontSize: 24)),
                  pw.Text(invoiceNumber, style: arabicBoldStyle.copyWith(fontSize: 18)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('العميل: $customerName', style: arabicBoldStyle),
                    if (customerAddress != null) pw.Text('العنوان: $customerAddress', style: arabicStyle),
                    pw.Text('التاريخ: ${formatDate(date)}', style: arabicStyle),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('البيان', style: arabicBoldStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('الكمية', style: arabicBoldStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('السعر', style: arabicBoldStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('الإجمالي', style: arabicBoldStyle)),
                    ],
                  ),
                  ...items.map((item) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['name'] ?? '', style: arabicStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item['quantity'] ?? 0}', style: arabicStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(formatCurrency(item['price'] ?? 0), style: arabicStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(formatCurrency(item['total'] ?? 0), style: arabicBoldStyle)),
                  ])),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Column(
                  children: [
                    _buildTotalRow('المجموع الفرعي', subtotal),
                    _buildTotalRow('الضريبة (15%)', taxAmount),
                    if (discount > 0) _buildTotalRow('الخصم', -discount),
                    pw.Divider(),
                    _buildTotalRow('الإجمالي', total, isBold: true),
                    if (paidAmount > 0) _buildTotalRow('المدفوع', paidAmount, color: PdfColors.green),
                    if (total - paidAmount > 0) _buildTotalRow('المتبقي', total - paidAmount, color: PdfColors.red),
                  ],
                ),
              ),
              if (notes != null && notes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('ملاحظات:', style: arabicBoldStyle),
                pw.Text(notes, style: arabicStyle),
              ],
            ],
          ),
        ),
      ],
    ));

    return pdf.save();
  }

  static pw.Widget _buildTotalRow(String label, double amount, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: isBold ? arabicBoldStyle : arabicStyle),
          pw.Text(formatCurrency(amount), style: (isBold ? arabicBoldStyle : arabicStyle).copyWith(color: color)),
        ],
      ),
    );
  }

  /// Generate Trial Balance PDF
  static Future<Uint8List> generateTrialBalancePdf({
    required DateTime asOfDate,
    required List<Map<String, dynamic>> items,
    required double totalDebit,
    required double totalCredit,
  }) async {
    await initialize();
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Directionality(textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Center(child: pw.Text('ميزان المراجعة', style: arabicBoldStyle.copyWith(fontSize: 24))),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('كما في ${formatDate(asOfDate)}', style: arabicStyle)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('رقم الحساب', style: arabicBoldStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('اسم الحساب', style: arabicBoldStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('مدين', style: arabicBoldStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('دائن', style: arabicBoldStyle)),
                    ],
                  ),
                  ...items.map((item) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['code'] ?? '', style: arabicStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['name'] ?? '', style: arabicStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['debit'] > 0 ? formatCurrency(item['debit']) : '-', style: arabicStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['credit'] > 0 ? formatCurrency(item['credit']) : '-', style: arabicStyle)),
                  ])),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('الإجمالي', style: arabicBoldStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(formatCurrency(totalDebit), style: arabicBoldStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(formatCurrency(totalCredit), style: arabicBoldStyle)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ));

    return pdf.save();
  }

  /// Generate Income Statement PDF
  static Future<Uint8List> generateIncomeStatementPdf({
    required DateTime fromDate,
    required DateTime toDate,
    required List<Map<String, dynamic>> revenue,
    required double totalRevenue,
    required List<Map<String, dynamic>> expenses,
    required double totalExpenses,
    required double netIncome,
  }) async {
    await initialize();
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Directionality(textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Center(child: pw.Text('قائمة الدخل', style: arabicBoldStyle.copyWith(fontSize: 24))),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('للفترة من ${formatDate(fromDate)} إلى ${formatDate(toDate)}', style: arabicStyle)),
              pw.SizedBox(height: 24),
              pw.Text('الإيرادات', style: arabicBoldStyle.copyWith(fontSize: 16, color: PdfColors.green)),
              pw.SizedBox(height: 8),
              ...revenue.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(item['name'] ?? '', style: arabicStyle),
                    pw.Text(formatCurrency(item['amount'] ?? 0), style: arabicStyle),
                  ],
                ),
              )),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('إجمالي الإيرادات', style: arabicBoldStyle),
                  pw.Text(formatCurrency(totalRevenue), style: arabicBoldStyle),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('المصروفات', style: arabicBoldStyle.copyWith(fontSize: 16, color: PdfColors.red)),
              pw.SizedBox(height: 8),
              ...expenses.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(item['name'] ?? '', style: arabicStyle),
                    pw.Text(formatCurrency(item['amount'] ?? 0), style: arabicStyle),
                  ],
                ),
              )),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('إجمالي المصروفات', style: arabicBoldStyle),
                  pw.Text(formatCurrency(totalExpenses), style: arabicBoldStyle),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: netIncome >= 0 ? PdfColors.green50 : PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(netIncome >= 0 ? 'صافي الربح' : 'صافي الخسارة', style: arabicBoldStyle.copyWith(fontSize: 18)),
                    pw.Text(formatCurrency(netIncome.abs()), style: arabicBoldStyle.copyWith(fontSize: 18, color: netIncome >= 0 ? PdfColors.green : PdfColors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ));

    return pdf.save();
  }

  /// Generate Balance Sheet PDF
  static Future<Uint8List> generateBalanceSheetPdf({
    required DateTime asOfDate,
    required List<Map<String, dynamic>> assets,
    required double totalAssets,
    required List<Map<String, dynamic>> liabilities,
    required double totalLiabilities,
    required List<Map<String, dynamic>> equity,
    required double totalEquity,
  }) async {
    await initialize();
    final pdf = pw.Document();
    final totalLE = totalLiabilities + totalEquity;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Directionality(textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Center(child: pw.Text('الميزانية العمومية', style: arabicBoldStyle.copyWith(fontSize: 24))),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('كما في ${formatDate(asOfDate)}', style: arabicStyle)),
              pw.SizedBox(height: 20),
              
              // Assets
              pw.Container(padding: const pw.EdgeInsets.all(8), color: PdfColors.blue50, child: pw.Text('الأصول', style: arabicBoldStyle.copyWith(fontSize: 16))),
              ...assets.map((item) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(item['name'] ?? '', style: arabicStyle), pw.Text(formatCurrency(item['amount'] ?? 0), style: arabicStyle)]))),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('إجمالي الأصول', style: arabicBoldStyle), pw.Text(formatCurrency(totalAssets), style: arabicBoldStyle)]),
              pw.SizedBox(height: 16),
              
              // Liabilities
              pw.Container(padding: const pw.EdgeInsets.all(8), color: PdfColors.orange50, child: pw.Text('الخصوم', style: arabicBoldStyle.copyWith(fontSize: 16))),
              ...liabilities.map((item) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(item['name'] ?? '', style: arabicStyle), pw.Text(formatCurrency(item['amount'] ?? 0), style: arabicStyle)]))),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('إجمالي الخصوم', style: arabicBoldStyle), pw.Text(formatCurrency(totalLiabilities), style: arabicBoldStyle)]),
              pw.SizedBox(height: 16),
              
              // Equity
              pw.Container(padding: const pw.EdgeInsets.all(8), color: PdfColors.purple50, child: pw.Text('حقوق الملكية', style: arabicBoldStyle.copyWith(fontSize: 16))),
              ...equity.map((item) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(item['name'] ?? '', style: arabicStyle), pw.Text(formatCurrency(item['amount'] ?? 0), style: arabicStyle)]))),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('إجمالي حقوق الملكية', style: arabicBoldStyle), pw.Text(formatCurrency(totalEquity), style: arabicBoldStyle)]),
              pw.SizedBox(height: 16),
              
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('إجمالي الخصوم وحقوق الملكية', style: arabicBoldStyle), pw.Text(formatCurrency(totalLE), style: arabicBoldStyle)]),
            ],
          ),
        ),
      ],
    ));

    return pdf.save();
  }

  static Future<void> printPdf(Uint8List pdfData) => Printing.layoutPdf(onLayout: (_) => pdfData);

  static Future<String> savePdf(Uint8List pdfData, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfData);
    return file.path;
  }
}
