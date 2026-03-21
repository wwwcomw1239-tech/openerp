import { NextResponse } from 'next/server'
import { db } from '@/lib/db'

// GET - Fetch dashboard statistics
export async function GET() {
  try {
    // Get counts
    const [
      customersCount,
      suppliersCount,
      productsCount,
      invoicesCount,
      purchasesCount,
      invoices,
      purchases,
      recentInvoices,
      lowStockProducts
    ] = await Promise.all([
      db.customer.count(),
      db.supplier.count(),
      db.product.count(),
      db.invoice.count(),
      db.purchase.count(),
      db.invoice.aggregate({
        _sum: { total: true }
      }),
      db.purchase.aggregate({
        _sum: { total: true }
      }),
      db.invoice.findMany({
        take: 5,
        include: { customer: true },
        orderBy: { createdAt: 'desc' }
      }),
      db.product.findMany({
        where: {
          quantity: { lte: db.product.fields.minQuantity }
        },
        take: 10
      })
    ])
    
    const totalSales = invoices._sum.total || 0
    const totalPurchases = purchases._sum.total || 0
    
    // Get monthly sales data
    const sixMonthsAgo = new Date()
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6)
    
    const monthlyInvoices = await db.invoice.findMany({
      where: {
        date: { gte: sixMonthsAgo },
        status: { not: 'cancelled' }
      },
      select: {
        date: true,
        total: true
      }
    })
    
    // Group by month
    const monthlyData: { [key: string]: number } = {}
    monthlyInvoices.forEach(invoice => {
      const month = invoice.date.toISOString().slice(0, 7)
      monthlyData[month] = (monthlyData[month] || 0) + invoice.total
    })
    
    const chartData = Object.entries(monthlyData).map(([month, total]) => ({
      month,
      total
    })).sort((a, b) => a.month.localeCompare(b.month))
    
    return NextResponse.json({
      stats: {
        customersCount,
        suppliersCount,
        productsCount,
        invoicesCount,
        purchasesCount,
        totalSales,
        totalPurchases,
        profit: totalSales - totalPurchases
      },
      chartData,
      recentInvoices,
      lowStockProducts
    })
  } catch (error) {
    console.error('Error fetching dashboard data:', error)
    return NextResponse.json({ error: 'Failed to fetch dashboard data' }, { status: 500 })
  }
}
