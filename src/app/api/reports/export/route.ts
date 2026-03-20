import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

export async function GET(request: NextRequest) {
  try {
    // Fetch data
    const [
      customers,
      suppliers,
      products,
      invoices,
      purchases
    ] = await Promise.all([
      db.customer.count(),
      db.supplier.count(),
      db.product.count(),
      db.invoice.aggregate({ _sum: { total: true } }),
      db.purchase.aggregate({ _sum: { total: true } })
    ])

    const totalSales = invoices._sum.total || 0
    const totalPurchases = purchases._sum.total || 0
    const profit = totalSales - totalPurchases

    // Generate HTML report (can be printed to PDF from browser)
    const html = `
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <title>OpenERP Report</title>
  <style>
    body { font-family: Arial, sans-serif; padding: 40px; direction: rtl; }
    .header { text-align: center; margin-bottom: 40px; }
    .header h1 { color: #1F4E79; margin: 0; }
    .header p { color: #666; margin: 5px 0; }
    .stats { display: flex; justify-content: space-around; margin: 30px 0; }
    .stat-box { text-align: center; padding: 20px; background: #f5f5f5; border-radius: 10px; width: 200px; }
    .stat-box h3 { color: #333; margin: 0; font-size: 24px; }
    .stat-box p { color: #666; margin: 5px 0 0 0; }
    .table { width: 100%; border-collapse: collapse; margin-top: 30px; }
    .table th, .table td { border: 1px solid #ddd; padding: 12px; text-align: right; }
    .table th { background: #1F4E79; color: white; }
    .table tr:nth-child(even) { background: #f9f9f9; }
    .footer { text-align: center; margin-top: 40px; color: #999; font-size: 12px; }
    .profit { color: #10B981; }
    .loss { color: #EF4444; }
    @media print { body { padding: 20px; } }
  </style>
</head>
<body>
  <div class="header">
    <h1>📊 تقرير الأداء المالي</h1>
    <p>OpenERP - نظام إدارة موارد المؤسسات</p>
    <p>تاريخ التقرير: ${new Date().toLocaleDateString('ar-SA')}</p>
  </div>

  <div class="stats">
    <div class="stat-box">
      <h3>${totalSales.toLocaleString()}</h3>
      <p>إجمالي المبيعات (ر.س)</p>
    </div>
    <div class="stat-box">
      <h3>${totalPurchases.toLocaleString()}</h3>
      <p>إجمالي المشتريات (ر.س)</p>
    </div>
    <div class="stat-box">
      <h3 class="${profit >= 0 ? 'profit' : 'loss'}">${profit.toLocaleString()}</h3>
      <p>صافي الربح (ر.س)</p>
    </div>
  </div>

  <table class="table">
    <thead>
      <tr>
        <th>البند</th>
        <th>العدد</th>
        <th>القيمة</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>العملاء</td>
        <td>${customers}</td>
        <td>-</td>
      </tr>
      <tr>
        <td>الموردين</td>
        <td>${suppliers}</td>
        <td>-</td>
      </tr>
      <tr>
        <td>المنتجات</td>
        <td>${products}</td>
        <td>-</td>
      </tr>
      <tr>
        <td>إجمالي المبيعات</td>
        <td>-</td>
        <td>${totalSales.toLocaleString()} ر.س</td>
      </tr>
      <tr>
        <td>إجمالي المشتريات</td>
        <td>-</td>
        <td>${totalPurchases.toLocaleString()} ر.س</td>
      </tr>
      <tr style="font-weight: bold; background: #e8f5e9;">
        <td>صافي الربح</td>
        <td>-</td>
        <td class="${profit >= 0 ? 'profit' : 'loss'}">${profit.toLocaleString()} ر.س</td>
      </tr>
    </tbody>
  </table>

  <div class="footer">
    <p>تم إنشاء هذا التقرير بواسطة OpenERP</p>
    <p>© ${new Date().getFullYear()} OpenERP - جميع الحقوق محفوظة</p>
  </div>
</body>
</html>
    `

    return new NextResponse(html, {
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Content-Disposition': `attachment; filename="report-${new Date().toISOString().split('T')[0]}.html"`
      }
    })
  } catch (error) {
    console.error('Error generating report:', error)
    return NextResponse.json({ error: 'Failed to generate report' }, { status: 500 })
  }
}
